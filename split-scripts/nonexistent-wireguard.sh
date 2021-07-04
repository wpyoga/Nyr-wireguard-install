#!/bin/bash

clear
echo 'Welcome to this WireGuard road warrior installer!'
# @MERGE
. split-scripts/choose-ip.sh
# @MERGE
. split-scripts/choose-port.sh
# @MERGE
. split-scripts/choose-client-name.sh
echo
new_client_dns
# @MERGE
. split-scripts/boringtun-autoupdate-ask.sh
echo
echo "WireGuard installation is ready to begin."
# @MERGE
. split-scripts/firewall-install.sh
read -n1 -r -p "Press any key to continue..."
# @MERGE
. split-scripts/install-wireguard.sh
# @MERGE
. split-scripts/firewalld-enable.sh
# @MERGE
. here-documents/wg0.conf.sh
# @MERGE
. split-scripts/firewall-configure-forwarding.sh
# Generates the custom client.conf
new_client_setup
# Enable and start the wg-quick service
systemctl enable --now wg-quick@wg0.service
# @MERGE
. split-scripts/boringtun-autoupdate-config.sh
echo
qrencode -t UTF8 < ~/"$client.conf"
echo -e '\xE2\x86\x91 That is a QR code containing the client configuration.'
echo
# @MERGE
. split-scripts/wireguard-kernel-module-check.sh
echo
echo "The client configuration is available in:" ~/"$client.conf"
echo "New clients can be added by running this script again."
