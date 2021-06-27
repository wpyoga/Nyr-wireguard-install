#!/bin/sh

clear
echo 'Welcome to this WireGuard road warrior installer!'
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
echo
echo "What port should WireGuard listen to?"
read -p "Port [51820]: " port
until [[ -z "$port" || "$port" =~ ^[0-9]+$ && "$port" -le 65535 ]]; do
	echo "$port: invalid port."
	read -p "Port [51820]: " port
done
[[ -z "$port" ]] && port="51820"
echo
echo "Enter a name for the first client:"
read -p "Name [client]: " unsanitized_client
# Allow a limited set of characters to avoid conflicts
client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
[[ -z "$client" ]] && client="client"
echo
new_client_dns
# Set up automatic updates for BoringTun if the user is fine with that
if [[ "$is_container" -eq 0 ]]; then
	echo
	echo "BoringTun will be installed to set up WireGuard in the system."
	read -p "Should automatic updates be enabled for it? [Y/n]: " boringtun_updates
	until [[ "$boringtun_updates" =~ ^[yYnN]*$ ]]; do
		echo "$remove: invalid selection."
		read -p "Should automatic updates be enabled for it? [Y/n]: " boringtun_updates
	done
	if [[ "$boringtun_updates" =~ ^[yY]*$ ]]; then
		if [[ "$os" == "centos" || "$os" == "fedora" ]]; then
			cron="cronie"
		elif [[ "$os" == "debian" || "$os" == "ubuntu" ]]; then
			cron="cron"
		fi
	fi
fi
echo
echo "WireGuard installation is ready to begin."
# Install a firewall in the rare case where one is not already available
if ! systemctl is-active --quiet firewalld.service && ! hash iptables 2>/dev/null; then
	if [[ "$os" == "centos" || "$os" == "fedora" ]]; then
		firewall="firewalld"
		# We don't want to silently enable firewalld, so we give a subtle warning
		# If the user continues, firewalld will be installed and enabled during setup
		echo "firewalld, which is required to manage routing tables, will also be installed."
	elif [[ "$os" == "debian" || "$os" == "ubuntu" ]]; then
		# iptables is way less invasive than firewalld so no warning is given
		firewall="iptables"
	fi
fi
read -n1 -r -p "Press any key to continue..."
# Install WireGuard
# If not running inside a container, set up the WireGuard kernel module
if [[ ! "$is_container" -eq 0 ]]; then
	if [[ "$os" == "ubuntu" ]]; then
		# Ubuntu
		apt-get update
		apt-get install -y wireguard qrencode $firewall
	elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
		# Debian 10
		if ! grep -qs '^deb .* buster-backports main' /etc/apt/sources.list /etc/apt/sources.list.d/*.list; then
			echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list
		fi
		apt-get update
		# Try to install kernel headers for the running kernel and avoid a reboot. This
		# can fail, so it's important to run separately from the other apt-get command.
		apt-get install -y linux-headers-"$(uname -r)"
		# There are cleaner ways to find out the $architecture, but we require an
		# specific format for the package name and this approach provides what we need.
		architecture=$(dpkg --get-selections 'linux-image-*-*' | cut -f 1 | grep -oE '[^-]*$' -m 1)
		# linux-headers-$architecture points to the latest headers. We install it
		# because if the system has an outdated kernel, there is no guarantee that old
		# headers were still downloadable and to provide suitable headers for future
		# kernel updates.
		apt-get install -y linux-headers-"$architecture"
		apt-get install -y wireguard qrencode $firewall
	elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
		# CentOS 8
		dnf install -y epel-release elrepo-release
		dnf install -y kmod-wireguard wireguard-tools qrencode $firewall
		mkdir -p /etc/wireguard/
	elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
		# CentOS 7
		yum install -y epel-release https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
		yum install -y yum-plugin-elrepo
		yum install -y kmod-wireguard wireguard-tools qrencode $firewall
		mkdir -p /etc/wireguard/
	elif [[ "$os" == "fedora" ]]; then
		# Fedora
		dnf install -y wireguard-tools qrencode $firewall
		mkdir -p /etc/wireguard/
	fi
# Else, we are inside a container and BoringTun needs to be used
else
	# Install required packages
	if [[ "$os" == "ubuntu" ]]; then
		# Ubuntu
		apt-get update
		apt-get install -y qrencode ca-certificates $cron $firewall
		apt-get install -y wireguard-tools --no-install-recommends
	elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
		# Debian 10
		if ! grep -qs '^deb .* buster-backports main' /etc/apt/sources.list /etc/apt/sources.list.d/*.list; then
			echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list
		fi
		apt-get update
		apt-get install -y qrencode ca-certificates $cron $firewall
		apt-get install -y wireguard-tools --no-install-recommends
	elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
		# CentOS 8
		dnf install -y epel-release
		dnf install -y wireguard-tools qrencode ca-certificates tar $cron $firewall
		mkdir -p /etc/wireguard/
	elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
		# CentOS 7
		yum install -y epel-release
		yum install -y wireguard-tools qrencode ca-certificates tar $cron $firewall
		mkdir -p /etc/wireguard/
	elif [[ "$os" == "fedora" ]]; then
		# Fedora
		dnf install -y wireguard-tools qrencode ca-certificates tar $cron $firewall
		mkdir -p /etc/wireguard/
	fi
	# Grab the BoringTun binary using wget or curl and extract into the right place.
	# Don't use this service elsewhere without permission! Contact me before you do!
	{ wget -qO- https://wg.nyr.be/1/latest/download 2>/dev/null || curl -sL https://wg.nyr.be/1/latest/download ; } | tar xz -C /usr/local/sbin/ --wildcards 'boringtun-*/boringtun' --strip-components 1
# @MERGE
. multi-line-strings/boringtun.conf.sh
	if [[ -n "$cron" ]] && [[ "$os" == "centos" || "$os" == "fedora" ]]; then
		systemctl enable --now crond.service
	fi
fi
# If firewalld was just installed, enable it
if [[ "$firewall" == "firewalld" ]]; then
	systemctl enable --now firewalld.service
fi
# @MERGE
. here-documents/wg0.conf.sh
# Enable net.ipv4.ip_forward for the system
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-wireguard-forward.conf
# Enable without waiting for a reboot or service restart
echo 1 > /proc/sys/net/ipv4/ip_forward
if [[ -n "$ip6" ]]; then
	# Enable net.ipv6.conf.all.forwarding for the system
	echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.d/99-wireguard-forward.conf
	# Enable without waiting for a reboot or service restart
	echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
fi
if systemctl is-active --quiet firewalld.service; then
	# Using both permanent and not permanent rules to avoid a firewalld
	# reload.
	firewall-cmd --add-port="$port"/udp
	firewall-cmd --zone=trusted --add-source=10.7.0.0/24
	firewall-cmd --permanent --add-port="$port"/udp
	firewall-cmd --permanent --zone=trusted --add-source=10.7.0.0/24
	# Set NAT for the VPN subnet
	firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
	firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
	if [[ -n "$ip6" ]]; then
		firewall-cmd --zone=trusted --add-source=fddd:2c4:2c4:2c4::/64
		firewall-cmd --permanent --zone=trusted --add-source=fddd:2c4:2c4:2c4::/64
		firewall-cmd --direct --add-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
		firewall-cmd --permanent --direct --add-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
	fi
else
	# Create a service to set up persistent iptables rules
	iptables_path=$(command -v iptables)
	ip6tables_path=$(command -v ip6tables)
	# nf_tables is not available as standard in OVZ kernels. So use iptables-legacy
	# if we are in OVZ, with a nf_tables backend and iptables-legacy is available.
	if [[ $(systemd-detect-virt) == "openvz" ]] && readlink -f "$(command -v iptables)" | grep -q "nft" && hash iptables-legacy 2>/dev/null; then
		iptables_path=$(command -v iptables-legacy)
		ip6tables_path=$(command -v ip6tables-legacy)
	fi
# @MERGE
. multi-line-strings/wg-iptables.service.sh
	if [[ -n "$ip6" ]]; then
# @MERGE
. multi-line-strings/wg-iptables.service-ipv6.sh
	fi
# @MERGE
. multi-line-strings/wg-iptables.service-tail.sh
	systemctl enable --now wg-iptables.service
fi
# Generates the custom client.conf
new_client_setup
# Enable and start the wg-quick service
systemctl enable --now wg-quick@wg0.service
# Set up automatic updates for BoringTun if the user wanted to
if [[ "$boringtun_updates" =~ ^[yY]*$ ]]; then
# @MERGE
. here-documents/boringtun-upgrade.sh
fi
echo
qrencode -t UTF8 < ~/"$client.conf"
echo -e '\xE2\x86\x91 That is a QR code containing the client configuration.'
echo
# If the kernel module didn't load, system probably had an outdated kernel
# We'll try to help, but will not will not force a kernel upgrade upon the user
if [[ ! "$is_container" -eq 0 ]] && ! modprobe -nq wireguard; then
	echo "Warning!"
	echo "Installation was finished, but the WireGuard kernel module could not load."
	if [[ "$os" == "ubuntu" && "$os_version" -eq 1804 ]]; then
	echo 'Upgrade the kernel and headers with "apt-get install linux-generic" and restart.'
	elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
	echo "Upgrade the kernel with \"apt-get install linux-image-$architecture\" and restart."
	elif [[ "$os" == "centos" && "$os_version" -le 8 ]]; then
		echo "Reboot the system to load the most recent kernel."
	fi
else
	echo "Finished!"
fi
echo
echo "The client configuration is available in:" ~/"$client.conf"
echo "New clients can be added by running this script again."
