#!/bin/bash -e
# -e afin de stopper l'exécution du script en cas de problème

# Initie les fonctions stockées dans le fichier functions.sh afin de les utiliser ici
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

# Supprime les './' des variables afin de normaliser leur écriture pour leur traitement dans le script
folderA=$(echo $folderA | sed 's|^\./||')
folderB=$(echo $folderB | sed 's|^\./||')

# Vérifie si les dossiers existent bien sous leur forme normalisée
[[ -d $folderA ]] || error "Le dossier A n'existe pas"
[[ -d $folderB ]] || error "Le dossier B n'existe pas"

# S'il le journal n'existe pas, il est créé en supprimant tous les fichiers de B et en synchronisant A vers B
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
  # Assignation des variables pour la fonction
  elementA=$1
  elementB=$2

  # Lancement d'une boucle for avec l'intégralité des dossiers et fichiers du elementA
  for file in $(listFolder $elementA); do

    # Si l'élément de la boucle dans elementA existe dans elementB
    if [[ -e $elementB/$file ]]; then

      # Vérifie si l'élément est un fichier ou un lien symbolique dans elementA et un dossier dans elementB, ou vice versa
      if [[ (-f $elementA/$file && ! -L $elementA/$file) && -d $elementB/$file ]]; then
        warn "Conflit ! $elementA/$file est un fichier et $elementB/$file est un dossier"
        wantToContinue
      elif [[ -d $elementA/$file && (-f $elementB/$file && ! -L $elementB/$file) ]]; then
        warn "Conflit ! $elementA/$file est un dossier et $elementB/$file est un fichier"
        wantToContinue
      elif [[ -L $elementA/$file && ! -d $elementB/$file && ! -f $elementB/$file ]]; then
        warn "Conflit ! $elementA/$file est un lien symbolique et $elementB/$file est un fichier ou un dossier"
        wantToContinue

      # Sinon, dans le cas où les deux sont fichiers ou dossiers, vérifie si ce fichier a déjà été enregistré dans le fichier de journalisation
      elif [[ $(getJournalFileName ${file}) ]]; then

        # Vérifie si les métadonnées des deux éléments sont différentes, sinon passe au prochain élément de la boucle
        if [[ $(getFileMetadatas $elementA/$file) != $(getFileMetadatas $elementB/$file) ]]; then
          # Supprime la variable de réponse dans la boucle 
          unset REPLY
          # Récupère les metadatas sur l'élément de la boucle dans le fichier de journalisation
          journalMetadas=$(getJournalFileMetadatas ${file})

          # Si l'élément de la boucle est un fichier,
            # compare la date de dernière modification, les permissions, le propriètaire et le groupe pour vérifier si un conflit existe
          # Si l'élément de la boucle est un dossier,
            # compare les permissions, le propriètaire et le groupe pour vérifier si un conflit existe

          # Si l'élément de la boucle est un fichier, et que les métadonnées du fichier sont différent de ceux enregistrée dans la journalisation 
          if [[ -f $elementA/$file && $journalMetadas != $(getFileMetadatas $elementA/$file) && $journalMetadas != $(getFileMetadatas $elementB/$file) ]]; then
            # Alors il y a un conflit entre deux fichiers
            while [[ $REPLY != 1 || $REPLY != 2 ]] ; do
              warn "Conflit sur le fichier $file !"
              echo "1) Garder $elementA/$file"
              echo "2) Garder $elementB/$file"
              echo "3) Afficher les différences"
              read
              # Soit le fichier de A et copié vers B 
              if [[ $REPLY == 1 ]]; then
                checkAndCopy $elementA/$file $elementB/$file
                break
              # Soit le fichier de B et copié vers A 
              elif [[ $REPLY == 2 ]]; then
                checkAndCopy $elementB/$file $elementA/$file
                break
              # Soit en affiche les différences afin de savoir lequels garder
              elif [[ $REPLY == 3 ]]; then
                if [[ -f $elementA/$file ]]; then
                  diff -y --suppress-common-lines $elementA/$file $elementB/$file || true
                fi
              fi
            done

          # Si l'élément de la boucle est un dossier, et que les métadonnées du dossier sont différent de ceux enregistrée dans la journalisation 
          elif [[ -d $elementA/$file && $journalMetadas != $(getFolderMetadatas $elementA/$file) && $journalMetadas != $(getFolderMetadatas $elementB/$file) ]]; then
            # Alors il y a un conflit entre deux dossiers
            while [[ $REPLY != 1 || $REPLY != 2 ]] ; do
              warn "Conflit sur le dossier $file !"
              echo "1) Garder $elementA/$file [$(getFolderMetadatas $elementA/$file)]"
              echo "2) Garder $elementB/$file [$(getFolderMetadatas $elementB/$file)]"
              read
              # Soit le dossier de A et copié vers B 
              if [[ $REPLY == 1 ]]; then
                checkAndCopy $elementA/$file $elementB/$file
                break
              # Soit le dossier de B et copié vers A 
              elif [[ $REPLY == 2 ]]; then
                checkAndCopy $elementB/$file $elementA/$file
                break
              fi
            done

          # Si les métadonnées de l'élément sont différentes de celles enregistrées dans la journalisation pour seulement l'un des deux, alors
          else
            # Si il y a eu une modification du elementA uniquement, alors A est copié vers B 
            if [[ $journalMetadas !=  $(getFileMetadatas $elementA/$file) ]]; then
              checkAndCopy $elementA/$file $elementB/$file
            # Si il y a eu une modification du elementB uniquement, alors B est copié vers A 
            elif [[ $journalMetadas !=  $(getFileMetadatas $elementB/$file) ]]; then
              checkAndCopy $elementB/$file $elementA/$file
            fi
          fi
        fi

	    # Dans le cas où les deux éléments sont fichiers ou dossiers, mais que l'élément de la boucle n'existe pas dans le fichier de journalisation 
      else
        error "Le fichier journal est incomplet ou incorrect. Veuillez le supprimer"
        exit 1
      fi

	  # Si l'élément de la boucle n'existe pas dans elementB
    else
	    # On regarde si l'élément il est présent dans le fichier de journalisation
      if [[ $(getJournalFileName ${file}) ]]; then
        # Si oui, alors on supprime de l'elementA car cela signifie qu'il a été supprimé dans elementB 
        rm -r $elementA/$file
        log "Remove $elementA/$file"

      # Si l'élément de la boucle n'est pas présent dans le fichier de journalisation
      else
        # Alors on le copie dans elementB car il a été créé dans elementA depuis la dernière synchronisation
        if [[ -d $elementA/$file ]]; then
          # Copie le dossier récursivement de elementA vers elementB
          cp -pr $elementA/$file $elementB
          log "Copie du dossier récursivement $elementA/$file --> $elementB"
        elif [[ -L $elementA/$file ]]; then
          # Copie le lien symbolique de elementA vers elementB
          cp -P $elementA/$file $elementB
          log "Copie du lien symbolique $elementA/$file --> $elementB"
        else
          # Sinon, c'est un fichier copié de elementA vers elementB
          cp -p $elementA/$file $elementB/$file
          log "Copie du fichier $elementA/$file --> $elementB/$file"
        fi
      fi
    fi
  done

  # Fin d'exécution de ce fichier ou dossier de la boucle, donc enfin on ajoute l'événement dans le journal
  listFolderExplicit $elementA > $journalPath
}

# Lance la fonction de synchronisation de A vers B, puis de B vers A
# Par extension de if [[ ! -f $journalPath ]], uniquement si le fichier de journalisation existe
sync $folderA $folderB
sync $folderB $folderA

# Annonce de fin de script
info "Synchronisation terminée"