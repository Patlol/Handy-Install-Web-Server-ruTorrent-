
clear
# récupération du port ssh
portSSH=0
portSSH=$(cat /etc/ssh/sshd_config | grep ^Port | awk -F" " '{print$2}')

if [ $portSSH -eq 0 ]; then
  __messageBox "Erreur port ssh" "
Le port ssh est introuvable dans /etc/ssh/sshd_config
Impossible d'installer le firewall sans bloquer l'acces ssh !!!
Consulter le wiki :  https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
  exit 1
fi

# ufw si pas installé, installer
which ufw 2>&1 > /dev/null
if [ $? != 0 ]; then
apt-get -yq install ufw
clear
fi

# menu
until false ; do
  echo
  echo "Voulez-vous"
  echo -e "\t1) Lister/Ajouter et activer les règles minimums"
  echo -e "\t2) Lister/Supprimer les règles en place"
  echo -e "\t3) Desactiver le firewall sans effacer les règles"
  echo -e "\t4) Activer le firewall sans changer les règles (port ssh ouvert)"
  echo -e "\t5) Voir les règles IPTABLES table 'filter'"
  echo -e "\t6) Voir les règles IPTABLES table 'nat'(pour openVPN)"
  echo -e "\t0) Sortir"
  echo
	read -p "Votre choix (0 1 2 3 4 5 6) " choixMenu
	echo

  case $choixMenu in
		0 )
      break
    ;;
    1 )  #  Lister/Ajouter et activer les règles minimums
      echo
      echo "** Règles ajoutées par l'utilitaire   **"
      echo "autoriser le port $portSSH/tcp IN (port ssh)"
      echo "autoriser le port 80 IN"
      echo "autoriser le port 443 IN"
      echo "autoriser le port 445 IN"
      # echo "autoriser le port 25/tcp IN"
      echo "autoriser la plage de ports 55950:56000/tcp IN (rtorrent)"
      echo "autoriser la plage de ports 55950:56000/udp IN (rtorrent)"
      echo "autoriser le port 10000/tcp IN (port Webmin)"
      echo "Activer les logs en LOW (logging on)"
      echo "interdire les autres ports en IN (default deny)"
      echo "autoriser tous les ports en OUT"
      echo
      echo "Voulez-vous"
      echo -e "\t1) Ajouter les règles ci-dessus"
      echo -e "\t2) Revenir au menu"
      until false ; do
        read -p "Votre choix (1 2) " choixMenu1
        case $choixMenu1 in
          1 )
            ufw disable
            # traitement
            ufw allow $portSSH/tcp
            ufw allow 80
            ufw allow 443
            ufw allow 445
            ufw allow 55950:56000/tcp
            ufw allow 55950:56000/udp
            ufw allow 10000/tcp
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
      echo "** Règles actuellement en place : **"
      if [ `ufw show added | grep None` ]; then
        echo "Aucune règles en place"
        sleep 1; continue
      else
        ufw status verbose
        echo
        echo "Voulez-vous"
        echo -e "\t1) Supprimer les règles ci-dessus"
        echo -e "\t2) Revenir au menu"
        until false ; do
          read -p "Votre choix (1 2) " choixMenu2
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
      echo "*************************************************************************"
      echo
      iptables -L
      echo "*************************************************************************"
    ;;
    6 )
      echo
      echo "*************************************************************************"
      echo
      iptables -t nat -n -L
      echo "*************************************************************************"
    ;;
    * )
      echo "Entrée invalide"
      sleep 1
    ;;
  esac
done
