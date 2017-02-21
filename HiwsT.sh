#!/bin/bash

# Version 1.0
# Installation apache2, php, rtorrent, rutorrent, cakebox, WebMin
# testée sur ubuntu et debian server vps Ovh
# à tester sur kimsufi et autres hébergeurs
# https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-


##################################################
#     variables install paquets Ubuntu/Debian
##################################################
#  Debian
# liste sans serveur http
paquetsWebD="mc aptitude autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php5 php5-cli php5-dev php5-fpm php5-curl php5-geoip php5-mcrypt php5-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoD="xmlrpc-api-utils libtorrent14 rtorrent"

sourceMediaD="deb http://www.deb-multimedia.org jessie main non-free"
paquetsMediaD="mediainfo ffmpeg"

upDebWebMinD="http://prdownloads.sourceforge.net/webadmin/webmin_1.830_all.deb"
paquetWebMinD="perl libnet-ssleay-perl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python"
debWebMinD="webmin_1.830_all.deb"

# Ubuntu
# liste sans serveur http
paquetsWebU="mc aptitude autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php7.0 php7.0-cli php7.0-dev php7.0-fpm php7.0-curl php-geoip php7.0-mcrypt php7.0-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoU="xmlrpc-api-utils libtorrent19 rtorrent"

paquetsMediaU="mediainfo ffmpeg"

upDebWebMinU="http://www.webmin.com/download/deb/webmin-current.deb"
debWebMinU="webmin-current.deb"

readonly REPWEB="/var/www/html"
readonly REPNGINX="/etc/nginx"
readonly REPAPA2="/etc/apache2"
readonly REPLANCE=$(echo `pwd`)
REPUL=""    # voir ligne ~345 ->  # si 2ème passage
readonly PORT_SCGI=5000  # port 1er Utilisateur
readonly miniDispoRoot=319   # minimum pour alerete place
readonly miniDispoHome=299   # disponible sur disque

#############################
#       Fonctions
#############################


__verifSaisie() {
if [[ $1 =~ ^[a-zA-Z0-9]{2,15}$ ]]; then
	yno="o"
else 	echo "Uniquement des caractères alphanumériques"
	echo "Entre 2 et 15 caractères"
	yno="n"
fi
}

__ouinon() {
local tmp=""
until [[ $tmp == "ok" ]]; do
echo
echo -n "Voulez-vous continuer ? (o/n) "; read yno
case $yno in
	[nN] | [nN][oO][nN])
		echo "Désolé, à bientôt !"
		sed -i "s/$userLinux ALL=(ALL) NOPASSWD:ALL/$userLinux ALL=(ALL:ALL) ALL/" /etc/sudoers
		if [ -e $REPWEB/info.php ]; then rm $REPWEB/info.php; fi
		exit 1
	;;
	[Oo] | [Oo][Uu][Ii])
		echo "On continue !"
		tmp="ok"
		sleep 1
	;;
	*)
		echo "Entrée invalide"
		sleep 1
	;;
esac
done
}    #  fin __ouinon(

__serviceapache2restart() {
service apache2 restart
if [ $? != 0 ]
then
	echo "Il y a un problème de configuration avec apache2"
	service apache2 status
	echo; echo "Consulter le wiki"
	echo "https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
	echo; echo "puis continuer/arrêter l'installation"
	__ouinon
fi
}   #  fin __serviceapache2restart()

__servicenginxrestart() {
service nginx restart
if [ $? != 0 ];	then
	echo "Il y a un problème de configuration avec nginx"
	service nginx status
	echo; echo "Consulter le wiki"
	echo "https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
	echo; echo "puis continuer/arrêter l'installation"
	__ouinon
fi
}  #  fin de __servicenginxrestart

__creauser() {
echo
local tmp=""; local tmp2=""
until [[ $tmp == "ok" ]]; do
	echo -n "Choisir un nom d'utilisateur linux (ni espace ni \) : "
	read -a userLinux
	__verifSaisie $userLinux
	if [[ $yno == "o" ]]; then
		egrep "^$userLinux:" /etc/passwd >/dev/null
		if [[ $? -eq 0 ]]; then
			echo "$userLinux existe déjà, choisir un autre nom"
			yno="N"
		else
			echo -n "Vous confirmez '$userLinux' comme nom d'utilisateur ? (o/n) "
			read yno
		fi
	fi
	case $yno in
		[Oo] | [Oo][Uu][Ii])   # création d'un utilisateur
			until [[ $tmp2 == "ok" ]]; do
				echo -n "Choisissez un mot de passe (ni espace ni \) : "
				read pwLinux
				echo -n "Resaisissez ce mot de passe : "
				read pwLinux2
				case $pwLinux in
					"" )
						echo "Le mot de passe ne peut pas être vide"
						echo
						sleep 1
					;;
					$pwLinux2)
						#  créer l'utilisateur $userlinux
						pass=$(perl -e 'print crypt($ARGV[0], "pwLinux")' $pwLinux)
						useradd -m -G adm,dip,plugdev,www-data,sudo -p $pass $userLinux
						if [[ $? -ne 0 ]]; then
							echo "Impossible de créer un utilisateur linux"
							__ouinon
						fi
						sed -i "1 a\bash" /home/$userLinux/.profile  #ubuntu, debian ?
						echo $userLinux > $REPLANCE/pass1
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
}  # __creauser

__erreurApt() {
	echo; echo "Une erreur c'est produite durant l'installation des paquets."
	__messageErreur
}   #  fin __erreurApt()

__messageErreur() {
	echo; echo "Consulter le wiki"
	echo "https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
	echo; echo "puis continuer/arrêter l'installation"
	__ouinon
}  # fin __messageErreur

#############################
#     Début du script
#############################


# root ?

if [[ $(id -u) -ne 0 ]]; then
	echo
	echo "Ce script nécessite d'être exécuté avec sudo."
	echo
	exit 1
fi

# info système

lsb_release &> /dev/null
if [ $? -ne 0 ]; then
	apt-get install -yq lsb-release
	__erreurApt
fi

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
	__ouinon
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
echo "Le script tourne sous : $user"
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
 	if [ "$entier" -lt "$miniDispoRoot" ]
 	then
		echo
		echo
		echo "*************************************************************************************"
		echo "|                                                                                   |"
		echo "|    ATTENTION seulement "$rootDispo", pour stocker les fichiers téléchargés        |"
		echo "|                                                                                   |"
		echo "*************************************************************************************"
	fi
else  # /home
	echo "Votre partition /home a $homeDispo de libre."
	len=${#homeDispo}
	entier=${homeDispo:0:len-1}
	entier=$(echo $entier | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')
 	if [ "$entier" -lt "$miniDispoHome" ]
 	then
		echo "************************************************************************************"
		echo "|                                                                                  |"
		echo "|    ATTENTION seulement "$homeDispo", pour stocker les fichiers téléchargés       |"
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

if [ ! -e $REPLANCE"/pass1" ]; then   # évite de tourner en rond si 2éme passage
	__ouinon

#------------------------------------------------

# Création de linux user

	echo
	echo "Vous allez créer un utilisateur spécifique"
	echo
	__creauser
	echo "Relancer le script :"
	echo "su $userLinux"
	echo "cd $REPLANCE"
	echo "sudo ./`basename $0`"
	chmod u+rwx,g+rx,o+rx $0
	exit 0
else   # si 2ème passage
	userLinux=$(cat pass1)
	REPUL="/home/$userLinux"
fi

# Choix serveur hhtp
service apache2 restart &> /dev/null
service nginx restart &> /dev/null
service apache2 status &> /dev/null; serveurHttpA=$?
service nginx status &> /dev/null; serveurHttpN=$?
echo
if [ ! $serveurHttpN -a ! $serveurHttpA ]; then
	echo "Vous avez apache2 ET nginx d'installés ?!"
	echo "Si vous continuez ce script la configuration existante va être remplacée par celle du script"
elif [ $serveurHttpN -a $serveurHttpA ]; then
	echo "Quel serveur http souhaitez-vous installer ?"
elif [ ! $serveurHttpA ]; then
	echo "Vous avez apache2 d'installer,"
	echo "Si vous continuez ce script la configuration existante va être remplacée par celle du script"
else
	echo "Vous avez nginx d'installer,"
	echo "Si vous continuez ce script la configuration existante va être remplacée par celle du script"
fi
tmp=""
until [[ $tmp == "ok" ]]; do
	echo "1) utiliser nginx"
	echo "2) utiliser Apache2"
	echo "0) sortir"
	echo -n "(0, 1, 2) "
	read -n 1 choix
	case $choix in
	0 )
		exit 0
	;;
	1 )
		serveurHttp="nginx"
		tmp="ok"
	;;
	2 )
		serveurHttp="apache2"
		tmp="ok"
	;;
	* )
		echo "Entrée invalide"
	esac
done



# Rutorrent user

echo
echo
echo "Utilisateur ruTorrent"
tmp=""; tmp2=""
until [[ $tmp == "ok" ]]; do
	echo
	echo "Il est préférable de choisir un nom différent de celui de l'utilisateur Linux"
	echo -n "Choisir un nom d'utilisateur ruTorrent (ni espace ni \) : "
	read -a userRuto
	__verifSaisie $userRuto
	if [[ $yno == "o" ]]; then
		echo -n "Vous confirmez '$userRuto' comme nom d'utilisateur ? (o/n) "
		read -n 1 yno
		echo
	fi
	case $yno in
		[Oo] | [Oo][Uu][Ii])
			until [[ $tmp2 == "ok" ]]; do
				echo -n "Choisissez un mot de passe (ni espace ni \) : "
				read pwRuto
				echo -n "Resaisissez ce mot de passe : "
				read pwRuto2
				case $pwRuto in
					"" )
						echo "Le mot de passe ne peut pas être vide"
						sleep 1
					;;
					$pwRuto2)
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
			echo "Nom d'utilisateur invalide. Reprendre la saisie"
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
echo
echo "Cakebox vous permettra, sur une interface graphique"
echo "web, de streamer, naviguer et partager vos films"
echo "depuis la seedbox, sans les télécharger sur votre PC."
echo "Pour plus d'infos https://github.com/cakebox/cakebox"
tmp=""; tmp2=""; tmp3=""
until [[ $tmp3 == "ok" ]]; do
	echo
	echo -n "Souhaitez-vous installer Cakebox ? (o/n) "
	read yno
	case $yno in
		[nN] | [nN][oO][nN])
			echo "Ok on continue"
			tmp3="ok"
			installCake="non"
		;;
		[Oo] | [Oo][Uu][Ii])
			until [[ $tmp == "ok" ]]; do
				echo
				echo "Choisir un nom d'utilisateur Cakebox"
				echo -n "(peut-être le même que pour rutorrent) (ni espace ni \) : "
				read -a userCake    # coupe si espace, 1er élément du tableau, "aa dd" donne "aa"
				__verifSaisie $userCake
				yno1=$yno
				if [[ $yno1 == "o" ]]; then
					echo -n "Vous confirmez '$userCake' comme nom d'utilisateur ? (o/n) "
					read -n 1 yno1
					echo
				fi
				case $yno1 in
					[Oo] | [Oo][Uu][Ii])
						until [[ $tmp2 == "ok" ]]; do
							echo -n "Choisissez un mot de passe (ni espace ni \) : "
							read pwCake
							echo -n "Resaisissez ce mot de passe : "
							read pwCake2
							case $pwCake in
							"" )
								echo "Le mot de passe ne peut pas être vide"
								sleep 1
							;;
							$pwCake2)
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
			echo "Ok on continue"
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


# port ssh

echo
echo
echo "Sécuriser SSH et SFTP"
echo
echo "Dans le but de sécuriser SSH et SFTP il est proposé"
echo "de changer le port standard (22) et d'interdire root"
echo "c'est une mesure de sécurité fortement recommandée."
echo "L'utilisateur sera $userLinux et le port aléatoire $portSSH"
echo "ou un port désigné par vous."
echo
tmp=""; port=""
until [[ $tmp == "ok" ]]; do
	echo
	echo -n "Souhaitez-vous appliquer cette modification ? (o/n) "; read yno
	case $yno in
		[nN] | [nN][oO][nN])
			echo
			echo "Le port reste 22 et l'utilisateur root"
			sleep 2
			changePort="non"
			portSSH="22"
			tmp="ok"
		;;
		[Oo] | [Oo][Uu][Ii])
			echo
			echo "L'utilisateur sera $userLinux"
			echo "Le port aléatoire proposé est $portSSH"
			echo "Souhaitez-vous un autre port (entre 20000 65535)"
			echo -n "Si oui saisissez le ici "; read -a port
			if [[ $port == "" ]]; then
				tmp="ok"
				changePort="oui"
	  		sleep 1
			elif ! [[ $port =~ ^[0-9]{5} ]]; then
    		echo "entrée invalide (entre 20000 et 65535)"
				sleep 1
  		elif [ $port -lt 65535 -a $port -gt 20000 ]; then
    		changePort="oui"
				portSSH=$port
				tmp="ok"
				sleep 1
  		else
    		echo "entrée invalide (entre 20000 et 65535)"
				sleep 1
			fi
		;;
		*)
			echo
			echo "Entrée invalide"
			sleep 1
		;;
	esac
done  #  fin port ssh


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
if [[ $changePort == "oui" ]]; then
	echo "Nom de votre utilisateur Linux (accès SSH et SFTP) : "$userLinux
	echo "Port pour SSh : "$portSSH
else
	echo "Nom de votre utilisateur accès SSH et SFTP : root"
  echo "Port pour SSh : "$portSSH
	echo "Nom de votre utilisateur Linux : "$userLinux
fi
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
read -n 1 yno
echo
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
sleep 1
echo
# upgrade
apt-get update -yq --force-yes
sortie=$?
apt-get upgrade -yq --force-yes
if [[ $? -eq 0 && $sortie -eq 0 ]]
then
	echo "****************************"
	echo "|  Mise à jour effectuée   |"
	echo "****************************"
	sleep 1
else
	__erreurApt  # __erreurApt()
fi

echo
echo "$userLinux ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers;
usermod -aG www-data $userLinux

# config mc

# config mc user
mkdir -p $REPUL/.config/mc/
cp $REPLANCE/fichiers-conf/mc_panels.ini $REPUL/.config/mc/panels.ini
chown -R $userLinux:$userLinux $REPUL/.config/

# config mc root
mkdir -p /root/.config/mc/
cp $REPLANCE/fichiers-conf/mc_panels.ini /root/.config/mc/panels.ini

echo
echo "******************************"
echo "|    Utilisateur linux ok    |"
echo "******************************"
sleep 1
echo

############################################
#      Installation du serveur http
############################################

if [[ $serveurHttp == "apache2" ]]; then
	service nginx stop &> /dev/null
	. $REPLANCE/insert/apacheinstall.sh
else
	service apache2 stop &> /dev/null
	. $REPLANCE/insert/nginxinstall.sh
fi

############################################
#           installation rtorrent
############################################
# téléchargement rtorrent libtorrent xmlrpc

echo
echo "*******************************************************"
echo "|  Début de l'installation de rtorrent et libtorrent  |"
echo "|                    et xmlrpc                        |"
echo "*******************************************************"
echo
sleep 1

if [[ $nameDistrib == "Debian" ]]; then
	paquets=$paquetsRtoD
else
	paquets=$paquetsRtoU
fi
apt-get install -yq $paquets
if [[ $? -eq 0 ]]
then
	echo "****************************"
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 1
else
	__erreurApt
fi

# configuration rtorrent
echo
echo "*****************************************"
echo "|    Configuration de .rtorrent.rc      |"
echo "*****************************************"
sleep 1
#-----------------------------------------------------------------
cp $REPLANCE/fichiers-conf/rto_rtorrent.rc $REPUL/.rtorrent.rc

sed -i 's/<username>/'$userLinux'/g' $REPUL/.rtorrent.rc

#-----------------------------------------------------------------

mkdir -p $REPUL/downloads/watch
mkdir -p $REPUL/downloads/.session
chown -R $userLinux:$userLinux $REPUL/downloads

# mettre rtorrent en deamon / screen
echo
echo "******************************************************"
echo "|  Configuration de rtorrent sous screen en daemon   |"
echo "******************************************************"
sleep 1
echo

#-----------------------------------------------------------------
cp $REPLANCE/fichiers-conf/rto_rtorrent.conf /etc/init/$userLinux-rtorrent.conf

chmod u+rwx,g+rwx,o+rx  /etc/init/$userLinux-rtorrent.conf
sed -i 's/<username>/'$userLinux'/g' /etc/init/$userLinux-rtorrent.conf

#-----------------------------------------------------------------

cp $REPLANCE/fichiers-conf/rto_rtorrentd.sh /etc/init.d/rtorrentd.sh

chmod u+rwx,g+rwx,o+rx  /etc/init.d/rtorrentd.sh
sed -i 's/<username>/'$userLinux'/g' /etc/init.d/rtorrentd.sh

ln -s /etc/init.d/rtorrentd.sh  /etc/rc4.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc5.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc6.d/K01rtorrentd.sh
systemctl daemon-reload
service rtorrentd start

#-----------------------------------------------------------------

sleep 1
sortie=`pgrep rtorrent`

if [ -n "$sortie" ]
then
	echo "*************************************************"
	echo "|  rtorrent en daemon fonctionne correctement   |"
	echo "*************************************************"
	sleep 1
else
	echo; echo "Il y a un problème avec rtorrent !!!"
	__messageErreur
fi


############################################
#        installation de rutorrent
############################################

# création de userRuto dans apacheinstall.sh / nginxinstall.sh
# Modifier la configuration du site par défaut (pour rutorrent) dans apacheinstall.sh / nginxinstall.sh

echo
echo "*************************************************"
echo "|   Installation et configuration de ruTorrent  |"
echo "*************************************************"
sleep 1

# téléchargement

mkdir $REPWEB/source
cd $REPWEB/source
wget https://github.com/Novik/ruTorrent/archive/master.zip
unzip master.zip
mv ruTorrent-master $REPWEB/rutorrent

chown -R www-data:www-data $REPWEB/rutorrent

# fichier de config

mv $REPWEB/rutorrent/conf/config.php $REPWEB/rutorrent/conf/config.php.old

cp $REPLANCE/fichiers-conf/ruto_config.php $REPWEB/rutorrent/conf/config.php

chown -R www-data:www-data $REPWEB/rutorrent
chmod -R 755 $REPWEB/rutorrent

if [[ $serveurHttp == "apache2" ]]; then
	# modif .htaccess dans /rutorrent  le passwd paramétré dans sites-available
	echo -e 'Options All -Indexes\n<Files .htaccess>\norder allow,deny\ndeny from all\n</Files>' > $REPWEB/rutorrent/.htaccess
fi

# modif du thème de rutorrent
mkdir -p $REPWEB/rutorrent/share/users/$userRuto/torrents
mkdir $REPWEB/rutorrent/share/users/$userRuto/settings
chown -R www-data:www-data $REPWEB/rutorrent/share/users/$userRuto
chmod -R 777 $REPWEB/rutorrent/share/users/$userRuto

echo 'O:6:"rTheme":2:{s:4:"hash";s:9:"theme.dat";s:7:"current";s:8:"Oblivion";}' > $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat
chmod u+rwx,g+rx,o+rx $REPWEB/rutorrent/share/users/$userRuto
chmod 666 $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat
chown www-data:www-data $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat


# installation de mediainfo et ffmpeg
echo
echo "**********************************************"
echo "|    Installation de mediainfo et ffmpeg     |"
echo "**********************************************"
sleep 1
echo

if [[ $nameDistrib == "Debian" ]]; then
	chmod 777 /etc/apt/sources.list
	echo $sourceMediaD >> /etc/apt/sources.list
	chmod 644 /etc/apt/sources.list
	apt-get update -yq
	apt-get install -yq deb-multimedia-keyring
	apt-get update -yq
	apt-get install -y --force-yes $paquetsMediaD
	sortie=$?
else
	apt-get install -yq $paquetsMediaU
	sortie=$?
fi
if [[ $sortie -eq 0 ]]
then
	echo "****************************"
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 1
else
	__erreurApt
fi

# installation des plugins rutorrent

echo
echo "*************************************************"
echo "|      Installation des plugins ruTorrent       |"
echo "*************************************************"
sleep 1

mkdir $REPWEB/rutorrent/plugins/conf

cp $REPLANCE/fichiers-conf/ruto_plugins.ini $REPWEB/rutorrent/plugins/conf/plugins.ini

# création de conf/users/userRuto en prévision du multiusers
mkdir -p $REPWEB/rutorrent/conf/users/$userRuto
cp $REPWEB/rutorrent/conf/access.ini $REPWEB/rutorrent/conf/plugins.ini $REPWEB/rutorrent/conf/users/$userRuto
cp $REPLANCE/fichiers-conf/ruto_multi_config.php $REPWEB/rutorrent/conf/users/$userRuto/config.php

sed -i -e 's/<port>/'$PORT_SCGI'/' -e 's/<username>/'$userRuto'/' $REPWEB/rutorrent/conf/users/$userRuto/config.php

chown -R www-data:www-data $REPWEB/rutorrent/conf

# Ajouter le plugin log-off

cd $REPWEB/rutorrent/plugins
wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rutorrent-logoff/logoff-1.3.tar.gz
tar -zxf logoff-1.3.tar.gz

# action pro qWant
sed -i "s|\(\$logoffURL.*\)|\$logoffURL = \"https://www.qwant.com/\";|" $REPWEB/rutorrent/plugins/logoff/conf.php
sed -i "s|\(\$allowSwitch.*\)|\$allowSwitch = \"$userRuto\";|" $REPWEB/rutorrent/plugins/logoff/conf.php
echo -e "\n;;\n        [logoff]\n        enabled = yes" >> $REPWEB/rutorrent/plugins/conf/plugins.ini

chown -R www-data:www-data $REPWEB/rutorrent/plugins/logoff
headTest=`curl -Is http://$IP/rutorrent/| head -n 1`
headTest=$(echo $headTest | awk -F" " '{ print $3 }')
if [[ $headTest == Unauthorized* ]]
then
	echo "****************************"
	echo "|  ruTorrent fonctionne    |"
	echo "****************************"
else
	echo; echo "Une erreur s'est produite sur ruTorrent"
	__messageErreur
fi
sleep 1

#######################################################
#   install cakebox and Coinstall cakebox and Co
#######################################################


if [[ $installCake == "oui" ]]
then
. $REPLANCE/insert/cakeboxinstall.sh
fi  # cakebox

#######################################################
#             installation de WebMin
#######################################################

if [[ $installWebMin == "oui" ]]
then
. $REPLANCE/insert/webmininstall.sh
fi   # Webmin

########################################
#            sécuriser ssh
########################################
#  des choses à faire de tte façon
. $REPLANCE/insert/sshsecuinstall.sh



# remettre sudoers en ordre
sed -i "s/$userLinux ALL=(ALL) NOPASSWD:ALL/$userLinux ALL=(ALL:ALL) ALL/" /etc/sudoers

# copie les script dans home
cp -r  $REPLANCE $REPUL/HiwsT
chown -R $userLinux:$userLinux $REPUL/HiwsT
chown root:root $REPUL/HiwsT/pass1
chmod 400 $REPUL/HiwsT/pass1  # r-- --- ---


########################################
#            générique de fin
########################################

hostName=$(hostname -f)
clear
echo
echo "Vous pouvez télécharger et streamer à loisir vos films (de vacances) !"
echo
echo "Pour accéder à ruTorrent :"
echo -en "\thttp(s)://$IP/rutorrent"
echo "   ID : $userRuto  PW : $pwRuto"
echo -e "\tou http(s)://$hostName/rutorrent"
echo -e "\tEn https accepter la connexion non sécurisée et"
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
	echo -e "\tAccepter la connexion non sécurisée et"
	echo -e "\tl'exception pour ce certificat !"
fi

echo
sleep 1
echo "En cas de problème concernant strictement ce script, vous pouvez aller"
echo "Consulter le wiki : https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki"
echo "et poster sur https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/issues"
echo
sleep 1
if [[ $changePort == "oui" ]]; then   # ssh sécurisé
	echo "************************************************"
	echo "|     ATTENTION le port standard et root       |"
	echo "|     n'ont plus d'accès en SSH et SFTP        |"
	echo "************************************************"
	echo
	echo "Pour accéder à votre serveur en ssh :"
	echo "Depuis linux, sur une console :"
	echo -e "\tssh -p$portSSH  $userLinux@$IP"
	echo "Depuis windows utiliser PuTTY"
	echo
	sleep 1
	echo "Pour accéder aux fichiers via SFTP :"
	echo -en "\tHôte : $IP"
	echo -e "\tPort : $portSSH"
	echo -e "\tProtocole : SFTP-SSH File Transfer Peotocol"
	echo -e "\tAuthentification : normale"
	echo -en "\tIdentifiant : $userLinux"
	if [[ $pwLinux != "" ]]; then
		echo -e "\tMot de passe : $pwLinux"
	else
		echo -e "\tVotre mot de passe"
	fi
	echo
	sleep 1
else   # ssh n'est pas sécurisé
	echo "Pour accéder à votre serveur en ssh :"
	echo "Depuis linux, sur une console :"
	echo -e "\tssh root@$IP"
	echo -e "\tSur la console du serveur 'su $userLinux'"
	echo "Depuis windows utiliser PuTTY"
	echo
	sleep 1
	echo "Pour accéder aux fichiers via SFTP :"
	echo -en "\tHôte : $IP"
	echo -e "\tPort : 22"
	echo -e "\tProtocole : SFTP-SSH File Transfer Protocol"
	echo -e "\tAuthentification : normale"
	echo -e "\tIdentifiant : root"
fi   # ssh pas sécurisé/ sécurisé
echo
echo "REBOOTEZ VOTRE SERVEUR"
echo
tmp=""
until [[ $tmp == "ok" ]]; do
	echo
	echo -n "Voulez-vous rebooter maintenant ? (o/n) "; read yno
	case $yno in
		[nN] | [nN][oO][nN])
			echo
			echo "Il peut être nécessaire de rebooter pour que tout fonctionne à 100%"
			exit 0
		;;
		[Oo] | [Oo][Uu][Ii])
			sleep 1
			reboot
		;;
		*)
			echo "Entrée invalide"
			sleep 1
		;;
	esac
done
