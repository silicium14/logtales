module Plot2 exposing (..)

import Date
import Svg
import Svg.Attributes
import Svg.Events
import Visualization.Scale as Scale

import Types
import MyPlot

plot: List Types.Event -> Svg.Svg Types.Msg
plot events =
  let
     scaleX = xScale events
     (scaleY, colorScale, items) = yScale events
  in
    Svg.svg [
      Svg.Attributes.width "100%"
    , Svg.Attributes.style "padding: 1rem"
    , items |> List.length |> toFloat |> (*) 1.2 |> max 5 |> toString |> \s -> s ++ "rem" |> Svg.Attributes.height
    ] (List.concat [
        List.map (point scaleX scaleY colorScale) events
      , List.map (label scaleY) items
      ])

point: Scale.ContinuousTimeScale -> Scale.OrdinalScale String Float -> Scale.OrdinalScale String String -> Types.Event -> Svg.Svg Types.Msg
point scaleX scaleY colorScale event =
  Svg.circle [
    event.date |> Scale.convert scaleX |> toString |> \s -> s ++ "%" |> Svg.Attributes.cx
  , event.item |> Scale.convert scaleY |> Maybe.withDefault 0.0 |> toString |> \s -> s ++ "%" |> Svg.Attributes.cy 
  , Svg.Attributes.r ".4rem"
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
  , item |> Scale.convert scaleY |> Maybe.withDefault 0 |> toString |> \s -> s ++ "%" |> Svg.Attributes.y
  ]
  [Svg.text item]

xScale: List Types.Event -> Scale.ContinuousTimeScale
xScale events =
  let
    dates = events |> List.map (.date >> Date.toTime)
    start = dates |> List.minimum |> Maybe.withDefault 0.0 |> Date.fromTime
    end = dates |> List.maximum   |> Maybe.withDefault 0.0 |> Date.fromTime
  in
    Scale.time (start, end) (0, 100)


yScale: List Types.Event -> (Scale.OrdinalScale String Float, Scale.OrdinalScale String String, List String)
yScale events =
  let
      sortedItems = events |> MyPlot.sortedItems |> List.reverse
      numberOfItems = sortedItems |> List.length
      step = 100 / (numberOfItems |> toFloat)
      coordinates = (List.range 0 (numberOfItems-1)) |> List.map (toFloat >> (*) step)
  in
    (Scale.ordinal sortedItems coordinates, Scale.ordinal sortedItems ["hotpink", "salmon"], sortedItems)
