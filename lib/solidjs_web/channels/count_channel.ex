defmodule SolidjsWeb.CountChannel do
  use Phoenix.Channel

  @impl true
  def join("counter", _params, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_in("inc", %{"count" => count}, socket) do
    dbg(count)
    Phoenix.PubSub.broadcast(:pubsub, "count", count)
    {:noreply, socket}
  end
end