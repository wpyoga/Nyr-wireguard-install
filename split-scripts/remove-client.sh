#!/bin/bash

# This option could be documented a bit better and maybe even be simplified
# ...but what can I say, I want some sleep too
number_of_clients=$(grep -c '^# BEGIN_PEER' /etc/wireguard/wg0.conf)
if [[ "$number_of_clients" = 0 ]]; then
	echo
	echo "There are no existing clients!"
	exit
fi
echo
echo "Select the client to remove:"
grep '^# BEGIN_PEER' /etc/wireguard/wg0.conf | cut -d ' ' -f 3 | nl -s ') '
read -p "Client: " client_number
until [[ "$client_number" =~ ^[0-9]+$ && "$client_number" -le "$number_of_clients" ]]; do
	echo "$client_number: invalid selection."
	read -p "Client: " client_number
done
client=$(grep '^# BEGIN_PEER' /etc/wireguard/wg0.conf | cut -d ' ' -f 3 | sed -n "$client_number"p)
echo
read -p "Confirm $client removal? [y/N]: " remove
until [[ "$remove" =~ ^[yYnN]*$ ]]; do
	echo "$remove: invalid selection."
	read -p "Confirm $client removal? [y/N]: " remove
done
if [[ "$remove" =~ ^[yY]$ ]]; then
	# The following is the right way to avoid disrupting other active connections:
	# Remove from the live interface
	wg set wg0 peer "$(sed -n "/^# BEGIN_PEER $client$/,\$p" /etc/wireguard/wg0.conf | grep -m 1 PublicKey | cut -d " " -f 3)" remove
	# Remove from the configuration file
	sed -i "/^# BEGIN_PEER $client/,/^# END_PEER $client/d" /etc/wireguard/wg0.conf
	echo
	echo "$client removed!"
else
	echo
	echo "$client removal aborted!"
fi
