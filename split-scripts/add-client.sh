#!/bin/bash

echo
echo "Provide a name for the client:"
read -p "Name: " unsanitized_client
# Allow a limited set of characters to avoid conflicts
client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
while [[ -z "$client" ]] || grep -q "^# BEGIN_PEER $client$" /etc/wireguard/wg0.conf; do
	echo "$client: invalid name."
	read -p "Name: " unsanitized_client
	client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
done
echo
new_client_dns
new_client_setup
# Append new client configuration to the WireGuard interface
wg addconf wg0 <(sed -n "/^# BEGIN_PEER $client/,/^# END_PEER $client/p" /etc/wireguard/wg0.conf)
echo
qrencode -t UTF8 < ~/"$client.conf"
echo -e '\xE2\x86\x91 That is a QR code containing your client configuration.'
echo
echo "$client added. Configuration available in:" ~/"$client.conf"
