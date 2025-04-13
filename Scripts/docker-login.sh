#!/bin/bash
echo "$1" | /usr/local/bin/docker login "$2" --username "$3" --password-stdin

