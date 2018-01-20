use Mix.Config

config :logger, backends: [:console]

# file: the path of the log file
# regex: a regex used for parsing and filtering log events.
#   It must have the three named capture groups date, item and content.
# date_format: the Timex format to use to parse dates captured by the `regex`.
#   see Timex.Format.DateTime.Formatters.Default
config :logtales,
  file: "nasa_ksc_www_Jul95_subset.log",
  regex: ~r/^.*\[(?<date>[^\s]+).*\] (?<content>[^\/]+(?<item>\/[^\/\s]*).*)/,
  date_format: "{0D}/{Mshort}/{YYYY}:{h24}:{m}:{s}"

config :mnesia,
  dump_log_write_threshold: 100000,
  dir: 'mnesia/#{Mix.env}'

config :eye_drops, 
  tasks: [
    %{
      id: :compile_frontend,
      name: "Compile front-end",
      run_on_start: false,
      cmd: "cd front; elm-make Main.elm --yes --warn --output main.js",
      paths: ["front/*.elm"]
    }
  ]
