#!/bin/bash
#
# https://github.com/Nyr/wireguard-install
#
# Copyright (c) 2020 Nyr. Released under the MIT License.


# @MERGE
. split-scripts/detect-os.sh

# @MERGE
. split-scripts/check-requirements.sh

# @MERGE
. split-scripts/util-functions.sh

if [[ ! -e /etc/wireguard/wg0.conf ]]; then
	# @MERGE
	. split-scripts/nonexistent-wireguard.sh
else
	# @MERGE
	. split-scripts/existing-wireguard.sh
fi
