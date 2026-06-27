#!/bin/bash
# Double-click this file to run ChoiceForge locally, then it opens in your browser.
cd "$(dirname "$0")"
PORT=8011
echo "Starting ChoiceForge at http://localhost:$PORT  (press Ctrl+C to stop)"
( sleep 1 && open "http://localhost:$PORT" ) &
python3 -m http.server $PORT
