# TP 13. ADK, Windows PE et fichier de réponse — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 2h

> Chapitres associés : [13. ADK, Windows PE et fichier de réponse](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/)

---

## Objectifs

- Installer Windows ADK et son module WinPE **dans la bonne version**
- Créer un WinPE personnalisé (PowerShell, clavier français) et le démarrer
- Construire avec WSIM le fichier de réponse `autounattend.xml` du Fournil
- Préparer le petit fichier d'installation de `MASTER` (anti-chiffrement)

---

## Prérequis

- `PC01` (poste d'administration) avec accès Internet, ~10 Go libres
- ISO Windows 11 26H2 montée dans `PC01` ou copiée dans `D:\ISO\` sur l'hôte

---

## Partie A — Installer l'ADK (25 min)

**A1.** Sur `PC01`, quelle version de l'ADK WinGet propose-t-il par défaut ? Et le module WinPE ? Quel problème vois-tu ?

> [!success]- Afficher la correction — A1
> ```powershell
> winget search "Microsoft.WindowsADK"
> ```
> ```
> Windows Assessment and Deployment Kit           Microsoft.WindowsADK            10.1.28000.3481
> Windows ADK Preinstallation Environment Add-ons Microsoft.WindowsADK.WinPEAddon 10.1.26100.9457
> ```
> Les deux **ne correspondent pas** : l'ADK 28000 est la branche **26H1** (PC Arm Snapdragon récents), le module WinPE est en 26100 (24H2/25H2/26H2). Microsoft exige **la même version** pour l'ADK et le module, alignée sur la famille de Windows déployée. Constaté lors de la construction du lab : il a fallu désinstaller l'ADK 28000.

**A2.** Installe en mode silencieux l'ADK **10.1.26100.9457** (Outils de déploiement + USMT) puis le module WinPE correspondant.

> [!success]- Afficher la correction — A2
> ```powershell
> winget install --id Microsoft.WindowsADK -e --version 10.1.26100.9457 `
>     --override "/quiet /norestart /features OptionId.DeploymentTools OptionId.UserStateMigrationTool"
> winget install --id Microsoft.WindowsADK.WinPEAddon -e `
>     --override "/quiet /norestart /features OptionId.WindowsPreinstallationEnvironment"
> ```
> `--override` remplace les arguments par défaut de l'installeur : on choisit précisément les fonctionnalités.

**A3.** Liste les dossiers créés sous `Assessment and Deployment Kit`. Où se trouvent `oscdimg.exe`, `copype.cmd`, WSIM, `scanstate.exe` ?

> [!success]- Afficher la correction — A3
> `C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\` :
> ```
> Deployment Tools                     ← DISM, oscdimg (amd64\Oscdimg), WSIM, copype.cmd, MakeWinPEMedia.cmd
> User State Migration Tool            ← amd64\scanstate.exe, loadstate.exe, MigDocs/MigApp/MigUser.xml
> Windows Preinstallation Environment  ← amd64\en-us\winpe.wim, amd64\WinPE_OCs\*.cab
> Windows Setup
> ```

---

## Partie B — Windows PE (40 min)

**B1.** Ouvre l'invite « Environnement de déploiement et d'outils de création d'images » en administrateur. Pourquoi cette invite plutôt qu'un terminal ordinaire ?

> [!success]- Afficher la correction — B1
> Elle exécute `DandISetEnv.bat`, qui ajoute au `PATH` les outils de l'ADK (`copype`, `MakeWinPEMedia`, `oscdimg`, le **DISM de l'ADK**) et définit `WinPERoot`. Depuis un terminal ordinaire, `copype` n'est pas trouvé. En script : `call "…\Deployment Tools\DandISetEnv.bat"` en première ligne.

**B2.** Crée l'arborescence WinPE amd64 dans `C:\WinPE_amd64`. Que contient-elle ?

> [!success]- Afficher la correction — B2
> ```cmd
> copype amd64 C:\WinPE_amd64
> ```
> ```
> C:\WinPE_amd64\
> ├── fwfiles\          fichiers de démarrage (efisys.bin, etfsboot.com)
> ├── media\            ce qui sera sur l'ISO/la clé
> │   └── sources\boot.wim   ← WinPE lui-même
> └── mount\            dossier vide, pour monter boot.wim
> ```

**B3.** Monte `boot.wim` et ajoute : WMI, NetFx, Scripting, PowerShell, StorageWMI, DismCmdlets — avec leurs packs `fr-fr`. Dans quel ordre, et pourquoi ?

> [!success]- Afficher la correction — B3
> ```cmd
> Dism /Mount-Image /ImageFile:C:\WinPE_amd64\media\sources\boot.wim /Index:1 /MountDir:C:\WinPE_amd64\mount
> set OC=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs
> for %P in (WinPE-WMI WinPE-NetFx WinPE-Scripting WinPE-PowerShell WinPE-StorageWMI WinPE-DismCmdlets) do (
>   Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\%P.cab"
>   Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\fr-fr\%P_fr-fr.cab"
> )
> ```
> Ordre imposé par les **dépendances** : PowerShell a besoin de NetFx et de Scripting, qui ont besoin de WMI ; StorageWMI et DismCmdlets ont besoin de PowerShell. Chaque `.cab` s'accompagne de son pack de langue, sinon le composant reste en anglais ou incomplet.

**B4.** Passe le clavier de WinPE en français, vérifie les paquets, puis démonte en validant.

> [!success]- Afficher la correction — B4
> ```cmd
> Dism /Image:C:\WinPE_amd64\mount /Set-InputLocale:fr-FR
> Dism /Image:C:\WinPE_amd64\mount /Get-Packages /Format:Table
> Dism /Unmount-Image /MountDir:C:\WinPE_amd64\mount /Commit
> ```
> Extrait réel :
> ```
> WinPE-PowerShell-Package~31bf3856ad364e35~amd64~~10.0.26100.1        | Installed | Feature Pack
> WinPE-PowerShell-Package~31bf3856ad364e35~amd64~fr-FR~10.0.26100.1   | Installed | Language Pack
> WinPE-WMI-Package~31bf3856ad364e35~amd64~~10.0.26100.1               | Installed | Feature Pack
> ...
> ```

**B5.** Crée l'ISO `WinPE-Fournil.iso`. Quelle taille fait-elle ?

> [!success]- Afficher la correction — B5
> ```cmd
> MakeWinPEMedia /ISO /F C:\WinPE_amd64 C:\Temp\WinPE-Fournil.iso
> ```
> ```
> Creating C:\Temp\WinPE-Fournil.iso...
> Success
> 08/11/2026  07:04       566 790 144 WinPE-Fournil.iso
> ```
> **≈ 567 Mo** (contre ~ 400 Mo pour un WinPE nu). `/F` écrase un fichier existant sans demander.

**B6.** Démarre une VM vierge sur cette ISO. Vérifie que PowerShell fonctionne et liste les disques.

> [!success]- Afficher la correction — B6
> VM Gen 2 vierge, DVD = `WinPE-Fournil.iso` (penser à la touche « Press any key »). WinPE exécute `wpeinit` puis donne la main :
> ```cmd
> powershell -NoProfile -Command "$PSVersionTable.PSVersion.ToString(); Get-Disk | Format-Table Number,FriendlyName,Size,PartitionStyle; Get-Volume | Format-Table DriveLetter,FileSystemLabel,Size"
> ```
> ![w11-15-winpe-powershell-disques](https://cours.kaya.ovh/windows11/assets/captures/w11-15-winpe-powershell-disques.png)
>
> PowerShell **5.1.26100.1** répond. Disque 0 = 64 Go **RAW** (vierge).

---

## Partie C — Le fichier de réponse avec WSIM (45 min)

**C1.** Copie `install.wim` depuis l'ISO, ouvre WSIM, sélectionne l'image **Windows 11 Professionnel**. Combien d'index contient ce `install.wim` ? Que se passe-t-il au premier chargement ?

> [!success]- Afficher la correction — C1
> ```powershell
> Copy-Item D:\sources\install.wim C:\Images\install.wim      # D: = ISO montée
> Get-WindowsImage -ImagePath C:\Images\install.wim | Select-Object ImageIndex, ImageName
> ```
> **11 index** sur l'ISO française 26H2 : Famille (1-3), Éducation (4-5), **Professionnel (6)**, Professionnel N (7), Professionnel Éducation (8-9), Professionnel pour les Stations de travail (10-11).
> Au premier chargement, WSIM propose de **créer un fichier catalogue** (`.clg`) : quelques minutes, une seule fois par image. Il faut un `install.wim` **copié** (accessible en écriture), pas celui de l'ISO.

**C2.** Passe **windowsPE** : langue fr-FR, disque 0 effacé, partitions EFI 200 Mo / MSR 16 Mo / Windows (tout le reste), installation sur la partition 3, contrat accepté, clé générique Pro.

> [!success]- Afficher la correction — C2
> Composants à ajouter à **1 windowsPE** : `Microsoft-Windows-International-Core-WinPE` et `Microsoft-Windows-Setup`.
> | Réglage | Valeur |
> |---------|--------|
> | `SetupUILanguage/UILanguage`, `InputLocale`, `SystemLocale`, `UILanguage`, `UserLocale` | `fr-FR` |
> | `DiskConfiguration/Disk` : `DiskID` / `WillWipeDisk` | `0` / `true` |
> | `CreatePartition` 1 / 2 / 3 | `EFI` 200 · `MSR` 16 · `Primary` `Extend=true` |
> | `ModifyPartition` (PartitionID 1) | `FAT32`, `System` |
> | `ModifyPartition` (PartitionID 3) | `NTFS`, `Windows`, lettre `C` |
> | `ImageInstall/OSImage/InstallTo` | `DiskID 0` / `PartitionID 3` |
> | `UserData/AcceptEula` | `true` |
> | `UserData/ProductKey/Key` | `VK7JG-NPHTM-C97JM-9MPGT-3V66T` |

**C3.** Pourquoi ne crée-t-on pas de partition de récupération dans le fichier ?

> [!success]- Afficher la correction — C3
> Windows Setup la crée **lui-même**, en fin de disque, en réduisant la partition Windows. Vérifié sur le lab : avec seulement EFI + MSR + Windows, les postes installés ont une partition **Recovery de 906 Mo en position 4**. L'ancienne version du cours créait WinRE **en tête** (500 Mo) : schéma dépassé, qui empêche d'agrandir WinRE lors des mises à jour.

**C4.** Passe **specialize** : nom généré automatiquement, organisation Fournil, fuseau `Romance Standard Time`.

> [!success]- Afficher la correction — C4
> `Microsoft-Windows-Shell-Setup` en **4 specialize** : `ComputerName = *` (le `*` **seul** génère un nom aléatoire ; `PC-*` provoque l'échec de la passe specialize, vécu sur le lab), `CopyProfile = false`, `RegisteredOrganization`/`RegisteredOwner = Fournil`, `TimeZone = Romance Standard Time`.
> Si le catalogue propose deux versions du composant (image contenant des mises à jour), prendre **la plus haute**.

**C5.** Passe **oobeSystem** : langue, masquage de tous les écrans, `ProtectYourPC = 3`, compte local `Utilisateur` administrateur avec mot de passe.

> [!success]- Afficher la correction — C5
> - `Microsoft-Windows-International-Core` : fr-FR partout, `UILanguageFallback = en-US`.
> - `Microsoft-Windows-Shell-Setup/OOBE` : `HideEULAPage`, `HideLocalAccountScreen`, `HideOEMRegistrationScreen`, `HideOnlineAccountScreens`, `HideWirelessSetupInOOBE` = `true` ; `ProtectYourPC = 3`.
> - `UserAccounts/LocalAccounts/LocalAccount` (clic droit → *Insérer un nouveau LocalAccount*) : `Name`/`DisplayName = Utilisateur`, `Group = Administrators`, `Password/Value = Fournil2026!`.
>
> `ProtectYourPC = 3` refuse les options de confidentialité facultatives (`1` = celles recommandées par Microsoft). Sans `LocalAccount`, `HideLocalAccountScreen` bloquerait l'OOBE.

**C6.** Valide (0 erreur) et enregistre `autounattend.xml`. Compare avec le fichier fourni `Ressources/Fichier-reponse/autounattend-fournil-26h2.xml`.

> [!success]- Afficher la correction — C6
> *Outils → Valider le fichier de réponses* : 0 erreur (les avertissements « paramètre non modifié » sont normaux). *Fichier → Enregistrer le fichier de réponses sous* → `autounattend.xml`.
> Le fichier fourni est celui qui a déployé `PC02` sur le lab : il ne doit différer que par des détails de mise en forme.

---

## Partie D — Le fichier d'installation de MASTER (10 min)

**D1.** Pourquoi faut-il un **second** fichier de réponse pour **installer** `MASTER` ?

> [!success]- Afficher la correction — D1
> Parce que l'installation de `MASTER` doit **s'arrêter à l'OOBE** (pour basculer en mode audit), alors que `autounattend-fournil-26h2.xml` va jusqu'au bureau. Et parce qu'il faut empêcher le **chiffrement automatique** BitLocker sur `MASTER` : sinon Sysprep échoue (`0x80310039`) — piège vécu sur le lab, qui a coûté une réinstallation de `MASTER`.

**D2.** Ajoute dans un nouveau fichier : passe windowsPE (disque + édition) et, en passe specialize, le composant qui empêche le chiffrement automatique. Pas de passe oobeSystem : pourquoi ?

> [!success]- Afficher la correction — D2
> - Passe **windowsPE** : comme en C2, plus `ImageInstall/OSImage/InstallFrom/MetaData` → `Key = /IMAGE/INDEX`, `Value = 6` (Pro), car l'ISO officielle contient 11 éditions.
> - Passe **specialize** : composant `Microsoft-Windows-SecureStartup-FilterDriver` → `PreventDeviceEncryption = true`.
> - **Pas** de passe oobeSystem : l'installation doit rester à l'OOBE pour `Ctrl+Maj+F3`.
>
> Fichier testé : `Ressources/Fichier-reponse/autounattend-installation-master.xml`. Résultat en mode audit : `Get-BitLockerVolume C:` → **FullyDecrypted**, `PreventDeviceEncryption = 1`.

---

## Partie E — Bonus

**E1.** Le fichier contient un mot de passe en clair. Que propose WSIM ? Est-ce un vrai chiffrement ?

> [!success]- Afficher la correction — E1
> *Fichier → Masquer les mots de passe sensibles* : WSIM remplace la valeur par une chaîne **Base64** (`PlainText = false`). Ce n'est **pas** un chiffrement : n'importe qui la décode en une ligne. Le fichier de réponse reste un document sensible (et il est copié dans `C:\Windows\Panther` du poste déployé — à nettoyer, ou à éviter en utilisant des comptes que LAPS reprendra en main).

**E2.** Sur une clé USB de 32 Go, comment faire tenir WinPE **et** une image de 8 Go ?

> [!success]- Afficher la correction — E2
> Une clé UEFI démarrable doit être en **FAT32** (limite de 4 Go par fichier). Deux solutions :
> - découper l'image : `Dism /Split-Image /ImageFile:MASTER.wim /SWMFile:MASTER.swm /FileSize:3800` puis appliquer avec `Dism /Apply-Image /ImageFile:MASTER.swm /SWMFile:MASTER*.swm /Index:1 /ApplyDir:W:\` ;
> - créer **deux partitions** : FAT32 (WinPE, quelques Go) + NTFS (images). Les UEFI récents démarrent sur la première et WinPE lit la seconde.

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp)
