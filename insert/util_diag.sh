
echo
lsb_release -a
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
echo "netstat : ports :"
echo "-----------------"
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
if [[ $serveurHttp == "apache2" ]]; then
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
. $REPLANCE/insert/util_listeusers.sh
