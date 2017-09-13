#!/usr/bin/env bash

# This script removes all application generated files
# included the database

cd back
echo "Cleaning Elixir generated files"
mix deps.clean --all
echo "Removing databases"
rm -r mnesia/*
cd ..
echo "Removing Elm generated files"
rm -r front/elm-stuff
