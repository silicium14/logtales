import Html exposing (..)
import Html.Events
import Html.Attributes
import Json.Decode
import Plot
import Date
import Date.Format
import Time
import Result

import Data
import Types
import MyPlot

main : Program Never Model Types.Msg
main =
  Html.program { init = init
               , view = view
               , update = update
               , subscriptions = subscriptions
               }

type alias Model =
  { events : List Types.Event -- List of events from the backend
  , info : String -- Text displayed when receiving messsages
  , start: Date.Date -- Currently plotted range of events start
  , end: Date.Date -- Currently plotted range of events end
  , hover: (Maybe Types.Event) -- Event that is being hovered on the plot
  , selected_event: (Maybe Types.Event) -- Event that has been clicked on the plot
  , slider_position: Date.Date -- Date corresponding to the current slider position, it is also the middle of the range of display events
  , range: Types.Range -- Available date range of events from backend
  , plot: MyPlot.MyPlot_ -- Plot data
  , labels: Bool -- Items labels displayed or not
}


-- MODEL
init : (Model, Cmd Types.Msg)
init =
  let
    events =
      [ { item = "Dragon", date = Date.fromTime (0.0*Time.second), content = "visits castle" }
      , { item = "Princess", date = Date.fromTime (1.0*Time.second), content = "kidnapped" }
      , { item = "Knight",  date = Date.fromTime (2.0*Time.second), content = "starts journey" }
      , { item = "Knight",  date = Date.fromTime (4.0*Time.second), content = "fights dragon" }
      , { item = "Dragon",  date = Date.fromTime (4.5*Time.second), content = "hurts knight" }
      , { item = "Princess",  date = Date.fromTime (4.7*Time.second), content = "afraid" }
      , { item = "Dragon",  date = Date.fromTime (6.0*Time.second), content = "dies" }
      , { item = "Knight",  date = Date.fromTime (6.5*Time.second), content = "returns" }
      , { item = "Princess",  date = Date.fromTime (6.5*Time.second), content = "returns" }
      , { item = "Knight",  date = Date.fromTime (8.0*Time.second), content = "back in the castle" }
      , { item = "Princess",  date = Date.fromTime (8.0*Time.second), content = "back in the castle" }
      ]
    range_start = Date.fromTime 0.0
    range_end = Date.fromTime 0.0
    (items_ys, plot_data, series, plot_start, plot_end) = MyPlot.myplot events
  in
    (
      { events = events
      , info = "Fetching range"
      , start = range_start
      , end = range_start
      , hover = Nothing
      , selected_event = Nothing
      , range = { start = range_start, end = range_start}
      , slider_position = range_start
      , plot = {
        data = plot_data
      , series = series
      , items_ys = items_ys
      , start_date = plot_start
      , end_date = plot_end
      }
      , labels = True
      }
    , Data.fetchRange
    )


-- UPDATE
update: Types.Msg -> Model -> (Model, Cmd Types.Msg)
update msg model =
  case msg of
    Types.Fetch ->
      (
        { model | info = "Fetching events" }
        , Data.getNewData model.start model.end
      )
    Types.NewData (Ok result) ->
      let
        (items_ys, data, series, start_date, end_date) = MyPlot.myplot result
      in
        (
          { model |
            info = "New data received"
          , events = result
          , plot = {
            items_ys = items_ys
          , data = data
          , series = series
          , start_date = start_date
          , end_date = end_date
          }
          },
          Cmd.none
        )
    Types.NewData (Err error) ->
      (
        { model | info = "Error while fetching events: " ++ toString(error) }
        , Cmd.none
      )
    Types.FetchRange ->
      (
        { model | info = "Fetching range" }
        , Data.fetchRange
      )
    Types.NewRange (Ok result) ->
      let
        rangeStart = result.start |> Date.toTime |> Time.inSeconds |> floor
        rangeEnd = result.end |> Date.toTime |> Time.inSeconds |> ceiling
      in
        (
          { model |
            info = "New range received"
          , range = result
          , start = add result.end (-0.5*Time.hour)
          , end = result.end
          }
        , Cmd.none
        )
    Types.NewRange (Err error) ->
      (
        { model | info = "Error while fetching range: " ++ toString(error) }
      , Cmd.none
      )
    Types.ToggleLabels ->
      (
        { model | labels = not model.labels }
      , Cmd.none
      )
    Types.Hover hover ->
      (
        { model | hover = hover },
        Cmd.none
      )
    Types.SelectEvent event ->
      ( { model | selected_event = event }
      , Cmd.none
      )
    Types.SliderCommit value ->
      let
        center = (value |> String.toFloat |> Result.withDefault 0.0)*Time.second
        width = 30*Time.minute
        start = (center - width/2) |> Date.fromTime
        end   = (center + width/2) |> Date.fromTime
      in
        (
          { model
          | info = "Fetching events"
          , start = start
          , end   = end
          , slider_position = value |> String.toFloat |> Result.withDefault 0.0 |> (*) Time.second |> Date.fromTime
          }
        , Data.getNewData start end
        )
    Types.SliderMove value ->
      (
        { model
        | slider_position = value |> String.toFloat |> Result.withDefault 0.0 |> (*) Time.second |> Date.fromTime
        }
      , Cmd.none
      )

-- VIEW
view: Model -> Html Types.Msg
view model =
  div [] [
    stylesheet
    , title
    , button [ Html.Events.onClick Types.FetchRange ] [ text "Refresh range" ]
    , button [ Html.Events.onClick Types.Fetch ] [ text "Refresh events" ]
    , button [ Html.Events.onClick Types.ToggleLabels ] [ text "Toggle labels" ]
    , text model.info
    , br [] []
    , div [Html.Attributes.style [("width", "88%"), ("margin", "0 auto"), ("text-align", "center")]] [
      span [Html.Attributes.style [("float", "left")]] [model.range.start |> Date.Format.format "%d/%m/%Y %H:%M:%S" |> text]
      , span [] [model.slider_position |> Date.Format.format "%d/%m/%Y %H:%M:%S" |> text]
      , span [Html.Attributes.style [("float", "right")]] [model.range.end |> Date.Format.format "%d/%m/%Y %H:%M:%S" |> text]
      , br [] []
      , input [
        Html.Attributes.type_ "range"
      , Html.Attributes.attribute "step" "any"
      , Html.Attributes.attribute "min" (model.range.start |> Date.toTime |> Time.inSeconds |> toString)
      , Html.Attributes.attribute "max" (model.range.end   |> Date.toTime |> Time.inSeconds |> toString)
      , Html.Attributes.style [ ("width", "100%") ]
      , Html.Events.on "change" (Json.Decode.map Types.SliderCommit Html.Events.targetValue)
      , Html.Events.on "input"  (Json.Decode.map Types.SliderMove Html.Events.targetValue)
      ] []
    ]
    , br [] []
    , Plot.viewSeriesCustom
      ( MyPlot.plotCustomizations
        model.plot.items_ys
        model.labels
        model.plot.start_date
        model.plot.end_date )
      model.plot.series
      model.plot.data
    , br [] []
    , div [ Html.Attributes.style [("min-height", "100px"), ("max-width", "100%")] ] [ text (displayEvent model.hover) ]
  ]

title: Html msg
title =
  span [
    Html.Attributes.style [
      ("float", "right")
    , ("font-size", "1rem")
    , ("text-transform", "uppercase")
    , ("margin-right", "20px")
    , ("margin-left", "20px")
    ]
  ] [ text "Logtales" ]

stylesheet: Html msg
stylesheet =
    let
        tag = "link"
        attrs =
            [ Html.Attributes.attribute "rel"       "stylesheet"
            , Html.Attributes.attribute "property"  "stylesheet"
            , Html.Attributes.attribute "href"      "https://cdn.rawgit.com/yegor256/tacit/gh-pages/tacit-0.8.1.min.css"
            ]
        children = []
    in 
        node tag attrs children

displayEvent: Maybe Types.Event -> String
displayEvent hoverEvent =
  case hoverEvent of
    Nothing ->
      ""
    Just hoverEvent ->
      toString hoverEvent

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Types.Msg
subscriptions model =
    Sub.none

-- FUNCTIONS
add: Date.Date -> Time.Time -> Date.Date
add date time =
  date |> Date.toTime |> (+) time |> Date.fromTime
