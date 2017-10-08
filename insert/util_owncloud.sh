clear

readonly htuser='www-data'
readonly htgroup='www-data'
readonly rootuser='root'

################################################################################
wget https://download.owncloud.org/community/owncloud-10.0.2.tar.bz2
wget https://download.owncloud.org/community/owncloud-10.0.2.tar.bz2.md5
md5sum -c owncloud-10.0.2.tar.bz2.md5 < owncloud-10.0.2.tar.bz2 || __msgErreurBox "md5sum -c owncloud-10.0.2.tar.bz2.md5 < owncloud-10.0.2.tar.bz2" $?

wget https://owncloud.org/owncloud.asc
wget https://download.owncloud.org/community/owncloud-10.0.2.tar.bz2.asc
gpg --import owncloud.asc &>/dev/null
gpg --verify owncloud-10.0.2.tar.bz2.asc || __msgErreurBox "gpg --verify owncloud-10.0.2.tar.bz2.asc" $?

tar -xjf owncloud-10.0.2.tar.bz2
mv owncloud $ocpath
if [[ $nameDistrib == "Debian" ]] && [[ $os_version_M -eq 8 ]]; then
  cmd="apt-get -yq install mariadb-server php5-gd php5-mysql php5-intl imagemagick-6.defaultquantum php5-imagick php5-apcu apcupsd php5-redis redis-server libzip2 php-pclzip php5-imap"; $cmd || __msgErreurBox "$cmd" $?
elif [[ $nameDistrib == "Debian" ]] && [[ $os_version_M -eq 9 ]]; then
  cmd="apt-get -yq install default-mysql-server php7.0-mbstring php7.0-xml php7.0-gd php7.0-mysql php7.0-intl php7.0-imagick php-apcu apcupsd php-redis redis-server libzip4  php7.0-zip php7.0-imap"; $cmd || __msgErreurBox "$cmd" $?
else  # Ubuntu
  cmd="apt-get -yq install mariadb-server php7.0-mbstring php7.0-xml php7.0-gd php7.0-mysql php7.0-intl php-imagick php-apcu apcupsd php-redis redis-server libzip4 php7.0-zip php7.0-imap"; $cmd || __msgErreurBox "$cmd" $?
fi

a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime
a2enmod proxy_fcgi setenvif

__servicerestart $PHPVER
  if [[ $? -eq 0 ]]; then
    echo "**************************************"
    echo "|  php restart (APCu anbd Redis) ok  |"
    echo "**************************************"
    sleep 1.5
  fi
################################################################################
# install de postfix et mailutils si pas présents
which mailutils 2>&1 > /dev/null
if [ $? != 0 ]; then
  __messageBox "postfix/mailutils install" "
Validate the default values"
  cmd="apt-get -yq install mailutils postfix"; $cmd || __msgErreurBox "$cmd" $?
  service postfix reload
  __servicerestart "postfix"
  if [[ $? -eq 0 ]]; then
    echo "**************************"
    echo "|    postfix start ok    |"
    echo "**************************"
  fi
fi

echo "*************************"
echo "|  Packages installed   |"
echo "*************************"
sleep 1.5

################################################################################
# paramétrage apache
cp $REPLANCE/fichiers-conf/apa_site_owncloud.conf $REPAPA2/sites-available/owncloud.conf
cp $REPLANCE/fichiers-conf/apa_conf_owncloud.conf $REPAPA2/conf-available/owncloud.conf

[[ ! -e $REPAPA2/sites-enabled/owncloud.conf ]] && \
  ln -s $REPAPA2/sites-available/owncloud.conf $REPAPA2/sites-enabled/owncloud.conf

[[ ! -e $REPAPA2/conf-enabled/owncloud.conf ]] && \
  ln -s $REPAPA2/conf-available/owncloud.conf $REPAPA2/conf-enabled/owncloud.conf

# L'en-tête HTTP "Strict-Transport-Security" n'est pas configurée à "15552000" secondes.
# Pour renforcer la sécurité nous recommandons d'activer HSTS cf. Guide pour le renforcement et la sécurité.
# ==> man-in-the-middle attacks https://79.137.33.190/owncloud/index.php/settings/help?mode=admin
sed -i '/<VirtualHost _default_:443>/a <IfModule mod_headers.c>\n  Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"\n</IfModule>' $REPAPA2/sites-available/default-ssl.conf

__servicerestart "apache2"
if [[ $? -eq 0 ]]; then
  echo "**************************"
  echo "|  apache setting-up ok  |"
  echo "**************************"
  sleep 1.5
fi
################################################################################
## si $ocDataDir modifié le créer et lui donner le bon proprio
if [[ ${ocDataDi}r != "/var/www/owncloud/data" ]]; then
  mkdir -p ${ocDataDir}
  chown -R ${htuser}:${htgroup} ${ocDataDir}
fi

################################################################################
## création base de données
echo "*************************************************************************"
echo "|        Creating the owncloud database and its administrator           |"
echo "| Enter the root password you entered in the mySql/mariadb installation |"
echo "|          Or leave blank if you have not entered anything              |"
echo "*************************************************************************"
mysql -tp <<EOF
CREATE DATABASE IF NOT EXISTS owncloud;
show databases;
GRANT ALL PRIVILEGES ON owncloud.* TO '`echo $userBdD`'@'localhost' IDENTIFIED BY '`echo $pwBdD`';
\q
EOF

if [[ $? -ne 0 ]]; then
  echo
  echo "Error creating the owncloud database!!!"
  exit 1
else
  echo "*****************************************************"
  echo "|  owncloud database and its administrator created  |"
  echo "*****************************************************"
  sleep 1.5
fi

################################################################################
## finalisation de l'installation remplace la GUI
# maintenance:install [--database DATABASE] [--database-name DATABASE-NAME] [--database-host DATABASE-HOST] [--database-user DATABASE-USER] [--database-pass [DATABASE-PASS]] [--database-table-prefix [DATABASE-TABLE-PREFIX]] [--admin-user ADMIN-USER] [--admin-pass ADMIN-PASS] [--data-dir DATA-DIR]
chown -R ${htuser}:${htgroup} ${ocpath}/  # autoriser l'exécution de occ et l'accès à www-data
sudo -u $htuser mkdir -p $ocDataDir
sudo -u $htuser $ocpath/occ  maintenance:install --database "mysql" --database-name "owncloud"  --database-user $userBdD --database-pass $pwBdD --admin-user ${FIRSTUSER[0]} --admin-pass $pwFirstuser --data-dir $ocDataDir
if [[ $? -ne 0 ]]; then
  echo
  echo "Error in owncloud finalizing the installation"
  echo
  exit 1
else
  echo "*************************************"
  echo "|       Finalized installation      |"
  echo "|     Database and admin-user set   |"
  echo "*************************************"
  sleep 1.5
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
  echo "**********************************"
  echo "|      upload_max_filesize       |"
  echo "|      and post_max_size set     |"
  echo "|  add integrity.check.disabled  |"
  echo "**********************************"
  sleep 1.5
fi

################################################################################
## partage du rep downloads de l'utilisateur et install audioplayer
if [[ $addStorage =~ [yY] ]]; then
  sudo -u $htuser $ocpath/occ app:enable files_external
  sudo -u $htuser $ocpath/occ files_external:create Downloads \\OC\\Files\\Storage\\Local null::null
  sudo -u $htuser $ocpath/occ files_external:config 1 datadir \/home\/${FIRSTUSER[0]}\/downloads
  sudo -u $htuser $ocpath/occ files_external:option 1 enable_sharing true
  sudo -u $htuser $ocpath/occ files_external:applicable --add-user=${FIRSTUSER[0]} 1
  verify=$(sudo -u $htuser $ocpath/occ files_external:verify 1)
  echo $verify | grep ok
  if [[ $? -ne 0 ]]; then
    echo
    echo "Error setting external storage to /home/${FIRSTUSER[0]}/downloads"
    echo "Does not impact main owncloud installation"
    echo
    sleep 3
  else
    echo "**************************************"
    echo "|    External storage support ok     |"
    echo "|  on /home/${FIRSTUSER[0]}/downloads  |"
    echo "**************************************"
    sleep 1.5
  fi
fi
if [[ $addAudioPlayer =~ [yY] ]]; then
  cmd="wget https://github.com/Rello/audioplayer/releases/download/2.1.0/audioplayer-2.1.0.zip -O $ocpath/apps/audioplayer-2.1.0.zip"; $cmd || __msgErreurBox "$cmd" $?
  cmd="unzip $ocpath/apps/audioplayer-2.1.0.zip -d $ocpath/apps"; $cmd || __msgErreurBox "$cmd" $?
  rm $ocpath/apps/audioplayer-2.1.0.zip
  chown -R $htuser:$htgroup $ocpath/apps/audioplayer
  verify=$(sudo -u $htuser $ocpath/occ app:enable audioplayer)
  echo $verify | grep enabled
  if [[ $? -ne 0 ]]; then
    echo
    echo "Error Audio Player install"
    echo "Does not impact main owncloud installation"
    echo
    sleep 3
  else
    ############################################################################
    ## install et param de iwatch
    cmd="apt-get -yq install iwatch"; $cmd || __msgErreurBox "$cmd" $?
    cp /etc/iwatch/iwatch.dtd /etc/iwatch/iwatch.dtd-dist
    sed -i -e "s/<!ELEMENT watchlist (title,contactpoint,path+)>/<!ELEMENT watchlist (title,path+)>/" \
      -e "/<!ELEMENT contactpoint (#PCDATA)>/,/>/d" /etc/iwatch/iwatch.dtd   # de <!ELEMENT contactpoint (#PCDATA)> au ">" suivant

    cp /etc/iwatch/iwatch.xml /etc/iwatch/iwatch.xml-dist
    cp -p $REPLANCE/insert/scanOC.sh /etc/iwatch/scanOC.sh
    sed -i -e 's/<title>Operating System<\/title>/<title>AudioplayerOC<\/title>/'\
      -e '/<contactpoint email="root@localhost" name="Administrator"\/>/d' \
      -e '/<path type/,/modules<\/path>/d' \
      -e '/<title>AudioplayerOC<\/title>/ a\<path type="recursive" syslog="off" events="close_write,move,delete,delete_self,move_self" exec="\/etc\/iwatch\/scanOC.sh %e %f">'$ocDataDir'\/'${FIRSTUSER[0]}'\/files<\/path>' /etc/iwatch/iwatch.xml

    sed -i 's/START_DAEMON=.*/START_DAEMON=true/' /etc/default/iwatch

    if [[ $addStorage =~ [yY] ]]; then
      sed -i '/<path type="recursive".*/ a\<path type="recursive" syslog="off" events="close_write,move,delete,delete_self,move_self" exec="\/etc\/iwatch\/scanOC.sh %e %f">\/home\/'${FIRSTUSER[0]}'\/downloads<\/path>\n<path type="exception">\/home\/'${FIRSTUSER[0]}'\/downloads\/.session<\/path>\n<path type="exception">\/home\/'${FIRSTUSER[0]}'\/downloads\/watch<\/path>'  /etc/iwatch/iwatch.xml
    fi

    __servicerestart "iwatch"
    if [[ $? -ne 0 ]]; then
      __messageBox "Audio-player install" "Successful installation
but without iwatch (setup issue)"
    else
    __messageBox "Audio-player install" "Successful installation
Changes to directories owncloud/data/${FIRSTUSER[0]}
( and /home/${FIRSTUSER[0]}/downloads if External Storage is enabled )
Will be automatically updated in Audio-player (Thanks to iwatch)"
    fi
    ## logrotate
    cp $REPLANCE/fichiers-conf/scanOC-rotate /etc/logrotate.d/scanOC-rotate
    logrotate -f /etc/logrotate.conf
    if [[ $? -eq 0 ]]; then
      echo
      echo "*********************************"
      echo "|   rotate of owncloud.log ok   |"
      echo "*********************************"
      echo
      sleep 1
    else
      echo
      echo "****************************************"
      echo "|              WARNING !               |"
      echo "|   issue on rotate of owncloud.log    |"
      echo "****************************************"
      echo
      sleep 2
    fi
  fi
fi

################################################################################
##  Sur config/config.php ajouter à trusted_domains notre IP
##  Après maintenance:install si non config.php n'existe pas
##  domaines approuvés IP + noms de domaine
sed -i "/0 => 'localhost'/a 1 => '"$IP"'," $ocpath/config/config.php
serverName=$(cat $REPAPA2/sites-available/000-default.conf | egrep "^ServerName" | awk -F" " '{print $2}')
if [[ $serverName != "" ]]; then   # Si nom de domaine
  serverNameAlias="www."$serverName
  sed -i "/1 => '"$IP"'/a\ 2 => '"$serverName"',\n 3 => '"$serverNameAlias"', "  $ocpath/config/config.php
fi
##  Prise en compte du memcache APCu/Redis
sed -i "/);/i 'memcache.local' => '\\\OC\\\Memcache\\\APCu',\n'memcache.locking' => '\\\OC\\\Memcache\\\Redis',\n'redis' => array(\n     'host' => 'localhost',\n     'port' => 6379,\n      )," $ocpath/config/config.php

################################################################################
## modif des droits
echo -e "\nCreating possible missing Directories\n"
mkdir -p $ocpath/data
mkdir -p $ocpath/assets
mkdir -p $ocpath/updater

echo -e "\nchmod Files and Directories\n"
find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750
if [[ ${ocDataDir} != "/var/www/owncloud/data" ]]; then
  echo -e "\nchown and chmod for new owncloud data directory\n"
  find ${ocDataDir}/ -type f -print0 | xargs -0 chmod 0640
  find ${ocDataDir}/ -type d -print0 | xargs -0 chmod 0750
  ocDataDirRoot=$(echo $ocDataDir | sed 's/\/data\/*$//')
  chmod 750 ${ocDataDirRoot}  # - /data(/)
  chown ${rootuser}:${htgroup} ${ocDataDirRoot} # - /data(/)
fi

echo -e "\nchown Directories\n"
chown -R ${rootuser}:${htgroup} ${ocpath}/
chown -R ${htuser}:${htgroup} ${ocpath}/apps/
chown -R ${htuser}:${htgroup} ${ocpath}/assets/
chown -R ${htuser}:${htgroup} ${ocpath}/config/
chown -R ${htuser}:${htgroup} ${ocpath}/data/
chown -R ${htuser}:${htgroup} ${ocpath}/themes/
chown -R ${htuser}:${htgroup} ${ocpath}/updater/

chmod +x ${ocpath}/occ

echo -e "\nchmod and chown .htaccess\n"
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
rm $REPLANCE/owncloud*.*

echo "*************************************"
echo "|  Permissions and owners modified  |"
echo "*************************************"

echo
echo -n "      "; sudo -u $htuser $ocpath/occ -V
echo "****************************"
echo "|  Installation completed  |"
echo "****************************"

sleep 2
# why i don't know, but necessary, the first restart is not enough
if [[ $(pgrep iwatch) -ne 0 ]]; then service restart iwatch; fi
