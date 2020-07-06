#!/bin/bash

# apt stuff
echo "-------------------------------"
echo "Updating stuff APT"
echo "-------------------------------"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y
apt-get install -y apt-transport-https bash-completion htop ca-certificates curl software-properties-common gnupg2