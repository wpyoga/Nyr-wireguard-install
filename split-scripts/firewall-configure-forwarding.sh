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
