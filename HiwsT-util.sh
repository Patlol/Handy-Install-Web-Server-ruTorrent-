#!/bin/bash

# Enemble d'utilitaires pour la gestion des utilisateurs linux, rutorrent
# L'ajout ou la suppression d'utilisateurs
# Changement de mot de passe
#
# installation d'openvpn et ownCloud
# L'ajout ou la suppression d'utilisateurs

# testée sur ubuntu et debian server vps Ovh
# et sur kimsufi. A tester sur autres hébergeurs
# https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-


readonly REPWEB="/var/www/html"
readonly REPAPA2="/etc/apache2"
readonly REPLANCE=$(pwd)
readonly REPInstVpn=$REPLANCE
readonly ocpath='/var/www/owncloud' # pour letsencrypt, owncloud, up-owncloud et crea-owncloud-user
# pas readonly pour IP car modifié dans openvpninstall
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
readonly HOSTNAME=$(hostname -f)
# Tableau des utilisateurs principaux 0=linux, 1=rutorrent, owncloud dans oc db
if [[ ! -e $REPLANCE/firstusers ]]; then
  echo; echo "The file \"firstusers\" is not available"; echo
  exit 2
fi
i=0
while read user; do  # [0]=linux, [1]=ruTorrent
  FIRSTUSER[$i]=$user
  (( i++ ))
done < $REPLANCE/firstusers
declare -ar FIRSTUSER  # -r readonly
readonly REPUL="/home/${FIRSTUSER[0]}"
# dialog param --backtitle --aspect --colors
readonly TITRE="Utilitaire HiwsT : rtorrent - ruTorrent - openVPN - ownCloud"
readonly TIMEOUT=20  # __messageBox
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

########################################
#       Fonctions utilitaires
########################################

__ouinonBox() {    # param : titre, texte  sortie $__ouinonBox 0 ou 1
  CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --trim --cr-wrap --yesno "
${2}" 0 0 )
  choix=$("${CMD[@]}" 2>&1 >/dev/tty)
  __ouinonBox=$?
}    #  fin ouinon

__messageBox() {   # param : titre texte
  local argTimeOut
  if [[ -z ${3} ]]; then
    argTimeOut="--timeout $TIMEOUT"
  fi
  CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --scrollbar --trim --cr-wrap $argTimeOut --msgbox "${2}" 0 0)
  choix=$("${CMD[@]}" 2>&1 >/dev/tty)
}

__msgErreurBox() {   # param : commande, N° erreur
  local msgErreur; local ref=$(caller 0)
  err=$2
  msgErreur="------------------\n"
  msgErreur+="Line N°$ref\n${BO}$R$1${N}\nError N° $R$err${N}\n"
  trace=$(tail -n 10 /tmp/trace)
  msgErreur+="$trace\n"
  :>/tmp/trace
  msgErreur+="-------------------\n"
  __messageBox "${R}Error message${N}" " $msgErreur$
    ${R}See the wiki on github${N}
    https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/something-wrong
    The error message is stored in ${I}/tmp/trace.log${N}" "NOtimeout"
  echo -e ${msgErreur} | sed -r 's/------------------//g' > /tmp/trace.log
  sed -i -e 's/\\Zb//g' -e 's/\\Z1//g' -e 's/\\Zn//g' /tmp/trace.log
  __ouinonBox "Error" "
    Do you want continue anyway?
    "
  if [[ $__ouinonBox -ne 0 ]]; then exit $err; fi
  return $err
}  # fin messageErreur

__saisieTexteBox() {   # param : titre, texte
  local codeRetour=""
  until false; do
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --trim --cr-wrap --help-button --help-label "Users list" --max-input 15 --inputbox "${2}" 0 0)
    __saisieTexteBox=$("${CMD[@]}" 2>&1 >/dev/tty)
    codeRetour=$?

    if [ $codeRetour == 2 ]; then  # bouton "liste" (help) renvoie code sortie 2
      cmd="__listeUtilisateurs"; $cmd || __msgErreurBox "$cmd" $?
      # l'appelle de la f() boucle jusqu'à code sortie == 0
    elif [ $codeRetour == 1 ]; then return 1
    elif [[ "$__saisieTexteBox" =~ ^[a-zA-Z0-9]{2,15}$ ]]; then
      __saisieTexteBox=$(echo $__saisieTexteBox | tr '[:upper:]' '[:lower:]')
      break
    else
      __messageBox "Validation entry" "
        Only alphanumeric characters
        Between 2 and 15 characters"
    fi
  done
}

__trap() {  # pour exit supprime affiche la dernière erreur
  export -n OC_PASS
  if [ -s /tmp/trace.log ]; then  # taille fichier > 0 ;)
    echo "/tmp/trace.log:"; echo
    cat /tmp/trace.log
  fi
}

__saisiePwBox() {  # param : titre, texte, nbr de ligne sous boite
  local pw1=""; local pw2=""; local codeSortie=""; local reponse=""
  until false; do
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --insecure --trim --cr-wrap --nocancel --passwordform "${2}" 0 0 ${3} "Password: " 2 4 "" 2 25 25 25 "Retype: " 4 4 "" 4 25 25 25 )
    reponse=$("${CMD[@]}" 2>&1 >/dev/tty)

    if [[ `echo $reponse | grep -Ec ".*[[:space:]].*[[:space:]].*"` -ne 0 ]] ||\
    [[ `echo $reponse | grep -Ec "[\\]"` -ne 0 ]]; then
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
}

__saisiePwOcBox() {  # param : titre, texte, nbr de ligne sous boite, pw à vérifier
  local pw1=""; local codeSortie=""; local reponse=""
  until false; do
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --insecure --trim --cr-wrap --passwordform "${2}" 0 0 ${3} "Retype password: " 2 4 "" 2 21 25 25)
    reponse=$("${CMD[@]}" 2>&1 >/dev/tty)
    if [[ $? == 1 ]]; then return 1; fi
    if [[ `echo $reponse | grep -Ec ".*[[:space:]].*[[:space:]].*"` -ne 0 ]] ||\
    [[ `echo $reponse | grep -Ec "[\\]"` -ne 0 ]]; then
      __messageBox "${1}" "
        The password can't contain spaces or \\.
        "
    else
      pw1=$(echo $reponse | awk -F" " '{ print $1 }')
      case $pw1 in
        "" )
          __messageBox "${1}" "
            The password can't be empty.
            "
        ;;
        ${4} )  # password linux or database
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
}  # fin __saisiePwOcBox()

__saisieOCBox() {  # POUR OWNCLOUD param : titre, texte, nbr de ligne sous boite
  __helpOC() {
    dialog --backtitle "$TITRE" --title "ownCloud help" --exit-label "Back to input" --textbox  "insert/helpOC" "51" "71"
  }  # fin __helpOC()

  ## debut __saisieOCBox()  $2 texte $3 Nbr lignes de la sous-boite
  local reponse="" codeRetour="" inputItem="" help="" # champs ou a été actionné le help-button
  pwFirstuser=""; userBdD=""; pwBdD=""; fileSize="513M"; addStorage=""; addAudioPlayer=""; ocDataDir="/var/www/owncloud/data"
  until false; do
    # --help-status donne les champs déjà saisis dans $reponse en plus du tag HELP "HELP nom du champs\sasie1\saide2\\saise4\"
    # --default-item "nom du champs" place le curseur sur le champs ou à été pressé le bouton help
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --nocancel --help-button --default-item "$inputItem" --help-status --separator "\\" --insecure --trim --cr-wrap --mixedform "${2}" 0 0 ${3} "Linux user:" 1 2 "${FIRSTUSER[0]}" 1 28 -16 0 2 "PW Linux user:" 3 2 "$pwFirstuser" 3 28 25 25 1 "OC Database admin:" 5 2 "$userBdD" 5 28 16 15 0 "Password database admin:" 7 2 "$pwBdD" 7 28 25 25 1 "Max files size:" 9 2 "$fileSize" 9 28 6 5 0 "Data directory location:" 11 2 "$ocDataDir" 11 28 25 35 0 "External storage [Y/N]:" 13 2 "$addStorage" 13 28 2 1 0 "AudioPlayer [Y/N]:" 15 2 "$addAudioPlayer" 15 28 2 1 0)
    reponse=$("${CMD[@]}" 2>&1 >/dev/tty)
    codeRetour=$?

    # bouton "Aide" (help) renvoie code sortie 2
    if [[ $codeRetour == 2 ]]; then
      __helpOC
      # FIRSTUSER[0] n'est pas dans reponse, n'étant pas modifiable (-16)
      # format de $reponse : HELP PW Linux user:\qsdf\ddddd\...
      inputItem=$(echo $reponse | awk -F"\\" '{ print $1 }' | cut -d \  -f 2-) # pour placer le curseur
      pwFirstuser=$(echo $reponse | awk -F"\\" '{ print $2 }')
      userBdD=$(echo $reponse | awk -F"\\" '{ print $3 }')
      pwBdD=$(echo $reponse | awk -F"\\" '{ print $4 }')
      fileSize=$(echo $reponse | awk -F"\\" '{ print $5 }')
      ocDataDir=$(echo $reponse | awk -F"\\" '{ print $6 }')
      addStorage=$(echo $reponse | awk -F"\\" '{ print $7 }')
      addAudioPlayer=$(echo $reponse | awk -F"\\" '{ print $8 }')
    else
      # FIRSTUSER[0] n'est pas dans reponse, n'étant pas modifiable (-16)
      # format de $reponse : zesfg\zf\azdzad\....
      pwFirstuser=$(echo $reponse | awk -F"\\" '{ print $1 }')
      userBdD=$(echo $reponse | awk -F"\\" '{ print $2 }')
      pwBdD=$(echo $reponse | awk -F"\\" '{ print $3 }')
      fileSize=$(echo $reponse | awk -F"\\" '{ print $4 }')
      ocDataDir=$(echo $reponse | awk -F"\\" '{ print $5 }')
      addStorage=$(echo $reponse | awk -F"\\" '{ print $6 }')
      addAudioPlayer=$(echo $reponse | awk -F"\\" '{ print $7 }')
      # vide le champs incriminé et place le curseur
      if [[ $pwFirstuser =~ [[:space:]\\] ]] || [[ -z $pwFirstuser ]]; then
        __helpOC
        pwFirstuser=""
        inputItem="PW Linux user:"
      elif [[ $userBdD =~ [[:space:]\\] ]] || [[ -z $userBdD ]]; then
        __helpOC
        userBdD=""
        inputItem="OC Database admin:"
      elif [[ $pwBdD =~ [[:space:]\\] ]] || [[ -z $pwBdD ]]; then
        __helpOC
        pwBdD=""
        inputItem="Password database admin:"
      elif [[ ! $fileSize =~ ^[1-9][0-9]{0,3}[GM]$ ]]; then
        __helpOC
        fileSize="513M"
        inputItem="Max files size:"
      elif [[ $ocDataDir =~ [[:space:]\\] ]] || [[ -z $ocDataDir ]]; then
        __helpOC
        ocDataDir="/var/www/owncloud/data"
        inputItem="Data directory location:"
      elif [[ ! $addStorage =~ ^[YyNn]$ ]]; then
        __helpOC
        addStorage=""
        inputItem="External storage [Y/N]:"
      elif [[ ! $addAudioPlayer =~ ^[YyNn]$ ]]; then
        __helpOC
        addAudioPlayer=""
        inputItem="AudioPlayer [Y/N]:"
      else
        __saisiePwOcBox "Validation password entry" "Linux user password" 2 $pwFirstuser && \
        __saisiePwOcBox "Validation password entry" "Database admin password" 2 $pwBdD  && \
        break
      fi
    fi  # fin $codeRetour == 2
  done  # fin until infinie
}  # fin __saisieOCBox()

__saisieDomaineBox() {  # param : titre, texte, lignes sous-boite
  local reponse="" message=""
  installCert="Y"
  until false; do
    until false; do
      CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --separator "\\" --default-item "$inputItem" --trim --cr-wrap --mixedform "${2}" 0 0 ${3} "Domain name:" 1 2 "$__saisieDomaineBox1" 1 28 44 43 0 "Cert Let's Encrypt [Y/N]:" 3 2 "$installCert" 3 28 2 1 0)
      reponse=$("${CMD[@]}" 2>&1 >/dev/tty)  # ezfezf.ff\Y\
      if [[ $? == 1 ]]; then return 1; fi  # bouton cancel
      __saisieDomaineBox1=$(echo $reponse | awk -F"\\" '{ print $1 }')
      installCert=$(echo $reponse | awk -F"\\" '{ print $2 }')
      if [[ "$__saisieDomaineBox1" =~ ^([[:digit:]a-z-]+\.[a-z\.]{2,})$ ]] && \
      [[ $(echo $__saisieDomaineBox1 | egrep "^w{3}\.") == "" ]]; then
        __saisieDomaineBox2="www."$__saisieDomaineBox1
        break
      else
                __messageBox "Entry validation" "
          Enter a valid domain name.
          Only unaccented alphanumeric characters,
          without http(s):// and www."
          inputItem="Domain name:"
      fi
      if [[ ! $installCert =~ ^[YyNn]$ ]]; then
        __messageBox "Entry validation" "
          Enter a valid reply:
          Y y N n in \"Cert Let's Encrypt\""
        installCert="Y"
        inputItem="Cert Let's Encrypt [Y/N]:"
      fi
    done
    if [[ $installCert =~ ^[Yy]$ ]]; then message="${BO}Vous allez installer Let'sEncrypt${N}"; fi
    __ouinonBox "Confirmation" " The domain names concerned are well:
      ${R}$__saisieDomaineBox1${N}
      and
      ${R}$__saisieDomaineBox2${N}
      $message"
    if [[ $__ouinonBox -eq 0 ]]; then break; fi
  done
} # fin __saisieDomaineBox()

__servicerestart() {
  local codeSortie
  service $1 restart
  codeSortie=$?
  cmd="service $1 status"; $cmd || __msgErreurBox "$cmd" $?
  return $codeSortie
} # fin __servicerestart()

################################################################################
#       Fonctions principales
########################################

#################################################
##  ajout utilisateur sous menu et traitements
#################################################
__ssmenuAjoutUtilisateur() {
local typeUser=""; local codeSortie=1

until false; do
  # Create a user:" 22 70 4 \
  CMD=(dialog --backtitle "$TITRE" --title "Add a user" --trim --cr-wrap --cancel-label "Exit" --menu "

    A ruTorrent user can only be created with a Linux user

    Create a user:" 18 65 3 \
    1 "Linux + ruTorrent"
    2 "OwnCloud"
    3 "Users list")

  typeUser=$("${CMD[@]}" 2>&1 > /dev/tty)
  if [[ $? -eq 0 ]]; then  # pas cancel
    if [[ $typeUser -ne 3 ]]; then  # 3 = users list
      __saisieTexteBox "Creating user" "
        Input the name of new user${R}
        Neither space nor special characters${N}"
      if [[ $? -eq 1 ]]; then   # 1 si bouton cancel
        typeUser=""
      fi
    fi
    case $typeUser in
      1 )  #  créa linux ruto
        __userExist $__saisieTexteBox    # insert/util_apache.sh renvoie userL userR 0 = existe
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
      2 )  # créa owncloud user
        pathOCC=$(find /var -name occ 2>/dev/null)
        if [[ -n $pathOCC ]]; then  # owncloud installé
          __listeUtilisateursOC
          if [[ $(echo $__listeUtilisateursOC | grep -w $__saisieTexteBox) ]]; then
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

######################################################
##  supprimer utilisateur sous menu et traitements
######################################################
__ssmenuSuppUtilisateur() {
  local typeUser=""; local codeSortie=1

  until false; do
    # Delete a user:" 22 70 4 \
    CMD=(dialog --backtitle "$TITRE" --title "Delete a user" --trim --cr-wrap --cancel-label "Exit" --menu "
      What user kind do you want to remove?

      - If a ruTorrent user is deleted, his Linux namesake
      will also be deleted.

      Delete a user:" 18 65 2 \
      1 "Linux + ruTorrent"
      2 "Users list")

    typeUser=$("${CMD[@]}" 2>&1 > /dev/tty)
    if [[ $? -eq 0 ]]; then
      # $type
      # filtrer le choix 2 : liste user
      if [[ $typeUser -ne 2 ]]; then
        __saisieTexteBox "Delete a user" "
          Input a user name:"
        if [[ $? -eq 1 ]]; then  # 1 si bouton cancel
          typeUser=""
        else
          __userExist $__saisieTexteBox  # insert/util_apache.sh renvoie userL userR
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
              #  $ __saisieTexteBox
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

#########################################
##  Changement pw Menu + traitement
#########################################

__changePW() {
  local typeUser=""; local user=""; local codeSortie=1

  until false; do
    CMD=(dialog --backtitle "$TITRE" --title "Change User Password" --trim --cr-wrap --cancel-label "Exit" --menu "


      What user kind do you want change?
      " 18 65 3 \
      1 "Linux"
      2 "ruTorrent"
      3 "users list")
    typeUser=$("${CMD[@]}" 2>&1 > /dev/tty)
    if [[ $? -eq 0 ]]; then
      case $typeUser in
        1 )   ###  utilisateur Linux
          __saisieTexteBox "Change Password" "
            Input a Linux user name
            Linux password also valid for sftp!!!"
          if [[ $? -eq 0 ]]; then  # 1 si bouton cancel
            # user linux
            clear
            egrep "^$__saisieTexteBox:" /etc/passwd >/dev/null
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
            Input a ruTorrent user name"
          if [[ $? -eq 0 ]]; then
            # user ruTorrent ?
            __userExist $__saisieTexteBox  # insert/util_apache.sh
            if [[ $userR -eq 0 ]]; then  # $userR sortie de __userExist 0 ou erreur
              __saisiePwBox "Change Password ruTorrent" "$__saisieTexteBox user" 4
              clear
              __changePWRuto $__saisieTexteBox $__saisiePwBox  # insert/util_apache.sh, renvoie $?
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


############################
##  Menu principal
############################
__menu() {
  local choixMenu=""; local item=1
  until false; do
    # /!\ 7) doit être firewall (retour test openvpn avec $item) et openvpn 5) item=x
    # --menu text height width menu-height
    CMD=(dialog --backtitle "$TITRE" --title "Main menu" --trim --cr-wrap --cancel-label "Exit" --default-item "$item" --menu "
      To be used after installation with HiwsT

      Your choice:" 22 70 12 \
      1 "Create a user Linux, ruTorrent, ownCloud" \
      2 "Change user password" \
      3 "Delete a user" \
      4 "List existing users" \
      5 "Install/uninstall OpenVPN, a openVPN user" \
      6 "Install/update ownCloud" \
      7 "Firewall" \
      8 "Add domain name & Install free cert Let's Encrypt" \
      9 "Install phpMyAdmin" \
      10 "Restart rtorrent manually" \
      11 "Diagnostic" \
      12 "Reboot the server")
    choixMenu=$("${CMD[@]}" 2>&1 > /dev/tty)

    if [[ $? -eq 0 ]]; then
      case $choixMenu in
        1 )  ################ ajouter user  ################################
          __ssmenuAjoutUtilisateur
        ;;
        2 ) ################# modifier pw utilisateur  ############################
          cmd="__changePW"; $cmd || __msgErreurBox "$cmd" $?
        ;;
        3 ) ################# supprimer utilisateur  ############################
          cmd="__ssmenuSuppUtilisateur"; $cmd || __msgErreurBox "$cmd" $?
        ;;
        4 )  ################# liste utilisateurs #######################
          cmd="__listeUtilisateurs"; $cmd || __msgErreurBox "$cmd" $?
        ;;
        5 )  ######### VPN  ###################################
          # si firewall off et vpn pas installé
          if [[ ! $(iptables -L -n | grep -E 'REJECT|DROP') ]]  && [[ ! -e /etc/openvpn/server.conf ]]; then
            __ouinonBox "Install openVPN" "${R}${BO} Turn ON the firewall BEFORE
              installing the VPN !!!${N}
              "
            if [[ $__ouinonBox -eq 0 ]]; then
              item=7  # menu => Firewall
              continue
            else
              continue
            fi
          fi
          __ouinonBox "openVPN" "
            VPN installed with the${R}Angristan script${N}(MIT  License),
            with his kind permission. Thanks to him

            github repository: https://github.com/Angristan/OpenVPN-install
            Angristan's blog: https://angristan.fr/installer-facilement-serveur-openvpn-debian-ubuntu-centos/

            Excellent security-enhancing script, allowing trouble-free installation
            on Debian, Ubuntu, CentOS et Arch Linux servers.
            Do not reinvent the wheel (less well), that's the Oppen Source
            ${R}${BO}
            -----------------------------------------------------------------------------------------
            |  - To the question 'Tell me a name for the client cert'
            |    Give the name of the linux user to which the vpn is intended.
            |  - If you restart this script you can add or remove
            |    a user, uninstall the VPN.
            |  - The configuration file will be located in the corresponding /home if his name exist.
            ------------------------------------------------------------------------------------------${N}" 22 100
          if [[ $__ouinonBox -eq 0 ]]; then __vpn; fi
          item=1  # menu => Create a user
        ;;
        6 )  ###################### ownCloud #############################
          pathOCC=$(find /var -name occ 2>/dev/null)
          if [[ -n $pathOCC ]]; then
            __ouinonBox "Install/update ownCloud" "
              ownCloud is already installed.
              Do you want update it?
              "
            if [[ $__ouinonBox -ne 0 ]]; then
              continue
            else
              . $REPLANCE/insert/util_up-owncloud.sh
              __messageBox "Owncloud upgrade" " Treatment completed.
              Your new ownCloud version: $ocVer is ok
              "
              continue
            fi
          fi
          __saisieOCBox "ownCloud setting" "${R}Consult the help${N}" 15   # lignes ss-boite

          . $REPLANCE/insert/util_owncloud.sh
          varLocalhost="localhost"  # pour $I$varLocalhost dans __messageBox
          varOwnCloud="owncloud"
          __messageBox "${ocVer} install" " Treatment completed.
            Your ownCloud website https://$HOSTNAME/owncloud or
            https://$IP/owncloud
            Accept the Self Signed Certificate and the exception for this certificate!

            ${BO}Note that ${N}${I}${FIRSTUSER[0]}$N${BO} and his password is your account and ownCloud administrator account.
            The administrator of mysql database $varOwnCloud is${N} ${I}$userBdD${N} and his password ${I}$pwBdD${N}

            This information is added to the file $REPUL/HiwsT/RecapInstall.txt"
          cat << EOF >> $REPUL/HiwsT/RecapInstall.txt

To access your private cloud:
  https://$HOSTNAME/owncloud ou $IP/owncloud
  User (and administrator): ${FIRSTUSER[0]}
  Password: $pwFirstuser
  Administrator of OC database: $userBdD
  Password: $pwBdD
EOF
        ;;
        7 )  #####################  firewall  ############################
          __messageBox "Firewall and ufw" "


            ${I}Warning !!!${N}
            The following setting only takes into account the installations
            execute with HiwsT" 12 75

          __firewall
          if [[ $item -eq 7 ]]; then item=5; fi  # menu : si on vient de openvpn on y retourne
        ;;
        8 )  #################  domain & letsencrypt ###################
          which certbot 2>&1 > /dev/null
          if [ $? -eq 0 ]; then
            __messageBox "Domain & Let's Encrypt" "
              Let's Encrypt Certificates is already installed
              "
            continue
          fi
          __saisieDomaineBox "Domain name registration" "
            If you have provided a domain name for ${IP}/ruTorrent /ownCloud
            ${R}AND${N} the DNS servers are uptodate, enter here your domain name.

            This domain will be used for the ${BO}Apache${N} and ${BO}Let's Encrypt${N} (free ssl certificate) configuration.

            Example: ${I}my-domain-name.co.uk${N} or ${I}22my-22domaine-name.commmm${N} etc. ...

            ${R}Do not enter www. or http:// The two domains ${BO}www.mydomainname.com${N}${R}
            and ${BO}mydomainname.com${N}${R} will be automatically used${N}" 3
          if [[ $? -eq 0 ]]; then   # not cancel
            . $REPLANCE/insert/util_letsencrypt.sh
          fi
        ;;
        9 )  ########################  phpMyAdmin  #####################
          pathPhpMyAdmin=$(find /var/lib/apache2/conf/enabled_by_maint -name phpmyadmin)
          if [[ -n $pathPhpMyAdmin ]]; then
            __messageBox "Install phpMyAdmin" "
              phpMyAdmin is already installed
              "
            continue
          fi
          . $REPLANCE/insert/util_phpmyadmin.sh
        ;;
        10 )  ########################  Relance rtorrent  ######################
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
        11 )  ################# Diagnostiques ###############################
          __diag
        ;;
        12 )  ###########################  REBOOT  #######################
          __ouinonBox "${R}${BO}Server Reboot${N}"
          if [[ $__ouinonBox -eq 0 ]]; then
            clear
            sleep 2
            reboot
          fi
        ;;
      esac  # $choixMenu
    else
      break
    fi  # Bouton ok/exit
  done  # Boucle infinie menu

}  # fin menu

################################################################################
##                              Début du script
################################################################################
# root ?

if [[ $(id -u) -ne 0 ]]; then
  echo
  echo "This script needs to be run with sudo."
  echo
  echo "id : "`id`
  echo
  exit 1
fi

################################################################################
# apache vs nginx ?

service nginx status  > /dev/null 2>&1
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

################################################################################
#  chargement des f() apache, liste users ...
. $REPLANCE/insert/util_apache.sh
. $REPLANCE/insert/util_listeusers.sh
. $REPLANCE/insert/util_diag.sh
. $REPLANCE/insert/util_firewall.sh
. $REPLANCE/insert/util_vpn.sh
. $REPLANCE/insert/util_supp-rutorrent-user.sh
. $REPLANCE/insert/util_crea-rutorrent-user.sh

################################################################################
#  debian ou ubuntu et version  pour ownCloud et diag
nameDistrib=$(lsb_release -si)  # "Debian" ou "Ubuntu"
os_version=$(lsb_release -sr)   # 18 , 8.041 ...
os_version_M=$(echo $os_version | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')  # version majeur 18, 8 ...
if [[ $nameDistrib == "Ubuntu" ]] || [[ $nameDistrib == "Debian" && $os_version_M == 9 ]]; then
  readonly PHPVER="php7.0-fpm"
else
  readonly PHPVER="php5-fpm"
fi

################################################################################
# gestion de la sortie de openvpn-install.sh

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
    chown ${FIRSTUSER[0]}:${FIRSTUSER[0]} /home/${FIRSTUSER[0]}/$NOMCLIENTVPN.ovpn
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

################################################################################
#  gestion errueurs
trap "__trap" EXIT

## gestion des erreurs stderr par __msgErreurBox()
:>/tmp/trace # fichier temporaire msg d'erreur
:>/tmp/trace.log # fichier msg d'erreur
exec 3>&2 2>/tmp/trace

################################################################################
# boucle menu / sortie
__menu

################################################################################
# Sortie
clear
echo
echo "Au revoir"  # french touch ;)
echo
