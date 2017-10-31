
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
