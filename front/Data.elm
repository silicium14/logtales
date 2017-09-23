module Data exposing (..)

import Date
import Time
import Http
import Json.Decode

import Types

eventDecoder: Json.Decode.Decoder Types.Event
eventDecoder =
  Json.Decode.map3
    Types.Event
    (Json.Decode.field "item" Json.Decode.string)
    (Json.Decode.field "date" dateTimestampDecoder)
    (Json.Decode.field "content" Json.Decode.string)

rangeDecoder: Json.Decode.Decoder Types.Range
rangeDecoder =
  Json.Decode.map2
    Types.Range
    (Json.Decode.field "start" dateTimestampDecoder)
    (Json.Decode.field "end" dateTimestampDecoder)

dateTimestampDecoder: Json.Decode.Decoder Date.Date
dateTimestampDecoder =
    let
      convert: Float -> Json.Decode.Decoder Date.Date
      convert time =
          time*Time.second |> Date.fromTime |> Json.Decode.succeed
    in
      Json.Decode.float |> Json.Decode.andThen convert

url: String
url =
  "http://localhost:4000/"

url_events: Int -> Int -> String
url_events start end =
  String.concat [
    url
  , "events?"
  , url_parameter "start" (toString start)
  , "&"
  , url_parameter "end" (toString end)
  ]

url_parameter: String -> String -> String
url_parameter name value =
  name ++ "=" ++ value

getNewData: Date.Date -> Date.Date -> Cmd Types.Msg
getNewData start end =
  let
    start_timstamp = start |> Date.toTime |> Time.inSeconds |> floor
    end_timestamp = end |> Date.toTime |> Time.inSeconds |> ceiling
  in
    Http.send
      Types.NewData
      (Http.get (url_events start_timstamp end_timestamp)
        (Json.Decode.list eventDecoder))

fetchRange: Cmd Types.Msg
fetchRange =
  Http.send Types.NewRange (Http.get (url ++ "range") rangeDecoder)
