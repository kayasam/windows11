# 15. Images WIM et DISM

> [!NOTE] Objectif
> Comprendre le format WIM, **capturer** l'image généralisée de `MASTER` (chapitre 14) avec DISM, la **maintenir hors ligne** (pilotes, mises à jour, applications, langues), et l'**appliquer** sur un disque vierge depuis Windows PE (`Dism /Apply-Image` + `bcdboot`).
>
> **Outils :** `dism.exe`, `Mount-VHD`/`Dismount-VHD` (Hyper-V), WinPE (chapitre 13)
> **Commandes à connaître :** `Dism /Capture-Image`, `Dism /Get-WimInfo`, `Dism /Mount-Image`, `Dism /Add-Driver`, `Dism /Add-Package`, `Dism /Unmount-Image`, `Dism /Apply-Image`, `bcdboot`

> [!INFO] Fil rouge — Fournil
> `D:\Images\MASTER.wim` capturée depuis l'hôte le 08/11/2026 (22 min, 8,3 Go). Le WinPE du chapitre 13 a été démarré sur une VM vierge pour la procédure d'application manuelle.

---

## Format WIM

**WIM** (Windows Imaging Format) est le format de fichier image utilisé par Windows depuis Vista, à la place des images secteur par secteur historiques.

| Caractéristique | Détail |
|-------------------|--------|
| **Basé sur les fichiers, pas les secteurs** | Une image WIM stocke une arborescence de fichiers, pas une copie brute du disque — elle peut donc être appliquée sur une partition de taille différente de l'originale |
| **Déduplication (single-instancing)** | Un même fichier identique présent dans plusieurs index n'est stocké **qu'une seule fois** physiquement dans le `.wim` |
| **Multi-index** | Un seul fichier `.wim` peut contenir **plusieurs images** (ex : Windows 11 Famille, Pro, Éducation dans le même `install.wim`), chacune identifiée par un numéro d'index |
| **Compression** | Compressible (`fast`, `max`, ou `none`), au prix du temps de capture/application |
| **Montable hors ligne** | Une image WIM peut être montée comme un dossier, modifiée, puis démontée — sans avoir à démarrer l'OS qu'elle contient |

```powershell
# Lister les index (images) contenus dans un fichier WIM
Get-WindowsImage -ImagePath "D:\Images\install.wim"

# Détails d'un index précis
Get-WindowsImage -ImagePath "D:\Images\install.wim" -Index 6
```

---

## Capturer une image avec DISM

`MASTER` a été généralisée et éteinte au chapitre 14. Plutôt que de démarrer un environnement WinPE, on peut **monter directement le VHDX** depuis l'hôte Hyper-V et capturer son contenu avec DISM.

> [!WARNING] Le checkpoint change quel fichier monter
> Depuis le `Checkpoint-VM "Avant-Sysprep"` (chapitre 14), `MASTER.vhdx` est devenu un disque **parent figé au moment du checkpoint** — donc **avant** Sysprep. Toutes les modifications faites depuis, y compris la généralisation elle-même, sont stockées dans un fichier de différence `.avhdx` séparé (visible à côté du `.vhdx` dans le dossier de la VM, nommé avec un GUID généré par Hyper-V). Monter directement `MASTER.vhdx` capturerait donc l'état **pré-Sysprep**, pas l'image généralisée qu'on veut réellement capturer.

Plutôt que deviner le nom du fichier `.avhdx`, on demande à Hyper-V quel est le disque **actuellement actif** de la VM — c'est automatiquement le bon fichier, avec ou sans checkpoint :

```powershell
# Depuis l'hôte : récupérer le chemin du disque actif de MASTER, puis le monter
$vhdPath = (Get-VMHardDiskDrive -VMName "MASTER").Path
Mount-VHD -Path $vhdPath -ReadOnly

# Identifier la lettre de lecteur attribuée au volume monté
Get-Disk | Where-Object OperationalStatus -eq "Online" | Get-Partition | Select-Object DriveLetter, Size
```

```cmd
:: Capturer le volume monté (ex: lettre E:) en image WIM
Dism /Capture-Image /ImageFile:D:\Images\MASTER.wim /CaptureDir:E:\ /Name:"MASTER-Fournil-2026-11" /Description:"Windows 11 Pro 26H2 Fournil" /Compress:max /CheckIntegrity
```

Relevé sur le lab (hôte, SSD NVMe) :

```
Disque actif : D:\HyperV\MASTER\MASTER_323716A8-0C9C-4085-929E-DC21A6A1633E.avhdx   ← le .avhdx, pas le .vhdx
Volume Windows de MASTER monté en E:
[==========================100.0%==========================]
L'opération a réussi.
Durée : 22.4 min

MASTER.wim  8,32 Go  (image décompressée : 30,9 Go)
```

> [!TIP] Une image plus légère
> 8,3 Go, c'est beaucoup — et ça dépasse la limite de 4 Go d'un fichier sur une clé USB FAT32. Avant Sysprep, en mode audit : `Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase` (supprime les anciennes versions des composants), `Delete-DeliveryOptimizationCache -Force`, `cleanmgr /sageset` puis `/sagerun`. Pour une clé USB : `Dism /Split-Image /ImageFile:MASTER.wim /SWMFile:MASTER.swm /FileSize:3800`.

```powershell
# Démonter en utilisant le même chemin
Dismount-VHD -Path $vhdPath
```

> [!TIP] Pourquoi monter le VHDX plutôt que démarrer une VM WinPE
> Hyper-V permet de monter un VHDX directement comme un disque sur l'hôte (`Mount-VHD`), sans avoir besoin de créer une VM WinPE dédiée juste pour la capture — plus rapide et plus simple en environnement de lab. `Mount-VHD` sur un fichier `.avhdx` résout automatiquement la chaîne parent/différence et présente le contenu fusionné, sans opération de fusion (`merge`) préalable — le checkpoint reste donc intact après la capture, disponible pour un futur rafraîchissement (chapitre 14). En dehors d'Hyper-V (poste physique par exemple), la capture se ferait effectivement en démarrant sur un support WinPE.

---

## Monter, modifier et démonter une image

Une fois capturée (ou pour modifier une image existante comme `install.wim`), DISM permet de **monter** un index précis comme un dossier accessible en lecture/écriture.

```powershell
# Monter l'index 1 de l'image dans un dossier de travail
New-Item -Path "C:\Mount" -ItemType Directory -Force
Dism /Mount-Image /ImageFile:D:\Images\MASTER.wim /Index:1 /MountDir:C:\Mount

# L'image est maintenant explorable comme un dossier classique
Get-ChildItem C:\Mount\Windows\System32 | Select-Object -First 5

# Démonter en enregistrant les modifications
Dism /Unmount-Image /MountDir:C:\Mount /Commit

# Démonter en annulant les modifications faites pendant le montage
Dism /Unmount-Image /MountDir:C:\Mount /Discard
```

> [!WARNING] Ne jamais supprimer le dossier de montage sans démonter proprement
> Supprimer directement `C:\Mount` ou éteindre la machine sans avoir démonté correctement laisse l'image dans un état "sale" (verrouillée). Utiliser `Dism /Cleanup-Wim` pour nettoyer les montages orphelins :
> ```cmd
> Dism /Cleanup-Wim
> ```

---

## Injection de pilotes et mises à jour hors ligne

Modifier une image montée permet d'ajouter des pilotes ou des correctifs **sans jamais démarrer** le Windows qu'elle contient — utile pour préparer une image compatible avec du matériel qui n'était pas présent sur la machine de référence.

```cmd
:: Ajouter un pilote unique (fichier .inf)
Dism /Image:C:\Mount /Add-Driver /Driver:C:\Drivers\reseau.inf

:: Ajouter tous les pilotes d'un dossier, y compris ses sous-dossiers
Dism /Image:C:\Mount /Add-Driver /Driver:C:\Drivers /Recurse

:: Lister les pilotes déjà présents dans l'image montée
Dism /Image:C:\Mount /Get-Drivers

:: Appliquer une mise à jour hors ligne (fichier .msu ou .cab)
Dism /Image:C:\Mount /Add-Package /PackagePath:C:\Updates\KB5041160.msu
```

> [!NOTE] Cas d'usage typique : le "pilote manquant au premier démarrage"
> Si le matériel cible (carte réseau, contrôleur de stockage) n'a pas de pilote **en boîte** dans Windows, le poste déployé peut se retrouver sans réseau au premier démarrage. Injecter le pilote directement dans l'image évite ce problème sans intervention manuelle après déploiement.

---

## Maintenance hors ligne : applications, langues, informations

Sur une image **montée** (`/Image:C:\Mount`), DISM sait faire presque tout ce qu'on ferait sur un poste démarré :

```cmd
:: Informations sur l'image et ses index
Dism /Get-WimInfo /WimFile:D:\Images\MASTER.wim
Dism /Get-WimInfo /WimFile:D:\Images\MASTER.wim /Index:1

:: Applications provisionnées : lister, retirer
Dism /Image:C:\Mount /Get-ProvisionedAppxPackages
Dism /Image:C:\Mount /Remove-ProvisionedAppxPackage /PackageName:Microsoft.BingWeather_4.53.52892.0_neutral_~_8wekyb3d8bbwe

:: Fonctionnalités Windows et capacités (FoD) — source = l'ISO des Features on Demand
Dism /Image:C:\Mount /Get-Features
Dism /Image:C:\Mount /Enable-Feature /FeatureName:NetFx3 /Source:E:\sources\sxs

:: Module linguistique (fichier .cab de l'ISO « Languages and Optional Features »)
Dism /Image:C:\Mount /Add-Package /PackagePath:E:\LanguagesAndOptionalFeatures\Microsoft-Windows-Client-Language-Pack_x64_es-es.cab
Dism /Image:C:\Mount /Set-AllIntl:es-ES

:: Nettoyer l'image après ajout de mises à jour (réduit la taille)
Dism /Image:C:\Mount /Cleanup-Image /StartComponentCleanup /ResetBase
```

Équivalents PowerShell : `Mount-WindowsImage`, `Add-WindowsDriver`, `Add-WindowsPackage`, `Get-AppxProvisionedPackage -Path`, `Dismount-WindowsImage -Save`.

---

## Appliquer une image depuis Windows PE

C'est ce que fait Windows Setup en coulisses, et ce que font tous les outils de déploiement : **partitionner**, **appliquer** le WIM, **rendre le disque démarrable**. On peut le faire à la main depuis le WinPE du chapitre 13 — indispensable quand on n'a ni ISO personnalisée ni infrastructure.

### 1. Préparer un script de partitionnement UEFI

`partition-uefi.txt` (sur le support qui contient l'image) :

```
select disk 0
clean
convert gpt
create partition efi size=200
format quick fs=fat32 label="System"
assign letter=S
create partition msr size=16
create partition primary
format quick fs=ntfs label="Windows"
assign letter=W
exit
```

### 2. Démarrer sur WinPE et identifier les disques

```powershell
powershell -NoProfile -Command "Get-Disk | Format-Table Number,FriendlyName,Size,PartitionStyle; Get-Volume | Format-Table DriveLetter,FileSystemLabel,Size"
```

![w11-15-winpe-powershell-disques](https://cours.kaya.ovh/windows11/assets/captures/w11-15-winpe-powershell-disques.png)

*WinPE du chapitre 13 sur une VM vierge : PowerShell 5.1 disponible, disque 0 vierge (RAW, cible), disque d'images monté en **C:** — dans WinPE, les lettres ne sont jamais celles de Windows. Toujours vérifier avant `clean`.*

### 3. Partitionner, appliquer, rendre démarrable

```cmd
diskpart /s C:\partition-uefi.txt
dism /Apply-Image /ImageFile:C:\MASTER.wim /Index:1 /ApplyDir:W:\
bcdboot W:\Windows /s S: /f UEFI
wpeutil reboot
```

| Commande | Rôle |
|----------|------|
| `diskpart /s` | Crée EFI (S:) + MSR + Windows (W:) |
| `Dism /Apply-Image` | Décompresse le WIM sur W: (≈ 10 min pour 8 Go) |
| `bcdboot W:\Windows /s S: /f UEFI` | Copie le gestionnaire de démarrage dans la partition EFI et crée le magasin BCD |
| `wpeutil reboot` | Redémarre : la passe **specialize** puis **oobeSystem** de l'image généralisée se jouent |

> [!NOTE] Rejoué de bout en bout sur le lab formateur (08/11/2026)
> VM vierge `PC03` démarrée sur le WinPE du chapitre 13, script `deploie.cmd` : `diskpart` → `Dism /Apply-Image` (100 %) → `bcdboot` (« *Boot files successfully created* ») → copie d'un `unattend.xml` (passes specialize + oobeSystem, `ComputerName = PC03`) dans `W:\Windows\Panther` → `wpeutil reboot`. **Une minute plus tard, `PC03` était sur le bureau, session `Utilisateur`, image Fournil.** Un premier essai avait échoué faute de place sur l'hôte : prévoir **au moins 40 Go libres**.
>
> ![w11-15-winpe-apply-image](https://cours.kaya.ovh/windows11/assets/captures/w11-15-winpe-apply-image.png)

> [!WARNING] Espace disque de l'hôte
> Une VM Hyper-V dont le disque dynamique ne peut plus grandir passe en état **PausedCritical** (`Get-VM` → *State*) : elle est gelée, sans erreur visible dans la VM. Libérer de la place, puis `Resume-VM`. À surveiller pendant tout le jour 4 (WIM de 8 Go, ISO de 9 Go, copies…).

> [!NOTE] Et le fichier de réponse ?
> Une image généralisée appliquée ainsi démarre sur l'**OOBE** classique. Pour l'automatiser, on copie un `unattend.xml` (passes specialize/oobeSystem) dans `W:\Windows\Panther\unattend.xml` **avant** de redémarrer — c'est exactement le rôle que joue l'`autounattend.xml` à la racine de l'ISO au chapitre 16.

---

## Récapitulatif

```
Format WIM
  Basé fichiers (pas secteurs) | déduplication | multi-index dans un seul .wim

Capture (MASTER généralisée et éteinte, chapitre 14)
  $vhdPath = (Get-VMHardDiskDrive -VMName "MASTER").Path   ← disque actif, pas forcément MASTER.vhdx (checkpoint = .avhdx)
  Mount-VHD -Path $vhdPath -ReadOnly → Dism /Capture-Image /CaptureDir:E:\ → Dismount-VHD -Path $vhdPath

Montage / modification / démontage
  Dism /Mount-Image /Index:N /MountDir:...
  Dism /Unmount-Image /Commit (garder) ou /Discard (annuler)
  Dism /Cleanup-Wim si un montage reste bloqué

Pilotes et mises à jour hors ligne
  Dism /Image:... /Add-Driver /Driver:... [/Recurse]
  Dism /Image:... /Add-Package /PackagePath:...msu

Maintenance hors ligne
  /Get-WimInfo | /Remove-ProvisionedAppxPackage | /Enable-Feature /Source | langues | /Cleanup-Image /ResetBase

Application depuis WinPE
  diskpart /s partition-uefi.txt → Dism /Apply-Image /ApplyDir:W:\ → bcdboot W:\Windows /s S: /f UEFI
  Lettres différentes dans WinPE : vérifier avec Get-Volume avant "clean"

→ Chapitre 16 : MASTER.wim intégrée dans une ISO de déploiement personnalisée
```
