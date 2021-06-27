#!/bin/sh

clear
echo "WireGuard is already installed."
echo
echo "Select an option:"
echo "   1) Add a new client"
echo "   2) Remove an existing client"
echo "   3) Remove WireGuard"
echo "   4) Exit"
read -p "Option: " option
until [[ "$option" =~ ^[1-4]$ ]]; do
	echo "$option: invalid selection."
	read -p "Option: " option
done
case "$option" in
	1)
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
		exit
	;;
	2)
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
		exit
	;;
	3)
		echo
		read -p "Confirm WireGuard removal? [y/N]: " remove
		until [[ "$remove" =~ ^[yYnN]*$ ]]; do
			echo "$remove: invalid selection."
			read -p "Confirm WireGuard removal? [y/N]: " remove
		done
		if [[ "$remove" =~ ^[yY]$ ]]; then
			port=$(grep '^ListenPort' /etc/wireguard/wg0.conf | cut -d " " -f 3)
			if systemctl is-active --quiet firewalld.service; then
				ip=$(firewall-cmd --direct --get-rules ipv4 nat POSTROUTING | grep '\-s 10.7.0.0/24 '"'"'!'"'"' -d 10.7.0.0/24' | grep -oE '[^ ]+$')
				# Using both permanent and not permanent rules to avoid a firewalld reload.
				firewall-cmd --remove-port="$port"/udp
				firewall-cmd --zone=trusted --remove-source=10.7.0.0/24
				firewall-cmd --permanent --remove-port="$port"/udp
				firewall-cmd --permanent --zone=trusted --remove-source=10.7.0.0/24
				firewall-cmd --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
				firewall-cmd --permanent --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
				if grep -qs 'fddd:2c4:2c4:2c4::1/64' /etc/wireguard/wg0.conf; then
					ip6=$(firewall-cmd --direct --get-rules ipv6 nat POSTROUTING | grep '\-s fddd:2c4:2c4:2c4::/64 '"'"'!'"'"' -d fddd:2c4:2c4:2c4::/64' | grep -oE '[^ ]+$')
					firewall-cmd --zone=trusted --remove-source=fddd:2c4:2c4:2c4::/64
					firewall-cmd --permanent --zone=trusted --remove-source=fddd:2c4:2c4:2c4::/64
					firewall-cmd --direct --remove-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
					firewall-cmd --permanent --direct --remove-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
				fi
			else
				systemctl disable --now wg-iptables.service
				rm -f /etc/systemd/system/wg-iptables.service
			fi
			systemctl disable --now wg-quick@wg0.service
			rm -f /etc/systemd/system/wg-quick@wg0.service.d/boringtun.conf
			rm -f /etc/sysctl.d/99-wireguard-forward.conf
			# Different packages were installed if the system was containerized or not
			if [[ ! "$is_container" -eq 0 ]]; then
				if [[ "$os" == "ubuntu" ]]; then
					# Ubuntu
					rm -rf /etc/wireguard/
					apt-get remove --purge -y wireguard wireguard-tools
				elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
					# Debian 10
					rm -rf /etc/wireguard/
					apt-get remove --purge -y wireguard wireguard-dkms wireguard-tools
				elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
					# CentOS 8
					rm -rf /etc/wireguard/
					dnf remove -y kmod-wireguard wireguard-tools
				elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
					# CentOS 7
					rm -rf /etc/wireguard/
					yum remove -y kmod-wireguard wireguard-tools
				elif [[ "$os" == "fedora" ]]; then
					# Fedora
					rm -rf /etc/wireguard/
					dnf remove -y wireguard-tools
				fi
			else
				{ crontab -l 2>/dev/null | grep -v '/usr/local/sbin/boringtun-upgrade' ; } | crontab -
				if [[ "$os" == "ubuntu" ]]; then
					# Ubuntu
					rm -rf /etc/wireguard/
					apt-get remove --purge -y wireguard-tools
				elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
					# Debian 10
					rm -rf /etc/wireguard/
					apt-get remove --purge -y wireguard-tools
				elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
					# CentOS 8
					rm -rf /etc/wireguard/
					dnf remove -y wireguard-tools
				elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
					# CentOS 7
					rm -rf /etc/wireguard/
					yum remove -y wireguard-tools
				elif [[ "$os" == "fedora" ]]; then
					# Fedora
					rm -rf /etc/wireguard/
					dnf remove -y wireguard-tools
				fi
				rm -f /usr/local/sbin/boringtun /usr/local/sbin/boringtun-upgrade
			fi
			echo
			echo "WireGuard removed!"
		else
			echo
			echo "WireGuard removal aborted!"
		fi
		exit
	;;
	4)
		exit
	;;
esac
