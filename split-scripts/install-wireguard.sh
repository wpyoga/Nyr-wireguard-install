# Install WireGuard
# If not running inside a container, set up the WireGuard kernel module
if [[ ! "$is_container" -eq 0 ]]; then
	# @MERGE
	. split-scripts/install-normal.sh
# Else, we are inside a container and BoringTun needs to be used
else
	# @MERGE
	. split-scripts/install-container.sh
fi
