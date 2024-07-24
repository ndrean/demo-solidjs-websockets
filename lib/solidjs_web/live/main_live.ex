defmodule SolidjsWeb.MainLive do
  use SolidjsWeb, :live_view

  alias SolidjsWeb.{Card, Frame}
  alias Solidjs.{Image, SupStreamer, Streamer, ModelLoader}

  defp range, do: 1..6

  defp fetch_card_data(data, id) do
    Enum.find(data, fn x -> x.id == Integer.to_string(id) end)
  end

  defp maybe_kill do
    case DynamicSupervisor.which_children(DynSup) do
      [{_, pid, :worker, [Streamer]}] ->
        Kernel.send(pid, :stop)
        :ok = DynamicSupervisor.terminate_child(DynSup, pid)

      [] ->
        :ok
    end
  end

  @impl true
  def mount(_, _session, socket) do
    {:ok, assign(socket, data: [])}
    # to get the signal when the image is processed
    Phoenix.PubSub.subscribe(MyPubsub, "image_processing")
    # to get the signal when  the model is ready
    Phoenix.PubSub.subscribe(MyPubsub, "models")

    if connected?(socket) do
    end

    {:ok, assign(socket, %{data: [], action: :pics, model_ready: true, mediapipe_caption: nil, blip_caption: nil})}
  end

  # navigation by tabs----------------------------------------------
  @impl true
  def handle_params(_, uri, socket) do
    case URI.parse(uri).path do
      "/chart" ->
        if DynamicSupervisor.which_children(DynSup) == [] do
          SupStreamer.start("bitcoin")
        end

        {:noreply, socket |> assign(live_action: :chart)}

      "/table" ->
        :ok = maybe_kill()
        {:noreply, socket |> assign(live_action: :table)}

      "/image" ->
        case ModelLoader.get_serving() == nil do
        # case !socket.assigns.model_ready do
          true ->
            :ok = maybe_kill()
            socket =
              put_flash(socket, :info, "model not ready yet")
              |> assign(%{live_action: :pics, model_ready: false})

            {:noreply, socket}

          false ->
            :ok = maybe_kill()
            send(self(), :process_image)
            {:noreply, socket |> assign(%{live_action: :image, model_ready: true, image: nil, classififcation: nil})}
        end

      _ ->
        :ok = maybe_kill()
        {:noreply, socket |> assign(live_action: :pics)}
    end
  end

  @impl true
  def handle_event("prefetch", %{"id" => id}, socket) do
    %{assigns: %{data: data}} = socket

    case Enum.find(data, fn x -> x.id == id end) do
      nil ->
        data_card = FetchData.fetch_data(id)

        {:noreply, update(socket, :data, fn data -> [data_card | data] end)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("mediapipe", %{"mediapipe" => caption}, socket) do
    caption = Enum.join(caption, ", ")
    {:noreply, assign(socket, %{mediapipe_caption: caption})}
  end

  @impl true
  # Triggered by the navigation to the image classification tab
  def handle_info(:process_image, socket) do
    Task.start(fn -> Image.process_and_caption() end)
    {:noreply, socket}
  end

  # PubSub callback from image.ex
  def handle_info({:image_processed, image, caption}, socket) do
    # socket = 
    #   socket
    #   |> assign(:image, image)
    #   |> push_event("image_processed", %{caption: caption})
    {:noreply, assign(socket, %{image: image, blip_caption: caption})}
  end

  # PubSub callback from model_loader.ex
  def handle_info(:loaded, socket) do
    {:noreply, assign(socket, :model_ready, true)}
  end

  #-------------------------------------------------------------------------------
  @impl true
  def render(assigns) when assigns.live_action == :pics do
    ~H"""
    <Frame.wrap  model_ready={@model_ready}>
      <h1>
        When you hover above an image, we pre-fetch data from an API and update the footer of the card once we get the data.
      </h1>
      <h2>
        In a second step, we will run a ML model to describe the image and update the footer with the findings.
      </h2>
      <br />
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-10">
        <%= for id <- range() do %>
          <Card.display
            card_id={Integer.to_string(id)}
            data={fetch_card_data(@data, id)}
            phx-hook="imageClassify"
          />
        <% end %>
      </div>
    </Frame.wrap>
    """
  end

  alias SolidjsWeb.Frame
  def render(assigns) when assigns.live_action == :image do
    ~H"""
      <Frame.wrap  model_ready={@model_ready}>
        <h1>Image classification of a random image</h1>
        <h2>The server fetches a random image and sends it to the browser. A ML model 
        runs server-side (BLIP) and in the browser (mediaPipe).</h2>
        <br/>
        <div>
          <figure id="figure" phx-hook="imageHook">
          <figcaption>
          <p>Server (BLIP) caption: <strong><%= @blip_caption %></strong></p>
          <p>Browser (MediaPipe) classification: <strong><%= inspect(@mediapipe_caption) %></strong></p>
          </figcaption>
            <img
              id="image"
              src={"data:image/jpeg;base64,#{@image}"}
              alt="Random Image"
              class="w-full"
            />
          </figure>
        </div>
      </Frame.wrap>
    """
  end

  def render(assigns) when assigns.live_action == :chart do
    ~H"""
    <Frame.wrap  model_ready={@model_ready}>
      <h1>
        This <code>LiveView</code>
        component receives data from an <code>Elixir</code>
        WebSocket client
      </h1>
      <h2>
        The realtime incoming data is then displayed in a <code>ChartJS</code> chart component
      </h2>
      <div id="chart" phx-hook="chartHook"></div>
    </Frame.wrap>
    """
  end

  def render(assigns) when assigns.live_action == :table do
    ~H"""
    <Frame.wrap  model_ready={@model_ready}>
      <h1><code>SolidJS</code> standalone component running as a hook</h1>
      <h2>The component connects to a WebSocket and preprends realtime incoming data</h2>
      <br />
      <div id="table" phx-hook="tableHook" phx-update="ignore"></div>
    </Frame.wrap>
    """
  end
end
