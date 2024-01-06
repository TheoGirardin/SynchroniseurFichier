#!/bin/bash -e
source ./functions.sh

# Vérification de la bonne entrée des arguments par l'utilisateur
if [[ -d $1 ]]; then
	folderA=$1
else
	echo "Le premier argument n'est pas un dossier."
	exit 1
fi
if [[ -d $2 ]]; then
	folderB=$2
else
	echo "Le deuxième argument n'est pas un dossier."
	exit 1
fi

# Création de la variable vers le fichier de journalisation 
journalPath="./journal.txt"

# Supprime les ./ si il existe afin de normaliser leur écriture en cas de besoin
folderA=$(echo $folderA | sed 's/^\.\///')
folderB=$(echo $folderB | sed 's/^\.\///')

# Vérifie si les dossiers existent bien, même sous leur forme normaliser
[[ -d $folderA ]] || error "Le dossier A n'existe pas"
[[ -d $folderB ]] || error "Le dossier B n'existe pas"

# Si le journal n'existe pas, il le créait en supprimant tous les fichier de B et synchronisant A vers B
if [[ ! -f $journalPath ]]; then
  rm -rf $folderB
  cp -pr $folderA $folderB
  log "Copie $folderA --> $folderB"
  listFolderExplicit $folderA > $journalPath
  echo "Fichier de journalisation créé et dossier synchronisé"
  exit 0
fi

# Début de la fonction principale de ce script
sync() {
  # Lancement d'une boucle for avec l'intégralité des dossiers et fichiers du folderA
  for file in $(listFolder $folderA); do

    # Regarde si l'élément de la boucle dans folderA existe dans le folderB
    if [[ -e $folderB/$file ]]; then

      # Si c'est un fichier dans le folderA et que c'est un dossier dans le folderB, alors on demande si il souhaite continuer
      if [[ -f $folderA/$file && -d $folderB/$file ]]; then
        warn "Conflit ! $folderA/$file est un fichier et $folderB/$file est un dossier"
        wantToContinue
      # Si c'est un dossier dans le folderA et que c'est un fichier dans le folderB, alors on demande si il souhaite continuer
      elif [[ -d $folderA/$file && -f $folderB/$file ]]; then
        warn "Conflit ! $folderA/$file est un dossier et $folderB/$file est un fichier"
        wantToContinue

      # Sinon, dans le cas où les deux sont fichiers ou dossiers, vérifie si ce fichier a déjà été enregistré dans le fichier de journalisation
      elif [[ $(getJournalFileName ${file}) ]]; then

        # Vérifie si les métadatas des deux éléments sont différents, sinon passe au prochain élément de la boucle
        if [[ $(getFileMetadatas $folderA/$file) != $(getFileMetadatas $folderB/$file) ]]; then
          # Supprime la variable de réponse dans la boucle 
          unset REPLY
          # Récupère les metadatas sur l'élément de la boucle dans le fichier de journalisation
          journalMetadas=$(getJournalFileMetadatas ${file})

          # Si l'élément de la boucle est un fichier,
            # compare la date de dernière modification, les permissions, le propriètaire et le groupe pour vérifier si un conflit existe
          # Si l'élément de la boucle est un dossier,
            # compare les permissions, le propriètaire et le groupe pour vérifier si un conflit existe

          # Si l'élément de la boucle est un fichier, et que les métadonnées du fichier sont différent de ceux enregistrée dans la journalisation 
          if [[ -f $folderA/$file && $journalMetadas != $(getFileMetadatas $folderA/$file) && $journalMetadas != $(getFileMetadatas $folderB/$file) ]]; then
            # Alors il y a un conflit entre deux fichiers
            while [[ $REPLY != 1 || $REPLY != 2 ]] ; do
              warn "Conflit sur le fichier $file !"
              echo "1) Garder $folderA/$file"
              echo "2) Garder $folderB/$file"
              echo "3) Afficher les différences"
              read
              # Soit le fichier de A et copié vers B 
              if [[ $REPLY == 1 ]]; then
                checkAndCopy $folderA/$file $folderB/$file
                break
              # Soit le fichier de B et copié vers A 
              elif [[ $REPLY == 2 ]]; then
                checkAndCopy $folderB/$file $folderA/$file
                break
              # Soit en affiche les différences afin de savoir lequels garder
              elif [[ $REPLY == 3 ]]; then
                if [[ -f $folderA/$file ]]; then
                  diff -y --suppress-common-lines $folderA/$file $folderB/$file || true
                fi
              fi
            done

          # Si l'élément de la boucle est un dossier, et que les métadonnées du dossier sont différent de ceux enregistrée dans la journalisation 
          elif [[ -d $folderA/$file && $journalMetadas != $(getFolderMetadatas $folderA/$file) && $journalMetadas != $(getFolderMetadatas $folderB/$file) ]]; then
            # Alors il y a un conflit entre deux dossiers
            while [[ $REPLY != 1 || $REPLY != 2 ]] ; do
              warn "Conflit sur le dossier $file !"
              echo "1) Garder $folderA/$file [$(getFolderMetadatas $folderA/$file)]"
              echo "2) Garder $folderB/$file [$(getFolderMetadatas $folderB/$file)]"
              read
              # Soit le dossier de A et copié vers B 
              if [[ $REPLY == 1 ]]; then
                checkAndCopy $folderA/$file $folderB/$file
                break
              # Soit le dossier de B et copié vers A 
              elif [[ $REPLY == 2 ]]; then
                checkAndCopy $folderB/$file $folderA/$file
                break
              fi
            done

          # Si les métadonnées de l'élément sont différent de ceux enregistrée dans la journalisation pour seulement l'un des deux, alors
          else
            # Si il y a eu une modification du folderA uniquement, alors A est copié vers B 
            if [[ $journalMetadas !=  $(getFileMetadatas $folderA/$file) ]]; then
              checkAndCopy $folderA/$file $folderB/$file
            # Si il y a eu une modification du folderB uniquement, alors B est copié vers A 
            elif [[ $journalMetadas !=  $(getFileMetadatas $folderB/$file) ]]; then
              checkAndCopy $folderB/$file $folderA/$file
            fi
          fi
        fi

	    # Dans le cas où les deux éléments sont fichiers ou dossiers, mais que l'élément de la boucle n'existe pas dans le fichier de journalisation 
      else
        error "Le fichier journal est incomplet ou incorrect. Veuillez le supprimer"
        exit 1
      fi

	  # Si l'élément de la boucle n'existe pas dans le folderB
    else
	    # Regarde si ce fichier exite dans le journal d'évenement
	    # TODO: comprendre ici, pourquoi supprimer si il existe dans le journal ??
      if [[ $(getJournalFileName ${file}) ]]; then
        # Le fichier existe dans le journal
        rm -r $folderA/$file
        log "Remove $folderA/$file"

      # Si l'élément de la boucle 
      else
        # check si le fichier est un dossier ou non
        [[ -d $folderA/$file ]] && cp -pr $folderA/$file $folderB || cp -p $folderA/$file $folderB/$file
        log "Copie $folderA/$file --> $folderB/$file"
      fi
    fi
  done

  # Fin d'execution de ce fichier ou dossier de la boucle, donc ajout de l'évenement dans le journal
  listFolderExplicit $folderA > $journalPath
}

# Lance la fontion de synchronisation de A vers B, puis de B vers A 
# Par extension de if [[ ! -f $journalPath ]], uniquement si le fichier de journalisation existe
sync $folderA $folderB
sync $folderB $folderA
# TODO : supprimer le second ???

# Annonce de fin de script
info "Synchronisation terminée"