#!/bin/bash


# les différents tableaux : utilisateurs linux, ruto et cake
listeL=(`cat /etc/passwd | grep -P "(:0:)|(:10[0-9]{2}:)" | awk -F":" '{ print $1 }'`)
if [[ $serveurHttp == "apache2" ]]; then
  listeR=(`cat $REPAPA2/.htpasswd | awk -F":" '{ print $1 }'`)
  listeC=(`cat $REPWEB/cakebox/public/.htpasswd | awk -F":" '{ print $1 }'`)
else
  listeR=(`cat $REPNGINX/.htpasswdR | awk -F":" '{ print $1 }'`)
  listeC=(`cat $REPNGINX/.htpasswdC | awk -F":" '{ print $1 }'`)
fi

# tableau contenant la longueur de chaque tableau ci-dessus
tabLong=(${#listeL[@]} ${#listeR[@]} ${#listeC[@]})

# le + grand tableau en nbre d'éléments
maxTab=${tabLong[0]}
for (( i = 1; i < 3; i++ )); do
  if [[ $maxTab -lt ${tabLong[i]} ]]; then
    maxTab=${tabLong[i]}
  fi
done

# Concaténation des éléments des tab
concaTab=(${listeC[*]} ${listeL[*]} ${listeR[*]})

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

__miseEnPage() {
espace=$(($maxElem+1-${#1}))
local tab=""

for (( i = 0; i < $espace; i++ )); do
  tab=$tab" "
done
echo -n "| ${1}$tab|"
}

__traitH() {
local tab=""
for (( i = 0; i < ((($maxElem * 3) + 12)); i++ )); do
  tab=$tab"-"
done
echo $tab
}

echo
__traitH
__miseEnPage "users Linux"
__miseEnPage "ruTorrent"
__miseEnPage "Cakebox"
echo
__traitH

for element in $(seq 0 $(($maxTab - 1)))
do
  __miseEnPage ${listeL[$element]}
  __miseEnPage ${listeR[$element]}
  __miseEnPage ${listeC[$element]}
  echo
done
__traitH
echo
