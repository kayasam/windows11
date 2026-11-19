# TP 04. Disques, volumes et systèmes de fichiers, version guidée

**Ta mission.** Prépare un disque de données dans `PC01` et, en atelier complémentaire, observe un miroir à deux disques. Sur l’hôte Hyper-V, dans **Paramètres de PC01 → Contrôleur SCSI → Disque dur**, ajoute un disque dynamique de **10 Go** nommé `Data1.vhdx`. Si ce disque est déjà attaché, passe à A1. Identifie le nouveau VHDX avant de formater quoi que ce soit.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp/standard)

## Identifier les disques et préparer le volume

### A1 — Comparer le disque système et les disques ajoutés

Sur `PC01`, ouvre PowerShell en administrateur. Lance `Get-Disk | Format-Table Number,FriendlyName,PartitionStyle,Size`. Dans `diskmgmt.msc`, confirme quel disque porte `C:` et quels disques sont vierges.

### A2 — Initialiser le disque de données

Dans **Gestion des disques**, mets en ligne puis initialise en **GPT** le disque de données identifié comme disque 1 dans le lab. Garde les deux disques destinés au miroir vierges.

### A3 — Créer et agrandir le volume

Crée un **Nouveau volume simple** de 5 Go en `G:`, NTFS, nommé `Data`. Ouvre-le dans l’Explorateur et crée un fichier de test. Dans Gestion des disques, **Étendre le volume** sur `G:` ajoute le reste de l’espace.

### A4 — Ajouter un point de montage

Crée un dossier NTFS vide `C:\Donnees`. Dans **Gestion des disques → G: → Modifier la lettre de lecteur et les chemins d’accès → Ajouter**, sélectionne ce dossier et garde `G:`.

## Atelier complémentaire. Observer un miroir (bonus)

### B1 — Créer un pool et un espace en miroir

Sur l’hôte, ajoute deux VHDX vierges de **10 Go** nommés `Data2.vhdx` et `Data3.vhdx`. Dans les **Espaces de stockage** de `PC01`, crée `Pool-Fournil` avec ces deux disques. Crée l’espace `Donnees-Miroir` en **miroir bidirectionnel**, NTFS, lettre `F:`. Crée `F:\recette.txt`.

### B2 — Contrôler la disponibilité après le retrait d’un disque

Dans le lab, confirme sur l’hôte le chemin du VHDX `Data3.vhdx`, puis détache-le de `PC01`. Dans la VM, ouvre `F:\recette.txt` et relève l’état de l’espace avec `Get-VirtualDisk`. Rattache ensuite le même VHDX et observe la réparation.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp/guide-corrigev2)
