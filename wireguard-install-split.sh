#!/bin/bash
#
# https://github.com/Nyr/wireguard-install
#
# Copyright (c) 2020 Nyr. Released under the MIT License.


# @MERGE
. main-script-parts/detect-os.sh

# @MERGE
. main-script-parts/check-requirements.sh

# @MERGE
. main-script-parts/util-functions.sh

if [[ ! -e /etc/wireguard/wg0.conf ]]; then
	# @MERGE
	. main-script-parts/install-wireguard.sh
else
	# @MERGE
	. main-script-parts/choose-action.sh
	case "$option" in
		1)
			# @MERGE
			. split-scripts/add-client.sh
			exit
		;;
		2)
			# @MERGE
			. split-scripts/remove-client.sh
			exit
		;;
		3)
			# @MERGE
			. split-scripts/uninstall-wireguard.sh
			exit
		;;
		4)
			exit
		;;
	esac
fi
