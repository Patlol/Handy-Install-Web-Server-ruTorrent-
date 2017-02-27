echo
echo
echo
echo "*************************************************"
echo "|           Installation de WebMin              |"
echo "|               soyez patient                   |"
echo "*************************************************"
echo
echo
sleep 1


cd /tmp

if [[ $nameDistrib == "Debian" ]]; then
	__cmd "wget $upDebWebMinD"
	__cmd "apt-get -f install -y $paquetWebMinD"
	__cmd "dpkg --install $debWebMinD"
else
	__cmd "wget $upDebWebMinU"
	__cmd "apt-get install -yq /tmp/$debWebMinU"
fi
	echo "****************************"
	echo "|     Paquets installés    |"
	echo "****************************"
	echo
	sleep 1


headTest=`curl -Is http://$IP:10000 | head -n 1`
headTest=$(echo $headTest | awk -F" " '{ print $3 }')
if [[ $headTest == Document* ]]
then
	echo "******************************"
	echo "|     WebMin fonctionne      |"
	echo "******************************"
	echo "Accepter l'exception au certificat pour ce site"
	echo
	sleep 1
else
	echo "curl -Is http://$IP:10000 | head -n 1 renvoie $headTest" >> /tmp/hiwst.log
	__msgErreurBox
fi
