#!/bin/bash -e
# rm -rf case*/ 

listFolderExplicit() {
  folderName=$1
  for item in $(find $folderName -mindepth 1); do
    if [[ -L $item ]]; then
      ls -l --time-style='+%Y-%m-%d-%H-%M-%S' "$item"
    elif [[ -f $item || -d $item ]]; then
      ls -ld --time-style='+%Y-%m-%d-%H-%M-%S' "$item"
    fi
  done | sed "s|$folderName/||"
}

# Cas 1: syncA avec un fichier et syncB avec un fichier identique, sans fichier de journalisation 
# Cas 2: syncA avec un fichier et syncB avec un fichier identique, avec fichier de journalisation
# Le script s'initialise bien et est idem-potent
mkdir -p case1-2/syncA case1-2/syncB
touch case1-2/syncA/file.txt
cp case1-2/syncA/file.txt case1-2/syncB/file.txt
cp main.sh functions.sh case1-2/

# Cas 3: syncA avec un fichier, syncB vide, sans fichier de journalisation
# Le fichier est bien copié 
mkdir -p case3/syncA case3/syncB
touch case3/syncA/file.txt
cp main.sh functions.sh case3/

# Cas 4: syncA vide, syncB avec un fichier, sans fichier de journalisation
# Le fichier est supprimé car le script est lancé dans lordre A -> B
mkdir -p case4/syncA case4/syncB
touch case4/syncB/file.txt
cp main.sh functions.sh case4/

# Cas 5: syncA avec un fichier, syncB vide, avec fichier de journalisation vide
# Le fichier de journalisation est rempli et le fichier copié de A vers B 
mkdir -p case5/syncA case5/syncB
touch case5/syncA/file.txt
touch case5/journal.txt
cp main.sh functions.sh case5/

# Cas 6: syncA vide, syncB avec un fichier, avec fichier de journalisation rempli
# Le fichier de journalisation est rempli et le fichier copié de A vers B 
mkdir -p case6/syncA case6/syncB
touch case6/syncB/file.txt
touch case6/journal.txt
listFolderExplicit case6/syncB > case6/journal.txt
cp main.sh functions.sh case6/

# Cas 7: syncA avec un fichier, syncB vide, avec un fichier de journalisation rempli
# Le fichier est supprimé, car le fichier de journalisation est rempli mais pas le dossier syncB, le fichier a donc été supprimé de syncB
mkdir -p case7/syncA case7/syncB
touch case7/syncA/file.txt
touch case7/journal.txt
listFolderExplicit case7/syncA > case7/journal.txt
cp main.sh functions.sh case7/

# Cas 8: syncA avec un fichier modifié, syncB avec le fichier original, avec fichier de journalisation
# Copie de la version modifié (A) vers l'original (B)
mkdir -p case8/syncA case8/syncB
echo "Version originale" > case8/syncB/file.txt
sleep 1.2
echo "Version modifiée" > case8/syncA/file.txt
touch case8/journal.txt
listFolderExplicit case8/syncB > case8/journal.txt
cp main.sh functions.sh case8/

# Cas 9: syncA avec le fichier original, syncB avec un fichier modifié, avec fichier de journalisation
# Copie de la version modifié (B) vers l'original (A)
mkdir -p case9/syncA case9/syncB
echo "Version originale" > case9/syncA/file.txt
sleep 1.2
echo "Version modifiée" > case9/syncB/file.txt
touch case9/journal.txt
listFolderExplicit case9/syncA > case9/journal.txt
cp main.sh functions.sh case9/

# Cas 10: syncA avec un répertoire, syncB vide, avec fichier de journalisation
# Copie d'un dossier uniquement mais de manière récursive
mkdir -p case10/syncA/directory case10/syncB
touch case10/journal.txt
cp main.sh functions.sh case10/

# Cas 11: syncA vide, syncB avec un répertoire, avec fichier de journalisation
# Copie d'un dossier de manière récursive avec toto.txt
mkdir -p case11/syncA case11/syncB/directory
touch case11/syncB/directory/toto.txt
touch case11/journal.txt
cp main.sh functions.sh case11/

# Cas 12: syncA avec un fichier, syncB avec un répertoire portant le même nom
# Conflit avec demande utilisateur, permettant d'ignorer ou de faire le changement soit même 
mkdir -p case12/syncA case12/syncB/same_name
sleep 1.2
touch case12/syncA/same_name
listFolderExplicit case12/syncA > case12/journal.txt
cp main.sh functions.sh case12/

# Cas 13: syncA avec un répertoire, syncB avec un fichier portant le même nom
# Conflit avec demande utilisateur, permettant d'ignorer ou de faire le changement soit même 
mkdir -p case13/syncA/same_name case13/syncB
sleep 1.2
touch case13/syncB/same_name
listFolderExplicit case13/syncA > case13/journal.txt
cp main.sh functions.sh case13/

# Cas 14: syncA avec un fichier ayant des permissions différentes, syncB avec le fichier original
# Si le contenu a été modifié, malgré les permissions, le contenu modifié sera changé
mkdir -p case14/syncA case14/syncB
echo "Contenu original" > case14/syncB/file.txt
sleep 1.2
echo "Contenu modifié" > case14/syncA/file.txt
chmod 644 case14/syncA/file.txt
chmod 755 case14/syncB/file.txt
listFolderExplicit case14/syncB > case14/journal.txt
cp main.sh functions.sh case14/

# Cas 15: syncA avec le fichier original, syncB avec un fichier ayant des permissions différentes
# Si le contenu a été modifié, malgré les permissions, le contenu modifié sera changé
mkdir -p case15/syncA case15/syncB
echo "Contenu original" > case15/syncA/file.txt
sleep 1.2
echo "Contenu modifié" > case15/syncB/file.txt
chmod 644 case15/syncA/file.txt
chmod 755 case15/syncB/file.txt
listFolderExplicit case15/syncA > case15/journal.txt
cp main.sh functions.sh case15/

# Cas 16: syncA et syncB avec des contenus et permissions différentes que celles dans le journal
# Un conflit existe sur les permissions donc une proposition sera donné à l'utilisateur
mkdir -p case16/syncA case16/syncB
echo "Contenu" > case16/syncA/file.txt
echo "Contenu" > case16/syncB/file.txt
chmod 644 case16/syncA/file.txt
chmod 755 case16/syncB/file.txt
touch case16/journal.txt
echo "-rw-r-xrw- 1 root root 17 2024-01-07-23-50-43 file.txt" > case16/journal.txt
cp main.sh functions.sh case16/

# Cas 17: syncA et syncB avec des contenus et permissions différentes que celles dans le journal -> A revoir
# Un conflit existe sur les données donc une proposition sera donné à l'utilisateur
mkdir -p case17/syncA case17/syncB
touch case17/syncA/file.txt
listFolderExplicit case17/syncA > case17/journal.txt
echo "Contenu" > case17/syncA/file.txt
echo "Contenu Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." >> case17/syncB/file.txt
echo "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat." >> case17/syncB/file.txt
echo "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur." >> case17/syncB/file.txt
echo "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum." >> case17/syncB/file.txt
touch case17/journal.txt
cp main.sh functions.sh case17/

# Cas 18: syncA avec plusieurs fichiers et répertoires modifiés, syncB avec les versions originales, avec fichier de journalisation
# Conflit de droits sur les dossiers, et copie de manière "récursive"
mkdir -p case18/syncA/dir case18/syncB/dir
echo "Version originale" > case18/syncB/dir/file2.txt
sleep 1.2
echo "Version modifiée" > case18/syncA/dir/file2.txt
chmod 644 case18/syncA/dir
chmod 755 case18/syncB/dir
touch case18/journal.txt
listFolderExplicit case18/syncB > case18/journal.txt
sed -i '/ dir$/s/^drwxr-xr-x/dr-xrw---x/' case18/journal.txt
cp main.sh functions.sh case18/

# Cas 19: Exécution du script avec des permissions utilisateur non-root lorsque des modifications de propriétaire sont nécessaires
# Conflit :  Présentation des données et métadonnée de chacun pour faire un choix
mkdir -p case19/syncA case19/syncB
touch case19/syncA/file.txt
touch case19/syncB/file.txt
echo "Test de contenu" > case19/syncA/file.txt
echo "Contenu de test" > case19/syncB/file.txt
listFolderExplicit case19/syncA > case19/journal.txt
sudo chown user1 case19/syncA/file.txt 
sudo chown user2 case19/syncB/file.txt 
touch case19/journal.txt
cp main.sh functions.sh case19/

sudo useradd user1 2> /dev/null
sudo useradd user2 2> /dev/null