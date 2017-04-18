#!/usr/bin/env bash

reset_production_server() {

	local prodServiceFileName="polymyrd.service.txt"
	local prodServiceName="polymyrd.service"
	local destinationPath="/etc/systemd/system/"

	echo "\n>>>> sudo cp $prodServiceFileName $destinationPath$prodServiceName"
	sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"

	echo "\n>>>> sudo chmod 664 $destinationPath$prodServiceName"
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "\n>>>> sudo systemctl daemon-reload"
	sudo systemctl daemon-reload
}

reset_development_server() {

	local prodServiceFileName="dev-polymyrd.service.txt"
	local prodServiceName="dev-polymyrd.service"
	local destinationPath="/etc/systemd/system/"

	echo "\n>>>> sudo cp $prodServiceFileName $destinationPath$prodServiceName"
	sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"

	echo "\n>>>> sudo chmod 664 $destinationPath$prodServiceName"
	sudo chmod 664 "$destinationPath$devServiceName"

	echo "\n>>>> sudo systemctl daemon-reload"
	sudo systemctl daemon-reload
}

CURRENT_GIT_SHA="$(git rev-parse HEAD)"

echo "\n>>>> git pull origin"
git pull origin

if [ "$(git diff --name-only $CURRENT_GIT_SHA HEAD -- nginx/)" ]; then
	echo "    \n>>>> sudo cp -ru nginx/* /etc/nginx/"
	sudo cp -ru nginx/* /etc/nginx/

	echo "    >>>> sudo systemctl restart nginx"
	sudo systemctl restart nginx
fi

if [ "$(git rev-parse --abbrev-ref HEAD)" = "master" ]; then
	echo "\n>>>> vapor build --release=true --fetch=false --verbose"
	vapor build --release=true --fetch=false --verbose

	if [ "$(git diff --name-only $CURRENT_GIT_SHA HEAD -- polymyrd.service.txt)" ]; then
    	echo "    \n>>>> Detected changes in production server configuration files!"
		reset_production_server
	fi

	echo "\n>>>> sudo systemctl restart polymyrd.service"
	sudo systemctl restart polymyrd.service
else
	echo "\n>>>> vapor build --release=false --fetch=false --verbose"
	vapor build --release=false --fetch=false --verbose

	if [ "$(git diff --name-only $CURRENT_GIT_SHA HEAD -- polymyrd.service.txt)" ]; then
    	echo "    \n>>>> Detected changes in development server configuration files!"
		reset_development_server
	fi

	echo "\n>>>> sudo systemctl restart dev-polymyrd.service"
	sudo systemctl restart dev-polymyrd.service
fi




