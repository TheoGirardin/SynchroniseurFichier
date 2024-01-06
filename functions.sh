# Liste des différentes alertes sous forme formatté pouvant être utilisé pour prévenir l'utilisateur pendant l'éxecution du code
log() {
  echo -e "\e[90m[$(date +"%Y-%m-%d %H:%M:%S")]\e[39m $@"
}

info() {
  log "\e[32mINFO:\e[39m $@"
}
warn() {
  log "\e[33mWARN:\e[39m $@"
}
debug() {
  log "\e[34mDEBUG:\e[39m $@"
}
error() {
  log "\e[31mERROR:\e[39m $@"
  exit 1
}

# Question posé en cas d'erreur dans la boucle
wantToContinue() {
  while [[ $REPLY != 1 || $REPLY != 2 ]] ; do
    echo "Souhaitez-vous continuer la synchronisation malgré cette erreur?"
    echo "1) Oui"
    echo "2) Non"
    unset REPLY
    read
    if [[ $REPLY == 1 ]]; then
      break
    else
      exit 0
    fi
  done
}

# Liste uniquement les noms des éléments du dossier passé en argument et supprime le dossier racine de cette liste
listFolder() {
  folderName=$1
  find $folderName | cut -d / -f 2- | sed '1d'
}

# Liste les éléments du dossier passé en argument en récupérant des détails sur chacun, formatte les noms et supprime le dossier racine de cette liste
listFolderExplicit() {
  folderName=$1
  find $folderName -exec ls -ld --time-style='+%Y-%m-%d-%H-%M-%S' {} + | sed '1d' | sed "s/$folderName\///"
}

# Récupère les permissions, le propriétaire, le groupe, la taille et la date de dernière modification d'un fichier
getFileMetadatas() {
  fileName=$1
  ls -ld --time-style='+%Y-%m-%d-%H-%M-%S' $fileName | awk '{print $1,$3,$4,$5,$6}'
}

# Cherche dans le fichier de journalisation les entrées où le nom de fichier est exactement le même que celui passé en argument
getJournalFileName() {
  fileName=$1
  cat $journalPath | awk '{print $7}' | grep -Fx "$fileName"
}

# Cherche dans le fichier de journalisation les entrées où le nom de fichier est exactement le même que celui passé en argument, et renvoie sa ligne
getJournalFileLineLocation() {
  fileName=$1
  cat $journalPath | awk '{print $7}' | grep -Fnx "$fileName" | cut -d : -f 1
  ## TODO : Ajout de "| tail -n 1" à la fin des commandes ???? 
}

# Récupère uniquement les permissions, le propriétaire, le groupe, la taille et date de dernière modification du fichier passé en argument dans le fichier de journalisation 
getJournalFileMetadatas() {
  fileName=$1
  line=$(getJournalFileLineLocation $fileName)
  cat $journalPath | awk '{print $1,$3,$4,$5,$6}' | sed -n "${line}p"
}

# Récupère les permissions, le propriètaire et le groupe d'un dossier
getFolderMetadatas() {
  folderName=$1
  ls -ld $folderName | awk '{print ($1,$3,$4)}'
}

# Avec l'aide de https://bit.ly/3dqAJcN
# Récupère les permissions d'un fichier sous sa forme octal (755)
getFilePermissions() {
  fileName=$1
  ls -ld $fileName | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf("%0o ",k);print $1}' | cut -c -3
}

# Récupère le propriètaire et le groupe d'un fichier et remplace l'espace par deux points (root:root)
getFileOwner() {
  fileName=$1
  ls -ld $fileName | awk '{print $3,$4}' | sed 's/\ /\:/'
}

# Permet la synchronisation d'un fichier ou dossier de la source vers la destination en vérifiant les permissions des dossiers
checkAndCopy() {
  source=$1
  destination=$2
  # Si l'élément passé en argument est un fichier
  if [[ -f $source ]]; then
    # Copie du fichier avec l'argument -p afin de garder les attributs de ce fichier (permissions, propriétaire, groupe)
    cp -p $source $destination
    log "Copie $source --> $destination"

  # Si l'élément passé en argument n'est pas un fichier
  else
    # Verifie si le propriétaire ou le groupe a changé
    if [[ $(getFileOwner $source) != $(getFileOwner $destination) ]]; then

      # Vérification si l'utilisateur du script est root, car seul le root peut lancer chown
      if [[ $UID == 0 ]]; then
        chown $(getFileOwner $source) $destination
        log "Changement de propriétaire [$source] pour $destination"

      # Si l'utilisateur du script n'est pas root
      else
        error "La possession du dossier $source est différente du dossier $destination, seul l'utilisateur root peut modifier cela"
        wantToContinue
      fi
    fi

    # Vérifie si les permissions de source sont différentes de celle de destination
    if [[ $(getFilePermissions $source) != $(getFilePermissions $destination) ]]; then
      chmod $(getFilePermissions $source) $destination 2> /dev/null ||

      if [[ $(chmod $(getFilePermissions $source) $destination) ]]; then
        log "Changement de droits [$source] pour $destination"

      else
        error "Vous n'avez pas les droits pour modifier $destination"
        wantToContinue
      fi
    fi
  fi
}