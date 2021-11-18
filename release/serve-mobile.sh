#!/bin/bash

has_device=false
while read line; do
    if [[ "$line" != "List of devices attached" ]]; then
        has_device=true
    fi
done <<< $(adb devices)

if [[ $has_device == false ]]; then
    echo "Could not find any connected devices"
    echo "- ensure that USB connection is set to USB tethering only"
    exit 1
fi

echo -e '\033[44m' "Mapping 4010 -> 4010" '\033[0m'
adb reverse tcp:4010 tcp:4010 
echo -e '\033[44m' "Mapping 8080 -> 8080" '\033[0m'
adb reverse tcp:8080 tcp:8080
echo "Connect to localhost:8080 on your phone"
echo "Open chrome to 'chrome://inspect/#devices' to inspect your device"
echo
yarn serve --host localhost --port 8080