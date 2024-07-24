defmodule Solidjs.ModelLoader do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def model, do: "Salesforce/blip-image-captioning-base"
  def cache_dir, do: Path.join(Application.app_dir(:solidjs), "blip-image-captioning-base")

  @impl true
  def init(_) do
    task = Task.async(&load_models/0)
    {:ok, task}
  end

  defp load_models do
    download_settings = {:hf, model(), cache_dir: cache_dir()}
    {:ok, model_info} = Bumblebee.load_model(download_settings)
    {:ok, featurizer} = Bumblebee.load_featurizer(download_settings)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(download_settings)
    {:ok, generation_config} = Bumblebee.load_generation_config(download_settings)

    serving = Bumblebee.Vision.image_to_text(model_info, featurizer, tokenizer, generation_config)

    :persistent_term.put(:image_caption_serving, serving)
  end

  def get_serving do
    :persistent_term.get(:image_caption_serving) || false
  end

  @impl true
  def handle_info({ref, :ok}, state) when ref == state.ref do
    IO.puts "model loaded ************"
    :ok = Phoenix.PubSub.broadcast(MyPubsub, "models", :loaded)
    Process.demonitor(ref, [:flush])
    {:noreply, state}
  end
end
