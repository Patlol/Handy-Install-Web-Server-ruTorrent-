
readonly R="\Z1"
readonly BK="\Z0"  # black
readonly G="\Z2"
readonly Y="\Z3"
readonly BL="\Z4"  # blue
readonly W="\Z7"
readonly BO="\Zb"  # bold
readonly I="\Zr"   # vidéo inversée
readonly N="\Zn"   # retour à la normale
# TITRE=""
# TIMEOUT=""  # __messageBox
# RATIO=""


# Background and text + tab in color with tempo
# usage : echoc r " string "
# ARG : [r|v|b] [string]
echoc() {
  local ER="\\E[40m\\E[1;31m"  # fond + typo rouge
  local EV="\\E[40m\\E[1;32m"  # fond + typo verte
  local EN="\\E[0m"   # retour aux std
  local EF="\\E[40m"  # fond
  case ${1} in
    r)
      echo -e "\t${ER}${2}${EN}"
    ;;
    v)
      echo -e "\t${EV}${2}${EN}"
    ;;
    b)
      echo -e "\t${EF}${2}${EN}"
    ;;
    *)
      echo -e "\t${2}"
    ;;
  esac
  sleep 0.2
}

# Choice between yes or no
# ARG : titre, texte.
# RETURN $__ouinonBox 0 : yes 1 : no
__ouinonBox() {
  CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --trim --cr-wrap --yesno "${2}" 0 0 )
  choix=$("${CMD[@]}" 2>&1 > /dev/tty)
  __ouinonBox=$?
}

# Just play a message during xs
# ARG : titre, texte, timeout : empty=timeout on or $TIMEOUT
# RETURN : nothing
__messageBox() {
  local argTimeOut=""
  if [[ -z ${3} ]]; then
    argTimeOut="--timeout $TIMEOUT"
  fi
  CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --trim --cr-wrap --scrollbar $argTimeOut --msgbox "${2}" 0 0)
  choix=$("${CMD[@]}" 2>&1 > /dev/tty)
}

# input a string with help button and check input. Depend __messageBox
# Use for user name. HiwsT and HiwsT-util
# ARG : titre, texte, [h] for help, optional for HiwsT-util
# RETURN : $__saisieTexteBox one string all lower $? 0 or 1 (cancel)
__saisieTexteBox() {
  local codeRetour="", argHelp="", label="Users List"
  if [[ ${3} == "h" ]]; then
    argHelp="--help-button --help-label label"
  fi
  until false; do
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --trim --cr-wrap $argHelp --max-input 15 --inputbox "${2}" 0 0)

    # dialog --aspect 12 --colors --backtitle HiwsT : Installation rtorrent - ruTorrent[5] --title Creating user[7] --trim --cr-wrap --help-button --help-label label[12] --max-input 15 --inputbox
    CMD[12]="$label"   # si non "Users" [12] et "List" [13]
    __saisieTexteBox=$("${CMD[@]}" 2>&1 > /dev/tty)
    codeRetour=$?

    if [ $codeRetour == 2 ]; then  # bouton "liste" (help) renvoie code sortie 2
      cmd="__listeUtilisateurs"; $cmd || __msgErreurBox "$cmd" $?
      # l'appelle de la f() boucle jusqu'à code sortie == 0 ou 1 (cancel)
    elif [ $codeRetour == 1 ]; then return 1
    elif [[ "$__saisieTexteBox" =~ ^[a-zA-Z0-9]{2,15}$ ]]; then
      __saisieTexteBox=$(echo "$__saisieTexteBox" | tr '[:upper:]' '[:lower:]')
      return 0
    else
      __messageBox "Validation entry" "
        Only alphanumeric characters
        Between 2 and 15 characters"
    fi
  done
}

# Input and check password
# Depend : __messageBox
# ARG : titre, texte, nbr de ligne sous boite
# RETURN :  __saisiePwBox string
__saisiePwBox() {
  local pw1=""; local pw2=""; local codeSortie=""; local reponse=""
  until false; do
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --insecure --trim --cr-wrap --nocancel --passwordform "${2}" 0 0 ${3} "Password: " 2 4 "" 2 25 25 25 "Retype: " 4 4 "" 4 25 25 25 )
    reponse=$("${CMD[@]}" 2>&1 > /dev/tty)

    if [[ "$reponse" =~ .*[[:space:]].*[[:space:]].* ]] || [[ "$reponse" =~ [\\] ]]; then
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

# Vérifie la double saisie d'un mot de passe
# ARG : titre, texte, nbr de ligne sous boite, pw à vérifier
# Depend __messageBox
__saisiePwOcBox() {
  local pw1=""; local codeSortie=""; local reponse=""
  until false; do
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --insecure --trim --cr-wrap --passwordform "${2}" 0 0 ${3} "Retype password: " 2 4 "" 2 21 25 25)
    reponse=$("${CMD[@]}" 2>&1 > /dev/tty)
    if [[ $? == 1 ]]; then return 1; fi
    if [[ "$reponse" =~ .*[[:space:]].*[[:space:]].* ]] || [[ "$reponse" =~ [\\] ]]; then
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

# Play text file with baseline (optional)
# ARG : $1 titre  $2 fichier à lire  $3 texte baseline
# RETURN : nothing
__textBox() {   # $1 titre  $2 fichier à lire  $3 texte baseline
  local argHLine=""
  if [[ -n ${3} ]]; then
    argHLine="--hline \"${3}\""
  fi
  CMD=(dialog --backtitle "$TITRE" --exit-label "Continued from installation" --title "${1}" $argHLine --textbox  "${2}" 0 0)
  ("${CMD[@]}" 2>&1 > /dev/tty)
}

# Play error message with line and source and write /tmp/trace.log
# Depend __messageBox __ouinonBox
# ARG : commande, N° error
# RETURN same N° error or exit N° erroro
__msgErreurBox() {
  local msgErreur, ref
  ref=$(caller 0)
  err=${2}
  msgErreur="------------------\n"
  msgErreur+="Line N°${ref}\n${BO}${R}${1}${N}\nError N° ${R}${err}${N}\n"
  trace=$(tail -n 10 /tmp/trace)
  msgErreur+="${trace}\n"
  msgErreur+="-------------------\n"
  :>/tmp/trace
  __messageBox "${R}Error message${N}" " ${msgErreur}
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
