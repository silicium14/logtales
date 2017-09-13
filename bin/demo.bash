#!/usr/bin/env bash

# Fetches backend dependences
# Resets the database, loads the configured log file
# and starts the application

cd back
mix deps.get
cd ..
bin/load.bash
bin/run.bash
