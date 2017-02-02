
__userExist() {   #  appelée par __IDuser  et autres f()  $user = $1
	# user linux ?
	egrep "^$1:" /etc/passwd >/dev/null
	userL=$?
	# user ruTorrent ?
	egrep "^$1:" $REPNGINX/.htpasswdR > /dev/null
	userR=$?
	# user cakebox ?
	egrep "^$1:" $REPNGINX/.htpasswdC > /dev/null
	userC=$?
# renvoie $userC $userR $userL = 0 existe = 1 n'existe pas
}

__creaUserRutoPasswd() {   # appelée par __creaUserRuto   $1 $userRuto   $2 $pwRuto
  # sécuriser ruTorrent
	htpasswd -b $REPNGINX/.htpasswdR $1 $2
  service nginx restart
# ne renvoie rien
}

__creaUserCakeConfSite() {  #  appelée par __creaUserCake  $1 $userCake
  # - ajout dans cakebox.conf apache
sed -i '/## add user/ a\        location \/access\/'$1'/ {\n                alias /home/'$1'/downloads/;\n                add_header Content-Disposition "attachment";\n                satisfy any; allow all;\n         }' $REPNGINX/sites-available/cakebox

  service nginx restart
  if [[ $? -eq o ]]; then
    echo
    echo "conf du site cakebox dans nginx modifiée"
    echo
  else
    service nginx status
  	__messageErreur
  	exit 1
  fi
# ne renvoie rien
}


__creaUserCakePasswd() {   # appelée par __creaUserCake  $1 $userCake $2 $pwCake
  # mot de passe
  htpasswd -b $REPNGINX/.htpasswdC $1 $2
  echo
  echo "Mot de passe de $1 créé"
  echo
}


__suppUserCakePasswd() {  # appelée par __suppUserCake  $1 $userCake
  sed -i "s/^"$1".*//" $REPNGINX/.htpasswdC
  echo "Mot de passe supprimé"
  echo
# ne renvoie rien
}


__suppUserCakeConfSite() {   # appelée par __suppUserCake  $1 $userCake
# supprimer dans cakebox.conf
  sed -i '/        location \/access\/'$1' {/,/         }/d' $REPNGINX/sites-available/cakebox
  service nginx restart
  if [[ $? -eq o ]]; then
    echo
    echo "cakebox.conf dans nginx modifié"
    echo
  else
    service nginx status
  	__messageErreur
  	exit 1
  fi
}


__suppUserRutoPasswd() {  #  appelée par __suppUserRuto  $1 $userRuto
  # mot de passe rutorrent
  sed -i "s/^"$1".*//" $REPNGINX/.htpasswdR
  echo "Mot de passe supprimé"
  echo
}


__changePWRuto() {   #  appelée par __changePW  $1 user  $2 pw
  sed -i "s/^"$1".*//" $REPNGINX/.htpasswdR
	htpasswd -b $REPNGINX/.htpasswdR $1 $2
	sortie=$?
# Renvoie $sortie
}


__changePWCake() {  #  appelée par __changePW  $1 user  $2 pw
  sed -i "s/^"$1".*//" $REPNGINX/.htpasswdC
	htpasswd -b $REPNGINX/.htpasswdC $1 $2
  sortie=$?
# Renvoie $sortie
}
