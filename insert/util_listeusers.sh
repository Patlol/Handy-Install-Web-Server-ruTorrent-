#!/bin/bash

# \u2502 │
# \u2500 ─

# \u250C ┌
# \u252C ┬
# \u2510 ┐

# \u2514 └
# \u2534 ┴
# \u2518 ┘

# \u251C ├
# \u253C ┼
# \u2524 ┤

__listeUtilisateurs() {
	local listeL; local listeR; local listeVpn
	# les différents tableaux : utilisateurs linux, ruto, vpn et oc
	listeL=(`cat /etc/passwd | grep -P "(:0:)|(:10[0-9]{2}:)" | awk -F":" '{ print $1 }'`)
	# encadrement utilisateur principal
  for (( i = 0; i < ${#listeL[@]}; i++ )); do
    if [[ "${listeL[i]}" == "${FIRSTUSER[0]}" ]]; then
      listeL[i]="[${listeL[i]}]"
    fi
  done

  listeR=(`cat $REPAPA2/.htpasswd | awk -F":" '{ print $1 }'`)
	# encadrement utilisateur principal
  for (( i = 0; i < ${#listeR[@]}; i++ )); do
    if [[ "${listeR[i]}" == "${FIRSTUSER[1]}" ]]; then
      listeR[i]="[${listeR[i]}]"
    fi
  done

	# si user openVPN
  if [[ -e /etc/openvpn/easy-rsa/pki/index.txt ]]; then
		nbrClients=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
		clients=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 )
		j=1
		for (( i = 0; i < $nbrClients; i++ )); do
		  listeVpn[$i]=$(echo $clients | cut -d ' ' -f $j)
		  (( j++ ))
		done
	fi

	# if users owncloud
	# if owncloud installed: $listeOC is already populate

	# tableau contenant la longueur (en nbr d'éléments) de chaque tableau ci-dessus
	tabLong=(${#listeL[@]} ${#listeR[@]} ${#listeVpn[@]} ${#listeOC[@]})

	# le + grand tableau en nbre d'éléments
	maxTab=${tabLong[0]}
  for (( i = 1; i < ${#tabLong[@]}; i++ )); do
	  if [[ $maxTab -lt ${tabLong[i]} ]]; then
	    maxTab=${tabLong[i]}
	  fi
	done

	# Tab contenant les éléments de ts tab d'utilisateurs
	concaTab=(${listeL[@]} ${listeR[@]} ${listeVpn[@]} ${listeOC[@]})

	# l'element le + long des tab d'utilisateurs
	maxElem=${#concaTab[0]}
	for (( i = 1; i < ${#concaTab[@]}; i++ )); do
	  if [[ $maxElem -lt ${#concaTab[i]} ]]; then
	    maxElem=${#concaTab[i]}
	  fi
	done
	if [[ $maxElem -lt 11 ]]; then
	  maxElem=11  # longueur minumum en f() du chapeau : users Linux
	fi

	__miseEnPageD() {
		# mise en page cellule droite
		local tab=""
		espace=$(($maxElem+1-${#1}))
		for (( i = 0; i < $espace; i++ )); do
		  tab=$tab" "
		done
		printf "\u2502 ${1}$tab"  # trait V
	}

	__miseEnPageM() {
		# mise en page cellule milieu
		local tab=""
		espace=$(($maxElem+1-${#1}))
		for (( i = 0; i < $espace; i++ )); do
		  tab=$tab" "
		done
		printf "\u2502 ${1}$tab"  # trait V
	}

	__miseEnPageG() {
		# mise en page cellule gauche
		espace=$(($maxElem+1-${#1}))
		local tab=""
		for (( i = 0; i < $espace; i++ )); do
		  tab=$tab" "
		done
		printf "\u2502 ${1}$tab\u2502\n"  # trait V
	}

	__traitHt() {
		# traits horizontaux
		local tab="\u250C"  # coin DrHt
		for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"  # trait H pour linux
		done
		tab=$tab"\u252C"  # Croix bas
		for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"  # trait H pour ruto
		done
    if [[ ${#listeVpn[@]} -ne 0 ]]; then
      tab=$tab"\u252C"  # Croix bas
      for (( i = 0; i < (($maxElem + 2)); i++ )); do
			     tab=$tab"\u2500"  # trait H pour vpn
		  done
    fi
		if [[ ${#listeOC[@]} -ne 0 ]]; then
      tab=$tab"\u252C"  # Croix bas
      for (( i = 0; i < (($maxElem + 2)); i++ )); do
			     tab=$tab"\u2500"  # trait H pour oc
		  done
    fi
		tab=$tab"\u2510"  # coin GHt
		printf $tab"\n"
	}

	__traitM() {
		local tab="\u251C"  # Croix G
		for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"  # trait H pour Linux
		done
		tab=$tab"\u253C"   # croix
		for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"  # trait H pour ruto
		done
    if [[ ${#listeVpn[@]} -ne 0 ]]; then
      tab=$tab"\u253C"   # croix
      for (( i = 0; i < (($maxElem + 2)); i++ )); do
			     tab=$tab"\u2500"  # trait H pour vpn
		  done
    fi
		if [[ ${#listeOC[@]} -ne 0 ]]; then
      tab=$tab"\u253C"   # croix
      for (( i = 0; i < (($maxElem + 2)); i++ )); do
			  tab=$tab"\u2500"  # trait H pour oc
		  done
    fi
		tab=$tab"\u2524"  # croix D
		printf $tab"\n"
	}

	__traitBs() {
		local tab="\u2514"  # Coin DrBas
		for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"  # trait H pour Linux
		done
		tab=$tab"\u2534"   # croiX Ht
		for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500" # trait H pour ruto
		done
    if [[ ${#listeVpn[@]} -ne 0 ]]; then
      tab=$tab"\u2534"   # croiX Ht
      for (( i = 0; i < (($maxElem + 2)); i++ )); do
			     tab=$tab"\u2500"  # trait H pour vpn
		  done
    fi
		if [[ ${#listeOC[@]} -ne 0 ]]; then
      tab=$tab"\u2534"   # croiX Ht
      for (( i = 0; i < (($maxElem + 2)); i++ )); do
			  tab=$tab"\u2500"  # trait H pour oc
		  done
    fi
		tab=$tab"\u2518"  # coin Gbas
		printf $tab"\n"
	}

  echo > /tmp/liste
	##  chapeau partie commune
	__traitHt >> /tmp/liste
	__miseEnPageD "Linux users" >> /tmp/liste
	if [[ ${#listeVpn[@]} -ne 0 ]] && [[ ${#listeOC[@]} -ne 0 ]]; then
    ##  chapeau
		__miseEnPageM "ruTorrent" >> /tmp/liste
    __miseEnPageM "VPN" >> /tmp/liste
		__miseEnPageG "ownCloud" >> /tmp/liste
	  __traitM >> /tmp/liste
    ##  corps
	  for element in $(seq 0 $(($maxTab - 1))); do
	    __miseEnPageD ${listeL[$element]} >> /tmp/liste
			__miseEnPageM ${listeR[$element]} >> /tmp/liste
      __miseEnPageM ${listeVpn[$element]} >> /tmp/liste
			__miseEnPageG ${listeOC[$element]} >> /tmp/liste
	  done
		la=$(($maxElem*4 +18))  # largeur du tableau pour la box
	elif [[ ${#listeVpn[@]} -ne 0 ]]; then
		##  chapeau
		__miseEnPageM "ruTorrent" >> /tmp/liste
    __miseEnPageG "VPN" >> /tmp/liste
	  __traitM >> /tmp/liste
    ##  corps
	  for element in $(seq 0 $(($maxTab - 1))); do
	    __miseEnPageD ${listeL[$element]} >> /tmp/liste
			__miseEnPageM ${listeR[$element]} >> /tmp/liste
      __miseEnPageG ${listeVpn[$element]} >> /tmp/liste
	  done
		la=$(($maxElem*3 +18))
	elif [[ ${#listeOC[@]} -ne 0 ]]; then
		##  chapeau
		__miseEnPageM "ruTorrent" >> /tmp/liste
		__miseEnPageG "ownCloud" >> /tmp/liste
	  __traitM >> /tmp/liste
    ##  corps
	  for element in $(seq 0 $(($maxTab - 1))); do
	    __miseEnPageD ${listeL[$element]} >> /tmp/liste
			__miseEnPageM ${listeR[$element]} >> /tmp/liste
			__miseEnPageG ${listeOC[$element]} >> /tmp/liste
	  done
		la=$(($maxElem*3 +18))
	else
		##  chapeau
		__miseEnPageG "ruTorrent" >> /tmp/liste
	  __traitM >> /tmp/liste
    ##  corps
	  for element in $(seq 0 $(($maxTab - 1))); do
	    __miseEnPageD ${listeL[$element]} >> /tmp/liste
			__miseEnPageG ${listeR[$element]} >> /tmp/liste
	  done
		la=$(($maxElem*2 +18))
	fi
	##  base commune
	__traitBs >> /tmp/liste

	if [[ ${1} != "texte" ]]; then
    ht=$(($maxTab +10))  #  dialog --aspect ne fonctionne pas avec --textbox
    # $la calculé ci-dessus
	  dialog --backtitle "$TITRE" --title "Users list" --textbox  "/tmp/liste" "$ht" "$la"
	fi
}
