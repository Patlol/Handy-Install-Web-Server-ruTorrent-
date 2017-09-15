
__userExist() {   #  appelée par __IDuser  et autres f()  $user = ${1}
	# user linux ?
	egrep "^${1}:" /etc/passwd >/dev/null
	userL=$?
	# user ruTorrent ?
	egrep "^${1}:rutorrent" $REPAPA2/.htpasswd > /dev/null
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
  echo "Password deleted"
  echo
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
