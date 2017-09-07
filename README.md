# Logtales

Logtales lets you visualize log events grouped per item on a timeline. Let it tell you the tales of your application, found in their logs.

## Dependencies
- Elixir 1.5, see `back/mix.exs` for packages
- Elm 0.18, see `front/elm-package.json` for packages

## How to use
- Configure the backend (see Configure section)
- Start the backend and the frontend (see Run in development mode section)
- Load log file into database (see Load the log file into database section)
- Open http://localhost:8000
- Click on `Fetch range` to get available date range
- Click on `Fetch data` to get events and plot them

## Configure
- Set the `file` value in the `:logtales` config in `back/config/config.exs` to the path of your log file
- Set the `regex` value in the `:logtales` config in `back/config/config.exs`. This is an elixir regex that *must* contain three named capture groups: date, item and content. It is used for both filtering log events and finding the date, item and content of event that will be displayed. For example, for a log whose lines are like
```
[2017-01-01 23:00:00] [an item] blah blah blah
[2017-01-02 00:05:00] [another item] blah blah blah
[2017-01-02 00:05:00] [an item] blah blah blah
```
the regex may be
```
~r/^\[(?<date>\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\] \[(?<item>[^\]]+)\] (?<content>.*)/
```
The item can be anything meaningful for you to group events when plotting them on a timeline. Events of the same item will be displayed on one line, there will be one line per item. For example if your logs are authentication logs and the application prints some events with a username in it, you can use the username as item. As a result there will be one line per username on the timeline plot.
- Set the `date_format` value in the `:logtales` config in `back/config/config.exs` to the [Timex format](https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html#content) to use to parse dates captured by the `regex`.

## Run in development mode
Open one terminal for the backend
```
cd back
# only the first time
mix deps.get

iex -S mix
# in IEx
Logtales.Server.start
```
The backend server should be running at http://localhost:4000.

Open one terminal for the frontend
```
cd front
elm-reactor
```
The frontend should be available at http://localhost:8000.

## Load the log file into database
In IEx console: `Logtales.load`

## Run the tests
### Backend
```bash
cd back
mix test
```
