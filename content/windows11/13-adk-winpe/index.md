---
title: "13. ADK, Windows PE et fichier de réponse"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/13-adk-winpe"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/13-adk-winpe.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Préparer les outils du déploiement : installer **Windows ADK et son module Windows PE** (en versions assorties), créer un support de démarrage **WinPE** personnalisé, et construire avec Windows SIM le fichier de réponse unique (`autounattend.xml`) qui servira au Sysprep de `MASTER` (chapitre 14) et à l'installation automatisée des postes (chapitre 16).
>
> **Outils :** Windows ADK, module WinPE, Windows System Image Manager (WSIM), `copype`, `MakeWinPEMedia`, `DISM`
> **Fichiers à connaître :** `install.wim`, `boot.wim`, `autounattend.xml`

> [!INFO] Fil rouge — Fournil
> L'ADK est installé sur `PC01` (poste d'administration) ; le fichier de réponse produit est `autounattend-fournil-26h2.xml` (dans `Ressources/Fichier-reponse/`).

---

## Stratégie d'image master

Plutôt que réinstaller Windows 11 et reconfigurer chaque poste individuellement, on prépare une **image master** (ou "image de référence") : un poste configuré une fois (applications, paramètres, pilotes courants), puis **généralisé** et capturé sous forme de fichier `.wim` (chapitre 15), redéployable ensuite sur d'autres machines (chapitre 16).

> [!TIP] Pourquoi une VM dédiée (`MASTER`) plutôt que réutiliser PC01 ?
> `PC01` est le poste de travail utilisé depuis le chapitre 1 : joint au domaine `ad.fournil.lab`, chargé de sa propre configuration, de comptes et d'historique. Généraliser cette machine serait risqué (casse la relation de confiance avec le domaine) et peu réaliste — en entreprise, on ne sysprep jamais un poste de production ou un poste d'administrateur en cours d'usage. La pratique standard est de préparer l'image sur une machine de référence **dédiée**, jamais jointe au domaine, jamais utilisée pour autre chose que la préparation d'image. C'est `MASTER`, créée au chapitre 14.

> [!NOTE] Une VM réutilisable, pas jetable
> Contrairement à une VM qu'on détruirait après chaque capture, `MASTER` est pensée pour vivre dans la durée : chaque mois (ou selon le rythme de l'entreprise), on la remet à jour (Windows Update, nouvelles versions d'applications), on la re-généralise, et on recapture une nouvelle version de l'image. Pour permettre ça sans tout recommencer de zéro à chaque fois, on protège l'état "prêt à généraliser" avec un point de contrôle Hyper-V plutôt qu'une sauvegarde complète de la VM — voir chapitre 14.

```
Ce chapitre (12)             Chapitre 14                    Chapitre 15        Chapitre 16
Outils + fichier de réponse   VM MASTER + mode audit          Capture WIM        ISO personnalisée
  install.wim            →    Checkpoint "Avant-Sysprep"  →   (DISM, hôte)   →   PC02 boot ISO → bureau
  ADK / Windows SIM            → sysprep /generalize                              (zéro clic, autounattend.xml)
  autounattend.xml             → capture prête

  PC01 : jamais touché, reste joint au domaine tout du long
```

> [!NOTE] Pourquoi une ISO personnalisée plutôt que WDS ou MDT ?
> En 2026, les deux outils « historiques » du déploiement sur site sont hors jeu :
> - **MDT** a été **retiré le 6 janvier 2026** (plus de support, plus de correctifs, téléchargement susceptible de disparaître) ;
> - **WDS** : le déploiement *mains libres* (fichier de réponse servi par WDS) est **bloqué par défaut depuis la mise à jour d'avril 2026** (faille CVE-2026-0386), et le rôle entier est **déprécié** pour la prochaine version de Windows Server.
>
> Une **ISO personnalisée** (image généralisée + fichier de réponse) reste la méthode autonome, sans infrastructure, qui fonctionne. Le détail des alternatives (ConfigMgr, Autopilot) est au chapitre 16.

> [!WARNING] Pourquoi généraliser avant de capturer ?
> Sans généralisation, tous les postes déployés à partir de l'image partageraient le **même SID machine** (identifiant de sécurité) que la référence — un problème connu sous le nom de "SID de duplication", qui peut causer des conflits en environnement Active Directory (identités machine ambiguës) et poser des problèmes de licence/activation.

---

## Récupérer le fichier install.wim

Windows SIM a besoin d'un fichier `install.wim` pour construire et valider le fichier de réponse (il y lit la liste des composants disponibles).

1. Monter l'ISO Windows 11 officielle (double-clic dessus, ou `Mount-DiskImage`).
2. Copier `sources\install.wim` depuis le lecteur monté vers un dossier de travail, par exemple `D:\Images\install.wim`.

```powershell
Mount-DiskImage -ImagePath "D:\ISO\Win11_25H2_French.iso"
Copy-Item "E:\sources\install.wim" -Destination "D:\Images\install.wim"
Dismount-DiskImage -ImagePath "D:\ISO\Win11_25H2_French.iso"
```

> [!NOTE] Plus besoin de convertir un .esd
> Certaines anciennes éditions livraient un fichier `install.esd` (compressé/chiffré) à la place de `install.wim`, nécessitant une conversion préalable via `dism /Export-Image`. Les supports d'installation Windows 11 actuels fournissent directement `install.wim` dans le dossier `sources` — cette étape de conversion n'est plus nécessaire.

---

## Installer Windows ADK et le module Windows PE

Le [Kit de déploiement et d'évaluation Windows (ADK)](https://learn.microsoft.com/windows-hardware/get-started/adk-install) se compose de **deux installeurs** :

| Installeur | Fonctionnalités utiles ici |
|------------|----------------------------|
| **ADK** | **Outils de déploiement** (DISM, `oscdimg`, WSIM, `copype`) · **Outil de migration de l'état utilisateur (USMT)** (chapitre 16) |
| **Module complémentaire Windows PE** (*WinPE add-on*) | L'environnement Windows PE (`winpe.wim`, composants optionnels) |

![w11-12-sysprep-images](https://cours.kaya.ovh/windows11/assets/captures/w11-12-sysprep-images.png)

> [!TIP] Pas besoin du "Concepteur de configuration"
> Cette fonctionnalité (ICD, *Imaging and Configuration Designer*) sert à créer des **paquets de provisionnement** (`.ppkg`) — une méthode alternative de personnalisation en bloc, indépendante de Windows SIM. Elle n'est pas nécessaire ici.

### Installation silencieuse avec WinGet (testée sur PC01)

```powershell
winget install --id Microsoft.WindowsADK -e --version 10.1.26100.9457 `
    --override "/quiet /norestart /features OptionId.DeploymentTools OptionId.UserStateMigrationTool"
winget install --id Microsoft.WindowsADK.WinPEAddon -e `
    --override "/quiet /norestart /features OptionId.WindowsPreinstallationEnvironment"
```

> [!WARNING] ADK et module WinPE : toujours la **même version**
> Vécu sur le lab : `winget install Microsoft.WindowsADK` installe par défaut l'ADK **10.1.28000** (branche *26H1*, pour les PC Arm Snapdragon), alors que le module WinPE disponible est en **10.1.26100.9457**. Les deux doivent avoir **exactement** la même version, et correspondre à la famille de Windows déployée : pour 24H2/25H2/**26H2**, c'est la branche **26100**. D'où le `--version 10.1.26100.9457` explicite.
> À noter aussi : WinPE **x86** n'existe plus dans les ADK récents (amd64 et arm64 uniquement).

Résultat dans `C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\` :

```
Deployment Tools
User State Migration Tool
Windows Preinstallation Environment
Windows Setup
```

---

## Windows PE — l'environnement de préinstallation

**Windows PE** (WinPE) est un Windows **minimal** qui démarre depuis une clé USB, une ISO ou le réseau, entièrement en mémoire (lecteur `X:`). C'est lui qui tourne quand on démarre sur l'ISO d'installation de Windows (`boot.wim`). On s'en sert pour :

- **capturer** ou **appliquer** une image (`DISM`) sur un poste physique ;
- **partitionner** un disque (`diskpart`) avant déploiement ;
- **dépanner** un poste qui ne démarre plus (accès aux fichiers, `bcdboot`) ;
- lancer un outil de déploiement (ConfigMgr, outils tiers).

### Créer un WinPE (environnement « Outils de déploiement et de création d'images »)

Les commandes s'exécutent dans l'invite **« Environnement de déploiement et d'outils de création d'images »** (menu Démarrer → Windows Kits), en administrateur — elle positionne les variables d'environnement de l'ADK.

```cmd
:: 1) Copier les fichiers WinPE dans un dossier de travail
copype amd64 C:\WinPE_amd64

:: 2) Monter l'image boot.wim de WinPE pour la personnaliser
Dism /Mount-Image /ImageFile:C:\WinPE_amd64\media\sources\boot.wim /Index:1 /MountDir:C:\WinPE_amd64\mount
```

### Personnaliser WinPE avec DISM : ajouter PowerShell

WinPE de base n'a ni PowerShell ni WMI. On ajoute des **composants optionnels** (fichiers `.cab` du module WinPE) — **toujours avec leur pack de langue** :

```cmd
set OC=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs

Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\WinPE-WMI.cab"
Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\fr-fr\WinPE-WMI_fr-fr.cab"
Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\WinPE-NetFx.cab"
Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\fr-fr\WinPE-NetFx_fr-fr.cab"
Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\WinPE-Scripting.cab"
Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\fr-fr\WinPE-Scripting_fr-fr.cab"
Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\WinPE-PowerShell.cab"
Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\fr-fr\WinPE-PowerShell_fr-fr.cab"
Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\WinPE-StorageWMI.cab"
Dism /Image:C:\WinPE_amd64\mount /Add-Package /PackagePath:"%OC%\fr-fr\WinPE-StorageWMI_fr-fr.cab"

:: Clavier français dans WinPE
Dism /Image:C:\WinPE_amd64\mount /Set-InputLocale:fr-FR

:: Ajouter un pilote (carte réseau/stockage absente en boîte)
Dism /Image:C:\WinPE_amd64\mount /Add-Driver /Driver:C:\Drivers\Reseau /Recurse

:: Vérifier puis démonter en enregistrant
Dism /Image:C:\WinPE_amd64\mount /Get-Packages
Dism /Unmount-Image /MountDir:C:\WinPE_amd64\mount /Commit
```

L'ordre compte : **WMI → NetFx → Scripting → PowerShell** (dépendances).

### Créer le support de démarrage

```cmd
:: ISO (pour une VM ou une gravure)
MakeWinPEMedia /ISO C:\WinPE_amd64 D:\ISO\WinPE-Fournil.iso

:: Clé USB (la clé sera formatée !)
MakeWinPEMedia /UFD C:\WinPE_amd64 P:
```

Au démarrage, WinPE ouvre une invite de commandes (`X:\Windows\System32>`), avec `wpeinit` déjà exécuté (réseau DHCP initialisé). `powershell` y est disponible grâce aux composants ajoutés. On s'en servira au chapitre 15 pour appliquer une image avec `Dism /Apply-Image` + `bcdboot`.

> [!TIP] Clé USB de plus de 32 Go ou image de plus de 4 Go
> Une clé UEFI doit être en **FAT32** pour démarrer, et FAT32 limite les fichiers à 4 Go. Pour transporter un `install.wim` plus gros sur la même clé : `Dism /Split-Image` en fichiers `.swm` de 3,8 Go, ou une seconde partition NTFS pour les données.

---

## Créer le fichier de réponse avec Windows SIM

Un fichier de réponse est découpé en **7 passes de configuration**, chacune exécutée à un moment précis du cycle d'installation/démarrage de Windows :

| # | Passe | S'exécute... | Utilisée ici ? |
|---|-------|---------------|-----------------|
| 1 | `windowsPE` | Dans l'environnement de préinstallation, avant la copie des fichiers : langue, partitionnement du disque, clé de produit | **Oui** — automatise l'installation sur les postes cibles (chapitre 16) |
| 2 | `offlineServicing` | Sur l'image Windows hors ligne, juste après la copie des fichiers (ajout de correctifs/pilotes) | Non |
| 3 | `generalize` | Pendant `sysprep /generalize` (contrôle ce qui est généralisé — pilotes, identifiants matériels) | Non |
| 4 | `specialize` | Au premier démarrage après généralisation, sur **chaque machine déployée** : nom d'ordinateur, fuseau horaire, réseau | **Oui** — `ComputerName` |
| 5 | `auditSystem` | Au démarrage en mode audit, avant l'ouverture de session (contexte système) | Non |
| 6 | `auditUser` | En mode audit, après ouverture de session (contexte utilisateur — scripts/apps auto) | Non |
| 7 | `oobeSystem` | Au dernier démarrage, à l'écran d'accueil final (OOBE) présenté à l'utilisateur | **Oui** — masquage des écrans OOBE |

> [!NOTE] Un seul fichier, deux usages
> Ce même fichier est utilisé à **deux moments distincts**, chacun ne lisant que les passes qui le concernent :
> - Au **Sysprep** de `MASTER` (`/generalize /oobe /unattend:`, chapitre 14) : seules les passes `specialize` et `oobeSystem` sont appliquées, la passe `windowsPE` est ignorée (le disque de `MASTER` est déjà partitionné).
> - Au **démarrage de l'ISO de déploiement** sur un poste cible (chapitre 16) : c'est l'inverse, la passe `windowsPE` pilote l'installation (partitionnement, clé de produit), puis `specialize`/`oobeSystem` s'appliquent normalement au premier démarrage.
>
> `generalize`, `offlineServicing`, `auditSystem` et `auditUser` ne sont utilisées dans aucun de ces deux scénarios ici.

### Comment les passes s'enchaînent

Le schéma officiel Microsoft ci-dessous montre que la passe `specialize` n'est **pas jouée qu'une seule fois** : elle est rejouée à chaque fois que Windows redémarre après une généralisation — ce qui explique pourquoi `ComputerName: *` produit bien un nom différent sur chaque machine déployée, même si elles proviennent toutes de la même image.

```
DÉROULÉ NORMAL — une installation classique, sans Sysprep

  windowsPE ──► offlineServicing ──► specialize ──► oobeSystem ──► Bureau
  (partition,                        (nom de la                  (écrans OOBE
   clé, langue)                       machine, fuseau)             affichés ou masqués)


NOTRE DÉTOUR — utilisé sur MASTER (chapitre 14)

  ... specialize ──► oobeSystem
                          │
                          │  Ctrl+Shift+F3 (avant la fin de l'OOBE)
                          ▼
                     auditSystem ──► auditUser     ← mode audit : personnalisation
                          │                            de MASTER (mises à jour, logiciels)
                          │  sysprep /generalize /oobe /unattend:autounattend.xml
                          ▼
                     generalize ──► specialize ──► oobeSystem ──► Bureau
                     (efface le      (rejouée, cette              (sur CHAQUE poste
                      SID et les      fois "pour de vrai",          déployé au
                      infos machine)  sur chaque poste déployé)     chapitre 16)
```

> [!NOTE] Ce que ça change concrètement
> `MASTER` ne termine jamais elle-même la passe `oobeSystem` — on l'interrompt en mode audit avant. C'est chaque machine **déployée** à partir de l'image capturée qui rejoue `specialize` puis `oobeSystem` pour de vrai, avec un SID propre et un nom généré (`FOURNIL-XXXXXXX`). C'est exactement pour ça que la généralisation (chapitre 14) est indispensable avant toute capture.

**Étape 1 — Charger l'image.** Fichier → Sélectionner une image Windows... → pointer vers `D:\Images\install.wim` → choisir l'édition (Windows 11 Pro). Si aucun fichier catalogue (`.clg`) n'existe encore, WSIM propose de le créer (quelques minutes, une seule fois par image).
![w11-12-sysprep-images-1](https://cours.kaya.ovh/windows11/assets/captures/w11-12-sysprep-images-1.png)
**Étape 2 — Nouveau fichier de réponse.** Fichier → Nouveau fichier de réponse...
![w11-12-sysprep-images-2](https://cours.kaya.ovh/windows11/assets/captures/w11-12-sysprep-images-2.png)

> [!INFO] Components et Packages
> Le fichier de réponse fraîchement créé contient deux dossiers, sous chacune de ses 7 passes :
> - **Components** : les composants logiciels disponibles dans l'image `install.wim` chargée. Chaque composant représente une fonctionnalité de Windows (langue, shell, réseau...) configurable via le fichier de réponse — c'est ici qu'on va chercher `Microsoft-Windows-Shell-Setup` dans les étapes suivantes.
> - **Packages** : les paquets disponibles dans l'image (mises à jour, pilotes, fonctionnalités linguistiques, fonctionnalités optionnelles) pouvant être ajoutés à l'image pendant le déploiement. Non utilisé dans ce chapitre.

**Étape 3 — Passe `windowsPE`.** Cette passe automatise l'installation elle-même sur les postes cibles (chapitre 16) : plus de clics sur langue/partition/édition, l'installation se lance seule jusqu'au premier démarrage.

Ajouter le composant `Microsoft-Windows-International-Core-WinPE` à la passe **1 windowsPE** :

| Paramètre | Valeur | Rôle |
|-----------|--------|------|
| `InputLocale`, `SystemLocale`, `UILanguage`, `UserLocale` | `fr-FR` | Langue du clavier et de l'interface pendant l'installation |
| `SetupUILanguage > UILanguage` | `fr-FR` | Langue affichée par le programme d'installation lui-même |

Ajouter ensuite le composant `Microsoft-Windows-Setup` à la même passe **1 windowsPE** :

| Section | Paramètre | Valeur | Rôle |
|---------|-----------|--------|------|
| `DiskConfiguration > Disk[0]` | `WillWipeDisk` | `true` | Efface tout le disque cible avant de partitionner — le poste déployé est considéré comme vierge |
| `CreatePartition[1]` | `Type` / `Size` | `EFI` / `200` | Partition système EFI, nécessaire au démarrage UEFI |
| `CreatePartition[2]` | `Type` / `Size` | `MSR` / `16` | Partition réservée Microsoft (MSR), 16 Mo, sans lettre ni système de fichiers |
| `CreatePartition[3]` | `Type` / `Extend` | `Primary` / `true` | Partition Windows, occupe **tout le reste** du disque |
| `ModifyPartition[1]` (PartitionID 1) | `Format` / `Label` | `FAT32` / `System` | |
| `ModifyPartition[2]` (PartitionID 3) | `Format` / `Label` / `Letter` | `NTFS` / `Windows` / `C` | |
| `ImageInstall > OSImage > InstallTo` | `DiskID` / `PartitionID` | `0` / `3` | Installe Windows sur la partition 3 du disque 0 |

> [!NOTE] Et la partition de récupération (WinRE) ?
> La v1 de ce cours créait une partition WinRE de 500 Mo **en tête** de disque : c'est l'ancien schéma, qui empêche d'agrandir WinRE lors des mises à jour (chapitre 02). Constaté sur le lab : avec seulement **EFI + MSR + Windows (`Extend`)**, Windows Setup réduit lui-même la partition Windows et crée une partition de **récupération d'environ 900 Mo en fin de disque**, comme une installation manuelle. Plus simple et conforme aux recommandations actuelles.
| `UserData > AcceptEula` | — | `true` | Accepte automatiquement le contrat de licence de **Windows Setup** (l'écran "Avis et conditions du contrat de licence applicables") |
| `UserData > ProductKey` | `Key` | `VK7JG-NPHTM-C97JM-9MPGT-3V66T` | Clé générique Windows 11 Pro (KMS client) — active le choix de l'édition sans licence individuelle à saisir |

> [!WARNING] `Extend` obligatoire sur la dernière partition
> Une partition `CreatePartition` doit avoir **soit** `Size`, **soit** `Extend` — jamais aucun des deux, jamais les deux à la fois. Sans l'un ou l'autre, Windows Setup rejette tout le bloc `DiskConfiguration` avec une erreur de validation (visible dans `setuperr.log` : *"Neither Extend nor Size were specified for CreatePartition"*) et l'installation échoue avant même de commencer à copier les fichiers.

> [!WARNING] Deux écrans de licence différents, deux réglages différents
> `AcceptEula` (passe `windowsPE`, ci-dessus) accepte le contrat de licence affiché **pendant l'installation**, par le programme Windows Setup lui-même. `HideEULAPage` (passe `oobeSystem`, étape 5 plus bas) masque un écran **différent**, affiché à l'utilisateur final au tout premier démarrage après l'installation. Sans `AcceptEula`, Windows Setup s'arrête sur l'écran de licence en attendant un clic manuel — et cette interruption empêche aussi la suite de l'automatisation (`InstallTo` ne s'applique plus, l'assistant de partitionnement reste affiché en attente d'une sélection manuelle).

> [!NOTE] Pourquoi cette clé de produit générique ?
> `VK7JG-NPHTM-C97JM-9MPGT-3V66T` est une clé "KMS client" publiée par Microsoft — elle sélectionne l'édition Windows 11 Pro et permet à l'installation de se dérouler sans écran de saisie de clé, mais n'active pas Windows en elle-même (l'activation dépendra du mécanisme habituel de l'entreprise : KMS, MAK, ou licence numérique liée au matériel).

**Étape 4 — Passe `specialize`.** Ajouter le composant `Microsoft-Windows-Shell-Setup` à la passe **4 specialize** et configurer :
![w11-12-sysprep-images-3](https://cours.kaya.ovh/windows11/assets/captures/w11-12-sysprep-images-3.png)
> [!WARNING] Plusieurs versions du même composant ?
> Le catalogue liste parfois deux entrées pour `Microsoft-Windows-Shell-Setup` (ex. `10.0.26100.1150` et `10.0.26100.7309`) — l'image contient des mises à jour cumulatives intégrées, qui ajoutent une version plus récente du composant sans faire disparaître l'ancienne du catalogue. **Toujours choisir la version la plus haute** : c'est la seule réellement active une fois l'image appliquée.

| Paramètre | Valeur | Rôle |
|-----------|--------|------|
| `ComputerName` | `*` | Nom donné à la machine. `*` **seul** fait générer un nom aléatoire, préfixé par l'organisation (`FOURNIL-AN4OLJL` sur le lab, grâce à `RegisteredOrganization`) ; **`PC-*` est invalide** (voir l'avertissement ci-dessous) — sans ça, toutes les machines déployées depuis cette image porteraient le même nom, ce qui provoquerait des conflits sur le domaine. |
| `CopyProfile` | `false` | N'applique pas le profil de l'utilisateur courant (celui utilisé en mode audit) comme profil par défaut — chaque poste déployé démarre avec un profil propre. |
| `RegisteredOrganization` | `Fournil` | Nom d'organisation affiché dans les informations système (`winver`, Paramètres > Système). Cosmétique, mais utile pour identifier le parc. |
| `RegisteredOwner` | `Fournil` | Propriétaire enregistré, même usage que ci-dessus. |
| `TimeZone` | `Romance Standard Time` | Fuseau horaire Paris/Bruxelles/Madrid — évite un écran de sélection ou une heure incorrecte au premier démarrage. |

> [!DANGER] `PC-*` fait échouer le déploiement — vécu sur le lab
> La v1 de ce cours utilisait `ComputerName = PC-*`. Résultat au premier démarrage du poste déployé : « *L'ordinateur a redémarré de manière inattendue ou a rencontré une erreur inattendue* », et dans `C:\Windows\Panther\UnattendGC\setuperr.log` :
> ```
> [Shell Unattend] ComputerName: failed to set the computer name [hr=0x80070057]
> Windows n'a pas pu analyser ou traiter le fichier de réponses sans assistance pour l'étape [specialize].
> ```
> Le `*` ne fonctionne que **seul** (nom aléatoire). Pour imposer une convention de nommage : renommer à la jonction au domaine (`Add-Computer -NewName`), par script en fin d'installation (`FirstLogonCommands`), ou via l'outil de déploiement (ConfigMgr, Autopilot : modèle de nom `FOURNIL-%RAND:5%`).

**Étape 5 — Passe `oobeSystem`.** Deux composants à ajouter à la passe **7 oobeSystem**.

D'abord `Microsoft-Windows-International-Core` (langue de l'interface finale, distincte de celle de l'installation) :

| Paramètre | Valeur | Rôle |
|-----------|--------|------|
| `InputLocale`, `SystemLocale`, `UILanguage`, `UserLocale` | `fr-FR` | Langue de l'interface une fois sur le bureau |
| `UILanguageFallback` | `en-US` | Langue de repli si un composant n'a pas de traduction française disponible |

Ensuite `Microsoft-Windows-Shell-Setup`, sous `OOBE` :

| Paramètre | Valeur | Rôle |
|-----------|--------|------|
| `HideEULAPage` | `true` | Masque l'écran d'acceptation du contrat de licence — sinon chaque poste déployé resterait bloqué dessus tant que personne ne clique. |
| `HideLocalAccountScreen` | `true` | Masque l'écran de création de compte local — nécessaire pour un vrai zéro clic, mais **suppose qu'un compte local est déjà défini** ci-dessous, sinon l'installation n'a nulle part où aller. |
| `HideOEMRegistrationScreen` | `true` | Masque l'écran d'enregistrement constructeur (non pertinent en environnement Hyper-V/entreprise). |
| `HideOnlineAccountScreens` | `true` | Masque les écrans proposant un compte Microsoft en ligne — garantit que le compte créé reste **local**, jamais un compte Microsoft. |
| `HideWirelessSetupInOOBE` | `true` | Masque l'étape de configuration Wi-Fi — les postes du lab sont câblés/déjà réseau ; sans ce réglage, l'OOBE peut bloquer en l'absence de Wi-Fi disponible. |
| `ProtectYourPC` | `3` | Passe l'écran « Confidentialité » sans l'afficher, en **refusant** les options facultatives (`1` = paramètres recommandés par Microsoft, `3` = minimum ; le RGPD plaide pour `3`). |

Puis, toujours dans `Microsoft-Windows-Shell-Setup`, sous `UserAccounts > LocalAccounts > LocalAccount` (clic droit → Ajouter un nouvel élément) :

| Paramètre | Valeur | Rôle |
|-----------|--------|------|
| `Name` | `Utilisateur` | Nom de connexion du compte local créé automatiquement. |
| `DisplayName` | `Utilisateur` | Nom affiché à l'écran de connexion. |
| `Description` | `Compte Local Principal` | Description du compte (visible dans la gestion des utilisateurs). |
| `Group` | `Administrators` | Le compte est créé avec des droits administrateur local. |
| `Password > Value` | `Fournil2026!` (`PlainText` = `true`) | Mot de passe du compte. WSIM propose d'**obscurcir** les mots de passe à l'enregistrement (*Fichier → Masquer les mots de passe sensibles*) : c'est un simple encodage Base64, pas un chiffrement — le fichier reste sensible. |

> [!WARNING] Sans compte local défini, `HideLocalAccountScreen` bloque l'installation
> Masquer l'écran de création de compte sans fournir de compte local en remplacement ne fait pas disparaître le besoin d'un compte : Windows Setup n'a alors aucune information pour continuer et l'installation reste bloquée. Les deux réglages (masquage + `LocalAccount`) vont toujours de pair.

**Étape 6 — Valider et enregistrer.** Vérifier le panneau "Messages de validation" (0 erreur), puis Fichier → Enregistrer le fichier de réponses sous → `autounattend.xml`.

Le fichier complet, testé sur le lab, est fourni : `Ressources/Fichier-reponse/autounattend-fournil-26h2.xml`.

### Un second petit fichier : empêcher le chiffrement automatique de MASTER

> [!DANGER] Le piège de 2026 : Sysprep refuse un disque chiffré
> Depuis la 24H2, Windows active le **chiffrement automatique de l'appareil** (BitLocker) dès l'installation, y compris pendant le mode audit. Vécu sur le lab au premier Sysprep de `MASTER` :
> ```
> SYSPRP BitLocker-Sysprep: BitLocker is on for the OS volume. Turn BitLocker off to run Sysprep. (0x80310039)
> ```
> Et impossible de s'en sortir après coup : `manage-bde -off C:` comme `Disable-BitLocker` échouent en mode audit avec **0x8007007A** (« La zone de données passée à un appel système est insuffisante »). Il a fallu réinstaller `MASTER`.

La parade documentée : **empêcher** le chiffrement dès l'installation de la machine de référence, avec le composant `Microsoft-Windows-SecureStartup-FilterDriver` en passe **specialize** :

```xml
<settings pass="specialize">
  <component name="Microsoft-Windows-SecureStartup-FilterDriver" processorArchitecture="amd64"
             publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
    <PreventDeviceEncryption>true</PreventDeviceEncryption>
  </component>
</settings>
```

C'est l'objet du fichier `Ressources/Fichier-reponse/autounattend-installation-master.xml`, utilisé pour **installer** `MASTER` (passe windowsPE pour le disque, specialize pour le chiffrement, et **pas** de passe oobeSystem : l'installation s'arrête à l'OOBE, où l'on bascule en mode audit). Il écrit `PreventDeviceEncryption = 1` sous `HKLM\SYSTEM\CurrentControlSet\Control\BitLocker` — valeur qui sera **capturée avec l'image** : les postes déployés ne se chiffreront pas d'eux-mêmes, c'est l'administrateur qui activera BitLocker proprement (GPO + sauvegarde des clés dans AD, chapitre 11).

> [!WARNING] Le nom du fichier compte
> Contrairement au fichier utilisé pour le Sysprep (peu importe son nom), celui déposé à la racine de l'ISO de déploiement (chapitre 16) doit s'appeler **exactement** `autounattend.xml` — c'est ce nom précis que Windows Setup recherche automatiquement au démarrage sur les supports amovibles/optiques.

---

## Tableau récapitulatif de tous les paramètres

Vue d'ensemble de tout ce que contient `autounattend.xml`, passe par passe :

| Passe | Composant | Paramètre | Valeur |
|-------|-----------|-----------|--------|
| **1 windowsPE** | International-Core-WinPE | `InputLocale`, `SystemLocale`, `UILanguage`, `UserLocale` | `fr-FR` |
| | | `SetupUILanguage > UILanguage` | `fr-FR` |
| | Microsoft-Windows-Setup | `WillWipeDisk` | `true` |
| | | Partitions (1-3) | EFI 200 Mo · MSR 16 Mo · Windows (`Extend=true`, lettre C) — WinRE créé par Setup en fin de disque |
| | | `InstallTo` | `DiskID 0` / `PartitionID 3` |
| | | `AcceptEula` | `true` |
| | | `ProductKey` | `VK7JG-NPHTM-C97JM-9MPGT-3V66T` |
| **4 specialize** | Shell-Setup | `ComputerName` | `*` (jamais `PC-*`) |
| | | `CopyProfile` | `false` |
| | | `RegisteredOrganization` / `RegisteredOwner` | `Fournil` |
| | | `TimeZone` | `Romance Standard Time` |
| **7 oobeSystem** | International-Core | `InputLocale`, `SystemLocale`, `UILanguage`, `UserLocale` | `fr-FR` |
| | | `UILanguageFallback` | `en-US` |
| | Shell-Setup > OOBE | `HideEULAPage` | `true` |
| | | `HideLocalAccountScreen` | `true` |
| | | `HideOEMRegistrationScreen` | `true` |
| | | `HideOnlineAccountScreens` | `true` |
| | | `HideWirelessSetupInOOBE` | `true` |
| | | `ProtectYourPC` | `3` |
| | Shell-Setup > UserAccounts | `LocalAccount` (Name/DisplayName) | `Utilisateur` |
| | | `Group` / `Password` | `Administrators` / `Fournil2026!` |

---

## Récapitulatif

```
install.wim         copié depuis l'ISO Windows 11 (pas de conversion .esd nécessaire)
ADK + WinPE add-on   MÊME version (26100.x pour 24H2/25H2/26H2) — Outils de déploiement + USMT + WinPE
WinPE                copype amd64 → Dism /Mount-Image → Add-Package (WMI, NetFx, Scripting, PowerShell + fr-fr)
                     → /Unmount-Image /Commit → MakeWinPEMedia /ISO ou /UFD
MASTER               installée avec PreventDeviceEncryption=true (sinon Sysprep échoue : 0x80310039)
autounattend.xml     via WSIM, un seul fichier pour deux usages :
                       - windowsPE (passe 1)   : partitionnement, clé produit, langue           → utilisé chapitre 16 (ISO)
                       - specialize (passe 4)  : ComputerName, organisation, fuseau horaire       → utilisé chapitre 14 (Sysprep)
                       - oobeSystem (passe 7)  : Hide* (5 écrans), ProtectYourPC, compte local     → utilisé aux deux chapitres
                                                  Utilisateur/Administrators — sans lui, HideLocalAccountScreen bloque tout

→ Chapitre 14 : création de MASTER, mode audit, et application de ce fichier au moment du Sysprep
→ Chapitre 16 : ce même fichier, déposé à la racine de l'ISO de déploiement
```
