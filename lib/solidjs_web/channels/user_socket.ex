defmodule SolidjsWeb.UserSocket do
  use Phoenix.Socket

  channel "currency:*", SolidjsWeb.CurrencyChannel
  channel "counter", SolidjsWeb.CountChannel
  
  @impl true
  def connect(_params, socket) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end