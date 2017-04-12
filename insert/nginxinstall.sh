# installation des paquets
if [[ $nameDistrib == "Debian" ]]; then
	# nginx apache2-utils
	paquetsWeb="nginx-full apache2-utils "$paquetsWebD
	phpSock="/run/php5-fpm.sock"
	repPhp="/etc/php5"
else
	# "nginx apache2-utils"
	paquetsWeb="nginx apache2-utils "$paquetsWebU
	phpSock="/run/php/php7.0-fpm.sock"
	repPhp="/etc/php/7.0"
fi
__cmd "apt-get install -yq $paquetsWeb"
echo
echo "***********************************************"
echo "|     Paquets necessaires au serveur web      |"
echo "|                installés                    |"
echo "***********************************************"
sleep 1

# config site default
mv $REPNGINX/sites-available/default $REPNGINX/sites-available/default.old
cp $REPLANCE/fichiers-conf/nginx_default $REPNGINX/sites-available/default
sed -i 's|<php-sock>|'$phpSock'|' $REPNGINX/sites-available/default
ln -s $REPNGINX/sites-available/default  $REPNGINX/sites-enabled/default

# config php
sed -i 's/.*;.*cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' $repPhp/fpm/php.ini
if [[ $nameDistrib == "Debian" ]]; then   php5-fpm
	service php5-fpm restart
	service php5-fpm status
	if [[ $? -eq 0 ]]; then
		echo "php5-fpm fonctionne."
		echo
	else
		dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "Message d'erreur" --prgbox "Problème au lancement du service php5-fpm : Consulter le wiki
https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal" "service php5-fpm" 8 98
		__msgErreurBox
	fi
else
	service php7.0-fpm restart
	service php7.0-fpm status
	if [[ $? -eq 0 ]]; then
		echo "php7.0-fpm fonctionne."
		echo
	else
		dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "Message d'erreur" --prgbox "Problème au lancement du service php7.0-fpm : Consulter le wiki
https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal" "service php7.0-fpm" 8 98
		__msgErreurBox
	fi
fi

# mot de passe rutorrent  htpasswdR
htpasswd -bc $REPNGINX/.htpasswdR $userRuto $pwRuto

__servicenginxrestart
echo
echo "*********************************************"
echo "|             nginx configuré               |"
echo "*********************************************"
sleep 1

# vérif bon fonctionnement nginx et php
echo "<?php phpinfo(); ?>" >$REPWEB/info.php
headTest1=`curl -Is http://$IP/info.php | head -n 1`
headTest2=`curl -Is http://$IP/| head -n 1`
headTest1=$(echo $headTest1 | awk -F" " '{ print $3 }')
headTest2=$(echo $headTest2 | awk -F" " '{ print $3 }')
if [[ "$headTest1" == OK* ]] && [[ "$headTest2" == OK* ]]
then
	echo "***********************************************"
	echo "|         nginx et php fonctionnent           |"
	echo "***********************************************"
	sleep 1
	rm $REPWEB/info.php
else
	echo "curl -Is http://$IP/info.php | head -n 1 renvoie $headTest1" >> /tmp/hiwst.log
	echo "curl -Is http://$IP/| head -n 1 renvoie $headTest2" >> /tmp/hiwst.log
	__msgErreurBox
fi

# Utilise le certificat fourni avec nginx
# echo
# echo "******************************************"
# echo "|    Création certificat auto signé      |"
# echo "******************************************"
# sleep 1
# echo
