
__userExist() {   #  appelée par __IDuser  et autres f()  $user = $1
	# user linux ?
	egrep "^$1" /etc/passwd >/dev/null
	userL=$?
	# user ruTorrent ?
	egrep "^$1:rutorrent" $REPAPA2/.htpasswd > /dev/null
	userR=$?
	# user cakebox ?
	egrep "^$1" $REPWEB/cakebox/public/.htpasswd > /dev/null
	userC=$?
# renvoie $userC $userR $userL = 0 existe = 1 n'existe pas
}


__creaUserRutoPasswd() {   # appelée par __creaUserRuto   $1 $userRuto   $2 $pwRuto
  # sécuriser ruTorrent
  (echo -n "$1:rutorrent:" && echo -n "$1:rutorrent:$2" | md5sum) >> $REPAPA2/.htpasswd
  sed -i 's/[ ]*-$//' $REPAPA2/.htpasswd
  # service apache2 restart
  # if [[ $? -eq o ]]; then
  # 	echo "Mot de passe de $1 créé"
  # 	echo
  # else
  #   service apache2 status
  # 	__messageErreur
  # 	exit 1
  # fi
# ne renvoie rien
}

__creaUserCakeConfSite() {  #  appelée par __creaUserCake  $1 $userCake
  # - ajout dans cakebox.conf apache
  sed -i '/ErrorLog.*/ i\\n    Alias /access /home/'$1'/downloads/\n    <Directory "/home/'$1'/downloads">\n        Options -Indexes\n\n        <IfVersion >= 2.4>\n            Require all granted\n        </IfVersion>\n        <IfVersion < 2.4>\n            Order allow,deny\n            Allow from all\n        </IfVersion>\n        Satisfy Any\n\n        Header set Content-Disposition "attachment"\n\n    </Directory>\n' $REPAPA2/sites-available/cakebox.conf
  service apache2 restart
  if [[ $? -eq o ]]; then
    echo
    echo "cakebox.conf dans apache modifié"
    echo
  else
    service apache2 status
  	__messageErreur
  	exit 1
  fi
# ne renvoie rien
}


__creaUserCakePasswd() {   # appelée par __creaUserCake  $1 $userCake $2 $pwCake
  # mot de passe
  htpasswd -b $REPWEB/cakebox/public/.htpasswd $1 $2
  echo
  echo "Mot de passe de $1 créé"
  echo
}


__suppUserCakePasswd() {  # appelée par __suppUserCake  $1 $userCake
  sed -i "s/^"$1".*//" $REPWEB/cakebox/public/.htpasswd
  echo "Mot de passe supprimé"
	echo
# ne renvoie rien
}


__suppUserCakeConfSite() {   # appelée par __suppUserCake  $1 $userCake
# supprimer dans cakebox.conf
  sed -i '/    Alias \/access \/home\/'$1'\/downloads\//,/    <\/Directory>/d' $REPAPA2/sites-available/cakebox.conf
  service apache2 restart
  if [[ $? -eq o ]]; then
    echo
    echo "cakebox.conf dans apache modifié"
    echo
  else
    service apache2 status
  	__messageErreur
  	exit 1
  fi
}


__suppUserRutoPasswd() {  #  appelée par __suppUserRuto  $1 $userRuto
  # mot de passe rutorrent
  sed -i "s/^"$1".*//" $REPAPA2/.htpasswd
  echo "Mot de passe supprimé"
  echo
}


__changePWRuto() {   #  appelée par __changePW  $1 user  $2 pw
  sed -i "s/^"$1".*//" $REPAPA2/.htpasswd
	(echo -n "$1:rutorrent:" && echo -n "$1:rutorrent:$2" | md5sum) >> $REPAPA2/.htpasswd
	sed -i 's/[ ]*-$//' $REPAPA2/.htpasswd
# ne renvoie rien
}


__changePWCake() {  #  appelée par __changePW  $1 user  $2 pw
  htpasswd -b $REPWEB/cakebox/public/.htpasswd $1 $2
  sortie=$?
# Renvoie $sortie
}
