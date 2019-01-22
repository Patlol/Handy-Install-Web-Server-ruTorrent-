
__userExist() {   #  appelée par __IDuser  et autres f()  $user = ${1}
  # user linux ?
  grep -E "^${1}:" /etc/passwd > /dev/null 2>&1
  userL=$?
  # user ruTorrent ?
  grep -E "^${1}:rutorrent" $REPAPA2/.htpasswd > /dev/null 2>&1
  userR=$?
  # renvoie $userR $userL = 0 existe = 1 n'existe pas
}


__creaUserRutoPasswd() {   # appelée par __creaUserRuto   ${1} $userRuto   ${2} $pwRuto
  # sécuriser ruTorrent
  (echo -n "${1}:rutorrent:" && echo -n "${1}:rutorrent:${2}" | md5sum) >> $REPAPA2/.htpasswd
  sed -i 's/[ ]*-$//' $REPAPA2/.htpasswd
  # ne renvoie rien
}


__suppUserRutoPasswd() {  #  appelée par __suppUserRuto  ${1} $userRuto
  # mot de passe rutorrent
  sed -i "s/^"${1}".*//" $REPAPA2/.htpasswd
  echo "Password deleted"; echo
}


__changePWRuto() {   #  appelée par __changePW  ${1} user  ${2} pw
  sed -i "s/^"${1}".*//" $REPAPA2/.htpasswd
  sortieCmd1=$?
  (echo -n "${1}:rutorrent:" && echo -n "${1}:rutorrent:${2}" | md5sum) >> $REPAPA2/.htpasswd
  sortieCmd2=$?
  sed -i 's/[ ]*-$//' $REPAPA2/.htpasswd
  sortieCmd3=$?
  let "total = $sortieCmd1 + $sortieCmd2 + $sortieCmd3"
  return $total
}


__setupApacheRuto() {
  # mot de passe user rutorrent  htpasswd
  (echo -n "$userRuto:rutorrent:" && echo -n "$userRuto:rutorrent:$pwRuto" | md5sum) > $REPAPA2/.htpasswd
  sed -i 's/[ ]*-$//' $REPAPA2/.htpasswd

  # Modifier la configuration du site par défaut (pour rutorrent)
  cp $REPAPA2/sites-available/000-default.conf $REPAPA2/sites-available/000-default.conf.old
  cp ${REPLANCE}/fichiers-conf/apa_000-default.conf $REPAPA2/sites-available/000-default.conf
  sed -i 's/<server IP>/'$IP'/g' $REPAPA2/sites-available/000-default.conf

  cp $REPAPA2/sites-available/default-ssl.conf $REPAPA2/sites-available/default-ssl.conf.old

  sed -i "/<\/VirtualHost>/i \<Location /rutorrent>\nAuthType Digest\nAuthName \"rutorrent\"\nAuthDigestDomain \/var\/www\/html\/rutorrent\/ http:\/\/$IP\/rutorrent\n\nAuthDigestProvider file\nAuthUserFile \/etc\/apache2\/.htpasswd\nRequire valid-user\nSetEnv R_ENV \"\/var\/www\/html\/rutorrent\"\n<\/Location>\n" $REPAPA2/sites-available/default-ssl.conf

  __servicerestart "apache2"
}
