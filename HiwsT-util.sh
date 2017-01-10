#!/bin/bash

# Enemble d'utilitaires pour la gestion des utilisateurs linux, rutorrent et cakebox
# L'ajout ou la suppression d'utilisateur rutorrent et cakebox 
# Version beta



#############################
#       Fonctions
#############################


__ouinon() {
local tmp=""; local yno=""
until [[ $tmp == "ok" ]]; do
echo
echo -n "Voulez-vous continuer ? (o/n) "; read yno
case $yno in
	[nN] | [nN][oO][nN])
		echo "Désolé, à bientôt !"
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



__IDuserRuto() {
echo
local tmp=""; local tmp2=""; local yno=""
until [[ $tmp == "ok" ]]; do
	echo -n "Choisir un nom d'utilisateur ruTorrent : "
	read userRuto
	
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
	
	case $yno in
		[Oo] | [Oo][Uu][Ii])   # saisie ID et PW d'un utilisateur
			until [[ $tmp2 == "ok" ]]; do
				echo -n "Choisissez un mot de passe : "
				read pwRuto
				echo -n "Resaisissez ce mot de passe : "
				read pwRuto2
				case $pwRuto2 in
					$pwRuto)
						tmp2="ok"; tmp="ok"
					;;
					*)
						echo "Les deux saisies du mot de passe ne sont pas identiques. Recommencez"
						echo
						sleep 1
					;;
				esac
			done  # fin création d'un utilisateur
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
}  # creauser


__creaUserRuto () { 

#  créer l'utilisateur linux $userRuto  ---------------------------------

#  group sftp pour interdire de sortir de /home/user en sftp
# Ajout du group sftp si n'existe pas
egrep "^sftp" /etc/group > /dev/null
if [[ $? -eq 1 ]]; then
	addgroup sftp
fi

pass=$(perl -e 'print crypt($ARGV[0], "pwRuto")' $pwRuto)
useradd -m -G sftp -p $pass $userRuto
erreur=$?
if [[ $erreur -ne 0 ]]; then
	echo "Impossible de créer l'utilisateur ruTorrent $userRuto"
	echo "Erreur $erreur sur 'useradd'"
	__messageErreur
	exit 1
fi

mkdir -p /home/$userRuto/downloads/watch
mkdir -p /home/$userRuto/downloads/.session
chown -R $userRuto:$userRuto /home/$userRuto/

#  rtorrent ------------------------------------------------

# incrémenter le port, écrir le fichier témoin
if [ -e /var/www/html/rutorrent/conf/scgi_port ]; then
	port=$(cat /var/www/html/rutorrent/conf/scgi_port)
else
	port=5000
fi

let "port += 1"
echo $port > /var/www/html/rutorrent/conf/scgi_port

# rtorrent.rc
cp $repLance/fichiers-conf/rto_rtorrent.rc /home/$userRuto/.rtorrent.rc
sed -i 's/<username>/'$userRuto'/g' /home/$userRuto/.rtorrent.rc
sed -i 's/scgi_port.*/scgi_port = 127.0.0.1:'$port'/' /home/$userRuto/.rtorrent.rc

#  fichiers daemon rtorrent
#  rtorrent.conf créé
cp $repLance/fichiers-conf/rto_rtorrent.conf /etc/init/rtorrent_$userRuto.conf
chmod u+rwx,g+rwx,o+rx  /etc/init/rtorrent_$userRuto.conf
sed -i 's/<username>/'$userRuto'/g' /etc/init/rtorrent_$userRuto.conf

#  rtorrentd.sh modifié
sed -i '23 i\          su -l '$userRuto' -c  "screen -fn -dmS rtd nice -19 rtorrent"' /etc/init.d/rtorrentd.sh
systemctl daemon-reload
service rtorrentd restart



#  ruTorrent ------------------------------------------------------------------

# dossier conf/users/user
mkdir -p /var/www/html/rutorrent/conf/users/$userRuto
cp /var/www/html/rutorrent/conf/access.ini /var/www/html/rutorrent/conf/plugins.ini /var/www/html/rutorrent/conf/users/$userRuto
cp $repLance/fichiers-conf/ruto_multi_config.php /var/www/html/rutorrent/conf/users/$userRuto/config.php
sed -i -e 's/<port>/'$port'/' -e 's/<username>/'$userRuto'/' /var/www/html/rutorrent/conf/users/$userRuto/config.php

# sécuriser ruTorrent
(echo -n "$userRuto:rutorrent:" && echo -n "$userRuto:rutorrent:$pwRuto" | md5sum) >> /etc/apache2/.htpasswd
sed -i 's/[ ]*-$//' /etc/apache2/.htpasswd
service apache2 restart


if [[ 10 -eq 20 ]]; then
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

fi
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
	echo -e "\t1  Ajouter un utilisateur ruTorrent"
	echo -e "\t2  Ajouter un utilisateur Cakebix"
	echo -e "\t3  Supprimer un utilisateur ruTorrent"
	echo -e "\t4  Supprimer un utilisateur Cakebox"
	echo -e "\t5  Relancer rtorrent (multiutilisateur)"
	echo -e "\t0  Sortir"
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
			[1])
				clear
				echo
				echo "****************************************"
				echo "|   Ajout d'un utilisateur ruTorrent   |"
				echo "****************************************"
				echo
				__IDuserRuto
				__creaUserRuto
		
				echo "fini"
				__ouinon
				tmp2="ok"
			;;
			[2]) 

			;;
			[3]) 

			;;
			[4])
				
			;;
			[5])
				clear
				echo
				echo "*************************"
				echo "|   Relancer rtorrent   |"
				echo "*************************"
				echo
				#usermod -s /bin/bash pat2
				#service rtorrentd restart
				#service rtorrentd status
				#ouinon
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























