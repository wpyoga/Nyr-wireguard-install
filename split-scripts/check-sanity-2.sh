#!/bin/sh

if [[ "$EUID" -ne 0 ]]; then
	echo "This installer needs to be run with superuser privileges."
	exit
fi

if [[ "$is_container" -eq 0 ]]; then
	if [ "$(uname -m)" != "x86_64" ]; then
		echo "In containerized systems, this installer supports only the x86_64 architecture.
The system runs on $(uname -m) and is unsupported."
		exit
	fi
	# TUN device is required to use BoringTun if running inside a container
	if [[ ! -e /dev/net/tun ]] || ! ( exec 7<>/dev/net/tun ) 2>/dev/null; then
		echo "The system does not have the TUN device available.
TUN needs to be enabled before running this installer."
		exit
	fi
fi
