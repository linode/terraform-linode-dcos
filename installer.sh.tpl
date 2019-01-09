#!/usr/bin/env bash
mkdir /tmp/dcos && cd /tmp/dcos
printf "Waiting for installer to appear at Bootstrap URL"
until $(curl -m 2 --connect-timeout 2 --output /dev/null --silent --head --fail http://${bootstrap}:4040/dcos_install.sh); do
    sleep 1
done
curl -O http://${bootstrap}:4040/dcos_install.sh
sudo bash dcos_install.sh $1
