# 05. Pilotes, applications et WinGet

> [!NOTE] Objectif
> Gérer les périphériques et leurs pilotes (magasin de pilotes, `pnputil`), comprendre les différents types d'applications Windows, et installer/mettre à jour/inventorier des logiciels avec **WinGet**, le gestionnaire de paquets intégré à Windows 11.
>
> **Outils :** Gestionnaire de périphériques (`devmgmt.msc`), `pnputil`, `winget`, Paramètres → Applications
> **Commandes à connaître :** `Get-PnpDevice`, `pnputil /enum-drivers`, `winget search/install/upgrade/export/import`, `Get-AppxProvisionedPackage`, `Get-WindowsCapability`

> [!INFO] Fil rouge — Fournil
> Sur `PC01`, on prépare le **socle logiciel standard** du Fournil (7-Zip, Notepad++…) et on l'exporte dans un fichier qui servira à installer les applications des nouveaux postes au déploiement (chapitre 16).

---

## 1. Périphériques et pilotes

Un **pilote** (*driver*) est le logiciel qui permet à Windows de dialoguer avec un matériel. Il tourne le plus souvent en **mode noyau** : un pilote défaillant peut provoquer un écran bleu.

### Le magasin de pilotes (*Driver Store*)

![Magasin de pilotes Windows — FileRepository contient les dossiers des pilotes, par exemple le réseau Hyper-V et Microsoft Print to PDF.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-05-driver-store.svg)

Windows n'installe un pilote **que depuis le magasin**. Ajouter un pilote = le **déposer dans le magasin** (« staging ») ; Windows l'associe ensuite automatiquement à tout périphérique compatible, présent ou futur.

| Origine d'un pilote | Exemple |
|---------------------|---------|
| **En boîte** (fourni avec Windows) | Clavier, stockage standard, réseau Hyper-V |
| **Windows Update** | Pilotes publiés par les constructeurs (catégorie « Mises à jour facultatives ») |
| **Constructeur** (package `.inf` + `.sys` + `.cat`, ou `.exe` d'installation) | Carte graphique, imprimante, station d'accueil |
| **Injecté dans l'image** (DISM, chapitre 15) | Pilote réseau/stockage indispensable au premier démarrage |

> [!WARNING] Signature obligatoire
> Les pilotes 64 bits doivent être **signés** par Microsoft (programme WHCP). Depuis **26H2**, Windows ne fait plus confiance par défaut aux anciens pilotes « *cross-signed* » (signés par l'éditeur avec un certificat tiers). Un vieux pilote d'imprimante ou de dongle peut donc refuser de se charger après la mise à niveau : c'est à vérifier avant de migrer un parc.

### Le Gestionnaire de périphériques — `devmgmt.msc`

| Icône | Signification |
|-------|---------------|
| ⚠️ Triangle jaune | Périphérique en erreur (pilote manquant, conflit) — voir le **code d'erreur** dans Propriétés |
| ⬇️ Flèche grise | Périphérique désactivé |
| « Périphérique inconnu » | Aucun pilote compatible dans le magasin |

Onglet **Pilote** d'un périphérique :
- **Mettre à jour le pilote** — chercher dans le magasin, dans un dossier, ou sur Windows Update
- **Restaurer le pilote** — revenir à la version précédente (si une mise à jour a cassé quelque chose)
- **Désactiver / Désinstaller** — avec la case « Tenter de supprimer le pilote » pour le retirer aussi du magasin

> [!TIP] Afficher les périphériques fantômes
> Menu **Affichage → Afficher les périphériques cachés** : on voit les périphériques déconnectés (anciennes clés USB, cartes réseau d'une VM supprimée…). Utile pour nettoyer un conflit d'IP fixe restée sur une ancienne carte réseau.

### En PowerShell et `pnputil`

```powershell
# Périphériques présents, par classe
Get-PnpDevice -PresentOnly | Group-Object Class | Sort-Object Count -Descending

# Périphériques en erreur (code d'erreur ≠ OK)
Get-PnpDevice -PresentOnly | Where-Object Status -ne 'OK' |
    Select-Object Status, Class, FriendlyName, InstanceId
```

`pnputil` est l'outil en ligne de commande du magasin de pilotes :

```cmd
:: Lister les pilotes tiers (OEMxx.inf) présents dans le magasin
pnputil /enum-drivers

:: Ajouter un pilote au magasin et l'installer sur les périphériques compatibles
pnputil /add-driver C:\Drivers\Reseau\*.inf /subdirs /install

:: Retirer un pilote du magasin (son "nom publié" oemNN.inf, pas le nom d'origine)
pnputil /delete-driver oem3.inf /uninstall

:: Exporter tous les pilotes tiers (avant réinstallation d'un poste !)
pnputil /export-driver * C:\Sauvegarde\Pilotes
```

Extrait réel sur `PC01` :

```
Nom publié :          oem1.inf
Nom d'origine :       voiceclarityep_audio_component.inf
Nom du fournisseur :  Microsoft Corporation
Nom de la classe :    AudioProcessingObject
Version du pilote :   06/16/2026 1.0.4.7057
Nom du signataire :   Microsoft Windows Hardware Compatibility Publisher
```

> [!NOTE] Nom publié vs nom d'origine
> Dans le magasin, un pilote tiers est renommé `oemNN.inf` (« nom publié »). C'est ce nom que demandent `/delete-driver` et le Gestionnaire de périphériques ; le nom d'origine (`voiceclarityep_audio_component.inf`) sert à le reconnaître.

---

## 2. Les types d'applications

| Type | Format | Installation | Particularité |
|------|--------|--------------|---------------|
| **Win32 « classique »** | `.exe`, `.msi` | Assistant, ou silencieuse (`msiexec /i x.msi /qn`) | Écrit dans `Program Files` et le registre — la majorité des logiciels métier |
| **Application empaquetée** | `.msix`, `.appx` | Store, `Add-AppxPackage`, WinGet | Isolée, désinstallation propre, mise à jour par le Store |
| **Application du Store** | Store | Microsoft Store, WinGet (source `msstore`) | Le Store pour Entreprises a été retiré : en entreprise on passe par **WinGet/Intune** |
| **Application web progressive** (PWA) | Site installé depuis Edge | Edge | Ex. : Outlook web épinglé |

### Applications provisionnées

Une image Windows contient des applications **provisionnées** : elles sont installées automatiquement pour **chaque nouvel utilisateur** qui ouvre une session.

```powershell
# Applications provisionnées dans l'image (installées pour tout nouveau profil)
Get-AppxProvisionedPackage -Online | Select-Object DisplayName, Version

# Applications installées pour l'utilisateur courant
Get-AppxPackage | Select-Object Name, Version

# Retirer une application de l'image (ne touche pas les profils existants)
Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq "Microsoft.BingNews" |
    Remove-AppxProvisionedPackage -Online
```

Sur `PC01` (26H2), on trouve une quarantaine d'applications provisionnées, dont `Clipchamp.Clipchamp`, `Microsoft.BingNews`, `Microsoft.OutlookForWindows`, `Microsoft.Windows.DevHome`, `MSTeams`, `MicrosoftCorporationII.QuickAssist`…

> [!TIP] Nouveauté 26H2 (Enterprise/Education)
> Une stratégie de groupe permet désormais de **supprimer des applications préinstallées** sans script : *Configuration ordinateur → Modèles d'administration → Composants Windows → Déploiement de package Appx → « Supprimez du système les packages par défaut du Microsoft Store »*. Une liste à cocher propose les applications courantes, et une liste dynamique accepte d'autres noms de famille de packages (ex. `Microsoft.BingNews_8wekyb3d8bbwe`). La stratégie est visible dans le `gpedit.msc` d'un Pro, mais elle n'est **effective que sur Enterprise/Education**. Sur Pro, on reste sur `Remove-AppxProvisionedPackage` (dans l'image, chapitre 15, ou en mode audit, chapitre 14).

### Fonctionnalités facultatives et « Features on Demand »

Certaines briques de Windows sont des **capacités** téléchargées à la demande :

```powershell
# Capacités (Features on Demand) : OpenSSH, RSAT, langues, outils...
Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH*" | Select-Object Name, State
Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0"

# Fonctionnalités Windows "historiques" (Hyper-V, .NET 3.5, Sysmon...)
Get-WindowsOptionalFeature -Online | Where-Object State -eq Enabled | Select-Object FeatureName
```

Quelques changements récents, constatés sur la 26H2 :

| Composant | Statut |
|-----------|--------|
| **WMIC** | **Supprimé** (plus réinstallable) → `Get-CimInstance` |
| **PowerShell 2.0** | **Supprimé** |
| **VBScript** | Capacité encore installée, en cours de dépréciation → PowerShell |
| **WordPad** | Supprimé (24H2) |
| **Sysmon** | **Nouveau** : fonctionnalité intégrée (désactivée par défaut) — chapitre 20 |

---

## 3. WinGet — le gestionnaire de paquets de Windows

**WinGet** (`winget.exe`) installe, met à jour et désinstalle des logiciels **en ligne de commande**, à partir de dépôts de « manifestes » (description du paquet, URL de l'installeur, empreinte SHA256, arguments silencieux).

Il est fourni par l'application **App Installer** (`Microsoft.DesktopAppInstaller`), présente et mise à jour par le Store sur Windows 11.

![Installation avec WinGet — Pour installer 7-Zip, WinGet lit le manifeste, télécharge et vérifie l’installeur, puis l’exécute silencieusement.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-05-installation-winget.svg)

| Source | Contenu |
|--------|---------|
| `winget` | Dépôt communautaire (plusieurs dizaines de milliers de logiciels Win32/MSIX) |
| `msstore` | Applications du Microsoft Store |
| Source privée (REST) | Dépôt interne d'une entreprise |

### Commandes essentielles

| Commande | Rôle |
|----------|------|
| `winget search 7zip` | Chercher un paquet |
| `winget show --id 7zip.7zip` | Détails : version, éditeur, URL, licence |
| `winget install --id 7zip.7zip -e` | Installer (`-e` = identifiant exact) |
| `winget list` | Logiciels installés (y compris ceux non installés par WinGet) |
| `winget upgrade` | Lister les mises à jour disponibles |
| `winget upgrade --all` | Tout mettre à jour |
| `winget uninstall --id 7zip.7zip` | Désinstaller |
| `winget pin add --id X` | Bloquer la mise à jour d'un logiciel |
| `winget export -o apps.json` | Exporter la liste des logiciels |
| `winget import -i apps.json` | Réinstaller une liste sur un autre poste |

Options utiles en administration :

```powershell
winget install --id 7zip.7zip -e `
    --silent `                       # aucune fenêtre
    --scope machine `                # pour tous les utilisateurs (Program Files)
    --accept-package-agreements `    # pas de question sur la licence
    --accept-source-agreements       # pas de question sur la source
```

> [!WARNING] Toujours utiliser l'identifiant exact
> `winget install 7zip` cherche par nom : sur le lab, la recherche renvoie aussi `mcmilk.7zip-zstd`, `ozone10.7zip.Dark`, `7zip.7zr`… Avec `--id 7zip.7zip -e`, on installe exactement le paquet voulu.

### Résultat réel sur PC01

```
> winget upgrade
Microsoft Edge WebView2 Runtime  Microsoft.EdgeWebView2Runtime  152.0.4191.66     157.0.4341.42
Microsoft OneDrive               Microsoft.OneDrive             25.087.0506.0001  26.183.0920.0005
Microsoft Teams                  Microsoft.Teams                1.0.0.1           26276.513.5241.9675
App Installer                    Microsoft.AppInstaller         1.26.509.0        1.29.380
Terminal Windows                 Microsoft.WindowsTerminal      1.24.11911.0      1.25.2733.0
...
8 upgrades available.
```

Un poste tout juste installé depuis l'ISO a déjà **8 logiciels à mettre à jour** — y compris WinGet lui-même (App Installer 1.26 → 1.29). C'est tout l'intérêt d'un `winget upgrade --all` dans la préparation d'un master (chapitre 14) et dans la maintenance (chapitre 21).

### Export / import : le socle logiciel standard

```powershell
winget export -o C:\Temp\socle-fournil.json      # sur le poste de référence
winget import -i C:\Temp\socle-fournil.json --accept-package-agreements   # sur un poste neuf
```

Le fichier JSON ne contient que les **identifiants** (pas les installeurs) : il est léger, versionnable, lisible.

### WinGet en entreprise

| Besoin | Solution |
|--------|----------|
| Scripter WinGet en PowerShell (objets, pas du texte) | Module **`Microsoft.WinGet.Client`** : `Get-WinGetPackage`, `Install-WinGetPackage` |
| Décrire l'état complet d'un poste (logiciels + paramètres) | **`winget configure`** avec un fichier YAML (configuration DSC) |
| Interdire des sources, désactiver WinGet | GPO **Composants Windows → Programme d'installation d'application** (ADMX App Installer) |
| Déployer à grande échelle | Intune (apps WinGet/Store intégrées), ConfigMgr, scripts de démarrage GPO |

> [!WARNING] WinGet et le compte SYSTEM
> `winget.exe` est un alias d'application **par utilisateur**. Lancé par une tâche planifiée en SYSTEM ou par certains outils de déploiement, il n'est pas trouvé : il faut appeler l'exécutable par son chemin complet (`C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*\winget.exe`) ou utiliser le module `Microsoft.WinGet.Client`.

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> **Pilotes**
> - Magasin de pilotes (DriverStore) → Windows n'installe que depuis le magasin
> - `devmgmt.msc` : mettre à jour / restaurer / désinstaller ; Affichage → périphériques cachés
> - `Get-PnpDevice` · Where Status -ne OK : périphériques en erreur
> - `pnputil /enum-drivers` · /add-driver `x.inf` /install · /delete-driver `oemNN.inf` · /export-driver *
> - **26H2** : fin de la confiance par défaut pour les pilotes cross-signed
>
> **Applications**
> - Win32 (exe/msi) · MSIX/Appx · Store · PWA
> - `Get-AppxProvisionedPackage -Online` : apps installées pour chaque nouveau profil
> - `Get-WindowsCapability` / `Add-WindowsCapability` → Features on Demand (OpenSSH, RSAT…)
> - WMIC et PowerShell 2.0 supprimés
>
> **WinGet**
> - `winget search` · show · install --id X -e --silent --scope machine
> - `winget list` · upgrade [--all] · uninstall · pin
> - `winget export -o socle.json` → `winget import -i socle.json`
> - **En SYSTEM** : chemin complet ou module Microsoft.WinGet.Client
