module Poller exposing (..)

import Html exposing (..)
import Http
import Task
import Time
import Process
import Navigation


main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL
type alias Model =
  { backend : String
  , app : String
  , success: Bool
  , retries: Int
  }

type alias Flags =
  { backend : String
  , app : String
  }

init : Flags -> (Model, Cmd Msg)
init flags =
  ( {
    backend = flags.backend
  , app = flags.app
  , success = False
  , retries = 0
  }
  , flags.backend |> Http.getString |> Http.send PollResult
  )

-- UPDATE
type Msg
  = PollResult (Result Http.Error String)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    PollResult (Ok body) ->
      (
        { model | retries = model.retries + 1, success = True }
      , Navigation.load model.app
      )
    
    PollResult (Err body) ->
      (
        { model | retries = model.retries + 1 }
        , Process.sleep (0.1 * Time.second)
        |> Task.andThen (\_ ->
          model.backend |> Http.getString |> Http.toTask)
        |> Task.attempt PollResult
      )


-- VIEW
view : Model -> Html Msg
view model =
  div []
    [ model.success |> toString |> text
    , text ", "
    , model.retries |> toString |> text
    , text ", "
    , model.app |> toString |> text
    ]


-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
