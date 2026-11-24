# TP 04. Disques, volumes et systèmes de fichiers

> [!abstract] Parcours TSSR
> Socle : A, B et D ; le volume G: est conservé pour la suite. Le miroir et sa panne simulée sont (bonus).

> Chapitres associés : [04. Disques, volumes et systèmes de fichiers](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/)

---

## Objectifs

- Ajouter des disques à une VM et les préparer (GPT, partition, NTFS)
- Utiliser `diskmgmt.msc`, `diskpart` et le module PowerShell `Storage`
- Monter un volume dans un dossier
- Créer un espace de stockage en miroir et **simuler la panne d'un disque** (bonus)

---

## Prérequis

- `PC01` opérationnel (TP 03)
- Sur l’hôte, ajoute `Data1.vhdx` de 10 Go à `PC01` via **Paramètres → Contrôleur SCSI → Disque dur**. Si le disque est déjà attaché, passe à la partie A.
- **(bonus)** Pour le miroir de la partie C, ajoute aussi `Data2.vhdx` et `Data3.vhdx`, de 10 Go chacun. Garde-les non initialisés jusqu’à cette partie.
- **Ou en PowerShell**, sur l’**hôte** (PowerShell **administrateur**) : une seule commande crée les **3 disques** de 10 Go et les branche sur `PC01` (la VM peut rester allumée) :

  ```powershell
  $dossier = (Get-VM PC01).Path      # le dossier de PC01, ex. D:\HyperV\PC01
  foreach ($nom in "Data1", "Data2", "Data3") {
      New-VHD -Path "$dossier\$nom.vhdx" -SizeBytes 10GB -Dynamic
      Add-VMHardDiskDrive -VMName PC01 -Path "$dossier\$nom.vhdx"
  }
  Get-VMHardDiskDrive -VMName PC01   # vérification : 4 disques (le système + Data1, 2, 3)
  ```

---

## Partie A — Observer

**A1.** Dans `PC01`, liste les disques en PowerShell. Quel est le style de partition des nouveaux disques ?

**A2.** Lance `diskpart` et affiche les disques et les volumes. Quelles lettres sont déjà occupées, et par quoi ?

---

## Partie B — Préparer un disque de données

**B1.** Initialise le disque 1 en **GPT** (dans `diskmgmt.msc` ou en PowerShell). Les disques 2 et 3 doivent rester **non initialisés** pour la partie C.

**B2.** Crée une partition de **5 Go** avec la lettre `G:`, formatée en NTFS, nommée `Data` (assistant *Nouveau volume simple* ou PowerShell).

**B3.** Un collègue a tapé `New-Partition -DiskNumber 1 -Size 1GB -DriveLetter D` et obtenu *« The requested access path is already in use »*. Explique. La partition a-t-elle été créée ?

**B4.** Étends `G:` à tout l'espace disponible du disque, puis vérifie sa taille.

**B5.** Monte aussi ce volume dans le dossier `C:\Donnees`. Vérifie les deux chemins d'accès.

---

## Partie C — Espace de stockage en miroir (bonus)

**C1.** Liste les disques qui peuvent rejoindre un pool. Le disque 1 y figure-t-il ? Que faire si oui ?

**C2.** Crée le pool `Pool-Fournil` avec les disques 2 et 3, puis l'espace `Donnees-Miroir` en **miroir 2 voies**, formaté en NTFS avec la lettre `F:`.

**C3.** Quelle est la taille utilisable de `F:` ? Pourquoi pas 10 Go ?

**C4.** Écris un fichier `F:\recette.txt`.

**C5.** **Simule une panne** : sur l'hôte, détache `Data3.vhdx` de `PC01`. Dans `PC01`, relève l'état du pool, de l'espace et des disques physiques. Le fichier est-il encore lisible ?

**C6.** Rattache le disque. Que se passe-t-il ?

---

## Partie D — Systèmes de fichiers

**D1.** Un formateur doit copier une ISO de 8 Go sur une clé USB lisible sur Mac et Linux. Quel système de fichiers ?

**D2.** Pourquoi ne formate-t-on pas un disque de données Windows en exFAT ?

---

## Partie E — Exercices complémentaires (bonus)

**E1.** Sur l'hôte, ajoute à `PC01` un quatrième disque `Data4.vhdx` de 5 Go. Écris un script DiskPart (`diskpart /s`) qui nettoie **ce disque**, le convertit en GPT et crée une partition NTFS unique `Archives` en `H:`. Quelle commande du script est irréversible ? (Ne touche pas au disque 1 : `G:` sert encore aux TP 06 et 09.)

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp/standard-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp/standard-corrigev2)
