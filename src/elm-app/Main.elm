port module Main exposing (..)

import Html exposing (..)
import Time exposing (Time, second)

main = Html.program
  { init = init
  , view = view
  , update = update
  , subscriptions = subscriptions
  }

-- Model

type alias Model =
  { lastRequest: String
  }

-- Init
init: (Model, Cmd Msg)
init = (Model "", requestResponse "Hello !")

-- Update

type Msg
  = NewRequest String

update: Msg -> Model -> (Model, Cmd Msg)

update msg model =
  case msg of
    NewRequest requestId -> ({ model | lastRequest = requestId }, Cmd.none)

-- Subscriptions

subscriptions: Model -> Sub Msg

subscriptions model =
  newRequest NewRequest

-- View

view: Model -> Html Msg

view model =
  div []
  [ h1 [] [ text (toString model.lastRequest) ]
  ]

-- Port for receiving pending requests from javascript
port newRequest: (String -> msg) -> Sub msg

-- Port for sending request responses to javascript
port requestResponse: String -> Cmd msg
