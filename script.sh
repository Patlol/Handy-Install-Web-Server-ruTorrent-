#!/bin/bash

# Version bêta testée sur ubuntu et debian server vps Ovh
# à tester sur kimsufi et autres hébergeurs

##################################################
#     variables install paquets Ubuntu/Debian
##################################################

#  Debian

paquetsWebD="mc aptitude apache2 apache2-utils autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libapache2-mod-php5 libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php5 php5-cli php5-dev php5-fpm php5-curl php5-geoip php5-mcrypt php5-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoD="xmlrpc-api-utils libtorrent14 rtorrent"

sourceMediaD="deb http://www.deb-multimedia.org jessie main non-free"
paquetsMediaD="mediainfo ffmpeg"

upDebWebMinD="http://prdownloads.sourceforge.net/webadmin/webmin_1.830_all.deb"
paquetWebMinD="perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python"
debWebMinD="webmin_1.830_all.deb"

# Ubuntu

paquetsWebU="mc aptitude apache2 apache2-utils autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libapache2-mod-php7.0 libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php7.0 php7.0-cli php7.0-dev php7.0-fpm php7.0-curl php-geoip php7.0-mcrypt php7.0-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoU="xmlrpc-api-utils libtorrent19 rtorrent"

paquetsMediaU="mediainfo ffmpeg"

upDebWebMinU="http://www.webmin.com/download/deb/webmin-current.deb"
debWebMinU="webmin-current.deb"


#############################
#       Fonctions
#############################


ouinon() {
tmp=""
until [[ $tmp == "ok" ]]; do
echo
echo -n "Voulez-vous continuer ? (o/n) "; read yno
case $yno in
	[nN] | [nN][oO][nN])
		echo "Désolé, à bientôt !"
		sed -i "s/$userLinux ALL=(ALL) NOPASSWD:ALL/$userLinux ALL=(ALL:ALL) ALL/" /etc/sudoers
		if [ -e /var/www/html/info.php ]; then rm /var/www/html/info.php; fi
		exit 1
	;;
	[Oo] | [Oo][Uu][Ii])
		echo "On continu !"
		tmp="ok"
		sleep 1
	;;
	*)
		echo "Entrée invalide"
		sleep 1
	;;
esac
done
}    #  fin ouinon(

serviceapache2restart() {
service apache2 restart
if [ $? != 0 ]
then
	echo "Il y a un problème de configuration avec apache2"
	service apache2 status
	echo "Régler le problème et relancer le script"
	echo "Google est votre ami  !"
	ouinon
fi
}   #  fin serviceapache2restart()

creauser() {
echo
tmp=""; tmp2=""
until [[ $tmp == "ok" ]]; do
	echo -n "Choisir un nom d'utilisateur linux : "
	read userLinux
	egrep "^$userLinux" /etc/passwd >/dev/null
	if [[ $? -eq 0 ]]; then
		echo "$userLinux existe déjà, choisir un autre nom"
		yno="N"
	else
		echo -n "Vous confirmez '$userLinux' comme nom d'utilisateur ? (o/n) "
		read yno
	fi
	case $yno in
		[Oo] | [Oo][Uu][Ii])   # création d'un utilisateur
			until [[ $tmp2 == "ok" ]]; do
				echo -n "Choisissez un mot de passe : "
				read pwLinux
				echo -n "Resaisissez ce mot de passe : "
				read pwLinux2
				case $pwLinux2 in
					$pwLinux)
						#  créer l'utilisateur $userlinux
						pass=$(perl -e 'print crypt($ARGV[0], "pwLinux")' $pwLinux)
						useradd -m -G adm,dip,plugdev,www-data,sudo,cdrom -p $pass $userLinux
						echo "bash" >> /home/$userLinux/.profile
						echo $userLinux > $repLance/pass1
						if [[ $? -ne 0 ]]; then
							echo "Impossible de créer un utilisateur linux"
							ouinon
						fi
						tmp2="ok"; tmp="ok"
					;;
					*)
						echo "Les deux saisies du mot de passe ne sont pas identiques. Recommencez"
						echo
						sleep 1
					;;
				esac
			done  # fin création d'un utilisateur
		;;
		[nN] | [nN][oO][nN])
			echo "Nom d'utilisateur invalidé. Reprendre la saisie"
			sleep 1
		;;
		*)
			echo "Entrée invalide"
			sleep 1
			;;
	esac
done
}  # creauser

erreurApt() {
	echo; echo "Une erreur c'est produite durant l'installation des paquets."
	echo "Souvent due au changement de nom des paquets (version)"
	echo
	echo "Dans une autre console (cf. Tips sur github), vérifier le nom des paquets en cause avec"
	echo "\"sudo aptitude search <nom partiel du paquet('php' pour 'php7.0-dev' par exemple)> | grep ^i\" pour trouver les noms correctes."
	echo
	echo "Les installer manuellement avec \"sudo apt-get install <nom correcte du paquet>\"."
	echo "Si cela ne fonctionne pas vérifier vos sources de repository"
	echo "et leurs disponibilité."
	echo
	echo "Puis recommencer l'installation"
	ouinon
}   #  fin erreurApt()





#############################
#     Début du script
#############################


# root ?

if [[ $(id -u) -ne 0 ]]; then
	echo
	echo "Ce script nécessite d'être exécuté avec sudo."
	echo
	echo "id : "`id`
	echo
	exit 1
fi

# info système

lsb_release &> /dev/null
if [ $? -ne 0 ]; then
	apt-get install -y lsb-release
	erreurApt
fi

repLance=$(echo `pwd`)
arch=$(uname -m)
interface=ifconfig | grep "Ethernet" | awk -F" " '{ print $1 }'  # pas tjs eth0 ...
IP=$(ifconfig $interface 2>/dev/null | grep 'inet ad' | awk -F: '{ printf $2 }' | awk '{ printf $1 }')  
distrib=$(cat /etc/issue | awk -F"\\" '{ print $1 }')
nameDistrib=$(lsb_release -si)  # Debian ou Ubuntu
os_version=$(lsb_release -sr)   # 18 , 8.041 ...
os_version_M=$(echo $os_version | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')  # version majeur
description=$(lsb_release -sd)     #  nom de code
user=$(id -un)       #  root avec user sudo 
loguser=$(logname)   #  user avec user sudo

# ubuntu / debian et bonne version ?

if [ $nameDistrib == "Debian" -a $os_version_M -gt 8 -o $nameDistrib == "Ubuntu" -a $os_version_M -gt 16 ]; then
	echo
	echo "Vous utilisez $description"
	echo
	echo "Ce script est prévu pour fonctionner sur un serveur Debian 8.xx ou Ubuntu 16.xx"
	echo "Vous risquez d'avoir des problèmes de version à l'installation"
	ouinon
fi

if [ $nameDistrib == "Debian" -a $os_version_M -lt 8 -o $nameDistrib == "Ubuntu" -a $os_version_M -lt 16 ]; then
	echo
	echo "Vous utilisez $description"
	echo
	echo "Ce script fonctionne sur un serveur Debian 8.xx ou Ubuntu 16.xx"
	echo
	exit 1
fi

if [ $nameDistrib != "Debian" -a $nameDistrib != "Ubuntu" ]; then
	echo
	echo "Vous utilisez $description"
	echo
	echo "Ce script fonctionne sur un serveur Debian 8.xx ou Ubuntu 16.xx !!!"
	echo
	exit 1
fi


# espace dispo

homeDispo=$(df -h | grep /home | awk -F" " '{ print $4 }')
rootDispo=$(df -h | grep  /$ | awk -F" " '{ print $4 }')

# portSSH aléatoire

RANDOM=$$  # N° processus du script
portSSH=0   #   initialise 20000 65535
PLANCHER=20000
ECHELLE=65534
while [ "$portSSH" -le $PLANCHER ]
do
  portSSH=$RANDOM
  let "portSSH %= $ECHELLE"  # Ramène $portSSH dans $ECHELLE.
done

#--------------------------------------------------------------



#############################
#    Partie interactive
#    ID, PW, questions
#############################

echo
clear
echo "***********************************************"
echo "|  Récupération des informations nécessaires  |"
echo "|             aux installations               |"
echo "***********************************************"
echo
echo "Distribution : "$description
echo "Architecture : "$arch
if [[ $arch != "x86_64" ]]
then
	echo "Vous n'êtes pas en 64 bits ???"
	echo "------------------------------"
	echo "Est-ce normal, avez-vous installé la bonne version de l'OS ?"
fi
echo "Votre IP : "$IP
echo "Vous êtes logué en : "$loguser
echo
echo "Durée du script : environ 10mn"
#----------------------------------------------------------
# vérif place sur disque

echo
echo
echo "Place disponible sur les partitions du disques"
echo

if [ -z "$homeDispo" ]  # /
then
	echo "Vous n'avez pas de partition /home."
	echo "Votre partition root (/) a "$rootDispo" de libre."
	len=${#rootDispo}
	entier=${rootDispo:0:len-1}
	entier=$(echo $entier | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')
	miniDispo=319
 	if [ "$entier" -lt "$miniDispo" ]
 	then
		echo
		echo
		echo "*************************************************************************************"
		echo "|                                                                                   |"
		echo "|    ATTENTION seulement "$rootDispo", pour stocker les fichiers téléchargés !      |"
		echo "|                                                                                   |"
		echo "*************************************************************************************"
	fi
else  # /home
	echo "Votre partition /home a $homeDispo de libre."
	len=${#homeDispo}
	entier=${homeDispo:0:len-1}
	entier=$(echo $entier | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')	
	miniDispo=299
 	if [ "$entier" -lt "$miniDispo" ]
 	then
		echo "************************************************************************************"
		echo "|                                                                                  |"
		echo "|    ATTENTION seulement "$homeDispo", pour stocker les fichiers téléchargés !     |"
		echo "|                                                                                  |"
		echo "************************************************************************************"		
	fi
fi

echo
echo
echo "*******************************************************************************"
echo "|                                                                             |"
echo "|                                ATTENTION !!!                                |"
echo "|                                                                             |"
echo "|        L'utilisation de ce script doit se faire sur un serveur nu,          |"
echo "|                    tel que livré par votre hébergeur.                       |"
echo "|    Une installation quelconque risque d'être endommagée par ce script !!!   |"
echo "|         Ne jamais exécuter ce script sur un serveur en production           |"
echo "|                                                                             |"
echo "*******************************************************************************"

if [ ! -e $repLance"/pass1" ]; then   # évite ce passage si 2éme passe
	tmp=""
	until [[ $tmp == "ok" ]]; do
		echo
		echo -n "Voulez-vous continuer l'installation ? (o/n) "
		read yno

		case $yno in
			[nN] | [nN][oO][nN])
				echo "Au revoir, a bientôt."
				exit 0
			;;
			[Oo] | [Oo][Uu][Ii])
				echo "Allons-y !"
				tmp="ok"
			;;
			*)
				echo "Entrée invalide"
				sleep 1
			;;
		esac
	done

#------------------------------------------------

# linux user

	echo
	if [[ $loguser != "root" ]]; then
		echo "Vous avez lancé le script depuis $loguser avec 'sudo'"
	else
		echo "Vous avez lancé le script depuis root"
	fi
	echo "Vous allez devoir créer un utilisateur spécifique"
	echo
	creauser
	echo "A bientôt ! avec"
	echo "'login $userLinux'"
	echo "'cd $repLance'"
	echo "'sudo ./`basename $0`'"
	chmod u+rwx,g+rx,o+rx $0			
	exit 0
else
	userLinux=$(cat pass1)
	if [[ $userLinux != $loguser ]]; then
		echo
		echo "Vous êtes logué avec $loguser"		
		echo "Vous deviez lancer le script en étant logué avec $userLinux !"
		echo "'sudo login $userLinux'"
		echo "'cd $repLance'"
		echo "'sudo ./`basename $0`'"
		exit 1
	fi
fi   # fin de évite ce passage si 2éme passe

# Rutorrent user

echo
echo
echo "Utilisateur ruTorrent"
tmp=""; tmp2=""
until [[ $tmp == "ok" ]]; do
	echo
	echo "Il est préférable de choisir un nom différent de celui de l'utilisateur Linux"
	echo -n "Choisir un nom d'utilisateur ruTorrent : "
	read userRuto
	echo -n "Vous confirmez '$userRuto' comme nom d'utilisateur ? (o/n) "
	read yno
	case $yno in
		[Oo] | [Oo][Uu][Ii])
			until [[ $tmp2 == "ok" ]]; do
				echo -n "Choisissez un mot de passe : "
				read pwRuto
				echo -n "Resaisissez ce mot de passe : "
				read pwRuto2
				case $pwRuto2 in
					$pwRuto)
						tmp="ok"; tmp2="ok"
					;;
					*)
						echo "Les deux saisies du mot de passe ne sont pas identiques. Recommencez"
						echo
						sleep 1
					;;
				esac
			done
		;;
		[nN] | [nN][oO][nN])
			echo "Nom d'utilisateur invalidé. Reprendre la saisie"
			sleep 1
		;;
		*)
			echo "Entrée invalide"
			sleep 1
		;;
	esac
done

#  cakebox

echo
echo
echo "Cakebox"
echo "Cakebox vous permettra, sur une interface graphique"
echo "web, de streamer, naviguer et partager vos films"
echo "depuis la seedbox, sans les télécharger sur votre PC."
echo "Pour plus d'infos https://github.com/cakebox/cakebox"
tmp=""; tmp2=""; tmp3=""
until [[ $tmp3 == "ok" ]]; do
	echo
	echo -n "Souhaitez-vous insaller Cakebox ? (o/n) "
	read yno
	case $yno in
		[nN] | [nN][oO][nN])
			echo "Ok on continu"
			tmp3="ok"
			installCake="non"
		;;
		[Oo] | [Oo][Uu][Ii])
			until [[ $tmp == "ok" ]]; do
				echo
				echo "Choisir un nom d'utilisateur Cakebox"
				echo -n "(peut-être le même que pour rutorrent) : "
				read userCake
				echo -n "Vous confirmez '$userCake' comme nom d'utilisateur ? (o/n) "
				read yno1
				case $yno1 in
					[Oo] | [Oo][Uu][Ii])
						until [[ $tmp2 == "ok" ]]; do
							echo -n "Choisissez un mot de passe : "
							read pwCake
							echo -n "Resaisissez ce mot de passe : "
							read pwCake2
							case $pwCake2 in
								$pwCake)
									installCake="oui"
									tmp="ok"; tmp2="ok"; tmp3="ok"
								;;
								*)
									echo "Les deux saisies du mot de passe ne sont pas identiques. Recommencez"
									echo
									sleep 1
								;;
							esac # pwCake
						done # tmp2
					;;
					[nN] | [nN][oO][nN])
						echo "Nom d'utilisateur invalidé. Reprendre la saisie"
						sleep 1
					;;
					*)
						echo "Entrée invalide"
						sleep 1
					;;
				esac # yno1
			done # tmp
		;;
		*)
			echo "Entrée invalide"
			sleep 1
		;;
	esac # yno
done  # tmp3


#  webmin

echo
echo
echo "WebMin"
echo
echo "WebMin vous permettra d'effectuer la plus-part"
echo "des taches d'administration de votre serveur sur une"
echo "interface graphique web. Pour plus d'infos http://www.webmin.com/"
tmp=""
until [[ $tmp == "ok" ]]; do
	echo
	echo -n "Souhaitez-vous insaller WebMin ? (o/n) "
	read yno
	case $yno in
		[nN] | [nN][oO][nN])
			echo "Ok on continu"
			tmp="ok"
			installWebMin="non"
			sleep 1
		;;
		[Oo] | [Oo][Uu][Ii])
			installWebMin="oui"
			tmp="ok"
			sleep 1
		;;
		*)
			echo "Entrée invalide"
			sleep 1
		;;
	esac # yno
done  # tmp

#  Récapitulation

clear
echo "*************************************************"
echo "|  Récapitulation des informations nécessaires  |"
echo "|              aux installations                |"
echo "*************************************************"
echo
echo "Distribution : "$description
echo "Architecture : "$arch
echo "Votre IP : "$IP

# echo "Votre nom de user actuel : "$loguser

if [ -z "$homeDispo" ]
then
	echo "Vous n'avez pas de partition /home."
else
	echo "Votre partition /home a $homeDispo de libre."
fi
echo "Votre partition root (/) a "$rootDispo" de libre."
echo
echo "Nom de votre utilisateur Linux (accès SSH et SFTP) : "$userLinux
echo "Port aléatoire pour SSh : "$portSSH
echo "Nom de votre utilisateur ruTorrent : "$userRuto
echo "Mot de passe de votre utilisateur ruTorrent : "$pwRuto
if [[ $installCake != "oui" ]]
then
	echo "Vous ne souhaitez pas installer Cakebox"
else
	echo "Vous souhaitez installer Cakebox"
	echo "Nom de votre utilisateur Cakebox : "$userCake
	echo "Mot de passe de votre utilisateur Cakebox : "$pwCake
fi
if [[ $installWebMin != "oui" ]]
then
	echo "Vous ne souhaitez pas installer WebMin"
else
	echo "Vous souhaitez installer WebMin"
	echo "L'utilisateur sera "root" avec son mot de passe"
fi
echo
echo
echo "                                                                     "
echo "                       ATTENTION !!!                                 "
echo "                                                                     "
echo "  Vous devez impérativement conserver ces informations en lieu sûr.  "
echo "  Les noms d'utilisateur, mots de passe et port sont indispensables  "
echo "  à l'utilisation du serveur.                                        "
echo "                                                                     "
echo "  Toutes ces informations seront utilisables seulement après         "
echo "  la bonne exécution du script.                                      "
echo "                                                                     "
tmp=""
until [[ $tmp == "ok" ]]; do
echo
echo -n "Voulez-vous continuer l'installation ? (o/n) "
read yno
case $yno in
	[nN] | [nN][oO][nN])
		echo "Au revoir, a bientôt."
		exit 0
	;;
	[Oo] | [Oo][Uu][Ii])
		echo "Allons-y !"
		tmp="ok"
		sleep 1
	;;
	*)
		echo "Entrée invalide"
		sleep 1
	;;
esac
done




############################################
#            Début de la fin
############################################


clear
echo
echo
echo
echo "*************************************************"
echo "|                 Installation                  |"
echo "*************************************************"
echo
echo
echo
echo "***********************************************"
echo "|              Update système                 |"
echo "|       Création de l'utilisateur linux       |"
echo "|          Installation des paquets           |"
echo "***********************************************"
sleep 2
echo
# upgrade
apt-get update -yq
sortie=$?
apt-get upgrade -yq
if [[ $? -eq 0 && $sortie -eq 0 ]]
then 
	echo "****************************"	
	echo "|  Mise à jour effectuée   |"
	echo "****************************"
	sleep 2
else
	erreurApt  # erreurApt()
fi

echo
echo "$userLinux ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers;
usermod -aG www-data $userLinux
echo
echo "******************************"
echo "|    Utilisateur linux ok    |"
echo "******************************"
sleep 3
echo

# Installation paquets

echo
echo "***********************************************"
echo "|          Installation des paquets           |"
echo "|         necessaires au serveur web          |"
echo "***********************************************"
sleep 2

if [[ $nameDistrib == "Debian" ]]; then
	paquets=$paquetsWebD
else
	paquets=$paquetsWebU
fi
apt-get install -y $paquets
if [[ $? -eq 0 ]]
then 
	echo "****************************"	
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 2
else
	erreurApt  # erreurApt()
fi

echo
echo "***********************************************"
echo "|           Configuration apache2             |"
echo "***********************************************"
sleep 2

# config apache
echo
echo
a2enmod ssl
a2enmod auth_digest
a2enmod reqtimeout
a2enmod authn_file
a2enmod rewrite

cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.old
sed -i 's/^Timeout[ 0-9]*/Timeout 30/' /etc/apache2/apache2.conf
echo "ServerTokens Prod" >> /etc/apache2/apache2.conf
echo "ServerSignature Off" >> /etc/apache2/apache2.conf
serviceapache2restart
	
echo "***********************************************"
echo "|      Fin de configuration d'Apache          |"
echo "***********************************************"
sleep 2
echo

# vérif bon fonctionnement apache et php

echo "<?php phpinfo(); ?>" >/var/www/html/info.php
headTest1=`curl -Is http://$IP/info.php/| head -n 1`
headTest2=`curl -Is http://$IP/| head -n 1`
headTest1=$(echo $headTest1 | awk -F" " '{ print $3 }')
headTest2=$(echo $headTest2 | awk -F" " '{ print $3 }')
if [[ $headTest1 == OK* ]] && [[ $headTest2 == OK* ]]
then 
	echo "***********************************************"
	echo "|        Apache et php fonctionne             |"
	echo "***********************************************"
	sleep 2
else
	echo; echo "Une erreur c'est produite"
	echo
	echo "Sur un navigateur entrer '$IP/info.php' et '$IP' comme URL"
	echo "pour savoir si c'est apache ou php qui pose problème"
	echo "Si les deux fonctionnent continuer, si non :"
	echo "Vérifier qu'il n'y a pas de messages d'erreur dans la console."
	echo "Dans une autre console (cf. Tips sur github), réglé le problème."
	echo
	echo "Puis reprendre l'installation"
	ouinon
fi
rm /var/www/html/info.php
echo -e 'Options All -Indexes\n<Files .htaccess>\norder allow,deny\ndeny from all\n</Files>' > /var/www/html/.htaccess


# téléchargement rtorrent libtorrent xmlrpc

echo
echo "*******************************************************"
echo "|  Début de l'installation de rtorrent et libtorrent  |"
echo "|                    et xmlrpc                        |"
echo "*******************************************************"
echo
sleep 3

if [[ $nameDistrib == "Debian" ]]; then
	paquets=$paquetsRtoD
else
	paquets=$paquetsRtoU
fi
apt-get install -y $paquets
if [[ $? -eq 0 ]]
then 
	echo "****************************"	
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 2
else
	erreurApt
fi

# configuration rtorrent
echo
echo "*****************************************"
echo "|    Configuration de .rtorrent.rc      |"
echo "*****************************************"
sleep 2
#-----------------------------------------------------------------
cat $repLance/rto_rtorrent.rc << EOF > /home/$userLinux/.rtorrent.rc
EOF

sed -i 's/<username>/'$userLinux'/g' /home/$userLinux/.rtorrent.rc

#-----------------------------------------------------------------

echo $userLinux | sudo -S -u $userLinux mkdir /home/$userLinux/downloads
echo $userLinux | sudo -S -u $userLinux mkdir /home/$userLinux/downloads/watch
echo $userLinux | sudo -S -u $userLinux mkdir /home/$userLinux/downloads/.session

# mettre rtorrent en deamon / screen
echo
echo "******************************************************"
echo "|  Configuration de rtorrent sous screen en daemon   |"
echo "******************************************************"
sleep 2
echo

#-----------------------------------------------------------------
cat $repLance/rto_rtorrent.conf << EOF > /etc/init/rtorrent.conf
EOF

chmod u+rwx,g+rwx,o+rx  /etc/init/rtorrent.conf
sed -i 's/<username>/'$userLinux'/g' /etc/init/rtorrent.conf

#-----------------------------------------------------------------

cat $repLance/rto_rtorrentd.sh << EOF > /etc/init.d/rtorrentd.sh
EOF

chmod u+rwx,g+rwx,o+rx  /etc/init.d/rtorrentd.sh
sed -i 's/<username>/'$userLinux'/g' /etc/init.d/rtorrentd.sh

ln -s /etc/init.d/rtorrentd.sh  /etc/rc4.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc5.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc6.d/K01rtorrentd.sh
systemctl daemon-reload
service rtorrentd start

#-----------------------------------------------------------------

sleep 2
sortie=`pgrep rtorrent`

if [ -n "$sortie" ]
then 
	echo "*************************************************"
	echo "|  rtorrent en daemon fonctionne correctement  |"
	echo "*************************************************"
	sleep 2
else
	echo; echo "Il y a un problème avec rtorrent !!!"
	echo
	echo "1) Dans une autre console (cf. Tips sur github)"
	echo "taper 'ps aux | grep rtorrent' et 'ps aux | grep rtd' Si il y a des processus"
	echo "autre que ceux de grep, fausse alerte, continuer."
	echo "Si non tenter votre chance avec"
	echo "su -l <nom utilisateur> -c 'screen -fn -dmS rtd nice -19 rtorrent'"
	echo "Mêmes vérif, même conclusion, le daemon devrait démarer au reboot"
	echo "Vérifier après le reboot comme indiqué ci-dessus"
	echo
	echo "2) Si non, vérifier que rtorrent tourne correctement :"
	echo "Dans une autre console, taper 'rtorrent'"
	echo "Pour sortir de rtorrent 'Ctrl-q'"
	echo
	echo "3) Si rtorrent tourne correctement en console, c'est au niveau"
	echo "des fichiers gérant le daemon qu'est le problème :"
	echo "/etc/init/rtorrent.conf ou /etc/init.d/rtorrentd.sh, vérifier"
	echo "leur présence, qu'ils sont bien en rwxrwxr-x root:root et que"
	echo "leur contenu est ok par rapport aux sources de ce script"
	echo "idem avec /home/<votre nom d'user>/.rtorrent.rc"
	echo "vérifier également la présence de liens symboliques dans les"
	echo "fichiers /etc/rc6d rc5.d et rc4.d"
	echo
	echo "Relancer le daemon avec 'systemctl daemon-reload'"
	echo "et 'service rtorrentd start'"
	echo "'ps aux | grep rtorrent', 'ps aux | grep rtd' et 'pgrep rtorrent'"
	echo "doit vous donner des processus et un port"
	echo "- Si oui vous pouvez continuer"
	echo
	echo "- Si non, tenter votre chance en recommençant l'installation"
	echo
	echo "4) Si rtorrent ne tourne pas correctement (2ème paragraphe)"
	echo "vérifier /home/<votre nom d'user>/.rtorrent.rc comme dit"
	echo "plus haut. Si non, tentez votre chance en recommençant"
	echo "l'installation"
	echo
	echo "5) Si vous recommencez l'installation gardez un œil attentif sur les"
	echo "installations de xmlrpc, rtorrent et librtorrent"
	echo "Bonne chance, linux est avec vous !"
	ouinon
fi


# installation de rutorrent

echo
echo "**************************************************************"
echo "|  Création certificat auto signé et utilisateur ruTorrennt  |"
echo "|            Modifications apache pour ruTorrent             |"
echo "**************************************************************"
sleep 2
echo


# certif ssl

openssl req -new -x509 -days 365 -nodes -newkey rsa:2048 -out /etc/apache2/apache.pem -keyout /etc/apache2/apache.pem -subj "/C=FR/ST=Paris/L=Paris/O=Global Security/OU=RUTO Department/CN=$IP"

chmod 600 /etc/apache2/apache.pem

cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.old

sed -i "/<\/VirtualHost>/i \<Location /rutorrent>\nAuthType Digest\nAuthName \"rutorrent\"\nAuthDigestDomain \/var\/www\/html\/rutorrent\/ http:\/\/$IP\/rutorrent\n\nAuthDigestProvider file\nAuthUserFile \/etc\/apache2\/.htpasswd\nRequire valid-user\nSetEnv R_ENV \"\/var\/www\/html\/rutorrent\"\n<\/Location>\n" /etc/apache2/sites-available/default-ssl.conf

a2ensite default-ssl
serviceapache2restart


# création de userRuto

(echo -n "$userRuto:rutorrent:" && echo -n "$userRuto:rutorrent:$pwRuto" | md5sum) > /etc/apache2/.htpasswd
sed -i 's/[ ]*-$//' /etc/apache2/.htpasswd


# Modifier la configuration du site par défaut (pour rutorrent)

cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.old
#-----------------------------------------------------------------
cat $repLance/apa_000-default.conf << EOF > /etc/apache2/sites-available/000-default.conf
EOF
#-------------------------------------------------------------------

sed -i 's/<server IP>/'$IP'/g' /etc/apache2/sites-available/000-default.conf
serviceapache2restart

echo
echo "************************************************************"
echo "|  Configuration sur Apache du site par défaut terminée   |"
echo "************************************************************"
sleep 1
echo
echo
echo "*************************************************"
echo "|   Installation et configuration de ruTorrent  |"
echo "*************************************************"
sleep 2

# téléchargement

cd /var/www/html
mkdir source
cd source
wget https://github.com/Novik/ruTorrent/archive/master.zip
unzip master.zip
mv ruTorrent-master /var/www/html/rutorrent
cd /var/www/html
chown -R www-data:www-data /var/www/html/rutorrent

# fichier de config,  échapper les $variable

mv /var/www/html/rutorrent/conf/config.php /var/www/html/rutorrent/conf/config.php.old
cd /var/www/html/rutorrent/conf

cat $repLance/ruto_config.php << EOF > /var/www/html/rutorrent/conf/config.php
EOF

cd /var/www/html
chown -R www-data:www-data rutorrent
chmod -R 755 rutorrent

# modif du thème de rutorrent

cd /var/www/html/rutorrent/share/users/
mkdir -p $userRuto/torrents; mkdir -p $userRuto/settings
chown -R www-data:www-data $userRuto
chmod -R 777 $userRuto; 

echo 'O:6:"rTheme":2:{s:4:"hash";s:9:"theme.dat";s:7:"current";s:8:"Oblivion";}' > /var/www/html/rutorrent/share/users/$userRuto/settings/theme.dat
chmod u+rwx,g+rx,o+rx $userRuto 
chmod 666 /var/www/html/rutorrent/share/users/$userRuto/settings/theme.dat
chown www-data:www-data /var/www/html/rutorrent/share/users/$userRuto/settings/theme.dat


# installation de mediainfo et ffmpeg
echo
echo "**********************************************"
echo "|    Installation de mediainfo et ffmpeg     |"
echo "**********************************************"
sleep 2
echo

if [[ $nameDistrib == "Debian" ]]; then
	chmod 777 /etc/apt/sources.list
	echo $sourceMediaD >> /etc/apt/sources.list
	chmod 644 /etc/apt/sources.list
	apt-get update -yq
	apt-get install -y deb-multimedia-keyring
	apt-get update -yq
	apt-get install -y --force-yes $paquetsMediaD
	sortie=$?
else
	apt-get install -y $paquetsMediaU
	sortie=$?
fi
if [[ $sortie -eq 0 ]]
then 
	echo "****************************"	
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 2
else
	erreurApt
fi

# installation des plugins rutorrent

echo
echo "*************************************************"
echo "|      Installation des plugins ruTorrent       |"
echo "*************************************************"
sleep 2

cd /var/www/html/rutorrent/plugins
mkdir conf
cd conf

cat $repLance/ruto_plugins.ini << EOF > /var/www/html/rutorrent/plugins/conf/plugins.ini
EOF

cd ..
chown -R www-data:www-data conf/

# Ajouter le plugin log-off

cd /var/www/html/rutorrent/plugins
wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rutorrent-logoff/logoff-1.3.tar.gz

tar -zxf logoff-1.3.tar.gz
cd logoff

sed -i "s|\(\$logoffURL.*\)|\$logoffURL = \"https://www.qwant.com/\";|" /var/www/html/rutorrent/plugins/logoff/conf.php
sed -i "s|\(\$allowSwitch.*\)|\$allowSwitch = \"$userRuto\";|" /var/www/html/rutorrent/plugins/logoff/conf.php

cd ..
chown -R www-data:www-data logoff
headTest=`curl -Is http://$IP/rutorrent/| head -n 1`
headTest=$(echo $headTest | awk -F" " '{ print $3 }')
if [[ $headTest == Unauthorized* ]]
then 
	echo "****************************"	
	echo "|  ruTorrent fonctionne    |"
	echo "****************************"
else
	echo; echo "Une erreur c'est produite"
	echo
	echo "Dans un navigateur enter '$IP/rutorrent' comme URL"
	echo "Si c'est ok continuez, si non :"
	echo "Vérifier qu'il n'y a pas de messages d'erreur dans la console."
	echo "Dans une autre console (cf. Tips sur guthub), réglé le problème."
	echo
	echo "Puis reprendre l'installation"
	ouinon
fi
sleep 2

# install cakebox and Co

if [[ $installCake == "oui" ]]
then
clear
echo
echo
echo
echo "*************************************************"
echo "|           Installation de CakeBox             |"
echo "*************************************************"
echo
echo
sleep 2

# install prérequis ****************************************

apt-get install -y git python-software-properties nodejs npm javascript-common node-oauth-sign debhelper javascript-common libjs-jquery
if [[ $? -eq 0 ]]
then 
	echo "****************************"	
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 2
else
	erreurApt
fi

# install composer /tmp
cd /tmp
echo $userLinux | sudo -S -u $userLinux curl -sS http://getcomposer.org/installer | php

mv /tmp/composer.phar /usr/bin/composer
chmod +x /usr/bin/composer

# nodejs
ln -s /usr/bin/nodejs /usr/bin/node

# install bower
npm install -g bower

# CakeBox depuis github sur /html  ********************************************

# chmod sur les répertoires www et html

chmod o+r /var/www
chmod u+rwx,g+rwx /var/www/html

cd /var/www/html
git clone https://github.com/Cakebox/Cakebox-light.git cakebox

cd /var/www/html/cakebox/
git checkout -b $(git describe --tags $(git rev-list --tags --max-count=1))
cd /var/www/html

chown -R $userLinux:$userLinux cakebox/

# traitement cakebox composer bower  *****************************************

# sur Debian .composer est sur /root
if [[ $nameDistrib == "Debian"  ]]; then
	chmod o+x /root; chmod -R o+wx /root/.composer
fi
# sur ubuntu .composer est sur /home/user
if [[ $nameDistrib == "Ubuntu" ]]; then
	chown -R $userLinux:$userLinux /home/$userLinux/.composer
fi

cd /var/www/html/cakebox
echo $userLinux | sudo -S -u $userLinux composer install
echo $userLinux | sudo -S -u $userLinux bower install

# pour Debian remise en l'état  de /root 
if [[ $nameDistrib == "Debian" ]]; then
	chmod -R o-w /root/.composer; chmod o-x /root
fi

# conbfiguration ***********************************************************
cd /var/www/html/cakebox/config/
echo $userLinux | sudo -S -u $userLinux cp default.php.dist default.php

sed -i "s|\(\$app\[\"cakebox.root\"\].*\)|\$app\[\"cakebox.root\"\] = \"/home/$userLinux/downloads/\";|" /var/www/html/cakebox/config/default.php
sed -i "s|\(\$app\[\"player.default_type\"\].*\)|\$app\[\"player.default_type\"\] = \"vlc\";|" /var/www/html/cakebox/config/default.php
chown -R www-data:www-data /var/www/html/cakebox/config

# config apache et ajout de l'alias sur apache

a2enmod headers
a2enmod rewrite

a2enconf javascript-common

cat /var/www/html/cakebox/webconf-example/apache2-alias.conf.example << EOF > /etc/apache2/sites-available/cakebox.conf
EOF

sed -i -e 's|'\$ALIAS'|cakebox|g' -e 's|'\$CAKEBOXREP'|/var/www/html/cakebox|g' -e 's|'\$VIDEOREP'|/home/'$userLinux'/downloads|g' /etc/apache2/sites-available/cakebox.conf
sed -i "/.*VirtualHost.*/d" /etc/apache2/sites-available/cakebox.conf

a2ensite cakebox.conf
serviceapache2restart


# install plugin cakebox sur rutorrent
echo
echo "*******************************************************"
echo "|   Installation du plugin ruTorrent pour Cakebox     |"
echo "*******************************************************"
sleep 2
echo

cd /var/www/html/rutorrent/plugins
git clone https://github.com/Cakebox/linkcakebox.git linkcakebox
chown -R www-data:www-data /var/www/html/rutorrent/plugins/linkcakebox

sed -i "s|\(\$url.*\)|\$url = 'http:\/\/"$IP"\/cakebox';|; s|\(\$dirpath.*\)|\$dirpath = '\/home\/"$userLinux"\/downloads\/';|" /var/www/html/rutorrent/plugins/linkcakebox/conf.php

echo -e "[linkcakebox]\nenabled = yes" >> /var/www/html/rutorrent/plugins/plugins.ini

chown www-data:www-data /var/www/html/cakebox/
chown -R www-data:www-data /var/www/html/cakebox/public

#  sécuriser cakebox
echo
echo "*************************"
echo "|   Sécuriser Cakebox   |"
echo "*************************"
sleep 2
echo

a2enmod auth_basic
cd /var/www/html/cakebox/public

echo -e 'AuthName "Entrer votre identifiant et mot de passe"\nAuthType Basic\nAuthUserFile "/var/www/html/cakebox/public/.htpasswd"\nRequire valid-user' > .htaccess
chown www-data:www-data .htaccess 

htpasswd -bc ./.htpasswd $userCake $pwCake
chown www-data:www-data .htpasswd

serviceapache2restart

headTest=`curl -Is http://$IP/cakebox/| head -n 1`
headTest=$(echo $headTest | awk -F" " '{ print $3 }')
if [[ $headTest == Unauthorized* ]]
then
	echo "***************************"
	echo "|   Cakebox fonctionne    |"
	echo "***************************"	
else
	echo; echo "Une erreur c'est produite"
	echo
	echo "Dans un navigateur enter '$IP/cakebox' comme URL"
	echo "Si c'est ok continuez, si non :"
	echo "Vérifier qu'il n'y a pas de messages d'erreur dans la console."
	echo "Dans une autre console (cf. Tips sur github), régler le problème."
	echo
	echo "Puis reprendre l'installation"
	ouinon
fi
chmod 755 /var/www/html
sleep 2
fi  # cakebox


if [[ $installWebMin == "oui" ]]
then
clear
echo
echo
echo
echo "*************************************************"
echo "|           Installation de WebMin              |"
echo "*************************************************"
echo
echo
sleep 2


cd /tmp

if [[ $nameDistrib == "Debian" ]]; then
	wget $upDebWebMinD
	apt-get install -y $paquetWebMinD
	sortie1=$?
	dpkg --install $debWebMinD
	sortie2=$?
#	apt-get -f install -y
else
	wget $upDebWebMinU
	apt-get install -y /tmp/$debWebMinU
	sortie1=$?; sortie2=0
fi
let sortie=$sortie1+$sortie2
if [[ $sortie -eq 0 ]]
then 
	echo "****************************"	
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 2
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
	echo; echo "Une erreur c'est produite"
	echo
	echo "Dans un navigateur enter 'https://$IP:10000' comme URL"
	echo "Accepter l'exception au certificat pour ce site"
	echo "Si c'est ok continuez, si non :"
	echo "Vérifier qu'il n'y a pas de messages d'erreur dans la console."
	echo "Dans une autre console (cf. Tips sur Github), régler le problème."
	echo
	echo "Puis reprendre l'installation"
	ouinon
fi
fi   # Webmin
sleep 3

# sécuriser ssh

echo
echo
echo "********************************************"
echo "|             Sécuriser ssh                |"
echo "********************************************"
echo
echo
sleep 2
sed -i -e 's/^Port.*/Port '$portSSH'/' -e 's/^Protocol.*/Protocol 2/' -e 's/^PermitRootLogin.*/PermitRootLogin no/' -e 's/^X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
echo -e "UseDNS no\nAllowUsers $userLinux" >> /etc/ssh/sshd_config
service ssh restart
service ssh status
if [[ $? -ne 0 ]]; then
	echo
	echo "Pour plus d'infos 'sudo journalctl -xe'"
	echo	
	echo "Il y a un problème sur le fichier /etc/ssh/sshd_config"
	echo "Le vérifiez avant de couper la connexion ssh"
	echo "En particulier : Port $portSSH et AllowUsers $userLinux"
	echo
	echo "Après correction 'sudo service ssh restart' et 'service ssh status'"
	echo "Vous pouvez finir le script l'installation est terminée."
	echo
	echo "              /!\\"
	echo
	echo "NE PAS REBOOTER, NE PAS COUPER votre connection SSH"
	echo "avant d'avoir résolu ce problème."
	ouinon
fi
sleep 2

# remettre sudoers en ordre
sed -i "s/$userLinux ALL=(ALL) NOPASSWD:ALL/$userLinux ALL=(ALL:ALL) ALL/" /etc/sudoers

# générique de fin
hostName=$(hostname -f)
clear
echo
echo "Vous pouvez télécharger et streamer à loisir vos films (de vacances) !"
echo
echo "Pour accéder à ruTorrent :"
echo -en "\thttp(s)://$IP/rutorrent"
echo "   ID : $userRuto  PW : $pwRuto"
echo -e "\tou http(s)://$hostName/rutorrent"
echo -e "\tEn https accépter la connexion non sécurisée et"
echo -e "\tl'exception pour ce certificat !"

if [[ $installCake == "oui" ]]; then
echo "Pour accéder à Cakebox :"
echo -en "\thttp://$IP/cakebox"
echo "   ID : $userCake  PW : $pwCake"
echo -e "\tou http://$hostName/cakebox"
echo -e "\t /!\\ NE PAS utiliser https si vous voulez streamer !"
echo -e "\tSur votre poste en local pour le streaming utiliser firefox"
echo -e "\tPenser à vérifier la présence du plugin vlc sur firefox"
echo -e "\tSur linux : sudo apt-get install browser-plugin-vlc"
fi

if [[ $installWebMin == "oui" ]]; then
echo "Pour accéder à WebMin :"
echo -e "\thttps://$IP:10000"
echo -e "\tou https://$hostName:10000"
echo -e "\tID : root  PW : votre mot de passe root"
echo -e "\tAccépter la connexion non sécurisée et"
echo -e "\tl'exception pour ce certificat !"
fi

echo
sleep 1
echo "En cas de problème concernant strictement"
echo "ce script, vous pouvez aller"
echo "Consulter le wiki : https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki"
echo "et poster sur https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/issues"
echo "Et consulter le wiki : https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki"
echo
sleep 1
echo "************************************************"
echo "|     ATTENTION le port standard et root       |"
echo "|     n'ont plus d'accès en SSH et SFTP        |"
echo "************************************************"
echo
echo "Pour accéder à votre serveur en ssh :"
echo "Depuis linux, sur une console :"
echo -e "\tssh -p$portSSH  $userLinux@$IP"
echo -e "\tsur la console du serveur 'su $userLinux'"
echo "Depuis windows utiliser PuTTY"
echo
sleep 1
echo "Pour accéder aux fichiers via SFTP :"
echo -en "\tHôte : $IP"
echo -e "\tPort : $portSSH"
echo -e "\tProtocole : SFTP-SSH File Transfer Peotocol"
echo -e "\tAuthentification : normale"
echo -en "\tIdentifiant : $userLinux"
if [[ $pwLinux != "" ]]
then echo -e "\tMot de passe : $pwLinux"
else echo -e "\tVotre mot de passe"
fi
echo
sleep 1
echo "REBOOTEZ VOTRE SERVEUR"
echo
tmp=""
until [[ $tmp == "ok" ]]; do
echo
echo -n "Voulez-vous rebooter maintenant ? (o/n) "; read yno
case $yno in
	[nN] | [nN][oO][nN])
		exit 0
	;;
	[Oo] | [Oo][Uu][Ii])
		sleep 2
		reboot
	;;
	*)
		echo "Entrée invalide"
		sleep 1
	;;
esac
done



