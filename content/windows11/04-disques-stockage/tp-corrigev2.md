---
title: "TP 04. Disques, volumes et systèmes de fichiers — Correction"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/04-disques-stockage"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/04-disques-stockage-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp-corrigev2" aria-current="page">Corrigé</a></nav>

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h15

> Chapitres associés : [04. Disques, volumes et systèmes de fichiers](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/)

---

## Objectifs

- Ajouter des disques à une VM et les préparer (GPT, partition, NTFS)
- Utiliser `diskmgmt.msc`, `diskpart` et le module PowerShell `Storage`
- Monter un volume dans un dossier
- Créer un espace de stockage en miroir et **simuler la panne d'un disque**

---

## Prérequis

- `PC01` opérationnel (TP 03)
- Sur l'**hôte**, créer et attacher trois disques de 10 Go à `PC01` (VM allumée, ajout à chaud) :

```powershell
1..3 | ForEach-Object {
    New-VHD -Path "D:\HyperV\PC01\Data$_.vhdx" -SizeBytes 10GB -Dynamic | Out-Null
    Add-VMHardDiskDrive -VMName PC01 -Path "D:\HyperV\PC01\Data$_.vhdx"
}
```

---

## Partie A — Observer (10 min)

**A1.** Dans `PC01`, liste les disques en PowerShell. Quel est le style de partition des nouveaux disques ?

> [!success]- Afficher la correction — A1
> ```powershell
> Get-Disk | Select-Object Number, FriendlyName, PartitionStyle, OperationalStatus, @{N="Go";E={$_.Size/1GB}}
> ```
> ```
> Number FriendlyName      PartitionStyle OperationalStatus Go
> ------ ------------      -------------- ----------------- --
>      0 Msft Virtual Disk GPT            Online            64
>      1 Msft Virtual Disk RAW            Online            10
>      2 Msft Virtual Disk RAW            Online            10
>      3 Msft Virtual Disk RAW            Online            10
> ```
> **RAW** : jamais initialisés, pas de table de partitions.

**A2.** Lance `diskpart` et affiche les disques et les volumes. Quelles lettres sont déjà occupées, et par quoi ?

> [!success]- Afficher la correction — A2
> ```
> DISKPART> list volume
>   N° volume   Ltr  Nom          Fs     Type        Taille   Statut
>   Volume 0     D   CCCOMA_X64F  UDF    DVD-ROM        8 G   Sain
>   Volume 1     E   CCCOMA_X64F  UDF    DVD-ROM        8 G   Sain
>   Volume 2     C   Windows      NTFS   Partition     62 G   Sain       Démarrage
>   Volume 3         SYSTEM       FAT32  Partition    200 M   Sain       Système
>   Volume 4                      NTFS   Partition    906 M   Sain       Masqué
> ```
> `C:` Windows, `D:` et `E:` = les **deux lecteurs DVD** de la VM (ISO d'installation, ISO de réponse). La partition EFI (FAT32) et la récupération (906 Mo) n'ont pas de lettre, c'est normal.

---

## Partie B — Préparer un disque de données (20 min)

**B1.** Initialise le disque 1 en **GPT**.

> [!success]- Afficher la correction — B1
> ```powershell
> Initialize-Disk -Number 1 -PartitionStyle GPT
> ```

**B2.** Crée une partition de **5 Go** avec la lettre `G:`, formatée en NTFS, nommée `Data`.

> [!success]- Afficher la correction — B2
> ```powershell
> New-Partition -DiskNumber 1 -Size 5GB -DriveLetter G |
>     Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data" -Confirm:$false
> ```

**B3.** Un collègue a tapé `-DriveLetter E` et obtenu *« The requested access path is already in use »*. Explique.

> [!success]- Afficher la correction — B3
> `E:` est déjà attribuée — ici au second lecteur DVD (voir A2). La partition est quand même créée, **sans lettre** : il faut la retrouver (`Get-Partition -DiskNumber 1`) et lui attribuer une lettre libre (`Set-Partition -NewDriveLetter G`), ou la supprimer et recommencer. Toujours regarder `Get-Volume` avant de choisir une lettre.

**B4.** Étends `G:` à tout l'espace disponible du disque, puis vérifie sa taille.

> [!success]- Afficher la correction — B4
> ```powershell
> Resize-Partition -DriveLetter G -Size (Get-PartitionSupportedSize -DriveLetter G).SizeMax
> Get-Volume G | Select-Object DriveLetter, @{N="Go";E={[math]::Round($_.Size/1GB,1)}}
> ```
> `G:` passe de 5 Go à ~10 Go (taille du disque moins la partition MSR).

**B5.** Monte aussi ce volume dans le dossier `C:\Donnees`. Vérifie les deux chemins d'accès.

> [!success]- Afficher la correction — B5
> ```powershell
> New-Item C:\Donnees -ItemType Directory
> Add-PartitionAccessPath -DriveLetter G -AccessPath "C:\Donnees"
> Get-Partition -DriveLetter G | Select-Object AccessPaths
> ```
> ```
> AccessPaths : {G:\, C:\Donnees\, \\?\Volume{9855d2d5-...}\}
> ```
> Le même volume est accessible par trois chemins. Le dossier de montage doit être **vide** et sur un volume **NTFS**.

---

## Partie C — Espace de stockage en miroir (25 min)

**C1.** Liste les disques qui peuvent rejoindre un pool. Le disque 1 y figure-t-il ? Que faire si oui ?

> [!success]- Afficher la correction — C1
> ```powershell
> Get-PhysicalDisk | Select-Object DeviceId, CanPool, CannotPoolReason
> ```
> Juste après la partie B, il arrive que le disque 1 apparaisse encore avec `CanPool = True` (information en cache) : `New-StoragePool` échoue alors avec « *L'espace utilisable pour cette opération est insuffisant* ». On rafraîchit :
> ```powershell
> Update-StorageProviderCache -DiscoveryLevel Full
> Get-PhysicalDisk | Select-Object DeviceId, CanPool, CannotPoolReason
> ```
> ```
> DeviceId CanPool CannotPoolReason
> -------- ------- ----------------
> 0          False Insufficient Capacity
> 2           True
> 3           True
> 1          False Insufficient Capacity
> ```

**C2.** Crée le pool `Pool-Fournil` avec les disques 2 et 3, puis l'espace `Donnees-Miroir` en **miroir 2 voies**, formaté en NTFS avec la lettre `F:`.

> [!success]- Afficher la correction — C2
> ```powershell
> $disques = Get-PhysicalDisk | Where-Object DeviceId -in '2','3'
> New-StoragePool -FriendlyName "Pool-Fournil" `
>     -StorageSubSystemFriendlyName (Get-StorageSubSystem).FriendlyName -PhysicalDisks $disques
> New-VirtualDisk -StoragePoolFriendlyName "Pool-Fournil" -FriendlyName "Donnees-Miroir" `
>     -UseMaximumSize -ResiliencySettingName Mirror
> Get-VirtualDisk -FriendlyName "Donnees-Miroir" | Get-Disk |
>     Initialize-Disk -PartitionStyle GPT -PassThru |
>     New-Partition -UseMaximumSize -DriveLetter F |
>     Format-Volume -FileSystem NTFS -NewFileSystemLabel "Donnees-Miroir" -Confirm:$false
> ```
> Désigner les disques par leur `DeviceId` est plus sûr que `-CanPool $true` : on sait exactement ce qu'on met dans le pool.
> En graphique : **Panneau de configuration → Système et sécurité → Espaces de stockage**.

**C3.** Quelle est la taille utilisable de `F:` ? Pourquoi pas 10 Go ?

> [!success]- Afficher la correction — C3
> ```
> Pool-Fournil    19 Go (2 × 10 Go moins les métadonnées)
> Donnees-Miroir   8 Go, NumberOfDataCopies = 2
> ```
> En miroir 2 voies, chaque bloc est écrit **deux fois** : on ne dispose que de la moitié du pool, moins l'espace réservé par Storage Spaces (métadonnées, réserve de réparation). Sur `PC01` : **8 Go** utiles pour 20 Go de disques.

**C4.** Écris un fichier `F:\recette.txt`.

> [!success]- Afficher la correction — C4
> ```powershell
> Set-Content F:\recette.txt "Pain de campagne : farine T80, levain, sel"
> ```

**C5.** **Simule une panne** : sur l'hôte, détache `Data3.vhdx` de `PC01`. Dans `PC01`, relève l'état du pool, de l'espace et des disques physiques. Le fichier est-il encore lisible ?

> [!success]- Afficher la correction — C5
> Sur l'hôte :
> ```powershell
> Get-VMHardDiskDrive PC01 | Where-Object Path -like '*Data3*' | Remove-VMHardDiskDrive
> ```
> Dans `PC01` :
> ```powershell
> Get-StoragePool Pool-Fournil | Select-Object FriendlyName, HealthStatus, OperationalStatus
> Get-VirtualDisk Donnees-Miroir | Select-Object FriendlyName, HealthStatus, OperationalStatus
> Get-PhysicalDisk | Select-Object DeviceId, HealthStatus, OperationalStatus
> Get-Content F:\recette.txt
> ```
> ```
> Pool-Fournil    Warning  Degraded
> Donnees-Miroir  Warning  {Degraded, Incomplete}
> (disque perdu)  Warning  Lost Communication
> Pain de campagne : farine T80, levain, sel
> ```
> Le miroir est **dégradé** mais les données restent **lisibles et modifiables** : c'est tout l'intérêt de la résilience. En revanche, une seconde panne serait fatale : il faut remplacer le disque rapidement (et surveiller ces états, chapitre 21).

**C6.** Rattache le disque. Que se passe-t-il ?

> [!success]- Afficher la correction — C6
> ```powershell
> Add-VMHardDiskDrive -VMName PC01 -Path D:\HyperV\PC01\Data3.vhdx   # sur l'hôte
> ```
> Quelques secondes plus tard, dans `PC01` : `Donnees-Miroir  Healthy  OK`. Storage Spaces resynchronise automatiquement les blocs modifiés pendant l'absence du disque (`Get-StorageJob` montre la réparation sur de gros volumes).
> Avec un disque **neuf** à la place de l'ancien, il faudrait l'ajouter au pool (`Add-PhysicalDisk`), retirer l'ancien (`Remove-PhysicalDisk`) puis lancer `Repair-VirtualDisk`.

---

## Partie D — Systèmes de fichiers (10 min)

**D1.** Un formateur doit copier une ISO de 8 Go sur une clé USB lisible sur Mac et Linux. Quel système de fichiers ?

> [!success]- Afficher la correction — D1
> **exFAT** : lisible et inscriptible par Windows, macOS et Linux, sans la limite de 4 Go par fichier de FAT32.

**D2.** Pourquoi ne formate-t-on pas un disque de données Windows en exFAT ?

> [!success]- Afficher la correction — D2
> exFAT n'a **ni permissions** (pas d'ACL NTFS : tout le monde lit tout), ni journalisation (risque de corruption en cas de coupure), ni chiffrement EFS, ni quotas, ni compression, ni points de montage. NTFS reste la norme pour un disque interne.

---

## Partie E — Bonus

**E1.** Écris un script DiskPart (`diskpart /s`) qui nettoie le disque 1, le convertit en GPT et crée une partition NTFS unique `Archives` en `H:`. Quelle commande du script est irréversible ?

> [!success]- Afficher la correction — E1
> `C:\Temp\archives.txt` :
> ```
> select disk 1
> clean
> convert gpt
> create partition primary
> format fs=ntfs label="Archives" quick
> assign letter=H
> ```
> ```cmd
> diskpart /s C:\Temp\archives.txt
> ```
> `clean` efface la table de partitions : **irréversible** (et il faut d'abord retirer le point de montage `C:\Donnees`). C'est exactement le genre de script qu'on retrouvera dans un fichier de réponse ou une séquence de déploiement (partitionnement automatisé, chapitre 16) — d'où l'importance du `select disk` correct.

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp)
