#!/bin/bash

# Enemble d'utilitaires pour la gestion des utilisateurs linux, rutorrent
# L'ajout ou la suppression d'utilisateurs
# Changement de mot de passe
# ....
# installation d'openvpn et ownCloud
# L'ajout ou la suppression d'utilisateurs

# testée sur ubuntu et debian server vps Ovh
# et sur kimsufi. A tester sur autres hébergeurs
# https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-


readonly REPWEB="/var/www/html"
readonly REPAPA2="/etc/apache2"
readonly REPLANCE=$(echo `pwd`)
readonly REPInstVpn=$REPLANCE
readonly IP=$(ifconfig $interface 2>/dev/null | grep 'inet ad' | awk -F: '{ printf $2 }' | awk '{ printf $1 }')
readonly HOSTNAME=$(hostname -f)
SERVEURHTTP=""
# Tableau des utilisateurs principaux 0=linux 1=rutorrent
if [[ ! -e $REPLANCE/firstusers ]]; then
  echo
  echo "The file \"firstusers\" is not available"
  echo
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
			dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --sleep ${2} --infobox "${3}" 0 0
}

__msgErreurBox() {
	__messageBox "Error message" "

	See the wiki on github

  https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
	exit 1
}  # fin messageErreur

__saisieTexteBox() {   # param : titre, texte
	local codeRetour=""
	until [[ 1  -eq 2 ]]; do
		CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --help-button --help-label "Users list" --max-input 15 --inputbox "${2}" 0 0)
		__saisieTexteBox=$("${CMD[@]}" 2>&1 >/dev/tty)
		codeRetour=$?

		if [ $codeRetour == 2 ]; then  # bouton "liste" (help) renvoie code sortie 2
			__listeUtilisateurs
 			# l'appelle de la f() boucle jusqu'à code sortie == 0
		elif [ $codeRetour == 1 ]; then return 1
		elif [[ "$__saisieTexteBox" =~ ^[a-zA-Z0-9]{2,15}$ ]]; then
      __saisieTexteBox=$(echo $__saisieTexteBox | tr '[:upper:]' '[:lower:]')
			break
		else
			__infoBox "Validation entry" 3 "
Only alphanumeric characters
Between 2 and 15 characters"
		fi
	done
}

__saisiePwBox() {  # param : titre, texte, nbr de ligne sous boite
  local pw1=""; local pw2=""; local codeSortie=""; local reponse=""
	until [[ 1 -eq 2 ]]; do
		CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --insecure --nocancel --passwordform "${2}" 0 0 ${3} "Password: " 2 4 "" 2 25 25 25 "Retype: " 4 4 "" 4 25 25 25 )
		reponse=$("${CMD[@]}" 2>&1 >/dev/tty)

    if [[ `echo $reponse | grep -Ec ".*[[:space:]].*[[:space:]].*"` -ne 0 ]] ||\
      [[ `echo $reponse | grep -Ec "[\\]"` -ne 0 ]]; then
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

# __saisieBdDBox() { # pour util_listeusers param : titre, texte, nbr ligne sous-boite
#   local reponse="" codeRetour="" repQuery="" tabQuery=""
#   userBdD=""; pwBdD=""
# 	until [[ 1 -eq 2 ]]; do
# 		CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --separator "\\" --insecure --mixedform "${2}" 0 0 ${3} "name admin MySQL user: " 1 2 "" 1 28 16 16 0 "PW admin MySQL user: " 3 2 "" 3 28 25 25 1)
# 		reponse=$("${CMD[@]}" 2>&1 >/dev/tty)
#     codeRetour=$?
#     if [[ $codeRetour -eq 1 ]]; then return 1; fi
#     userBdD=$(echo $reponse | awk -F"\\" '{ print $1 }')
#     pwBdD=$(echo $reponse | awk -F"\\" '{ print $2 }')
#     repQuery=$(echo "SELECT * FROM owncloud.oc_group_user;" | mysql -BN -u $userBdD -p$pwBdD)
#     if [[ $repQuery == "" ]]; then
#       __infoBox "${1}" 3 "
# The Name or the password of user is (are) false."
#     else
#   		# liste => tab,  $repQuery : group id group id .....
#   		tabQuery=($(echo $repQuery))
#   		j=0  # $j : 0 1 2 3 ... index nouveau tableau $listeOC ne contenant que les id
#   		     # $i : 1 3 5 ... les id dans $tabQuery,  (($i-1)) le groupe correspondant
#   		for (( i = 1; i < ${#tabQuery[@]}; i++)); do
#   			listeOC[$j]=${tabQuery[$i]}
#   			if [[ ${tabQuery[(($i-1))]} == "admin" ]]; then
#   				listeOC[$j]="[${listeOC[$j]}]"  # entre [] pour l'admin
#   			fi
#   			((j++)); ((i++))
#   		done
#       break
#     fi
#   done
#   return 0
# }

__saisieOCBox() {  # POUR OWNCLOUD param : titre, texte, nbr de ligne sous boite
  __helpOC() {
    dialog --backtitle "$TITRE" --title "ownCloud help" --exit-label "Back to input" --textbox  "insert/helpOC" "51" "71"
  }
  __saisiePwOcBox() {  # param : titre, texte, nbr de ligne sous boite, pw à vérifier
    local pw1=""; local codeSortie=""; local reponse=""
  	until [[ 1 -eq 2 ]]; do
  		CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --insecure --passwordform "${2}" 0 0 ${3} "Retype password: " 2 4 "" 2 21 25 25)
  		reponse=$("${CMD[@]}" 2>&1 >/dev/tty)
      if [[ $? == 1 ]]; then return 1; fi
      if [[ `echo $reponse | grep -Ec ".*[[:space:]].*[[:space:]].*"` -ne 0 ]] ||\
        [[ `echo $reponse | grep -Ec "[\\]"` -ne 0 ]]; then
        __infoBox "${1}" 2 "
  The password can't contain spaces or \\."
      else
  	    pw1=$(echo $reponse | awk -F" " '{ print $1 }')
  			case $pw1 in
  				"" )
  					__infoBox "${1}" 2 "
  The password can't be empty."
  				;;
  				${4} )  # password linux or database
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

  local reponse="" codeRetour="" inputItem="" help="" # champs ou a été actionné le help-button
  pwFirstuser=""; userBdD=""; pwBdD=""; fileSize="513M"; addStorage=""; addAudioPlayer=""; ocDataDir="/var/www/owncloud/data"
	until [[ 1 -eq 2 ]]; do
    # --help-status donne les champs déjà saisis dans $reponse en plus du tag HELP "HELP nom du champs\sasie1\saide2\\saise4\"
    # --default-item "nom du champs" place le curseur sur le champs ou à été pressé le bouton help
		CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --nocancel --help-button --default-item "$inputItem" --help-status --separator "\\" --insecure --mixedform "${2}" 0 0 ${3} "Linux user:" 1 2 "${FIRSTUSER[0]}" 1 28 -16 0 2 "PW Linux user:" 3 2 "$pwFirstuser" 3 28 25 25 1 "OC Database admin:" 5 2 "$userBdD" 5 28 16 15 0 "Password database admin:" 7 2 "$pwBdD" 7 28 25 25 1 "Max files size:" 9 2 "$fileSize" 9 28 6 5 0 "Data directory location:" 11 2 "$ocDataDir" 11 28 25 35 0 "External storage [Y/N]:" 13 2 "$addStorage" 13 28 2 1 0 "AudioPlayer [Y/N]:" 15 2 "$addAudioPlayer" 15 28 2 1 0)
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
      if [[ $pwFirstuser =~ [[:space:]\\] ]] || [[ $pwFirstuser == "" ]]; then
        __helpOC
        pwFirstuser=""
        inputItem="PW Linux user:"
      elif [[ $userBdD =~ [[:space:]\\] ]] || [[ $userBdD == "" ]]; then
        __helpOC
        userBdD=""
        inputItem="OC Database admin:"
      elif [[ $pwBdD =~ [[:space:]\\] ]] || [[ $pwBdD == "" ]]; then
        __helpOC
        pwBdD=""
        inputItem="Password database admin:"
      elif [[ ! $fileSize =~ ^[1-9][0-9]{0,3}[GM]$ ]]; then
        __helpOC
        fileSize="513M"
        inputItem="Max files size:"
      elif [[ $ocDataDir =~ [[:space:]\\] ]] || [[ $ocDataDir == "" ]]; then
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
    fi
  done
}

################################################################################
#       Fonctions principales
########################################

############################################
##  création utilisateur ruTorrent Linux
############################################
__creaUserRuto () {
	# echo " param : ${1} ${2}"
egrep "^sftp" /etc/group > /dev/null
if [[ $? -ne 0 ]]; then
	addgroup sftp
fi

pass=$(perl -e 'print crypt($ARGV[0], "pwRuto")' ${2})
useradd -m -G sftp -p $pass ${1}
if [[ $? -ne 0 ]]; then
	__infoBox "Setting-up rutorrent user" 3 "
Unable to create Linux user ${1}
'useradd' error"
	__msgErreurBox
fi
sed -i "1 a\bash" /home/${1}/.profile

echo "Linux user ${1} created"
echo

mkdir -p /home/${1}/downloads/watch
mkdir -p /home/${1}/downloads/.session
chown -R ${1}:${1} /home/${1}/

echo "Directory/subdirectories /home/${1} created"
echo

#  partie rtorrent __creaUserRuto------------------------------------------------
# incrémenter le port, écrir le fichier témoin
if [ -e $REPWEB/rutorrent/conf/scgi_port ]; then
	port=$(cat $REPWEB/rutorrent/conf/scgi_port)
else 	port=5000
fi

let "port += 1"
echo $port > $REPWEB/rutorrent/conf/scgi_port

# rtorrent.rc
cp $REPLANCE/fichiers-conf/rto_rtorrent.rc /home/${1}/.rtorrent.rc
sed -i 's/<username>/'${1}'/g' /home/${1}/.rtorrent.rc
sed -i 's/scgi_port.*/scgi_port = 127.0.0.1:'$port'/' /home/${1}/.rtorrent.rc

echo "/home/${1}/rtorrent.rc created"
echo

#  fichiers daemon rtorrent
#  créer rtorrent.conf
cp $REPLANCE/fichiers-conf/rto_rtorrent.conf /etc/init/${1}-rtorrent.conf
chmod u+rwx,g+rwx,o+rx  /etc/init/${1}-rtorrent.conf
sed -i 's/<username>/'${1}'/g' /etc/init/${1}-rtorrent.conf

#  rtorrentd.sh modifié   il faut redonner aux users bash
sed -i '/## bash/ a\          usermod -s \/bin\/bash '${1}'' /etc/init.d/rtorrentd.sh
sed -i '/## screen/ a\          su --command="screen -dmS '${1}'-rtd rtorrent" "'${1}'"' /etc/init.d/rtorrentd.sh
sed -i '/## false/ a\          usermod -s /bin/false '${1}'' /etc/init.d/rtorrentd.sh
systemctl daemon-reload
service rtorrentd restart
if [[ $? -eq 0 ]]; then
	echo "rtorrent daemon modified and work well."
	echo
else
	dialog --backtitle "$TITRE" --title "Error message" --prgbox "Issues on running rtorrentd: see wiki on github
https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal" "ps aux | grep -e '^${1}.*rtorrent$'" 8 98
	exit 1
fi
#  fin partie rtorrent  __creaUserRuto-----------------------------------------

#  partie rutorrent -----------------------------------------------------------
# dossier conf/users/userRuto
mkdir -p $REPWEB/rutorrent/conf/users/${1}
cp $REPWEB/rutorrent/conf/access.ini $REPWEB/rutorrent/conf/plugins.ini $REPWEB/rutorrent/conf/users/${1}
cp $REPLANCE/fichiers-conf/ruto_multi_config.php $REPWEB/rutorrent/conf/users/${1}/config.php
sed -i -e 's/<port>/'$port'/' -e 's/<username>/'${1}'/' $REPWEB/rutorrent/conf/users/${1}/config.php
chown -R www-data:www-data $REPWEB/rutorrent/conf/users/${1}

# déactivation du plugin linkcakebox
mkdir -p $REPWEB/rutorrent/share/users/${1}/torrents
mkdir $REPWEB/rutorrent/share/users/${1}/settings
chmod -R 777 $REPWEB/rutorrent/share/users/${1}
echo 'a:2:{s:8:"__hash__";s:11:"plugins.dat";s:11:"linkcakebox";b:0;}' > $REPWEB/rutorrent/share/users/${1}/settings/plugins.dat
chmod 666 $REPWEB/rutorrent/share/users/${1}/settings/plugins.dat
chown -R www-data:www-data $REPWEB/rutorrent/share/users/${1}

echo "Directory users/${1} created on ruTorrent"
echo

__creaUserRutoPasswd ${1} ${2}   # insert/util_apache.sh ne renvoie rien

# modif pour sftp / sécu sftp __creaUserRuto  ---------------------------------
# pour user en sftp interdit le shell en fin de traitement; bloque le daemon
usermod -s /bin/false ${1}
# pour interdire de sortir de /home/user  en sftp
chown root:root /home/${1}
chmod 0755 /home/${1}

# modif sshd.config  -------------------------------------------------------
sed -i 's/AllowUsers.*/& '${1}'/' /etc/ssh/sshd_config
sed -i 's|^Subsystem sftp /usr/lib/openssh/sftp-server|#  &|' /etc/ssh/sshd_config   # commente
# pour bloquer les utilisateurs supplémentaires
if [[ `cat /etc/ssh/sshd_config | grep "Subsystem  sftp  internal-sftp"` == "" ]]; then
	echo -e "Subsystem  sftp  internal-sftp\nMatch Group sftp\n ChrootDirectory %h\n ForceCommand internal-sftp\n AllowTcpForwarding no" >> /etc/ssh/sshd_config
fi
service sshd restart > /dev/null
echo "SFTP security ok" # seulement accès a /home/${1}
}   #  fin __creaUserRuto

#################################################
##  ajout utilisateur sous menu et traitements
#################################################
__ssmenuAjoutUtilisateur() {
local typeUser=""; local codeSortie=1

until [[ 1 -eq 2 ]]; do
  # Create a user:" 22 70 4 \
	CMD=(dialog --backtitle "$TITRE" --title "Add a user" --menu "

- A ruTorrent user can only be created with a Linux user

Create a user:" 18 65 2 \
	1 "Linux + ruTorrent"
	2 "Users list")

	typeUser=$("${CMD[@]}" 2>&1 > /dev/tty)
	if [[ $? -eq 0 ]]; then
		if [[ $typeUser -ne 2 ]]; then
			__saisieTexteBox "Creating a user" "
Input the name of new user$R
Neither space nor special characters$N"
			if [[ $? -eq 1 ]]; then   # 1 si bouton cancel
				typeUser=""
			else
				__userExist $__saisieTexteBox    # insert/util_apache.sh renvoie userL userR
			fi
		fi
		case $typeUser in
			1 )  #  créa linux ruto
				if [[ $userL -eq 0 ]] || [[ $userR -eq 0 ]]; then
					__infoBox "Creating a user" 2 "
The $__saisieTexteBox user already exists"
				else
					__ouinonBox "Creating Linux/ruTorrent user" "- The new user will have SFTP access with his/her name and password,
  same port as all users.
- His/her access is limited at /home directory.
- No access to ssh$R
Confirm $__saisieTexteBox as new user?"
					if [[ $__ouinonBox -eq 0 ]]; then
						__saisiePwBox "User $__saisieTexteBox setting-up" "
Input user password" 0 0
						clear; __creaUserRuto $__saisieTexteBox $__saisiePwBox; sleep 2
						__infoBox "Creating Linux/ruTorrent user" 3 "Setting-up completed
$__saisieTexteBox user created
Password $__saisiePwBox"
					fi
				fi
			;;
			2 )
				__listeUtilisateurs
			;;
		esac
	else  # === si sortie du menu -ne 0
		break
	fi
done
}   #  fin __ssmenuAjoutUtilisateur()


#####################################################
##  Suppression d'un utilisateur linux et rutorrent
#####################################################
__suppUserRuto() {
 ### traitement sur sshd, dossier user dans rutorrent, rtorrentd.sh, user linux et son home
 # ${1} == $__saisieTexteBox
 clear
  # suppression du user allowed dans sshd_config
  sed -i 's/'${1}' //' /etc/ssh/sshd_config
  service sshd restart

  __suppUserRutoPasswd ${1}

  # dossier rutorrent/conf/users/userRuto et rutorrent/share/users/userRuto
  rm -r $REPWEB/rutorrent/conf/users/${1}
  echo "Directory conf/users/${1} on ruTorrent deleted"
  echo
  rm -r $REPWEB/rutorrent/share/users/${1}
  echo "Directory share/users/${1} on ruTorrent deleted"
  echo

  # modif de rtorrentd.sh (daemon)
  sed -i '/.*'${1}.*'/d' /etc/init.d/rtorrentd.sh
  rm /etc/init/${1}-rtorrent.conf

  systemctl daemon-reload
  service rtorrentd restart
  if [[ $? -eq 0 ]]; then
  	echo "Daemon rtorrent modified and work well."
  	echo
  else
  	dialog --backtitle "$TITRE" --title "Error message" --prgbox "Issues on running rtorrentd service: See wiki on github
https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal" "ps aux | grep -e '^${1}.*rtorrent$'" 8 98
  	__msgErreurBox
  fi
  # suppression fichier témoin de screen
  rm -r /var/run/screen/S-${1}
  # Suppression du home et suppression user linux (-f le home est root:root)
  userdel -fr ${1}
  echo "Linux user and his/her /home/${1} deleted"
}  # fin __suppUserRuto

######################################################
##  supprimer utilisateur sous menu et traitements
######################################################
__ssmenuSuppUtilisateur() {
  local typeUser=""; local codeSortie=1

  until [[ 1 -eq 2 ]]; do
    # Delete a user:" 22 70 4 \
  	CMD=(dialog --backtitle "$TITRE" --title "Delete a user" --menu "
What user kind do you want to remove?

- If a ruTorrent user is deleted, his Linux namesake
will also be deleted.

Delete a user:" 18 65 2 \
  1 "Linux + ruTorrent"
  2 "Users list")

   typeUser=$("${CMD[@]}" 2>&1 > /dev/tty)
    if [[ $? -eq 0 ]]; then
      #	 $type
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
  	      __ouinonBox "Delete a Linux user" "Warning the user's /home directory
will be deleted. You confirm removing $__saisieTexteBox?"
  	      if [[ $__ouinonBox -eq 0 ]]; then
  		      if [[ $userR -eq 0 ]] && [[ $userL -eq 0 ]] && [ "${FIRSTUSER[0]}" != "$__saisieTexteBox" ]; then
      	    #  $ __saisieTexteBox
  			      __suppUserRuto $__saisieTexteBox; sleep 2
  			      __infoBox "Delete a Linux user" 3 "Treatment completed
Linux/ruTorrent user$R $__saisieTexteBox$N deleted"
  		      else
  			      __infoBox "Delete a Linux/ruTorrent user" 3 "
$__saisieTexteBox$R is not a Linux/ruTorrent user or$N
$__saisieTexteBox$R is the main user"
  			      #sortie case $typeUser et if  retour ss menu
  		      fi
  	      fi
        ;;
        2)
  	      __listeUtilisateurs
        ;;
      #  fin $ __saisieTexteBox
  	  esac
    else
  	  break
    fi
  done
}

####################
##  Changement pw
####################

__changePW() {
local typeUser=""; local user=""; local codeSortie=1

until [[ 1 -eq 2 ]]; do
	CMD=(dialog --backtitle "$TITRE" --title "Change User Password" --menu "




	What user kind do you want change?" 18 65 3 \
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
						passwd $__saisieTexteBox; sortie=$?
						sleep 2
						if [[ $sortie -ne 0 ]]; then
							__infoBox "Linux password Inputed" 2 "An error occurred, password unchanged."
						else
							__infoBox "Linux password Inputed" 2 "User password $__saisieTexteBox changed
Treatment completed"
						fi
					else
						__infoBox "Change Password" 3 "$__saisieTexteBox is not a Linux user"
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
							__infoBox "Change Password" 3 "An error occurred, password unchanged."
						else
							__infoBox "Change Password" 2 "User password $__saisieTexteBox changed
Treatment completed"
						fi
					else
						__infoBox "Change Password" 2 "$__saisieTexteBox is not a ruTorrent user"
					fi
				fi
			;;
			[3] )
				__listeUtilisateurs
			;;
		esac
	else
		break
	fi
done
}  #  fin __changePW


######################################################
##  ajout vpn, téléchargement du script
######################################################
__vpn() {
  # $REPInstVpn == $REPLANCE and readonly
  clear
  if [[ -e $REPInstVpn/openvpn-install.sh ]]; then
    rm $REPInstVpn/openvpn-install.sh
  fi
  wget https://raw.githubusercontent.com/Angristan/OpenVPN-install/master/openvpn-install.sh -O $REPInstVpn/openvpn-install.sh
  chmod +x $REPInstVpn/openvpn-install.sh
  export ERRVPN="" NOMCLIENTVPN=""
  sed -i "/^#!\/bin\/bash/ a\__myTrap() {\nERRVPN=\$?\nNOMCLIENTVPN=\$CLIENT\ncd $REPInstVpn\n$REPInstVpn\/HiwsT-util.sh\n}\ntrap '__myTrap' EXIT" $REPLANCE/openvpn-install.sh
# __myTrap() {
# ERRVPN=$?
# NOMCLIENTVPN=$CLIENT
# cd /home/patrick/Bureau/HiwsT
# /home/patrick/Bureau/HiwsT/HiwsT-util.sh
# }
# trap '__myTrap' EXIT
. $REPLANCE/openvpn-install.sh
}


############################
##  Menu principal
############################
__menu() {
choixMenu=""
item=1
until [[ 1 -eq 2 ]]; do
	CMD=(dialog --backtitle "$TITRE" --title "Main menu" --cancel-label "Exit" --default-item "$item" --menu "

 To be used after installation with HiwsT

 Your choice:" 22 70 10 \
	1 "Create a user" \
	2 "Change user password" \
	3 "Delete a user" \
	4 "List existing users" \
	5 "Install/uninstall OpenVPN, a openVPN user" \
  6 "Install ownCloud" \
	7 "Firewall" \
	8 "Restart rtorrent manually" \
	9 "Diagnostic" \
	10 "Reboot the server")

	choixMenu=$("${CMD[@]}" 2>&1 > /dev/tty)
	if [[ $? -eq 0 ]]; then
		case $choixMenu in
			1 )  ################ ajouter user  ################################
				__ssmenuAjoutUtilisateur
			;;
			2 )
				__changePW
			;;
			3 ) ################# supprimer utilisateur  ############################
				__ssmenuSuppUtilisateur
			;;
			4 )  ################# liste utilisateurs #######################
				__listeUtilisateurs
			;;
			5 )  ######### VPN  ###################################
        if [[ ! $(iptables -L -n | grep -E 'REJECT|DROP') ]]; then
          __ouinonBox "openVPN" "$R$BO  Turn ON the firewall BEFORE
  installing the VPN !!!$N"
          if [[ $__ouinonBox -eq 0 ]]; then
            item=7
            continue
            #. $REPLANCE/insert/util_firewall.sh
          else
            continue
          fi
        fi
				__ouinonBox "openVPN" "
				VPN installed with the$R Angristan script$N (MIT  License),
				with his kind permission. Thanks to him

				github repository: https://github.com/Angristan/OpenVPN-install
				Angristan's blog: https://angristan.fr/installer-facilement-serveur-openvpn-debian-ubuntu-centos/

				Excellent security-enhancing script, allowing trouble-free installation
				on Debian, Ubuntu, CentOS et Arch Linux servers.
				Do not reinvent the wheel (less well), that's the Oppen Source
				$R $BO
				-----------------------------------------------------------------------------------------
				|  - To the question 'Tell me a name for the client cert'
				|    Give the name of the linux user to which the vpn is intended.
				|  - If you restart this script you can add or remove
				|    a user, uninstall the VPN.
				|  - The configuration file will be located in the corresponding /home if his name exist.
				------------------------------------------------------------------------------------------$N" 22 100
				if [[ $__ouinonBox -eq 0 ]]; then __vpn; fi
        item=1
			;;
      6 )  ###################### ownCloud #############################
        pathOCC=$(find /var -name occ 2>/dev/null)
	      if [[ -n $pathOCC ]]; then
          __infoBox "Install ownCloud" 3 "
  ownCloud is already installed
          "
          continue
        fi
        __saisieOCBox "ownCloud setting" $R"Consult the help$N" 15   # lignes ss-boite

        . $REPLANCE/insert/util_owncloud.sh
        varLocalhost="localhost"  # pour $I$varLocalhost dans __messageBox
        varOwnCloud="owncloud"
        __messageBox "ownCloud install" "Treatment completed.
Your ownCloud website https://$HOSTNAME/owncloud or
https://$IP/owncloud
Accept the Self Signed Certificate and the exception for this certificate!

${BO}Note that $N $I${FIRSTUSER[0]}$N$BO and her/his password is your account and ownCloud administrator account.
The administrator of mysql database $varOwnCloud is$N $I$userBdD$N

This information is added to the file $REPUL/HiwsT/RecapInstall.txt"
        cat << EOF >> $REPUL/HiwsT/RecapInstall.txt

Pour accéder a votre cloud privé :
  https://$HOSTNAME/owncloud ou $IP/owncloud
  Utilisateur (et administrateur) : ${FIRSTUSER[0]}
  Mot de passe : $pwFirstuser
  Administrateur de la base de donnée OC : $userBdD
  Mot de passe : $pwBdD
EOF
      ;;
			7 )  #####################  firewall  ############################
				__messageBox "Firewall and ufw" "


\ZrWarning !!!\Zn The following setting only takes into account the installations execute with HiwsT" 12 75

				. $REPLANCE/insert/util_firewall.sh
        if [[ $item -eq 7 ]]; then item=5; fi # si on vient de openvpn on y retourne
			;;
			8 )  ########################  Relance rtorrent  ######################
				__infoBox "Message" 1 "

			 	  Restart

		rtorrentd daemon " 10 35
				clear
				service rtorrentd restart
				service rtorrentd status
				sleep 3
			;;
			9 )  ################# Diagnostiques ###############################
				. $REPLANCE/insert/util_diag.sh
			;;
			10 )  ###########################  REBOOT  #######################
				__ouinonBox "$R $BO Server Reboot$N"
				if [[ $__ouinonBox -eq 0 ]]; then
					clear
					sleep 2
					reboot
				fi
			;;
		esac
	else
		break
	fi
done

}   # fin menu

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

service nginx status > /dev/null
sortieN=$?  # 0 actif, 1 erreur == inactif
service apache2 status > /dev/null
sortieA=$?
if [[ $sortieN -eq 0 ]] && [[ $sortieA -eq 0 ]]; then
	echo
	echo "Apache2 and nginx are active. Apache2 must be the http server"
  read -p "To continue [Enter] to stop [Ctrl-c] "
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

#  chargement des f() apache
SERVEURHTTP="apache2"
. $REPLANCE/insert/util_apache.sh
. $REPLANCE/insert/util_listeusers.sh

################################################################################
#  debian ou ubuntu ?  pour ownCloud
nameDistrib=$(lsb_release -si)  # "Debian" ou "Ubuntu"

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
# # si owncloud est installé saise id et pw
# pathOCC=$(find /var -name occ 2>/dev/null)
# if [[ -n $pathOCC ]]; then
#   __saisieBdDBox "ownCloud MySQL Database", "ownCloud is installed, give me the name and password of the ownCloud database administrator", 3
#   if [[ $? == 1 ]]; then  # si esc sur __saisieBdDBox
#     __infoBox "${1}" 3 "
# You will not be able to see ownCloud users."
#   fi
# fi


################################################################################
#  boucle menu / sortie
__menu

clear
echo
echo "Au revoir"  # french touch ;)
echo
