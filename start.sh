#!/usr/bin/env bash

while getopts "e:f:d:" opt; do
    case $opt in
      e) environment="$OPTARG"
      ;;
      f) pidFile="$OPTARG"
    esac
done

if [ -z "$environment" ]; then
    printf "No environment was provided. Provde one with -e."
    exit
fi

if [ -z "$pidFile" ]; then
    printf "No pidFile was provided. Provide one with -f."
    exit
fi

sudo rm "$pidFile"
sudo touch "$pidFile"

DIR="$(dirname "${BASH_SOURCE[0]}")"
"$DIR"/.build/release/App --env="$environment" & echo $! > "$pidFile"
