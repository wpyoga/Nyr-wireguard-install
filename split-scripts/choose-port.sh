echo
echo "What port should WireGuard listen to?"
read -p "Port [51820]: " port
until [[ -z "$port" || "$port" =~ ^[0-9]+$ && "$port" -le 65535 ]]; do
	echo "$port: invalid port."
	read -p "Port [51820]: " port
done
[[ -z "$port" ]] && port="51820"
