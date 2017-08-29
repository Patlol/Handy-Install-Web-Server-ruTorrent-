
clear
apt-get update && apt-get -yq install phpMyAdmin
if [[ $? ]]; then
	echo "***************************"
	echo "|   Packages Installed    |"
	echo "***************************"
	echo
	sleep 1
	headTest=$(curl -Is http://$IP/phpmyadmin | head -n 1 | awk -F" " '{ print $2 }')
	if [[ "$headTest" == "301" ]]; then
		echo "**********************************"
		echo "|     phpMyAdmin works well      |"
		echo "**********************************"
		echo "Accept certificate exception for this site"
		echo
		sleep 3
	else
		msgErreur=$(echo "curl -Is http://$IP/phpmyadmin | head -n 1 renvoie $headTest")
		echo "$msgErreur" >> /tmp/hiwst.log
		__messageBox "Install phpMyAdmin" $msgErreur
	fi
else
	echo "************************************"
	echo "|   Error in installing packages   |"
	echo "************************************"
	echo
	sleep 3
fi
