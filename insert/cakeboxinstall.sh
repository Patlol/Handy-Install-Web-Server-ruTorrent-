clear
echo
echo
echo
echo "*************************************************"
echo "|           Installation de CakeBox             |"
echo "*************************************************"
echo
echo
sleep 1

# install prérequis ****************************************

apt-get install -yq git python-software-properties nodejs npm javascript-common node-oauth-sign debhelper javascript-common libjs-jquery
if [[ $? -eq 0 ]]
then
	echo "****************************"
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 1
else
	erreurApt
fi

# install composer /tmp
cd /tmp
echo $userLinux | sudo -S -u $userLinux curl -sS http://getcomposer.org/installer | php

mv /tmp/composer.phar /usr/bin/composer
chmod +x /usr/bin/composer

# nodejs
ln -s /usr/bin/nodejs /usr/bin/node

# install bower
npm install -g bower

# CakeBox depuis github sur /html  ********************************************

# chmod sur les répertoires www et html

chmod o+r /var/www
chmod u+rwx,g+rwx $REPWEB
git clone https://github.com/Cakebox/Cakebox-light.git $REPWEB/cakebox
cd $REPWEB/cakebox/
git checkout -b $(git describe --tags $(git rev-list --tags --max-count=1))

chown -R $userLinux:$userLinux $REPWEB/cakebox/

# traitement cakebox composer bower  *****************************************

# sur Debian .composer est sur /root
if [[ $nameDistrib == "Debian"  ]]; then
	chmod o+x /root; chmod -R o+wx /root/.composer
fi
# sur ubuntu .composer est sur /home/user
if [[ $nameDistrib == "Ubuntu" ]]; then
	chown -R $userLinux:$userLinux $REPUL/.composer
fi

echo $userLinux | sudo -S -u $userLinux composer install
echo $userLinux | sudo -S -u $userLinux bower install

# pour Debian remise en l'état  de /root
if [[ $nameDistrib == "Debian" ]]; then
	chmod -R o-w /root/.composer; chmod o-x /root
fi

# configuration ***********************************************************
cp $REPWEB/cakebox/config/default.php.dist $REPWEB/cakebox/config/$userCake.php

sed -i "s|\(\$app\[\"cakebox.root\"\].*\)|\$app\[\"cakebox.root\"\] = \"$REPUL/downloads/\";|" $REPWEB/cakebox/config/$userCake.php
sed -i "s|\(\$app\[\"player.default_type\"\].*\)|\$app\[\"player.default_type\"\] = \"vlc\";|" $REPWEB/cakebox/config/$userCake.php
chown -R www-data:www-data $REPWEB/cakebox/config

# modification apache pour cakebox
if [[ $serveurHttp == "apache2" ]]; then
	echo
	echo "*************************************************"
	echo "|            Modifications apache2              |"
	echo "*************************************************"
	echo
	a2enmod headers
	a2enmod rewrite
	a2enconf javascript-common
	# config apache et ajout de l'alias sur apache
	cp $REPWEB/cakebox/webconf-example/apache2-alias.conf.example $REPAPA2/sites-available/cakebox.conf

	sed -i -e 's|'\$ALIAS'|cakebox|g' -e 's|'\$CAKEBOXREP'|'$REPWEB'/cakebox|g' -e 's|'\$VIDEOREP'|/home/'$userLinux'/downloads|g' $REPAPA2/sites-available/cakebox.conf
	sed -i "/.*VirtualHost.*/d" $REPAPA2/sites-available/cakebox.conf

	a2ensite cakebox.conf
	__serviceapache2restart

else   # modification nginx pour cakebox
	echo
	echo "*************************************************"
	echo "|             Modifications nginx               |"
	echo "*************************************************"
	echo
	# sur default : proxy
	sed -i '/.*# Cakebox proxy/ r '$REPLANCE'/fichiers-conf/nginx_default_cakebox' $REPNGINX/sites-available/default
	# conf site cakebox
	cp $REPLANCE/fichiers-conf/nginx_cakebox $REPNGINX/sites-available/cakebox
	sed -i 's|<php-sock>|'$phpSock'|' $REPNGINX/sites-available/cakebox
	sed -i 's/<user-Cakebox>/'$userLinux'/' $REPNGINX/sites-available/cakebox
	ln -s $REPNGINX/sites-available/cakebox  $REPNGINX/sites-enabled/cakebox
	__servicenginxrestart
fi    # fin modif serveur http



# install plugin cakebox sur rutorrent
echo
echo "*******************************************************"
echo "|   Installation du plugin ruTorrent pour Cakebox     |"
echo "*******************************************************"
sleep 1
echo

git clone https://github.com/Cakebox/linkcakebox.git $REPWEB/rutorrent/plugins/linkcakebox
chown -R www-data:www-data $REPWEB/rutorrent/plugins/linkcakebox

sed -i "s|\(\$url.*\)|\$url = 'http:\/\/"$IP"\/cakebox\/index.html';|" $REPWEB/rutorrent/plugins/linkcakebox/conf.php

echo -e "\n    [linkcakebox]\n    enabled = yes" >> $REPWEB/rutorrent/conf/users/$userRuto/plugins.ini

chown www-data:www-data $REPWEB/cakebox/
chown -R www-data:www-data $REPWEB/cakebox/public

#  sécuriser cakebox
echo
echo "*************************"
echo "|   Sécuriser Cakebox   |"
echo "*************************"
sleep 1
echo

if [[ $serveurHttp == "apache2" ]]; then
	a2enmod auth_basic
	echo -e 'AuthName "Entrer votre identifiant et mot de passe Cakebox"\nAuthType Basic\nAuthUserFile "/var/www/html/cakebox/public/.htpasswd"\nRequire valid-user' > $REPWEB/cakebox/public/.htaccess
	chown www-data:www-data $REPWEB/cakebox/public/.htaccess

	htpasswd -bc $REPWEB/cakebox/public/.htpasswd $userCake $pwCake
	chown www-data:www-data $REPWEB/cakebox/public/.htpasswd

	__serviceapache2restart
	chmod 755 $REPWEB
else
	# mot de passe rutorrent  htpasswdR
	htpasswd -bc $REPNGINX/.htpasswdC $userCake $pwCake
  __servicenginxrestart
fi

headTest=`curl -Is http://$IP/cakebox/index.html | head -n 1`
headTest=$(echo $headTest | awk -F" " '{ print $3 }')
# unautorized pour apache, moved pour nginx
if [[ $headTest == Unauthorized* ]] || [[ $headTest == Moved* ]]
then
	echo "***************************"
	echo "|   Cakebox fonctionne    |"
	echo "***************************"
else
	echo; echo "Une erreur c'est produite sur cakebox"
	echo; echo "Consulter le wiki"
	echo "https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
	echo; echo "puis continuer/arrêter l'installation"
	__ouinon
fi
sleep 1
