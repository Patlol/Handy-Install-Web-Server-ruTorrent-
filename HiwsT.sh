#!/bin/bash

# Installation apache2, php, rtorrent, rutorrent, WebMin
# testée sur ubuntu et debian server vps Ovh
# et sur kimsufi. A tester sur autres hébergeurs
# https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-


##################################################
#     variables install paquets Ubuntu/Debian
##################################################
#  Debian 8
#  liste sans serveur http
paquetsWebD8="mc nano aptitude autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php5 php5-cli php5-dev php5-fpm php5-curl php5-geoip php5-mcrypt php5-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoD8="xmlrpc-api-utils libtorrent14 rtorrent"

sourceMediaD8="deb http://www.deb-multimedia.org jessie main non-free"
paquetsMediaD8="mediainfo ffmpeg"

#  Debian 9 stretch
# liste sans serveur http - autoconf build-essential comerr-dev libcloog-ppl-dev libcppunit-dev libcurl4-openssl-dev libncurses5-dev libxml2-dev libsigc++-2.0-dev libperl-dev libssl-dev php7.0-dev  manpages-dev
paquetsWebD9="mc nano aptitude ca-certificates curl cfv dtach htop irssi libcurl3 libterm-readline-gnu-perl libtool ncurses-base ncurses-term ntp openssl patch pkg-config php7.0 php7.0-cli php7.0-fpm php7.0-curl php-geoip php7.0-mcrypt php7.0-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev manpages libfile-fcntllock-perl bzip2 xz-utils geoip-database libltdl-dev libxml-sax-expat-perl xml-core unar"

paquetsRtoD9="xmlrpc-api-utils libtorrent19 rtorrent"

# sourceMediaD9="deb http://www.deb-multimedia.org stretch main non-free" sur les repository standards
paquetsMediaD9="mediainfo ffmpeg"

# Ubuntu 16
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
readonly TIMEOUT=30  # __messageBox
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

__trap() {  # pour exit supprime info.php et affiche dernier message d'erreur
  if [ -e $REPWEB/info.php ]; then rm $REPWEB/info.php; fi
  if [ -s /tmp/trace.log ]; then
    echo "/tmp/trace.log:"
    echo
    cat /tmp/trace.log
  fi
}

__ouinonBox() {    # param : titre, texte  sortie $__ouinonBox oui : 0 ou non : 1
  CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --trim --cr-wrap  --yesno "${2}" 0 0 )
  choix=$("${CMD[@]}" 2>&1 >/dev/tty)
  __ouinonBox=$?
}  # fin ouinon

__messageBox() {   # param : titre texte vide=timeout on
  local argTimeOut
  if [[ -z ${3} ]]; then
    argTimeOut="--timeout $TIMEOUT"
  fi
  CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --trim --cr-wrap --scrollbar $argTimeOut --msgbox "${2}" 0 0)
  choix=$("${CMD[@]}" 2>&1 >/dev/tty)
}

__msgErreurBox() {   # param : commande, N° erreur
  local msgErreur; local ref=$(caller 0)
  err=${2}
  msgErreur="------------------\n"
  msgErreur+="Line N°${ref}\n${BO}${R}${1}${N}\nError N° ${R}${err}${N}\n"
  trace=$(cat /tmp/trace)
  msgErreur+="${trace}\n"
  msgErreur+="------------------\n"
  :>/tmp/trace
  __messageBox "${R}Error message${N}" " ${msgErreur}  ${R}
    See the wiki on github ${N}
    https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/something-wrong
    The error message is stored in ${I}/tmp/trace.log${N}" "NOtimeout"
  __ouinonBox "Error" "
    Do you want continue anyway?
    "
  if [[ $__ouinonBox -ne 0 ]]; then exit $err; fi
  echo -e $msgErreur > /tmp/hiwst.log
  sed -i '/------------------/d' /tmp/hiwst.log
  sed -r 's/(\\Zb)|(\\Z1)|(\\Zn)//g' </tmp/hiwst.log >>/tmp/trace.log
  return $err
}  # fin messageErreur

__saisieTexteBox() {   # param : titre, texte
  until false; do
    CMD=(dialog --aspect $RATIO --colors --nocancel --backtitle "$TITRE" --title "${1}" --trim --cr-wrap --max-input 15 --inputbox "${2}" 0 0)
    __saisieTexteBox=$("${CMD[@]}" 2>&1 >/dev/tty)
    if [ $? == 1 ]; then return 1; fi
    if [[ "$__saisieTexteBox" =~ ^[a-zA-Z0-9]{2,15}$ ]]; then
      __saisieTexteBox=$(echo $__saisieTexteBox | tr '[:upper:]' '[:lower:]')
      break
    else
      __messageBox "Entry validation" "
        Only alphanumeric characters
        Between 2 and 15 characters
        "
    fi
  done
}

__saisiePwBox() {  # param : titre, texte, nbr de ligne sous boite
  local pw=1""; local pw2=""; local codeSortie=""; local reponse=""
  until false; do
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --insecure --trim --cr-wrap --nocancel --passwordform "${2}" 0 0 ${3} "Password " 2 4 "" 2 25 25 25 "Retype: " 4 4 "" 4 25 25 25 )
    reponse=$("${CMD[@]}" 2>&1 >/dev/tty)
    if [[ "$reponse" =~ .*[[:space:]].*[[:space:]].* ]] || \
      [[ "$reponse" =~ [\\] ]]; then
      __messageBox "${1}" "
        The password can't contain spaces or \\.
        "
    else
      pw1=$(echo $reponse | awk -F" " '{ print $1 }')
      pw2=$(echo $reponse | awk -F" " '{ print $2 }')
      case $pw1 in
        "" )
          __messageBox "${1}" "
            The password can't be empty.
            "
        ;;
        $pw2 )
          __saisiePwBox=$pw1
          break
        ;;
        * )
          __messageBox "${1}" "
            The 2 inputs are not identical.
            "
        ;;
      esac
    fi
  done
}  #  Fin __saisiePwBox

__textBox() {   # $1 titre  $2 fichier à lire  $3 texte baseline
  CMD=(dialog --backtitle "$TITRE" --exit-label "Continued from installation" --title "${1}" --hline "${3}" --textbox  "${2}" 0 0)
  ("${CMD[@]}" 2>&1 >/dev/tty)
}

__servicerestart() {
  service $1 restart
  codeSortie=$?
  cmd="service $1 status"; $cmd || __msgErreurBox "$cmd" $?
  return $codeSortie
}  #  fin __servicerestart


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
lang=$(cat /etc/locale.gen | egrep ^[a-z].*UTF-8$ | awk -F" " '{ print $1 }')
lang=$(echo $lang | awk -F" " '{ print $1 }')  # debian 9
export LANGUAGE=$lang
export LANG=$lang
export LC_ALL=$lang
update-locale LANGUAGE=$lang
update-locale LANG=$lang
update-locale LC_ALL=$lang
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

if [[ $nameDistrib == "Debian" && $os_version_M -gt 9 ]] || [[ $nameDistrib == "Ubuntu" && $os_version_M -gt 16 ]]; then
  __ouinonBox "Distribution check" "
    You are using $description
    This script is intended to run on a Debian server
    8.xx/9.xx or Ubuntu 16.xx
    You risk having version issues at installation
    Do you want to continue?"
  if [[ $__ouinonBox -ne 0 ]]; then  clear; exit 1; fi
fi

if [[ $nameDistrib == "Debian" && $os_version_M -lt 8 ]] || [[ $nameDistrib == "Ubuntu" && $os_version_M -lt 16 ]]; then
  __messageBox "Distribution check" "
    You are using $description
    This script is intended to run on a Debian server
    8.xx/9.xx ou Ubuntu 16.xx"
  clear; exit 1
fi

if [[ $nameDistrib != "Debian" && $nameDistrib != "Ubuntu" ]]; then
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
#--------------------------------------------------------------

#############################
#    Partie interactive
#    ID, PW, questions
#############################

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
  if [ $rootDispo -lt $miniDispoRoot ]; then
    __messageBox "Important message" "
      ${BO}${R}
      WARNING ${N}

      Only ${R}$(( $rootDispo/1024/1024 )) Go${N}, on / to store downloaded files"
  fi
else  # /home
  if [ $homeDispo -lt $miniDispoHome ];then
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
  userLinux=$__saisieTexteBox
  egrep "^$userLinux:" /etc/passwd >/dev/null
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
  userRuto=$__saisieTexteBox
  egrep "^$userRuto:" /etc/passwd >/dev/null
  usernameOk=$?
  if [[ $usernameOk -eq 0 ]] && [[ $userRuto != $userLinux ]]; then
    __messageBox "ruTorrent user" "
      $userRuto already exists, choose another username
      "
  fi
done
__saisiePwBox "ruTorrent user" "
  Password for $userRuto:" 4
pwRuto=$__saisiePwBox

#  webmin
__ouinonBox "Webmin" "
  Would you like to install Webmin?
  "
installWebMin=$__ouinonBox

# port ssh
__ouinonBox "Secure ssh/sftp" "
  In order to secure SSH and SFTP it's proposed to change the standard port (22)
  and to prohibit root.
  $R
  This is a highly recommended safety measure.$N

  The user will be $userLinux and the random port $portSSH${BO} or a port designated by you.$N
  Would you like to apply this change?"
changePort=$__ouinonBox
if [ $changePort -eq 0 ]; then
  choix=0
  until [[ $choix -le $ECHELLE && $choix -ge $PLANCHER ]] || [[ $choix -eq 22 ]]; do
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "ssh/sftp port" --trim --cr-wrap --max-input 5 --nocancel --inputbox "
      The proposed random port is $I$portSSH${N}${BO}
      You can change it between $PLANCHER and $ECHELLE$N
      Or the default port 22. The ssh user is $userLinux" 0 0 $portSSH)
    choix=$("${CMD[@]}" 2>&1 >/dev/tty)
  done
  portSSH=$choix
  userSSH=$userLinux
else
  portSSH=22
  userSSH="root"
fi


#  Récapitulatif
cat << EOF > $REPLANCE/RecapInstall.txt

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

At the end of the installation:

Your http server will be $serveurHttp

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

__textBox "Installation Summary" $REPLANCE/RecapInstall.txt
__ouinonBox "Installation" "
Do you want start installation?
"
if [ $__ouinonBox -ne 0 ]; then exit 0; fi


############################################
#            Début de la fin
############################################

clear
## gestion des erreurs stderr par __msgErreurBox()
:>/tmp/trace # fichier d'erreur temporaire
:>/tmp/trace.log  # messages d'erreur
:>/tmp/hiwst.log  # fichier temporaire msg pour __msgErreurBox
exec 3>&2 2>/tmp/trace
trap "__trap" EXIT # supprime info.php et affiche le dernier message d'erreur
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
cmd="apt-get upgrade -yq"; $cmd ||  __msgErreurBox "$cmd" $?
echo "***********************"
echo "|  Update completed   |"
echo "***********************"
sleep 1

##############################
#  Création de linux user    #
##############################
. $REPLANCE/insert/install_linuxuser.sh

############################################
#      Installation du serveur http        #
############################################
service nginx stop &> /dev/null
. $REPLANCE/insert/install_apache.sh

############################################
#           installation rtorrent          #
############################################
. $REPLANCE/insert/install_rtorrent.sh

############################################
#        installation de rutorrent         #
############################################
. $REPLANCE/insert/install_rutorrent.sh

#######################################################
#             installation de WebMin                  #
#######################################################
if [[ $installWebMin -eq 0 ]]; then
  . $REPLANCE/insert/install_webmin.sh
fi

########################################
#            sécuriser ssh             #
########################################
#  des choses à faire de tte façon
. $REPLANCE/insert/install_ssh.sh

####################################
#     Nettoyage, finalisation      #
####################################

## copie les scripts dans home
cp -r  $REPLANCE $REPUL/HiwsT
chown -R $userLinux:$userLinux $REPUL/HiwsT

## complète firstusers
echo $userRuto >> $REPUL/HiwsT/firstusers
chown root:root $REPUL/HiwsT/firstusers
chmod 400 $REPUL/HiwsT/firstusers  # r-- --- ---

## copie dans $REPUL/HiwsT le fichiers log d'erreurs
cp -t $REPUL/HiwsT /tmp/trace.log
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
  echo -e "\tHost          : $IP (or $HOSTNAME)"
  echo -e "\tPort          : 22"
  echo -e "\tProtocol      : SFTP-SSH File Transfer Protocol"
  echo -e "\tAuthentication: normal"
  echo -e "\tLogin         : root"
fi  # ssh pas sécurisé/ sécurisé`
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
echo "Au revoir"  # french touch ;)
echo
exit 0
