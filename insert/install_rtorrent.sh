############################################
#           installation rtorrent          #
############################################

# téléchargement rtorrent libtorrent xmlrpc
if [[ $nameDistrib == "Debian" && $os_version_M -eq 8 ]]; then
  paquets=$paquetsRtoD8
elif [[ $nameDistrib == "Debian" && $os_version_M -eq 9 ]]; then
  paquets=$paquetsRtoD9
else
  paquets=$paquetsRtoU
fi
cmd="apt-get install -yq $paquets"; $cmd || __msgErreurBox "$cmd" $?

echo
echo "******************************"
echo "|    rtorrent, libtorrent    |"
echo "|    and xmlrpc packages     |"
echo "******************************"
echo
sleep 1


# configuration rtorrent
cp $REPLANCE/fichiers-conf/rto_rtorrent.rc $REPUL/.rtorrent.rc
sed -i 's/<username>/'$userLinux'/g' $REPUL/.rtorrent.rc

mkdir -p $REPUL/downloads/watch
mkdir -p $REPUL/downloads/.session
chown -R $userLinux:$userLinux $REPUL/downloads
echo
echo "************************************************"
echo "|   .rtorrent.rc configured for Linux user     |"
echo "************************************************"
sleep 1

# mettre rtorrent en deamon / screen
cp $REPLANCE/fichiers-conf/rto_rtorrent.conf /etc/init/$userLinux-rtorrent.conf
chmod u+rwx,g+rwx,o+rx  /etc/init/$userLinux-rtorrent.conf
sed -i 's/<username>/'$userLinux'/g' /etc/init/$userLinux-rtorrent.conf
#-----------------------------------------------------------------
cp $REPLANCE/fichiers-conf/rto_rtorrentd.sh /etc/init.d/rtorrentd.sh
chmod u+rwx,g+rwx,o+rx  /etc/init.d/rtorrentd.sh
sed -i 's/<username>/'$userLinux'/g' /etc/init.d/rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc4.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc5.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc6.d/K01rtorrentd.sh
systemctl daemon-reload
__servicerestart "rtorrentd"
#-----------------------------------------------------------------
pgrep rtorrent && { \
echo "**************************************"; \
echo "|  rtorrent daemon works correctly   |"; \
echo "**************************************"; \
sleep 1; } || \
__msgErreurBox "rtorrent daemon don't work" 1
