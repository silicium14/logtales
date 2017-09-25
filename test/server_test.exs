defmodule ServerTest do
  use ExUnit.Case
  use Plug.Test
  doctest Logtales.Server

  @router_options Logtales.Server.init([])

  test "the range response is as expected" do
    # Arrange
    start_date = DateTime.from_naive!(~N[2017-01-01 00:00:01], "Etc/UTC")
    end_date = DateTime.from_naive!(~N[2017-01-02 00:00:01], "Etc/UTC")

    # Act
    conn = 
    conn(:get, "/range")
    |> Plug.Conn.assign(:range_function, fn -> %{start: start_date, end: end_date} end)
    |> Logtales.Server.call(@router_options)

    # Assert
    assert conn.status == 200
    assert conn.resp_body == %{
      start: DateTime.to_unix(start_date),
      end: DateTime.to_unix(end_date)
    } |> Poison.encode!()
  end

  test "the events response is as expected" do
    # Arrange
    date_1 = DateTime.from_naive!(~N[2017-01-01 00:00:01], "Etc/UTC")
    date_2 = DateTime.from_naive!(~N[2017-01-02 00:00:01], "Etc/UTC")
    events = [
      %{
        date: date_1,
        item: "an item",
        content: "The content of the first event"
      },
      %{
        date: date_2,
        item: "another item",
        content: "The content of another event"
      }
    ]
    query = "/events?" <> Plug.Conn.Query.encode(%{
      start: DateTime.to_unix(date_1),
      end: DateTime.to_unix(date_2),
    })

    # Act
    conn = 
    conn(:get, query)
    |> Plug.Conn.assign(:events_function, fn _, _ -> Flow.from_enumerable(events) end)
    |> Logtales.Server.call(@router_options)

    # Assert
    assert conn.status == 200
    assert conn.resp_body == events
    |> Enum.map(fn event -> Map.update!(event, :date, &DateTime.to_unix/1) end)
    |> Poison.encode!()
  end
end
