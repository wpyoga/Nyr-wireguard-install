#!/bin/bash

# If system has a single IPv4, it is selected automatically. Else, ask the user
if [[ $(ip -4 addr | grep inet | grep -vEc '127(\.[0-9]{1,3}){3}') -eq 1 ]]; then
	ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')
else
	number_of_ip=$(ip -4 addr | grep inet | grep -vEc '127(\.[0-9]{1,3}){3}')
	echo
	echo "Which IPv4 address should be used?"
	ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | nl -s ') '
	read -p "IPv4 address [1]: " ip_number
	until [[ -z "$ip_number" || "$ip_number" =~ ^[0-9]+$ && "$ip_number" -le "$number_of_ip" ]]; do
		echo "$ip_number: invalid selection."
		read -p "IPv4 address [1]: " ip_number
	done
	[[ -z "$ip_number" ]] && ip_number="1"
	ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n "$ip_number"p)
fi
# If $ip is a private IP address, the server must be behind NAT
if echo "$ip" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
	echo
	echo "This server is behind NAT. What is the public IPv4 address or hostname?"
	# Get public IP and sanitize with grep
	get_public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")
	read -p "Public IPv4 address / hostname [$get_public_ip]: " public_ip
	# If the checkip service is unavailable and user didn't provide input, ask again
	until [[ -n "$get_public_ip" || -n "$public_ip" ]]; do
		echo "Invalid input."
		read -p "Public IPv4 address / hostname: " public_ip
	done
	[[ -z "$public_ip" ]] && public_ip="$get_public_ip"
fi
# If system has a single IPv6, it is selected automatically
if [[ $(ip -6 addr | grep -c 'inet6 [23]') -eq 1 ]]; then
	ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}')
fi
# If system has multiple IPv6, ask the user to select one
if [[ $(ip -6 addr | grep -c 'inet6 [23]') -gt 1 ]]; then
	number_of_ip6=$(ip -6 addr | grep -c 'inet6 [23]')
	echo
	echo "Which IPv6 address should be used?"
	ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | nl -s ') '
	read -p "IPv6 address [1]: " ip6_number
	until [[ -z "$ip6_number" || "$ip6_number" =~ ^[0-9]+$ && "$ip6_number" -le "$number_of_ip6" ]]; do
		echo "$ip6_number: invalid selection."
		read -p "IPv6 address [1]: " ip6_number
	done
	[[ -z "$ip6_number" ]] && ip6_number="1"
	ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | sed -n "$ip6_number"p)
fi
