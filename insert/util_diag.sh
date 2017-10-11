clear
echo
lsb_release -a
echo
echo "http server:    $SERVEURHTTP"
echo
echo "IP: $IP"
echo "Host Name: $HOSTNAME"
serverName=$(cat $REPAPA2/sites-available/000-default.conf | egrep "^ServerName" | awk -F" " '{print $2}')
if [[ $serverName != "" ]]; then   # Si nom de domaine
  echo "Domain name: $serverName"
  echo
  echo "Certificates ssl"
  certbot certificates
fi
echo
echo "RAM: "
echo "----"
free -h
echo
echo "-------------------------------------------------------------------------------"
echo "Disks:"
echo "------"
df -h
echo
echo "-------------------------------------------------------------------------------"
echo "firewall: ufw show listening"
echo "----------------------------"
ufw show listening 2>/dev/null
[[ $? -ne 0 ]] && echo "Ufw is not installed"
echo "-------------------------------------------------------------------------------"
echo "firewall: ufw status verbose"
echo "----------------------------"
ufw status verbose 2>/dev/null
[[ $? -ne 0 ]] && echo "Ufw is not installed"
echo "-------------------------------------------------------------------------------"
echo "apache2:"
echo "--------"
service apache2 status
echo
echo "-------------------------------------------------------------------------------"
echo "php-fpm:"
echo "--------"
service $PHPVER status
echo
echo "-------------------------------------------------------------------------------"
echo "sshd:"
echo "-----"
service sshd status
echo
echo "-------------------------------------------------------------------------------"
echo "rtorrentd:"
echo "----------"
service rtorrentd status
echo
ps -aux | grep '.torrent$'
echo
echo "-------------------------------------------------------------------------------"
echo "Users:"
echo "------"
__listeUtilisateurs "texte"
cat /tmp/liste

until [[ false ]]; do
  echo "Scroll up to see the beginning"
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
      echo "------------------------------------------------------------------------"
      iptables -n -L
      echo "------------------------------------------------------------------------"
    ;;
    2 )
      echo "------------------------------------------------------------------------"
      iptables -t nat -n -L
      echo "------------------------------------------------------------------------"
    ;;
    3 )
      echo "------------------------------------------------------------------------"
      echo "netstat:"
      echo "--------"
      netstat -tap
      echo "------------------------------------------------------------------------"
    ;;
    4 )
      echo "------------------------------------------------------------------------"
      echo "netstat:"
      echo "--------"
      netstat -tap | egrep "ESTABLISHED | LISTEN | SYN_SENT |SYN_RECV | CONNECTING | CONNECTED | SYN_RECV"
      echo "------------------------------------------------------------------------"
    ;;
    * )
      echo "Invalid input"
      sleep 1
    ;;
  esac
done
