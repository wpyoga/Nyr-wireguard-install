clear
echo "WireGuard is already installed."
echo
echo "Select an option:"
echo "   1) Add a new client"
echo "   2) Remove an existing client"
echo "   3) Remove WireGuard"
echo "   4) Exit"
read -p "Option: " option
until [[ "$option" =~ ^[1-4]$ ]]; do
	echo "$option: invalid selection."
	read -p "Option: " option
done
