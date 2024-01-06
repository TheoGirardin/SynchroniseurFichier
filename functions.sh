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

# Liste le dossier récursivement et supprime le dossier racine
listFolder() {
  # Récupère la variable passé en argument
  folderName=$1
  # Récupére uniquement les noms des fichiers et dossiers dans le dossier passé en argument
  find $folderName | cut -d / -f 2- | sed '1d'
}

# Fonction explicite pour la journalisation des événements
listFolderExplicit() {
  # Récupère la variable passé en argument
  folderName=$1
  # Supprime les lignes autres que celle du fichier en argument et formate la sortie
  find $folderName -exec ls -ld --time-style='+%Y-%m-%d-%H-%M-%S' {} + | sed '1d' | sed "s/$folderName\///"
}

getFileMetadatas() {
  ls -ld --time-style='+%Y-%m-%d-%H-%M-%S' $1 | awk '{print $1,$3,$4,$5,$6}'
}

getFileOwner() {
  ls -ld $1 | awk '{print $3,$4}' | sed 's/\ /\:/'
}

# Help with https://bit.ly/3dqAJcN
# Prints the permissions in octal
getFilePermissions() {
  ls -ld $1 | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf("%0o ",k);print $1}' | cut -c -3
}

# Retourne le nom de fichier si celui ci existe dans le fichier de journalisation
getJournalFileName() {
  # Récupère la variable passé en argument
  file=$1
  # Cherche dans le fichier de journalisation les entrées où le nom de fichier est exactement le même que celui passé en argument
  cat $journalPath | awk '{print $7}' | grep -Fx "$file"
}

# Retourne à quelle ligne du fichier de journalisation le fichier se situe
getJournalFileLineLocation() {
  # Récupère la variable passé en argument
  file=$1
  # Cherche dans le fichier de journalisation les entrées où le nom de fichier est exactement le même que celui passé en argument, avec sa ligne
  cat $journalPath | awk '{print $7}' | grep -Fnx "$file" | cut -d : -f 1
}

getJournalFileMetadatas() {
  # Récupère la variable passé en argument
  file=$1
  # 
  line=$(getJournalFileLineLocation $file)
  cat $journalPath | awk '{print $1,$3,$4,$5,$6}' | sed -n "${line}p"
}

# Récupère les métadonnées utiles d'un dossier (droits, proprio, groupe)
getFolderMetadatas() {
  folder=$1
  ls -ld $folder | awk '{print ($1,$3,$4)}'
}

# $1 source -> FolderA
# $2 dest -> FolderB
checkAndCopy() {
  if [[ -f $1 ]]; then
    cp -p $1 $2
    log "Copie $1 --> $2"
  else
    # Verifie si le proprio/groupe a changé
    if [[ $(getFileOwner $1) != $(getFileOwner $2) ]]; then
      # Seul le root peut lancer chown, verification si on est root
      if [[ $UID == 0 ]]; then
        chown $(getFileOwner $1) $2
        log "Changement de propriétaire [$1] pour $2"
      else
        error "La possession du dossier $1 est différente du dossier $2 et seul le root peut le modifier"
        wantToContinue
      fi
    fi

    if [[ $(getFilePermissions $1) != $(getFilePermissions $2) ]]; then
      chmod $(getFilePermissions $1) $2 2> /dev/null ||

      if [[ $(chmod $(getFilePermissions $1) $2) ]]; then
        log "Chagnement de droits [$1] pour $2"

      else
        error "Vous n'avez pas les droits pour modifier $2"
        wantToContinue
      fi
    fi
  fi
}