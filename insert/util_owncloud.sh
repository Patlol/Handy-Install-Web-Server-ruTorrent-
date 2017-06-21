clear

readonly ocpath='/var/www/owncloud'
readonly htuser='www-data'
readonly htgroup='www-data'
readonly rootuser='root'

################################################################################
# install paquet manquant (ubuntu / debian) + owncloud + php
# module php et paquets necessaires cf doc owncloud
# apt-get install apache2 libapache2-mod-php5 # mariadb-server
# apt-get install php5-gd php5-json php5-mysql php5-curl
# apt-get install php5-intl php5-mcrypt php5-imagick
if [[ $nameDistrib = "Ubuntu" ]]; then
  wget -nv https://download.owncloud.org/download/repositories/stable/xUbuntu_16.04/Release.key -O ./Release.key
  apt-key add - < ./Release.key
  sh -c "echo 'deb http://download.owncloud.org/download/repositories/stable/xUbuntu_16.04/ /' >> /etc/apt/sources.list.d/owncloud.list"
  apt-get update
  apt-get -yq install mysql-server php7.0-gd php7.0-mysql php7.0-intl php-imagick owncloud   # owncloud pour installation complette avec ttes les dépendances.
else  # Debian 8.xx
  wget -nv https://download.owncloud.org/download/repositories/stable/Debian_8.0/Release.key -O Release.key
  apt-key add - < Release.key
  sh -c "echo 'deb http://download.owncloud.org/download/repositories/stable/Debian_8.0/ /' > /etc/apt/sources.list.d/owncloud.list"
  apt-get update
  apt-get -yq install php5-gd php5-mysql php5-intl imagemagick-6.defaultquantum php5-imagick owncloud
fi

################################################################################
# install de postfix et mailutils si pas présents
which mailutils 2>&1 > /dev/null
if [ $? != 0 ]; then
  __messageBox "Installation postfix/mailutils" "
Valider les valeurs proposées par défaut"
  apt-get -yq install mailutils postfix
  service postfix reload
  if [[ $? -ne 0 ]]; then
    service postfix status
    echo
    echo "Erreur postfix !!!"
    exit 1
  fi
fi

echo "***************************************"
echo "|  Installation des paquets terminée  |"
echo "***************************************"

################################################################################
# paramétrage apache
cp $REPLANCE/fichiers-conf/apa_site_owncloud.conf $REPAPA2/sites-available/owncloud.conf
cp $REPLANCE/fichiers-conf/apa_conf_owncloud.conf $REPAPA2/conf-available/owncloud.conf

a2enmod rewrite
a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime

[[ ! -e $REPAPA2/sites-enabled/owncloud.conf ]] && \
  ln -s $REPAPA2/sites-available/owncloud.conf $REPAPA2/sites-enabled/owncloud.conf

[[ ! -e $REPAPA2/conf-enabled/owncloud.conf ]] && \
  ln -s $REPAPA2/conf-available/owncloud.conf $REPAPA2/conf-enabled/owncloud.conf

# L'en-tête HTTP "Strict-Transport-Security" n'est pas configurée à "15552000" secondes.
# Pour renforcer la sécurité nous recommandons d'activer HSTS cf. Guide pour le renforcement et la sécurité.
# ==> man-in-the-middle attacks https://79.137.33.190/owncloud/index.php/settings/help?mode=admin
sed -i '/<VirtualHost _default_:443>/a <IfModule mod_headers.c>\n  Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"\n</IfModule>' $REPAPA2/sites-available/default-ssl.conf

service apache2 reload
service apache2 restart
if [[ $? -ne 0 ]]; then
  service apache2 status
  echo
  echo "Erreur apache !!!"
  exit 1
else
  echo "********************************"
  echo "|  Paramétrage apache terminé  |"
  echo "********************************"
fi

################################################################################
## création base de données
echo "***************************************************************************"
echo "|       Création de la Base de données owncloud et de son admin           |"
echo "|    Entrez le mot de passe root que vous avez saisi à l'installation     |"
echo "|         de mySql ou laisser vide si vous n'avez rien saisi              |"
echo "***************************************************************************"
mysql -tp <<EOF
CREATE DATABASE IF NOT EXISTS owncloud;
show databases;
GRANT ALL PRIVILEGES ON owncloud.* TO '`echo $userBdD`'@'localhost' IDENTIFIED BY '`echo $pwBdD`';
\q
EOF

if [[ $? -ne 0 ]]; then
  echo
  echo "Erreur à la création de la base de données owncloud !!!"
  exit 1
else
  echo "************************************"
  echo "|  Base de données et admin créés  |"
  echo "************************************"
fi

################################################################################
## finalisation de l'installation remplace la GUI
# maintenance:install [--database DATABASE] [--database-name DATABASE-NAME] [--database-host DATABASE-HOST] [--database-user DATABASE-USER] [--database-pass [DATABASE-PASS]] [--database-table-prefix [DATABASE-TABLE-PREFIX]] [--admin-user ADMIN-USER] [--admin-pass ADMIN-PASS] [--data-dir DATA-DIR]

sudo -u $htuser $ocpath/occ  maintenance:install --database "mysql" --database-name "owncloud"  --database-user $userBdD --database-pass $pwBdD --admin-user ${FIRSTUSER[0]} --admin-pass $pwFirstuser
if [[ $? -ne 0 ]]; then
  echo
  echo "Erreur à la finalisation de l'installation"
  echo
  exit 1
else
  echo "*************************************"
  echo "|       Installation finalisée      |"
  echo "|   déclaration BdD et admin-user   |"
  echo "*************************************"
fi

################################################################################
#  apache Modif des limites fichiers .htaccess
#  upload_max_filesize=513M post_max_size=513Mpost_max_size=513M valeurs d'origine
#  supprime l'integrity check    sed -i 's/  php_value memory_limit 512M/# php_value memory_limit 512M/g' $ocpath/.htaccess
if [[ $fileSize != "513M" ]]; then
  sed -i -e 's/php_value upload_max_filesize 513M/php_value upload_max_filesize '$fileSize'/' \
         -e 's/php_value post_max_size 513M/php_value post_max_size '$fileSize'/' $ocpath/.htaccess

  # pour éviter "Il y a eu des problèmes à la vérification d’intégrité du code."
  # https://doc.owncloud.org/server/9.0/admin_manual/issues/code_signing.html#errors et
  # https://stackoverflow.com/questions/35954919/owncloud-9-code-signing-and-htaccess
  sed -i "/);/i 'integrity.check.disabled' => true," $ocpath/config/config.php
  echo "*************************************"
  echo "|       upload_max_filesize         |"
  echo "|   et post_max_size paramétrés     |"
  echo "| ajout de integrity.check.disabled |"
  echo "*************************************"
fi

chown -R ${htuser}:${htgroup} ${ocpath}/  # autoriser l'exécution de occ

################################################################################
## partage du rep downloads de l'utilisateur et install audioplayer
if [[ $addStorage =~ [oO] ]]; then
  sudo -u $htuser $ocpath/occ app:enable files_external
  sudo -u $htuser $ocpath/occ files_external:create Downloads \\OC\\Files\\Storage\\Local null::null
  sudo -u $htuser $ocpath/occ files_external:config 1 datadir \/home\/${FIRSTUSER[0]}\/downloads
  sudo -u $htuser $ocpath/occ files_external:option 1 enable_sharing true
  sudo -u $htuser $ocpath/occ files_external:applicable --add-user=${FIRSTUSER[0]} 1
  sudo -u $htuser $ocpath/occ files_external:verify 1
  if [[ $? -ne 0 ]]; then
    echo
    echo "Erreur au paramétrage du stockage externe vers /home/${FIRSTUSER[0]}/downloads"
    echo "Ne remet pas en cause l'installation de ownCloud"
    echo
    sleep 1.5
  else
    echo "***************************************"
    echo "|        stockage externe ok          |"
    echo "| sur /home/${FIRSTUSER[0]}/downloads |"
    echo "***************************************"
  fi
fi
if [[ $addAudioPlayer =~ [oO] ]]; then
  wget https://github.com/Rello/audioplayer/archive/master.zip -O $ocpath/apps/master.zip
  unzip $ocpath/apps/master.zip -d $ocpath/apps/
  mv $ocpath/apps/audioplayer-master  $ocpath/apps/audioplayer
  rm $ocpath/apps/master.zip
  chown -R $htuser:$htgroup $ocpath/apps/audioplayer
  sudo -u $htuser $ocpath/occ app:enable audioplayer
  if [[ $? -ne 0 ]]; then
    echo
    echo "Erreur à l'installation de Audio Player"
    echo "Ne remet pas en cause l'installation de ownCloud"
    echo
    sleep 1.5
  else
    ############################################################################
    ## install et param de iwatch
    apt-get -yq install iwatch  # ok deb, ubuntu ?
    cp /etc/iwatch/iwatch.dtd /etc/iwatch/iwatch.dtd-dist
    sed -i -e "s/<!ELEMENT watchlist (title,contactpoint,path+)>/<!ELEMENT watchlist (title,path+)>/" \
      -e "/<!ELEMENT contactpoint (#PCDATA)>/,/>/d" /etc/iwatch/iwatch.dtd

    cp /etc/iwatch/iwatch.xml /etc/iwatch/iwatch.xml-dist
    sed -i -e 's/<title>Operating System<\/title>/<title>AudioplayerOC<\/title>/'\
      -e '/<contactpoint email="root@localhost" name="Administrator"\/>/d' \
      -e '/<path type/,/modules<\/path>/d' \
      -e '/<title>AudioplayerOC<\/title>/ a\<path type="recursive" syslog="off" events="close_write,move,delete,delete_self,move_self" exec="\/home\/'${FIRSTUSER[0]}'\/HiwsT\/insert\/scanOC.sh %e %f '${FIRSTUSER[0]}'">\/var\/www\/owncloud\/data\/'${FIRSTUSER[0]}'\/files<\/path>' /etc/iwatch/iwatch.xml

    sed -i 's/START_DAEMON=.*/START_DAEMON=true/' /etc/default/iwatch

    if [[ $addStorage =~ [oO] ]]; then
      sed -i '/<path type="recursive".*/ a\<path type="recursive" syslog="off" events="close_write,move,delete,delete_self,move_self" exec="\/home\/'${FIRSTUSER[0]}'\/HiwsT\/insert\/scanOC.sh %e %f '${FIRSTUSER[0]}'">\/home\/'${FIRSTUSER[0]}'\/downloads<\/path>\n<path type="exception">\/home\/'${FIRSTUSER[0]}'\/downloads\/.session<\/path>\n<path type="exception">\/home\/'${FIRSTUSER[0]}'\/downloads\/watch<\/path>'  /etc/iwatch/iwatch.xml
    fi

    service iwatch restart
    service iwatch status
    if [[ $? -ne 0 ]]; then
      __messageBox "Installation Audio-player" "Installation réussie
mais sans iwatch (problème au paramétrage)"
    else
    __messageBox "Installation Audio-player" "Installation réussie
les modifications sur les répertoires owncloud/data/${FIRSTUSER[0]}
( et /home/${FIRSTUSER[0]}/downloads si stockage externe activé )
mises à jour automatiquement dans Audio-player"
    fi
    clear
  fi
fi

################################################################################
##  Sur config/config.php ajouter à trusted_domains notre IP
sed -i "/0 => 'localhost',/a 1 => '"$IP"'," $ocpath/config/config.php

################################################################################
## modif des droits
echo -e "\nCréation de répertoires si nécessaire\n" # "Creating possible missing Directories\n"
mkdir -p $ocpath/data
mkdir -p $ocpath/assets
mkdir -p $ocpath/updater

echo -e "\nModification des droits\n" # "chmod Files and Directories\n"
find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750

echo -e "\nModification du propriétaire des répertoires\n" # "chown Directories\n"
chown -R ${rootuser}:${htgroup} ${ocpath}/
chown -R ${htuser}:${htgroup} ${ocpath}/apps/
chown -R ${htuser}:${htgroup} ${ocpath}/assets/
chown -R ${htuser}:${htgroup} ${ocpath}/config/
chown -R ${htuser}:${htgroup} ${ocpath}/data/
chown -R ${htuser}:${htgroup} ${ocpath}/themes/
chown -R ${htuser}:${htgroup} ${ocpath}/updater/

chmod +x ${ocpath}/occ

echo -e "\nchmod et chown .htaccess\n"
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

echo "*************************"
echo "|    Droits modifiés    |"
echo "*************************"

echo
echo "***************************"
echo "|  Installation terminée  |"
echo "***************************"

sleep 2

# debug :
# apt-get install phpmyadmin
# service php7.0-fpm status
