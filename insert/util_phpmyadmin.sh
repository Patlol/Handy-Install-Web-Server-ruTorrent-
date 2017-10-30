
clear
apt-get update

if [[ $nameDistrib == "Debian" ]] && [[ $os_version_M -eq 8 ]]; then
  cmd="apt-get -yq install mariadb-server phpmyadmin"; $cmd || __msgErreurBox "$cmd" $?
elif [[ $nameDistrib == "Debian" ]] && [[ $os_version_M -eq 9 ]]; then
  cmd="apt-get -yq install mariadb-server phpmyadmin"; $cmd || __msgErreurBox "$cmd" $?
else  # Ubuntu
  cmd="apt-get -yq install mariadb-server phpmyadmin"; $cmd || __msgErreurBox "$cmd" $?
fi
if [[ $? ]]; then
  echoc v "    Packages Installed     "
  echo
  sleep 1
  headTest=$(curl -Is http://$IP/phpmyadmin | head -n 1 | awk -F" " '{ print $2 }')
  if [[ "$headTest" =~ "301" ]]; then
    echoc v "                           "
    echoc v "   phpMyAdmin works well   "
    echoc v "                           "
    sleep 3
  else
    __msgErreurBox "curl -Is http://$IP/phpmyadmin | head -n 1 | awk -F\" \" '{ print $2 }' renvoie '$headTest'" "http $headTest"
  fi
fi
