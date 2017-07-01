# installation des paquets
if [[ $nameDistrib == "Debian" ]]; then
	paquetsWeb="apache2 apache2-utils libapache2-mod-php5 "$paquetsWebD
else
	paquetsWeb="apache2 apache2-utils libapache2-mod-php7.0 "$paquetsWebU
fi
__cmd "apt-get install -yq $paquetsWeb"
echo
echo "***********************************************"
echo "|     Packages needed by the web server      |"
echo "|                 installed                  |"
echo "**********************************************"
sleep 1

# config apache
a2enmod ssl
a2enmod auth_digest
a2enmod reqtimeout
a2enmod authn_file
a2enmod rewrite

cp $REPAPA2/apache2.conf $REPAPA2/apache2.conf.old
sed -i 's/^Timeout[ 0-9]*/Timeout 30/' $REPAPA2/apache2.conf
echo -e "\nServerTokens Prod\nServerSignature Off" >> $REPAPA2/apache2.conf

echo
echo "***********************************"
echo "|      Apache2 configured         |"
echo "***********************************"
sleep 1

# mot de passe user rutorrent  htpasswd
(echo -n "$userRuto:rutorrent:" && echo -n "$userRuto:rutorrent:$pwRuto" | md5sum) > $REPAPA2/.htpasswd
sed -i 's/[ ]*-$//' $REPAPA2/.htpasswd

# Modifier la configuration du site par défaut (pour rutorrent)
cp $REPAPA2/sites-available/000-default.conf $REPAPA2/sites-available/000-default.conf.old
cp $REPLANCE/fichiers-conf/apa_000-default.conf $REPAPA2/sites-available/000-default.conf
sed -i 's/<server IP>/'$IP'/g' $REPAPA2/sites-available/000-default.conf
__serviceapache2restart

# vérif bon fonctionnement apache et php
echo "<?php phpinfo(); ?>" >$REPWEB/info.php
headTest1=`curl -Is http://$IP/info.php/| head -n 1`
headTest2=`curl -Is http://$IP/| head -n 1`
headTest1=$(echo $headTest1 | awk -F" " '{ print $3 }')
headTest2=$(echo $headTest2 | awk -F" " '{ print $3 }')
if [[ "$headTest1" == OK* ]] && [[ "$headTest2" == OK* ]]
then
	echo "***********************************************"
	echo "|        Apache and php work well             |"
	echo "***********************************************"
	sleep 1
	rm $REPWEB/info.php
else
	echo "curl -Is http://$IP/info.php/| head -n 1 return $headTest1" >> /tmp/hiwst.log
	echo "curl -Is http://$IP/| head -n 1 return $headTest2" >> /tmp/hiwst.log
	__msgErreurBox
fi

echo -e 'Options All -Indexes\n<Files .htaccess>\norder allow,deny\ndeny from all\n</Files>' > $REPWEB/.htaccess

## création certificat ---------------------------------------------------------
openssl req -new -x509 -days 365 -nodes -newkey rsa:2048 -out $REPAPA2/apache.pem -keyout $REPAPA2/apache.pem -subj "/C=FR/ST=Paris/L=Paris/O=Global Security/OU=RUTO Department/CN=$IP"

chmod 600 $REPAPA2/apache.pem

cp $REPAPA2/sites-available/default-ssl.conf $REPAPA2/sites-available/default-ssl.conf.old

sed -i "/<\/VirtualHost>/i \<Location /rutorrent>\nAuthType Digest\nAuthName \"rutorrent\"\nAuthDigestDomain \/var\/www\/html\/rutorrent\/ http:\/\/$IP\/rutorrent\n\nAuthDigestProvider file\nAuthUserFile \/etc\/apache2\/.htpasswd\nRequire valid-user\nSetEnv R_ENV \"\/var\/www\/html\/rutorrent\"\n<\/Location>\n" $REPAPA2/sites-available/default-ssl.conf

a2ensite default-ssl
__serviceapache2restart
echo
echo "**********************************************"
echo "|      Self-signed certificate created       |"
echo "**********************************************"
sleep 1
echo
