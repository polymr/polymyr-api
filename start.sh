#!/usr/bin/env bash

while getopts "e:f:d:" opt; do
  	case $opt in
    	e) config="$OPTARG"
    	;;
     	f) pidFile="$OPTARG"
     	;;
     	d) projectFolder="$OPTARG"
  	esac
done

configs=("development" "release")

function printConfigs {
	for item in ${configs[*]}; do
    	printf "%s " "$item"
	done
}

if [ -z "$config" ]; then
  	printf "No environment was provided. Provde one with -e. Valid values are "
  	printConfigs
  	printf "\n"
  	exit
fi

if [ -z "$pidFile" ]; then
    printf "No pidFile was provided."
    exit
fi

if [ -z "$projectFolder" ]; then
    printf "No projectFolder was provided."
    exit
fi

if [[ ! " ${configs[@]} " =~ " ${config} " ]]; then
	printf "Invalid environment. Valid values are "
	printConfigs
	printf "\n"
fi

sudo rm "$pidFile"
sudo touch "$pidFile"

cd "$projectFolder" || exit

.build/"$config"/App & echo $! > "$pidFile"
