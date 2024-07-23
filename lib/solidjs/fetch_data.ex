defmodule TypiCode do
  defstruct id: nil, title: nil, body: nil
end

defmodule FetchData do
  defp url, do: "https://jsonplaceholder.typicode.com/posts?"

  def fetch_data(id) do
    [post] = Req.get!(url()<>"id=#{id}").body
    %TypiCode{
      id: Integer.to_string(post["id"]),
      title: post["title"],
      body: post["body"]
    }
  end
end