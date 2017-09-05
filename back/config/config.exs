use Mix.Config

config :logger, backends: [:console]

# file: the path of the log file
# regex: a regex used for parsing and filtering log events.
#   It must have the three named capture groups date, item and content.
config :back,
  file: "../tmp/events.log",
  regex: ~r/^\[(?<date>\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\] \[(?<item>[^\]]+)\] (?<content>.*)/,
  date_format: "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"

config :mnesia,
  dump_log_write_threshold: 100000
