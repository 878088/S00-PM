#!/bin/bash

if pgrep -f s5 > /dev/null; then
    echo "s5 is already running."
else
    screen -dmS s5 ./.s5/s5 -c .s5/config.json
    echo "Screen session created and s5 is running."
fi
