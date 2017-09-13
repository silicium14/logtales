#!/usr/bin/env bash

# Starts the elixir backend, the elm frontend (elm-reactor)
# and opens the application URL

cd back
mix run --no-halt &
BACK_PID=$!
cd ..

cd front
elm-reactor &
FRONT_PID=$!

platform=$(uname)
if [[ "$platform" == 'Linux' ]]; then
    xdg-open http://localhost:8000/Main.elm
elif [[ "$platform" == 'Darwin' ]]; then
    open http://localhost:8000/Main.elm
fi

wait $BACK_PID
wait $FRONT_PID