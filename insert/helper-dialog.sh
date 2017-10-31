
readonly R="\Z1"
readonly BK="\Z0"  # black
readonly G="\Z2"
readonly Y="\Z3"
readonly BL="\Z4"  # blue
readonly W="\Z7"
readonly BO="\Zb"  # bold
readonly I="\Zr"   # vidéo inversée
readonly N="\Zn"   # retour à la normale
TITRE=""
TIMEOUT=""  # __messageBox
RATIO=""


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
  local argTimeOut
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
  local codeRetour="", argHelp=""
  if [[ ${3} == "h" ]]; then
    argHelp="--help-button --help-label \"Users list\""
  fi
  until false; do
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --trim --cr-wrap --max-input 15 $argHelp --inputbox "${2}" 0 0)
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
