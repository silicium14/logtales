module Types exposing (..)

import Date
import Http 

-- DATA TYPES
type alias Event =
  {
    item : String
  , date : Date.Date
  , content: String
  }

type alias Range =
  { start:  Date.Date, end: Date.Date }

type RangeWidthUnit = Seconds | Minutes | Hours | Days

-- MESSAGES
type Msg =
  Fetch 
  | NewData (Result Http.Error (List Event))
  | FetchRange
  | NewRange (Result Http.Error Range)
  | ToggleLabels
  | Hover (Maybe Event)
  | SliderMove Date.Date
  | SliderCommit Date.Date
  | RangeWidthEdit String
  | RangeWidthCommit (Result String Int)
  | RangeUnitCommit RangeWidthUnit