############################################
##  création utilisateur ruTorrent Linux
############################################
__creaUserRuto () {
  # param : ${1} name user ${2} pw user"
  local codeSortie
  egrep "^sftp" /etc/group > /dev/null
  if [[ $? -ne 0 ]]; then
    addgroup sftp
  fi

  pass=$(perl -e 'print crypt($ARGV[0], "pwRuto")' ${2})
  useradd -m -G sftp -p $pass ${1}
  codeSortie=$?
  if [[ $codeSortie -ne 0 ]]; then
    __messageBox "Setting-up rutorrent user" "
      Unable to create Linux user ${1}
      'useradd' error"
    __msgErreurBox "useradd -m -G sftp -p $pass ${1}" $codeSortie
  fi
  sed -i "1 a\bash" /home/${1}/.profile

  echo "Linux user ${1} created"; echo

  mkdir -p /home/${1}/downloads/watch
  mkdir -p /home/${1}/downloads/.session
  chown -R ${1}:${1} /home/${1}/

  echo "Directory/subdirectories /home/${1} created"; echo

  #  partie rtorrent __creaUserRuto------------------------------------------------
  # incrémenter le port scgi, écrir le fichier témoin
  if [ -e $REPWEB/rutorrent/conf/scgi_port ]; then
    port=$(cat $REPWEB/rutorrent/conf/scgi_port)
  else
    port=5000
  fi

  let "port += 1"
  echo $port > $REPWEB/rutorrent/conf/scgi_port

  # rtorrent.rc
  cp $REPLANCE/fichiers-conf/rto_rtorrent.rc /home/${1}/.rtorrent.rc
  sed -i 's/<username>/'${1}'/g' /home/${1}/.rtorrent.rc
  sed -i 's/<port>/'$port'/' /home/${1}/.rtorrent.rc  #  port scgi

  echo "/home/${1}/rtorrent.rc created"; echo

  #  fichiers daemon rtorrent
  #  créer rtorrent.conf
  cp $REPLANCE/fichiers-conf/rto_rtorrent.conf /etc/init/${1}-rtorrent.conf
  chmod u+rwx,g+rwx,o+rx  /etc/init/${1}-rtorrent.conf
  sed -i 's/<username>/'${1}'/g' /etc/init/${1}-rtorrent.conf

  #  rtorrentd.sh modifié   il faut redonner aux users bash
  sed -i '/## bash/ a\          usermod -s \/bin\/bash '${1}'' /etc/init.d/rtorrentd.sh
  sed -i '/## screen/ a\          su --command="screen -dmS '${1}'-rtd rtorrent" "'${1}'"' /etc/init.d/rtorrentd.sh
  sed -i '/## false/ a\          usermod -s /bin/false '${1}'' /etc/init.d/rtorrentd.sh
  systemctl daemon-reload
  __servicerestart "rtorrentd"
  if [[ $? -eq 0 ]]; then
    echo "rtorrent daemon modified and work well."; echo
  fi
  #  fin partie rtorrent  __creaUserRuto-----------------------------------------

  #  partie rutorrent -----------------------------------------------------------
  # dossier conf/users/userRuto
  mkdir -p $REPWEB/rutorrent/conf/users/${1}
  cp $REPWEB/rutorrent/conf/access.ini $REPWEB/rutorrent/conf/plugins.ini $REPWEB/rutorrent/conf/users/${1}
  cp $REPLANCE/fichiers-conf/ruto_multi_config.php $REPWEB/rutorrent/conf/users/${1}/config.php
  sed -i -e 's/<port>/'$port'/' -e 's/<username>/'${1}'/' $REPWEB/rutorrent/conf/users/${1}/config.php
  chown -R www-data:www-data $REPWEB/rutorrent/conf/users/${1}

  # déactivation du plugin linkcakebox
  mkdir -p $REPWEB/rutorrent/share/users/${1}/torrents
  mkdir $REPWEB/rutorrent/share/users/${1}/settings
  chmod -R 777 $REPWEB/rutorrent/share/users/${1}
  echo 'a:2:{s:8:"__hash__";s:11:"plugins.dat";s:11:"linkcakebox";b:0;}' > $REPWEB/rutorrent/share/users/${1}/settings/plugins.dat
  chmod 666 $REPWEB/rutorrent/share/users/${1}/settings/plugins.dat
  chown -R www-data:www-data $REPWEB/rutorrent/share/users/${1}

  echo "Directory users/${1} created on ruTorrent"; echo

  __creaUserRutoPasswd ${1} ${2}   # insert/util_apache.sh ne renvoie rien

  # modif pour sftp / sécu sftp __creaUserRuto  ---------------------------------
  # pour user en sftp interdit le shell en fin de traitement; bloque le daemon
  usermod -s /bin/false ${1}
  # pour interdire de sortir de /home/user  en sftp
  chown root:root /home/${1}
  chmod 0755 /home/${1}

  # modif sshd_config  -------------------------------------------------------
  sed -i 's/AllowUsers.*/& '${1}'/' /etc/ssh/sshd_config
  sed -i 's|^Subsystem.*sftp.*/usr/lib/openssh/sftp-server|#  &|' /etc/ssh/sshd_config   # commente
  # pour bloquer les utilisateurs supplémentaires
  if [[ `cat /etc/ssh/sshd_config | grep "Subsystem  sftp  internal-sftp"` == "" ]]; then
    echo -e "Subsystem  sftp  internal-sftp\nMatch Group sftp\n ChrootDirectory %h\n ForceCommand internal-sftp\n AllowTcpForwarding no" >> /etc/ssh/sshd_config
  fi
  __servicerestart "sshd"
  if [[ $? -eq 0 ]]; then
    echo "SFTP security ok" # seulement accès a /home/${1}
  fi
}   #  fin __creaUserRuto
