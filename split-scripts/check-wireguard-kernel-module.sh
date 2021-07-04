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
