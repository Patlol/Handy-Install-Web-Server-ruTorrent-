echo
echo
echo "********************************************"
echo "|             Sécuriser ssh                |"
echo "********************************************"
echo
echo
sleep 2
sed -i -e 's/^Port.*/Port '$portSSH'/' -e 's/^Protocol.*/Protocol 2/' -e 's/^PermitRootLogin.*/PermitRootLogin no/' -e 's/^X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
echo -e "UseDNS no\nAllowUsers $userLinux" >> /etc/ssh/sshd_config
service ssh restart
service ssh status
if [[ $? -ne 0 ]]; then
	echo
	echo "Il y a une erreur au redémarage du service ssh"
	echo; echo "Consulter le wiki"
	echo "https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
	echo; echo "puis continuer/arrêter l'installation"	
	echo "Mais vous pouvez finir le script l'installation est terminée."
	echo
	echo "              /!\\"
	echo
	echo "NE PAS REBOOTER, NE PAS COUPER votre connection SSH"
	echo "avant d'avoir résolu ce problème."
	ouinon
fi
