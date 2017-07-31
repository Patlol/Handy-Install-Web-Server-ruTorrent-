#!/bin/bash

# Installation apache2, php, rtorrent, rutorrent, WebMin
# testée sur ubuntu et debian server vps Ovh
# et sur kimsufi. A tester sur autres hébergeurs
# https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-


##################################################
#     variables install paquets Ubuntu/Debian
##################################################
#  Debian
# liste sans serveur http
paquetsWebD="mc nano aptitude autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php5 php5-cli php5-dev php5-fpm php5-curl php5-geoip php5-mcrypt php5-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoD="xmlrpc-api-utils libtorrent14 rtorrent"

sourceMediaD="deb http://www.deb-multimedia.org jessie main non-free"
paquetsMediaD="mediainfo ffmpeg"

# Ubuntu
# liste sans serveur http
paquetsWebU="mc nano aptitude autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php7.0 php7.0-cli php7.0-dev php7.0-fpm php7.0-curl php-geoip php7.0-mcrypt php7.0-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoU="xmlrpc-api-utils libtorrent19 rtorrent"

paquetsMediaU="mediainfo ffmpeg"

#------------------------------------------------------------------------------
readonly HOSTNAME=$(hostname -f)
readonly REPWEB="/var/www/html"
readonly REPAPA2="/etc/apache2"
readonly REPLANCE=$(echo `pwd`)
REPUL=""    # repertoire user Linux dans __creauser
readonly PORT_SCGI=5000  # port 1er Utilisateur
readonly PLANCHER=20001  # bas fourchette port ssh
readonly ECHELLE=65534  # ht de la fourchette
readonly miniDispoRoot=334495744   # 319 Go minimum pour alerete place \
readonly miniDispoHome=313524224   # 299 Go disponible sur disque
readonly serveurHttp="apache2"
# dialog param --backtitle --aspect --colors
readonly TITRE="HiwsT : Installation rtorrent - ruTorrent"
readonly RATIO=12
readonly R="\Z1"
readonly BK="\Z0"  # black
readonly G="\Z2"
readonly Y="\Z3"
readonly BL="\Z4"  # blue
readonly W="\Z7"
readonly BO="\Zb"  # bold
readonly I="\Zr"   # vidéo inversée
readonly N="\Zn"   # retour à la normale

######################################
#       Fonctions utilitaires
######################################

__trap() {  # pour exit supprime NOPASSWD et info.php
	if [ -e $REPWEB/info.php ]; then rm $REPWEB/info.php; fi
}

__ouinonBox() {    # param : titre, texte  sortie $__ouinonBox oui : 0 ou non : 1
	CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}"  --yesno "
${2}" 0 0 )
	choix=$("${CMD[@]}" 2>&1 >/dev/tty)
	__ouinonBox=$?
}    #  fin ouinon

__messageBox() {   # param : titre texte
			CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --msgbox "${2}" 0 0)
			choix=$("${CMD[@]}" 2>&1 >/dev/tty)
}

__infoBox() {   # param : titre sleep texte
			CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --sleep ${2} --infobox "${3}" 0 0)
			choix=$("${CMD[@]}" 2>&1 >/dev/tty)
}

__msgErreurBox() {
	__messageBox "$R Error message $N" "

`cat /tmp/hiwst.log`
	$R
See the wiki on github $N
https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/something-wrong

The error message is stored in $I/tmp/trace$N"
	__ouinonBox "Error" "
Do you want continue anyway?"
	if [[ $__ouinonBox -ne 0 ]]; then exit 1; fi
}  # fin messageErreur

__saisieTexteBox() {   # param : titre, texte
	until [[ 1 -eq 2 ]]; do
		CMD=(dialog --aspect $RATIO --colors --nocancel --backtitle "$TITRE" --title "${1}" --max-input 15 --inputbox "${2}" 0 0)
		__saisieTexteBox=$("${CMD[@]}" 2>&1 >/dev/tty)
		if [ $? == 1 ]; then return 1; fi
		if [[ "$__saisieTexteBox" =~ ^[a-zA-Z0-9]{2,15}$ ]]; then
			__saisieTexteBox=$(echo $__saisieTexteBox | tr '[:upper:]' '[:lower:]')
			break
		else
			__infoBox "Entry validation" 3 "
Only alphanumeric characters
Between 2 and 15 characters"
		fi
	done
}

__saisiePwBox() {  # param : titre, texte, nbr de ligne sous boite
  local pw=1""; local pw2=""; local codeSortie=""; local reponse=""
	until [[ 1 -eq 2 ]]; do
		CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --insecure --nocancel --passwordform "${2}" 0 0 ${3} "Password " 2 4 "" 2 25 25 25 "Retype: " 4 4 "" 4 25 25 25 )
		reponse=$("${CMD[@]}" 2>&1 >/dev/tty)
		if [[ "$reponse" =~ .*[[:space:]].*[[:space:]].* ]] || \
		[[ "$reponse" =~ [\\] ]]; then
      __infoBox "${1}" 2 "
The password can't contain spaces or \\."
    else
	    pw1=$(echo $reponse | awk -F" " '{ print $1 }')
	    pw2=$(echo $reponse | awk -F" " '{ print $2 }')
			case $pw1 in
				"" )
					__infoBox "${1}" 2 "
The password can't be empty."
				;;
				$pw2 )
					__saisiePwBox=$pw1
					break
				;;
				* )
					__infoBox "${1}" 2 "
The 2 inputs are not identical."
				;;
			esac
		fi
	done
}

__textBox() {   # $1 titre  $2 fichier à lire  $3 texte baseline
  CMD=(dialog --backtitle "$TITRE" --exit-label "Continued from installation" --title "${1}" --hline "${3}" --textbox  "${2}" 0 0)
	("${CMD[@]}" 2>&1 >/dev/tty)
}

__cmd() {
  local msgErreur
  $*
  err=$?
  if [[ $err -ne 0 ]]; then
    msgErreur="$BO$R$*$N \nerreur N° $R$err$N"
		echo "------------------" >> /tmp/hiwst.log
    echo -e $msgErreur" " >> /tmp/hiwst.log
		tail --lines=16 /tmp/trace >> /tmp/hiwst.log
    echo "------------------" >> /tmp/hiwst.log
    tail --lines=16 /tmp/trace
		__msgErreurBox
		:>/tmp/hiwst.log  # ràz
    return 1
  else
		:>/tmp/hiwst.log
    return 0
  fi
}
__serviceapache2restart() {
	service apache2 restart
	__cmd "service apache2 status"
}   #  fin __serviceapache2restart()


###############################################################
#                Début du script                              #
###############################################################

# root ?

if [[ $(id -u) -ne 0 ]]; then
	echo
	echo "This script needs to be run with sudo."
	echo
	exit 1
fi
clear

#########################################
## localisation et infos système        #
#########################################

# Complèter la localisation (vps)
lang=$(cat /etc/locale.gen | egrep ^[a-z].*UTF-8$ | awk -F" " '{print $1 }')
export LANGUAGE=$lang
export LANG=$lang
export LC_ALL=$lang
update-locale LANGUAGE=$lang
update-locale LANG=$lang
update-locale LC_ALL=$lang
dpkg-reconfigure --frontend=noninteractive locales
locale-gen

# installe dialog si pas installé
apt-get update
which dialog &>/dev/null
if [ $? -ne 0 ]; then
	apt-get install -yq dialog
fi
# installe lsb_release si pas installé
which lsb_release &>/dev/null
if [ $? -ne 0 ]; then
	apt-get install -yq lsb-release
fi
# installe sudo si pas installé
which sudo &>/dev/null
if [ $? -ne 0 ]; then
	apt-get install -yq sudo
fi


arch=$(uname -m)
interface=ifconfig | grep "Ethernet" | awk -F" " '{ print $1 }'
# pas tjs eth0 ... ou interface=$(ip -o -4 addr | grep $IP | awk '{print $2}')
# ou ip -o -4 link | grep ether (ou BROADCAST)
# 2: eth0: <BROADCAST,MULTI ... link/ether fa:1 ...
readonly IP=$(ifconfig $interface 2>/dev/null | grep 'inet ad' | awk -F: '{ printf $2 }' | awk '{ printf $1 }')
distrib=$(cat /etc/issue | awk -F"\\" '{ print $1 }')
nameDistrib=$(lsb_release -si)  # Debian ou Ubuntu
os_version=$(lsb_release -sr)   # 18 , 8.041 ...
os_version_M=$(echo $os_version | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')  # version majeur
description=$(lsb_release -sd)     #  nom de code
user=$(id -un)       #  root avec user sudo

# espace dispo
homeDispo=$(df | grep /home | awk -F" " '{ print $4 }')
rootDispo=$(df | grep  /$ | awk -F" " '{ print $4 }')
if [ -z "$homeDispo" ]; then
	info="You don't have /home partition"
else
  info="Your /home partition has $(( $homeDispo/1024/1024 )) Go free."
fi

# portSSH aléatoire
RANDOM=$$  # N° processus du script
portSSH=0   #   initialise 20000 65535
while [ $portSSH -le $PLANCHER ]; do
  portSSH=$RANDOM
  let "portSSH %= $ECHELLE"  # Ramène $portSSH dans $ECHELLE.
done

# ubuntu / debian et bonne version ?

if [ $nameDistrib == "Debian" -a $os_version_M -gt 8 -o $nameDistrib == "Ubuntu" -a $os_version_M -gt 16 ]; then
	__ouinonBox "Distribution check" "
	You are using $description
	This script is intended to run on a Debian server 8.xx ou Ubuntu 16.xx
	You risk having version issues at installation
	Do you want to continue?"
	if [[ $__ouinonBox -ne 0 ]]; then	exit 1; fi
fi

if [ $nameDistrib == "Debian" -a $os_version_M -lt 8 -o $nameDistrib == "Ubuntu" -a $os_version_M -lt 16 ]; then
	__messageBox "Distribution check" "

	You are using $description
	This script is intended to run on a Debian server 8.xx ou Ubuntu 16.xx"
	exit 1
fi

if [ $nameDistrib != "Debian" -a $nameDistrib != "Ubuntu" ]; then
	__messageBox "Distribution check" "

	You are using $description
	This script is intended to run on a Debian server 8.xx ou Ubuntu 16.xx"
	exit 1
fi

# Vérif serveur hhtp
service apache2 restart &> /dev/null
service nginx restart &> /dev/null
service apache2 status &> /dev/null; serveurHttpA=$?
service nginx status &> /dev/null; serveurHttpN=$?
service apache2 stop &> /dev/null
service nginx stop &> /dev/null

if [[ $serveurHttpN -eq 0 ]] && [[ $serveurHttpA -eq 0 ]]; then
	__ouinonBox "Http server" "
You have apache2$BO and$N nginx installed!?
If you continue this script, the existing configuration will be replaced by the script configuration (apache2)"
	if [[ $__ouinonBox -eq 1 ]]; then exit 1; fi
elif [[ $serveurHttpA -eq 0 ]]; then
	__ouinonBox "Http server" "
You have apache2 installed,
If you continue this script, the existing configuration will be replaced by the script configuration"
	if [[ $__ouinonBox -eq 1 ]]; then exit 1; fi
elif [[ $serveurHttpN -eq 0 ]]; then
	__ouinonBox "Http server" "
You have nginx installed,
If you continue this script, the existing configuration will be replaced by the script configuration (apache2)"
	if [[ $__ouinonBox -eq 1 ]]; then exit 1; fi
fi
#--------------------------------------------------------------


#############################
#    Partie interactive
#    ID, PW, questions
#############################

__messageBox "$R Important message $N" "

                    $I WARNING !!! $N

 The use of this script must be done on a fresh server
 as delivered by your host.

$R Any installation may be damaged by this script!!!
 Never run this script on a server in production."

__messageBox "Your system" " $BO

Distribution :$N $description $BO
Architecture :$N $arch $BO
Your IP     :$N $IP $BO
The script runs under:$N $user
$BO
Execution duration:$N about 6mn

Amount of disk space available$BO
Your root partition (/) has $(( $rootDispo/1024/1024 )) Go free.
$info"  # $info valeur suivant $homeDispo cf. # espace dispo

if [ -z "$homeDispo" ]; then  # /
 	if [ $rootDispo -lt $miniDispoRoot ]; then
		__infoBox "Important message" 4 "
$BO $R
WARNING $N

Only $R$(( $rootDispo/1024/1024 )) Go$N, on / to store downloaded files"
	fi
else  # /home
 	if [ $homeDispo -lt $miniDispoHome ];then
		__infoBox "Important message" 4 "
$BO $R
WARNING $N

Only $R$(( $homeDispo/1024/1024 )) Go$N, on /home to store downloaded files"
	fi
fi

# utilisateur linux
usernameOk=0
until [[ $usernameOk -ne 0 ]]; do
	__saisieTexteBox "Linux user" "
You must create a specific user.
Choose a linux username$R
(neither space nor \)$N : "
	userLinux=$__saisieTexteBox
	egrep "^$userLinux:" /etc/passwd >/dev/null
	usernameOk=$?
	if [[ $usernameOk -eq 0 ]]; then
		__infoBox "Linux user" 3 "
	$userLinux already exists, choose another username"
	fi
done
	__saisiePwBox "Linux user" "
Password for $userLinux:" 4
pwLinux=$__saisiePwBox

# Rutorrent user
usernameOk=0
until [[ $usernameOk -ne 0 ]]; do
	__saisieTexteBox "ruTorrent user" "

It's more secure to choose a different name
than the Linux user
Choose a ruTorrent username$R (neither space nor \)$N: "
	userRuto=$__saisieTexteBox
	egrep "^$userRuto:" /etc/passwd >/dev/null
	usernameOk=$?
	if [[ $usernameOk -eq 0 ]] && [[ $userRuto != $userLinux ]]; then
			__infoBox "ruTorrent user" 3 "
		$userRuto already exists, choose another username"
	fi
done
__saisiePwBox "ruTorrent user" "
Password for $userRuto:" 4
pwRuto=$__saisiePwBox

#  webmin
__ouinonBox "Webmin" "
Would you like to install Webmin?"
installWebMin=$__ouinonBox

# port ssh
__ouinonBox "Secure ssh/sftp" "
In order to secure SSH and SFTP it's proposed to change the standard port (22) and to prohibit root.
 $R
This is a highly recommended safety measure.$N

The user will be $userLinux and the random port $portSSH$BO or a port designated by you.$N
Would you like to apply this change?"
changePort=$__ouinonBox
if [ $changePort -eq 0 ]; then
	choix=0
	until [ $choix -le $ECHELLE -a $choix -ge $PLANCHER ]; do
	  CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "ssh/sftp port" --max-input 5 --nocancel --inputbox "
The proposed random port is $I$portSSH$N $BO
You can change it between $PLANCHER and $ECHELLE$N" 0 0 $portSSH)
	  choix=$("${CMD[@]}" 2>&1 >/dev/tty)
	done
	portSSH=$choix
	userSSH=$userLinux
else
	portSSH=22
	userSSH="root"
fi


#  Récapitulatif
cat << EOF > $REPUL/RecapInstall.txt

This information will be used only after the script has been executed correctly.

Distribution    : $description
Architecture    : $arch
Your IP         : $IP
Your hostname   : $HOSTNAME

`if [ -z "$homeDispo" ]
then
	echo "You haven't /home partition."
else
	echo "Your /home partition has $(( $homeDispo/1024/1024 )) Go free."
fi`
Your root (/) partition has $(( $rootDispo/1024/1024 )) Go free.
Your http server is $serveurHttp

Name of user with SSH and SFTP access: $userSSH
SSh port: $portSSH

Linux username:           $userLinux
Password Linux user:      $pwLinux

ruTorrent username:       $userRuto
Password ruTorrent user:  $pwRuto

`if [[ $installWebMin -ne 0 ]]
then
	echo "You don't want to install WebMin"
else
	echo "You want install WebMin"
	echo "The user will be "root" with his password"
fi`
EOF

__textBox "Installation Summary" $REPUL/RecapInstall.txt
__ouinonBox "Installation" "Do you want start installation?"
if [ $__ouinonBox -ne 0 ]; then exit 0; fi


############################################
#            Début de la fin
############################################

clear
## gestion des erreurs stderr par __cmd()
:>/tmp/trace
:>/tmp/hiwst.log
exec 2>/tmp/trace
echo
echo
echo
echo "************************************"
echo "|           Installation           |"
echo "************************************"
echo
echo
echo
echo "************************************"
echo "|           System update          |"
echo "|     User Linux configuration     |"
echo "|       Packages installation      |"
echo "************************************"
sleep 1
echo

# upgrade
__cmd "apt-get update -yq"
__cmd "apt-get upgrade -yq"
echo "***********************"
echo "|  Update completed   |"
echo "***********************"
sleep 1

##############################
#  Création de linux user    #
##############################
pwCrypt=$(perl -e 'print crypt($ARGV[0], "pwLinux")' $pwLinux)
useradd -m -G adm,dip,plugdev,www-data,sudo -p $pwCrypt $userLinux
if [[ $? -ne 0 ]]; then
	__infoBox "Linux user" 3 "
Unable to create linux user"
	exit 1
fi
sed -i "1 a\bash" /home/$userLinux/.profile  #ubuntu ok, debian ok après reboot
echo $userLinux > $REPLANCE/firstusers
readonly REPUL="/home/$userLinux"
trap "__trap" EXIT # supprime nopasswd et info.php en cas d'exit
__cmd "usermod -aG www-data $userLinux"

## config mc (installé dans apacheinstall)
# config mc user
mkdir -p $REPUL/.config/mc/
cp $REPLANCE/fichiers-conf/mc_panels.ini $REPUL/.config/mc/panels.ini
chown R $userLinux:$userLinux $REPUL/.config/
# config mc root
mkdir -p /root/.config/mc/
cp $REPLANCE/fichiers-conf/mc_panels.ini /root/.config/mc/panels.ini

echo
echo "***************************"
echo "|   Linux user created    |"
echo "***************************"
sleep 1
echo

############################################
#      Installation du serveur http        #
############################################
	service nginx stop &> /dev/null
	. $REPLANCE/insert/apacheinstall.sh

############################################
#           installation rtorrent          #
############################################
# téléchargement rtorrent libtorrent xmlrpc
if [[ $nameDistrib == "Debian" ]]; then
	paquets=$paquetsRtoD
else
	paquets=$paquetsRtoU
fi
__cmd "apt-get install -yq $paquets"

echo
echo "******************************"
echo "|    rtorrent, libtorrent    |"
echo "|    and xmlrpc packages     |"
echo "******************************"
echo
sleep 1


# configuration rtorrent
cp $REPLANCE/fichiers-conf/rto_rtorrent.rc $REPUL/.rtorrent.rc
sed -i 's/<username>/'$userLinux'/g' $REPUL/.rtorrent.rc

mkdir -p $REPUL/downloads/watch
mkdir -p $REPUL/downloads/.session
chown -R $userLinux:$userLinux $REPUL/downloads
echo
echo "************************************************"
echo "|   .rtorrent.rc configured for Linux user     |"
echo "************************************************"
sleep 1

# mettre rtorrent en deamon / screen
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
	echo "**************************************"
	echo "|  rtorrent daemon works correctly   |"
	echo "**************************************"
	sleep 1
else
	__cmd "ps aux | grep -e '^$userLinux.*rtorrent$'"
fi


############################################
#        installation de rutorrent         #
############################################

# création de userRuto dans apacheinstall.sh
# Modifier la configuration du site par défaut (pour rutorrent) dans apacheinstall.sh

# téléchargement
mkdir $REPWEB/source
cd $REPWEB/source
__cmd "wget https://github.com/Novik/ruTorrent/archive/master.zip"
unzip -o master.zip
mv -f ruTorrent-master $REPWEB/rutorrent
chown -R www-data:www-data $REPWEB/rutorrent

# fichier de config config.php générique ( modif dans conf/user/nonuser/)
mv $REPWEB/rutorrent/conf/config.php $REPWEB/rutorrent/conf/config.php.old
cp $REPLANCE/fichiers-conf/ruto_config.php $REPWEB/rutorrent/conf/config.php
chown -R www-data:www-data $REPWEB/rutorrent
chmod -R 755 $REPWEB/rutorrent

# modif .htaccess dans /rutorrent  le passwd paramétré dans sites-available
echo -e 'Options All -Indexes\n<Files .htaccess>\norder allow,deny\ndeny from all\n</Files>' > $REPWEB/rutorrent/.htaccess

# modif du thème de rutorrent
mkdir -p $REPWEB/rutorrent/share/users/$userRuto/torrents
mkdir $REPWEB/rutorrent/share/users/$userRuto/settings
chown -R www-data:www-data $REPWEB/rutorrent/share/users/$userRuto
chmod -R 777 $REPWEB/rutorrent/share/users/$userRuto

echo 'O:6:"rTheme":2:{s:4:"hash";s:9:"theme.dat";s:7:"current";s:8:"Oblivion";}' > $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat
chmod u+rwx,g+rx,o+rx $REPWEB/rutorrent/share/users/$userRuto
chmod 666 $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat
chown www-data:www-data $REPWEB/rutorrent/share/users/$userRuto/settings/theme.dat

echo
echo "**********************************************"
echo "|    ruTorrent installed and configured      |"
echo "**********************************************"
sleep 1

# installation de mediainfo et ffmpeg
if [[ $nameDistrib == "Debian" ]]; then
	chmod 777 /etc/apt/sources.list
	echo $sourceMediaD >> /etc/apt/sources.list
	chmod 644 /etc/apt/sources.list
	apt-get update -yq
	__cmd "apt-get install -yq --force-yes deb-multimedia-keyring"
	apt-get update -yq
	__cmd "apt-get install -y --force-yes $paquetsMediaD"
else
	__cmd "apt-get install -yq --force-yes $paquetsMediaU"
fi
echo
echo "*****************************************"
echo "|    mediainfo and ffmpeg installed     |"
echo "*****************************************"
sleep 1

## plugins rutorrent
mkdir $REPWEB/rutorrent/plugins/conf

cp $REPLANCE/fichiers-conf/ruto_plugins.ini $REPWEB/rutorrent/plugins/conf/plugins.ini

# création de conf/users/userRuto en prévision du multiusers
mkdir -p $REPWEB/rutorrent/conf/users/$userRuto
cp $REPWEB/rutorrent/conf/access.ini $REPWEB/rutorrent/conf/plugins.ini $REPWEB/rutorrent/conf/users/$userRuto
cp $REPLANCE/fichiers-conf/ruto_multi_config.php $REPWEB/rutorrent/conf/users/$userRuto/config.php

sed -i -e 's/<port>/'$PORT_SCGI'/' -e 's/<username>/'$userLinux'/' $REPWEB/rutorrent/conf/users/$userRuto/config.php

chown -R www-data:www-data $REPWEB/rutorrent/conf

# Ajouter le plugin log-off

cd $REPWEB/rutorrent/plugins
__cmd "wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rutorrent-logoff/logoff-1.3.tar.gz"
tar -zxf logoff-1.3.tar.gz

# action pro Qwant
sed -i "s|\(\$logoffURL.*\)|\$logoffURL = \"https://www.qwant.com/\";|" $REPWEB/rutorrent/plugins/logoff/conf.php
sed -i "s|\(\$allowSwitch.*\)|\$allowSwitch = \"$userRuto\";|" $REPWEB/rutorrent/plugins/logoff/conf.php
echo -e "\n;;\n        [logoff]\n        enabled = yes" >> $REPWEB/rutorrent/plugins/conf/plugins.ini

chown -R www-data:www-data $REPWEB/rutorrent/plugins/logoff
echo
echo "********************************************"
echo "|       ruTorrent plugins installed        |"
echo "********************************************"
sleep 1

headTest=`curl -Is http://$IP/rutorrent/| head -n 1`
headTest=$(echo $headTest | awk -F" " '{ print $3 }')
if [[ "$headTest" == Unauthorized* ]]
then
	echo
	echo "*********************************"
	echo "|  ruTorrent works correctly    |"
	echo "*********************************"
	sleep 1
else
	echo "curl -Is http://$IP/rutorrent/| head -n 1 return $headTest" >> /tmp/hiwst.log
	__msgErreurBox
fi

#######################################################
#             installation de WebMin                  #
#######################################################

if [[ $installWebMin -eq 0 ]]
then
. $REPLANCE/insert/webmininstall.sh
fi   # Webmin

########################################
#            sécuriser ssh             #
########################################
#  des choses à faire de tte façon
. $REPLANCE/insert/sshsecuinstall.sh


## copie les scripts dans home
cp -r  $REPLANCE $REPUL/HiwsT
chown -R $userLinux:$userLinux $REPUL/HiwsT

## complète firstusers
echo $userRuto >> $REPUL/HiwsT/firstusers
chown root:root $REPUL/HiwsT/firstusers
chmod 400 $REPUL/HiwsT/firstusers  # r-- --- ---

## copie dans $REPUL/HiwsT les fichiers log et trace
cp -t $REPUL/HiwsT /tmp/hiwst.log /tmp/trace
rm -r $REPLANCE



########################################
#            générique de fin          #
########################################

cat << EOF > $REPUL/HiwsT/RecapInstall.txt

Your system

	Distribution    : $description
	Architecture    : $arch
	Your IP         : $IP
	Your hostname   : $HOSTNAME

	Linux username  : $userLinux
	Password        : $pwLinux

To access ruTorrent:
	http(s)://$IP/rutorrent   ID : $userRuto  PW : $pwRuto
	or http(s)://$HOSTNAME/rutorrent
	With https, accept the Self Signed Certificate and
	the exception for this certificate!

`if [[ $installWebMin -eq 0 ]]; then
	echo "To access WebMin:"
	echo -e "\thttps://$IP:10000"
	echo -e "\tor https://$HOSTNAME:10000"
	echo -e "\tID : root  PW : your root password"
	echo -e "\tAccept the Self Signed Certificate and"
	echo -e "\tthe exception for this certificate!"
	echo " "
fi`
In case of issues strictly concerning this script, you can go consult the wiki:
https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki
and post  https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/issues

`if [[ $changePort -eq 0 ]]; then   # ssh sécurisé
	echo "***********************************************"
	echo "|      Warning standard port and root         |"
	echo "|     no longer access to SSH and SFTP        |"
	echo "***********************************************"
	echo
	echo "To access your server in ssh:"
	echo "On Linux console:"
	echo -e "\tssh -p$portSSH  $userLinux@$IP"
	echo "On windows use PuTTY"

	echo "To access files via SFTP:"
	echo -e "\tHost          : $IP (ou $HOSTNAME)"
	echo -e "\tPort          : $portSSH"
	echo -e "\tProtocol      : SFTP-SSH File Transfer Peotocol"
	echo -e "\tAuthentication: normale"
	echo -e "\tLogin         : $userLinux"
	echo -e "\tYour $userLinux password"
else   # ssh n'est pas sécurisé
	echo "To access your server via ssh:"
	echo "On Linux console:"
	echo -e "\tssh root@$IP"
	echo -e "\tOn server console 'su $userLinux'"
	echo "On windows use PuTTY"
	echo " "
	echo "To access files via SFTP:"
	echo -e "\tHost          : $IP (ou $HOSTNAME)"
	echo -e "\tPort          : 22"
	echo -e "\tProtocol      : SFTP-SSH File Transfer Protocol"
	echo -e "\tAuthentication: normal"
	echo -e "\tLogin         : root"
fi  # ssh pas sécurisé/ sécurisé`
EOF

# efface la récap 1ère version
rm $REPUL/RecapInstall.txt
chmod 400 $REPUL/HiwsT/RecapInstall.txt
__textBox "Installation summary" $REPUL/HiwsT/RecapInstall.txt "Information saved in RecapInstall.txt"
__ouinonBox "Installation end" "Use HiwsT-util.sh for all modifications
It may be necessary to reboot for everything work 100%.
Do you want reboot your server now?"
if [ $__ouinonBox -eq 0 ]; then
	__ouinonBox "Installation end" "Reboot :
Are you sure?"
	if [ $__ouinonBox -eq 0 ]; then rm -r $REPLANCE; sleep 1; reboot; fi
fi
clear
echo
echo "Au revoir"  # french touch ;)
echo
rm -r $REPLANCE
