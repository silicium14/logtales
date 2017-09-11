defmodule MnesiaTest do
  use ExUnit.Case
  alias Logtales.Db.Mnesia
  doctest Mnesia

  test "the result of the events function is as expected" do
    ### Arrange
    Mnesia.resetdb
    # Create a Flow with one event
    event = %{
      date: DateTime.from_naive!(~N[2017-01-01 00:00:01], "Etc/UTC"),
      item: "an item",
      content: "The content"
    }
    # Load into Mnesia
    Mnesia.load Flow.from_enumerable([{0, event}])

    ### Act
    result = Mnesia.events(
      DateTime.from_naive!(~N[2017-01-01 00:00:01], "Etc/UTC"),
      DateTime.from_naive!(~N[2017-01-01 00:00:01], "Etc/UTC")
    )

    ### Assert
    assert result == [event]
  end
end
