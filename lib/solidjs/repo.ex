defmodule Solidjs.Repo do
  use Ecto.Repo,
    otp_app: :solidjs,
    adapter: Ecto.Adapters.SQLite3
end
