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
  { pendingRequests: List Request
  }

-- Init
init: (Model, Cmd Msg)
init = (Model [], Cmd.none)

-- Update

type Msg
  = NewRequest Request
  | SendResponse Request

update: Msg -> Model -> (Model, Cmd Msg)

update msg model =
  case msg of
    NewRequest request -> ({ model | pendingRequests = request::model.pendingRequests }, Cmd.none)
    SendResponse response -> (
      { model | pendingRequests = (removeRequest response.id model.pendingRequests)
      },
      requestResponse response
    )

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
  [ h1 [] [ text "Pending requests:" ]
  , ul [ class "requests"] (List.map requestView model.pendingRequests)
  ]

requestView request =
  li [ class "request" ]
  [ button [ onClick (SendResponse request) ] [ text "Send response" ]
  , strong [] [text request.url]
  , text (" (" ++ (toString request.id) ++ ")")
  ]

type alias Request =
  { id: Float
  , url: String
  }

-- Port for receiving pending requests from javascript
port newRequest: (Request -> msg) -> Sub msg

-- Port for sending request responses to javascript
port requestResponse: Request -> Cmd msg
