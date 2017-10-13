module Plot exposing (..)

import Date
import Dict
import Dict.Extra
import Html exposing (..)
import Html.Attributes
import Svg
import Svg.Attributes
import Svg.Events
import Visualization.Scale as Scale
import Visualization.Axis as Axis exposing (defaultOptions)
import Window

import Types

plot: Window.Size -> List Types.Event -> Html Types.Msg
plot windowSize events =
  let
    -- The window width is the reference for the plot width
    svgWidth = windowSize.width - 100  -- The width of the svg elements
    paddingX = 50  -- The padding to put a each side of the plot
    plotWidth = svgWidth - 2*paddingX  -- the width of the plot area available for drawing
    scaleX = xScale plotWidth events
    viewBoxXStart = -paddingX  -- The viewbox starts before zero for the padding
    viewBoxWidth = svgWidth  -- The width of the viewbox is the same as the width of the svg element

    -- The height of the plot svg elements depends on the number of items to display
    (scaleY, colorScale, items, plotHeight) = yScale events
    plotSvgHeight = plotHeight + 2*axisPaddingY

    axisPaddingY = 20  -- The Y padding inside the axis svg
    axisSvgHeight = axisPaddingY + 10  -- The height of the axis svg elements
  in
    div [ Html.Attributes.style [ ("display", "block"), ("text-align", "center") ] ] [
      Svg.svg [
        Svg.Attributes.width <| toString <| svgWidth
      , Svg.Attributes.height <| toString <| axisSvgHeight
      -- Top padding for the bottom axis
      , [viewBoxXStart, -axisPaddingY, viewBoxWidth, axisSvgHeight] |> List.map toString |> String.join " " |> Svg.Attributes.viewBox
      ] [
        xAxis Axis.Top (xScale plotWidth events)
      ]
    , Svg.svg [
        Svg.Attributes.width <| toString <| svgWidth
      , Svg.Attributes.height <| toString <| plotSvgHeight
      , [viewBoxXStart, -axisPaddingY, viewBoxWidth, plotSvgHeight] |> List.map toString |> String.join " " |> Svg.Attributes.viewBox
      ] [
        Svg.g [] (List.map (point scaleX scaleY colorScale) events)
      , Svg.g [] (List.map (label scaleY) items)
      ]
    , Svg.svg [
        Svg.Attributes.width <| toString <| svgWidth
      , Svg.Attributes.height <| toString <| axisSvgHeight
      -- Bottom padding for the bottom axis
      , [viewBoxXStart, 0, viewBoxWidth, axisSvgHeight] |> List.map toString |> String.join " " |> Svg.Attributes.viewBox
      ] [
        xAxis Axis.Bottom (xScale plotWidth events)
      ]
    ]


point: Scale.ContinuousTimeScale -> Scale.OrdinalScale String Float -> Scale.OrdinalScale String String -> Types.Event -> Svg.Svg Types.Msg
point scaleX scaleY colorScale event =
  Svg.circle [
    event.date |> Scale.convert scaleX |> toString |> Svg.Attributes.cx
  , event.item |> Scale.convert scaleY |> Maybe.withDefault 0.0 |> toString |> Svg.Attributes.cy 
  , Svg.Attributes.r "8"
  , Svg.Attributes.opacity "0.2"
  , event.item |> Scale.convert colorScale |> Maybe.withDefault "black" |> Svg.Attributes.fill 
  , Svg.Events.onMouseOver (Types.Hover (Just event))
  , Svg.Events.onMouseOut (Types.Hover Nothing)
  ] []

label: Scale.OrdinalScale String Float -> String -> Svg.Svg Types.Msg
label scaleY item =
  Svg.text_ [
    Svg.Attributes.fontSize ".8rem"
  , Svg.Attributes.textAnchor "start"
  , item |> Scale.convert scaleY |> Maybe.withDefault 0 |> toString |> Svg.Attributes.y
  ]
  [Svg.text item]

xScale: Int -> List Types.Event -> Scale.ContinuousTimeScale
xScale width events =
  let
    dates = events |> List.map (.date >> Date.toTime)
    start = dates |> List.minimum |> Maybe.withDefault 0.0 |> Date.fromTime
    end = dates |> List.maximum   |> Maybe.withDefault 0.0 |> Date.fromTime
  in
    Scale.time (start, end) (0, width |> toFloat)


yScale: List Types.Event -> (Scale.OrdinalScale String Float, Scale.OrdinalScale String String, List String, Int)
yScale events =
  let
      items = events |> sortedItems |> List.reverse
      numberOfItems = items |> List.length
      step = 25
      height = step * (numberOfItems-1)
      coordinates = (List.range 0 (numberOfItems-1)) |> List.map (toFloat >> (*) step)
  in
    (Scale.ordinal items coordinates, Scale.ordinal items ["hotpink", "salmon"], items, height)

xAxis: Axis.Orientation -> Scale.ContinuousTimeScale -> Svg.Svg Types.Msg
xAxis orientation scaleX =
  let
      domain = Scale.domain scaleX
  in
    Axis.axis
      { defaultOptions
      | orientation = orientation
      , ticks = Just [Tuple.first domain, Tuple.second domain]
      }
      scaleX

sortedItems: List Types.Event -> List String
sortedItems events =
  events
  |> Dict.Extra.groupBy .item
  |> Dict.toList
  |> (List.map <| Tuple.mapSecond <| List.map .date)
  |> (List.map <| Tuple.mapSecond <| List.map Date.toTime)
  |> (List.map <| Tuple.mapSecond <| List.minimum)
  |> (List.map <| Tuple.mapSecond <| Maybe.withDefault 0.0)
  |> List.sortBy Tuple.second
  |> List.map Tuple.first
  |> List.reverse