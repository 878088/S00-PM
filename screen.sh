#!/bin/bash

NAME="screen"

if screen -list | grep -q "$NAME"; then
    echo "Screen session $NAME is already running."
else
    screen -dmS $NAME ./.s5/s5 -c config.json
    echo "Screen session $NAME created and command is running."
fi
