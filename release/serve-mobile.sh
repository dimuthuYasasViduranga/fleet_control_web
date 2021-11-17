#!/bin/bash

if [ $# -lt 1 ]; then
    echo "usage: ./release/server-mobile.sh local.ip.address"
    exit 1
fi

host=$1

dev_config="$PWD/../phx/config/dev.exs"
secret_config="$PWD/../phx/config/config.secret.exs"
main="$PWD/src/main.js"

sed -i "s/url:.*,/url: \"http:\/\/${host}:4010\",/" $dev_config
sed -i "s/  url:.*/  url: [host: \"${host}\"]/" $secret_config
sed -r -i "s/hostname = '.+';/hostname = 'http:\/\/${host}:4010';/" $main
sed -r -i "s/uiHost = '.+';/uiHost = 'http:\/\/${host}:8080';/" $main

yarn serve --host $1
