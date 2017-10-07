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
  , slider_position: Date.Date -- Date corresponding to the current slider position, it is also the middle of the range of display events
  , range_width_value: Int  -- The width of the time range around the slider position. Expressed as an positive integer in the unit of the range.
  , range_width_edit_value: String -- The current value during edition of the range width
  , range_width_unit: Types.RangeWidthUnit -- The unit associated with the range width value
  , range: Types.Range -- Available date range of events from backend
  , plot: MyPlot.MyPlot_ -- Plot data
  , labels: Bool -- Items labels displayed or not
}


-- MODEL
init : (Model, Cmd Types.Msg)
init =
  let
    events =
      [ { item = "Dragon",    date = Date.fromTime (0.0*Time.second), content = "visits castle" }
      , { item = "Princess",  date = Date.fromTime (1.0*Time.second), content = "kidnapped" }
      , { item = "Knight",    date = Date.fromTime (2.0*Time.second), content = "starts journey" }
      , { item = "Knight",    date = Date.fromTime (4.0*Time.second), content = "fights dragon" }
      , { item = "Dragon",    date = Date.fromTime (4.5*Time.second), content = "hurts knight" }
      , { item = "Princess",  date = Date.fromTime (4.7*Time.second), content = "afraid" }
      , { item = "Dragon",    date = Date.fromTime (6.0*Time.second), content = "dies" }
      , { item = "Knight",    date = Date.fromTime (6.5*Time.second), content = "returns" }
      , { item = "Princess",  date = Date.fromTime (6.5*Time.second), content = "returns" }
      , { item = "Knight",    date = Date.fromTime (8.0*Time.second), content = "back in the castle" }
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
      , range = { start = range_start, end = range_start}
      , slider_position = range_start
      , range_width_value = 1
      , range_width_edit_value = "1"
      , range_width_unit = Types.Hours
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
    Types.SliderMove value ->
      (
        { model
        | slider_position = value
        }
      , Cmd.none
      )
    Types.SliderCommit value ->
      let
        (start, end) = compute_range
          value
          (range_width_to_time model.range_width_value model.range_width_unit)
      in
        (
          { model
          | info = "Fetching events"
          , start = start
          , end   = end
          , slider_position = value
          }
        , Data.getNewData start end
        )
    Types.RangeWidthEdit edit_value ->
      (
        { model | range_width_edit_value = edit_value }
      , Cmd.none
      )

    Types.RangeWidthCommit result ->
      case result of
        Ok value ->
          let
            (start, end) = compute_range model.slider_position (range_width_to_time value model.range_width_unit)
          in
      (
        { model
              | range_width_value = value
              , start = start
              , end = end
              , info = "Fetching events"
        }
            , Data.getNewData start end
            )
        Err error ->
          (
            { model
            | info = error
            , range_width_edit_value = model.range_width_value |> toString
            }
      , Cmd.none
      )
    Types.RangeUnitCommit unit ->
      let
        (start, end) = compute_range model.slider_position (range_width_to_time model.range_width_value unit)
      in  
        (
          { model
          | range_width_unit = unit
          , start = start
          , end = end
          , info = "Fetching events"
          }
        , Data.getNewData start end
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
      span [Html.Attributes.style [("float", "left")]] [model.range.start |> Date.Format.format date_format |> text]
      , span []
        [ range_width_value_edit model.range_width_value model.range_width_edit_value
        , text " "
        , range_width_unit_edit model.range_width_unit model.range_width_value
        , text " around "
        , model.slider_position |> Date.Format.format date_format |> text
        ]
      , span [Html.Attributes.style [("float", "right")]] [model.range.end |> Date.Format.format date_format |> text]
      , br [] []
      , input [
        Html.Attributes.type_ "range"
      , Html.Attributes.attribute "step" "any"
      , Html.Attributes.attribute "min" (model.range.start |> Date.toTime |> Time.inSeconds |> toString)
      , Html.Attributes.attribute "max" (model.range.end   |> Date.toTime |> Time.inSeconds |> toString)
      , Html.Attributes.style [ ("width", "100%") ]
      , Html.Events.on "change"
        (Json.Decode.map
          (String.toFloat >> Result.withDefault 0.0 >> (*) Time.second >> Date.fromTime >> Types.SliderCommit)
          Html.Events.targetValue)
      , Html.Events.on "input"
        (Json.Decode.map
          (String.toFloat >> Result.withDefault 0.0 >> (*) Time.second >> Date.fromTime >> Types.SliderMove)
          Html.Events.targetValue)
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
    , displayEvent model.hover
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

displayEvent: Maybe Types.Event -> Html Types.Msg
displayEvent hoverEvent =
  case hoverEvent of
    Nothing ->
      div [] []
    Just event ->
      span
        [ Html.Attributes.style
          [ ("min-height", "100px")
          , ("max-width", "100%")
          , ("position", "fixed")
          , ("bottom", "0")
          , ("background", "lightgray")
          , ("border", "1px solid #ccc")
          , ("border-radius", "3.6px")
          , ("padding", "0.5% 1%")
          , ("min-height", "0")
          ]
        ]
        [ event |> toString |> text ]

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Types.Msg
subscriptions model =
    Sub.none

-- FUNCTIONS
add: Date.Date -> Time.Time -> Date.Date
add date time =
  date |> Date.toTime |> (+) time |> Date.fromTime

range_width_value_edit: Int -> String -> Html Types.Msg
range_width_value_edit value edit_value =
  input
    [ Html.Attributes.style [
        ("cursor", "pointer")
      , ("background", "inherit")
      , ("padding", "0.5% 1%")
      , ("border", "1px solid #ccc")
      , ("text-align", "center")]
    , Html.Attributes.type_ "text"
    , Html.Attributes.value edit_value
    , edit_value |> String.length |> max 1 |> Html.Attributes.size
    , Html.Events.on "change" (Json.Decode.map (String.toInt >> Types.RangeWidthCommit) Html.Events.targetValue)
    , Html.Events.on "input" (Json.Decode.map Types.RangeWidthEdit Html.Events.targetValue)
    ] []

unitDecoder : String -> Types.RangeWidthUnit
unitDecoder str =
  case str of
    "Seconds" ->
        Types.Seconds
    "Minutes" ->
        Types.Minutes
    "Hours" ->
        Types.Hours
    "Days" ->
        Types.Days
    anythingElse ->
        Types.Seconds

unitToString: Bool -> Types.RangeWidthUnit -> String
unitToString singular unit =
  let
    result = unit |> toString
  in
    if singular then
      result |> String.dropRight 1
    else
      result


range_width_unit_edit: Types.RangeWidthUnit -> Int -> Html Types.Msg
range_width_unit_edit current_unit current_value =
  select
    [ Html.Attributes.style [
        ("cursor", "pointer")
      , ("background", "inherit")
      , ("appearance", "none")
      , ("padding", "0.5% 1%")
      , ("text-align", "center")
      , ("-webkit-appearance", "none")
      , ("-moz-appearance", "none")]
    , Html.Events.on "change" (Json.Decode.map (unitDecoder >> Types.RangeUnitCommit) Html.Events.targetValue)
    ] (List.map
      (\unit -> node "option"
        [ unit |> toString |> Html.Attributes.value
        , Html.Attributes.selected (unit == current_unit)
        , Html.Attributes.style [("text-align", "center")] ]
        [unit |> unitToString (current_value <= 1) |> String.toLower |> text])
      [Types.Seconds, Types.Minutes, Types.Hours, Types.Days])

range_width_to_time: Int -> Types.RangeWidthUnit -> Time.Time
range_width_to_time value unit =
  let
    time_unit = case unit of
      Types.Days ->
        24*Time.hour
      Types.Hours ->
        Time.hour
      Types.Minutes ->
        Time.minute
      Types.Seconds ->
        Time.second
  in
    toFloat(value) * time_unit

date_format: String
date_format = "%Y/%m/%d %H:%M:%S"

compute_range: Date.Date -> Time.Time -> (Date.Date, Date.Date)
compute_range center width =
  let
      center_time = center |> Date.toTime
  in
    (
      (center_time - width/2) |> Date.fromTime
    , (center_time + width/2) |> Date.fromTime
    )
