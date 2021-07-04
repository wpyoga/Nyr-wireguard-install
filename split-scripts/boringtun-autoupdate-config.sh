# Set up automatic updates for BoringTun if the user wanted to
if [[ "$boringtun_updates" =~ ^[yY]*$ ]]; then
	# @MERGE
	. here-documents/boringtun-upgrade.sh
fi
