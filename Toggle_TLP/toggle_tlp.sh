#!/bin/bash

# file path to tlp.conf
TLP_CONF="/etc/tlp.conf"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [on|off]"
  exit 1
fi

# enable charging thresholds
enable_thresholds() {
  sudo sed -i 's/^#\?START_CHARGE_THRESH_BAT0=.*/START_CHARGE_THRESH_BAT0=0/' $TLP_CONF
  sudo sed -i 's/^#\?STOP_CHARGE_THRESH_BAT0=.*/STOP_CHARGE_THRESH_BAT0=100/' $TLP_CONF
  echo "Battery charging thresholds enabled: START=0, STOP=100"
}

# disable charging thresholds
disable_thresholds() {
  sudo sed -i 's/START_CHARGE_THRESH_BAT0=.*/#START_CHARGE_THRESH_BAT0=75/' $TLP_CONF
  sudo sed -i 's/STOP_CHARGE_THRESH_BAT0=.*/#STOP_CHARGE_THRESH_BAT0=80/' $TLP_CONF
  echo "Battery charging thresholds disabled"
}

if [[ "$1" == "on" ]]; then
  enable_thresholds
elif [[ "$1" == "off" ]]; then
  disable_thresholds
else
  echo "Invalid argument. Use 'on' to enable and 'off' to disable."
  exit 1
fi

sudo systemctl restart tlp

