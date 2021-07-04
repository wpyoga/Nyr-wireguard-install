# Configure wg-quick to use BoringTun
mkdir /etc/systemd/system/wg-quick@wg0.service.d/ 2>/dev/null
# @MULTILINE
echo "[Service]
Environment=WG_QUICK_USERSPACE_IMPLEMENTATION=boringtun
Environment=WG_SUDO=1" > /etc/systemd/system/wg-quick@wg0.service.d/boringtun.conf
# @MULTILINE-END
