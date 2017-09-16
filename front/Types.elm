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

-- MESSAGES
type Msg =
  Fetch
  | NewData (Result Http.Error (List Event))
  | FetchRange
  | NewRange (Result Http.Error Range)
  | ToggleLabels
  | Hover (Maybe Event)
  | SliderMove String
  | SliderCommit String