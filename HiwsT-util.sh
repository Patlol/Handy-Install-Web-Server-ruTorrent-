#!/bin/bash


# Enemble of utilities for linux, rutorrent, owncloud.
# Installation of openvpn, ownCloud, webmin, phpmyadmin, let's encrypt
# Users management: Adding or deleting users, changing password.
# Firewall. Server system's status
#
# Tested on ubuntu and debian server vps Ovh and on kimsufi.
# To be tested on other hosting providers
# https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-

readonly REPWEB="/var/www/html"
readonly REPAPA2="/etc/apache2"
readonly REPLANCE=$(pwd)
readonly ocpath='/var/www/owncloud' # pour letsencrypt, owncloud, up-owncloud et crea-owncloud-user
readonly DbNameOC="owncloud"
# pas readonly pour IP car modifié dans openvpninstall
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
readonly HOSTNAME=$(hostname -f)
# Tableau des utilisateurs principaux 0=linux, 1=rutorrent, owncloud dans oc db
if [[ ! -e $REPLANCE/firstusers ]]; then
  echo; echo "The file \"firstusers\" is not available"
  echo "You must use Hiwst.sh before using this script"; echo
  exit 2
fi

i=0
while read user; do  # [0]=linux, [1]=ruTorrent
  FIRSTUSER[$i]=$user
  (( i++ ))
done < $REPLANCE/firstusers
declare -ar FIRSTUSER  # -r readonly
readonly REPUL="/home/${FIRSTUSER[0]}"
readonly userLinux="${FIRSTUSER[0]}"
# dialog param --backtitle --aspect --colors
TITRE="Utilitaire HiwsT : rtorrent - ruTorrent - openVPN - ownCloud"
TIMEOUT=30  # __messageBox
RATIO=12

############################################################
##                Fonctions utilitaires
############################################################

. $REPLANCE/insert/helper-dialog.sh
. $REPLANCE/insert/helper-scripts.sh
. $REPLANCE/insert/util_apache.sh
. $REPLANCE/insert/util_listeusers.sh
. $REPLANCE/insert/util_diag.sh
. $REPLANCE/insert/util_firewall.sh
. $REPLANCE/insert/util_supp-rutorrent-user.sh
. $REPLANCE/insert/util_crea-rutorrent-user.sh
. $REPLANCE/insert/util_phpmyadmin.sh
. $REPLANCE/insert/util_vpn.sh


############################################################
##           Fonctions principales ss menus
############################################################

############################################################
##      ajout utilisateur sous menu et traitements
############################################################
__ssmenuAjoutUtilisateur() {
local typeUser=""; local codeSortie=1

until false; do
  # Create a user:" 22 70 4 \
  CMD=(dialog --backtitle "$TITRE" --title "Add a user" --trim --cr-wrap --cancel-label "Exit" --menu "

    A ruTorrent user can only be created with a Linux user

    Create a user:" 18 65 3 \
    1 "Linux + ruTorrent" \
    2 "OwnCloud" \
    3 "Users list")

  typeUser=$("${CMD[@]}" 2>&1 > /dev/tty)
  if [[ $? -eq 0 ]]; then  # pas cancel
    if [[ $typeUser -ne 3 ]]; then  # 3 = users list
      __saisieTexteBox "Creating user" "
        Input the name of new user${R}
        Neither space nor special characters${N}" h
      if [[ $? -eq 1 ]]; then   # 1 si bouton cancel
        typeUser=""
      fi
    fi
    case $typeUser in
      1 )  #  créa linux ruto
        __userExist "$__saisieTexteBox"    # insert/util_apache.sh renvoie userL userR 0 = existe
        if [[ $userL -eq 0 ]] || [[ $userR -eq 0 ]]; then
          __messageBox "Creating Linux/ruTorrent user" "
            The $__saisieTexteBox user already exists
            "
        else
          __ouinonBox "Creating Linux/ruTorrent user" " - The new user will have SFTP access with his/her name and password,
            same port as all users.
            - His/her access is limited at /home directory.
            - No access to ssh$R
            Confirm $__saisieTexteBox as new user?"
          if [[ $__ouinonBox -eq 0 ]]; then
            __saisiePwBox "User $__saisieTexteBox setting-up" "
              Input user password" 0 0
            clear;
            cmd="__creaUserRuto $__saisieTexteBox $__saisiePwBox"; $cmd || __msgErreurBox "$cmd" $?
            __messageBox "Creating Linux/ruTorrent user" " Setting-up completed
              $__saisieTexteBox user created
              Password $__saisiePwBox"
          fi
        fi
      ;;
      2 )  # créa owncloud user "a-z", "A-Z", "0-9", "_@-" et "." (le point)
        pathOCC=$(find /var -name occ 2>/dev/null)
        if [[ -n $pathOCC ]]; then  # owncloud installé
          if [[ ! "$__saisieTexteBox" =~ ^[[:alnum:]_@\.-]{1,}$ ]]; then
            __messageBox "Creating ownCloud user" "
            It's the UID, you can use only
            \"a-z\", \"A-Z\", \"0-9\", \"_@-\" et \".\" (point)"
            continue
          fi
          __listeUtilisateursOC   ## in util_listusers.sh liste users existants
          if [[ $(echo "$__listeUtilisateursOC" | grep -w "$__saisieTexteBox") ]]; then
            # l'utilisateur existe
            __messageBox "Creating ownCloud user" "
              The $__saisieTexteBox user \Z1already exists\Zn
              "
          else
            . $REPLANCE/insert/util_crea-owncloud-user.sh
          fi
        else # ownCloud pas installé
          __messageBox "Creating ownCloud user" "
            Owncloud is not installing!"
        fi
      ;;
      3 )
        cmd="__listeUtilisateurs"; $cmd || __msgErreurBox "$cmd" $?
      ;;
    esac
  else  # === si sortie du menu $? -ne 0 = bouton cancel
    break
  fi
done
}   #  fin __ssmenuAjoutUtilisateur()


############################################################
##    supprimer utilisateur sous menu et traitements
############################################################

__ssmenuSuppUtilisateur() {
  local typeUser=""; local codeSortie=1

  until false; do
    # Delete a user:" 22 70 4 \
    CMD=(dialog --backtitle "$TITRE" --title "Delete a user" --trim --cr-wrap --cancel-label "Exit" --menu "
      What user kind do you want to remove?

      - If a ruTorrent user is deleted, his Linux namesake
      will also be deleted.

      Delete a user:" 18 65 2 \
      1 "Linux + ruTorrent" \
      2 "Users list")

    typeUser=$("${CMD[@]}" 2>&1 > /dev/tty)
    if [[ $? -eq 0 ]]; then
      # filtrer le choix 2 : liste user
      if [[ $typeUser -ne 2 ]]; then
        __saisieTexteBox "Delete a user" "
          Input a user name:" h
        if [[ $? -eq 1 ]]; then  # 1 si bouton cancel
          typeUser=""
        else
          __userExist "$__saisieTexteBox"  # insert/util_apache.sh renvoie userL userR
        fi
      fi
      # $type $userL R $__saisieTexteBox
      case $typeUser in
        1)  #   suppression utilisateur Linux/ruto ----------------
          __ouinonBox "Delete a Linux user" " Warning the user's /home directory
            will be deleted. You confirm removing $__saisieTexteBox?
            "
          if [[ $__ouinonBox -eq 0 ]]; then
            if [[ $userR -eq 0 ]] && [[ $userL -eq 0 ]] && [ "${FIRSTUSER[0]}" != "$__saisieTexteBox" ]; then
              cmd="__suppUserRuto $__saisieTexteBox"; $cmd || __msgErreurBox "$cmd" $?
              __messageBox "Delete a Linux user" " Treatment completed
                Linux/ruTorrent user ${R}$__saisieTexteBox${N} deleted
                "
            else
              __messageBox "Delete a Linux/ruTorrent user" "
                $__saisieTexteBox${R} is not a Linux/ruTorrent user or$N
                $__saisieTexteBox${R} is the main user"
              #sortie case $typeUser et if  retour ss menu
            fi
          fi
        ;;
        2)
          cmd="__listeUtilisateurs"; $cmd || __msgErreurBox "$cmd" $?
        ;;
      esac
    else
      break
    fi
  done
}


############################################################
##          Changement pw Menu + traitement
############################################################

__changePW() {
  local typeUser=""; local user=""; local codeSortie=1

  until false; do
    CMD=(dialog --backtitle "$TITRE" --title "Change User Password" --trim --cr-wrap --cancel-label "Exit" --menu "


      What user kind do you want change?
      " 18 65 3 \
      1 "Linux" \
      2 "ruTorrent" \
      3 "users list")
    typeUser=$("${CMD[@]}"  2>&1 > /dev/tty)
    if [[ $? -eq 0 ]]; then
      case $typeUser in
        1 )   ###  utilisateur Linux
          __saisieTexteBox "Change Password" "
            Input a Linux user name
            Linux password also valid for sftp!!!" h
          if [[ $? -eq 0 ]]; then  # 1 si bouton cancel
            # user linux
            clear
            grep -E "^$__saisieTexteBox:" /etc/passwd > /dev/null 2>&1
            if [[ $? -eq 0 ]]; then
              __saisiePwBox "Change Password Linux" "$__saisieTexteBox user" 4
              echo "$__saisieTexteBox:$__saisiePwBox" | chpasswd
              if [[ $? -ne 0 ]]; then
                __messageBox "Change Linux password" "
                An error occurred, password unchanged.
                "
              else
                __messageBox "Change Linux password" " User password $__saisieTexteBox changed
                  Treatment completed
                  "
              fi
            else
              __messageBox "Change Password" "
              $__saisieTexteBox is not a Linux user
              "
            fi
          fi
        ;;
        [2] )   ###  utilisateur ruTorrent
          __saisieTexteBox "Change Password" "
            Input a ruTorrent user name" h
          if [[ $? -eq 0 ]]; then
            # user ruTorrent ?
            __userExist "$__saisieTexteBox"  # insert/util_apache.sh
            if [[ $userR -eq 0 ]]; then  # $userR sortie de __userExist 0 ou erreur
              __saisiePwBox "Change Password ruTorrent" "$__saisieTexteBox user" 4
              clear
              __changePWRuto "$__saisieTexteBox" "$__saisiePwBox"  # insert/util_apache.sh, renvoie $?
              if [[ $? -ne 0 ]]; then
                __messageBox "Change ruTorrent Password" "
                An error occurred, password unchanged.
                "
              else
                __messageBox "Change ruTorrent Password" " User password $__saisieTexteBox changed
                  Treatment completed
                  "
              fi
            else
              __messageBox "Change Password" "
              $__saisieTexteBox is not a ruTorrent user
              "
            fi
          fi
        ;;
        [3] )
          cmd="__listeUtilisateurs"; $cmd || __msgErreurBox "$cmd" $?
        ;;
      esac
    else
      break
    fi
  done
} # fin __changePW


############################################################
##                   Menu principal
############################################################

__menu() {
  local choixMenu=""; local item=1
  until false; do
    # /!\ 9) doit être firewall (retour test openvpn avec $item) et openvpn 7) item=x
    # --menu text height width menu-height
    CMD=(dialog --backtitle "$TITRE" --title "Main menu" --trim --cr-wrap --cancel-label "Exit" --default-item "$item" --menu "
      To be used after installation with HiwsT

      Your choice:" 24 70 14 \
      1 "Create a user Linux, ruTorrent, ownCloud" \
      2 "Change user password" \
      3 "Delete a user" \
      4 "List existing users" \
      5 "Install rtorrent/ruTorrent" \
      6 "Install webMin" \
      7 "Install/uninstall OpenVPN, a openVPN user" \
      8 "Install/update ownCloud" \
      9 "Firewall" \
      10 "Add domain name & Install free cert Let's Encrypt" \
      11 "Install phpMyAdmin" \
      12 "Restart rtorrent manually" \
      13 "Diagnostic" \
      14 "Reboot the server")
    choixMenu=$("${CMD[@]}" 2>&1 > /dev/tty)

    if [[ $? -eq 0 ]]; then
      case $choixMenu in
        1 )  ######  ajouter user  #########################
          __ssmenuAjoutUtilisateur
        ;;
        2 )  ######  modifier pw utilisateur  ##############
          cmd="__changePW"; $cmd || __msgErreurBox "$cmd" $?
        ;;
        3 )  ###### supprimer utilisateur  #################
          cmd="__ssmenuSuppUtilisateur"; $cmd || __msgErreurBox "$cmd" $?
        ;;
        4 )  ######liste utilisateurs ######################
          cmd="__listeUtilisateurs"; $cmd || __msgErreurBox "$cmd" $?
        ;;
        5 )  ######  rtorrent & ruTorrent
            if [[ -d /var/www/html/rutorrent ]]; then
              __messageBox "Install rTorrent & ruTorrent" "
                rTorrent and ruTorrent are already installed."
              continue
            fi
            . $REPLANCE/insert/util_rtorrent.sh
            . $REPLANCE/insert/util_rutorrent.sh
        ;;
        6 )  ######  WebMin   ##############################
          if [[ -d /var/webmin ]]; then
            __messageBox "Install webMin" "
              webMin is already installed."
            continue
          fi
          . ${REPLANCE}/insert/util_webmin.sh
        ;;
        7 )  ######  VPN   #################################
          # si firewall off et vpn pas installé
          if [[ ! $(iptables -L -n | grep -E 'REJECT|DROP') ]]  && [[ ! -e /etc/openvpn/server.conf ]]; then
            __ouinonBox "Install openVPN" "${R}${BO} Turn ON the firewall BEFORE
              installing the VPN !!!${N}
              "
            if [[ $__ouinonBox -eq 0 ]]; then
              item=9  # menu => Firewall
              continue
            else
              continue
            fi
          fi
          __vpn
          item=1  # menu => Create a user
        ;;
        8 )  ######  ownCloud ##############################
          # owncloud installé ?
          pathOCC=$(find /var -name occ 2>/dev/null)
          if [[ -n "$pathOCC" ]]; then
            __ouinonBox "Install/update ownCloud" "
              ownCloud is already installed.
              Do you want update it?
              "
            if [[ $__ouinonBox -ne 0 ]]; then
              continue  # sortie vers le main menu
            else
              . ${REPLANCE}/insert/util_up-owncloud.sh
              continue  # sortie vers le main menu
            fi
          fi  # fin si déjà installé
          . ${REPLANCE}/insert/util_owncloud.sh
        ;;
        9 )  ######  firewall  #############################
          . ${REPLANCE}/insert/util_firewall.sh
          cmd="__firewall"; $cmd || __msgErreurBox "$cmd" $?
          # menu : si on vient de openvpn on y retourne
          if [[ $item -eq 8 ]]; then item=7; fi # => goto vpn
        ;;
        10 )  ######  domain & letsencrypt ##################
          which certbot 2>&1 > /dev/null
          if [ $? -eq 0 ]; then
            __messageBox "Domain & Let's Encrypt" "
              Let's Encrypt Certificates is already installed
              "
            continue
          fi
          . ${REPLANCE}/insert/util_letsencrypt.sh
        ;;
        11 )  ######  phpMyAdmin  ###########################
          pathPhpMyAdmin=$(find /var/lib/apache2/conf/enabled_by_maint -name phpmyadmin)
          if [[ -n "$pathPhpMyAdmin" ]]; then
            __messageBox "Install phpMyAdmin" "
              phpMyAdmin is already installed
              "
            continue
          fi
          __phpmyadmin
        ;;
        12 )  ######  Relance rtorrent  ####################
          __messageBox "Message" "
            Restart rtorrentd daemon
            " 10 35
          clear
          __servicerestart "rtorrentd"
          if [[ $? -eq 0 ]]; then
            service rtorrentd status
            sleep 4
          fi
        ;;
        13 )  ######  Diagnostiques ########################
          __diag
        ;;
        14 )  ######  REBOOT  ##############################
          __ouinonBox "${R}${BO}Server Reboot${N}"
          if [[ $__ouinonBox -eq 0 ]]; then
            clear
            sleep 2
            reboot
          fi
        ;;
      esac  # $choixMenu
    else  # Bouton exit de main menu
      break
    fi  # Bouton ok/exit
  done  # Boucle infinie menu

}  # fin menu


############################################################
##                    Début du script
############################################################

# root ?
if [[ $(id -u) -ne 0 ]]; then
  echo
  echo "This script needs to be run with sudo."
  echo
  echo "id : $(id)"
  echo
  exit 1
fi

############################################################
# apache vs nginx ?
service nginx status > /dev/null 2>&1
sortieN=$?  # 0 actif, 1 erreur == inactif
service apache2 status > /dev/null 2>&1
sortieA=$?
if [[ $sortieN -eq 0 ]] && [[ $sortieA -eq 0 ]]; then
  echo
  echo "Apache2 and nginx are active. Apache2 must be the http server"
  echo -n "To continue [Enter] to stop [Ctrl-c] "
  read
fi
if [[ $sortieN -eq 0 ]] && [[ $sortieA -ne 0 ]]; then
  echo
  echo "You have a nginx configuration. But this script uses apache2"
  echo
  exit 1
fi
if [[ $sortieN -ne 0 ]] && [[ $sortieA -ne 0 ]]; then
  echo
  echo "Neither apache nor nginx are active"
  echo
  exit 1
fi
SERVEURHTTP="Apache2"

#  debian ou ubuntu et version  pour ownCloud et diag
nameDistrib=$(lsb_release -si)  # "Debian" ou "Ubuntu"
os_version=$(lsb_release -sr)   # 18 , 8.041 ...
os_version_M=$(echo "$os_version" | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')  # version majeur 18, 8 ...
if [[ "$nameDistrib" == "Ubuntu" ]] || [[ "$nameDistrib" == "Debian" && $os_version_M -eq 9 ]]; then
  readonly PHPVER="php7.0-fpm"
else
  readonly PHPVER="php5-fpm"
fi

############################################################
# gestion de la sortie de openvpn-install.sh
# to do: ajout dans RecapInstall
#   cat << EOF >> $REPUL/HiwsT/RecapInstall.txt
#
# OpenVpn is installed
# EOF


if [[ ! -z "$ERRVPN" && $ERRVPN -ne 0 ]]; then  # sortie avec un code != 0 et non vide
  __messageBox "OpenVPN installation output" "
    Exit status: $ERRVPN
    There was a issue running openvpn-install"
  trap - EXIT
elif [[ ! -z "$ERRVPN" && $ERRVPN -eq 0 ]]; then # sortie avec un code == 0 et non vide
  # le script d'install copie le fichier *.ovpn dans ~ de l'admin
  # le déplacer dans le rep de l'utilisateur si existe et lui donner le bon proprio
  #                      si le compte existe                      et  si l'home a ce nom existe   et  si le compte a été manipulé
  if [[ -e /etc/openvpn/easy-rsa/pki/private/$NOMCLIENTVPN.key ]] && [[ -e /home/$NOMCLIENTVPN ]] && [[ ! -z "$NOMCLIENTVPN" ]]; then
    mv /home/${FIRSTUSER[0]}/$NOMCLIENTVPN.ovpn /home/$NOMCLIENTVPN/
    chown $NOMCLIENTVPN:$NOMCLIENTVPN /home/$NOMCLIENTVPN/$NOMCLIENTVPN.ovpn
    ici="/home/$NOMCLIENTVPN"
  elif [[ -e /etc/openvpn/easy-rsa/pki/private/$NOMCLIENTVPN.key ]] && [[ ! -z "$NOMCLIENTVPN" ]]; then
    # si l'home a ce nom n'existe pas
    chown "${FIRSTUSER[0]}":"${FIRSTUSER[0]}" /home/"${FIRSTUSER[0]}"/"$NOMCLIENTVPN".ovpn
    ici="/home/${FIRSTUSER[0]}"
  fi

  # contextualisation du message dans __messageBox
  #                 si le compte existe                           et si le compte a été manipulé
  if [[ -e /etc/openvpn/easy-rsa/pki/private/$NOMCLIENTVPN.key ]] && [[ ! -z $NOMCLIENTVPN ]]; then
    msg="
      Exit status: $ERRVPN
      Rated execution of openvpn-install$I
      The file $NOMCLIENTVPN.ovpn is in directory $ici $N"
  else  # si le compte n'existe plus ou qu'il n'a pas été manipulé
    msg="
      Exit status: $ERRVPN
      Rated execution of openvpn-install"
  fi
  __messageBox "OpenVPN installation output" "$msg"
  trap - EXIT
fi  # code ERRVPN vide veut dire openvpn-install pas exécuté

############################################################
#  gestion errueurs
trap "__trap" EXIT

## gestion des erreurs stderr par __msgErreurBox()
:>/tmp/trace # fichier temporaire msg d'erreur
:>/tmp/trace.log # fichier msg d'erreur
exec 3>&2 2>/tmp/trace

############################################################
# boucle main menu / sortie
__menu

############################################################
# Sortie
clear
echo
echo "Au revoir"  # french touch ;)
echo
