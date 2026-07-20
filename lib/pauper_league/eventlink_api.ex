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
    {_request, resp} =
      Req.new(
        method: :post,
        url: "https://api.tabletop.wizards.com/silverbeak-griffin-service/graphql",
        json: refresh_auth_request_body()
      )
      |> add_headers()
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

  def refresh_auth_request_body do
    access_token = PauperLeague.AccessToken.get_current()

    %{
      operationName: "refreshToken",
      variables: %{
        refreshToken: access_token.refresh_token
      },
      query: PauperLeague.GraphQL.refresh_token_query()
    }
  end

  def get_store_events(store_id, start_time, end_time) do
    Req.new(
      method: :post,
      url: "https://api.tabletop.wizards.com/silverbeak-griffin-service/graphql",
      json: store_event_request_body(store_id, start_time, end_time)
    )
    |> add_headers()
    |> run_with_retry()
  end

  def get_event_info(event_id) do
    Req.new(
      method: :post,
      url: "https://api.tabletop.wizards.com/silverbeak-griffin-service/graphql",
      json: event_info_request_body(event_id)
    )
    |> add_headers()
    |> run_with_retry()
  end

  def get_event_round_info(event_id, round_no) do
    Req.new(
      method: :post,
      url: "https://api.tabletop.wizards.com/silverbeak-griffin-service/graphql",
      json: event_round_request_body(event_id, round_no)
    )
    |> add_headers()
    |> run_with_retry()
  end

  def run_with_retry(query) do
    {_request, resp} =
      request_result =
      query
      |> Req.Request.run_request()

    cond do
      is_map(resp.body) and resp.body |> Map.has_key?("errors") ->
        with {:ok, _} <- refresh_auth_token() do
          query |> add_headers() |> Req.Request.run_request()
        end

      true ->
        request_result
    end
  end

  def add_headers(query) do
    headers = default_headers() |> add_current_auth_token()

    query
    |> Req.Request.put_headers(headers)
  end

  def store_event_request_body(store_id, start_time, end_time) do
    %{
      operationName: "getStoreEvents",
      variables: %{
        includePlayerSaved: false,
        filter: %{
          organizationId: store_id,
          page: 0,
          pageSize: 250,
          # Need to change to dynamic dates
          startDate: start_time |> DateTime.to_iso8601(),
          endDate: end_time |> DateTime.to_iso8601(),
          searchText: "",
          # formatIds: ["7uyjldU9xB1IhLH6SY6UFf"],
          formatIds: [],
          rulesEnforcementLevels: [],
          pairingTypes: [],
          twoHeadedGiant: nil,
          cutToPlayoff: nil,
          eventStatuses: [
            "SCHEDULED",
            "PLAYERREGISTRATION",
            "ROUNDREADY",
            "ROUNDACTIVE",
            "ROUNDCERTIFIED",
            "DRAFTING",
            "DECKCONSTRUCTION",
            "ENDED",
            "EXPIRED"
          ],
          templateIds: nil
        },
        locale: "en"
      },
      query: PauperLeague.GraphQL.store_event_query()
    }
  end

  def event_info_request_body(event_id) do
    %{
      operationName: "event",
      variables: %{
        includePlayerSaved: false,
        id: event_id,
        locale: "en"
      },
      query: PauperLeague.GraphQL.event_info_query()
    }
  end

  def event_round_request_body(event_id, round_no) do
    %{
      operationName: "getGameStateAtRound",
      variables: %{
        eventId: event_id,
        round: round_no
      },
      query: PauperLeague.GraphQL.event_round_query()
    }
  end
end
