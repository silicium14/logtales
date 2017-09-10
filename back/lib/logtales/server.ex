defmodule Logtales.Server do
    @moduledoc """
    Documentation for Logtales.Server.
    """

    require Logger
    use Plug.Router
  
    plug Plug.Logger, log: :debug
    plug :match
    plug :dispatch
  
    get "/" do
      resp(conn, 200, "API Running")
    end
  
    get "/events" do
      conn = Plug.Conn.fetch_query_params(conn)
      start = unixSecondsStringToDate(conn.query_params["start"])
      end_ = unixSecondsStringToDate(conn.query_params["end"])
      Logger.debug "start: #{start}, end: #{end_}"
      events_function = conn.assigns[:events_function] || &Logtales.events/2
      events_function.(start, end_)
      |> Enum.map(&date_to_unix(&1))
      |> json_response(conn)
    end

    get "/range" do
      range_function = conn.assigns[:range_function] || &Logtales.range/0
      range_function.()
      |> Map.to_list()
      |> Enum.reduce(
        %{},
        fn {key, date}, acc ->
          acc |> Map.put(key, DateTime.to_unix(date))
        end
      )
      |> json_response(conn)
    end
  
    match _ do
      resp(conn, 404, "Not found")
    end

    def json_response(data, conn) do
      Logger.debug(inspect(data))
      data
      |> Poison.encode!
      |> (
        fn data -> resp(
          Plug.Conn.put_resp_header(conn, "access-control-allow-origin", "*"),
          200, data
        ) end
      ).()
    end
    
    def unixSecondsStringToDate(string) do
      {seconds, _} = Integer.parse(string)
      DateTime.from_unix!(seconds)
    end

    def date_to_unix(event_map) do
      Map.update!(
        event_map, :date,
        fn date -> date |> DateTime.to_unix() end
      )
    end

    def restart do
      Plug.Adapters.Cowboy.shutdown __MODULE__.HTTP
      :ok = :mnesia.start
      Plug.Adapters.Cowboy.http __MODULE__, []
    end

    def start do
      :ok = :mnesia.start
      Plug.Adapters.Cowboy.http __MODULE__, []
    end
  end
