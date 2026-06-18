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
      query: refresh_token_query()
    }
  end

  def get_store_events(store_id) do
    Req.new(
      method: :post,
      url: "https://api.tabletop.wizards.com/silverbeak-griffin-service/graphql",
      json: store_event_request_body(store_id)
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

  def store_event_request_body(store_id) do
    %{
      operationName: "getStoreEvents",
      variables: %{
        includePlayerSaved: false,
        filter: %{
          organizationId: store_id,
          page: 0,
          pageSize: 250,
          # Need to change to dynamic dates
          startDate: "2026-05-18T05:00:00.000Z",
          endDate: "2026-07-15T05:00:00.000Z",
          searchText: "",
          formatIds: ["7uyjldU9xB1IhLH6SY6UFf"],
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
      query: store_event_query()
    }
  end

  def refresh_token_query do
    """
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
  end

  def store_event_query do
    """
    query getStoreEvents($filter: AdvancedEventFilter!, $locale: String, $includePlayerSaved: Boolean! = false) {
    storeEvents(filter: $filter) {
      events {
        ...EventFields
        __typename
      }
      pageInfo {
        page
        pageSize
        totalResults
        __typename
      }
      hasMoreResults
      __typename
    }
    }

    fragment EventFields on Event {
    id
    status
    title
    isSegmentEvent
    eventFormat(locale: $locale) {
      id
      name
      color
      requiresSetSelection
      includesDraft
      includesDeckbuilding
      wizardsOnly
      attributes {
        attributeTag
        __typename
      }
      __typename
    }
    cardSet(locale: $locale) {
      id
      name
      __typename
    }
    rulesEnforcementLevel
    entryFee {
      amount
      currency
      __typename
    }
    venue {
      id
      name
      latitude
      longitude
      address
      streetAddress
      city
      state
      country
      postalCode
      timeZone
      phoneNumber
      emailAddress
      __typename
    }
    pairingType
    capacity
    numberOfPlayers
    historicalNumPlayers
    description
    scheduledStartTime
    estimatedEndTime
    actualStartTime
    actualEndTime
    latitude
    longitude
    address
    timeZone
    phoneNumber
    emailAddress
    shortCode
    startingTableNumber
    hasTop8
    isAdHoc
    isOnline
    groupId
    requiredTeamSize
    eventTemplateId
    tags
    playerSaved @include(if: $includePlayerSaved)
    __typename
    }
    """
  end
end
