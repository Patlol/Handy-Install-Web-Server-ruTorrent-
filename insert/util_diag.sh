__diag() {
  clear
  echo
  lsb_release -a
  echo
  echo "http server:    $SERVEURHTTP"
  echo
  echo "IP: $IP"
  echo "Host Name: $HOSTNAME"
  serverName=$(grep -E "^ServerName" $REPAPA2/sites-available/000-default.conf | awk -F" " '{print $2}')
  if [[ -n "$serverName" ]]; then   # Si nom de domaine
    echo "Domain name: $serverName"
    echo
    echo "Certificates ssl"
    certbot certificates
  fi
  echo
  echoc v "  RAM:  "
  echo
  free -h
  echo
  echo "-------------------------------------------------------------------------------"
  echoc v "  Disks:  "
  echo
  df -h
  echo
  echo "-------------------------------------------------------------------------------"
  echoc v "  firewall: ufw show listening  "
  echo
  ufw show listening 2>/dev/null
  [[ $? -ne 0 ]] && echoc r " Ufw is not installed "
  echo "-------------------------------------------------------------------------------"
  echoc v "  firewall: ufw status verbose  "
  echo
  ufw status verbose 2>/dev/null
  [[ $? -ne 0 ]] && echoc r " Ufw is not installed "
  echo "-------------------------------------------------------------------------------"
  echoc v "  apache2:  "
  echo
  service apache2 status
  echo
  echo "-------------------------------------------------------------------------------"
  echoc v "  php-fpm:  "
  echo
  service $PHPVER status
  echo
  echo "-------------------------------------------------------------------------------"
  echoc v "  sshd:  "
  echo
  service sshd status
  echo
  echo "-------------------------------------------------------------------------------"
  echoc v "  rtorrentd:  "
  echo
  service rtorrentd status
  echo
  ps -aux | grep '.torrent$'
  echo
  echo "-------------------------------------------------------------------------------"
  echoc v "  Users:  "
  echo
  __listeUtilisateurs "texte"
  cat /tmp/liste

  until false; do
    echo
    echoc r "Scroll up to see the beginning"
    echo
    echo -e "\t1) See iptables rules, 'filter' table"
    echo -e "\t2) See iptables rules, 'nat' table"
    echo -e "\t3) netstat -tap"
    echo -e "\t4) netstat -tap"
    echo -e "\t   ESTABLISHED LISTEN SYN_SENT SYN_RECV"
    echo -e "\t   CONNECTING CONNECTED SYN_RECV"
    echo -e "\t0) Exit"
    echo
    echo -n "Your choice (0 1 2 3 4) "
    read choixMenu
    echo
    case $choixMenu in
      0 )
        break
      ;;
      1 )
        echoc v "------------------------------------------------------------------------"
        iptables -n -L
        echoc v "------------------------------------------------------------------------"
      ;;
      2 )
        echoc v "------------------------------------------------------------------------"
        iptables -t nat -n -L
        echoc v "------------------------------------------------------------------------"
      ;;
      3 )
        echo "------------------------------------------------------------------------"
        echoc v "  netstat:  "
        echo
        netstat -tap
        echo "------------------------------------------------------------------------"
      ;;
      4 )
        echo "------------------------------------------------------------------------"
        echoc v "  netstat:  "
        echo
        netstat -tap | grep -E "ESTABLISHED | LISTEN | SYN_SENT |SYN_RECV | CONNECTING | CONNECTED | SYN_RECV"
        echo "------------------------------------------------------------------------"
      ;;
      * )
        echoc r "Invalid input"
        sleep 1
      ;;
    esac
  done
}
