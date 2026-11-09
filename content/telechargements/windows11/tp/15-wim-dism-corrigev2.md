# TP 15 — Images WIM et DISM — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h45

> Chapitres associés : [15. Images WIM et DISM](https://kayasam.github.io/windows11/windows11/15-wim-dism/)

---

## Objectifs

- Capturer l'image généralisée de `MASTER` depuis l'hôte
- Inspecter un fichier WIM (index, tailles, édition)
- Monter une image et la modifier hors ligne (applications, pilotes)
- Découper une image pour une clé USB
- Appliquer une image à la main depuis Windows PE

---

## Prérequis

- `MASTER` généralisée et **éteinte** (TP 14), avec son point de contrôle `Avant-Sysprep`
- WinPE personnalisé (TP 13)
- **40 Go libres** sur le disque de l'hôte

---

## Partie A — Capture (30 min)

**A1.** Quel fichier disque faut-il monter pour capturer `MASTER` ? Pourquoi pas `MASTER.vhdx` ?

> [!success]- Afficher la correction — A1
> Le **disque actif** de la VM : depuis le point de contrôle `Avant-Sysprep`, toutes les écritures (dont la généralisation) vont dans un `.avhdx`. `MASTER.vhdx` est figé **avant** Sysprep : le capturer donnerait une image non généralisée.
> ```powershell
> (Get-VMHardDiskDrive -VMName MASTER).Path
> # …\MASTER_323716A8-0C9C-4085-929E-DC21A6A1633E.avhdx
> ```

**A2.** Monte le disque actif en **lecture seule**, repère la lettre du volume Windows, vérifie que c'est bien l'image Fournil.

> [!success]- Afficher la correction — A2
> ```powershell
> $vhdPath = (Get-VMHardDiskDrive -VMName MASTER).Path
> Mount-VHD -Path $vhdPath -ReadOnly
> Get-Disk | Where-Object Location -like "*MASTER*" | Get-Partition | Select-Object DriveLetter, Type, Size
> Get-Content E:\Fournil\version-image.txt      # Image Fournil v2026.11 - 2026-11-08T07:10:21
> ```
> `-ReadOnly` : on ne risque pas de modifier l'image (ni de casser la chaîne de différenciation).

**A3.** Capture le volume dans `D:\Images\MASTER.wim` (nom « MASTER-Fournil-2026-11 », compression maximale, contrôle d'intégrité). Combien de temps ? Quelle taille ?

> [!success]- Afficher la correction — A3
> ```cmd
> Dism /Capture-Image /ImageFile:D:\Images\MASTER.wim /CaptureDir:E:\ /Name:"MASTER-Fournil-2026-11" ^
>      /Description:"Windows 11 Pro 26H2 Fournil" /Compress:max /CheckIntegrity
> ```
> Sur le lab : **22 minutes**, **8,32 Go**. DISM exclut automatiquement `pagefile.sys`, `hiberfil.sys`, `swapfile.sys` et `System Volume Information`.

**A4.** Démonte le disque. Le point de contrôle de `MASTER` est-il toujours utilisable ?

> [!success]- Afficher la correction — A4
> ```powershell
> Dismount-VHD -Path $vhdPath
> Get-VMCheckpoint -VMName MASTER      # Avant-Sysprep toujours présent
> ```
> Oui : le montage en lecture seule n'a rien fusionné. On pourra revenir à `Avant-Sysprep` le mois prochain.

---

## Partie B — Inspecter (15 min)

**B1.** Affiche les informations de `MASTER.wim`, puis le détail de l'index 1. Combien d'index ? Quelle édition ? Quelle taille décompressée ?

> [!success]- Afficher la correction — B1
> ```cmd
> Dism /Get-WimInfo /WimFile:D:\Images\MASTER.wim
> Dism /Get-WimInfo /WimFile:D:\Images\MASTER.wim /Index:1
> ```
> ```
> Index : 1
> Nom : MASTER-Fournil-2026-11
> Taille : 33 184 210 905 octets
> Architecture : x64
> Version : 10.0.26300
> ```
> **1 index**, édition Professionnel, **31 Go décompressés** pour 8,3 Go sur disque (compression *max* + déduplication des fichiers).

**B2.** Compare avec le `install.wim` de l'ISO officielle.

> [!success]- Afficher la correction — B2
> `install.wim` de l'ISO 26H2 française : **11 index** (Famille, Éducation, Pro, Pro N, Pro Éducation, Pro Stations de travail…) dans un seul fichier de ~6 Go — la déduplication rend l'ajout d'une édition presque gratuit. `MASTER.wim` n'a qu'un index, mais contient nos logiciels et réglages.

---

## Partie C — Maintenance hors ligne (30 min)

**C1.** Monte l'index 1 de `MASTER.wim` dans `C:\Mount`.

> [!success]- Afficher la correction — C1
> ```cmd
> mkdir C:\Mount
> Dism /Mount-Image /ImageFile:D:\Images\MASTER.wim /Index:1 /MountDir:C:\Mount
> ```
> > [!WARNING] « Impossible d'accéder à l'image » : attribut lecture seule
> > Vécu sur le lab : un `.wim` **copié depuis une ISO** garde l'attribut *lecture seule*, et `Dism /Mount-Image` échoue (l'image ne peut pas être montée en écriture). `attrib -r D:\Images\MASTER.wim` (ou ajouter `/ReadOnly` au montage si on veut seulement lire).

**C2.** Liste les applications provisionnées de l'image montée et retire `Microsoft.BingWeather`.

> [!success]- Afficher la correction — C2
> ```cmd
> Dism /Image:C:\Mount /Get-ProvisionedAppxPackages
> Dism /Image:C:\Mount /Remove-ProvisionedAppxPackage /PackageName:Microsoft.BingWeather_4.54.63038.0_neutral_~_8wekyb3d8bbwe
> ```
> Sur le lab : **45** applications provisionnées dans `MASTER.wim` (BingNews, Clipchamp, Solitaire et GamingApp ont déjà été retirés au TP 14). Le **nom complet** du paquet est obligatoire.
> En PowerShell sur l'hôte : `Get-AppxProvisionedPackage -Path C:\Mount` — qui a échoué sur l'hôte du lab sous PowerShell 7 (« Classe non enregistrée ») : utiliser Windows PowerShell 5.1 ou `dism.exe`.

**C3.** Ajoute un pilote (`.inf`) à l'image montée. Où trouver un pilote pour le test ?

> [!success]- Afficher la correction — C3
> ```cmd
> Dism /Image:C:\Mount /Add-Driver /Driver:C:\Drivers\Reseau /Recurse
> Dism /Image:C:\Mount /Get-Drivers /Format:Table
> ```
> Source pour le test : l'export du TP 05 (`C:\Sauvegarde\Pilotes`), ou un pilote du magasin de l'hôte (`C:\Windows\System32\DriverStore\FileRepository\netvsc.inf_amd64_…\netvsc.inf`). En production : le pack de pilotes du constructeur (*Driver Pack* Dell/HP/Lenovo, au format `.inf`).

**C4.** Démonte en **enregistrant**. Que se passe-t-il si on supprime `C:\Mount` sans démonter ?

> [!success]- Afficher la correction — C4
> ```cmd
> Dism /Unmount-Image /MountDir:C:\Mount /Commit
> ```
> Supprimer `C:\Mount` sans démonter laisse un montage **orphelin** : l'image reste verrouillée et les montages suivants échouent. Réparation : `Dism /Cleanup-Wim` (et `Dism /Get-MountedWimInfo` pour voir l'état).

---

## Partie D — Clé USB (10 min)

**D1.** Pourquoi `MASTER.wim` ne peut-il pas être copié tel quel sur une clé USB de démarrage UEFI ? Découpe-le en morceaux de 3,8 Go.

> [!success]- Afficher la correction — D1
> Une clé UEFI démarrable doit être en **FAT32** : 4 Go maximum par fichier. `MASTER.wim` fait 8,3 Go.
> ```cmd
> Dism /Split-Image /ImageFile:D:\Images\MASTER.wim /SWMFile:D:\Images\MASTER.swm /FileSize:3800
> ```
> Résultat sur le lab : `MASTER.swm` (3,65 Go), `MASTER2.swm` (3,70 Go), `MASTER3.swm` (0,97 Go). Windows Setup accepte directement un `sources\install.swm` découpé.

---

## Partie E — Appliquer depuis WinPE (20 min)

**E1.** Prépare un disque contenant `MASTER.wim` et le script `partition-uefi.txt`. Démarre une VM vierge sur le WinPE du TP 13, avec ce disque attaché.

> [!success]- Afficher la correction — E1
> Sur l'hôte, un disque virtuel `Images.vhdx` (NTFS) contenant `MASTER.wim` et `partition-uefi.txt` (voir le cours), attaché comme second disque à une VM Gen 2 vierge qui démarre sur `WinPE-Fournil.iso`.

**E2.** Identifie le disque cible et la lettre du disque d'images. Pourquoi cette étape est-elle vitale ?

> [!success]- Afficher la correction — E2
> ```cmd
> powershell -NoProfile -Command "Get-Disk | Format-Table Number,FriendlyName,Size,PartitionStyle; Get-Volume | Format-Table DriveLetter,FileSystemLabel,Size"
> ```
> ![w11-15-winpe-powershell-disques](https://kayasam.github.io/windows11/assets/captures/w11-15-winpe-powershell-disques.png)
>
> Disque **0** = cible (64 Go, RAW). Le disque d'images a reçu la lettre **C:** dans WinPE ! Le script `diskpart` commence par `select disk 0` puis `clean` : se tromper de numéro efface le mauvais disque. Toujours vérifier.

**E3.** Partitionne, applique l'image, rends le disque démarrable.

> [!success]- Afficher la correction — E3
> ```cmd
> diskpart /s C:\partition-uefi.txt
> dism /Apply-Image /ImageFile:C:\MASTER.wim /Index:1 /ApplyDir:W:\
> bcdboot W:\Windows /s S: /f UEFI
> wpeutil reboot
> ```
> Prévoir **40 Go libres sur l'hôte** : l'image décompressée fait 31 Go (sur le lab, un hôte saturé a figé les VM en *PausedCritical*).

**E4.** Au redémarrage, que voit-on ? Comment l'automatiser ?

> [!success]- Afficher la correction — E4
> L'image généralisée joue **specialize** puis affiche l'**OOBE** (pays, clavier, compte…), puisque rien ne lui fournit de réponses. Pour automatiser : avant `wpeutil reboot`,
> ```cmd
> mkdir W:\Windows\Panther
> copy C:\unattend.xml W:\Windows\Panther\unattend.xml
> ```
> avec un fichier contenant les passes specialize et oobeSystem du TP 13.

---

[Retour à l'énoncé](https://kayasam.github.io/windows11/windows11/15-wim-dism/tp)
