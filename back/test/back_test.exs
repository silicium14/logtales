defmodule BackTest do
  use ExUnit.Case
  doctest Back

  test "Events are retrieved after being loaded into database" do
    # TODO : use a different mnesia directory for testing
    # Arrange
    Back.load(
      "test/fake_log.txt",
      ~r/^\[(?<date>\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\] \[(?<item>[^\]]+)\] (?<content>.*)/,
      "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"
    )

    # Act
    events = Back.events(
      DateTime.from_naive!(~N[2017-01-01 00:00:01], "Etc/UTC"),
      DateTime.from_naive!(~N[2017-01-01 02:00:00], "Etc/UTC")
    )

    # Assert
    assert MapSet.new(events) == MapSet.new([
      %{
        "date" => DateTime.from_naive!(~N[2017-01-01 00:00:01], "Etc/UTC"),
        "item" => "an item", "content" => "This is the first event"
      },
      %{
        "date" => DateTime.from_naive!(~N[2017-01-01 00:01:00], "Etc/UTC"),
        "item" => "another item", "content" => "This is the second event"
      },
      %{
        "date" => DateTime.from_naive!(~N[2017-01-01 02:00:00], "Etc/UTC"),
        "item" => "an item", "content" => "This is the third event"
      }
    ])
  end
end
