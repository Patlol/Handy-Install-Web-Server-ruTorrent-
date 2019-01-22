#####################################################
##  Suppression d'un utilisateur linux et rutorrent
#####################################################
__suppUserRuto() {
  ### traitement sur sshd, dossier user dans rutorrent, rtorrentd.sh, user linux et son home
  # ${1} == $__saisieTexteBox
  clear
  # suppression du user allowed dans sshd_config
  sed -i 's/'${1}'[:space:]* //' /etc/ssh/sshd_config
  __servicerestart "sshd"

  __suppUserRutoPasswd ${1}

  # dossier rutorrent/conf/users/userRuto et rutorrent/share/users/userRuto
  rm -r $REPWEB/rutorrent/conf/users/${1}
  echoc v " Directory conf/users/${1} on ruTorrent deleted  "
  rm -r $REPWEB/rutorrent/share/users/${1}
  echoc v " Directory share/users/${1} on ruTorrent deleted "; echo

  # modif de rtorrentd.sh (daemon)
  sed -i '/.*'${1}.*'/d' /etc/init.d/rtorrentd.sh
  rm /etc/init/${1}-rtorrent.conf

  systemctl daemon-reload
  __servicerestart "rtorrentd"
  if [[ $? -eq 0 ]]; then
  echoc v "     Daemon rtorrent modified and work well.     "; echo
  fi
  # suppression fichier témoin de screen
  rm -r /var/run/screen/S-${1}
  # Suppression du home et suppression user linux (-f le home est root:root)
  userdel -fr ${1}
  echoc v "                                      "
  echoc v "   Linux user and his /home deleted   "
  echoc v "                                      "
  sleep 4
}  # fin __suppUserRuto
