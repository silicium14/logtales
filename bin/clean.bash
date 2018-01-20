#!/usr/bin/env bash

# This script removes all application generated files
# included the databases

echo "Cleaning Elixir generated files"
mix clean --deps
echo "Removing databases"
rm -r mnesia/*
echo "Removing Elm generated files"
rm -r front/elm-stuff
rm -r loading_page/elm-stuff
echo "Removing node generated files"
rm -r node_modules
