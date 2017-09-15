echo
echo
echo
echo "********************************************"
echo "|           Installing WebMin              |"
echo "|         This may take a while            |"
echo "********************************************"
echo
echo
sleep 1
# paquets debian
upDebWebMinD="http://prdownloads.sourceforge.net/webadmin/webmin_1.830_all.deb"
paquetWebMinD="perl libnet-ssleay-perl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python"
debWebMinD="webmin_1.830_all.deb"
# paquets ubuntu
upDebWebMinU="http://www.webmin.com/download/deb/webmin-current.deb"
debWebMinU="webmin-current.deb"

cd /tmp

if [[ $nameDistrib == "Debian" ]]; then
	cmd="wget $upDebWebMinD"; $cmd || __msgErreurBox "$cmd" $?
	cmd="apt-get -f install -y $paquetWebMinD"; $cmd || __msgErreurBox "$cmd" $?
	cmd="dpkg --install $debWebMinD"; $cmd || __msgErreurBox "$cmd" $?
else
	cmd="wget $upDebWebMinU"; $cmd || __msgErreurBox "$cmd" $?
	cmd="apt-get install -yq /tmp/$debWebMinU"; $cmd || __msgErreurBox "$cmd" $?
fi
	echo "***************************"
	echo "|   Packages Installed    |"
	echo "***************************"
	echo
	sleep 1


headTest=`curl -Is http://$IP:10000 | head -n 1`
headTest=$(echo $headTest | awk -F" " '{ print $3 }')
if [[ "$headTest" == Document* ]]
then
	echo "******************************"
	echo "|     WebMin works well      |"
	echo "******************************"
	echo "Accepter l'exception au certificat pour ce site"
	echo
	sleep 1
else
	__msgErreurBox "curl -Is http://$IP:10000 | head -n 1 | awk -F\" \" '{ print $3 }' renvoie '$headTest'" "http $headTest"
fi
