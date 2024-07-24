defmodule Solidjs.SupStreamer do
  def start(symbol) do
    options = [
      uri: "wss://ws.coincap.io/prices?assets=" <> symbol,
      state: %{symbol: symbol, data: []}
    ]

    DynamicSupervisor.start_child(DynSup, {Solidjs.Streamer, options})
  end
end

defmodule Solidjs.Streamer do
  use Fresh

  def handle_connect(101, _headers, state) do
    {:reply, [], state}
  end

  def handle_in({:text, msg}, %{symbol: symbol} = state) do
    case Jason.decode(msg) do
      {:ok, json} ->
        value = Map.get(json, symbol)

        new_state =
          Map.update!(state, :data, fn data ->
            [%{price: String.to_float(value), time: DateTime.utc_now()} | data]
          end)

        :ok =
          SolidjsWeb.Endpoint.broadcast!(
            "streamer:#{symbol}",
            "update",
            %{price: String.to_float(value), time: DateTime.utc_now()}
          )

        {:ok, new_state}

      {:error, reason} ->
        require Logger
        Logger.error("error decoding json: #{inspect(reason)}")
        {:ok, state}
    end
  end

  def handle_info(:stop, state) do
    IO.puts("closing---------")
    Fresh.close(self(), 1000, "normal")
    {:reply, [{:close, 1000, nil}], state}
  end
end
