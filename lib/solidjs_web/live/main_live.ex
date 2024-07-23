defmodule SolidjsWeb.MainLive do
  use SolidjsWeb, :live_view

  alias SolidjsWeb.{Card, Nav}

 defp range, do: 1..6

  defp fetch_card_data(data, id) do
    Enum.find(data, fn x -> x.id == Integer.to_string(id) end)
  end

  defp maybe_kill_websocket_client do
    case DynamicSupervisor.which_children(DynSup) do
      [{_, pid, :worker,[Solidjs.Streamer]}] -> 
        Kernel.send(pid, :stop)
        :ok = DynamicSupervisor.terminate_child(DynSup, pid)
      [] -> :ok
    end
  end

  @impl true
  def mount(_,_session, socket) do
    {:ok, assign(socket, data: [])}
    if connected?(socket) do
      
    end
    {:ok, assign(socket, %{data: [], action: :pics})}
  end

  @impl true
  def handle_params(_, uri, socket) do
    case URI.parse(uri).path do
      "/chart" -> 
        if length(DynamicSupervisor.which_children(DynSup)) == 0 do
          Solidjs.SupStreamer.start("bitcoin")
        end

        {:noreply, socket |> assign(live_action: :chart)}
      "/table" -> 
        :ok = maybe_kill_websocket_client()
          {:noreply, socket |> assign(live_action: :table)}
        
      _ -> 
        :ok = maybe_kill_websocket_client()
        {:noreply, socket |> assign(live_action: :pics)}
    end
  end

  @impl true
  def handle_event("prefetch", %{"id"=> id}, socket) do
    %{assigns: %{data: data}} = socket
    case Enum.find(data, fn x -> x.id == id end) do
      nil -> 
       data_card = FetchData.fetch_data(id)

        {:noreply, update(socket, :data, fn data -> [data_card | data] end )}
      _ -> 
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) when assigns.live_action == :pics do
    ~H"""
    <div class="container mx-auto">
      <h1 class="text-3xl font-bold text-center">SolidJS</h1>
      <Nav.display />


      <h1>When you hover above an image, we pre-fetch data from an API and update the footer of the card once we get the data.</h1>
      <h2>In a second step, we will run a ML model to describe the image and update the footer with the findings. </h2>
      <br/>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-10">

        <%= for id <- range() do %>
          <Card.display card_id={Integer.to_string(id)} data={fetch_card_data(@data, id)}/>  
        <% end %>
      </div>
    </div>
    """
  end

  def render(assigns) when assigns.live_action == :chart do
     ~H"""
    <div class="container mx-auto">
      <h1 class="text-3xl font-bold text-center">SolidJS</h1>
      <Nav.display />
      <br/>
      <div>
        <h1>This <code>LiveView</code> component receives data from an <code>Elixir</code> WebSocket client</h1>
        <h2>The realtime incoming data is then displayed in a <code>ChartJS</code> chart component</h2>
        <div id="chart" phx-hook="chartHook"></div>
      </div>
    </div>
    """
  end

  def render(assigns) when assigns.live_action == :table do
    ~H"""
   <div class="container mx-auto">
     <h1 class="text-3xl font-bold text-center">SolidJS</h1>
     <Nav.display />
     <br/>
     <div>
       <h1 ><code>SolidJS</code> standalone component running as a hook</h1>
       <h2>The component connects to a WebSocket and preprends realtime incoming data </h2>
       <br/>
       <div id="table" phx-hook="tableHook" phx-update="ignore"></div>
     </div>
   </div>
   """
 end
end
