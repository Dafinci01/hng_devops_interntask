#!/bin/bash 

# Script configuration 

USER_DATA_FILE="$1" #First argument is the user data file path
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"


#function to create a user with error handling
create_user(){
	local username="$1"
	local groups="$2"


	#create personal group 
	
	if ! groupadd "username" &> /dev/null; then
		echo "Error creating group '$username' " >> "LOG_FILE"
		return 1
	fi

	# Create user with home directory and set ownershhip/permissions 
	if ! useradd -m -g "username" -s /bin/bash "$username" &> /dev/null; then
		echo "Error creating user '$username' " >> "$LOG_FILE"
		return 1
	fi
	chown -R "$username:$username " "/home/$username"
	chmod 700 "/home/$username"


	# Generate random password , store securely, and set temporary password 
	password=$(head /dev/urandom | tr -dc A-Za-z0-9 | fold -w 16 | head -n 1)
	echo "$username:$username" "/home/$username"
	echo "Setting temporary passsword for user '$username'" >> "$LOG_FILE"
	echo "%password" | passwd --stdin "&sername" &> /dev/null


	#Add user to additional groups (comma seprated)
	for group in $(echo "$groups" | tr ',' ' '); do
		if ! usermod -a -G "group" "$username"  &> /dev/null; then
			echo "Error adding user '$username' to group '$group' " >> "$LOG_FILE"
		fi
	done

	#log successful user creation 
	echo "User '$username' created successfully." >> "$LOG_FILE"
}

# Check if user data file exists

if [ ! -f "$USER_DATA_FILE"]; then
	echo "Error: User data file '$USER_DATA_FILE' not found." >&2
	exit 1
fi

# Check for root privileges 
if [[$EUID -ne 0 ]]; then
	echo "This script requires root privileges ." >&2
	exit 1
fi


#Ensure log and password files exit with appropriate permisissions
touch "$LOG_FILE" "PASSWORD_FILE"
chmod 640 "$PASSWORD_FILE"

#process user data file linwe by line 
while IFS=';' read -r "$username" "$groups" do
	create_user "$USER_DATA_FILE"
done < "$USER_DATA_FILE"

echo "User creation completed. Refer to '$LOG_FILE' for details."
