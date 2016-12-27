port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

main = Html.program
  { init = init
  , view = view
  , update = update
  , subscriptions = subscriptions
  }

-- Model

type alias Model =
  { enablePendingRequests: Bool
  , pendingRequests: List Request
  , routes: List Route
  }

initRoutes = []

-- Init
init: (Model, Cmd Msg)
init = (Model False [] initRoutes, Cmd.none)

-- Update

type Msg
  = NewRequest Request
  | SendResponse Response
  | AddRoute
  | SetRouteUrl Route String
  | SetRouteResponse Route String
  | RemoveRoute Route
  | TogglePendingRequests

update: Msg -> Model -> (Model, Cmd Msg)

update msg model =
  case msg of
    NewRequest request ->
      -- New request: match with routes
      case (findMatchingRoute request model.routes) of
        -- No match: add to pending requests (if enabled, else just pass through)
        Nothing ->
          if model.enablePendingRequests
          then ({model | pendingRequests = model.pendingRequests++[request]}, Cmd.none)
          else (model, requestResponse (Response request.id True ""))
        -- Match: send response !
        Just route -> (model, requestResponse (responseFromRoute route request.id))
    SendResponse response -> ({
      model | pendingRequests = (removeRequest response.requestId model.pendingRequests)
    }, requestResponse response)
    AddRoute -> ({ model | routes=model.routes++[(Route "" "")] }, Cmd.none)
    SetRouteUrl route url -> ({
      model | routes=(List.map (\r ->
        if r == route then { r | url=url } else r
      ) model.routes)
    }, Cmd.none)
    SetRouteResponse route response -> ({
      model | routes=(List.map (\r ->
        if r == route then { r | responseBody=response } else r
      ) model.routes)
    }, Cmd.none)
    RemoveRoute route -> ({
      model | routes=(List.filter (\r -> not (r == route)) model.routes)
    }, Cmd.none)
    TogglePendingRequests -> ({
      model | enablePendingRequests = not model.enablePendingRequests
    }, Cmd.none)


removeRequest requestId requestsList =
  List.filter (\r -> (not (r.id == requestId))) requestsList

-- Subscriptions

subscriptions: Model -> Sub Msg

subscriptions model =
  newRequest NewRequest

-- View

view: Model -> Html Msg

view model =
  div []
  [ h1 [] [ text "Routes" ]
  , ul [ class "routes"] (List.map routeView model.routes)
  , button [ onClick AddRoute ] [ text "+ Add route" ]
  , h1 [] [ text "Pending requests", button [ onClick TogglePendingRequests] [
      text (if model.enablePendingRequests then "Enabled" else "Disabled")]]
  , ul [ class "requests"] (List.map requestView model.pendingRequests)
  ]

requestView request =
  li [ class "request" ]
  [ button [ onClick (SendResponse (Response request.id False "Mocked body!")) ] [ text "Mock response" ]
  , button [ onClick (SendResponse (Response request.id True "")) ] [ text "Pass through" ]
  , strong [] [text request.url]
  , text (" (" ++ (toString request.id) ++ ")")
  ]

routeView route =
  li [ class "route" ]
  [ label [] [text "Url", input [ type_ "text", value route.url, onInput (SetRouteUrl route) ] []]
  , label [] [text "JSON Response", textarea [value route.responseBody, onInput (SetRouteResponse route)] []]
  , button [ onClick (RemoveRoute route) ] [ text "Remove" ]
  ]

-- Models

type alias Request =
  { id: Float
  , url: String
  }

type alias Response =
  { requestId: Float
  , passthrough: Bool
  , body: String
  }

type alias Route =
  { url: String
  , responseBody: String
  }

findMatchingRoute request routesList =
  let filteredRoutes = List.filter (matchRoute request) routesList
  in List.head filteredRoutes

matchRoute request route =
  String.contains route.url request.url

responseFromRoute route requestId =
  Response requestId False route.responseBody

-- Ports

-- Port for receiving pending requests from javascript
port newRequest: (Request -> msg) -> Sub msg

-- Port for sending request responses to javascript
port requestResponse: Response -> Cmd msg
