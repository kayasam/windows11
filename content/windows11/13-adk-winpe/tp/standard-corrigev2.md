---
title: "TP 13. ADK, Windows PE et fichier de réponse — Correction"
aliases: ["windows11/13-adk-winpe/tp-corrigev2"]
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/13-adk-winpe"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="html" href="https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/html/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28 32"><path d="M2 2h24l-2 25-10 3-10-3Z" fill="#e44d26"/><path d="M14 5v22l7-2 2-20Z" fill="#f16529"/><path d="M7 8h15l-.3 3H11l.3 3h10l-.8 9-6.5 2-6.5-2-.4-5h3l.2 2.6 3.7 1 3.7-1 .3-3.6H8Z" fill="#fff"/></svg>
</span><span class="resource-label">HTML</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/13-adk-winpe-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp/standard">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp/standard-corrigev2" aria-current="page">Corrigé</a></nav>

> [!tip] Mot de passe du lab
> Remplace `MOT_DE_PASSE_DU_LAB` par la valeur donnée par le formateur pour le compte concerné.

> [!abstract] Parcours TSSR
> ADK, WinPE et catalogue WSIM sont préchargés ou mis en cache par le formateur. Socle : vérifier les outils, créer un WinPE standard, puis compléter et valider un fichier de réponse fourni. PowerShell dans WinPE et la préparation de MASTER sont (bonus).

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Chapitres associés : [12. ADK, Windows PE et fichier de réponse](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/)

---

## Objectifs

- Installer Windows ADK et son module WinPE **dans la bonne version**
- Créer et démarrer un WinPE standard ; personnalisation PowerShell et clavier français (bonus)
- Construire avec WSIM le fichier de réponse `autounattend.xml` du Fournil
- Préparer le petit fichier d'installation de `MASTER` (anti-chiffrement) (bonus)

---

## Fichier du TP

Télécharge <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/autounattend-fournil-26h2.xml" download data-router-ignore>autounattend-fournil-26h2.xml</a> dans `C:\Images` sur `PC01`. Ouvre cette copie dans WSIM. Garde le marqueur de mot de passe tant que tu vérifies seulement la structure.

## Prérequis

- `PC01` (poste d'administration) avec accès Internet, ~10 Go libres
- ISO Windows 11 26H2 montée dans `PC01` ou copiée dans `D:\ISO\` sur l'hôte

---

## Partie A — Installer l'ADK

**A1.** Sur `PC01`, quelle version de l'ADK WinGet propose-t-il par défaut ? Et pour le module WinPE ? Quelle version Microsoft indique-t-il pour l’ISO Windows 11 26H2 du lab ?

> [!success]- Afficher la correction — A1
> ```powershell
> winget search Microsoft.WindowsADK --source winget
> ```
> ```
> Windows Assessment and Deployment Kit           Microsoft.WindowsADK            10.1.28000.3481
> Windows ADK Preinstallation Environment Add-ons Microsoft.WindowsADK.WinPEAddon 10.1.28000.3481
> ```
> WinGet propose la branche **10.1.28000.3481** pour les deux paquets. Microsoft indique cette version pour Windows 11 **26H1**. Pour l’ISO **26H2** du lab, prends l’ADK et son module WinPE en **10.1.26100.9457**. [Versions prises en charge par Microsoft](https://learn.microsoft.com/windows-hardware/get-started/adk-install)

**A2.** Installe en mode silencieux l'ADK **10.1.26100.9457** (Outils de déploiement + USMT) puis le module WinPE correspondant.

> [!success]- Afficher la correction — A2
> ```powershell
> winget install --id Microsoft.WindowsADK -e --version 10.1.26100.9457 `
>     --override "/quiet /norestart /features OptionId.DeploymentTools OptionId.UserStateMigrationTool"
> winget install --id Microsoft.WindowsADK.WinPEAddon -e --version 10.1.26100.9457 `
>     --override "/quiet /norestart /features OptionId.WindowsPreinstallationEnvironment"
> ```
> `--override` remplace les arguments par défaut de l'installeur : on choisit précisément les fonctionnalités. Les deux installations prennent **≈ 3 minutes** sur le lab (petit installeur qui télécharge le reste).
>
> ![w11-13-winget-install-adk](https://cours.kaya.ovh/windows11/assets/captures/w11-13-winget-install-adk.png)

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

## Partie B — Windows PE

**B1.** Ouvre l'invite « Environnement de déploiement et d'outils de création d'images » en administrateur. Pourquoi cette invite plutôt qu'un terminal ordinaire ?

> [!success]- Afficher la correction — B1
> Menu Démarrer → taper *Environnement de déploiement* → **Exécuter en tant qu'administrateur**.
>
> ![w11-13-menu-environnement-deploiement](https://cours.kaya.ovh/windows11/assets/captures/w11-13-menu-environnement-deploiement.png)
>
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

**B3.** Monte `boot.wim` et ajoute : WMI, NetFx, Scripting, PowerShell, StorageWMI, DismCmdlets — avec leurs packs `fr-fr`. Dans quel ordre, et pourquoi ? (bonus)

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

**B4.** Passe le clavier de WinPE en français, vérifie les paquets, puis démonte en validant. (bonus)

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
> 100% complete
> Success
> 17/11/2026  09:42       398 462 976 WinPE-Fournil.iso
> ```
> **≈ 398 Mo** pour le WinPE standard du socle (≈ 567 Mo si le bonus B3 a ajouté PowerShell). `/F` écrase un fichier existant sans demander. Si `C:\Temp` n'existe pas : `mkdir C:\Temp` d'abord.
>
> ![w11-13-makewinpemedia](https://cours.kaya.ovh/windows11/assets/captures/w11-13-makewinpemedia.png)

**B6.** Démarre une VM vierge sur cette ISO. Dans l’invite CMD de WinPE standard, utilise `diskpart`, `list disk`, `list volume`, puis `exit`. PowerShell ne sera disponible que si tu as réalisé B3 et B4 (bonus).

> [!success]- Afficher la correction — B6
> Socle sans PowerShell : copier l'ISO sur l'hôte, créer une VM Gen 2 vierge (2 Go suffisent) avec l'ISO en premier périphérique de démarrage, appuyer sur une touche au « Press any key », puis `diskpart`, `list disk`, `list volume`, `exit`. Résultat : *Disk 0 Online 64 GB, 64 GB free* (disque vierge) et le DVD en `D:`. Aucune partition ne doit être créée dans cet exercice.
>
> ![w11-13-winpe-diskpart](https://cours.kaya.ovh/windows11/assets/captures/w11-13-winpe-diskpart.png)
>
> > [!WARNING] Clavier QWERTY
> > WinPE standard est en anglais **QWERTY** : sur un clavier AZERTY, le M est sur la touche virgule (`list volu;e`). Taper `wpeutil SetKeyboardLayout 040c:0000040c` pour passer en AZERTY.
>
> (bonus) Après B3 et B4, variante PowerShell :
> VM Gen 2 vierge, DVD = `WinPE-Fournil.iso` (penser à la touche « Press any key »). WinPE exécute `wpeinit` puis donne la main :
> ```cmd
> powershell -NoProfile -Command "$PSVersionTable.PSVersion.ToString(); Get-Disk | Format-Table Number,FriendlyName,Size,PartitionStyle; Get-Volume | Format-Table DriveLetter,FileSystemLabel,Size"
> ```
> ![w11-15-winpe-powershell-disques](https://cours.kaya.ovh/windows11/assets/captures/w11-15-winpe-powershell-disques.png)
>
> PowerShell **5.1.26100.1** répond. Disque 0 = 64 Go **RAW** (vierge).

---

## Partie C — Le fichier de réponse avec WSIM

**C1.** Copie `install.wim` de l'ISO dans `C:\Images` (ou utilise la copie préparée par le formateur), ouvre WSIM (« Assistant Gestion d'installation » dans le menu Démarrer), sélectionne l'image **Windows 11 Pro**. Combien d'index contient ce `install.wim` ? Que se passe-t-il au premier chargement ?

> [!success]- Afficher la correction — C1
> ```powershell
> Copy-Item D:\sources\install.wim C:\Images\install.wim      # D: = ISO montée
> Get-WindowsImage -ImagePath C:\Images\install.wim | Select-Object ImageIndex, ImageName
> ```
> **11 index** sur l'ISO française 26H2 : Famille (1-3), Éducation (4-5), **Professionnel (6)**, Professionnel N (7), Professionnel Éducation (8-9), Professionnel pour les Stations de travail (10-11).
> Lancer WSIM : menu Démarrer → **« Assistant Gestion d'installation »** (nom français de *Windows System Image Manager*). Clic droit dans le volet *Image Windows* → **Sélectionner l'image Windows…** → `C:\Images\install.wim` → **Windows 11 Pro** (noms anglais, *Home* présélectionné).
>
> Au premier chargement, WSIM propose de **créer un fichier catalogue** (`.clg`) → **Oui** puis **Oui** à l'UAC : ≈ **10 minutes** sur le lab (fichier `install_Windows 11 Pro.clg`, 2,7 Mo), une seule fois par image. Il faut un `install.wim` **copié** et **non en lecture seule** (`attrib -r`), pas celui de l'ISO.
>
> ![w11-13-wsim-creer-catalogue](https://cours.kaya.ovh/windows11/assets/captures/w11-13-wsim-creer-catalogue.png)

**C2.** Ouvre le fichier fourni `autounattend-fournil-26h2.xml` dans WSIM, puis vérifie et adapte la passe **windowsPE** : langue fr-FR, disque 0 effacé, partitions EFI 200 Mo / MSR 16 Mo / Windows (tout le reste), installation sur la partition 3, contrat accepté, clé générique Pro.

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
> - `UserAccounts/LocalAccounts/LocalAccount` (clic droit → *Insérer un nouveau LocalAccount*) : `Name`/`DisplayName = Utilisateur`, `Group = Administrators`, `Password/Value = MOT_DE_PASSE_DU_LAB`.
>
> `ProtectYourPC = 3` refuse les options de confidentialité facultatives (`1` = celles recommandées par Microsoft). Sans `LocalAccount`, `HideLocalAccountScreen` bloquerait l'OOBE.

**C6.** Valide (0 erreur) et enregistre `autounattend.xml`. Compare avec le fichier fourni `Ressources/Fichier-reponse/autounattend-fournil-26h2.xml`.

> [!success]- Afficher la correction — C6
> *Fichier → Ouvrir un fichier de réponses* → `autounattend-fournil-26h2.xml` → **Oui** pour l'associer à l'image. *Outils → Valider le fichier de réponses* : onglet *Validation* → **« Aucun avertissement ni erreur »** sur le lab. *Fichier → Enregistrer le fichier de réponses sous* → `C:\Images\autounattend.xml`.
>
> ![w11-13-wsim-validation](https://cours.kaya.ovh/windows11/assets/captures/w11-13-wsim-validation.png)
>
> Différences avec le fichier fourni après enregistrement : la mise en forme, une ligne `cpi:offlineImage` qui mémorise l'image utilisée, et le **mot de passe encodé** (`<PlainText>false</PlainText>`) car *Outils → Masquer les données sensibles* est coché par défaut (voir E1).

---

## Partie D — Le fichier d'installation de MASTER (bonus)

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

## Partie E — Exercices complémentaires (bonus)

**E1.** Le fichier contient un mot de passe en clair. Que propose WSIM ? Est-ce un vrai chiffrement ?

> [!success]- Afficher la correction — E1
> *Fichier → Masquer les mots de passe sensibles* : WSIM remplace la valeur par une chaîne **Base64** (`PlainText = false`). Ce n'est **pas** un chiffrement : n'importe qui la décode en une ligne. Le fichier de réponse reste un document sensible (et il est copié dans `C:\Windows\Panther` du poste déployé — à nettoyer, ou à éviter en utilisant des comptes que LAPS reprendra en main).

**E2.** Sur une clé USB de 32 Go, comment faire tenir WinPE **et** une image de 8 Go ?

> [!success]- Afficher la correction — E2
> Une clé UEFI démarrable doit être en **FAT32** (limite de 4 Go par fichier). Deux solutions :
> - découper l'image : `Dism /Split-Image /ImageFile:MASTER.wim /SWMFile:MASTER.swm /FileSize:3800` puis appliquer avec `Dism /Apply-Image /ImageFile:MASTER.swm /SWMFile:MASTER*.swm /Index:1 /ApplyDir:W:\` ;
> - créer **deux partitions** : FAT32 (WinPE, quelques Go) + NTFS (images). Les UEFI récents démarrent sur la première et WinPE lit la seconde.

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp/standard)
