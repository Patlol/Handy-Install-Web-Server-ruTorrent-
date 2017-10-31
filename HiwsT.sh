#!/bin/bash

# Installation apache2, php, rtorrent, rutorrent
# testée sur ubuntu et debian server vps Ovh
# et sur kimsufi. A tester sur autres hébergeurs
# https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-


############################################################
##        variables install paquets Ubuntu/Debian
############################################################
#  Debian 8
#  liste sans serveur http
paquetsWebD8="git mc nano aptitude autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php5 php5-cli php5-dev php5-fpm php5-curl php5-geoip php5-mcrypt php5-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoD8="xmlrpc-api-utils libtorrent14 rtorrent"

sourceMediaD8="deb http://www.deb-multimedia.org jessie main non-free"
paquetsMediaD8="mediainfo ffmpeg"

#  Debian 9 stretch
# liste sans serveur http - autoconf build-essential comerr-dev libcloog-ppl-dev libcppunit-dev libcurl4-openssl-dev libncurses5-dev libxml2-dev libsigc++-2.0-dev libperl-dev libssl-dev php7.0-dev  manpages-dev
paquetsWebD9="git mc nano aptitude ca-certificates curl cfv dtach htop irssi libcurl3 libterm-readline-gnu-perl libtool ncurses-base ncurses-term ntp openssl patch pkg-config php7.0 php7.0-cli php7.0-fpm php7.0-curl php-geoip php7.0-mcrypt php7.0-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev manpages libfile-fcntllock-perl bzip2 xz-utils geoip-database libltdl-dev libxml-sax-expat-perl xml-core unar"

paquetsRtoD9="xmlrpc-api-utils libtorrent19 rtorrent"

# sourceMediaD9="deb http://www.deb-multimedia.org stretch main non-free" sur les repository standards
paquetsMediaD9="mediainfo ffmpeg"

# Ubuntu 16
# liste sans serveur http
paquetsWebU="git mc nano aptitude autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php7.0 php7.0-cli php7.0-dev php7.0-fpm php7.0-curl php-geoip php7.0-mcrypt php7.0-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoU="xmlrpc-api-utils libtorrent19 rtorrent"

paquetsMediaU="mediainfo ffmpeg"

############################################################
readonly HOSTNAME=$(hostname -f)
readonly REPWEB="/var/www/html"
readonly REPAPA2="/etc/apache2"
readonly REPLANCE=$(pwd)
REPUL=""    # repertoire user Linux dans __creauser
readonly PORT_SCGI=5000  # port 1er Utilisateur
readonly PLANCHER=20001  # bas fourchette port ssh
readonly ECHELLE=65534  # ht de la fourchette
readonly miniDispoRoot=334495744   # 319 Go minimum pour alerete place \
readonly miniDispoHome=313524224   # 299 Go disponible sur disque
readonly serveurHttp="apache2"
# dialog param --backtitle --aspect --colors
TITRE="HiwsT : Installation rtorrent - ruTorrent"
TIMEOUT=30  # __messageBox
RATIO=12


############################################################
##                Fonctions utilitaires
############################################################

. $REPLANCE/insert/helper-dialog.sh
. $REPLANCE/insert/helper-scripts.sh


############################################################
##                   Début du script
############################################################

# root ?
if [[ $(id -u) -ne 0 ]]; then
  echo
  echoc r "This script needs to be run with sudo."
  echo
  exit 1
fi
clear

############################################################
##            localisation et infos système
############################################################

# Complèter la localisation (vps)
lang=$(grep -E "^[a-z].*UTF-8$" /etc/locale.gen | awk -F" " '{ print $1 }')
lang=$(echo "$lang" | awk -F" " '{ print $1 }')  # debian 9
export LANGUAGE="$lang"
export LANG="$lang"
export LC_ALL="$lang"
update-locale LANGUAGE="$lang"
update-locale LANG="$lang"
update-locale LC_ALL="$lang"
dpkg-reconfigure --frontend=noninteractive locales
locale-gen

apt-get update

# installe dialog si pas installé
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
readonly IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
nameDistrib=$(lsb_release -si)  # Debian ou Ubuntu
os_version=$(lsb_release -sr)   # 18 , 8.041 ...
os_version_M=$(echo "$os_version" | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')  # version majeur
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
if [[ "$nameDistrib" == "Debian" && "$os_version_M" -gt 9 ]] || [[ "$nameDistrib" == "Ubuntu" && "$os_version_M" -gt 16 ]]; then
  __ouinonBox "Distribution check" "
    You are using $description
    This script is intended to run on a Debian server
    8.xx/9.xx or Ubuntu 16.xx
    You risk having version issues at installation
    Do you want to continue?"
  if [[ $__ouinonBox -ne 0 ]]; then  clear; exit 1; fi
fi

if [[ "$nameDistrib" == "Debian" && "$os_version_M" -lt 8 ]] || [[ "$nameDistrib" == "Ubuntu" && "$os_version_M" -lt 16 ]]; then
  __messageBox "Distribution check" "
    You are using $description
    This script is intended to run on a Debian server
    8.xx/9.xx ou Ubuntu 16.xx"
  clear; exit 1
fi

if [[ "$nameDistrib" != "Debian" && "$nameDistrib" != "Ubuntu" ]]; then
  __messageBox "Distribution check" "
    You are using $description
    This script is intended to run on a Debian server
    8.xx/9.xx ou Ubuntu 16.xx"
  clear; exit 1
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
    You have apache2${BO} and${N} nginx installed!?
    If you continue this script, the existing configuration
    will be replaced by the script configuration (apache2)"
  if [[ $__ouinonBox -eq 1 ]]; then clear; exit 1; fi
elif [[ $serveurHttpA -eq 0 ]]; then
  __ouinonBox "Http server" "
    You have apache2 installed,
    If you continue this script, the existing configuration
    will be replaced by the script configuration"
  if [[ $__ouinonBox -eq 1 ]]; then clear; exit 1; fi
elif [[ $serveurHttpN -eq 0 ]]; then
  __ouinonBox "Http server" "
    You have nginx installed,
    If you continue this script, the existing configuration
    will be replaced by the script configuration (apache2)"
  if [[ $__ouinonBox -eq 1 ]]; then clear; exit 1; fi
fi


############################################################
##                    Partie interactive
##                    ID, PW, questions
############################################################

__messageBox "${R}Important message${N}" "

  ${I}WARNING !!!${N}

  The use of this script must be done on a fresh server
  as delivered by your host.

  ${R}Any installation may be damaged by this script!!!
  Never run this script on a server in production."

__messageBox "Your system" " ${BO}

  Distribution : ${N}$description ${BO}
  Architecture : ${N}$arch ${BO}
  Your IP      : ${N}$IP ${BO}
  The script runs under: ${N}$user
  ${BO}
  Execution duration: ${N}about 8mn

  Amount of disk space available${BO}
  Your root partition (/) has $(( $rootDispo/1024/1024 )) Go free.
  $info"  # $info valeur suivant $homeDispo cf. # espace dispo

if [ -z "$homeDispo" ]; then  # /
  if [ "$rootDispo" -lt $miniDispoRoot ]; then
    __messageBox "Important message" "
      ${BO}${R}
      WARNING ${N}

      Only ${R}$(( $rootDispo/1024/1024 )) Go${N}, on / to store downloaded files"
  fi
else  # /home
  if [ "$homeDispo" -lt $miniDispoHome ];then
    __messageBox "Important message" "
      ${BO}$R
      WARNING $N

      Only ${R}$(( $homeDispo/1024/1024 )) Go${N}, on /home to store downloaded files"
  fi
fi

# utilisateur linux
usernameOk=0
until [[ $usernameOk -ne 0 ]]; do
  __saisieTexteBox "Linux user" "
    You must create a specific user.
    Choose a linux username${R}
    (neither space nor \)${N}: "
  userLinux="$__saisieTexteBox"
  grep -E "^$userLinux:" /etc/passwd >/dev/null
  usernameOk=$?
  if [[ $usernameOk -eq 0 ]]; then
    __messageBox "Linux user" "
      $userLinux already exists,
      choose another username
      "
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
    Choose a ruTorrent username${R} (neither space nor \)$N: "
  userRuto="$__saisieTexteBox"
  grep -E "^$userRuto:" /etc/passwd >/dev/null
  usernameOk=$?
  if [[ $usernameOk -eq 0 ]] && [[ "$userRuto" != "$userLinux" ]]; then
    __messageBox "ruTorrent user" "
      $userRuto already exists, choose another username
      "
  fi
done
__saisiePwBox "ruTorrent user" "
  Password for $userRuto:" 4
pwRuto="$__saisiePwBox"

# port ssh
__ouinonBox "Secure ssh/sftp" "
  In order to secure SSH and SFTP it's proposed to change the standard port (22)
  and to prohibit root.
  ${R}
  This is a highly recommended safety measure.${N}

  The user will be $userLinux and the random port $portSSH${BO} or a port designated by you.$N
  Would you like to apply this change?"
changePort=$__ouinonBox
if [ $changePort -eq 0 ]; then
  choix=0
  until [[ $choix -le $ECHELLE && $choix -ge $PLANCHER ]] || [[ $choix -eq 22 ]]; do
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "ssh/sftp port" --trim --cr-wrap --max-input 5 --nocancel --inputbox "
      The proposed random port is ${I}$portSSH${N}${BO}
      You can change it between $PLANCHER and $ECHELLE$N
      Or the default port 22. The ssh user is $userLinux" 0 0 $portSSH)
    choix=$("${CMD[@]}" 2>&1 > /dev/tty)
  done
  portSSH=$choix
  userSSH="$userLinux"
else
  portSSH=22
  userSSH="root"
fi


#  Récapitulatif
cat << EOF > ${REPLANCE}/RecapInstall.txt

This information will be used only after the script has been executed correctly.

Distribution    : $description
Architecture    : $arch
Your IP         : $IP
Your hostname   : $HOSTNAME

$(if [ -z "$homeDispo" ]
then
  echo "You haven't /home partition."
else
  echo "Your /home partition has $(( $homeDispo/1024/1024 )) Go free."
fi)
Your root (/) partition has $(( $rootDispo/1024/1024 )) Go free.

At the end of the installation:

Your http server will be $serveurHttp

Name of user with SSH and SFTP access: $userSSH
SSh port: $portSSH

Linux username:           $userLinux
Password Linux user:      $pwLinux

ruTorrent username:       $userRuto
Password ruTorrent user:  $pwRuto
EOF

__textBox "Installation Summary" "$REPLANCE/RecapInstall.txt"
__ouinonBox "Installation" "
Do you want start installation?
"
if [ $__ouinonBox -ne 0 ]; then exit 0; fi


############################################################
##                    Début de la fin
############################################################

clear
## gestion des erreurs stderr par __msgErreurBox()
:>/tmp/trace # fichier d'erreur temporaire
:>/tmp/trace.log  # messages d'erreur
exec 3>&2 2>/tmp/trace
trap "__trap" EXIT # supprime info.php et affiche le dernier message d'erreur

echoc v "                              "
echoc b "         Installation         "
echoc v "                              "
echoc b "         Update System        "
echoc b "   User Linux configuration   "
echoc b "     Packages installation    "
echoc v "                              "
echo

# upgrade
cmd="apt-get upgrade -yq"; $cmd || __msgErreurBox "$cmd" $?
echoc v "                              "
echoc v "      Update completed        "
echoc v "                              "
sleep 1

############################################################
##                Création de linux user

. ${REPLANCE}/insert/install_linuxuser.sh

############################################################
##              Installation du serveur http

. ${REPLANCE}/insert/install_apache.sh

############################################################
##              installation rtorrent

. ${REPLANCE}/insert/install_rtorrent.sh

############################################################
##              installation de rutorrent

. ${REPLANCE}/insert/install_rutorrent.sh

############################################################
##                   sécuriser ssh
##           des choses à faire de tte façon
. ${REPLANCE}/insert/install_ssh.sh

############################################################
##            Nettoyage, finalisation

## copie les scripts dans home
cp -r  ${REPLANCE} $REPUL/HiwsT
chown -R $userLinux:$userLinux $REPUL/HiwsT

## complète firstusers
echo $userRuto >> $REPUL/HiwsT/firstusers
chown root:root $REPUL/HiwsT/firstusers
chmod 400 $REPUL/HiwsT/firstusers  # r-- --- ---

## copie dans $REPUL/HiwsT le fichiers log d'erreurs
cp -t $REPUL/HiwsT /tmp/trace.log
rm -r ${REPLANCE}


############################################################
##                  générique de fin
############################################################

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
  If you not again use Let's Encrypt, with https, accept
  the Self Signed Certificate and the exception
  for this certificate!

In case of issues strictly concerning this script, you can consult the wiki:
https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki
and post  https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/issues

$(if [[ $changePort -eq 0 ]]; then   # ssh sécurisé
  echo "***********************************************"
  echo "|      Warning standard port and root         |"
  echo "|     no longer access to SSH and SFTP        |"
  echo "***********************************************"
  echo
  echo "To access your server in ssh:"
  echo "On Linux terminal:"
  echo -e "\tssh -p$portSSH  $userLinux@$IP"
  echo "On windows use PuTTY"
  echo " "
  echo "To access files via SFTP:"
  echo -e "\tHost          : $IP (or $HOSTNAME)"
  echo -e "\tPort          : $portSSH"
  echo -e "\tProtocol      : SFTP-SSH File Transfer Peotocol"
  echo -e "\tAuthentication: normal"
  echo -e "\tLogin         : $userLinux"
  echo -e "\tYour $userLinux password"
else   # ssh n'est pas sécurisé
  echo "To access your server via ssh:"
  echo "On Linux terminal:"
  echo -e "\tssh root@$IP"
  echo -e "\tOn server console 'su $userLinux'"
  echo "On windows use PuTTY"
  echo " "
  echo "To access files via SFTP:"
  echo -e "\tHost          : $IP (or $HOSTNAME)"
  echo -e "\tPort          : 22"
  echo -e "\tProtocol      : SFTP-SSH File Transfer Protocol"
  echo -e "\tAuthentication: normal"
  echo -e "\tLogin         : root"
fi  # ssh pas sécurisé/ sécurisé)
EOF

# écrase la récap 1ère version et le répertoire de scripts dans root
chmod 400 $REPUL/HiwsT/RecapInstall.txt
__textBox "Installation summary" $REPUL/HiwsT/RecapInstall.txt "Information saved in RecapInstall.txt"
__ouinonBox "Installation end" "
  Use HiwsT-util.sh for all modifications
  It may be necessary to reboot for
  everything work 100%.
  Do you want reboot your server now?"
if [ $__ouinonBox -eq 0 ]; then
  __ouinonBox "Installation end" " Reboot :
    Are you sure?"
  if [ $__ouinonBox -eq 0 ]; then sleep 1; reboot; fi
fi

clear
echo
echoc b "   Au revoir   "  # french touch ;)
echo
exit 0
