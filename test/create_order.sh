#!/bin/bash

postData=$(cat<<EOF
{
  "from": {"lat": 22.338322, "lng": 114.147328},
  "to": {"lat": 22.278156, "lng": 114.172762}
}
EOF
)

curl -v -X POST -H 'Host: orders.local' -H 'Content-Type: application/json; charset=utf-8' http://127.0.0.1/rpc/createOrder -d "$postData"
echo ""
