#!/bin/bash

if [ -e /dev/video0 ]; then
    mpv /dev/video0
else
    echo "Camera not found!"
fi

