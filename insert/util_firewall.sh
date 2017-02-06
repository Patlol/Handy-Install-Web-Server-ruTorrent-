

# récupération du port ssh
portSSH=0
portSSH=$(cat /etc/ssh/sshd_config | grep ^Port | awk -F" " '{print$2}')
if [ $portSSH -eq 0 ]; then
  echo "Le port ssh est introuvable dans /etc/ssh/sshd_config"
  echo "Impossible d'installer le firewall sans bloquer l'acces ssh !!!"
  echo" https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
  echo
  sortir="ok"
fi

# si pas installé, installer
which ufw 2>&1 > /dev/null
if [ $? != 0 ]; then
apt-get -yq install ufw
fi

# menu
tmp=""; choixMenu=""; sortir=""
until [[ $tmp == "ok" ]]; do
  echo
  if ! [ `ufw show added | grep None` ] && [[ $choixMenu -ne 5 ]]; then
    #  installé avec des règles préexistantes
    echo "** Règles actuellement en place : **"
    ufw status verbose
    echo
  fi
  echo "** Règles ajoutées par l'utilitaire   **"
  echo "** Si elles ne sont pas déjà en place **"
  echo "autoriser le port $portSSH IN (port ssh)"
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
  echo -e "\t1) Supprimer les règles en place si elles existent"
  echo -e "\t2) Ajouter les nouvelles règles"
  echo -e "\t3) Desactiver le firewall sans effacer les règles"
  echo -e "\t4) Activer le firewall sans changer les règles"
  echo -e "\t5) Voir les règles IPTABLES ;)"
  echo -e "\t0) Sortir"
  echo
  echo -n "Votre choix (0 1 2 3 4 5) "
	read choixMenu
	echo
	case $choixMenu in
		0 )
      tmp="ok"; sortir="ok"
    ;;
    1 )
      ufw --force reset
    ;;
    2 )
      ufw disable
      tmp="ok"
    ;;
    3 )
      ufw disable
      tmp="ok"; sortir="ok"
    ;;
    4 )
      ufw --force enable
      tmp="ok"; sortir="ok"
    ;;
    5 )
      echo
      echo "*************************************************************************"
      echo
      iptables -L
      echo "*************************************************************************"
    ;;
    * )
      echo "Entrée invalide"
      sleep 1
    ;;
  esac
done
tmp=""; choixMenu=""
if [[ $sortir == "" ]]; then
  # traitement
  ufw allow $portSSH
  ufw allow 80
  ufw allow 443
  ufw allow 445
  ufw allow 55950:56000/tcp
  ufw allow 55950:56000/udp
  ufw allow 10000/tcp
  # ufw allow 25/tcp
  ufw default deny
  ufw logging on
  echo
  echo "Règles actuellement en place :"
  ufw status verbose

  ufw --force enable
  echo
fi
sortir=""
echo
