
htuser="www-data"
newUserName=$__saisieTexteBox
# get infos in config.php
readonly ocDataDir=$(grep "datadirectory" < $ocpath/config/config.php | awk -F"=>" '{ print $2 }' | sed -r "s/[ ',]//g")

# boite de saisie
__creaUserOCBox() {   # arg : titre, texte, l sous-boite
  __erreurSaise() {  # arg champs
    __messageBox "Creating ownCloud user" "
    ${R}Input mistake on ${BO}${1}${N}
    No space and \\ for the ${BO}Password${N}
    No \\ for the ${BO}Full name${N} and ${BO}Group${N}
    ${BO}Email address${N} in the format: xxxxxxx@xxxx.xxxx
    ${BO}External storage${N} and ${BO}Audioplayer${N} Y|y|N|n

    If ${BO}External storage${N} is enabled:
    Give fullpath direcory for ${BO}Local \"External\" Storage${N}
    This directory must exist"
  }
  local inputItem="" reponse=""
  addStorage="Y"; addAudioPlayer="Y"
  newUserPw=""; newFullUserName=""; newUserGroup=""; newUserMail=""
  until false; do
    # "${newUserName}" 1 28 -25 0 2
    # x, y
    # field len = flen 0 non modifiable long du champs = long du contenu  <0 non modifiable valeur = logueur du champs
    # input len = ilen =0 prends la valeur de flen
    # input type = itype 0 = normal 1 = hidden  2 = readonly
    # --default-item "nom du champs" place le curseur sur le champs en question
    CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --default-item "$inputItem" --separator "\\" --insecure --trim --cr-wrap --mixedform "${2}" 0 0 ${3} \
    "New ownCloud user:" 1 2 "${newUserName}" 1 28 -25 0 2 \
    "PW new ownCloud user:" 3 2 "${newUserPw}" 3 28 25 26 1 \
    "Full name:" 5 2 "$newFullUserName" 5 28 25 26 0 \
    "Group:" 7 2 "${newUserGroup}" 7 28 25 26 0 \
    "Email adress:" 9 2 "${newUserMail}" 9 28 25 26 0 \
    "AudioPlayer [Y/N]:" 11 2 "${addAudioPlayer}" 11 28 2 1 0
    "External storage [Y/N]:" 13 2 "${addStorage}" 13 28 2 1 0 \
    "Full path of local directory to mount:" 15 2 "${mountDir}" 16 15 50 26 0)
    reponse=$("${CMD[@]}" 2>&1 > /dev/tty)
    if [[ $? -ne 0 ]]; then return 1; fi

    # $newUserName n'est pas dans reponse, n'étant pas modifiable (-25)
    # format de $reponse : zesfg\zf\azdzad\....
    newUserPw=$(echo "$reponse" | awk -F"\\" '{ print $1 }')
    newFullUserName=$(echo "$reponse" | awk -F"\\" '{ print $2 }')
    newUserGroup=$(echo "$reponse" | awk -F"\\" '{ print $3 }')
    newUserMail=$(echo "$reponse" | awk -F"\\" '{ print $4 }')
    addAudioPlayer=$(echo "$reponse" | awk -F"\\" '{ print $5 }')
    addStorage=$(echo "$reponse" | awk -F"\\" '{ print $6 }')
    mountDir=$(echo "$reponse" | awk -F"\\" '{ print $7 }')

    # si erreur vide le champs incriminé et place le curseur
    if [[ "$newUserPw" =~ [[:space:]\\] ]] || [[ -z $newUserPw ]]; then
      __erreurSaise "PW new ownCloud user:"
      newUserPw=""
      inputItem="PW new ownCloud user:"
    elif [[ "$newFullUserName" =~ [\\] ]] || [[ -z $newFullUserName ]]; then
      __erreurSaise "Full name:"
      newFullUserName=""
      inputItem="Full name:"
    elif [[ "$newUserGroup" =~ [\\] ]] || [[ -z $newUserGroup ]]; then
      __erreurSaise "Group:"
      newUserGroup=""
      inputItem="Group:"
    elif [[ ! "$newUserMail" =~ ^[a-zA-Z0-9_][a-zA-Z0-9\.\+_-]{1,}@[a-zA-Z0-9\.\+_-]{1,}\.[a-zA-Z\.]{2,}$ ]] && [[ -n "$newUserMail" ]]; then
      __erreurSaise "Email adress:"
      newUserMail=""
      inputItem="Email adress:"
    elif [[ ! $addAudioPlayer =~ ^[YyNn]$ ]]; then
      __erreurSaise "AudioPlayer refresh"
      addAudioPlayer=""
      inputItem="AudioPlayer [Y/N]:"
    elif [[ ! $addStorage =~ ^[YyNn]$ ]]; then
      __erreurSaise "External storage"
      addStorage=""
      inputItem="External storage [Y/N]:"
    elif [[ ! -d "$mountDir" ]] && [[ $addStorage =~ ^[Yy]$ ]]; then
      __erreurSaise "Full path of local directory to mount:"
      mountDir=""
      inputItem="Full path of local directory to mount:"
    else  # tout est ok
      __saisiePwOcBox "Validation password entry" "New ownCloud user password:" 2 $newUserPw && \
      return 0
    fi
  done
}

__creaUserOCBox "Creating ownCloud user" "
  New ownCloud user: ${I}$newUserName${N}
  Attention! local storage can not be implemented later for this user
  as well as the Automatic AudioPlayer refresh.
  If you answer ${BO}yes${N} to the External Storage, enter the last field:
  Give Fullpath local direcory that you want mount with External Storage
  it must be exist:" 16
if [[ $? -ne 0 ]]; then continue; fi
export OC_PASS=$newUserPw
argEmail=""
if [[ -n "$newUserMail" ]]; then argEmail="--email=$newUserMail"; fi
su -s /bin/sh $htuser -c "php $ocpath/occ user:add --password-from-env --display-name=\"$newFullUserName\" --group=\"$newUserGroup\" $argEmail $newUserName" || \
__msgErreurBox "$ocpath/occ user:add --password-from-env --display-name=$newFullUserName --group=$newUserGroup $argEmail $newUserName" $?
export -n OC_PASS

if [[ $addStorage =~ [yY] ]]; then
  flagFiles_external=""
  ## vérifier que l'app files_external est bien activé si non l'activer
  verify=$(sudo -u $htuser php $ocpath/occ config:app:get files_external enabled)
  ## réponse "yes" correspond à "activé" sur le GUI
  if [[ $verify == "no" ]]; then
    cmd="sudo -u $htuser php $ocpath/occ app:enable files_external"; $cmd || __msgErreurBox "$cmd" $?
    flagFiles_external="disabled"
  else
    flagFiles_external="enabled"
  fi
  id=$(sudo -u $htuser php $ocpath/occ files_external:create Local-storage \\OC\\Files\\Storage\\Local null::null)
  id=$(expr match "$id" '.*\(.[0-9]\)')  # 1 ou 2 digits
  # ajout de \ a mountDir \/home\/${$newUserL}\/downloads
  sudo -u $htuser php $ocpath/occ files_external:config $id datadir $mountDir
  sudo -u $htuser php $ocpath/occ files_external:option $id enable_sharing true
  sudo -u $htuser php $ocpath/occ files_external:applicable --add-user=${newUserName} $id
  cmd="sudo -u $htuser php $ocpath/occ files_external:verify $id"; $cmd || __msgErreurBox "$cmd" $?
  if [[ $? -eq 0 ]]; then
    echoc v "                                      "
    echoc v "     External storage support ok      "
    echoc v "                                      "
    sleep 2
  fi
  if [[ $flagFiles_external == "disabled" ]]; then  # si l'app était désactivée la remettre dans le même état
    cmd="sudo -u $htuser php $ocpath/occ app:disable files_external"; $cmd || __msgErreurBox "$cmd" $?
  fi
fi

if [[ $addAudioPlayer =~ [yY] ]]; then
  flagAudioplayer=""
  verify=$(sudo -u $htuser php $ocpath/occ config:app:get audioplayer enabled)
  ## correspond à "activé" sur le GUI
  if [[ $verify == "no" ]]; then
    flagAudioplayer="disabled"
  else
    flagAudioplayer="enabled"
  fi
  sed -i '/<title>AudioplayerOC<\/title>/ a\<path type="recursive" syslog="off" events="close_write,move,delete,delete_self,move_self" exec="\/etc\/iwatch\/scanOC.sh %e %f">'$ocDataDir'\/'${newUserName}'\/files<\/path>' /etc/iwatch/iwatch.xml
  if [[ $addStorage =~ [yY] ]]; then
    sed -i '/<title>AudioplayerOC<\/title>/ a\<path type="recursive" syslog="off" events="close_write,move,delete,delete_self,move_self" exec="\/etc\/iwatch\/scanOC.sh %e %f">'$mountDir'<\/path>' /etc/iwatch/iwatch.xml
    if [[ -e "$mountDir/.session" ]] || [[ -e "$mountDir/watch" ]]; then
      sed -i '/.*</watchlist>/ i\<path type="exception">'$mountDir'\/.session<\/path>\n<path type="exception">'$mountDir'\/watch<\/path>'  /etc/iwatch/iwatch.xml
    fi
  fi
  __servicerestart "iwatch"
  if [[ $? -eq 0 ]]; then
    echoc v "                                      "
    echoc v "   Automatic AudioPlayer refresh ok   "
    echoc v "      All is ok for the new user      "
    echoc v "                                      "
    sleep 4
  fi
fi

__messageBox "Creating ownCloud user" " If setting-up completed
  $newUserName user created with
  Password:         $newUserPw
  Full name:        $newFullUserName
  Group:            $newUserGroup
  email:            $newUserMail
  External storege: $addStorage
  Audioplayer:      $addAudioPlayer
  The app External Storage is $flagFiles_external
  The app Audioplayer is $flagAudioplayer"
