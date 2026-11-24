---
title: "TP 04. Disques, volumes et systèmes de fichiers, corrigé guidé"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/04-disques-stockage"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/04-disques-stockage-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Ta mission.** Prépare un disque de données dans `PC01` et, en atelier complémentaire, observe un miroir à deux disques. Sur l’hôte Hyper-V, dans **Paramètres de PC01 → Contrôleur SCSI → Disque dur**, ajoute un disque dynamique de **10 Go** nommé `Data1.vhdx`. Si ce disque est déjà attaché, passe à A1. Identifie le nouveau VHDX avant de formater quoi que ce soit.

> [!TIP] Ou en PowerShell (les 3 disques d’un coup)
> Sur l’**hôte**, dans PowerShell **administrateur** :
> ```powershell
> $dossier = (Get-VM PC01).Path      # le dossier de PC01, ex. D:\HyperV\PC01
> foreach ($nom in "Data1", "Data2", "Data3") {
>     New-VHD -Path "$dossier\$nom.vhdx" -SizeBytes 10GB -Dynamic
>     Add-VMHardDiskDrive -VMName PC01 -Path "$dossier\$nom.vhdx"
> }
> Get-VMHardDiskDrive -VMName PC01   # vérification : 4 disques (le système + Data1, 2, 3)
> ```
> `Data2` et `Data3` servent à l’atelier miroir : laisse-les vierges d’ici là.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp/standard)

## Identifier les disques et préparer le volume

### A1 — Comparer le disque système et les disques ajoutés

Sur `PC01`, ouvre PowerShell en administrateur. Lance `Get-Disk | Format-Table Number,FriendlyName,PartitionStyle,Size`. Dans `diskmgmt.msc`, confirme quel disque porte `C:` et quels disques sont vierges.

> [!success]- Afficher la correction — A1
> Le disque système est déjà partitionné. Les nouveaux VHDX sont normalement `RAW`. Les numéros peuvent différer si la VM a été modifiée. Identifie chaque disque par sa taille, son état et son rattachement sur l’hôte.

### A2 — Initialiser le disque de données

Dans **Gestion des disques**, mets en ligne puis initialise en **GPT** le disque de données identifié comme disque 1 dans le lab. Garde les deux disques destinés au miroir vierges.

> [!success]- Afficher la correction — A2
> L’espace apparaît comme **Non alloué** sur le disque GPT. Le volume système n’a subi aucune modification.

### A3 — Créer et agrandir le volume

Crée un **Nouveau volume simple** de 5 Go en `G:`, NTFS, nommé `Data`. Ouvre-le dans l’Explorateur et crée un fichier de test. Dans Gestion des disques, **Étendre le volume** sur `G:` ajoute le reste de l’espace.

> [!success]- Afficher la correction — A3
> `Get-Volume -DriveLetter G` affiche `Data`, `NTFS` et une taille supérieure à la taille de départ. Le fichier de test reste accessible.

### A4 — Ajouter un point de montage

Crée un dossier NTFS vide `C:\Donnees`. Dans **Gestion des disques → G: → Modifier la lettre de lecteur et les chemins d’accès → Ajouter**, sélectionne ce dossier et garde `G:`.

> [!success]- Afficher la correction — A4
> Le fichier de test est visible depuis `G:\` et depuis `C:\Donnees`. Les chemins pointent vers le même volume.

## Atelier complémentaire. Observer un miroir (bonus)

### B1 — Créer un pool et un espace en miroir

Sur l’hôte, ajoute deux VHDX vierges de **10 Go** nommés `Data2.vhdx` et `Data3.vhdx`. Dans les **Espaces de stockage** de `PC01`, crée `Pool-Fournil` avec ces deux disques. Crée l’espace `Donnees-Miroir` en **miroir bidirectionnel**, NTFS, lettre `F:`. Crée `F:\recette.txt`.

> [!success]- Afficher la correction — B1
> La capacité utilisable d’un miroir sur deux disques identiques est proche de celle d’un seul disque avant déduction des métadonnées. Les données sont écrites en deux exemplaires.

### B2 — Contrôler la disponibilité après le retrait d’un disque

Dans le lab, confirme sur l’hôte le chemin du VHDX `Data3.vhdx`, puis détache-le de `PC01`. Dans la VM, ouvre `F:\recette.txt` et relève l’état de l’espace avec `Get-VirtualDisk`. Rattache ensuite le même VHDX et observe la réparation.

> [!success]- Afficher la correction — B2
> Le fichier doit rester accessible avec un seul disque miroir disponible. L’état peut devenir dégradé. Après rattachement, surveille `Get-StorageJob` et attends le retour à un état sain avant tout autre retrait.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp/guide)
