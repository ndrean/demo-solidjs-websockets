defmodule SolidjsWeb.Card do
  use Phoenix.Component

  def display(assigns) do
    ~H"""
    <div id={"card-#{@card_id}"} data-id={@card_id} phx-hook="hoverCard" class="relative overflow-hidden transform transition-transform duration-300 ease-in-out hover:scale-105 group" >
      <img src={"https://picsum.photos/200/300?random=#{@card_id}"} alt="Random Image" class="w-full">
      <footer :if={@data} class="absolute bottom-0 left-0 right-0 bg-white bg-opacity-90 p-4 opacity-0 group-hover:opacity-100 transition-opacity duration-300 ease-in-out z-10">
        <h2 class="text-lg font-bold mb-2"><%= @data.title %></h2>
        <p class="text-sm"><%= @data.body %></p>
      </footer>
    </div>
    """
  end
end

defmodule SolidjsWeb.Nav do
  use Phoenix.Component
  use SolidjsWeb, :verified_routes
  alias Phoenix.LiveView.JS
  alias SolidjsWeb.Nav

  defp menu do
    [
      {"Realtime chart", "/chart"},
      {"Realtime table", "/table"},
      {"Describe Pictures", "/"}
    ]
  end

  attr :action, :map
  attr :tab, :string 
  def tab(assigns) do
    ~H"""
    <.link
      replace
      phx-click={@action}
      class="p-4 my-4 text-xl md:text-3xl font-bold bg-[bisque] text-[midnightblue] hover:text-blue-700 transition phx-submit-loading:opacity-75 rounded-lg text-center"
    >
      <%= @tab %>
    </.link>
    """
  end

  def display(assigns) do
    ~H"""
    <nav class="flex justify-center space-x-4">
      <%= for {tab, uri} <- menu() do%>
        <Nav.tab tab={tab} action={JS.patch(uri)}/>
      <% end %>
   </nav>
   """
  end
end

