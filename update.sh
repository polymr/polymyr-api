#!/usr/bin/env bash

reset_production_server() {

	local prodServiceFileName="polymyrd.service.txt"
	local prodServiceName="polymyrd.service"
	local destinationPath="/etc/systemd/system/"

	echo "\n>>>> sudo cp $prodServiceFileName $destinationPath$prodServiceName"
	sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"

	echo "\n>>>> sudo chmod 664 $destinationPath$prodServiceName"
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "\n>>>> systemctl daemon-reload"
	systemctl daemon-reload

	echo "\n>>>> systemctl restart $prodServiceName"
	systemctl restart "$prodServiceName"
}

echo "\n>>>> git pull origin master"
git pull origin master

if [[ $(git diff --name-only HEAD~ HEAD -- nginx/) ]]; then
	echo "\n>>>> sudo cp -ru nginx/* /etc/nginx/"
	sudo cp -ru nginx/* /etc/nginx/
fi

echo "\n>>>> vapor build --release=true --fetch=false"
vapor build --release=true --fetch=false

echo "\n>>>> sudo systemctl restart polymyrd.service"
sudo systemctl restart polymyrd.service

if [[ $(git diff --name-only HEAD~1 HEAD -- polymyrd.service.txt) ]]; then
    echo "\n>>>> Detected changes in production server configuration files!"
	reset_production_server
fi
