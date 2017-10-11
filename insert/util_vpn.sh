######################################################
##  ajout vpn, téléchargement du script
######################################################
__vpn() {
  # $REPInstVpn is == $REPLANCE and readonly
  clear
  if [[ -e $REPInstVpn/openvpn-install.sh ]]; then
    rm $REPInstVpn/openvpn-install.sh
  fi
  cmd="wget https://raw.githubusercontent.com/Angristan/OpenVPN-install/master/openvpn-install.sh -O $REPInstVpn/openvpn-install.sh"; $cmd || __msgErreurBox "$cmd" $?
  chmod +x $REPInstVpn/openvpn-install.sh
  export ERRVPN="" NOMCLIENTVPN=""
  sed -i "/^#!\/bin\/bash/ a\__myTrap() {\nERRVPN=\$?\nNOMCLIENTVPN=\$CLIENT\ncd $REPInstVpn\n$REPInstVpn\/HiwsT-util.sh\n}\ntrap '__myTrap' EXIT" $REPLANCE/openvpn-install.sh
  # __myTrap() {
  #   ERRVPN=$?
  #   NOMCLIENTVPN=$CLIENT
  #   cd /home/<username>/HiwsT
  #   /home/<username>/HiwsT/HiwsT-util.sh
  # }
  # trap '__myTrap' EXIT

  ## supprimer la redirection de sterr
  exec 2>&3 3>&-  # permettre l'affichage des read -p qui passe par sterr ?
  . $REPLANCE/openvpn-install.sh
}
