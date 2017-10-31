######################################################
##  ajout vpn, téléchargement du script
######################################################

# ARG : no, RETURN : no
__vpnInstall() {
  readonly local REPInstVpn=$REPLANCE
  ## script installation
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

__vpn() {
  __ouinonBox "openVPN" "
    VPN installed with the${R}Angristan script${N}(MIT  License),
    with his kind permission. Thanks to him

    github repository: https://github.com/Angristan/OpenVPN-install
    Angristan's blog: https://angristan.fr/installer-facilement-serveur-openvpn-debian-ubuntu-centos/

    Excellent security-enhancing script, allowing trouble-free installation
    on Debian, Ubuntu, CentOS et Arch Linux servers.
    Do not reinvent the wheel (less well), that's the Oppen Source
    ${R}${BO}
    -----------------------------------------------------------------------------------------
    |  - To the question 'Tell me a name for the client cert'
    |    Give the name of the linux user to which the vpn is intended.
    |  - If you restart this script you can add or remove
    |    a user, uninstall the VPN.
    |  - The configuration file will be located in the corresponding /home if his name exist.
    ------------------------------------------------------------------------------------------${N}" 22 100
  if [[ $__ouinonBox -eq 0 ]]; then
  __vpnInstall
  fi
}
