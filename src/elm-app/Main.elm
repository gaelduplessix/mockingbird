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
  { time: Time
  }

-- Init
init: (Model, Cmd Msg)
init = (Model 0, Cmd.none)

-- Update

type Msg
  = Tick Time

update: Msg -> Model -> (Model, Cmd Msg)

update msg model =
  case msg of
    Tick time -> ({ model | time = time }, Cmd.none)

-- Subscriptions

subscriptions: Model -> Sub Msg

subscriptions model = Sub.none -- Time.every second Tick

-- View

view: Model -> Html Msg

view model =
  div []
  [ h1 [] [ text (toString res) ]
  ]

res = "Hello world"
