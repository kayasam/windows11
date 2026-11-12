---
title: "TP 05. Pilotes, applications et WinGet — Correction"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/05-peripheriques-applications"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/05-peripheriques-applications-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp-corrigev2" aria-current="page">Corrigé</a></nav>

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h30

> Chapitres associés : [05. Pilotes, applications et WinGet](https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/)

---

## Objectifs

- Inventorier les périphériques et le magasin de pilotes
- Ajouter, exporter et retirer un pilote avec `pnputil`
- Distinguer applications installées et applications provisionnées
- Construire le socle logiciel du Fournil avec WinGet et l'exporter

---

## Prérequis

- `PC01` installé (TP 02), avec accès Internet (TP 03)
- Terminal **administrateur**

---

## Partie A — Périphériques (20 min)

**A1.** Ouvre le Gestionnaire de périphériques. Combien de cartes réseau vois-tu ? Affiche les périphériques cachés : qu'est-ce qui apparaît en plus ?

> [!success]- Afficher la correction — A1
> `Win + X` → **Gestionnaire de périphériques** (ou `devmgmt.msc`). Dans **Cartes réseau** : une **Microsoft Hyper-V Network Adapter** (plus éventuellement des cartes « WAN Miniport » si on affiche les cachés).
> **Affichage → Afficher les périphériques cachés** : apparaissent en grisé les périphériques non connectés — les miniports WAN, les volumes et lecteurs vus une fois (ISO de réponse de l'installation, par exemple), d'anciennes cartes réseau.

**A2.** En PowerShell, compte les périphériques présents par classe, puis liste ceux qui ne sont pas en état `OK`.

> [!success]- Afficher la correction — A2
> ```powershell
> Get-PnpDevice -PresentOnly | Group-Object Class | Sort-Object Count -Descending |
>     Select-Object Count, Name -First 8
> Get-PnpDevice -PresentOnly | Where-Object Status -ne 'OK' |
>     Select-Object Status, Class, FriendlyName
> ```
> Sur `PC01` : `System` (33), `Volume` (4), `Processor`, `SCSIAdapter`, `CDROM`… et **aucun** périphérique en erreur — une VM Hyper-V n'utilise que des pilotes en boîte.

**A3.** Quel est le nom du pilote utilisé par la carte réseau de `PC01` ? D'où vient-il ?

> [!success]- Afficher la correction — A3
> Propriétés de **Microsoft Hyper-V Network Adapter** → onglet **Pilote** → **Détails du pilote** : `netvsc.sys`, fournisseur **Microsoft**.
> ```powershell
> Get-NetAdapter | Select-Object Name, InterfaceDescription, DriverFileName, DriverVersion, DriverProvider
> ```
> C'est un pilote **en boîte** : livré avec Windows, c'est pourquoi une VM Hyper-V a du réseau dès l'installation. Sur un PC physique récent, la carte Wi-Fi ou Ethernet peut au contraire exiger un pilote constructeur (à injecter dans l'image, chapitre 15).

---

## Partie B — Magasin de pilotes (25 min)

**B1.** Liste les pilotes tiers du magasin avec `pnputil`. Que signifient « Nom publié » et « Nom d'origine » ?

> [!success]- Afficher la correction — B1
> ```cmd
> pnputil /enum-drivers
> ```
> ```
> Nom publié :          oem1.inf
> Nom d'origine :       voiceclarityep_audio_component.inf
> Nom du fournisseur :  Microsoft Corporation
> Nom de la classe :    AudioProcessingObject
> Version du pilote :   06/16/2026 1.0.4.7057
> Nom du signataire :   Microsoft Windows Hardware Compatibility Publisher
> ```
> - **Nom d'origine** : le nom du fichier `.inf` fourni par le constructeur.
> - **Nom publié** : le nom attribué par Windows en l'ajoutant au magasin (`oem0.inf`, `oem1.inf`…). C'est lui qu'il faut donner à `pnputil /delete-driver`.
>
> Seuls les pilotes **tiers** (ajoutés après l'installation) sont listés ; les pilotes en boîte n'apparaissent pas.

**B2.** Exporte tous les pilotes tiers dans `C:\Sauvegarde\Pilotes`. Dans quelle situation cet export est-il précieux ?

> [!success]- Afficher la correction — B2
> ```cmd
> mkdir C:\Sauvegarde\Pilotes
> pnputil /export-driver * C:\Sauvegarde\Pilotes
> ```
> Chaque pilote est exporté dans son propre sous-dossier. Précieux **avant de réinstaller** un poste dont le constructeur ne propose plus les pilotes en téléchargement (vieux scanner, carte d'acquisition…) : on les réinjecte après l'installation, ou directement dans l'image (`Dism /Add-Driver`, chapitre 15).
> Équivalent PowerShell : `Export-WindowsDriver -Online -Destination C:\Sauvegarde\Pilotes`.

**B3.** Réinjecte l'un des pilotes exportés dans le magasin avec `pnputil /add-driver`. Que répond l'outil, et pourquoi ?

> [!success]- Afficher la correction — B3
> ```cmd
> pnputil /add-driver C:\Sauvegarde\Pilotes\prnms009.inf_amd64_*\prnms009.inf /install
> ```
> Réponse réelle sur `PC01` :
> ```
> Ajout en cours du package de pilotes :  prnms009.inf
> Package de pilotes ajouté. (Existe déjà dans le système)
> Nom publié :         oem0.inf
> Le package de pilotes est à jour sur l'appareil : SWD\PRINTENUM\{B3CE8B6B-...}
> Packages de pilotes ajoutés :  0
> ```
> Le pilote est **déjà dans le magasin** (même version, même signature) : `pnputil` ne crée pas de doublon et retrouve son nom publié `oem0.inf`. Sur un poste neuf, il l'aurait ajouté et installé sur les périphériques compatibles.
>
> L'export de `PC01` contient 2 dossiers : `prnms009.inf_amd64_…` (Microsoft Print to PDF) et `voiceclarityep_audio_component.inf_amd64_…`.

**B4.** Une mise à jour de pilote graphique provoque des écrans noirs depuis hier. Quelles sont tes options, de la plus douce à la plus radicale ?

> [!success]- Afficher la correction — B4
> 1. **Restaurer le pilote** (Propriétés → Pilote → Restaurer le pilote) : revient à la version précédente, qui est encore dans le magasin.
> 2. Si le poste ne s'affiche plus : **mode sans échec** (pilote vidéo de base) puis restauration (chapitre 19).
> 3. Désinstaller le périphérique **en cochant « Tenter de supprimer le pilote »**, redémarrer : Windows reprend un pilote générique.
> 4. Bloquer la réinstallation automatique via Windows Update (GPO « Ne pas inclure les pilotes avec les mises à jour Windows », chapitre 08) le temps que le constructeur corrige.
> 5. En dernier recours : point de restauration ou point-in-time restore (chapitre 19).

---

## Partie C — Applications et fonctionnalités (20 min)

**C1.** Liste les applications **provisionnées** de l'image. Quelle est la différence avec `Get-AppxPackage` ?

> [!success]- Afficher la correction — C1
> ```powershell
> Get-AppxProvisionedPackage -Online | Select-Object DisplayName, Version
> ```
> Une quarantaine de paquets sur `PC01` 26H2, dont `Clipchamp.Clipchamp`, `Microsoft.BingNews`, `Microsoft.OutlookForWindows`, `Microsoft.Windows.DevHome`, `MSTeams`, `MicrosoftCorporationII.QuickAssist`, `Microsoft.WindowsTerminal`…
> - `Get-AppxProvisionedPackage` : ce que l'**image** installera à **chaque nouveau profil**.
> - `Get-AppxPackage` : ce qui est installé pour **l'utilisateur courant** (`-AllUsers` pour tous les profils existants).

**C2.** Le Fournil ne veut pas de `Microsoft.BingNews` pour les **futurs** utilisateurs du poste. Retire-le de l'image. Les utilisateurs qui ont déjà un profil le perdent-ils ?

> [!success]- Afficher la correction — C2
> ```powershell
> Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq "Microsoft.BingNews" |
>     Remove-AppxProvisionedPackage -Online
> ```
> **Non**, les profils existants le gardent : on n'a retiré que la « copie modèle ». Pour eux, il faut en plus :
> ```powershell
> Get-AppxPackage -AllUsers Microsoft.BingNews | Remove-AppxPackage -AllUsers
> ```
> D'où l'intérêt de faire ce ménage **dans l'image**, avant tout profil (mode audit, chapitre 14).

**C3.** Vérifie si `wmic` existe encore sur le poste. Un vieux script du Fournil contient `wmic bios get serialnumber` : réécris-le.

> [!success]- Afficher la correction — C3
> ```powershell
> Test-Path C:\Windows\System32\wbem\wmic.exe     # False sur 26H2
> ```
> WMIC a été **supprimé** de Windows 11 (et n'est plus réinstallable comme fonctionnalité à la demande). La couche WMI elle-même existe toujours ; on l'interroge en PowerShell :
> ```powershell
> (Get-CimInstance Win32_BIOS).SerialNumber
> ```

**C4.** Liste les capacités OpenSSH. Lesquelles sont installées ?

> [!success]- Afficher la correction — C4
> ```powershell
> Get-WindowsCapability -Online -Name OpenSSH* | Select-Object Name, State
> ```
> ```
> Name                        State
> ----                        -----
> OpenSSH.Client~~~~0.0.1.0   Installed
> OpenSSH.Server~~~~0.0.1.0   NotPresent
> ```
> Le **client** est installé par défaut sur Windows 11 ; le **serveur** non (il sera ajouté au chapitre 12). Sur Windows Server 2025, c'est l'inverse : le serveur est déjà installé (mais arrêté).

---

## Partie D — WinGet : le socle logiciel du Fournil (25 min)

**D1.** Vérifie la version de WinGet et les sources configurées.

> [!success]- Afficher la correction — D1
> ```powershell
> winget --version
> winget source list
> ```
> ```
> v1.11.510
>
> Name    Argument                                      Explicit
> --------------------------------------------------------------
> msstore https://storeedgefd.dsx.mp.microsoft.com/v9.0 false
> winget  https://cdn.winget.microsoft.com/cache        false
> ```
> Au premier usage, WinGet demande d'accepter les conditions de la source `msstore` (envoi du code pays) : `--accept-source-agreements` répond oui automatiquement.

**D2.** Cherche « 7zip ». Pourquoi `winget install 7zip` est-il une mauvaise idée ? Installe 7-Zip correctement, pour tous les utilisateurs, sans aucune question.

> [!success]- Afficher la correction — D2
> ```powershell
> winget search 7zip
> ```
> La recherche renvoie aussi `mcmilk.7zip-zstd`, `ozone10.7zip.Dark`, `7zip.7zr`, `Gabtyss.Py7z`… `winget install 7zip` cherche par **nom/mot-clé** : s'il y a plusieurs correspondances, il s'arrête, ou pire installe un paquet non voulu.
> ```powershell
> winget install --id 7zip.7zip -e --silent --scope machine `
>     --accept-package-agreements --accept-source-agreements
> ```
> ```
> Found 7-Zip [7zip.7zip] Version 26.06
> Downloading https://github.com/ip7z/7zip/releases/download/26.06/7z2606-x64.exe
> Successfully verified installer hash
> Starting package install...
> Successfully installed
> ```
> La ligne « *verified installer hash* » est essentielle : WinGet compare l'empreinte SHA256 du fichier téléchargé à celle du manifeste. Un installeur modifié serait refusé.

**D3.** Installe Notepad++ de la même façon.

> [!success]- Afficher la correction — D3
> ```powershell
> winget install --id Notepad++.Notepad++ -e --silent --accept-package-agreements
> ```

**D4.** Liste les mises à jour disponibles. Combien y en a-t-il sur un poste tout juste installé, et pourquoi ?

> [!success]- Afficher la correction — D4
> ```powershell
> winget upgrade
> ```
> ```
> Microsoft Edge WebView2 Runtime  Microsoft.EdgeWebView2Runtime  152.0.4191.66     157.0.4341.42
> Microsoft OneDrive               Microsoft.OneDrive             25.087.0506.0001  26.183.0920.0005
> Microsoft Teams                  Microsoft.Teams                1.0.0.1           26276.513.5241.9675
> App Installer                    Microsoft.AppInstaller         1.26.509.0        1.29.380
> Outlook for Windows              Microsoft.Outlook              1.0.0.0           1.2026.812.100
> Terminal Windows                 Microsoft.WindowsTerminal      1.24.11911.0      1.25.2733.0
> ...
> 8 upgrades available.
> ```
> **8 mises à jour** sur un poste tout neuf : les logiciels intégrés à l'ISO datent de sa fabrication. WinGet voit aussi les logiciels qu'il n'a pas installés lui-même (Edge, OneDrive, Teams), dès qu'ils correspondent à un paquet connu.

**D5.** Bloque les mises à jour de Microsoft Teams (le Fournil veut valider chaque version), puis mets à jour tout le reste.

> [!success]- Afficher la correction — D5
> ```powershell
> winget pin add --id Microsoft.Teams
> winget pin list
> ```
> ```
> Name            Id              Version Source Pin type
> -------------------------------------------------------
> Microsoft Teams Microsoft.Teams 1.0.0.1 winget Pinning
> ```
> ```powershell
> winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
> ```
> `winget upgrade --all` ignore les paquets épinglés. `winget pin remove --id Microsoft.Teams` lève le blocage.

**D6.** Exporte la liste des logiciels dans `C:\Temp\socle-fournil.json`. Que contient ce fichier ? Que n'y trouve-t-on pas ?

> [!success]- Afficher la correction — D6
> ```powershell
> New-Item C:\Temp -ItemType Directory -Force
> winget export -o C:\Temp\socle-fournil.json
> ```
> ```json
> {
>   "$schema" : "https://aka.ms/winget-packages.schema.2.0.json",
>   "Sources" : [ { "Packages" : [
>       { "PackageIdentifier" : "7zip.7zip" },
>       { "PackageIdentifier" : "Notepad++.Notepad++" },
>       { "PackageIdentifier" : "Microsoft.Edge" },
>       { "PackageIdentifier" : "Microsoft.OneDrive" },
>       ...
>   ] } ],
>   "WinGetVersion" : "1.11.510"
> }
> ```
> Le fichier contient les **identifiants** des paquets (et la source) — **ni les installeurs, ni les versions** (sauf `--include-versions`), **ni les paramètres** des logiciels. Les logiciels inconnus des sources (« *Installed package is not available from any source* ») ne sont pas exportés.
> Au déploiement (chapitre 16), `postinstall.ps1` installe ce socle sur chaque nouveau poste. Variante : `winget import -i socle-fournil.json --accept-package-agreements`.

---

## Partie E — Bonus

**E1.** Installe le module PowerShell `Microsoft.WinGet.Client` et liste les paquets installés sous forme d'objets, triés par nom.

> [!success]- Afficher la correction — E1
> ```powershell
> Install-Module Microsoft.WinGet.Client -Scope CurrentUser -Force
> Get-WinGetPackage | Sort-Object Name | Select-Object Name, Id, InstalledVersion, IsUpdateAvailable
> ```
> **Piège rencontré sur le lab** : sur Windows 11 client, la stratégie d'exécution par défaut est `Restricted` (toutes les portées à `Undefined`). Le module s'installe, mais refuse de se charger :
> ```
> ... Format.ps1xml : le fichier a été ignoré en raison de l'exception de validation suivante :
> Échec de la vérification d'AuthorizationManager.
> ```
> Il faut d'abord autoriser les scripts (chapitre 07) : `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`.
>
> Résultat :
> ```
> Name                        Id                                            InstalledVersion IsUpdateAvailable
> ----                        --                                            ---------------- -----------------
> 7-Zip                       7zip.7zip                                     26.06                        False
> App Installer               Microsoft.AppInstaller                        1.26.509.0                    True
> AV1 Video Extension         MSIX\Microsoft.AV1VideoExtension_2.0.7.0_...  2.0.7.0                      False
> Bloc-notes Windows          MSIX\Microsoft.WindowsNotepad_11.2605.34.0... 11.2605.34.0                 False
> ```
> Les résultats sont des **objets** : on peut filtrer (`Where-Object IsUpdateAvailable`), exporter en CSV, etc. — impossible proprement avec la sortie texte de `winget.exe`.
>
> > [!NOTE] Session interactive requise
> > `Get-WinGetPackage` s'appuie sur un serveur COM lancé dans la session de l'utilisateur. Dans une session distante (`Enter-PSSession`, PowerShell Direct), il échoue avec `Failed to create instance: -2147023174` : c'est une limite connue, pas une erreur de commande.

**E2.** Une tâche planifiée en SYSTEM lance `winget upgrade --all` chaque nuit et échoue avec « winget n'est pas reconnu ». Explique et corrige.

> [!success]- Afficher la correction — E2
> `winget.exe` est un **alias d'exécution d'application** créé dans le profil de chaque utilisateur (`%LOCALAPPDATA%\Microsoft\WindowsApps`). Le compte SYSTEM n'a pas cet alias.
> Correction : appeler l'exécutable par son chemin réel.
> ```powershell
> $wg = Get-ChildItem "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" |
>     Sort-Object FullName -Descending | Select-Object -First 1
> & $wg.FullName upgrade --all --silent --accept-package-agreements --accept-source-agreements --scope machine
> ```
> Le tri descendant prend la version la plus récente d'App Installer (le dossier change à chaque mise à jour). Alternative : le module `Microsoft.WinGet.Client` (`Update-WinGetPackage`).

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp)
