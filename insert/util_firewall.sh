

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
  if ! [ `ufw show added | grep None` ]; then
    #  installé avec des règles préexistantes
    echo "** Règles actuellement en place : **"
    ufw show added
    echo
  fi
  echo "** Règles ajoutées par l'utilitaire : **"
  echo "autoriser le port $portSSH (port ssh)"
  echo "autoriser le port 80"
  echo "autoriser le port 443"
  echo "autoriser le port 445"
  echo "autoriser la plage de ports 55950:56000/tcp (rtorrent)"
  echo "autoriser la plage de ports 55950:56000/udp (rtorrent)"
  echo "autoriser le port 10000/tcp (port Webmin)"
  echo "autoriser le port 25/tcp"
  echo "interdire les autres ports"
  echo
  echo "Voulez-vous"
  echo -e "\t1) Supprimer les règles en place si elles existent"
  echo -e "\t2) Ajouter les nouvelles règles"
  echo -e "\t3) déactiver le firewall"
  echo -e "\t4) activer le firewall sans changer les règles"
  echo -e "\t0) sortir"
  echo
  echo -n "Votre choix (0 1 2 3 4) "
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
  ufw allow 25/tcp
  ufw default deny
  ufw logging on
  echo
  echo "Règles actuellement en place :"
  ufw show added

  ufw --force enable
  echo
fi
sortir=""
echo
