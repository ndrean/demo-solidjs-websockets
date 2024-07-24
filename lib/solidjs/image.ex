defmodule Solidjs.Image do
  @moduledoc """
  This module is responsible for processing images and captions.
  """

  def process_and_caption do
    url = :persistent_term.get(:photo_url)
    {:ok, %{body: image_binary}} = Req.get(url)

    serving = Solidjs.ModelLoader.get_serving()

    tx_image =
      image_binary
      |> StbImage.read_binary!()
      |> StbImage.to_nx()
      

    %{results: [%{text: text}]} =  Nx.Serving.run(serving, tx_image)

    b64_image = Base.encode64(image_binary)

    :ok = Phoenix.PubSub.broadcast(MyPubsub, "image_processing", {:image_processed, b64_image, text})
  end
end
