
# évite grosse salade en cas de repasse
if ! [[ -e /etc/ssh/sshd_config.dist ]]; then
	cp /etc/ssh/sshd_config /etc/ssh/sshd_config.dist
else
	cp /etc/ssh/sshd_config.dist /etc/ssh/sshd_config
fi

if [[ $changePort -eq 0 ]]; then
	sed -i -e 's/^Port.*/Port '$portSSH'/' \
				-e 's/^Protocol.*/Protocol 2/' \
				-e 's/^PermitRootLogin.*/PermitRootLogin no/' \
				-e 's/^X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
	# éviter 2 x UseDNS ce qui bloque
	sed -i 's/UseDNS.*//' /etc/ssh/sshd_config
	echo -e "UseDNS no\nAllowUsers $userLinux" >> /etc/ssh/sshd_config
else
	sed -i -e 's/^Port.*/Port 22/' \
				-e 's/^Protocol.*/Protocol 2/' \
				-e 's/^X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
	# éviter 2 x UseDNS ce qui bloque
	sed -i 's/UseDNS.*//' /etc/ssh/sshd_config
	echo -e "UseDNS no\nAllowUsers root" >> /etc/ssh/sshd_config
fi
service sshd restart
__cmd "service sshd status"

echo "******************************************"
echo "|             ssh sécurisé               |"
echo "******************************************"
echo
sleep 1
