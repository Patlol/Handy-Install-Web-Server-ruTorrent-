clear
# install paquet manquant (ubuntu - apache2) + owncloud
wget -nv https://download.owncloud.org/download/repositories/stable/xUbuntu_16.04/Release.key -O ./Release.key
apt-key add - < ./Release.key
sh -c "echo 'deb http://download.owncloud.org/download/repositories/stable/xUbuntu_16.04/ /' >> /etc/apt/sources.list.d/owncloud.list"
apt-get update
apt-get -yq install mariadb-server php7.0-gd php7.0-mysql php7.0-intl php-imagick owncloud   # to get a complete installation with all dependencies.

chown -R www-data:www-data /var/www/owncloud/

echo "***************************************"
echo "|  Installation des paquets terminée  |"
echo "***************************************"

# paramétrage apache
cp $REPLANCE/fichiers-conf/apa_site_owncloud.conf $REPAPA2/sites-available/owncloud.conf
cp $REPLANCE/fichiers-conf/apa_conf_owncloud.conf $REPAPA2/conf-available/owncloud.conf

a2enmod rewrite
a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime

ln -s $REPAPA2/sites-available/owncloud.conf $REPAPA2/sites-enabled/owncloud.conf
ln -s $REPAPA2/conf-available/owncloud.conf $REPAPA2/conf-enabled/owncloud.conf

service apache2 reload
service apache2 restart
service apache2 status 2>&1 /dev/null

if [[ $? -ne 0 ]]; then
  echo "Erreur apache !!!"
  exit 1
else
  echo "********************************"
  echo "|  Paramétrage apache terminé  |"
  echo "********************************"
fi

## création base de données

mysql -uroot -pofh4HMkO -t <<EOF
CREATE DATABASE IF NOT EXISTS owncloud;
show databases;
GRANT ALL PRIVILEGES ON owncloud.* TO '`echo ${FIRSTUSER[0]}`'@'localhost' IDENTIFIED BY '`echo $__saisieIdPwBox`';
\q
EOF
unset $__saisieIdPwBox
echo "***************************"
echo "|  Base de données créée  |"
echo "***************************"

## modif des droits
ocpath='/var/www/owncloud'
htuser='www-data'
htgroup='www-data'
rootuser='root'

printf "Creating possible missing Directories\n"
mkdir -p $ocpath/data
mkdir -p $ocpath/assets
mkdir -p $ocpath/updater

printf "chmod Files and Directories\n"
find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750

printf "chown Directories\n"
chown -R ${rootuser}:${htgroup} ${ocpath}/
chown -R ${htuser}:${htgroup} ${ocpath}/apps/
chown -R ${htuser}:${htgroup} ${ocpath}/assets/
chown -R ${htuser}:${htgroup} ${ocpath}/config/
chown -R ${htuser}:${htgroup} ${ocpath}/data/
chown -R ${htuser}:${htgroup} ${ocpath}/themes/
chown -R ${htuser}:${htgroup} ${ocpath}/updater/

chmod +x ${ocpath}/occ

printf "chmod/chown .htaccess\n"
if [ -f ${ocpath}/.htaccess ]
 then
  chmod 0644 ${ocpath}/.htaccess
  chown ${rootuser}:${htgroup} ${ocpath}/.htaccess
fi
if [ -f ${ocpath}/data/.htaccess ]
 then
  chmod 0644 ${ocpath}/data/.htaccess
  chown ${rootuser}:${htgroup} ${ocpath}/data/.htaccess
fi

echo "*********************"
echo "|  Droits modifiés  |"
echo "*********************"
sleep 1

# /etc/php/7.0/fpm/php.ini
# service php7.0-fpm status
