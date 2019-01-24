############################################
##  création utilisateur ruTorrent Linux
############################################
__creaUserRuto () {
  # param : ${1} name user ${2} pw user"
  local codeSortie
  grep -E "^sftp" /etc/group > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    addgroup sftp
  fi

  salt=$(perl -e '@c=("A".."Z","a".."z",0..9);print join("",@c[map{rand @c}(1..2)])')
  pass=$(perl -e 'print crypt($ARGV[0], $ARGV[1])' ${2} $salt)
  useradd -m -G sftp -p $pass ${1}
  codeSortie=$?
  if [[ $codeSortie -ne 0 ]]; then
    __messageBox "Setting-up Linux user" "
      Unable to create Linux user ${1}
      'useradd' error"
    __msgErreurBox "useradd -m -G sftp -p $pass ${1}" $codeSortie
  fi
  sed -i "1 a\bash" /home/${1}/.profile

  echoc v " Linux user ${1} created "; echo

  mkdir -p /home/${1}/downloads/watch
  mkdir -p /home/${1}/downloads/.session
  chown -R ${1}:${1} /home/${1}/

  echoc v " Directory/subdirectories /home/${1} created "; echo

  #  partie rtorrent __creaUserRuto------------------------------------------------
  #  incrémenter le port scgi, écrire le fichier témoin
  #if [[ -e $REPWEB/rutorrent/conf/scgi_port ]]; then
  PORT_SCGI=$(cat $REPWEB/rutorrent/conf/scgi_port)
  # else
  #  touch $REPWEB/rutorrent/conf/scgi_port
  #  PORT_SCGI=5000
  # fi

  let "PORT_SCGI += 1"
  echo $PORT_SCGI > $REPWEB/rutorrent/conf/scgi_port
  echoc v "SCGI port used for this new user: ${PORT_SCGI}"; echo

  # rtorrent.rc
  cp $REPLANCE/fichiers-conf/rto_rtorrent.rc /home/${1}/.rtorrent.rc
  sed -i 's/<username>/'${1}'/g' /home/${1}/.rtorrent.rc
  sed -i 's/<port>/'$PORT_SCGI'/' /home/${1}/.rtorrent.rc  #  port scgi

  echoc v " /home/${1}/rtorrent.rc created "; echo

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
    echoc v " rtorrent daemon modified and work well. "; echo
  fi
  #  fin partie rtorrent  __creaUserRuto-----------------------------------------

  #  partie rutorrent -----------------------------------------------------------
  # dossier conf/users/userRuto
  mkdir -p $REPWEB/rutorrent/conf/users/${1}
  cp $REPWEB/rutorrent/conf/access.ini $REPWEB/rutorrent/conf/plugins.ini $REPWEB/rutorrent/conf/users/${1}
  cp $REPLANCE/fichiers-conf/ruto_multi_config.php $REPWEB/rutorrent/conf/users/${1}/config.php
  sed -i -e 's/<port>/'$PORT_SCGI'/' -e 's/<username>/'${1}'/' $REPWEB/rutorrent/conf/users/${1}/config.php
  chown -R www-data:www-data $REPWEB/rutorrent/conf/users/${1}

  # déactivation du plugin linkcakebox
  mkdir -p $REPWEB/rutorrent/share/users/${1}/torrents
  mkdir $REPWEB/rutorrent/share/users/${1}/settings
  chmod -R 777 $REPWEB/rutorrent/share/users/${1}
  echo 'a:2:{s:8:"__hash__";s:11:"plugins.dat";s:11:"linkcakebox";b:0;}' > $REPWEB/rutorrent/share/users/${1}/settings/plugins.dat
  chmod 666 $REPWEB/rutorrent/share/users/${1}/settings/plugins.dat
  chown -R www-data:www-data $REPWEB/rutorrent/share/users/${1}

  # modif du thème de rutorrent
  echo 'O:6:"rTheme":2:{s:4:"hash";s:9:"theme.dat";s:7:"current";s:8:"Oblivion";}' > $REPWEB/rutorrent/share/users/${1}/settings/theme.dat
  chmod u+rwx,g+rx,o+rx $REPWEB/rutorrent/share/users/${1}
  chmod 666 $REPWEB/rutorrent/share/users/${1}/settings/theme.dat
  chown www-data:www-data $REPWEB/rutorrent/share/users/${1}/settings/theme.dat

  echoc v " Directory users/${1} created on ruTorrent "; echo

  __creaUserRutoPasswd "${1}" "${2}"   # insert/util_apache.sh ne renvoie rien

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
  if [[ $(grep "Subsystem  sftp  internal-sftp" /etc/ssh/sshd_config) == "" ]]; then
    echo -e "Subsystem  sftp  internal-sftp\nMatch Group sftp\n ChrootDirectory %h\n ForceCommand internal-sftp\n AllowTcpForwarding no" >> /etc/ssh/sshd_config
  fi
  __servicerestart "sshd"
  if [[ $? -eq 0 ]]; then
    echoc v " SFTP security ok " # seulement accès a /home/${1}
  fi
  echo
  echoc v "                                "
  echoc v "   All is ok for the new user   "
  echoc v "                                "
  sleep 2
}   #  fin __creaUserRuto
