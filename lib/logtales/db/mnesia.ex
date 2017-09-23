defmodule Logtales.Db.Mnesia do
  @behaviour Logtales.Db
  require Logger

  def resetdb() do
    Logger.debug "resetdb"
    dropdb()
    {:atomic, :ok} = createdb()
    :ok
  end

  @doc """
  Loads events in the Mnesia database.
  The argument is a Flow of events with and index:
  [
    {0, %{date: DateTime.t, item: String.t, content: String.t}},
    {1, %{date: DateTime.t, item: String.t, content: String.t}},
    ...
  ]
  The only constraint on indexes are uniqueness.
  """
  def load(events) do
    Logger.debug "Loading events into Mnesia database"
    events
    |> Flow.map(&mnesia_event/1)
    |> Flow.map(&:mnesia.dirty_write/1)
    |> Flow.run()

    Logger.debug "Adding indexes"
    :mnesia.add_table_index Event, :item
    :mnesia.add_table_index Event, :timestamp
    :ok
  end

  def range() do
    {:atomic, timestamps} = :mnesia.transaction(fn ->
      :mnesia.select(Event, [{{Event, :"$1", :"$2", :"$3", :"$4"}, [], [:"$2"]}])
    end)
    %{
      start: timestamps |> Enum.min() |> Timex.from_unix(),
      end: timestamps |> Enum.max() |> Timex.from_unix()
    }
  end

  def events(start, end_) do
    {:atomic, values} = :mnesia.transaction(fn ->
      :mnesia.select(
        Event,
        [{
          {Event, :"$1", :"$2", :"$3", :"$4"},
          [
            {:and, 
            {:">=", :"$2", DateTime.to_unix(start)},
            {:"=<", :"$2", DateTime.to_unix(end_)}}
          ],
          [:"$$"]
        }]
        )
    end)
    values
    |> Enum.map(&event_record_to_map/1)
  end

  # Supplementary functions that are not part of the behaviour
  def dropdb() do
    :stopped = :mnesia.stop
    :ok = :mnesia.delete_schema [node()]
  end
  
  def createdb() do
    :stopped = :mnesia.stop    
    :ok = :mnesia.create_schema [node()]
    :ok = :mnesia.start
    {:atomic, :ok} = :mnesia.create_table(
      Event,
      [
        attributes: [:id, :timestamp, :item, :content],
        disc_only_copies: [node()]
      ]
    )
  end

  # Private functions
  defp mnesia_event({index, event}) do
    {Event, index, Timex.to_unix(event[:date]), event[:item], event[:content]}
  end

  defp event_record_to_map([_, timestamp, item, content]) do
    %{
      :date => DateTime.from_unix!(timestamp),
      :item => item,
      :content => content
    }
  end
end
