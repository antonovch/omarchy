#!/bin/bash

if pgrep -x hypridle >/dev/null ; then
    echo '{"text": "", "class": "active", "tooltip": "Screen locking active\nLeft: Deactivate\nRight: Lock Screen"}'
else
    echo '{"text": "󱫖", "class": "notactive", "tooltip": "Screen locking deactivated\nLeft: Activate\nRight: Lock Screen"}'
fi
