defmodule Logtales do
  use Application

  @file_ Application.get_env(:logtales, :file)
  @regex Application.get_env(:logtales, :regex)
  @date_format Application.get_env(:logtales, :date_format)

  require Logger

  def events(start, end_, database \\ Logtales.Db.Mnesia) do
    database.events(start, end_)
  end

  def range(database \\ Logtales.Db.Mnesia) do
    database.range()
  end

  def load(file \\ @file_, regex \\ @regex, date_format \\ @date_format, database \\ Logtales.Db.Mnesia) do
    database.resetdb

    flow = File.stream!(file, [:utf8, :read])
    |> Stream.transform(0, fn event, index -> {[{index, event}], index+1} end)
    |> Flow.from_enumerable()
    |> Flow.map(fn {index, string} -> {index, Regex.named_captures(regex, string)} end)
    |> Flow.filter(&filter_flow/1)
    |> Flow.map(fn {index, event} -> {index, atomize_map_keys(event)} end)
    |> Flow.map(fn {index, event} -> {index, parse_event_date(event, date_format)} end)

    Logger.debug "Loading events from file #{file}"
    {duration, _} = :timer.tc(database, :load, [flow])
    Logger.debug "Loading finished in #{duration / 1_000_000} s"
  end
  
  defp filter_flow({_, event}) when event == nil, do: false
  defp filter_flow(_), do: true

  defp atomize_map_keys(map) do
    for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}
  end

  defp parse_event_date(event, date_format) do
    event
    |> Map.update!(:date, fn str -> Timex.parse str, date_format end)
    |> Map.update!(:date, fn {:ok, date} -> date end)
  end

  # Benchmarking
  def bench(function, args \\ []) do
    IO.puts "Executing code"
    {time, _} = :timer.tc(__MODULE__, function, args)
    seconds = time / 1_000_000
    {:ok, %File.Stat{size: bytes}} = File.stat @file_
    IO.puts "Counting lines in file"
    lines = File.stream!(@file_, [:utf8, :read]) |> Enum.count
    %{
      time: seconds,
      size: bytes,
      bytes_per_second: Float.round(bytes/seconds),
      lines: lines,
      lines_per_second: Float.round(lines/seconds)
    }
  end

  def start(_type, _args) do
    Logtales.load
    r = Logtales.Server.start
    Logger.info("Logtales started")
    r
  end
end
