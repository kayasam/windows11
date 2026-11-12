---
title: "TP 17. Déployer Windows 11 par le réseau : PXE et WDS — Correction"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/17-wds-pxe"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/17-wds-pxe-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp-corrigev2" aria-current="page">Corrigé</a></nav>

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 2h30

> Chapitres associés : [17. Déployer Windows 11 par le réseau : PXE et WDS](https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/)

---

## Objectifs

- Installer et configurer WDS sur `SRV01`, qui porte déjà le DHCP
- Préparer une image de démarrage qui lance l'installation depuis un partage
- Déployer `PC03` **sans clic** en démarrant sur la carte réseau, avec le fichier de réponse du chapitre 16
- Diagnostiquer un démarrage PXE qui échoue

---

## Prérequis

- TP 16 réussi : `autounattend-iso-officielle.xml` et `postinstall.ps1` fonctionnent (dossier `Ressources/Fichier-reponse/`)
- `deploiement.cmd` et `winpeshl.ini` (dossier `Ressources/deploiement-wds/`)
- `SRV01` : contrôleur de domaine `ad.fournil.lab` avec DHCP actif (TP 10), OU `OU=Ordinateurs,OU=Fournil`
- ISO officielle Windows 11 26H2 dans `D:\ISO` sur l'hôte
- **70 Go libres** sur l'hôte (disque de données de `SRV01` + `PC03`)

---

## Partie A — Comprendre le démarrage réseau (15 min)

**A1.** Remets dans l'ordre ce qui se passe quand `PC03` démarre sur sa carte réseau, et indique le protocole de chaque étape : chargement de `boot.wim` · ouverture du partage `Deploy$` · obtention d'une adresse IP · téléchargement de `wdsmgfw.efi` · réponse du serveur PXE.

> [!success]- Afficher la correction — A1
> | # | Étape | Protocole |
> |---|-------|-----------|
> | 1 | Obtention d'une adresse IP (avec l'option 60 « PXEClient ») | **DHCP** (UDP 67/68) |
> | 2 | Réponse du serveur PXE : nom du chargeur à télécharger | **PXE** (UDP 4011) |
> | 3 | Téléchargement de `wdsmgfw.efi` (puis gestionnaire de démarrage et BCD) | **TFTP** (UDP 69) |
> | 4 | Chargement de `boot.wim` en mémoire, démarrage de WinPE | **TFTP** |
> | 5 | Ouverture du partage `Deploy$`, lancement de `setup.exe` | **SMB** (TCP 445) |
>
> TFTP ne transporte que le démarrage (≈ 600 Mo). Les sources de Windows (≈ 6 Go) passent par SMB, bien plus fiable et rapide.

**A2.** En 2026, pourquoi n'importe-t-on **aucune image d'installation** dans WDS ? Qu'est-ce que WDS fait encore pour nous ?

> [!success]- Afficher la correction — A2
> Pour Windows 11, Microsoft ne prend plus en charge l'installation pilotée par WDS : Setup en « mode WDS » affiche un avertissement de dépréciation puis redémarre. Sur le lab, `Import-WdsInstallImage` refuse même le `install.wim` 26H2. Le fichier de réponse servi par WDS (*mains libres*) est bloqué par défaut depuis avril 2026, et le rôle sera déprécié dans la prochaine version de Windows Server.
> WDS sert encore à **PXE + TFTP** : il livre un **WinPE** au poste. C'est ce WinPE qui lance une installation classique (`setup.exe /unattend`) depuis un partage.

**A3.** Le DHCP et WDS sont sur le même serveur. Quel conflit cela pose-t-il ? Comment le poste apprend-il qu'un serveur PXE existe ?

> [!success]- Afficher la correction — A3
> Les deux services veulent écouter le port **UDP 67**. On dit donc à WDS de **ne pas** l'écouter (`/UseDhcpPorts:No`). Le serveur DHCP ajoute à sa réponse l'**option 60** (« *PXEClient* ») (`/DhcpOption60:Yes`). En la voyant, le firmware du poste sait qu'un serveur PXE est présent sur la même machine et l'interroge sur le port **4011**.

---

## Partie B — Préparer SRV01 et installer WDS (25 min)

**B1.** Ajoute à `SRV01` un second disque virtuel de 60 Go, formate-le en `E:` (label `Deploiement`), et insère l'ISO officielle dans son lecteur DVD.

> [!success]- Afficher la correction — B1
> Sur l'hôte :
> ```powershell
> New-VHD -Path D:\HyperV\SRV01\SRV01-data.vhdx -SizeBytes 60GB -Dynamic
> Add-VMHardDiskDrive -VMName SRV01 -Path D:\HyperV\SRV01\SRV01-data.vhdx
> Set-VMDvdDrive -VMName SRV01 -Path D:\ISO\Win11_26H2_French_x64.iso
> ```
> Sur `SRV01` :
> ```powershell
> Get-Disk | Where-Object PartitionStyle -eq 'RAW' |
>     Initialize-Disk -PartitionStyle GPT -PassThru |
>     New-Partition -DriveLetter E -UseMaximumSize |
>     Format-Volume -FileSystem NTFS -NewFileSystemLabel Deploiement
> Get-Volume | Select-Object DriveLetter, FileSystemLabel, DriveType   # E: = Deploiement, D: = CD-ROM
> ```
> Un disque séparé garde `RemoteInstall` et les 7 Go de sources **hors du volume système**, comme le recommande WDS. `Add-VMHardDiskDrive` fonctionne VM allumée (contrôleur SCSI).

**B2.** Installe le rôle WDS puis initialise-le avec le dossier `E:\RemoteInstall`. Vérifie que le chargeur UEFI est bien présent. Que faire s'il manque ?

> [!success]- Afficher la correction — B2
> ```powershell
> Install-WindowsFeature WDS -IncludeManagementTools
> wdsutil /Initialize-Server /RemInst:"E:\RemoteInstall"
> Test-Path E:\RemoteInstall\Boot\x64\wdsmgfw.efi     # True attendu
> Get-Service WDSServer                              # Running
> ```
> `SRV01` est contrôleur de domaine : WDS s'intègre à l'AD sans autre option.
> **S'il manque** (vécu sur le lab : erreur `0x41D` à l'initialisation, service lent à démarrer, dossier `Boot\x64` incomplet) :
> ```powershell
> Copy-Item C:\Windows\System32\RemInst\boot\x64\* E:\RemoteInstall\Boot\x64\ -Recurse -Force
> Restart-Service WDSServer
> ```
> Sans `wdsmgfw.efi`, un poste UEFI affiche « *A boot image was not found* ».

**B3.** Configure WDS pour qu'il cohabite avec le DHCP, réponde à tous les postes et démarre sans appui sur F12. Vérifie la configuration.

> [!success]- Afficher la correction — B3
> ```powershell
> wdsutil /Set-Server /UseDhcpPorts:No /DhcpOption60:Yes
> wdsutil /Set-Server /AnswerClients:All
> wdsutil /Set-Server /PxePromptPolicy /Known:NoPrompt /New:NoPrompt
> wdsutil /Get-Server /Show:Config
> ```
> Dans la sortie de `/Get-Server` :
> ```text
> Configuration DHCP :
>      État du service DHCP : En cours d'exécution
>      Option DHCP 60 configurée : Oui
>      Utiliser les ports DHCP : Non
> ```
> Équivalent graphique (onglets des propriétés du serveur) : **DHCP** (deux cases cochées), **Réponse PXE** (« Répondre à tous les ordinateurs clients »), **Démarrer** (« Toujours continuer le démarrage PXE »).
>
> ![Onglet DHCP](https://cours.kaya.ovh/windows11/assets/captures/w11-wds-prop-dhcp.png)

**B4.** Pourquoi ces réglages de réponse seraient-ils dangereux en production ? Propose deux alternatives.

> [!success]- Afficher la correction — B4
> N'importe quel poste qui démarre sur le réseau lance l'installation **sans confirmation**, et le fichier de réponse **efface le disque 0**. Il suffit d'un ordre de démarrage modifié ou d'une carte mère remplacée pour perdre un poste et ses données.
> Alternatives :
> - exiger **F12** (`/PxePromptPolicy /New:OptIn`) : un humain confirme devant le poste ;
> - ne répondre qu'aux postes **connus**, préinstallés dans l'AD avec leur adresse MAC ou leur GUID (`/AnswerClients:Known`) ;
> - ou isoler le déploiement dans un **VLAN** dédié.

---

## Partie C — Accélérer TFTP (10 min)

**C1.** Règle la taille de bloc TFTP à 16384 et redémarre le service.

> [!success]- Afficher la correction — C1
> ```powershell
> $k = 'HKLM:\SYSTEM\CurrentControlSet\Services\WDSServer\Providers\WDSTFTP'
> Set-ItemProperty $k -Name MaxBlockSize     -Value 16384 -Type DWord
> Set-ItemProperty $k -Name MaximumBlockSize -Value 16384 -Type DWord
> Restart-Service WDSServer
> ```
> Sur le lab : `boot.wim` (≈ 600 Mo) chargé en **6 secondes** au lieu de **7 minutes**. La console affiche cette valeur dans l'onglet **TFTP** (« Taille de bloc maximale »).

**C2.** Pourquoi ne pas mettre systématiquement la valeur la plus grande possible ?

> [!success]- Afficher la correction — C2
> Un bloc plus grand que la trame Ethernet (1500 octets) est **fragmenté** en plusieurs paquets IP. Certains firmwares, commutateurs, pare-feux ou liaisons VPN gèrent mal les fragments : le chargement échoue ou reste bloqué. On choisit une valeur qui marche sur **tous** les postes du parc. En cas de souci, on redescend à 8192, puis 4096.

---

## Partie D — L'image de démarrage (30 min)

**D1.** Copie `boot.wim` de l'ISO dans `E:\WinPE` et liste ses images. Laquelle WDS démarre-t-il ? Que se passe-t-il si on l'importe sans modification ?

> [!success]- Afficher la correction — D1
> ```powershell
> New-Item E:\WinPE\mount -ItemType Directory -Force
> Copy-Item D:\sources\boot.wim E:\WinPE\boot.wim
> Set-ItemProperty E:\WinPE\boot.wim -Name IsReadOnly -Value $false
> Get-WindowsImage -ImagePath E:\WinPE\boot.wim | Select-Object ImageIndex, ImageName
> ```
> ```text
> ImageIndex ImageName
> ---------- ---------
>          1 Microsoft Windows PE (amd64)
>          2 Microsoft Windows Setup (amd64)
> ```
> WDS démarre l'**index 2** (*Windows Setup*). Importé tel quel, il lance Setup en « mode WDS » : message « *La fonctionnalité du client des Services de déploiement Windows est partiellement déconseillée* », puis redémarrage en boucle, puisqu'aucune image d'installation n'est disponible.
>
> ![Setup en mode WDS](https://cours.kaya.ovh/windows11/assets/captures/w11-wds-pxe-avertissement-setup.png)

**D2.** Lis `winpeshl.ini` et `deploiement.cmd`. À quoi sert `winpeshl.ini` ? Pourquoi `deploiement.cmd` commence-t-il par `wpeinit` ? Pourquoi `cmd.exe /k` plutôt que `/c` ?

> [!success]- Afficher la correction — D2
> - **`winpeshl.ini`** (dans `Windows\System32`) remplace le programme que WinPE lance au démarrage. Sans lui, l'image *Windows Setup* lance Setup en mode WDS ; avec lui, elle lance **notre script**.
> - **`wpeinit`** initialise WinPE : pilotes, réseau, DHCP. Quand `winpeshl.ini` existe, WinPE **ne le lance plus tout seul**. Sans cette ligne, pas de réseau, donc pas de partage.
> - **`/k`** garde l'invite ouverte quand le script se termine. Si le partage est inaccessible ou si Setup échoue, on lit le message et on peut taper des commandes (`ipconfig`, `net use`). Avec `/c`, la fenêtre se fermerait et WinPE redémarrerait aussitôt.

**D3.** Injecte les deux fichiers dans la bonne image, puis importe le `boot.wim` dans WDS sous le nom `WinPE Fournil - déploiement réseau`.

> [!success]- Afficher la correction — D3
> ```powershell
> Mount-WindowsImage -ImagePath E:\WinPE\boot.wim -Index 2 -Path E:\WinPE\mount
> Copy-Item .\deploiement.cmd, .\winpeshl.ini E:\WinPE\mount\Windows\System32\
> Dismount-WindowsImage -Path E:\WinPE\mount -Save
>
> Import-WdsBootImage -Path E:\WinPE\boot.wim -NewImageName 'WinPE Fournil - déploiement réseau'
> Get-WdsBootImage | Select-Object Name, Architecture, FileName
> ```
> On injecte dans l'**index 2**, celui que WDS démarre. Sur le lab, une première tentative sur l'index 1 n'a rien changé.
>
> ![L'image de démarrage dans la console WDS](https://cours.kaya.ovh/windows11/assets/captures/w11-wds-console-images-demarrage.png)

**D4.** Un collègue propose de modifier directement le `.wim` qui se trouve dans `E:\RemoteInstall\Boot\x64\Images`, « c'est plus rapide ». Qu'en penses-tu ?

> [!success]- Afficher la correction — D4
> Mauvaise idée. WDS gère lui-même ce dossier : au moment de l'import, il prépare les fichiers de démarrage (BCD, métadonnées) pour cette image précise. Remplacer le fichier a provoqué sur le lab une erreur de démarrage **`0xc0000098`**. La bonne méthode : modifier le `boot.wim` **avant** l'import, ou bien `Remove-WdsBootImage` puis un nouvel `Import-WdsBootImage`.

---

## Partie E — Le partage de déploiement (20 min)

**E1.** Crée le compte `svc.deploiement` (mot de passe `Fournil2026!`, n'expire jamais) dans `OU=Fournil`. Pourquoi un compte dédié plutôt que `Administrateur` ?

> [!success]- Afficher la correction — E1
> ```powershell
> New-ADUser svc.deploiement -Path 'OU=Fournil,DC=ad,DC=fournil,DC=lab' -Enabled $true `
>     -AccountPassword (ConvertTo-SecureString 'Fournil2026!' -AsPlainText -Force) `
>     -PasswordNeverExpires $true -CannotChangePassword $true
> ```
> Son mot de passe est écrit **en clair** dans `deploiement.cmd`, donc **dans l'image de démarrage**. N'importe qui peut la télécharger par TFTP, sans authentification. Ce compte ne doit savoir faire qu'une chose : **lire** le partage. Avec `Administrateur`, on donnerait le domaine entier.

**E2.** Copie le contenu de l'ISO dans `E:\Deploy\Windows11`, et place à la racine de `E:\Deploy` un `autounattend.xml` pour `PC03`, construit à partir de `autounattend-iso-officielle.xml`. Combien de remplacements faut-il ?

> [!success]- Afficher la correction — E2
> ```powershell
> robocopy D:\ E:\Deploy\Windows11 /E /NFL /NDL
> $xml = (Get-Content .\autounattend-iso-officielle.xml -Raw) -replace 'PC02', 'PC03'
> Set-Content E:\Deploy\autounattend.xml $xml -Encoding UTF8
> Select-String -Path E:\Deploy\autounattend.xml -Pattern 'PC0'
> ```
> **Deux** occurrences, plus le commentaire d'en-tête : `<ComputerName>` (passe `specialize`) et `<Domain>` du bloc `AutoLogon`. `admin` est un compte local : `<Domain>` doit porter le nom du poste (chapitre 16, question A3). En oublier un, c'est un poste nommé `PC02`, ou une post-installation qui ne se lance jamais.
> Le fichier de réponse est **le même** qu'au chapitre 16 : seul le transport change.

**E3.** Comment `postinstall.ps1` arrive-t-il sur le poste, alors qu'il n'y a plus ni DVD ni clé ? Place-le au bon endroit.

> [!success]- Afficher la correction — E3
> Par le dossier spécial **`$OEM$`** des sources d'installation : Setup copie le contenu de `sources\$OEM$\$$` dans `C:\Windows` du poste installé. `postinstall.ps1` arrive donc dans `C:\Windows\Setup\Scripts`, l'un des emplacements où les `FirstLogonCommands` du fichier de réponse le cherchent.
> ```powershell
> New-Item 'E:\Deploy\Windows11\sources\$OEM$\$$\Setup\Scripts' -ItemType Directory -Force
> Copy-Item .\postinstall.ps1 'E:\Deploy\Windows11\sources\$OEM$\$$\Setup\Scripts\'
> ```
> Apostrophes **simples** obligatoires : entre guillemets doubles, PowerShell prendrait `$OEM` et `$$` pour des variables.

**E4.** Partage `E:\Deploy` sous le nom `Deploy$`, en lecture pour `svc.deploiement`. Depuis `PC01`, vérifie que ce compte peut lire `autounattend.xml`.

> [!success]- Afficher la correction — E4
> Sur `SRV01` :
> ```powershell
> New-SmbShare -Name 'Deploy$' -Path E:\Deploy -ReadAccess 'FOURNIL\svc.deploiement' -FullAccess 'FOURNIL\Admins du domaine'
> ```
> Sur `PC01` (invite de commandes, exactement ce que fera WinPE) :
> ```bat
> net use Z: \\192.168.3.1\Deploy$ /user:FOURNIL\svc.deploiement Fournil2026!
> dir Z:\
> type Z:\autounattend.xml | more
> net use Z: /delete
> ```
> Les droits NTFS par défaut de `E:\` donnent déjà la lecture aux utilisateurs authentifiés : le droit de **partage** en lecture suffit. Tester avant de démarrer le poste évite de chercher un problème de droits depuis WinPE.

---

## Partie F — Déployer PC03 (40 min)

**F1.** Crée `PC03` (Gen 2, TPM, 2 vCPU, 4 Go statiques, disque de 64 Go, `vSwitch-Rennes`, **aucun DVD**), avec la carte réseau en premier périphérique de démarrage. Démarre-la et observe les écrans successifs.

> [!success]- Afficher la correction — F1
> ```powershell
> New-VM -Name PC03 -Generation 2 -NewVHDPath D:\HyperV\PC03\PC03.vhdx -NewVHDSizeBytes 64GB `
>     -SwitchName vSwitch-Rennes -Path D:\HyperV
> Set-VMMemory PC03 -DynamicMemoryEnabled $false -StartupBytes 4GB; Set-VMProcessor PC03 -Count 2
> Set-VMKeyProtector -VMName PC03 -NewLocalKeyProtector; Enable-VMTPM -VMName PC03
> Set-VMFirmware PC03 -FirstBootDevice (Get-VMNetworkAdapter PC03)
> Start-VM PC03; vmconnect.exe localhost PC03
> ```
> Écrans successifs :
>
> ![1. Contact du serveur WDS](https://cours.kaya.ovh/windows11/assets/captures/w11-wds-pxe-contact-serveur.png)
>
> ![2. Chargement de boot.wim par TFTP](https://cours.kaya.ovh/windows11/assets/captures/w11-wds-pxe-chargement.png)
>
> ![3. deploiement.cmd a ouvert le partage et lancé Setup](https://cours.kaya.ovh/windows11/assets/captures/w11-wds-pxe-script-setup.png)
>
> ![4. Installation sans question](https://cours.kaya.ovh/windows11/assets/captures/w11-wds-installation-en-cours.png)
>
> Puis redémarrages, OOBE masquée, ouverture de session `admin`, post-installation, redémarrage final.

**F2.** Combien de temps entre le démarrage et l'écran de connexion final ? Combien de gestes ?

> [!success]- Afficher la correction — F2
> Mesuré sur le lab (10/11/2026) : **environ 13 minutes** et **aucun geste**, pas même la touche « Press any key » du DVD.
>
> | Heure | Étape |
> |-------|-------|
> | 15:09:30 | `Start-VM PC03` |
> | + 10 s | Contact du serveur WDS, `boot.wim` chargé en quelques secondes |
> | + 25 s | WinPE : `deploiement.cmd` ouvre `Deploy$`, Setup démarre |
> | 15:15:41 | Compte ordinateur `PC03` créé dans l'AD (passe `specialize`) |
> | 15:18:38 | Ouverture de session `admin`, début de `postinstall.ps1` |
> | 15:21:28 | Obsidian et VS Code installés (code retour 0), nettoyage, redémarrage dans 30 s |
> | ≈ 15:22:30 | Écran de connexion du domaine |
>
> C'est le temps du chapitre 16 (≈ 9 min), plus la copie des sources par le réseau. Et surtout, aucun support à préparer par poste.

**F3.** Vérifie depuis `SRV01` : OU de `PC03` dans l'AD, enregistrement DNS, journal de post-installation, applications installées.

> [!success]- Afficher la correction — F3
> ```powershell
> Get-ADComputer PC03 | Select-Object DistinguishedName
> Resolve-DnsName PC03.ad.fournil.lab
> Get-Content '\\PC03\C$\Windows\Temp\postinstall.log' | Select-String 'Début|Installation de|code retour|Fin'
> Invoke-Command -ComputerName PC03 { winget list --id Obsidian.Obsidian; winget list --id Microsoft.VisualStudioCode }
> ```
> Résultat sur le lab :
> ```text
> DistinguishedName : CN=PC03,OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab
>
> Name                IPAddress
> ----                ---------
> PC03.ad.fournil.lab 192.168.3.100
>
> 15:18:38  Début post-installation sur PC03 (PC03\admin)
> 15:18:58  Installation de Obsidian.Obsidian
> 15:20:17    code retour 0
> 15:20:17  Installation de Microsoft.VisualStudioCode
> 15:21:28    code retour 0
> 15:21:28  Fin post-installation : redémarrage dans 30 s
> ```
> La ligne « *Début post-installation* » prouve que `postinstall.ps1` est bien arrivé par `$OEM$` (question E3). L'adresse `.100` est la première de l'étendue DHCP.

---

## Partie G — Dépannage (10 min)

**G1.** Un poste affiche « *A boot image was not found* » pour sa carte réseau. Cite trois causes possibles et où les vérifier.

> [!success]- Afficher la correction — G1
> ![Network Adapter — A boot image was not found](https://cours.kaya.ovh/windows11/assets/captures/w11-wds-pxe-erreur-image-introuvable.png)
>
> | Cause | Vérification |
> |-------|--------------|
> | WDS ne répond pas à ce poste | `wdsutil /Get-Server /Show:Config` → stratégie de réponse ; `/AnswerClients:All` |
> | Chargeur UEFI absent de `RemoteInstall\Boot\x64` | `Test-Path E:\RemoteInstall\Boot\x64\wdsmgfw.efi` (question B2) |
> | Aucune image de démarrage x64 | `Get-WdsBootImage` |
> | Pas d'option 60, ou poste sur un autre réseau | `/Get-Server` → *Option DHCP 60 configurée : Oui* ; commutateur virtuel du poste |
> | Service arrêté | `Get-Service WDSServer` |
>
> Le journal `Microsoft-Windows-Deployment-Services-Diagnostics/Admin` indique la cause côté serveur (question H1).

**G2.** Un poste affiche « *La fonctionnalité du client des Services de déploiement Windows est partiellement déconseillée* », puis redémarre et recommence. Explique et corrige.

> [!success]- Afficher la correction — G2
> L'image de démarrage lance **Setup en mode WDS**, déconseillé pour Windows 11. Après **OK**, Setup ne trouve aucune image d'installation dans WDS et le poste redémarre, puis repart en PXE.
> Causes : `boot.wim` importé **sans** `winpeshl.ini`, ou fichiers injectés dans l'**index 1** au lieu de l'index 2.
> Correction : `Remove-WdsBootImage -ImageName 'WinPE Fournil - déploiement réseau' -Architecture X64`, puis refaire D3 sur l'index 2, puis importer à nouveau.

**G3.** Le poste démarre WinPE, mais l'invite affiche « Partage inaccessible ». Comment diagnostiquer sans redémarrer ?

> [!success]- Afficher la correction — G3
> L'invite est restée ouverte grâce à `cmd.exe /k` :
> ```bat
> ipconfig                                  :: une adresse 192.168.3.x ? sinon : réseau, DHCP, pilote
> ping 192.168.3.1                          :: SRV01 joignable ?
> net use Z: \\192.168.3.1\Deploy$ /user:FOURNIL\svc.deploiement Fournil2026!
> ```
> Le message de `net use` donne la cause : **erreur 5** (accès refusé : droits du partage), **erreur 1326** (nom d'utilisateur ou mot de passe incorrect), **erreur 53** (chemin réseau introuvable : nom du partage, pare-feu, service Serveur).
> Une fois `Z:` monté : `Z:\Windows11\setup.exe /unattend:Z:\autounattend.xml` à la main.

---

## Partie H — Bonus

**H1.** Où voir, sur `SRV01`, qu'un poste a demandé un démarrage PXE sans obtenir d'image ?

> [!success]- Afficher la correction — H1
> ```powershell
> Get-WinEvent -LogName 'Microsoft-Windows-Deployment-Services-Diagnostics/Admin' -MaxEvents 10 |
>     Format-List TimeCreated, Id, Message
> ```
> Exemple relevé sur le lab (événement **57347**, niveau *Erreur*) : « *Le serveur PXE a traité une demande émise par un client dont l'architecture est x64uefi. Aucune image…* ». C'est exactement le cas « *A boot image was not found* » vu côté poste.

**H2.** La carte réseau était le premier périphérique de démarrage de `PC03`, et WDS répond à tous les postes sans F12. Pourquoi `PC03` ne se réinstalle-t-il pas en boucle à chaque redémarrage ? Vérifie, puis cite un cas où la boucle se produirait.

> [!success]- Afficher la correction — H2
> En UEFI, Setup crée l'entrée **Windows Boot Manager** dans le firmware et la place **en tête** de l'ordre de démarrage :
> ```powershell
> (Get-VMFirmware PC03).BootOrder | Select-Object BootType, Description
> ```
> ```text
> BootType Description
> -------- -----------
>     File Windows Boot Manager
>  Network EFI Network
>    Drive EFI SCSI Device
> ```
> La boucle se produirait si quelqu'un remettait la carte réseau en premier (`Set-VMFirmware -FirstBootDevice`), sur un firmware qui ne laisse pas Windows modifier l'ordre, ou en BIOS (génération 1) avec le réseau avant le disque. D'où l'intérêt de **F12** en production (question B4).

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp)
