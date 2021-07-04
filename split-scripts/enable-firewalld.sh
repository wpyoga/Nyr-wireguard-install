# If firewalld was just installed, enable it
if [[ "$firewall" == "firewalld" ]]; then
	systemctl enable --now firewalld.service
fi
