use Mix.Config

config :logger, backends: [:console]

# file: the path of the log file
# regex: a regex used for parsing and filtering log events.
#   It must have the three named capture groups date, item and content.
# date_format: the Timex format to use to parse dates captured by the `regex`.
config :logtales,
  file: "../tmp/example.log",
  regex: ~r/^\[(?<date>\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\] \[(?<item>[^\]]+)\] (?<content>.*)/,
  date_format: "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"

config :mnesia,
  dump_log_write_threshold: 100000,
  dir: 'mnesia/#{Mix.env}'
