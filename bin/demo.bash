#!/usr/bin/env bash

# Resets the database, loads the configured log file
# and starts the application
cd back
mix deps.get
mix load
cd ..
bin/run.bash
