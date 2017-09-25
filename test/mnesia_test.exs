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
    ) |> Enum.to_list()

    ### Assert
    assert result == [event]
  end

  test "the events are filtered by range" do
    ### Arrange
    Mnesia.resetdb
    event_in_range = %{
      date: DateTime.from_naive!(~N[2017-01-01 00:00:01], "Etc/UTC"),
      item: "an item",
      content: "The content"
    }
    event_out_of_range = %{
      date: DateTime.from_naive!(~N[2017-01-02 00:00:01], "Etc/UTC"),
      item: "an item",
      content: "The content"
    }
    # Load into Mnesia
    Mnesia.load Flow.from_enumerable([{0, event_in_range}, {1, event_out_of_range}])

    ### Act
    result = Mnesia.events(
      DateTime.from_naive!(~N[2017-01-01 00:00:00], "Etc/UTC"),
      DateTime.from_naive!(~N[2017-01-01 10:00:00], "Etc/UTC")
    ) |> Enum.to_list()

    ### Assert
    assert result == [event_in_range]
  end
end
