
# trap for exit
__trap() {  # pour exit supprime affiche la dernière erreur
  export -n OC_PASS
  if [ -e $REPWEB/info.php ]; then rm $REPWEB/info.php; fi
  if [ -s /tmp/trace.log ]; then  # taille fichier > 0 ;)
    echo "/tmp/trace.log:"; echo
    cat /tmp/trace.log
  fi
}

# Restar service with . Depend __msgErreur
# ARG : service name
__servicerestart() {
  service "${1}" restart
  codeSortie=$?
  cmd="service ${1} status"; $cmd || __msgErreurBox "$cmd" $?
  return $codeSortie
}  #  fin __servicerestart

# Va chercher un UID et PW de mysql dans /etc/mysql/debian.cnf
# ARG : no
# RETUN : $userBdD et $pwBdD
__mySqlDebScript() {
  userBdD=$(grep -m 1 "user" /etc/mysql/debian.cnf | awk -F"= " '{ print $2 }') || \
      __msgErreurBox "userBdD=$(grep -m 1 user /etc/mysql/debian.cnf | awk -F\"= \" '{ print $2 }')" $?
  pwBdD=$(grep -m 1 "password" /etc/mysql/debian.cnf | awk -F"= " '{ print $2 }') || \
      __msgErreurBox "pwBdD=$(grep -m 1 password /etc/mysql/debian.cnf | awk -F\"= \" '{ print $2 }')" $?
}
