#!/bin/bash

NAME="screen"

if screen -list | grep -q screen; then
    echo "Screen session screen is already running."
else
    screen -dmS screen ./.s5/s5 -c .s5/config.json
    echo "Screen session screen created and command is running."
fi
