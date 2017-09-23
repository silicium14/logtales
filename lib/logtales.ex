defmodule Logtales do
  use Application

  @file_ Application.get_env(:logtales, :file)
  @regex Application.get_env(:logtales, :regex)
  @date_format Application.get_env(:logtales, :date_format)

  require Logger

  @doc """
  Retrieves events that happened between start and end
  """
  @spec events(start :: DateTime.t, end_ :: DateTime.t, database :: module()) :: Enum.t
  def events(start, end_, database \\ Logtales.Db.Mnesia) do
    database.events(start, end_)
  end

  @spec range(database :: module()) :: %{ start: DateTime.t, end: DateTime.t }
  def range(database \\ Logtales.Db.Mnesia) do
    database.range()
  end

  @doc """
  Convert file lines to events and insert them into the database
  """
  @spec load(file :: String.t, regex :: Regex.t, date_format :: String.t, database :: module()) :: :ok
  def load(file \\ @file_, regex \\ @regex, date_format \\ @date_format, database \\ Logtales.Db.Mnesia) do
    database.resetdb

    flow = File.stream!(file, [:utf8, :read])
    |> Stream.transform(0, fn event, index -> {[{index, event}], index+1} end)  # Enumerate lines
    |> Flow.from_enumerable()
    |> Flow.map(fn string -> Regex.named_captures(regex, string) end |> keep_index())  # Parse log line with regex
    |> Flow.filter(fn {_, result_of_match} -> not is_nil(result_of_match) end)  # Keep only successful regex matches
    |> Flow.map(keep_index(&atomize_map_keys/1))  # Convert event map keys from string to atoms
    |> Flow.map(fn event -> parse_event_date(event, date_format) end |> keep_index())  # Convert date field from string to date type

    Logger.debug "Loading events from file #{file}"
    {duration, _} = :timer.tc(database, :load, [flow])
    Logger.debug "Loading finished in #{duration / 1_000_000} s"
    :ok
  end
  
  defp keep_index(function) do
    fn {index, value} -> {index, function.(value)} end
  end

  defp atomize_map_keys(map) do
    for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}
  end

  defp parse_event_date(event, date_format) do
    event
    |> Map.update!(:date, fn str -> Timex.parse str, date_format end)
    |> Map.update!(:date, fn {:ok, date} -> date end)
  end

  def start(_type, _args) do
    r = Logtales.Server.start
    Logger.info("Logtales started")
    r
  end
end
