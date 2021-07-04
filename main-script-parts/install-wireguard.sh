#!/bin/bash

clear
echo 'Welcome to this WireGuard road warrior installer!'
# @MERGE
. split-scripts/choose-ip.sh
# @MERGE
. split-scripts/choose-port.sh
# @MERGE
. split-scripts/choose-client-name.sh
# @MERGE
. split-scripts/choose-dns.sh
# Set up automatic updates for BoringTun if the user is fine with that
if [[ "$is_container" -eq 0 ]]; then
	# @MERGE
	. split-scripts/ask-boringtun-autoupdate.sh
fi
echo
echo "WireGuard installation is ready to begin."
# @MERGE
. split-scripts/determine-firewall.sh
read -n1 -r -p "Press any key to continue..."
# Install WireGuard
# If not running inside a container, set up the WireGuard kernel module
if [[ ! "$is_container" -eq 0 ]]; then
	# @MERGE
	. split-scripts/install-normal-dependencies.sh
# Else, we are inside a container and BoringTun needs to be used
else
	# @MERGE
	. split-scripts/install-container-dependencies.sh
fi
# @MERGE
. split-scripts/enable-firewalld.sh
# @MERGE
. split-scripts/generate-server-config.sh
# @MERGE
. split-scripts/configure-ip-forwarding.sh
# @MERGE
. split-scripts/generate-client-config.sh
# @MERGE
. split-scripts/start-wireguard-service.sh
# @MERGE
. split-scripts/configure-boringtun-autoupdate.sh
# @MERGE
. split-scripts/show-qr.sh
# @MERGE
. split-scripts/check-wireguard-kernel-module.sh
echo
echo "The client configuration is available in:" ~/"$client.conf"
echo "New clients can be added by running this script again."
