############################################################
##                  Questions préalables
##                   $userRuto $pwRuto
############################################################
readonly miniDispoRoot=334495744   # 319 Go minimum pour alerete place \
readonly miniDispoHome=313524224   # 299 Go disponible sur disque
readonly PORT_SCGI=5000  # port 1er Utilisateur
# deb 8
paquetsRtoD8="xmlrpc-api-utils libtorrent14 rtorrent"
# deb 9
paquetsRtoD9="xmlrpc-api-utils libtorrent19 rtorrent"
# ubuntu
paquetsRtoU="xmlrpc-api-utils libtorrent19 rtorrent"

homeDispo=$(df | grep /home | awk -F" " '{ print $4 }')
rootDispo=$(df | grep  /$ | awk -F" " '{ print $4 }')

if [ -z "$homeDispo" ]; then  # /
  if [ "$rootDispo" -lt $miniDispoRoot ]; then
    __messageBox "Important message" "
      ${BO}${R}
      WARNING ${N}

      Only ${R}$(( $rootDispo/1024/1024 )) Go${N}, on / to store downloaded files"
  fi
else  # /home
  if [ "$homeDispo" -lt $miniDispoHome ];then
    __messageBox "Important message" "
      ${BO}$R
      WARNING $N

      Only ${R}$(( $homeDispo/1024/1024 )) Go${N}, on /home to store downloaded files"
  fi
fi

# Rutorrent user
until false; do
  __saisieTexteBox "ruTorrent user" "
    It's more secure to choose a different name
    than a Linux user
    Choose a ruTorrent username${R} (neither space nor \)$N: "
  if [[ $? -ne 0 ]]; then continue 2; fi  # cancel => main menu
  userRuto="$__saisieTexteBox"
  grep -E "^$userRuto:" /etc/passwd > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    __messageBox "ruTorrent user" "
      The new user ${I}$userRuto${N} must already be a linux user.
      Choose another username.
      "
      continue
  else
    __saisiePwBox "ruTorrent user" "
      Password for $userRuto:" 4
    pwRuto="$__saisiePwBox"
    break
  fi
done

############################################################
##                 installation rtorrent
############################################################

# téléchargement rtorrent libtorrent xmlrpc
if [[ $nameDistrib == "Debian" && $os_version_M -eq 8 ]]; then
  paquets=$paquetsRtoD8
elif [[ $nameDistrib == "Debian" && $os_version_M -eq 9 ]]; then
  paquets=$paquetsRtoD9
else
  paquets=$paquetsRtoU
fi
echo
cmd="apt-get install -yq $paquets"; $cmd || __msgErreurBox "$cmd" $?

echo
echoc v "                                                "
echoc v "            rtorrent, libtorrent                "
echoc v "            and xmlrpc packages                 "
echoc v "                installed                       "
echoc v "                                                "
echo


# configuration rtorrent
cp $REPLANCE/fichiers-conf/rto_rtorrent.rc /home/$userRuto/.rtorrent.rc
sed -i 's/<username>/'$userRuto'/g' /home/$userRuto/.rtorrent.rc
sed -i 's/<port>/'$PORT_SCGI'/' /home/$userRuto/.rtorrent.rc

mkdir -p /home/$userRuto/downloads/watch
mkdir -p /home/$userRuto/downloads/.session
chown -R $userRuto:$userRuto /home/$userRuto/downloads
echo
echoc v "                                                     "
echoc v "    .rtorrent.rc configured for Linux user           "
echoc v "                                                     "
sleep 1

# mettre rtorrent en deamon / screen
cp $REPLANCE/fichiers-conf/rto_rtorrent.conf /etc/init/$userRuto-rtorrent.conf
chmod u+rwx,g+rwx,o+rx  /etc/init/$userRuto-rtorrent.conf
sed -i 's/<username>/'$userRuto'/g' /etc/init/$userRuto-rtorrent.conf
#-----------------------------------------------------------------
cp $REPLANCE/fichiers-conf/rto_rtorrentd.sh /etc/init.d/rtorrentd.sh
chmod u+rwx,g+rwx,o+rx  /etc/init.d/rtorrentd.sh
sed -i 's/<username>/'$userRuto'/g' /etc/init.d/rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc4.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc5.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc6.d/K01rtorrentd.sh
systemctl daemon-reload
__servicerestart "rtorrentd"
#-----------------------------------------------------------------
pgrep rtorrent && { \
echoc v "                                                "; \
echoc v "       rtorrent daemon works correctly          "; \
echoc v "                                                "; \
sleep 1; }
