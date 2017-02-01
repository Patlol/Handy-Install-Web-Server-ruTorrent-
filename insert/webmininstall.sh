clear
echo
echo
echo
echo "*************************************************"
echo "|           Installation de WebMin              |"
echo "*************************************************"
echo
echo
sleep 1


cd /tmp

if [[ $nameDistrib == "Debian" ]]; then
	wget $upDebWebMinD
	apt-get -f install -y $paquetWebMinD
	sortie1=$?
	dpkg --install $debWebMinD
	sortie2=$?
else
	wget $upDebWebMinU
	apt-get install -yq /tmp/$debWebMinU
	sortie1=$?; sortie2=0
fi
let sortie=$sortie1+$sortie2
if [[ $sortie -eq 0 ]]
then
	echo "****************************"
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 1
else
	erreurApt
fi

headTest=`curl -Is http://$IP:10000 | head -n 1`
headTest=$(echo $headTest | awk -F" " '{ print $3 }')
if [[ $headTest == Document* ]]
then
	echo "******************************"
	echo "|     WebMin fonctionne      |"
	echo "******************************"
	echo "Accepter l'exception au certificat pour ce site"
else
	echo; echo "Une erreur c'est produite sur Webmin"
	echo; echo "Consulter le wiki"
	echo "https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
	echo; echo "puis continuer/arrêter l'installation"
	ouinon
fi
sleep 1
