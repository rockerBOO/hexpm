defmodule Hexpm.Web.TestController do
  use Hexpm.Web, :controller

  def registry(conn, _params) do
    registry = Hexpm.Store.get(nil, :s3_bucket, "registry.ets.gz", [])

    if signature = Hexpm.Store.get(nil, :s3_bucket, "registry.ets.gz.signed", []) do
      conn
      |> put_resp_header("x-hex-signature", signature)
      |> send_resp(200, registry)
    else
      send_resp(conn, 200, registry)
    end
  end

  def registry_signed(conn, _params) do
    Hexpm.Store.get(nil, :s3_bucket, "registry.ets.gz.signed", [])
    |> send_object(conn)
  end

  def names(conn, _params) do
    Hexpm.Store.get(nil, :s3_bucket, "names", [])
    |> send_object(conn)
  end

  def versions(conn, _params) do
    Hexpm.Store.get(nil, :s3_bucket, "versions", [])
    |> send_object(conn)
  end

  def package(conn, %{"package" => package}) do
    Hexpm.Store.get(nil, :s3_bucket, "packages/#{package}", [])
    |> send_object(conn)
  end

  def tarball(conn, %{"ball" => ball}) do
    Hexpm.Store.get(nil, :s3_bucket, "tarballs/#{ball}", [])
    |> send_object(conn)
  end

  def repo(conn, %{"name" => name}) do
    Repositories.create(name, conn.assigns.current_user, audit: {%User{}, "TEST"})
    send_resp(conn, 204, "")
  end

  def docs_page(conn, params) do
    path = Path.join([params["package"], params["version"], params["page"]])
    Hexpm.Store.get(nil, :docs_bucket, path, [])
    |> send_object(conn)
  end

  def docs_sitemap(conn, _params) do
    Hexpm.Store.get(nil, :docs_bucket, Routes.sitemap_path(Hexpm.Web.Endpoint, :sitemap), [])
    |> send_object(conn)
  end

  def installs_csv(conn, _params) do
    send_resp(conn, 200, "")
  end

  defp send_object(nil, conn), do: send_resp(conn, 404, "")
  defp send_object(obj, conn), do: send_resp(conn, 200, obj)
end
