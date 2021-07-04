#!/bin/bash

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
