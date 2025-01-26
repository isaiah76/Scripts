#!/bin/bash

DEVICE_NAME="Raydium Corporation Raydium Touch System"

DEVICE_ID=$(xinput list --id-only "$DEVICE_NAME")
DEVICE_ENABLED=$(xinput list-props "$DEVICE_ID" | grep "Device Enabled" | awk '{print $4}')

if [ "$DEVICE_ENABLED" -eq 1 ]; then
    echo "Disabling touchscreen..."
    xinput disable "$DEVICE_ID"
    echo "Touchscreen disabled."
else
    echo "Enabling touchscreen..."
    xinput enable "$DEVICE_ID"
    echo "Touchscreen enabled."
fi
