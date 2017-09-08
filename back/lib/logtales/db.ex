defmodule Logtales.Db do
  @callback resetdb() :: none()  
  @callback load(events :: Flow.t) :: none()
  @callback range() :: %{ start: DateTime.t, end: DateTime.t }
  @callback events(start :: DateTime.t, end_ :: DateTime.t) :: Enum.t
end
