#!/usr/bin/env bash

echo "- Fetching Elixir back-end dependencies"
mix deps.get
echo "- Finished fetching Elixir back-end dependencies"

echo "- Building Elixir back-end"
mix compile
echo "- Finished building Elixir back-end"

echo "- Fetching javascript electron front-end dependencies"
yarn
echo "- Finished Fetching javascript electron front-end dependencies"

cd front
echo "- Building Elm front-end"
elm-make Main.elm --yes --warn --output main.js
echo "- Finished building Elm front-end"
cd ..
