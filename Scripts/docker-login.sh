#!/bin/bash
echo "$1" | /usr/local/bin/docker  --config /tmp/.docker  login "$2" --username "$3" --password-stdin

