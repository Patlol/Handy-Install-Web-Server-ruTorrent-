#!/bin/bash

# Enemble d'utilitaires pour la gestion des utilisateurs linux, rutorrent et cakebox
# L'ajout ou la suppression d'utilisateur rutorrent et cakebox
# Version beta



#############################
#       Fonctions
#############################


__verifSaisie() {
if [[ $1 =~ ^[a-zA-Z0-9]{2,15}$ ]]; then
	yno="o"
else 	echo "Uniquement des caractères alphanumériques"
	echo "Entre 2 et 15 caractères"
	yno="n"
fi
}


__ouinon() {
local tmp=""; local yno=""
until [[ $tmp == "ok" ]]; do
echo
echo -n "Voulez-vous continuer ? (o/n) "; read yno
case $yno in
	[nN] | [nN][oO][nN])
		echo "A bientôt !"
		exit 1
	;;
	[Oo] | [Oo][Uu][Ii])
		echo "On continu !"
		tmp="ok"
		sleep 1
	;;
	*)
		echo "Entrée invalide"
		sleep 1
	;;
esac
done
}    #  fin ouinon



__messageErreur() {
	echo; echo "Consulter le wiki"
	echo "https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
}  # fin messageErreur



__IDuserRuto() {    # saisie ID et PW
echo
local tmp=""; local tmp2=""; local yno=""
until [[ $tmp == "ok" ]]; do
	echo -n "Choisir un nom d'utilisateur ruTorrent (ni espace ni \) : "
	read userRuto
	__verifSaisie $userRuto
	if [[ $yno == "o" ]]; then
		# user linux ?
		egrep "^$userRuto" /etc/passwd >/dev/null
		if [[ $? -eq 0 ]]; then
			echo "$userRuto existe déjà, c'est un utilisateur linux"
			yno="N"
		else
			# user ruTorrent ?
			egrep "^$userRuto:rutorrent" /etc/apache2/.htpasswd > /dev/null
			if [[ $? -eq 0 ]]; then
				echo "$userRuto existe déjà, c'est un utilisateur ruTorrent"
				yno="N"
			else
				# user cakebox ?
				egrep "^$userRuto" /var/www/html/cakebox/public/.htpasswd > /dev/null
				if [[ $? -eq 0 ]]; then
					echo "$userRuto existe déjà, c'est un utilisateur cakebox"
					yno="N"
				else
					echo -n "Vous confirmez '$userRuto' comme nom d'utilisateur ? (o/n) "
					read yno
				fi
			fi
		fi
	fi

	case $yno in
		[Oo] | [Oo][Uu][Ii])   # saisie ID et PW d'un utilisateur
			until [[ $tmp2 == "ok" ]]; do
				echo -n "Choisissez un mot de passe (ni espace ni \) : "
				read pwRuto
				echo -n "Resaisissez ce mot de passe : "
				read pwRuto2
				case $pwRuto2 in
					$pwRuto)
						tmp2="ok"; tmp="ok"
						sleep 2
					;;
					*)
						echo "Les deux saisies du mot de passe ne sont pas identiques. Recommencez"
						echo
						sleep 1
					;;
				esac
			done  # fin saisie d'un utilisateur
		;;
		[nN] | [nN][oO][nN])
			echo "Nom d'utilisateur invalidé. Reprendre la saisie"
			sleep 1
		;;
		*)
			echo "Entrée invalide"
			sleep 1
			;;
	esac
done
}  # fin IDuserRuto


__creaUserRuto () {

clear
echo
echo "**************************************"
echo "|  Création d'un nouvel utilisateur  |"
echo "|            ruTorrent               |"
echo "**************************************"
echo
echo -e "\tNom utilisateur : $userRuto"
echo -e "\tMot de passe    : $pwRuto"
echo
sleep 2

#  créer l'utilisateur linux $userRuto  ---------------------------------

# Ajout du group sftp si n'existe pas
#  group sftp pour interdire de sortir de /home/user en sftp
egrep "^sftp" /etc/group > /dev/null
if [[ $? -eq 1 ]]; then
	addgroup sftp
fi

pass=$(perl -e 'print crypt($ARGV[0], "pwRuto")' $pwRuto)
useradd -m -G sftp -p $pass $userRuto   # adm,dip,plugdev,www-data,sudo,cdrom,sftp -p $pass $userRuto
if [[ $? -ne 0 ]]; then
	echo "Impossible de créer l'utilisateur ruTorrent $userRuto"
	echo "Erreur $erreur sur 'useradd'"
	__messageErreur
	exit 1
fi

echo "bash" >> /home/$userRuto/.profile

echo "Utilisateur linux $userRuto créé"
echo

mkdir -p /home/$userRuto/downloads/watch
mkdir -p /home/$userRuto/downloads/.session
chown -R $userRuto:$userRuto /home/$userRuto/

echo "Répertoire/sous-répertoires /home/$userRuto créé"
echo
#  rtorrent ------------------------------------------------

# incrémenter le port, écrir le fichier témoin
if [ -e /var/www/html/rutorrent/conf/scgi_port ]; then
	port=$(cat /var/www/html/rutorrent/conf/scgi_port)
else 	port=5000
fi

let "port += 1"
echo $port > /var/www/html/rutorrent/conf/scgi_port

# rtorrent.rc
cp $repLance/fichiers-conf/rto_rtorrent.rc /home/$userRuto/.rtorrent.rc
sed -i 's/<username>/'$userRuto'/g' /home/$userRuto/.rtorrent.rc
sed -i 's/scgi_port.*/scgi_port = 127.0.0.1:'$port'/' /home/$userRuto/.rtorrent.rc

echo "/home/$userRuto/rtorrent.rc créé"
echo

#  fichiers daemon rtorrent
#  créé rtorrent.conf
cp $repLance/fichiers-conf/rto_rtorrent.conf /etc/init/$userRuto-rtorrent.conf
chmod u+rwx,g+rwx,o+rx  /etc/init/$userRuto-rtorrent.conf
sed -i 's/<username>/'$userRuto'/g' /etc/init/$userRuto-rtorrent.conf

#  rtorrentd.sh modifié   il faut redonner aux users bash
sed -i '/## bash/ a\          usermod -s \/bin\/bash '$userRuto'' /etc/init.d/rtorrentd.sh
sed -i '/## screen/ a\          su --command="screen -dmS '$userRuto'-rtd rtorrent" "'$userRuto'"' /etc/init.d/rtorrentd.sh
sed -i '/## false/ a\          usermod -s /bin/false '$userRuto'' /etc/init.d/rtorrentd.sh
systemctl daemon-reload
service rtorrentd restart
if [[ $? -eq 0 ]]; then
	echo "rtorrent en daemon fonctionne."
	echo
else	echo "Un problème est survenu."
	ps aux | grep -e '.*torrernt$'
	echo
	service rtorrentd status
	__messageErreur
	exit 1
fi

#  ruTorrent ------------------------------------------------------------------

# dossier conf/users/userRuto
mkdir -p /var/www/html/rutorrent/conf/users/$userRuto
cp /var/www/html/rutorrent/conf/access.ini /var/www/html/rutorrent/conf/plugins.ini /var/www/html/rutorrent/conf/users/$userRuto
cp $repLance/fichiers-conf/ruto_multi_config.php /var/www/html/rutorrent/conf/users/$userRuto/config.php
sed -i -e 's/<port>/'$port'/' -e 's/<username>/'$userRuto'/' /var/www/html/rutorrent/conf/users/$userRuto/config.php

# plugins
echo -e "    [linkcakebox]\n    enabled = no" >> $REPWEB/rutorrent/conf/users/$userRuto/plugins.ini

echo "Dossier users/$userRuto sur ruTorrent crée"
echo

# sécuriser ruTorrent
(echo -n "$userRuto:rutorrent:" && echo -n "$userRuto:rutorrent:$pwRuto" | md5sum) >> /etc/apache2/.htpasswd
sed -i 's/[ ]*-$//' /etc/apache2/.htpasswd
service apache2 restart
if [[ $? -eq o ]]; then
	echo "Mot de passe de $userRuto créé"
	echo
else	service apache2 status
	__messageErreur
	exit 1
fi


# modif pour sftp / sécu sftp -------------------------------------------------------

# pour user en sftp interdit le shell en fin de traitement; bloque le daemon
usermod -s /bin/false $userRuto
# pour interdire de sortir de /home/user  en sftp
chown root:root /home/$userRuto
chmod 0755 /home/$userRuto

# modif sshd.config
sed -i 's/AllowUsers.*/& '$userRuto'/' /etc/ssh/sshd_config
sed -i 's|^Subsystem sftp /usr/lib/openssh/sftp-server|#  &|' /etc/ssh/sshd_config
if [[ `cat /etc/ssh/sshd_config | grep "Subsystem  sftp  internal-sftp"` == "" ]]; then
	echo -e "Subsystem  sftp  internal-sftp\nMatch Group sftp\n ChrootDirectory %h\n ForceCommand internal-sftp\n AllowTcpForwarding no" >> /etc/ssh/sshd_config
fi
service ssh restart > /dev/null
service ssh status
echo "Sécurisation SFTP faite : seulement accès a /home/$userRuto"
}   #  fin creauserruto


__menu() {

 local tmp=""; choixMenu=""
until [[ $tmp == "ok" ]]; do
	clear
	echo "******************************************"
	echo "|                                        |"
	echo "|         Utilitaires seedbox            |"
	echo "|                                        |"
	echo "|         ruTorrent - Cakebox            |"
	echo "|                                        |"
	echo "|   A utiliser après une installation    |"
	echo "|         Réalisée avec HiwsT            |"
	echo "******************************************"
	echo; echo; echo
	echo "Voulez-vous"
	echo
	echo -e "\t1)  Ajouter un utilisateur ruTorrent"
	# echo -e "\t2)  Ajouter un utilisateur Cakebix"
	# echo -e "\t3)  Supprimer un utilisateur ruTorrent"
	# echo -e "\t4)  Supprimer un utilisateur Cakebox"
	# echo -e "\t5)  Relancer rtorrent manuellement"
	echo -e "\t0)  Sortir"
	echo

	local tmp2=""
	until [[ $tmp2 == "ok" ]]; do
		echo -n "Votre choix (0 1 2 3 4 5) "
		read choixMenu
		echo
		case $choixMenu in
			[0])
				exit 0
			;;
			[1])  # + user ruTorrent
				clear
				echo
				echo "****************************************"
				echo "|   Ajout d'un utilisateur ruTorrent   |"
				echo "****************************************"
				echo
				echo "Le nouvel utilisateur aura un accès SFTP"
				echo "Avec son ID et mot de passe, même port"
				echo "Il sera limité à son répertoire"
				echo
				__IDuserRuto
				__creaUserRuto

				echo
				echo "Utilisateur $userRuto crée"
				echo "Mot de passe $pwRuto"
				__ouinon
				tmp2="ok"
			;;
			[2])
				echo "En construction ..."
				sleep 3
				tmp2="ok"
			;;
			[3])
				echo "En construction ..."
				sleep 3
				tmp2="ok"
			;;
			[4])
				echo "En construction ..."
				sleep 3
				tmp2="ok"
			;;
			[5])
				clear
				echo
				echo "*************************"
				echo "|   Relancer rtorrent   |"
				echo "*************************"
				echo
				echo "En construction ..."
				sleep 3
				tmp2="ok"
				#usermod -s /bin/bash pat2
				#service rtorrentd restart
				#service rtorrentd status
				#usermod -s /bin/false pat2
			;;
			*)
				echo "Entrée invalide"
				sleep 1
			;;
		esac
	done
done
}   # fin menu



#############################
#     Début du script
#############################


# root ?

if [[ $(id -u) -ne 0 ]]; then
	echo
	echo "Ce script nécessite d'être exécuté avec sudo."
	echo
	echo "id : "`id`
	echo
	exit 1
fi

repLance=$(echo `pwd`)

#############################
#          MENU
#############################


	__menu

	echo
	echo "Au revoir"
