module MyPlot exposing (..)

import Dict
import Dict.Extra
import List.Extra
import Date
import Date.Format
import Plot
import Svg
import Svg.Attributes
import Svg.Events

import Types

-- TYPES
type alias MultipeSeriesData data = Dict.Dict Int data
type alias PlotEvent = { event: Types.Event, x : Float, y : Float, color: String }
type alias MyPlot_ =
  {
    data: MultipeSeriesData (List PlotEvent)
  , series: List (Plot.Series (MultipeSeriesData (List PlotEvent)) Types.Msg)
  , items_ys: Dict.Dict String Float
  , start_date: Date.Date
  , end_date: Date.Date
  }

-- FUNCTIONS
{-| Convert a list of events to a tuple (item_ys, data, series)

    item_ys: the Y position for each item line on the timeline
    data: the data that will be fed to the elm-plot viewSeries
      it is a dict whose keys are ints (one per item) and values are
      the list of events, with plot coordinates, for the item
    series: list of series that will be fed to elm-plot viewSeries
      each series is has will pick one item from the data dict
-}
myplot: List Types.Event
        -> (
          Dict.Dict String Float
        , MultipeSeriesData (List PlotEvent)
        , List (
          Plot.Series
            (MultipeSeriesData (List PlotEvent))
            Types.Msg
          )
        , Date.Date
        , Date.Date
        )
myplot events =
  let
    unique_items = items events
    items_ys = map_ys unique_items
    colors = map_colors unique_items
    axis = 0
    
    (normalised_plot_events, min_, max_) = events
    |> Dict.Extra.groupBy .item
    |> Dict.values
    |> List.map (generate_points items_ys colors)
    |> normalise2

    (data, series) = normalised_plot_events
    |> List.map (\events -> (events, myseries))
    |> multiple_series Dict.empty []
  in
    (items_ys, data, series, Date.fromTime min_, Date.fromTime max_)

items: List Types.Event -> List String
items events =
  events
  |> List.map (\e -> e.item)
  |> List.Extra.unique

new_toDataPoints
  : (data -> List (Plot.DataPoint msg))
  -> Int
  -> MultipeSeriesData data
  -> List (Plot.DataPoint msg)
new_toDataPoints toDataPoints index multipleData =
  case Dict.get index multipleData of
    Just data ->
      toDataPoints data
    Nothing ->
      []

series_with_index: Int -> Plot.Series data msg -> Plot.Series (MultipeSeriesData data) msg
series_with_index index series =
  { series
    | toDataPoints = new_toDataPoints series.toDataPoints index
  }

multiple_series
  : MultipeSeriesData data
  -> List (Plot.Series (MultipeSeriesData data) msg)
  -> List (data, Plot.Series data msg)
  -> (MultipeSeriesData data, List (Plot.Series (MultipeSeriesData data) msg))
multiple_series multipeSeriesData newSeries list_data_with_series =
  let
    index = (Dict.size multipeSeriesData)+1
  in
    case list_data_with_series of
      [] ->
        (multipeSeriesData, newSeries)
      (data, series)::tl ->
        multiple_series (Dict.insert index data multipeSeriesData) ((series_with_index index series)::newSeries) tl

-- TODO: Decouple from event structure, take item field as parameter somewhere
generate_points
  : Dict.Dict String Float
  -> Dict.Dict String String
  -> List Types.Event
  -> List PlotEvent
generate_points ys colors events =
  List.map
    (\event ->
      {
        event = event
      , x = event.date |> Date.toTime
      , y = Dict.get event.item ys |> Maybe.withDefault -1.0
      , color = Dict.get event.item colors |> Maybe.withDefault "black"
      }
    )
    events

normalise: Float -> Float -> Float -> Float
normalise min_ max_ value =
  (value - min_) / (max_ - min_)

{-| Normalises x values of a list of list of records
    to the 0-1 range
-}
normalise2
  : List (List { a | x : Float})
  ->( List (List { a | x : Float})
    , Float
    , Float
    )
normalise2 events =
  let
    all_values = List.map .x (List.concat events)
    min_ = List.minimum all_values |> Maybe.withDefault 0.0
    max_ = List.maximum all_values |> Maybe.withDefault 0.0
  in
    ( List.map
        (List.map (\event -> { event | x = normalise min_ max_ event.x}))
        events
    , min_
    , max_
    )
    

reverse_pair : ( a, b ) -> ( b, a )
reverse_pair (first, second) =
  (second, first)

map_ys: List String -> Dict.Dict String Float
map_ys unique_items =
  unique_items
  |> List.Extra.zip (List.length unique_items |> List.range 0 |> List.map toFloat)
  |> List.map reverse_pair
  |> Dict.fromList

map_colors: List comparable -> Dict.Dict comparable String
map_colors unique_items =
  unique_items
  |> List.Extra.zip
    ( List.length unique_items
    |> List.range 0
    |> List.map (\index -> if (rem index 2) == 1 then "hotpink" else "salmon")
    )
  |> List.map reverse_pair
  |> Dict.fromList

mypoint: Types.Event -> String -> Svg.Svg Types.Msg
mypoint event color =
  Svg.circle
    [ Svg.Attributes.r "3"
    , Svg.Attributes.stroke "transparent"
    , Svg.Attributes.strokeWidth "3px"
    , Svg.Attributes.fill color
    , Svg.Attributes.opacity "0.2"
    , Svg.Events.onMouseOver (Types.Hover (Just event))
    , Svg.Events.onMouseOut (Types.Hover Nothing)
    , Svg.Events.onClick (Types.SelectEvent (Just event))
    ]
    []

myseries: Plot.Series (List PlotEvent) Types.Msg
myseries =
  let
    series = Plot.dots (
      List.map (
        \plot_event -> {
          x = plot_event.x
        , y = plot_event.y
        , hint = Nothing
        , view = Just (mypoint plot_event.event plot_event.color)
        , xTick = Nothing
        , yTick = Nothing
        , xLine = Nothing
        , yLine = Nothing
        })
    )
  in
    { series
    | axis = Plot.customAxis <| \summary ->
      { position = \_ _ -> 0
      -- , axisLine = Just (Plot.simpleLine summary)
      , axisLine = Nothing
      , ticks = []
      , labels = []
      , flipAnchor = False
      }
    }

time_labels: String -> String -> List Plot.LabelCustomizations
time_labels start end =
  let
    attributes = [ Svg.Attributes.fontSize "8" ]
  in
    List.map
      (\label -> 
        { view = Plot.viewLabel attributes label.text
        , position = label.position
        }
      )
      [{text = start, position = 0.0}, {text = end, position = 1.0}]

plotCustomizations : 
  Dict.Dict String Float
  -> Bool
  -> Date.Date
  -> Date.Date
  -> Plot.PlotCustomizations Types.Msg
plotCustomizations items_ys show_labels plot_start_date plot_end_date =
  let
    defaults = Plot.defaultSeriesPlotCustomizations
    timeAxis_height = -1.0
    x_start = 0
  in
    { defaults
    | toDomainLowest = min timeAxis_height
    , toRangeLowest = min x_start
    , horizontalAxis = Plot.customAxis <| \summary ->
      { position = \_ _ -> timeAxis_height
      , axisLine = Nothing
      -- , axisLine = Just (Plot.simpleLine summary)
      , ticks = List.map Plot.simpleTick [ summary.dataMin, summary.dataMax ]
      , labels = time_labels
        (Date.Format.format "%d/%m/%Y %H:%M:%S" plot_start_date)
        (Date.Format.format "%d/%m/%Y %H:%M:%S" plot_end_date)
      , flipAnchor = False
      }
    , height = max (10*(Dict.size items_ys)) 60
    , junk = if show_labels then items_labels show_labels items_ys x_start else (\_ -> [])
    }

items_labels: Bool -> Dict.Dict String Float -> Float -> Plot.PlotSummary -> List (Plot.JunkCustomizations msg)
items_labels showLabels items_ys x _ =
  let
    attributes = 
      [ Svg.Attributes.fontSize "6"
      , Svg.Attributes.textAnchor "start"
      ]
  in
    items_ys
    |> Dict.map (\item y ->Plot.junk (Plot.viewLabel attributes item) x y)
    |> Dict.values
