defmodule SolidjsWeb.CurrencyChannel do
  use Phoenix.Channel

  @impl true
  def join("currency:"<>type, _params, socket) do
    topic = "streamer:#{type}"
    :ok = SolidjsWeb.Endpoint.subscribe(topic)

    {:ok, assign(socket, :currency, type)}
  end

  # FROM the browser, to be saved in the database
  @impl true
  def handle_in("currency:"<>currency,  payload, socket)
      when socket.assigns.currency == currency do
    save_to_db(payload)
    {:noreply, socket}
  end

  @impl true
  # brodcasted FROM the WebSocket client Solidjs.Streamer, then forward TO the browser chartHook via the channel
  def handle_info(%{topic: "streamer:"<>currency, event: "update", payload: payload}, socket) 
      when currency == socket.assigns.currency do
    broadcast!(socket, "update", payload)
    {:noreply, socket}
  end

  defp save_to_db(payload) do
    Solidjs.DataContext.save_data(%{
      price: payload["price"],
      time: payload["time"],
      type: payload["type"]
    })
  end
end