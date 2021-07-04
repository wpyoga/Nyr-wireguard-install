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
