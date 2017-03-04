#!/usr/bin/env bash

prodServiceFileName="polymyrd.service.txt"
prodServiceName="polymyrd.service"

destinationPath="/etc/systemd/system/"

sudo cp "$prodServiceFileName" "$destinationPath$prodServiceName"
sudo chmod 664 "$destinationPath$prodServiceName"

systemctl daemon-reload
systemctl restart "$prodServiceName"
