clear
echo
lsb_release -a
echo
echo "Serveur http : $SERVEURHTTP"
echo
echo "-------------------------------------------------------------------------------"
echo "RAM : "
echo "-----"
free -h
echo
echo "-------------------------------------------------------------------------------"
echo "Disques :"
echo "---------"
df -h
echo
echo "-------------------------------------------------------------------------------"
echo "netstat :"
echo "---------"
netstat -tap
echo
echo "-------------------------------------------------------------------------------"
echo "firewall : ufw show listening"
echo "-----------------------------"
ufw show listening
echo "-------------------------------------------------------------------------------"
echo "firewall : ufw status verbose"
echo "-----------------------------"
ufw status verbose
echo "-------------------------------------------------------------------------------"
if [[ $SERVEURHTTP == "apache2" ]]; then
  echo "apache2 :"
  echo "---------"
  service apache2 status
  echo
else
  echo "nginx :"
  echo "-------"
  service nginx status
  echo
fi
echo "-------------------------------------------------------------------------------"
echo "sshd :"
echo "------"
service sshd status
echo
echo "-------------------------------------------------------------------------------"
echo "rtorrentd :"
echo "-----------"
service rtorrentd status
echo
ps aux | grep '.torrent$'
echo
echo "-------------------------------------------------------------------------------"
echo "Utilisateurs :"
echo "--------------"
__listeUtilisateurs "texte"
cat /tmp/liste

until [[ 1 -eq 2 ]]; do
  echo "faire défiler vers le haut pour voir le début"
  echo
  echo -e "\t1) Voir les règles iptables table 'filter'"
  echo -e "\t2) Voir les règles iptables table 'nat'"
  echo -e "\t0) Sortir"
  echo
  echo -n "Votre choix (0 1 2) "
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
    * )
      echo "Entrée invalide"
      sleep 1
    ;;
  esac
done
