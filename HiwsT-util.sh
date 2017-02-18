#!/bin/bash

# Enemble d'utilitaires pour la gestion des utilisateurs linux, rutorrent et cakebox
# L'ajout ou la suppression d'utilisateurs
# Changement de mot de passe
# ....

# Version 1.0
# https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-


REPWEB="/var/www/html"
REPAPA2="/etc/apache2"
REPNGINX="/etc/nginx"
REPLANCE=$(echo `pwd`)
serveurHttp=""
# utilisateur linux principal dans pass1
firstUserLinux=$(cat pass1)
LOGUSER=$(logname)


########################################
#       Fonctions utilitaires
########################################

__ouinonBox() {    # param : titre, texte  sortie $__ouinonBox 0 ou 1
	CMD=(dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "${1}"  --yesno "
${2}" 0 0 )
	choix=$("${CMD[@]}" 2>&1 >/dev/tty)
	__ouinonBox=$?
}    #  fin ouinon

__entInvalBox() {    # param : titre
	CMD=(dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "${1}" --sleep 2 --infobox "
Votre entrée n'est pas valide" 0 0)
	choix=$("${CMD[@]}" 2>&1 >/dev/tty)
}

# __listeUtilisateurs() {
# 	. $REPLANCE/insert/util_listeusers.sh
# }

__messageBox() {   # param : titre texte
			CMD=(dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "${1}" --msgbox "${2}" 0 0)
			choix=$("${CMD[@]}" 2>&1 >/dev/tty)
}

__infoBox() {   # param : titre sleep texte
			CMD=(dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "${1}" --sleep ${2} --infobox "${3}" 0 0)
			choix=$("${CMD[@]}" 2>&1 >/dev/tty)
}

__msgErreurBox() {
	__messageBox "Message d'erreur" "

	Consulter le wiki

  https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
	exit 1
}  # fin messageErreur

__saisieTexteBox() {   # param : titre, texte
	local tmp=""
	until [[ $tmp == "ok" ]]; do
		CMD=(dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "${1}" --nocancel --help-button --help-label "liste users" --max-input 15 --inputbox "${2}" 0 0)
		__saisieTexteBox=$("${CMD[@]}" 2>&1 >/dev/tty)

		if [ $? == 2 ]; then  # bouton "liste" (help) renvoie code sortie 2
			__listeUtilisateurs
			# dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "Liste utilisateurs" --textbox $REPLANCE/liste 0 0
			return 1 ; break  # l'appelle de la f() boucle jusqu'à code sortie == 0
		fi
		if [[ $__saisieTexteBox =~ ^[a-zA-Z0-9]{2,15}$ ]]; then
			tmp="ok"
		else
			__infoBox "Vérification saisie" 3 "
Uniquement des caractères alphanumériques
Entre 2 et 15 caractères"
		fi
	done
}

__saisiePwBox() {  # param : titre, texte, nbr de ligne sous boite
  local tmp=""; local pw=1""; local pw2=""; local codeSortie=""; local reponse=""
	until [[ $tmp == "ok" ]]; do
		CMD=(dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "${1}" --insecure --nocancel --passwordform "${2}" 0 0 ${3} "Mot de passe : " 2 4 "" 2 25 25 25 "Resaisissez : " 4 4 "" 4 25 25 25 )
		reponse=$("${CMD[@]}" 2>&1 >/dev/tty)

	    pw1=$(echo $reponse | awk -F" " '{ print $1 }')
	    pw2=$(echo $reponse | awk -F" " '{ print $2 }')

			case $pw1 in
				"" )
					__infoBox ${1} 2 "
Le mot de passe ne peut pas être vide."
				;;
				$pw2 )
					__saisiePwBox=$pw1
					tmp="ok"
				;;
				* )
					__infoBox ${1} 2 "
Les 2 saisies ne sont pas identiques." 0 0
				;;
			esac
			if [[ `echo $pw1 | grep -E "[ \\]"` -ne 0 ]]; then
				__infoBox "${1}" 2 "
Le mot de passe ne peut pas contenir d'espace ou de \\."
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
egrep "^sftp" /etc/group > /dev/null
if [[ $? -ne 0 ]]; then
	addgroup sftp
fi

pass=$(perl -e 'print crypt($ARGV[0], "pwRuto")' ${2})
useradd -m -G sftp -p $pass ${1}
if [[ $? -ne 0 ]]; then
	__infoBox "Création utilisateur ruTorrent" 3 "
Impossible de créer l'utilisateur ruTorrent ${1}
Erreur sur 'useradd'"
	__msgErreurBox
fi
sed -i "1 a\bash" /home/${1}/.profile  #ubuntu, debian ?

echo "Utilisateur linux ${1} créé"
echo

mkdir -p /home/${1}/downloads/watch
mkdir -p /home/${1}/downloads/.session
chown -R ${1}:${1} /home/${1}/

echo "Répertoire/sous-répertoires /home/${1} créé"
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

echo "/home/${1}/rtorrent.rc créé"
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
	echo "Daemon rtorrent modifié et fonctionne."
	echo
else
	dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "Message d'erreur" --prgbox "Problème au lancement du service rtorrentd : ps aux | grep -e '^utilisateur.*rtorrent$'
Consulter le wiki
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

echo "Dossier users/${1} sur ruTorrent crée"
echo

__creaUserRutoPasswd ${1} ${2}   # insert/util_apache.sh et util_nginx ne renvoie rien

# modif pour sftp / sécu sftp __creaUserRuto  ---------------------------------
# pour user en sftp interdit le shell en fin de traitement; bloque le daemon
usermod -s /bin/false ${1}
# pour interdire de sortir de /home/user  en sftp
chown root:root /home/${1}
chmod 0755 /home/${1}

# modif sshd.config  -------------------------------------------------------
sed -i 's/AllowUsers.*/& '${1}'/' /etc/ssh/sshd_config
sed -i 's|^Subsystem sftp /usr/lib/openssh/sftp-server|#  &|' /etc/ssh/sshd_config   # commente
if [[ `cat /etc/ssh/sshd_config | grep "Subsystem  sftp  internal-sftp"` == "" ]]; then
	echo -e "Subsystem  sftp  internal-sftp\nMatch Group sftp\n ChrootDirectory %h\n ForceCommand internal-sftp\n AllowTcpForwarding no" >> /etc/ssh/sshd_config
fi
service sshd restart > /dev/null
echo "Sécurisation SFTP faite" # seulement accès a /home/${1}
}   #  fin __creaUserRuto


####################################
##  Création utilisateur Cakebox
####################################
 __creaUserCake() {
# - copier conf/user.php modif rep à scanner
cp $REPWEB/cakebox/config/default.php.dist $REPWEB/cakebox/config/${1}.php
sed -i "s|\(\$app\[\"cakebox.root\"\].*\)|\$app\[\"cakebox.root\"\] = \"/home/${1}/downloads/\";|" $REPWEB/cakebox/config/${1}.php
sed -i "s|\(\$app\[\"player.default_type\"\].*\)|\$app\[\"player.default_type\"\] = \"vlc\";|" $REPWEB/cakebox/config/${1}.php
chown -R www-data:www-data $REPWEB/cakebox/config
echo
echo "cakebox/config/${1}.php créé"
echo

__creaUserCakeConfSite ${1}
__creaUserCakePasswd ${1} ${2}

# Réactiver le plugin linkcakebox
rm $REPWEB/rutorrent/share/users/${1}/settings/plugins.dat
}  # fin __creaUserCake


#################################################
##  ajout utilisateur sous menu et traitements
#################################################
__ssmenuAjoutUtilisateur() {
local typeUser=""; local codeSortie=1

until [[ 1 -eq 2 ]]; do
	CMD=(dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "Ajouter un utilisateur" --menu "Quel type d'utilisateur voulez-vous ajouter ?

- Un utilisateur ruTorrent ne peut être créé qu'avec un utilisateur Linux
- Un utilisateur Cakebox ne peut être crtéé que si un homonyme ruTorrent existe déjà ou est créé dans la foulée

 Créer un utilisateur :" 22 70 4 \
	1 "Linux + ruTorrent"
	2 "Linux + ruTorrent + Cakebox"
	3 "Cakebox"
	4 "Liste des utilisateurs")

	typeUser=$("${CMD[@]}" 2>&1 > /dev/tty)
	if [[ $? -eq 0 ]]; then
		if [[ $typeUser -ne 4 ]]; then
			until [[ $codeSortie -eq 0 ]]; do
		#  boucle saise nom user
			__saisieTexteBox "Création d'un utilisateur" "
Saisissez le nom du nouvel utilisateur
Ni espace, ni caractères spéciaux"
			codeSortie=$?
		done  # fin boucle sur __saisieTexteBox
		codeSortie=1
		__userExist $__saisieTexteBox    # insert/util_apache.sh et util_nginx.sh renvoie userL userR userC
		echo $__saisieTexteBox
	fi
		case $typeUser in
			1 )  #  créa linux ruto
				if [[ $userL -eq 0 ]] || [[ $userR -eq 0 ]] || [[ $userC -eq 0 ]]; then
					__infoBox "Création d'un utilisateur" 2 "
Il existe déjà un utilisateur $__saisieTexteBox"
				else
					__ouinonBox "Création utilisateur Linux/ruTorrent" "- Le nouvel utilisateur aura un accès SFTP avec son nom et mot de passe, même port que les autres utilisateurs.
- Il sera limité à son répertoire /home.
- Pas d'accès ssh
Vous confirmez $__saisieTexteBox comme nouvel utilisateur ?"
					if [[ $__ouinonBox -eq 0 ]]; then
						__saisiePwBox "Création d'un utilisateur ${1}" "
Saisissez d'un mot de passe utilisateur" 0 0
						clear; __creaUserRuto $__saisieTexteBox $__saisiePwBox; sleep 2
						__infoBox "Création utilisateur Linux/ruTorrent" 3 "Traitement terminé
Utilisateur $__saisieTexteBox crée
Mot de passe $__saisiePwBox"
					fi
				fi
			;;
			2 )  #  créa linux ruto cake
				if [[ $userL -eq 0 ]] || [[ $userR -eq 0 ]]; then
					# pas de userlinux ou existe usercake NON
					__infoBox "Création d'un utilisateur Linux/ruTorrent/Cakebox" 2 "
$__saisieTexteBox est déjà un utilisateur Linux ou
$__saisieTexteBox est déjà un utilisatreur ruTorrent." 0 0
				elif [[ $userC -eq 0 ]]; then
					# existe userl  pas de userrutorrent  pas de userc NON
					__infoBox "Création d'un utilisateur Linux/ruTorrent/Cakebox" 2 "
$__saisieTexteBox est déjà un utilisateur Cakebox" 0 0
				else
					# existe userl exite userr pas de userc OUI
					__ouinonBox "Création utilisateur Linux/ruTorrent/Cakebox" "- Le nouvel utilisateur aura le même nom et Mot de passe pour les 3 accès.
- Il aura un accès SFTP avec le même nom et mot de passe, même port que les autres utilisateurs.
- Il sera limité à son répertoire /home.
- Pas d'accès ssh
Vous confirmez $__saisieTexteBox comme nouvel utilisateur ?"
					if [[ $__ouinonBox -eq 0 ]]; then
						# saisie PW d'un utilisateur
						__saisiePwBox "Création d'un nouvel utilisateur" "
Saisissez d'un mot de passe utilisateur" 0 0

						clear; __creaUserRuto $__saisieTexteBox $__saisiePwBox; sleep 2
						__creaUserCake $__saisieTexteBox $__saisiePwBox; sleep 2
						__infoBox "Création utilisateur Linux/ruTorrent/Cakebox" 3 "Traitement terminé
Utilisateur $__saisieTexteBox crée
Mot de passe $__saisiePwBox"
					fi
				fi
			;;
			3 )  #  créa cake
				if [[ $userC -eq 0 ]]; then
					__infoBox "Création d'un utilisateur Linux/ruTorrent/Cakebox" 2 "
$__saisieTexteBox est déjà un utilisateur Cakebox" 0 0
				elif [[ $userL -ne 0 ]] && [[ $userR -ne 0 ]]; then
					__infoBox "Création d'un utilisateur Linux/ruTorrent/Cakebox" 2 "
$__saisieTexteBox n'a pas d'homonyme Linux et ruTorrent" 0 0
				else
					echo $__saisieTexteBox
					__ouinonBox "Création utilisateur Cakebox" "Le nouvel utilisateur ne pourra scanner que son répertoire de téléchargement.
Vous confirmez "$__saisieTexteBox" comme nouvel utilisateur ?"
					if [[ $__ouinonBox -eq 0 ]]; then
						# saisie PW d'un utilisateur
						__saisiePwBox "Création d'un nouvel utilisateur" "
Saisissez d'un mot de passe utilisateur" 0 0

						clear; __creaUserCake $__saisieTexteBox $__saisiePwBox; sleep 2
						__infoBox "Création utilisateur Cakebox" 3 "Traitement terminé
Utilisateur $__saisieTexteBox crée
Mot de passe $__saisiePwBox"
					fi
				fi
			;;
			[4] )
				__listeUtilisateurs
			;;
		esac
	else
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
echo "Dossier conf/users/${1} sur ruTorrent supprimé"
echo
rm -r $REPWEB/rutorrent/share/users/${1}
echo "Dossier share/users/${1} sur ruTorrent supprimé"
echo

# modif de rtorrentd.sh (daemon)
sed -i '/.*'${1}.*'/d' /etc/init.d/rtorrentd.sh
rm /etc/init/${1}-rtorrent.conf

systemctl daemon-reload
service rtorrentd restart
if [[ $? -eq 0 ]]; then
	echo "rtorrent en daemon modifié et fonctionne."
	echo
else
	dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "Message d'erreur" --prgbox "Problème au lancement du service rtorrentd : ps aux | grep -e '^utilisateur.*rtorrent$'
Consulter le wiki
https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal" "ps aux | grep -e '^${1}.*rtorrent$'" 8 98
	__msgErreurBox
fi
# Suppression du home et suppression user linux (-f le home est root:root)
userdel -fr ${1}
echo "Utilisateur linux et /home/${1} supprimé"
}  # fin __suppUserRuto

############################################
##  Suppression d'un utilisateur Cakebox
############################################
__suppUserCake() {
	# ${1} == $__saisieTexteBox
clear
__suppUserCakePasswd ${1}   # insert/util_apache.sh et util_nginx
__suppUserCakeConfSite ${1}   # insert/util_apache.sh et util_nginx

# supprimer le fichier conf/user.php
rm $REPWEB/cakebox/config/${1}.php
echo
echo "cakebox/config/${1}.php supprimé"
echo
}  # fin __suppUserCake

######################################################
##  supprimer utilisateur sous menu et traitements
######################################################
__ssmenuSuppUtilisateur() {
local typeUser=""; local codeSortie=1

until [[ 1 -eq 2 ]]; do
	CMD=(dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "Supprimer un utilisateur" --menu "Quel type d'utilisateur voulez-vous supprimer ?

- Si un utilisateur ruTorrent est supprimé, son homonyme Linux
le sera aussi.
- Si un utilisateur Cakebox est supprimé, ses homonymes Linux et ruTorrent seront conservés

 Supprimer un utilisateur :" 22 70 3 \
	1 "Linux + ruTorrent + Cakebox"
	2 "Cakebox"
	3 "Liste des utilisateurs")

	typeUser=$("${CMD[@]}" 2>&1 > /dev/tty)
	if [[ $? -eq 0 ]]; then
		#	----------------------------------------------------------$ type
		if [[ $typeUser -ne 3 ]]; then
			until [[ $codeSortie -eq 0 ]]; do
				#  boucle saisie nom user
				__saisieTexteBox "Suppression d'un utilisateur" "
Saisissez le nom de l'utilisateur :"
				codeSortie=$?
			done  # fin boucle sur __saisieTexteBox
			codeSortie=1
			__userExist $__saisieTexteBox  # insert/util_apache.sh et util_nginx.sh renvoie userL userR userC
		fi
		# ---------------------------------------------------- $type $userL R C $__saisieTexteBox
		case $typeUser in
			1 ) #   suppression utilisateur Linux/ruto/cake ----------------
				__ouinonBox "Suppression d'un utilisateur Linux" "ATTENTION le répertoire /home
de l'utilisateur va être supprimé. Vous confirmez la suppression de $__saisieTexteBox ?"
				if [[ $__ouinonBox -eq 0 ]]; then
					if [[ $userR -eq 0 ]] && [[ $userL -eq 0 ]] && [ $LOGUSER != $__saisieTexteBox ] && [[ $userC -eq 0 ]]; then
			    	#  --------------------------------------------------------$ __saisieTexteBox
						__suppUserRuto $__saisieTexteBox; sleep 2
						__suppUserCake $__saisieTexteBox; sleep 2
						__infoBox "suppression d'un utilisateur Linux" 3 "Traitement terminé
Utilisateur $__saisieTexteBox pour Linux/ruTorrent/Cakebox supprimé"
					else
						__infoBox "Suppression d'un utilisateur ruTorrent/Linux" 3 "
$__saisieTexteBox n'est pas un utilisateur Linux/ruTorrent/Cakebox
$__saisieTexteBox est l'utilisateur principal"
						#sortie case $typeUser et if  retour ss menu
					fi
				fi
	      #  -----------------------------------------------------------fin
			;;
			2)
				__ouinonBox "Suppression d'un utilisateur Cakebox" "
Vous confirmez la suppression de $__saisieTexteBox ?"
				if [[ $__ouinonBox -eq 0 ]]; then
					if [[ $userC -eq 0 ]] && [ $__saisieTexteBox != $LOGUSER ]; then
						__suppUserCake $__saisieTexteBox; sleep 2
						__infoBox "suppression d'un utilisateur Cakebox" 3 "Traitement terminé
Utilisateur $__saisieTexteBox supprimé"
					else
						__infoBox "Suppression d'un utilisateur Cakebox" 3 "
$__saisieTexteBox n'est pas un utilisateur Cakebox ou
$__saisieTexteBox est l'utilisateur principal"
						# sortie case $typeUser et if
					fi
				fi
			;;
			3)
				__listeUtilisateurs
			;;
			#-----------------------------------------------fin---$ __saisieTexteBox
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
local typeUser=""; local user=""; local tmp=""; local codeSortie=1

until [[ 1 -eq 2 ]]; do
	CMD=(dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "Changer un mot de passe utilisateur" --menu "




	Quel type d'utilisateur voulez-vous modifier ?" 22 70 4 \
	1 "Linux"
	2 "ruTorrent"
	3 "Cakebox"
	4 "Liste des utilisateurs")

	typeUser=$("${CMD[@]}" 2>&1 > /dev/tty)
	if [[ $? -eq 0 ]]; then
		case $typeUser in
			1 )   ###  utilisateur Linux
				until [[ $codeSortie -eq 0 ]]; do
					#  boucle après affichage de la liste des users
					__saisieTexteBox "Modification mot de passe" "
Saisissez un nom d'utilisateur Linux
Mot de passe Linux valable aussi pour sftp !!!"
					codeSortie=$?
				done  # fin boucle sur __saisieTexteBox
				codeSortie=1
				# user linux    idem apache et nginx
				clear
				egrep "^$__saisieTexteBox:" /etc/passwd >/dev/null
				if [[ $? -eq 0 ]]; then
					passwd $__saisieTexteBox; sortie=$?
					sleep 2
					if [[ $sortie -ne 0 ]]; then
						__infoBox "Saisie mot de passe Linux" 2 "Une erreur c'est produite, mot de passe inchangé."
					else
						__infoBox "Saisie mot de passe Linux" 2 "Modification mot de passe de l'utilisateur $__saisieTexteBox
Traitement terminé"
					fi
				else
						__infoBox "Modification mot de passe" 3 "$__saisieTexteBox n'est pas un utilisateur Linux"
				fi
			;;
			[2] )   ###  utilisateur ruTorrent
				until [[ $codeSortie -eq 0 ]]; do
					#  boucle après affichage de la liste des users
					__saisieTexteBox "Modification mot de passe" "
Saisissez un nom d'utilisateur ruTorrent"
					codeSortie=$?
				done  # fin boucle sur __saisieTexteBox
				codeSortie=1
					# user ruTorrent ?
					__userExist $__saisieTexteBox  # insert/util_apache.sh et util_nginx
					if [[ $userR -eq 0 ]]; then  # $userR sortie de __userExist 0 ou erreur
						__saisiePwBox "Modification mot de passe ruTorrent" "Utilisateur $__saisieTexteBox" 4
						clear
						__changePWRuto $__saisieTexteBox $__saisiePwBox  # insert/util_apache.sh et util_nginx, renvoie $sortie
						sortie=$?
						sleep 2
						if [[ $sortie -ne 0 ]]; then
							__infoBox "Saisie mot de passe" 3 "une erreur c'est produite"
						else
							__infoBox "Saisie mot de passe" 2 "Modification mot de passe de l'utilisateur $__saisieTexteBox
Traitement terminé"
						fi
					else
						__infoBox "Modification mot de passe" 2 "$__saisieTexteBox n'est pas un utilisateur ruTorrent"
					fi
			;;
			[3] )   ###  utilisateur cakebox
				until [[ $codeSortie -eq 0 ]]; do
					#  boucle après affichage de la liste des users
					__saisieTexteBox "Modification mot de passe" "
Saisissez un nom d'utilisateur Cakebox"
					codeSortie=$?
				done  # fin boucle sur __saisieTexteBox
				codeSortie=1
				# user cakebox ?
				__userExist $__saisieTexteBox  # insert/util_apache.sh et util_nginx
				if [[ $userC -eq 0 ]]; then   # $userC sortie de __userExist 0 ou erreur
					__saisiePwBox "Modification mot de passe Cakebox" "Utilisateur $__saisieTexteBox" 4
					clear
					__changePWCake $__saisieTexteBox $__saisiePwBox   # insert/util_apache.sh  renvoie $sortie
					sortie=$?
					sleep 2
					if [[ $sortie != 0 ]]; then
						__infoBox "Saisie mot de passe" 3 "une erreur c'est produite"
					else
						__infoBox "Saisie mot de passe" 2 "Modification mot de passe de l'utilisateur $__saisieTexteBox
Traitement terminé"
					fi
				else
					__infoBox "Modification mot de passe" 2 "$__saisieTexteBox n'est pas un utilisateur Cakebox"
				fi
			;;
			[4] )
				__listeUtilisateurs
			;;
		esac
	else
		break
	fi
done
}  #  fin __changePW


######################################################
##  ajout vpn téléchargement du script
######################################################
__vpn() {
	clear
	if [[ -e $REPLANCE/openvpn-install.sh ]]; then
		rm $REPLANCE/openvpn-install.sh
	fi
	wget https://raw.githubusercontent.com/Angristan/OpenVPN-install/master/openvpn-install.sh
	chmod +x $REPLANCE/openvpn-install.sh
	sed -i "/#!\/bin\/bash/ a\trap 'sleep 4;"$REPLANCE"\/HiwsT-util.sh' EXIT" $REPLANCE/openvpn-install.sh
 #trap '$REPLANCE/HiwsT-util.sh' EXIT
. $REPLANCE/openvpn-install.sh
}


############################
##  Menu principal
############################
__menu() {
local tmp=""; choixMenu=""
until [[ $tmp == "ok" ]]; do
	CMD=(dialog --backtitle "Utilitaire HiwsT : rtorrent - ruTorrent - Cakebox - openVPN" --title "Menu principale" --cancel-label "Quitter" --menu "
 A utiliser après une installation réalisée avec HiwsT

 Votre choix :" 22 70 9 \
	1 "Ajouter un utilisateur" \
	2 "Modifier un mot de passe utilisateur" \
	3 "Supprimer un utilisateur" \
	4 "Lister les utilisateurs existants" \
	5 "Installer/déinstaller OpenVPN, utilisateurs openVPN" \
	6 "Firewall" \
	7 "Relancer rtorrent manuellement" \
	8 "Diagnostique" \
	9 "Rebooter le serveur")

	choixMenu=$("${CMD[@]}" 2>&1 > /dev/tty)
	if [[ $? -eq 0 ]]; then
		case $choixMenu in
			1 )  ################ ajout user  ################################
				__ssmenuAjoutUtilisateur
			;;
			2 )
				echo
				echo "********************************"
				echo "|   Changer un mot de passe    |"
				echo "********************************"
				__changePW
				echo
			;;
			3 ) ################# supp utilisateur  ############################
				__ssmenuSuppUtilisateur
			;;
			4 )
				echo
				echo "****************************"
				echo "|  Liste des utilisateurs  |"
				echo "****************************"
				echo
				__listeUtilisateurs
			;;
			5 )  ######### VPN  ###################################
				__messageBox "openVPN" "
				VPN installé avec le script de Angristan (MIT  License),
				avec son aimable autorisation. Merci à lui

				Dépôt github : https://github.com/Angristan/OpenVPN-install
				Blog de Angristan : https://angristan.fr/installer-facilement-serveur-openvpn-debian-ubuntu-centos/

				Excellent script mettant l'accent sur la sécurité, permettant une installation sans histoire
				sur des serveurs Debian, Ubuntu, CentOS et Arch Linux. Bravo !!!
				Ne pas réinventer la roue (en moins bien), c'est ça l'Open Source

				--------------------------------------------------------------------
				|  !!! Activer le firewall avant d'installer le VPN !!!
				|  A la question 'Tell me a name for the client cert'
				|  donner le nom de l'utilisateur linux au quel est destiné le vpn
				--------------------------------------------------------------------" 22 100

				__vpn
			;;
			6 )  ##########  firewall  ############################
				__messageBox "Firewall et ufw" "


Attention !!! le paramétrage suivant ne tient compte que des installations effectuées avec HiwsT" 12 75

				. $REPLANCE/insert/util_firewall.sh
			;;
			7 )  #########  Relance rtorrent  ###############
				__infoBox "Message" 1 "

			 	  Relance

		du daemon rtorrentd" 10 35
				clear
				service rtorrentd restart
				service rtorrentd status
				sleep 3
			;;
			8 )
				echo
				echo "***************************"
				echo "|      Diagnostique       |"
				echo "***************************"
				echo
				. $REPLANCE/insert/util_diag.sh
			;;
			9 )
				echo
				echo "*********************"
				echo "|      Reboot       |"
				echo "*********************"
				echo
				__ouinonBox "Reboot système"
				if [[ $__ouinonBox -eq 0 ]]; then
					clear
					sleep 2
					reboot
				fi
			;;
		esac
	else
		tmp="ok"
	fi
done

}   # fin menu

################################################################################
# #                             Début du script
################################################################################

# root ?
if [[ $(id -u) -ne 0 ]]; then
	echo
	echo "Ce script nécessite d'être exécuté avec sudo."
	echo
	echo "id : "`id`
	echo
	exit 1
fi
#########################################################################
trap -- EXIT
# apache vs nginx ?
service nginx status > /dev/null
sortieN=$?
service apache2 status > /dev/null
sortieA=$?
if [[ $sortieN -eq 0 ]] && [[ $sortieA -eq 0 ]]; then
	echo
	echo "Votre configuration apache2/nginx est incompatible avec ce script"
	echo
	exit 1
fi
if [[ $sortieN -ne 0 ]] && [[ $sortieA -ne 0 ]]; then
	echo
	echo "Ni apache ni nginx ne sont actifs"
	echo
	exit 1
fi

#  chargement des f() nginx ou apache
if [[ $sortieA -eq 0 ]]; then
	serveurHttp="apache2"
	. $REPLANCE/insert/util_apache.sh
else
	serveurHttp="nginx"
	. $REPLANCE/insert/util_nginx.sh
fi
. $REPLANCE/insert/util_listeusers.sh

# installe dialog si pas installé
which dialog
if [ $? != 0 ]; then
	sudo apt-get install -yq dialog
fi
########################################################################


__menu

clear
echo
echo "Au revoir"
echo
