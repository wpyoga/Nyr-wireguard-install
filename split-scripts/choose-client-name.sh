echo
echo "Enter a name for the first client:"
read -p "Name [client]: " unsanitized_client
# Allow a limited set of characters to avoid conflicts
client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
[[ -z "$client" ]] && client="client"
