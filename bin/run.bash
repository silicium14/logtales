#!/usr/bin/env bash

# Compiles the elm frontend and starts the backend server (that serves the frontend)

set -e

cd front
echo "- Building front-end"
elm-make Main.elm --yes --warn --output app.html
echo "- Finished building front-end"
cd ..

yarn start
