#!/usr/bin/env bash

# Starts the elixir backend, the elm frontend (elm-reactor)
# and opens the application URL

set -e

cd front
echo "- Building front-end"
elm-make Main.elm --yes --warn --output app.html
echo "- Finished building front-end"
cd ..

mix run --no-halt
