import Html exposing (..)
import Html.Events
import Html.Attributes
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
      , info = ""
      , start = range_start
      , end = range_start
      , hover = Nothing
      , selected_event = Nothing
      , range = { start = range_start, end = range_start}
      , plot = {
        data = plot_data
      , series = series
      , items_ys = items_ys
      , start_date = plot_start
      , end_date = plot_end
      }
      , labels = True
      }
    , Cmd.none
    )


-- UPDATE
update: Types.Msg -> Model -> (Model, Cmd Types.Msg)
update msg model =
  case msg of
    Types.Fetch ->
      (
        { model | info = "Fetching data" }
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
        { model | info = "Error while fetching data: " ++ toString(error) }
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
          , start = add result.end (-48*Time.hour)
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
      (
        { model | selected_event = event },
        Cmd.none
      )
    Types.SliderChange ->
      (model, Cmd.none)

-- VIEW
view: Model -> Html Types.Msg
view model =
  div [] [
    stylesheet
    , title
    , br [] []
    , button [ Html.Events.onClick Types.FetchRange ] [ text "Fetch range" ]
    , button [ Html.Events.onClick Types.Fetch ] [ text "Fetch Data" ]
    , button [ Html.Events.onClick Types.ToggleLabels ] [ text "Toggle labels" ]
    , text model.info
    , br [] []
    , text <| String.concat
    [ "Available range: "
      , Date.Format.format "%d/%m/%Y %H:%M:%S" model.range.start
      , " - "
      , Date.Format.format "%d/%m/%Y %H:%M:%S" model.range.end
    ]
    , Plot.viewSeriesCustom
      ( MyPlot.plotCustomizations
        model.plot.items_ys
        model.labels
        model.plot.start_date
        model.plot.end_date )
      model.plot.series
      model.plot.data
    , br [] []
    -- , div [
    --   Html.Attributes.style [
    --     ("text-align", "center")
    --   ]
    -- ] [
    --   input [
    --     Html.Attributes.type_ "range"
    --   , Html.Attributes.style [ ("width", "85%") ]
    --   ] []
    -- ]
    , br [] []
    , div [ Html.Attributes.style [("min-height", "100px"), ("max-width", "100%")] ] [ text (displayEvent model.hover) ]
  ]

title: Html msg
title =
  div [ Html.Attributes.style [
  ("text-align", "center"),
  ("font-size", "20pt")
  ]] [ text "Logtales" ]

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

-- FUNCTION
add: Date.Date -> Time.Time -> Date.Date
add date time =
  Date.fromTime (
    (Date.toTime date)
    + (Time.inMilliseconds time)
  )
