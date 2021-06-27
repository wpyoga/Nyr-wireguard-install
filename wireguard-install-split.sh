#!/bin/bash
#
# https://github.com/Nyr/wireguard-install
#
# Copyright (c) 2020 Nyr. Released under the MIT License.


# @MERGE
. split-scripts/detect-os.sh

# @MERGE
. split-scripts/check-sanity.sh

# @MERGE
. split-scripts/detect-os-2.sh

# @MERGE
. split-scripts/check-sanity-2.sh

# @MERGE
. split-scripts/utils-wireguard.sh

if [[ ! -e /etc/wireguard/wg0.conf ]]; then
# @MERGE t 1
. split-scripts/nonexistent-wireguard.sh
else
# @MERGE t 1
. split-scripts/existing-wireguard.sh
fi
