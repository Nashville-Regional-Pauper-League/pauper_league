defmodule PauperLeague.EventlinkApi do
  def default_headers do
    %{
      "User-Agent" =>
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:151.0) Gecko/20100101 Firefox/151.0",
      "Accept" => "*/*",
      "Accept-Language" => "en-US,en;q=0.9",
      "Accept-Encoding" => "gzip, deflate, br, zstd",
      "Referer" => "https://eventlink.wizards.com/",
      "content-type" => "application/json",
      "x-wotc-client" => "client:eventlink version:6ea86725 platform:Mac OS/firefox/151.0.0",
      "Origin" => "https://eventlink.wizards.com",
      "Sec-GPC" => "1",
      "Connection" => "keep-alive",
      "Sec-Fetch-Dest" => "empty",
      "Sec-Fetch-Mode" => "cors",
      "Sec-Fetch-Site" => "same-site",
      "Priority" => "u=4",
      "Pragma" => "no-cache",
      "Cache-Control" => "no-cache",
      "TE" => "trailers"
    }
  end

  def add_current_auth_token(headers) do
    access_token = PauperLeague.AccessToken.get_current()

    auth_string = "Bearer " <> access_token.auth_token

    headers
    |> Map.put("Authorization", auth_string)
  end

  def refresh_auth_token do
    headers = default_headers() |> add_current_auth_token()

    {_request, resp} =
      Req.new(
        method: :post,
        url: "https://api.tabletop.wizards.com/silverbeak-griffin-service/graphql",
        headers: headers,
        json: refresh_auth_query()
      )
      |> Req.Request.run_request()

    with 200 <- Map.get(resp, :status),
         body <- Map.get(resp, :body, %{}),
         true <- Map.has_key?(body, "data") do
      auth_token = body |> Map.get("data") |> Map.get("refreshToken") |> Map.get("access_token")

      refresh_token =
        body |> Map.get("data") |> Map.get("refreshToken") |> Map.get("refresh_token")

      %{
        auth_token: auth_token,
        refresh_token: refresh_token
      }
      |> PauperLeague.AccessToken.create()
    end
  end

  def refresh_auth_query do
    access_token = PauperLeague.AccessToken.get_current()

    query = """
    query refreshToken($refreshToken: String!) {
      refreshToken(refreshToken: $refreshToken) {
        access_token
        refresh_token
        expires_in
        persona_id
        display_name
        __typename
      }
    }
    """

    %{
      operationName: "refreshToken",
      variables: %{
        refreshToken: access_token.refresh_token
      },
      query: query
    }
  end
end
