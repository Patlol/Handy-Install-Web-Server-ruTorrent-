
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
echo "ports :"
echo "-------"
netstat -lntup
echo
echo "-------------------------------------------------------------------------------"
echo "apache2 :"
echo "---------"
service apache2 status
echo
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
ps aux | grep rtorrent
echo
echo "-------------------------------------------------------------------------------"
echo "Utilisateurs :"
echo "--------------"
. $REPLANCE/insert/listeusers.sh
