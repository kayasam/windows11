# 16. Déployer Windows 11 : ISO, réseau, migration, moderne

> [!NOTE] Objectif
> Connaître les méthodes de déploiement d'un poste en 2026 et leur statut, réaliser un déploiement **zéro clic** par ISO personnalisée (image `MASTER.wim` + `autounattend.xml`), situer PXE/WDS et MDT (présentation : retirés ou bloqués en 2026), **migrer les profils** avec USMT, et comprendre le déploiement **moderne** (Windows Autopilot + Intune).
>
> **Outils :** `oscdimg.exe`, USMT (`scanstate`/`loadstate`), WinPE, PowerShell
> **Fichiers à connaître :** `install.wim` (remplacé), `autounattend.xml`, `MigApp.xml`/`MigDocs.xml`/`MigUser.xml`

> [!INFO] Fil rouge — Fournil
> `PC02` est déployé depuis l'ISO `MASTER-Deploiement.iso`, puis joint au domaine ; les données de `stagiaire` sont migrées depuis `PC01` avec USMT.

---

## 1. Panorama des méthodes de déploiement (2026)

| Méthode | Principe | Infrastructure | Statut 2026 |
|---------|----------|----------------|-------------|
| **Manuelle** | ISO/clé USB officielle, on clique | Aucune | ✅ Dépannage, poste isolé |
| **Automatisée** | ISO/clé + `autounattend.xml` | Aucune | ✅ Ce cours (chapitre 13) |
| **Par image** | `MASTER.wim` appliquée (ISO personnalisée, WinPE + DISM) | Aucune, ou un partage | ✅ Ce chapitre et le chapitre 15 |
| **Réseau — WDS** (PXE) | Le poste démarre sur la carte réseau, WDS fournit WinPE et l'image | Serveur WDS + DHCP | ⚠️ **Mains libres bloqué depuis avril 2026**, rôle **déprécié** |
| **Réseau — MDT** (Lite Touch) | Séquences de tâches sur un partage, souvent via WDS | Serveur de déploiement | ❌ **Retiré le 6 janvier 2026** |
| **Réseau — ConfigMgr OSD** | Séquences de tâches, PXE, multidiffusion | Microsoft Configuration Manager | ✅ Supporté (grandes entreprises sur site) |
| **Mise à niveau en place** | `setup.exe /auto upgrade` | Aucune | ✅ Windows 10 → 11 (chapitre 02) |
| **Package de provisionnement** | Fichier `.ppkg` appliqué sur un Windows d'usine | Windows Configuration Designer | ✅ PME, écoles |
| **Moderne — Autopilot** | Le Windows d'usine est configuré depuis le cloud, au premier démarrage | Entra ID + Intune | ✅ **Recommandé par Microsoft** |

> [!NOTE] Pourquoi une ISO personnalisée pour le lab ?
> C'est la seule méthode « traditionnelle » encore pleinement fonctionnelle **sans infrastructure** : MDT est retiré, WDS ne sert plus de fichier de réponse par défaut, ConfigMgr est une infrastructure lourde, Autopilot exige un tenant et des licences. L'ISO personnalisée fait la même chose qu'eux sur le fond : **WinPE → partitionnement → application d'une image → fichier de réponse**.

---

## 2. Méthode 1 — l'ISO de déploiement personnalisée

```
MASTER.wim (chapitre 15)         autounattend.xml (chapitre 13)
        │                                  │
        └──────────────┬───────────────────┘
                        ▼
        ISO Windows 11 officielle, copiée dans un dossier de travail
        → install.wim remplacé par MASTER.wim
        → autounattend.xml déposé à la racine
                        ▼
              oscdimg → ISO bootable
                        ▼
        Attachée à PC02 → démarrage → zéro clic → bureau
```

---

### Prérequis

| Élément | Origine |
|---------|---------|
| `MASTER.wim` | Chapitre 15 (capture DISM) |
| `autounattend.xml` | Chapitre 13 (Windows SIM, passes `windowsPE` + `specialize` + `oobeSystem`) |
| ISO Windows 11 officielle | Celle utilisée depuis le chapitre 2 |
| `oscdimg.exe` | Installé avec l'ADK (chapitre 13), dans `Deployment Tools\<arch>\Oscdimg\` |

---

### Étape 1 — Copier le contenu de l'ISO officielle

```powershell
Mount-DiskImage -ImagePath "D:\ISO\Win11_25H2_French.iso"
New-Item -Path "D:\ISO-Deploiement" -ItemType Directory -Force
robocopy E:\ D:\ISO-Deploiement /E /COPY:DAT /R:1 /W:1   # E: = lettre de l'ISO montée
Dismount-DiskImage -ImagePath "D:\ISO\Win11_25H2_French.iso"
```

> [!WARNING] `Copy-Item -Recurse` ne suffit pas pour dupliquer un média d'installation
> `Copy-Item` peut mal recopier certains fichiers système/cachés propres aux médias d'installation Windows — notamment les fichiers de boot EFI (`bootmgfw_EX.efi` et son dossier `boot\EFI_EX`). Symptôme typique : l'ISO reconstruite boote et s'installe normalement jusqu'à la toute fin, puis échoue à la phase "Finalize" avec une erreur `BfspCopyFile` en boucle sur ce fichier, avant de tomber en erreur `0x8007000B`. `robocopy` (`/E` copie tous les sous-dossiers y compris vides, `/COPY:DAT` copie données + attributs + horodatage) est l'outil recommandé pour dupliquer fidèlement un média d'installation Windows.

---

### Étape 2 — Remplacer install.wim par MASTER.wim

```powershell
attrib -r "D:\ISO-Deploiement\sources\install.wim"      # les fichiers copiés depuis une ISO sont en lecture seule
Copy-Item "D:\Images\MASTER.wim" -Destination "D:\ISO-Deploiement\sources\install.wim" -Force
```

> [!DANGER] Vérifier qu'il ne reste pas de fichier de réponse dans l'image
> Vécu sur le lab : le premier déploiement de `PC02` a échoué (« *Échec de l'installation de Windows 11* », `0x80070050`) parce que `MASTER.wim` contenait `Windows\Panther\unattend-original.xml` — copie du fichier qui avait servi à installer `MASTER`. Le Setup des médias 24H2+ refuse de l'écraser. Puis le deuxième essai a échoué sur un dossier `Windows.old` **vide** capturé dans l'image (`0x800700B7`, *CRelocateOS*). Correction et diagnostic : chapitre 14, *Dépanner Sysprep*, pièges n° 4 et 5. **Règle** : avant de distribuer une image, la monter et vérifier sa racine et `Windows\Panther`.

> [!NOTE] Le nom de fichier reste `install.wim`
> Windows Setup cherche spécifiquement `sources\install.wim` — on ne renomme pas le fichier lui-même, seul le **contenu** change (l'image généralisée et personnalisée de `MASTER` à la place de l'image Windows "nue").

---

### Étape 3 — Déposer le fichier de réponse à la racine

```powershell
Copy-Item "D:\Images\autounattend.xml" -Destination "D:\ISO-Deploiement\autounattend.xml"
```

Windows Setup scanne automatiquement la racine des supports amovibles/optiques au démarrage à la recherche d'un fichier nommé **exactement** `autounattend.xml` — s'il le trouve, il l'applique sans rien demander.

---

### Étape 4 — Construire l'ISO bootable avec oscdimg

```cmd
oscdimg -m -o -u2 -udfver102 -bootdata:2#p0,e,bD:\ISO-Deploiement\boot\etfsboot.com#pEF,e,bD:\ISO-Deploiement\efi\microsoft\boot\efisys.bin D:\ISO-Deploiement D:\ISO\MASTER-Deploiement.iso
```

| Option | Rôle |
|--------|------|
| `-m` | Ignore la limite de taille classique d'une ISO (700 Mo) |
| `-o` | Écrase le fichier de sortie s'il existe déjà, sans confirmation |
| `-u2` / `-udfver102` | Système de fichiers UDF, nécessaire pour une image de plus de 2 Go |
| `-bootdata:2#p0,e,b...\etfsboot.com#pEF,e,b...\efisys.bin` | Rend l'ISO bootable en BIOS (`etfsboot.com`) **et** en UEFI (`efisys.bin`) |

> [!TIP] Un vrai zéro clic : supprimer « Press any key to boot from CD or DVD »
> Avec `efisys.bin`, le démarrage UEFI attend une touche : sans elle, le poste passe au périphérique suivant. L'ADK fournit **`efisys_noprompt.bin`** (dossier `Oscdimg` de l'ADK) qui démarre directement — testé sur le lab avec `PC02` :
> ```cmd
> oscdimg -m -o -u2 -udfver102 -bootdata:2#p0,e,bD:\ISO-Deploiement\boot\etfsboot.com#pEF,e,b"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys_noprompt.bin" D:\ISO-Deploiement D:\ISO\MASTER-Deploiement.iso
> ```
> Attention : une ISO qui démarre sans confirmation **efface le disque** de tout PC qui démarre dessus par erreur (`WillWipeDisk`). À étiqueter clairement.

> [!TIP] Chemin complet d'oscdimg si besoin
> Si `oscdimg` n'est pas reconnu directement, utiliser le chemin complet : `"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"` (le sous-dossier d'architecture et la version de l'ADK peuvent varier).

---

### Étape 5 — Déployer sur PC02

```powershell
New-VM -Name "PC02" -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath "D:\VMs\PC02\PC02.vhdx" -NewVHDSizeBytes 64GB -SwitchName "vSwitch-Rennes"
Add-VMDvdDrive -VMName "PC02" -Path "D:\ISO\MASTER-Deploiement.iso"
Set-VMProcessor -VMName "PC02" -Count 2
Set-VMMemory -VMName "PC02" -DynamicMemoryEnabled $false -StartupBytes 6GB
Set-VMKeyProtector -VMName "PC02" -NewLocalKeyProtector
Enable-VMTPM -VMName "PC02"
Set-VMFirmware -VMName "PC02" -FirstBootDevice (Get-VMDvdDrive -VMName "PC02")
Start-VM -Name "PC02"
vmconnect.exe localhost "PC02"
```

> [!WARNING] PC02 a les mêmes exigences que MASTER
> Comme `MASTER` (chapitre 14), `PC02` doit répondre aux prérequis Windows 11 : au moins 2 processeurs virtuels et un TPM activé (`Set-VMKeyProtector` + `Enable-VMTPM`) — sans ça, l'installation peut échouer ou se comporter de façon imprévisible à des étapes tardives (le TPM est notamment sollicité par les vérifications BitLocker pendant Setup). `Set-VMFirmware -FirstBootDevice` force explicitement le démarrage sur le lecteur DVD, plutôt que de compter sur l'ordre par défaut.

> [!WARNING] Mémoire dynamique = échecs aléatoires et difficiles à diagnostiquer
> Si la mémoire dynamique est activée, Windows Setup peut demander de la RAM plus vite que Hyper-V n'arrive à la lui allouer pendant l'application de l'image — l'installation échoue alors avec une erreur `0x800705AA` ("ressources système insuffisantes", visible dans `setuperr.log` comme `CApplyWIM: Failure while applying image... GLE [1450]`), souvent tard dans le processus, sans lien apparent avec l'ISO ou le fichier de réponse. `Set-VMMemory -DynamicMemoryEnabled $false` avec au moins 6 Go statiques évite ce piège.

`PC02` démarre sur l'ISO (disque vierge, rien d'autre à booter), Windows Setup détecte `autounattend.xml` à la racine, partitionne le disque, applique `install.wim` (en réalité `MASTER.wim`), redémarre — et arrive directement sur le bureau, sans aucun écran ni clic intermédiaire.

> [!NOTE] Nom d'ordinateur généré automatiquement
> Grâce à `ComputerName: *` (passe `specialize`, chapitre 13), chaque déploiement génère un nom unique (`FOURNIL-AN4OLJL` sur le lab : préfixe = `RegisteredOrganization`) — plusieurs postes peuvent être déployés depuis la même ISO sans conflit. On le renomme ensuite à la jonction au domaine (`Add-Computer -NewName PC02`). **Ne pas** utiliser `PC-*` : invalide, il fait échouer la passe specialize (chapitre 13).

---

## 3. Déploiement par le réseau : PXE, WDS, MDT, ConfigMgr

### Le principe PXE

```
Poste (carte réseau)            DHCP                       Serveur de déploiement
      │  DHCPDISCOVER (PXEClient) ──►                              │
      │  ◄── adresse IP + « serveur de boot = X, fichier = Y » ────│ (options 66/67 ou proxy DHCP)
      │  TFTP : télécharge le chargeur (wdsmgfw.efi / bootmgfw.efi) ─► │
      │  TFTP : télécharge boot.wim (WinPE)                         │
      │  WinPE démarre, contacte le serveur, applique l'image (SMB) │
```

Avantage : **aucun support physique**, des dizaines de postes en parallèle (multidiffusion). Inconvénients : infrastructure (DHCP, serveur, VLAN, Secure Boot), maintenance.

### WDS en 2026

**Windows Deployment Services** est encore installable sur Windows Server 2025 (`Get-WindowsFeature WDS` → *Available* sur `SRV01`), mais :

| Date | Changement |
|------|-----------|
| Janvier 2026 | Phase 1 du durcissement CVE-2026-0386 (déploiement « mains libres ») |
| **Avril 2026** | **Phase 2** : le fichier de réponse servi par WDS (*hands-free*) **est bloqué par défaut**. Contournement par la valeur `AllowHandsFreeFunctionality = 1`, explicitement non recommandé |
| Prochaine version de Windows Server | Rôle WDS **déprécié** : console, PXE, outils, composants WinPE dédiés |

`boot.wim` de Windows Setup servi tel quel par WDS n'est plus supporté pour plusieurs combinaisons. **Conclusion pour la formation** : on **présente** WDS (culture, parcs existants), on ne monte plus de TP WDS.

### MDT : retiré

**Microsoft Deployment Toolkit** (Lite Touch, `Bootstrap.ini`, `CustomSettings.ini`, séquences de tâches) a été **retiré le 6 janvier 2026** : plus de mises à jour ni de support, téléchargement susceptible de disparaître, intégration ConfigMgr non supportée. Les déploiements existants continuent de fonctionner, sans garantie avec les futures versions de Windows. Les fichiers MDT des sessions précédentes sont archivés dans `Ressources/`.

### Ce qui reste sur site

| Solution | Pour qui |
|----------|----------|
| **Microsoft Configuration Manager (OSD)** | Grandes entreprises déjà équipées : séquences de tâches, PXE, multidiffusion — **non concerné** par le blocage WDS |
| Outils tiers (WAPT/WADS, FOG, SmartDeploy…) | PME qui veulent garder du PXE |
| ISO / clé USB personnalisée (section 2) | Petits volumes, sites distants, lab |

---

## 4. Partitionnement automatisé

Deux façons, vues aux chapitres 13 et 15 :

| Méthode | Où | Quand |
|---------|----|-------|
| `DiskConfiguration` dans la passe **windowsPE** du fichier de réponse | `autounattend.xml` | Installation par Windows Setup (ISO, clé) |
| Script **`diskpart /s`** | WinPE | Application manuelle d'une image, outil de déploiement |

Schéma UEFI/GPT recommandé : **EFI** (FAT32, 100-260 Mo) · **MSR** (16 Mo) · **Windows** (NTFS) · **Récupération** (≥ 1 Go, en fin de disque — créée automatiquement par Setup si on ne la décrit pas).

> [!WARNING] `WillWipeDisk` et `clean` effacent tout
> Un fichier de réponse avec `WillWipeDisk=true` sur une ISO `noprompt` efface le disque **sans rien demander**. Toujours cibler le bon `DiskID` (attention aux postes à deux disques ou avec une clé USB branchée).

---

## 5. Migrer les profils et les données : USMT

Changer de poste (ou réinstaller) sans perdre les documents, le fond d'écran, les lecteurs réseau, les paramètres d'applications : c'est le rôle de **USMT** (*User State Migration Tool*), fourni avec l'ADK (dossier `User State Migration Tool\amd64`).

```
Ancien poste                      Magasin (partage réseau)            Nouveau poste
scanstate.exe ──── USMT.MIG ────► \\SRV01\USMT$\Store\PC01 ────────► loadstate.exe
 (capture)        (compressé)                                         (restaure)
```

```cmd
:: Sur PC01 (administrateur) : capturer le profil de stagiaire uniquement
\\SRV01\USMT$\USMT\scanstate.exe \\SRV01\USMT$\Store\PC01 ^
    /i:\\SRV01\USMT$\USMT\MigDocs.xml /i:\\SRV01\USMT$\USMT\MigApp.xml ^
    /ue:*\* /ui:FOURNIL\stagiaire /o /c /l:\\SRV01\USMT$\scan-PC01.log

:: Sur PC02 joint au domaine : restaurer
\\SRV01\USMT$\USMT\loadstate.exe \\SRV01\USMT$\Store\PC01 ^
    /i:\\SRV01\USMT$\USMT\MigDocs.xml /i:\\SRV01\USMT$\USMT\MigApp.xml ^
    /ue:*\* /ui:FOURNIL\stagiaire /c /l:\\SRV01\USMT$\load-PC02.log
```

| Option | Rôle |
|--------|------|
| `/i:MigDocs.xml` | Documents (recherche « intelligente » de fichiers utilisateur sur **tout** le poste) |
| `/i:MigUser.xml` | Dossiers du profil, plus des types de fichiers sur tout le poste |
| `/i:MigApp.xml` | Paramètres d'applications connues (Office, navigateurs…) |
| `/ue:*\*` puis `/ui:DOMAINE\user` | Exclure tous les profils… sauf celui-ci (l'ordre compte : `/ui` l'emporte) |
| `/o` · `/c` | Écraser un magasin existant · continuer malgré les erreurs non fatales |
| `/listfiles:fichier.txt` | Lister ce qui serait migré — **indispensable pour tester** |
| `/genconfig:config.xml` puis `/config:` | Désactiver des composants précis |

> [!WARNING] Testé sur le lab : les XML fournis ratissent large
> Pour **deux** fichiers de test dans le profil de `stagiaire`, `scanstate` a produit un magasin de **6,9 Go** avec `MigDocs.xml`, **5,8 Go** avec `MigUser.xml`. `/listfiles` a montré pourquoi : `MigDocs.xml` embarque les « documents » de tout le disque (dont `C:\WinPE_amd64`, une ISO de 567 Mo…), et USMT capture aussi par défaut des éléments système — sons de `C:\Windows\Media`, définitions Defender, et **le cache de l'Optimisation de la distribution** (plusieurs Go de mises à jour, dans le profil `NetworkService`).
> Avant une vraie migration : lancer `scanstate` avec `/listfiles`, vider le cache de distribution (`Delete-DeliveryOptimizationCache -Force`), et exclure ce qui ne doit pas partir (`/genconfig` + `/config`, ou un XML personnalisé).

### USMT ou OneDrive ?

| | USMT | OneDrive — *Known Folder Move* (KFM) | Windows Backup for Organizations |
|-|------|--------------------------------------|----------------------------------|
| Données | Documents, bureau, images… vers un magasin | Bureau, Documents, Images **synchronisés en continu** dans OneDrive | Paramètres Windows + liste des applications |
| Paramètres | Oui (XML, MigApp) | Non | Oui (fond d'écran, langues, Wi-Fi…) |
| Prérequis | Partage réseau, admin | Microsoft 365, OneDrive (GPO/Intune) | Postes **joints à Entra ID** |
| Moment | Une opération planifiée | En continu : le nouveau poste retrouve tout à la connexion | Restauration proposée au premier démarrage |

En 2026, la combinaison **OneDrive KFM + Windows Backup for Organizations** rend USMT inutile dans les entreprises 100 % Microsoft 365 / Entra. USMT reste l'outil des parcs **sur site** (AD, partages) et des migrations Windows 10 → 11 par réinstallation.

---

## 6. Le déploiement moderne : Windows Autopilot et Intune

### Le principe

Plus d'image : on **garde le Windows installé en usine** et on le **transforme** en poste d'entreprise au premier démarrage, depuis le cloud.

```
Constructeur / revendeur               Microsoft Entra ID + Intune               Utilisateur
  enregistre le hash matériel ───────►  profil Autopilot attribué au poste
                                                                                  déballe le PC,
                                         ◄──────── le poste s'identifie ─────────  se connecte au Wi-Fi
                                         OOBE personnalisée (logo, pas de choix)
                                         jonction Entra ID + inscription Intune
                                         applications, stratégies, BitLocker,      ───► bureau prêt,
                                         Windows Update (Autopatch)                     données OneDrive
```

| Mode | Usage |
|------|-------|
| **Piloté par l'utilisateur** | Le cas standard : l'utilisateur se connecte avec son compte pro |
| **Pré-provisionnement** (*White Glove*) | Le service informatique ou le revendeur fait la partie « appareil » à l'avance |
| **Auto-déploiement** | Bornes, kiosques, salles de réunion (sans utilisateur) |
| **Autopilot device preparation** | Nouvelle génération (2024+), plus simple, sans enregistrement préalable obligatoire ; en 26H2, ajout de l'*association d'appareil* pour reconnaître les postes de confiance |
| **Réinitialisation Autopilot** | Remettre un poste à zéro (pour un nouvel utilisateur) en gardant son inscription |

Enregistrer un poste existant (le « hash matériel ») :

```powershell
Install-Script Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -OutputFile C:\Temp\autopilot-PC02.csv
# ou, avec les droits sur le tenant : Get-WindowsAutopilotInfo -Online
```

Prérequis : licence Intune (M365 Business Premium, E3/E5), Entra ID, Windows **Pro** ou plus, accès Internet au premier démarrage.

### Traditionnel ou moderne ?

| Critère | Traditionnel (image + AD + GPO) | Moderne (Autopilot + Entra + Intune) |
|---------|----------------------------------|--------------------------------------|
| Image | `MASTER.wim` à maintenir chaque mois | Aucune : Windows d'usine |
| Infrastructure | DC, partages, serveur de déploiement | Cloud Microsoft (abonnement) |
| Où se déploie le poste ? | Sur le réseau de l'entreprise | **N'importe où** avec Internet (télétravail) |
| Intervention IT | Préparation du poste par un technicien | Expédition directe à l'utilisateur possible |
| Applications | Dans l'image ou par GPO/scripts | Intune (Win32, Store, WinGet), à jour à l'installation |
| Pilotes | À injecter dans l'image | Ceux du constructeur, déjà dans le Windows d'usine |
| Coût | Temps humain, serveurs | Licences par utilisateur |
| Limites | Nomades mal servis | Applications métier anciennes, sites sans Internet, PC sans licence OEM Pro |

En pratique, beaucoup d'organisations sont **hybrides** : jonction AD + Entra (*hybrid join*), GPO et Intune ensemble, transition progressive.

---

## Récapitulatif

```
ISO officielle → copiée dans un dossier de travail
  sources\install.wim  remplacé par MASTER.wim (chapitre 15)
  autounattend.xml      déposé à la racine (chapitre 13 — passes windowsPE/specialize/oobeSystem)

oscdimg -m -o -u2 -udfver102 -bootdata:2#p0,e,b...etfsboot.com#pEF,e,b...efisys.bin <source> <iso>
  → ISO bootable BIOS + UEFI

  efisys_noprompt.bin → plus de "Press any key" (vrai zéro clic, mais efface sans prévenir)
  Image sans Windows\Panther\unattend-original.xml (sinon 0x80070050 au déploiement)

PC02 : New-VM (Gen2, vSwitch-Rennes) → Add-VMDvdDrive (ISO) → démarrage
  → zéro clic → bureau directement

Réseau : PXE = DHCP + TFTP + WinPE | WDS : mains libres BLOQUÉ (avril 2026), rôle déprécié
         MDT : RETIRÉ (janvier 2026) | ConfigMgr OSD : supporté
Migration : USMT scanstate/loadstate (/ue:*\* /ui:DOM\user, tester avec /listfiles)
            ou OneDrive KFM + Windows Backup for Organizations (Entra)
Moderne : Autopilot (hash matériel, Entra + Intune, OOBE pilotée par le cloud, pas d'image)
```
