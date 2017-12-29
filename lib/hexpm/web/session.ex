defmodule Hexpm.Web.Session do
  alias Hexpm.Accounts.Session
  alias Hexpm.Repo

  @behaviour Plug.Session.Store

  def init(_opts) do
    :ok
  end

  def get(_conn, cookie, _opts) do
    with {id, "++" <> token} <- Integer.parse(cookie),
         {:ok, token} <- Base.url_decode64(token),
         session = Repo.get(Session, id),
         true <- session && Plug.Crypto.secure_compare(token, session.token) do
      {{id, token}, session.data}
    else
      _ ->
        {nil, %{}}
    end
  end

  def put(_conn, nil, data, _opts) do
    session = Session.build(data)
    session = if run?(), do: Repo.insert!(session), else: Ecto.Changeset.apply_changes(session)
    build_cookie(session)
  end

  def put(_conn, {id, token}, data, _opts) do
    Repo.update_all(Session.by_id(id), [set: [
      data: data,
      updated_at: NaiveDateTime.utc_now()
    ]])
    build_cookie(id, token)
  end

  def delete(_conn, {id, _token}, _opts) do
    Repo.delete_all(Session.by_id(id))
    :ok
  end

  defp build_cookie(session) do
    build_cookie(session.id, session.token)
  end

  defp build_cookie(id, token) do
    "#{id}++#{Base.url_encode64(token)}"
  end

  # Hack around transaction being rolled back in tests
  if Mix.env == :test do
    defp run?() do
      conn = Process.get({Ecto.Adapters.SQL, Hexpm.Repo.Pool})
      case conn && Process.get({DBConnection, conn.conn_ref}) do
        {:failed, _} -> false
        _ -> true
      end
    end
  else
    defp run?(), do: true
  end
end
