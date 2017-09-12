#!/usr/bin/env bash

cd back
mix deps.clean --all
rm -r mnesia/*
cd ..
rm -r front/elm-stuff
