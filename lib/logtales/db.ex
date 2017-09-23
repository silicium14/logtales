defmodule Logtales.Db do
  @callback resetdb() :: :ok
  @callback load(events :: Flow.t) :: :ok
  @callback range() :: %{ start: DateTime.t, end: DateTime.t }
  @callback events(start :: DateTime.t, end_ :: DateTime.t) :: Enum.t
end
