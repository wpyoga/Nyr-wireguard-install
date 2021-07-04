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
