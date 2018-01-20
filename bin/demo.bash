#!/usr/bin/env bash

# Fetches backend dependences
# Resets the database, loads the configured log file
# and starts the application

bin/build.bash

echo "- Parsing log file and loading events into database"
mix load
echo "- Finished parsing and loading"

bin/run.bash
