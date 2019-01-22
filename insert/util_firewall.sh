
__firewall() {
  __messageBox "Firewall and ufw" "

    ${I}Warning !!!${N}
    The following setting only takes into account the installations
    execute with HiwsT" 12 75

  clear
  # récupération du port ssh
  portSSH=0
  portSSH=$(grep -E ^Port /etc/ssh/sshd_config | awk -F" " '{print$2}')
  if [ $portSSH -eq 0 ]; then
    __messageBox "ssh port Error" "
      The ssh port can not be found in /etc/ssh/sshd_config
      Unable to install the firewall without blocking ssh acces!!!
      See the wiki :  https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
    exit 1
  fi

  # ufw si pas installé, installer
  which ufw > /dev/null 2>&1
  if [ $? != 0 ]; then
    apt-get update
    cmd="apt-get -yq install ufw"; $cmd || __msgErreurBox "$cmd" $?
    if [[ $? -eq 0 ]] ; then echoc v " ufw installed "; fi
    cat << EOF >> $REPUL/HiwsT/RecapInstall.txt

Firewall (ufw) is installed
EOF
    clear
  fi

  # menu
  until false ; do
    echo
    echoc v " Do you want "
    echo -e "\t1) List/Add and enable basic rules with ufw"
    echo -e "\t2) List/Delete the enabled ufw rules (all policy ACCEPT)"
    echo -e "\t3) Stopped and disabled on system startup the firewall"
    echo -e "\t   without erasing the rules"
    echo -e "\t4) Activate and enabled on system startup the firewall"
    echo -e "\t   without changing the rules (ssh port open anyway)"
    echo -e "\t5) See rules IPTABLES 'filter' table"
    echo -e "\t6) See rules IPTABLES 'nat' table (for openVPN)"
    echo -e "\t0) Exit"
    echo
    echo -n "Your choice (0 1 2 3 4 5 6) "
    read choixMenu
    echo

    case $choixMenu in
      0 )
        break
      ;;
      1 )  #  Lister/Ajouter et activer les règles minimums
        echo
        echoc r " ** Rules added by the script ** "
        echo "Accept port $portSSH/tcp Chain INPUT (port ssh)"
        echo "Accept port 80 Chain INPUT (http)"
        echo "Accept port 443 Chain INPUT (https)"
        echo "Accept the ports range 55950:56000/tcp Chain INPUT (rtorrent)"
        echo "Accept the ports range 55950:56000/udp Chain INPUT (rtorrent)"
        echo "Accept port 6881 Chain INPUT (rtorrent DHT)"
        echo "Accept port 10000/tcp Chain INPUT (Webmin)"
        echo "Enable logs in LOW (logging on)"
        echo "Drop others ports in Chain INPUT (policy DROP)"
        echo "Accept all ports in Chain OUTPUT (policy ACCEPT)"
        echo
        echoc r " Do you want "
        echo -e "\t1) Add the rules above"
        echo -e "\t2) Back to menu"
        until false ; do
          echo -n "Your choice (1 2) "
          read choixMenu1
          case $choixMenu1 in
            1 )
              ufw disable
              # traitement
              ufw allow $portSSH/tcp
              ufw allow 80
              ufw allow 443
              # ufw allow 445
              ufw allow 55950:56000/tcp
              ufw allow 55950:56000/udp
              ufw allow 10000/tcp
              ufw allow 6881/tcp  # DHT rtorent
              ufw allow 6881/udp
              # ufw allow 25/tcp
              ufw default deny
              ufw logging on
              ufw --force enable
              echo; sleep 1
              break
            ;;
            2 )
              break
            ;;
            * )
              continue
            ;;
          esac
        done
      ;;
      2 )  #  Lister/Supprimer les règles en place
        echo
        echoc r " ** Rules currently enabled: ** "
        if [ $(ufw show added | grep None) ]; then
          echoc r "       No rule enabled          "
          echo
          sleep 1; continue
        else
          ufw status verbose
          echo
          echoc v " Do you want "
          echo -e "\t1) Remove the above rules"
          echo -e "\t2) Back to menu"
          until false ; do
            echo -n "Your choice (1 2) "
            read choixMenu2
            case $choixMenu2 in
              1 )
                ufw --force reset
                break
              ;;
              2 )
                break
              ;;
              * )
                continue
              ;;
            esac
          done
        fi
      ;;
      3 )  #  Desactiver le firewall sans effacer les règles
        ufw disable
      ;;
      4 )  #  Activer le firewall sans changer les règles (port ssh ouvert)
        ufw allow $portSSH/tcp
        ufw --force enable
      ;;
      5 )
        echo
        echoc v "*************************************************************************"
        echo
        iptables -L
        echoc v "*************************************************************************"
      ;;
      6 )
        echo
        echoc v "*************************************************************************"
        echo
        iptables -t nat -n -L
        echoc v "*************************************************************************"
      ;;
      * )
        echoc r " Invalid input "
        sleep 1
      ;;
    esac
  done
}
