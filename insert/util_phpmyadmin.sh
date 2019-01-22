__phpmyadmin() {
  clear
  apt-get update

  if [[ $nameDistrib == "Debian" ]] && [[ $os_version_M -eq 8 ]]; then
    cmd="apt-get -yq install mariadb-server phpmyadmin"; $cmd || __msgErreurBox "$cmd" $?
  elif [[ $nameDistrib == "Debian" ]] && [[ $os_version_M -eq 9 ]]; then
    cmd="apt-get -yq install mariadb-server phpmyadmin"; $cmd || __msgErreurBox "$cmd" $?
  else  # Ubuntu
    cmd="apt-get -yq install mariadb-server phpmyadmin"; $cmd || __msgErreurBox "$cmd" $?
  fi
  if [[ $? -eq 0 ]]; then
    echoc v "    Packages Installed     "
    echo
    sleep 1
    headTest=$(curl -Is http://$IP/phpmyadmin | head -n 1 | awk -F" " '{ print $2 }')
    if [[ "$headTest" =~ "301" ]]; then
      echoc v "                           "
      echoc v "   phpMyAdmin works well   "
      echoc v "                           "
      sleep 3
      cat << EOF >> $REPUL/HiwsT/RecapInstall.txt

To access phpMyAdmin:
    https://$IP/phpmyadmin
    ID : phpmyadmin  PW : the password you entered during installation
    Without Let's Encrypt accept the Self Signed Certificate
    and the exception for this certificate!
EOF
    __messageBox "phpMyAdmin installed" " ${I}phpMyAdmin works well${N}

      To access phpMyAdmin
      https://$IP/phpmyadmin
      ID : phpmyadmin  PW : the password you just entered

      Without Let's Encrypt accept the Self Signed Certificate
      and the exception for this certificate!

      This information is added to the file $REPUL/HiwsT/RecapInstall.txt"
    else
      __msgErreurBox "curl -Is http://$IP/phpmyadmin | head -n 1 | awk -F\" \" '{ print $2 }' renvoie '$headTest'" "http $headTest"
    fi
  fi
}
