defmodule Back.Mnesia do
  require Logger
  
  # Business
  def range() do
    {:atomic, timestamps} = :mnesia.transaction(fn ->
      :mnesia.select(Event, [{{Event, :"$1", :"$2", :"$3", :"$4"}, [], [:"$2"]}])
    end)
    %{"start" => Integer.to_string(Enum.min(timestamps)), "end" => Integer.to_string(Enum.max(timestamps))}
  end

  defp event_record_to_map([_, timestamp, item, content]) do
    %{
      "date" => DateTime.from_unix!(timestamp),
      "item" => item,
      "content" => content
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
  
  # Operational
  def resetdb() do
    Logger.debug "resetdb"
    dropdb()
    createdb()
  end
  
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

  def mnesia_event({index, event}) do
    {Event, index, Timex.to_unix(event["date"]), event["item"], event["content"]}
  end

  def load(flow) do
    Logger.debug "Loading events into Mnesia database"
    flow
    |> Flow.map(&mnesia_event/1)
    |> Flow.map(&:mnesia.dirty_write/1)
    |> Flow.run()

    Logger.debug "Adding indexes"
    :mnesia.add_table_index Event, :item
    :mnesia.add_table_index Event, :timestamp
  end
end
