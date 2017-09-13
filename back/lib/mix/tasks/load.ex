defmodule Mix.Tasks.Load do
  use Mix.Task

  @shortdoc "Resets the existing database and reloads log file"
  def run(_args) do
    Logtales.load
  end
end
