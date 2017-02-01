# installation des paquets
echo
echo "***********************************************"
echo "|          Installation des paquets           |"
echo "|         necessaires au serveur web          |"
echo "***********************************************"
sleep 1

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
apt-get install -yq $paquetsWeb
if [[ $? -eq 0 ]]
then
	echo "****************************"
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 1
else
	__erreurApt  # __erreurApt()
fi

echo
echo "***********************************************"
echo "|            Configuration nginx              |"
echo "***********************************************"
sleep 1
# config site default
mv $REPNGINX/sites-available/default $REPNGINX/sites-available/default.old
cp $REPLANCE/fichiers-conf/nginx_default $REPNGINX/sites-available/default
sed -i 's|<php-sock>|'$phpSock'|' $REPNGINX/sites-available/default
ln -s $REPNGINX/sites-available/default  $REPNGINX/sites-enabled/default

# config php
sed -i 's/.*;.*cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' $repPhp/fpm/php.ini

# mot de passe rutorrent  htpasswdR
htpasswd -bc $REPNGINX/.htpasswdR $userRuto $pwRuto

__servicenginxrestart

echo "***********************************************"
echo "|      Fin de configuration de nginx          |"
echo "***********************************************"
sleep 1
echo

# vérif bon fonctionnement nginx et php
echo "<?php phpinfo(); ?>" >$REPWEB/info.php
headTest1=`curl -Is http://$IP/info.php | head -n 1`
headTest2=`curl -Is http://$IP/| head -n 1`
headTest1=$(echo $headTest1 | awk -F" " '{ print $3 }')
headTest2=$(echo $headTest2 | awk -F" " '{ print $3 }')
if [[ $headTest1 == OK* ]] && [[ $headTest2 == OK* ]]
then
	echo "***********************************************"
	echo "|         nginx et php fonctionne             |"
	echo "***********************************************"
	sleep 1
else
	echo; echo "Une erreur nginx/php c'est produite"
	__messageErreur    #  __messageErreur()
fi
rm $REPWEB/info.php

# Utilise le certificat fourni avec nginx
# echo
# echo "******************************************"
# echo "|    Création certificat auto signé      |"
# echo "******************************************"
# sleep 1
# echo
