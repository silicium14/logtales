defmodule Back.Db do
  @callback resetdb() :: none()  
  @callback load(events :: Flow.t) :: none()
  @callback range() :: map()
  @callback events(start :: DateTime.t, end_ :: DateTime.t) :: Enum.t
end
