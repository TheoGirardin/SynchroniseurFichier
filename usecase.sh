# Cas 1: syncA avec un fichier et syncB avec un fichier identique, sans fichier de journalisation
mkdir -p case2/syncA case2/syncB
touch case2/syncA/file.txt
cp case2/syncA/file.txt case2/syncB/file.txt
cp main.sh functions.sh case2/

# Cas 2: syncA avec un fichier et syncB avec un fichier identique, avec fichier de journalisation
mkdir -p case2/syncA case2/syncB
touch case2/syncA/file.txt
cp case2/syncA/file.txt case2/syncB/file.txt
cp main.sh functions.sh case2/

# Cas 3: syncA avec un fichier, syncB vide, sans fichier de journalisation
mkdir -p case3/syncA case3/syncB
touch case3/syncA/file.txt
cp main.sh functions.sh case3/

# Cas 4: syncA vide, syncB avec un fichier, sans fichier de journalisation
mkdir -p case4/syncA case4/syncB
touch case4/syncB/file.txt
cp main.sh functions.sh case4/

# Cas 5: syncA avec un fichier, syncB vide, avec fichier de journalisation
mkdir -p case5/syncA case5/syncB
touch case5/syncA/file.txt
touch case5/journal.txt
cp main.sh functions.sh case5/

# Cas 6: syncA vide, syncB avec un fichier, avec fichier de journalisation
mkdir -p case6/syncA case6/syncB
touch case6/syncB/file.txt
touch case6/journal.txt
cp main.sh functions.sh case6/

# Cas 7: syncA avec un fichier modifié, syncB avec le fichier original, avec fichier de journalisation
mkdir -p case7/syncA case7/syncB
echo "Version modifiée" > case7/syncA/file.txt
echo "Version originale" > case7/syncB/file.txt
touch case7/journal.txt
cp main.sh functions.sh case7/

# Cas 8: syncA avec le fichier original, syncB avec un fichier modifié, avec fichier de journalisation
mkdir -p case8/syncA case8/syncB
echo "Version originale" > case8/syncA/file.txt
echo "Version modifiée" > case8/syncB/file.txt
touch case8/journal.txt
cp main.sh functions.sh case8/

# Cas 9: syncA avec un répertoire, syncB vide, avec fichier de journalisation
mkdir -p case9/syncA/directory case9/syncB
touch case9/journal.txt
cp main.sh functions.sh case9/

# Cas 10: syncA vide, syncB avec un répertoire, avec fichier de journalisation
mkdir -p case10/syncA case10/syncB/directory
touch case10/journal.txt
cp main.sh functions.sh case10/

# Cas 11: syncA avec un fichier, syncB avec un répertoire portant le même nom
mkdir -p case11/syncA case11/syncB/same_name
touch case11/syncA/same_name
cp main.sh functions.sh case11/

# Cas 12: syncA avec un répertoire, syncB avec un fichier portant le même nom
mkdir -p case12/syncA/same_name case12/syncB
touch case12/syncB/same_name
cp main.sh functions.sh case12/

# Cas 13: syncA avec un lien symbolique, syncB avec le fichier cible du lien
mkdir -p case13/syncA case13/syncB
touch case13/syncB/target_file.txt
ln -s ../syncB/target_file.txt case13/syncA/symlink
cp main.sh functions.sh case13/

# Cas 14: syncA avec le fichier cible du lien, syncB avec un lien symbolique
mkdir -p case14/syncA case14/syncB
touch case14/syncA/target_file.txt
ln -s ../syncA/target_file.txt case14/syncB/symlink
cp main.sh functions.sh case14/

# Cas 15: syncA avec un fichier ayant des permissions/modifications différentes, syncB avec le fichier original
mkdir -p case15/syncA case15/syncB
echo "Contenu modifié" > case15/syncA/file.txt
echo "Contenu original" > case15/syncB/file.txt
chmod 644 case15/syncA/file.txt
chmod 755 case15/syncB/file.txt
cp main.sh functions.sh case15/

# Cas 16: syncA avec le fichier original, syncB avec un fichier ayant des permissions/modifications différentes
mkdir -p case16/syncA case16/syncB
echo "Contenu original" > case16/syncA/file.txt
echo "Contenu modifié" > case16/syncB/file.txt
chmod 644 case16/syncA/file.txt
chmod 755 case16/syncB/file.txt
cp main.sh functions.sh case16/

# Cas 17: syncA avec plusieurs fichiers et répertoires modifiés, syncB avec les versions originales, avec fichier de journalisation
mkdir -p case17/syncA/dir case17/syncB/dir
echo "Version modifiée" > case17/syncA/file1.txt
echo "Version modifiée" > case17/syncA/dir/file2.txt
echo "Version originale" > case17/syncB/file1.txt
echo "Version originale" > case17/syncB/dir/file2.txt
touch case17/journal.txt
cp main.sh functions.sh case17/

# Cas 18: syncA avec les versions originales, syncB avec plusieurs fichiers et répertoires modifiés, avec fichier de journalisation
mkdir -p case18/syncA/dir case18/syncB/dir
echo "Version originale" > case18/syncA/file1.txt
echo "Version originale" > case18/syncA/dir/file2.txt
echo "Version modifiée" > case18/syncB/file1.txt
echo "Version modifiée" > case18/syncB/dir/file2.txt
touch case18/journal.txt
cp main.sh functions.sh case18/

# Cas 19: syncA avec un fichier supprimé présent dans le fichier de journalisation, syncB avec le fichier existant
mkdir -p case19/syncA case19/syncB
touch case19/syncB/file.txt
touch case19/journal.txt
echo "file.txt" >> case19/journal.txt
cp main.sh functions.sh case19/

# Cas 20: syncA avec un fichier existant, syncB avec un fichier supprimé présent dans le fichier de journalisation
mkdir -p case20/syncA case20/syncB
touch case20/syncA/file.txt
touch case20/journal.txt
echo "file.txt" >> case20/journal.txt
cp main.sh functions.sh case20/

# Cas 21 : Couper au milieu de la synchronisation puis reprendre

# Cas 22: Exécution du script avec des permissions utilisateur non-root lorsque des modifications de propriétaire sont nécessaires
mkdir -p case22/syncA case22/syncB

touch case22/syncA/fileA.txt
touch case22/syncB/fileB.txt
sudo useradd user1
sudo useradd user2
sudo chown user1 case22/syncA/fileA.txt
sudo chown user2 case22/syncB/fileB.txt
cp main.sh functions.sh case22/
