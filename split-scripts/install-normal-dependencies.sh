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
