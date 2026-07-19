defmodule PauperLeague.GraphQL do
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

  def event_info_query do
    """
        query event($id: ID!, $locale: String, $includePlayerSaved: Boolean! = false) {
        event(id: $id) {
          ...EventFields
          ...PlayerListFields
          incidents {
            ...IncidentFields
            __typename
          }
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

      fragment IncidentFields on Incident {
        id
        ticketId
        offender {
          personaId
          firstName
          lastName
          displayName
          __typename
        }
        infraction {
          id
          name
          category {
            id
            name
            __typename
          }
          defaultPenalty {
            id
            name
            __typename
          }
          __typename
        }
        penalty {
          id
          name
          __typename
        }
        roundNumber
        comment
        reportedAt
        __typename
      }

      fragment PlayerListFields on Event {
        registeredPlayers {
          ...RegistrationFields
          __typename
        }
        interestedPlayers {
          personaId
          displayName
          firstName
          lastName
          __typename
        }
        teams {
          ...TeamPayloadFields
          __typename
        }
        __typename
      }

      fragment TeamPayloadFields on TeamPayload {
        id
        eventId
        teamCode
        isLocked
        isRegistered
        tableNumber
        reservations {
          personaId
          displayName
          firstName
          lastName
          __typename
        }
        registrations {
          ...RegistrationFields
          __typename
        }
        __typename
      }

      fragment RegistrationFields on Registration {
        id
        personaId
        displayName
        firstName
        lastName
        status
        preferredTableNumber
        __typename
      }
    """
  end

  def event_round_query do
    """
    query getGameStateAtRound($eventId: ID!, $round: Int!) {
    gameStateV2AtRound(eventId: $eventId, round: $round) {
      ...GameStateFields
      __typename
    }
    }

    fragment GameStateFields on GameStateV2 {
    eventId
    minRounds
    podPairingType
    draft {
      ...DraftFields
      __typename
    }
    playoffDraft {
      ...DraftFields
      __typename
    }
    deckConstruction {
      timerId
      canRollback
      seats {
        ...SeatFields
        __typename
      }
      __typename
    }
    currentRoundNumber
    rounds {
      ...RoundFields
      __typename
    }
    drops {
      teamId
      roundNumber
      __typename
    }
    nextRoundMeta {
      hasDraft
      hasDeckConstruction
      __typename
    }
    gamesToWin
    teams {
      ...GameStateTeamFields
      __typename
    }
    playoffRounds
    __typename
    }

    fragment SeatFields on SeatV2 {
    seatNumber
    teamId
    __typename
    }

    fragment RoundFields on RoundV2 {
    roundId
    roundNumber
    isFinalRound
    isPlayoff
    isCertified
    pairingStrategy
    canRollback
    timerId
    matches {
      ...MatchFields
      __typename
    }
    standings {
      ...StandingFields
      __typename
    }
    __typename
    }

    fragment MatchFields on MatchV2 {
    matchId
    isBye
    teamIds
    tableNumber
    results {
      ...ResultsFields
      __typename
    }
    __typename
    }

    fragment ResultsFields on TeamResultV2 {
    isBye
    wins
    losses
    draws
    teamId
    __typename
    }

    fragment StandingFields on TeamStandingV2 {
    teamId
    rank
    wins
    losses
    draws
    matchPoints
    gameWinPercent
    opponentGameWinPercent
    opponentMatchWinPercent
    __typename
    }

    fragment DraftFields on DraftV2 {
    timerId
    canRollback
    pods {
      podNumber
      seats {
        ...SeatFields
        __typename
      }
      __typename
    }
    __typename
    }

    fragment GameStateTeamFields on TeamV2 {
    teamId
    teamName
    tableNumber
    players {
      personaId
      displayName
      firstName
      lastName
      __typename
    }
    __typename
    }
    """
  end
end
