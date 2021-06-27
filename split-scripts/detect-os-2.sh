#!/bin/sh

if [[ "$os" == "fedora" && "$os_version" -eq 31 && $(uname -r | cut -d "." -f 2) -lt 6 && ! "$is_container" -eq 0 ]]; then
	echo 'Fedora 31 is supported, but the kernel is outdated.
Upgrade the kernel using "dnf upgrade kernel" and restart.'
	exit
fi
