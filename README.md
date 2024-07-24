# Phoenix LiveView with Solidjs, ApexCharts

## What is this?

A small `Phoenix LiveView` app to showcase:

- navigation with tabs.
- code splitting,
- prefetching data on image hovering.
- include a `SolidJS` component that renders a table with the WebSocket connection to an endpoint to preprend data in realtime. This component sends the data to the server via an `Elixir.Channel` where it is saved into an `SQLite` database.
- include a `SolidJS` component that uses the lightweight Javascript charting `ApexCharts`. We visualize data sent from a WebSocket client (a server module powered by [Fresh](https://github.com/bunopnu/fresh)). He set a PubSub between the Fresh server and an `Elixir.Channel`, and then push via the Channel to the browser.

## Esbuild plugins

We are going to use `Esbuild` plugins. This is explained [in the documentation](https://hexdocs.pm/phoenix/asset_management.html#esbuild-plugins).

### Package.json

Besides bringing in `esbuild` and `tailwind`, we use `solidjs` and `apexcharts`.

At the time of writting, you have:

```bash
pnpm init
pnpm add -D @tailwindcss/forms esbuild esbuild-plugin-solid tailwindcss fs
pnpm add solid-js @solid-primitives/ref apexcharts solid-apexcharts ../deps/phoenix ../deps/phoenix_html ../deps/phoenix_live_view
```

You should have (at the time of writing):

```json
"type": "module",
"devDependencies": {
  "@tailwindcss/forms": "^0.5.7",
  "esbuild": "^0.23.0",
  "esbuild-plugin-solid": "^0.6.0",
  "tailwindcss": "^3.4.6",
  "fs": "0.0.1-security",
},
"dependencies": {
  "@solid-primitives/refs": "^1.0.8",
  "@solidjs/router": "^0.14.1",
  "apexcharts": "^3.51.0",
  "phoenix": "link:../deps/phoenix",
  "phoenix_html": "link:../deps/phoenix_html",
  "phoenix_live_view": "link:../deps/phoenix_live_view",
  "solid-apexcharts": "^0.3.4",
  "solid-js": "^1.8.18",
  "topbar": "^3.0.0"
}
```

## Custom Esbuild configuration

SolidJS uses JSX for templating, we have to be sure Esbuild compiles the JSX files for SolidJS.
Phoenix compiles and bundles all `js` and `jsx` files into the "priv/static/assets" folder.
We also evaluate bundle size mapping.

<details>
<summary>Build.js file</summary>

```js
// new file: /assets/build.js

import { context, build } from "esbuild";
import { solidPlugin } from "esbuild-plugin-solid";
import fs from "fs";

const args = process.argv.slice(2);
const watch = args.includes("--watch");
const deploy = args.includes("--deploy");

// Define esbuild options
let opts = {
  entryPoints: ["js/app.js"],
  bundle: true,
  logLevel: "info",
  target: "es2022",
  outdir: "../priv/static/assets",
  external: ["*.css", "fonts/*", "images/*"],
  loader: { ".js": "jsx", ".svg": "file" },
  plugins: [solidPlugin()],
  nodePaths: ["../deps"],
  format: "esm",
};

if (deploy) {
  opts = {
    ...opts,
    minify: true,
    splitting: true,
  };
  let result = await build(opts);
  fs.writeFileSync("meta.json", JSON.stringify(result.metafile, null, 2));
}

if (watch) {
  opts = {
    ...opts,
    sourcemap: "inline",
  };

  context(opts)
    .then((ctx) => (watch ? ctx.watch() : build(opts)))
    .catch((error) => {
      console.log(`Build error: ${error}`);
      process.exit(1);
    });
}
```

</details>
<br/>

In "config/dev/exs", add:

```elixir
# config/devs.exs

config :solidjs, SolidjsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "aaiv+mgJIO4sLLpE7GUxg45/HQeETt98/a8ff6zlCwPEd4mOYSzDU7UEWoLyuzzv",
  watchers: [
    node: ["build.js", "--watch", cd: Path.expand("../assets", __DIR__)],
    ^^^
    tailwind: {Tailwind, :install_and_run, [:solidjs, ~w(--watch)]}
  ]
```

and remove the config for "esbuild" (as `node` will run `esbuild`).

The `Mix` tasks in the "mix.exs" file are:

```elixir
# mix.exs

defp aliases do
  [
    setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
    "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs", "cmd --cd assets pnpm install"],
    "ecto.reset": ["ecto.drop", "ecto.setup"],
    test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
    "assets.deploy": [
      "tailwind solidjs --minify",
      "cmd --cd assets node build.js --deploy",
      "phx.digest"
    ]
  ]
end
```

## Tab navigation

- In the `handle_params/3` callback, parse the "uri" argument and add a `live_action` assign accordingly. For example, we want to navigate to "/chart", we add `live_action: :chart`.
- In the router, add the routes corresponding to the tabs, such as:

```elixir
live "/chart", MainLive, :chart
```

- add a `render/1` with a guard clause to render the appropriate markup.

```elixir
def render(assigns) when assigns.live_action == :chart do
  ~H"""
   .....
  """
end
```

The navigation action is triggered by a link that looks like:

```elixir
<.link
  replace
  phx-click={JS.patch(uri)}
  class="..."
>
  Go the chart
</.link>
```

## Javascript components with context pattern

We used the **"context" pattern**: you parametrize a function that returns a Component.

The pattern is:

```js
export const component = (ctx) =>  {
  // get stuff from the context
  const {state, setState} = ctx
  [...]
  return Component(props) {
    do stuff...;
    return HTMLComponent
  }
}
```

To use it, do:

```js
import context from "./context";
import {componen}t from "./component.jsx"

const Component = component(context);
```

You want to design a component as stateless as possible. You centralize everything related to the configuration, styles.

Local state is still possible though if it only belongs to this component where reactivity is need.

For example, `userSocket` and `useChannel` are declared in the "context". We can use them in any component.

## Re-usable channels client-side

To establish the "user socket" and channel, we firstly build the userSocket client endpoint

- connect client-side:

:exclamation:note that we did not pass a "user-token" as an object in the `new Socket` constructor, but this should be the case.

```js
import { Socket } from "phoenix";
const userSocket = new Socket("/socket", {});
userSocket.connect();
export default userSocket;
```

- define the "userSocket" server-side:

```elixir
# add to endpoint.ex
socket "/socket", SolidjsWeb.UserSocket,
    websocket: true,
```

- define the server-side handler:
  
:exclamation: we should receive the "user-token" in the connect and check it.

```elixir
# create user_socket.ex
defmodule SolidjsWeb.UserSocket do
  use Phoenix.Socket

  channel "currency:*", SolidjsWeb.CurrencyChannel

  @impl true
  def connect(_params, socket) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
```

Note that we already declared the channels we will use in this module. For example, `CurrencyChannel` with the topics "currecny:\*".

To establish channels on top of the "user socket", we define a generic `useChannel` client-side function:

```js
// userChannel.js

export default function useChannel(socket, topic) {
  if (!socket) return null;
  const channel = socket.channel(topic, {});
  channel
    .join()
    .receive("ok", () => {
      console.log(`Joined successfully: ${topic}`);
    })
    .receive("error", (resp) => {
      console.log(`Unable to join ${topic}`, resp.reason);
    });
  return channel;
}
```

To use it, we add the topic client-side which matches the one declared in "user_socket.ex".

```js
import userSocket from "./context";
const currencyChannel = useChannel(userSocket, "currency:bitcoin");
```

<details>
<summary> It remains to build the channel "CurrencyChannel" with this topic server-side. An example here</summary>

```elixir
defmodule SolidjsWeb.CurrencyChannel do
  use Phoenix.Channel

  @impl true
  def join("currency:"<>type, _params, socket) do
    topic = "streamer:#{type}"
    :ok = SolidjsWeb.Endpoint.subscribe(topic)

    {:ok, assign(socket, :currency, type)}
  end

  # received FROM the browser, to be saved in the database
  @impl true
  def handle_in("currency:"<>currency,  payload, socket)
      when socket.assigns.currency == currency do
    save_to_db(payload)
    {:noreply, socket}
  end

  @impl true
  # received as we subscribed to a PubSub topic
  # brodcasted FROM the WebSocket client Solidjs.Streamer, then forward TO the browser chartHook via the channel
  def handle_info(%{topic: "streamer:"<>currency, event: "update", payload: payload}, socket)
      when currency == socket.assigns.currency do
    broadcast!(socket, "update", payload)
    {:noreply, socket}
  end

  defp save_to_db(payload) do
    Solidjs.Repo.save(payload)
  end
end
```

</details>
<br/>

## Cleanup between SolidJS and LiveView

`LiveView` shadows the `SolidJS` method `onCleanup`.
To properly stop a channel and a websocket connection when you leave a tab that runs these features, we may need to pass a reference from the Javascript hook, and use the "ref.current" in the `destroyed` hook lifecycle (check "table.jsx" and "tableHook.js")

```js
const componentHook = {
  channelRef: { current: null },
  socketRef: { current: null },
  mounted() {
    Component(channelRef, socketRef);
  },
  destroyed() {
    this.channelRref.leave();
    this.socketRef.close();
  },
};
```

## Bundle size with code splitting

The "build.js" will produce a [metafile](https://esbuild.github.io/api/#metafile) when running `mix assets.deploy`.

Analyse it:

<https://esbuild.github.io/analyze/>

This displays:

<img width="1372" alt="Screenshot 2024-07-23 at 20 12 08" src="https://github.com/user-attachments/assets/50cb0255-896b-4cf7-838b-a19ba198a3e6">
