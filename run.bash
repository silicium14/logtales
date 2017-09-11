#!/usr/bin/env bash

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