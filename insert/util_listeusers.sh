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
	local listeL; local listeR; local listeC; local listeVpn
	# les différents tableaux : utilisateurs linux, ruto et cake et vpn
	listeL=(`cat /etc/passwd | grep -P "(:0:)|(:10[0-9]{2}:)" | awk -F":" '{ print $1 }'`)
	# encadrement utilisateur principal
  for (( i = 0; i < ${#listeL[@]}; i++ )); do
    if [[ "${listeL[i]}" == "${FIRSTUSER[0]}" ]]; then
      listeL[i]="[${listeL[i]}]"
    fi
  done

	if [[ $SERVEURHTTP == "apache2" ]]; then
	  listeR=(`cat $REPAPA2/.htpasswd | awk -F":" '{ print $1 }'`)
	  listeC=(`cat $REPWEB/cakebox/public/.htpasswd 2>/dev/null | awk -F":" '{ print $1 }'`)
	else
	  listeR=(`cat $REPNGINX/.htpasswdR | awk -F":" '{ print $1 }'`)
	  listeC=(`cat $REPNGINX/.htpasswdC 2>/dev/null | awk -F":" '{ print $1 }'`)
	fi
	# encadrement utilisateur principal
  for (( i = 0; i < ${#listeR[@]}; i++ )); do
    if [[ "${listeR[i]}" == "${FIRSTUSER[1]}" ]]; then
      listeR[i]="[${listeR[i]}]"
    fi
  done
  for (( i = 0; i < ${#listeC[@]}; i++ )); do
    if [[ "${listeC[i]}" == "${FIRSTUSER[2]}" ]]; then
      listeC[i]="[${listeC[i]}]"
    fi
  done

  if [[ -e /etc/openvpn/easy-rsa/pki/index.txt ]]; then
		nbrClients=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
		clients=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 )
		j=1
		for (( i = 0; i < $nbrClients; i++ )); do
		  listeVpn[$i]=$(echo $clients | cut -d ' ' -f $j)
		  (( j++ ))
		done
	fi

	# tableau contenant la longueur de chaque tableau ci-dessus
	tabLong=(${#listeL[@]} ${#listeR[@]} ${#listeC[@]} ${#listeVpn[@]})

	# le + grand tableau en nbre d'éléments
	maxTab=${tabLong[0]}
  for (( i = 1; i < ${#tabLong[@]}; i++ )); do
	  if [[ $maxTab -lt ${tabLong[i]} ]]; then
	    maxTab=${tabLong[i]}
	  fi
	done

	# Concaténation des éléments des tab
	concaTab=(${listeC[*]} ${listeL[*]} ${listeR[*]} ${listeVpn[*]})

	# l'element le + long des tab
	maxElem=${#concaTab[0]}
	for (( i = 1; i < ${#concaTab[*]}; i++ )); do
	  if [[ $maxElem -lt ${#concaTab[i]} ]]; then
	    maxElem=${#concaTab[i]}
	  fi
	done
	if [[ $maxElem -lt 11 ]]; then
	  maxElem=11  # longueur minumum en f() du chapeau : users Linux
	fi

	__miseEnPageD() {
		local tab=""
		espace=$(($maxElem+1-${#1}))
		for (( i = 0; i < $espace; i++ )); do
		  tab=$tab" "
		done
		printf "\u2502 ${1}$tab"  # trait V
	}

	__miseEnPageM() {
		local tab=""
		espace=$(($maxElem+1-${#1}))
		for (( i = 0; i < $espace; i++ )); do
		  tab=$tab" "
		done
		printf "\u2502 ${1}$tab"
	}

	__miseEnPageG() {
		espace=$(($maxElem+1-${#1}))
		local tab=""
		for (( i = 0; i < $espace; i++ )); do
		  tab=$tab" "
		done
		printf "\u2502 ${1}$tab\u2502"
	}

	__traitHt() {
		local tab="\u250C"  # coin DrHt
		for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"  # trait H
		done  # pour linux
		tab=$tab"\u252C"  # Croix bas
		for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"  # trait H
		done  #  pour ruto
		tab=$tab"\u252C"  # Croix bas
		for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"  # trait H
		done  #  pour cake
    if [[ ${#listeVpn[*]} -ne 0 ]]; then
      tab=$tab"\u252C"  # Croix bas
      for (( i = 0; i < (($maxElem + 2)); i++ )); do
			     tab=$tab"\u2500"  # trait H
		  done  #  pour vpn
    fi
		tab=$tab"\u2510"  # coin GHt
		printf $tab"\n"
	}

	__traitM() {
		local tab="\u251C"  # Croix G
		for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"  # trait H
		done  # pour Linux
		tab=$tab"\u253C"   # croix
			for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"
		done  # pour ruto
		tab=$tab"\u253C"  # croix
			for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"
		done  # pour cake
    if [[ ${#listeVpn[*]} -ne 0 ]]; then
      tab=$tab"\u253C"   # croix
      for (( i = 0; i < (($maxElem + 2)); i++ )); do
			     tab=$tab"\u2500"  # trait H
		  done  #  pour vpn
    fi
		tab=$tab"\u2524"  # croix D
		printf $tab"\n"
	}

	__traitBs() {
		local tab="\u2514"  # Coin DrBas
		for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"  # trait H
		done
		tab=$tab"\u2534"   # croiX Ht
			for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"
		done
		tab=$tab"\u2534"  # croix Ht
			for (( i = 0; i < (($maxElem + 2)); i++ )); do
			tab=$tab"\u2500"
		done
    if [[ ${#listeVpn[*]} -ne 0 ]]; then
      tab=$tab"\u2534"   # croiX Ht
      for (( i = 0; i < (($maxElem + 2)); i++ )); do
			     tab=$tab"\u2500"  # trait H
		  done  #  pour vpn
    fi
		tab=$tab"\u2518"  # coin Gbas
		printf $tab"\n"
	}

	  echo > /tmp/liste
    #  chapeau
	  __traitHt >> /tmp/liste
	  __miseEnPageD "users Linux" >> /tmp/liste
	  __miseEnPageM "ruTorrent" >> /tmp/liste
    if [[ ${#listeVpn[*]} -ne 0 ]]; then
      __miseEnPageM "Cakebox" >> /tmp/liste
      __miseEnPageG "VPN" >> /tmp/liste
    else
      __miseEnPageG "Cakebox" >> /tmp/liste
    fi
	   echo >> /tmp/liste
	  __traitM >> /tmp/liste
    # corps
	  for element in $(seq 0 $(($maxTab - 1)))
	  do
	    __miseEnPageD ${listeL[$element]} >> /tmp/liste
	    __miseEnPageM ${listeR[$element]} >> /tmp/liste
      if [[ ${#listeVpn[*]} -ne 0 ]]; then
        __miseEnPageM ${listeC[$element]} >> /tmp/liste
        __miseEnPageG ${listeVpn[$element]} >> /tmp/liste
      else
        __miseEnPageG ${listeC[$element]} >> /tmp/liste
      fi
	     echo >> /tmp/liste
	  done
    # base
	  __traitBs >> /tmp/liste

	if [[ ${1} != "texte" ]]; then
    ht=$(($maxTab +10))  #  --aspect ne fonctionne pas avec --textbox
    if [[ ${#listeVpn[*]} -ne 0 ]]; then
      la=$(($maxElem*4 +18))
    else
      la=$(($maxElem*3 +15))
    fi
	  dialog --backtitle "$TITRE" --title "Liste utilisateurs" --textbox  "/tmp/liste" "$ht" "$la"
	fi
}
