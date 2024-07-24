defmodule SolidjsWeb.UserSocket do
  use Phoenix.Socket

  channel "currency:*", SolidjsWeb.CurrencyChannel
  channel "counter", SolidjsWeb.CountChannel

  @impl true
  def connect(params, socket) do
    dbg(params)
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
