defmodule Back do
  @file_ Application.get_env(:back, :file)
  @regex Application.get_env(:back, :regex)
  @date_format Application.get_env(:back, :date_format)

  require Logger

  # Business
  def events(start, end_) do
    Back.Mnesia.events(start, end_)
  end

  def range() do
    Back.Mnesia.range()
  end
  
  # Loading file
  def filter_flow({_, event}) when event == nil, do: false
  def filter_flow(_), do: true

  def parse_event_date(event) do
    event
    |> Map.update!("date", fn str -> Timex.parse str, @date_format end)
    |> Map.update!("date", fn {:ok, date} -> date end)
  end

  def keep_index({index, value}, function) do
    {index, function.(value)}
  end

  def load() do
    Back.Mnesia.resetdb

    flow = File.stream!(@file_, [:utf8, :read])
    |> Stream.transform(0, fn event, index -> {[{index, event}], index+1} end)
    |> Flow.from_enumerable()
    |> Flow.map(&keep_index(&1, fn string -> Regex.named_captures(@regex, string) end))
    |> Flow.filter(&filter_flow/1)
    |> Flow.map(fn event -> keep_index(event, &parse_event_date/1) end)

    {duration, _} = :timer.tc(Back.Mnesia, :load, [flow])
    Logger.debug "Loading finished in #{duration / 1_000_000} s"
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
end
