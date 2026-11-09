---
title: "18 — Démarrage et récupération"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/18-demarrage-recuperation"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://kayasam.github.io/windows11/windows11/18-demarrage-recuperation/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://kayasam.github.io/windows11/windows11/18-demarrage-recuperation/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://kayasam.github.io/windows11/telechargements/windows11/cours/18-demarrage-recuperation.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Comprendre la séquence de démarrage UEFI, configurer le démarrage (`msconfig`, `bcdedit`), réparer un démarrage cassé (`bcdboot`), utiliser WinRE, et connaître **toute la palette de récupération 2026** : points de restauration, *point-in-time restore*, réinstallation via Windows Update, réinitialisation, Quick Machine Recovery.
>
> **Outils :** `msconfig`, `bcdedit`, `bcdboot`, `reagentc`, WinRE, `rstrui.exe`, Paramètres → Récupération
> **Commandes à connaître :** `bcdedit /enum`, `bcdboot`, `reagentc /info`, `shutdown /r /o`, `sfc`, `DISM /RestoreHealth`, `Checkpoint-Computer`

> [!INFO] Fil rouge — Fournil
> On casse volontairement le démarrage de `PC02` (checkpoint Hyper-V avant !) puis on le répare depuis WinRE.

## Choisir la bonne arme

| Situation | Outil, du plus doux au plus radical |
|-----------|-------------------------------------|
| Un pilote/logiciel récent pose problème, Windows démarre | Désinstaller / restaurer le pilote → **point de restauration** (`rstrui`) |
| Une mise à jour casse le poste | **Désinstaller la mise à jour** (Paramètres ou WinRE) → **point-in-time restore** |
| Fichiers système corrompus | `sfc /scannow` → `DISM /Online /Cleanup-Image /RestoreHealth` → **Réinstaller maintenant** (via Windows Update, garde tout) |
| Windows ne démarre plus | WinRE : Réparation du démarrage → `bcdboot` → mode sans échec |
| Le poste est « pourri » | **Réinitialiser ce PC** (conserver ou non les fichiers) → redéploiement (chapitre 16) |
| Incident massif (mise à jour défectueuse sur tout le parc) | **Quick Machine Recovery** (WinRE + Windows Update, piloté par Microsoft / Intune) |

---

## Processus de démarrage Windows 11

La séquence de démarrage d'un système UEFI/GPT est la suivante :

```
Mise sous tension
      │
      ▼
 Firmware UEFI
 (POST + autotest matériel)
      │
      ▼
 Secure Boot
 (vérification signatures bootloader)
      │
      ▼
 Windows Boot Manager
 (bootmgfw.efi — partition EFI)
      │
      ▼
 Windows Boot Loader
 (winload.efi)
 ├── Charge le noyau (ntoskrnl.exe)
 ├── Charge les drivers de démarrage
 └── Initialise le HAL (couche d'abstraction matérielle)
      │
      ▼
 Noyau Windows (ntoskrnl.exe)
 ├── Session Manager (smss.exe)
 ├── Processus système (wininit.exe, lsass.exe, services.exe)
 └── Chargement des services
      │
      ▼
 Winlogon → Bureau (explorer.exe)
```

### Fichiers clés

| Fichier | Emplacement | Rôle |
|---------|-------------|------|
| `bootmgfw.efi` | Partition EFI (`\EFI\Microsoft\Boot\`) | Windows Boot Manager (UEFI) |
| `BCD` | Partition EFI | Base de données de configuration du boot |
| `winload.efi` | `C:\Windows\System32\` | Chargeur du noyau Windows (UEFI) |
| `ntoskrnl.exe` | `C:\Windows\System32\` | Noyau Windows |
| `hal.dll` | `C:\Windows\System32\` | Hardware Abstraction Layer |
| `smss.exe` | `C:\Windows\System32\` | Session Manager (premier processus utilisateur) |

> [!TIP] BCD vs boot.ini
> Avant Vista/7, la configuration du boot était dans `C:\boot.ini` (fichier texte). Depuis Vista, c'est la **BCD** (Boot Configuration Data), une base de données binaire stockée dans la partition EFI et gérée avec `bcdedit`.

---

## Configuration du démarrage

### msconfig — Configuration du système
![w11-06-demarrage-recuperation](https://kayasam.github.io/windows11/assets/captures/w11-06-demarrage-recuperation.png)
`msconfig` est l'outil graphique pour configurer les options de démarrage courantes.

**Accès :** `Win + R` → `msconfig`

**Onglets :**

| Onglet | Contenu |
|--------|---------|
| **Général** | Mode de démarrage (Normal, Diagnostic, Sélectif) |
| **Démarrer** | Entrées de boot, options avancées (nombre de processeurs, mémoire max) |
| **Services** | Activer/désactiver les services au démarrage |
| **Démarrage** | Lien vers le Gestionnaire des tâches → Applications de démarrage |
| **Outils** | Raccourcis vers les outils système (eventvwr, regedit, cmd...) |

#### Options de démarrage (onglet Démarrer)

| Option | Description |
|--------|-------------|
| **Démarrage sécurisé → Minimal** | Mode sans échec sans réseau (pilotes de base uniquement) |
| **Démarrage sécurisé → Autre environnement** | Mode sans échec avec invite de commandes (sans GUI) |
| **Démarrage sécurisé → Réparer Active Directory** | Mode sans échec pour réparer une base AD corrompue (serveurs) |
| **Démarrage sécurisé → Réseau** | Mode sans échec avec pilotes réseau |
| **Ne pas démarrer la GUI** | Démarre les services sans charger l'interface graphique (dépannage avancé) |
| **Journaliser le démarrage** | Crée `C:\Windows\ntbtlog.txt` listant tous les drivers chargés |
| **Vidéo de base** | Force le pilote vidéo générique (résolution minimale) |
| **Infos de démarrage du SE** | Affiche les drivers chargés à l'écran pendant le boot |
| **Rendre permanents tous les paramètres** | Les options cochées restent actives après redémarrage sans repasser par msconfig |

> [!WARNING] msconfig vs services.msc
> Désactiver un service dans `msconfig` → onglet Services est équivalent à le passer en "Désactivé" dans `services.msc`. Ne pas désactiver les services Microsoft essentiels.

### bcdedit — Gestion avancée du BCD

`bcdedit` est l'outil en ligne de commande pour modifier la BCD. À utiliser depuis un terminal **administrateur**.

> [!WARNING] Erreur "Le périphérique système demandé est introuvable"
> `bcdedit` nécessite un terminal **élevé** (Run as Administrator). Un terminal PowerShell ou CMD ouvert normalement retourne cette erreur même si le compte est administrateur. Vérifier avec :
> ```powershell
> ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
> ```
> Si le résultat est `False` : fermer le terminal et le relancer via **clic droit → Exécuter en tant qu'administrateur**.

```cmd
# Afficher toutes les entrées de boot
bcdedit /enum all

# Afficher uniquement les entrées actives
bcdedit

# Modifier le délai d'affichage du menu de boot (en secondes)
bcdedit /timeout 10

# Modifier la description d'une entrée
bcdedit /set {current} description "Windows 11 Pro - Fournil"

# Ajouter le mode sans échec comme entrée permanente
bcdedit /copy {current} /d "Mode sans echec"
# Noter le GUID retourné, ex : {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
bcdedit /set {GUID} safeboot minimal

# Supprimer une entrée
bcdedit /delete {GUID}
```

> [!WARNING] bcdedit est puissant et risqué
> Une modification incorrecte du BCD peut rendre Windows non démarrable. Toujours noter l'état actuel avant modification et créer un checkpoint Hyper-V (en lab) ou une sauvegarde (en production).

---

## Mode sans échec

Le **mode sans échec** (Safe Mode) démarre Windows avec un ensemble minimal de pilotes et services — sans réseau, sans interface graphique complète, sans la plupart des services tiers.

### Accès au mode sans échec

**Méthode 1 — Depuis Windows (système fonctionnel) :**
- `msconfig` → Démarrage → cocher "Démarrage sécurisé" → redémarrer
- Ou : Paramètres → Système → Récupération → Démarrage avancé → Redémarrer maintenant

**Méthode 2 — Interruption du démarrage :**
- Éteindre la machine 3 fois pendant le démarrage → Windows propose automatiquement les options de récupération

**Méthode 3 — Touche F8 (désactivée par défaut sur Windows 11) :**
```cmd
# Réactiver F8 au démarrage
bcdedit /set {current} bootmenupolicy legacy
```

### Variantes du mode sans échec

| Mode | Description |
|------|-------------|
| **Sans échec** | Minimal : pilotes de base uniquement |
| **Sans échec avec réseau** | + pilotes réseau (utile pour télécharger des outils de réparation) |
| **Sans échec avec invite de commandes** | Sans interface graphique, terminal uniquement |

---

## Environnement de récupération Windows (WinRE)

Le **WinRE** (Windows Recovery Environment) est un environnement de récupération miniature stocké sur la partition Recovery (≈ 650 Mo). Il démarre automatiquement après plusieurs échecs de démarrage, ou peut être lancé manuellement.

**Accès manuel :**
- Menu Démarrer ou écran de connexion → bouton d'alimentation → maintenir **Shift** → **Redémarrer**

### Options disponibles dans WinRE

![w11-06-demarrage-recuperation-2](https://kayasam.github.io/windows11/assets/captures/w11-06-demarrage-recuperation-2.png)

```
Options avancées
├── Restauration du système       ← revenir à un point de restauration
├── Point-in-time restore          ← revenir à l'état complet d'il y a quelques heures (2026)
├── Récupération de l'image système ← sauvegarde « Windows 7 » (héritée, rarement utilisée)
├── Réparation du démarrage       ← répare automatiquement les problèmes de boot
├── Invite de commandes           ← accès CMD (bootrec, sfc, diskpart...)
├── Paramètres de démarrage       ← redémarrer en mode sans échec
└── Désinstaller les mises à jour ← supprimer la dernière mise à jour de qualité/fonctionnalité
```

### Commandes de réparation depuis WinRE

```cmd
:: 1) Repérer les lettres : dans WinRE, Windows n'est pas forcément en C:
diskpart
  list volume          ← repérer le volume NTFS "Windows" et la partition FAT32 (EFI, ~200 Mo)
  select volume 3
  assign letter=S      ← donner une lettre à la partition EFI
  exit

:: 2) Recréer les fichiers de démarrage UEFI et le BCD (méthode moderne, GPT)
bcdboot C:\Windows /s S: /f UEFI

:: 3) Vérifier les fichiers système DU WINDOWS INSTALLÉ (et non de WinRE)
sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows

:: 4) Réparer le magasin de composants hors ligne (source = ISO de même build, montée en D:)
DISM /Image:C:\ /Cleanup-Image /RestoreHealth /Source:D:\sources\install.wim:6 /LimitAccess
```

> [!WARNING] `bootrec` sur un disque GPT/UEFI
> `bootrec /fixmbr` et `/fixboot` concernent le **MBR/BIOS**. Sur un Windows 11 (GPT/UEFI), `bootrec /fixboot` répond souvent « *Accès refusé* » : c'est normal, il ne sait pas écrire dans la partition EFI. La commande qui répare réellement le démarrage UEFI est **`bcdboot`** (c'est elle qu'on a utilisée pour rendre `PC03` démarrable au chapitre 15). `bootrec /rebuildbcd` reste utile pour rechercher des installations.

> [!WARNING] `/Online` n'a pas de sens dans WinRE
> `sfc /scannow` et `DISM /Online` sans options vérifient… WinRE lui-même. Depuis WinRE, toujours cibler l'installation hors ligne (`/offwindir`, `/Image:`). La v1 de ce cours contenait l'erreur.

---

## Points de restauration système

Les **points de restauration** permettent de revenir à un état antérieur du système sans affecter les fichiers personnels. Ils sauvegardent : le registre, les pilotes, certains fichiers système.

> [!NOTE] Limites des points de restauration
> Les points de restauration **ne sauvegardent pas** les fichiers personnels (documents, images...). Pour une sauvegarde complète, utiliser la Sauvegarde Windows ou un outil tiers.

### Activer la protection du système

La protection est **désactivée par défaut sur les VM** (et souvent sur les installations récentes de Windows 11). Il faut l'activer manuellement avant de pouvoir créer des points de restauration.

Vérifier et activer via :
**Clic droit sur Démarrer → Système → Protection du système** (onglet dans les Propriétés système)

![w11-06-demarrage-recuperation-1](https://kayasam.github.io/windows11/assets/captures/w11-06-demarrage-recuperation-1.png)

Ou en PowerShell :
```powershell
# Vérifier l'état de la protection
Get-ComputerRestorePoint

# Activer la protection sur C:
Enable-ComputerRestore -Drive "C:\"

# Créer un point de restauration manuellement
Checkpoint-Computer -Description "Avant-installation-logiciel" -RestorePointType "MODIFY_SETTINGS"
```

### Restaurer depuis un point de restauration

**Graphique :** `rstrui.exe` → choisir un point → Suivant → Terminer → redémarrage

**Depuis WinRE :** Options avancées → Restauration du système (utile si Windows ne démarre plus)

```powershell
# Lister les points de restauration disponibles
Get-ComputerRestorePoint | Select-Object SequenceNumber, Description, CreationTime

# Restaurer vers un point (nécessite un redémarrage)
Restore-Computer -RestorePoint <SequenceNumber> -Confirm:$false
```

---

## Récupérer sans tout réinstaller (Paramètres → Système → Récupération)

![w11-18-parametres-recuperation](https://kayasam.github.io/windows11/assets/captures/w11-18-parametres-recuperation.png)

*Page Récupération d'un poste 26H2 déployé (`PC03`).*

| Option | Ce qu'elle fait | Données |
|--------|-----------------|---------|
| **Résoudre les problèmes sans réinitialiser** | Lance l'application *Obtenir de l'aide* (remplaçante des anciens dépanneurs MSDT) | Conservées |
| **Résoudre les problèmes à l'aide de Windows Update → Réinstaller maintenant** | Télécharge et **réinstalle la version actuelle** de Windows par-dessus elle-même | Applications, fichiers, paramètres **conservés** |
| **Réinitialiser ce PC** | Réinstalle Windows, depuis le cloud ou le disque local | Au choix : conserver les fichiers personnels (applications perdues) ou tout supprimer |
| **Revenir en arrière** | Retour à la version précédente (10 jours après une mise à niveau) | Conservées |
| **Démarrage avancé** | Redémarre dans WinRE (= `shutdown /r /o /t 0`) | — |

### Point-in-time restore (GA juin 2026)

Nouveauté majeure : Windows prend automatiquement des **instantanés complets du poste** (système, applications, paramètres **et fichiers**), par défaut toutes les 24 h, conservés jusqu'à 72 h. Depuis WinRE → **Dépannage → Point-in-time restore**, on revient à l'état d'hier en quelques minutes — idéal après une mise à jour ou un pilote qui empêche le démarrage.

| | Point de restauration système | Point-in-time restore |
|-|-------------------------------|-----------------------|
| Contenu | Registre, pilotes, fichiers système | **Tout** le volume, y compris fichiers utilisateur |
| Fréquence | Avant installations / manuel | Automatique (24 h par défaut) |
| Rétention | Selon l'espace alloué | Courte (72 h) |
| Restauration | Windows ou WinRE | WinRE (clé BitLocker éventuellement demandée) |
| Postes gérés | — | **Désactivé par défaut** avant 26H2, à activer par Intune (CSP *Recovery*) |

### Quick Machine Recovery (QMR)

Quand une mise à jour défectueuse empêche **des milliers** de postes de démarrer (cf. l'incident CrowdStrike de juillet 2024), **Quick Machine Recovery** permet à Windows de démarrer en WinRE, de se connecter au réseau et de **télécharger un correctif** depuis Windows Update, sans intervention physique. Activé par défaut sur Home ; configurable par Intune sur les éditions professionnelles, avec une variante qui permet à l'admin de redémarrer et restaurer les postes à distance.

---

## Récapitulatif

```
Séquence de boot UEFI
  UEFI → Secure Boot → bootmgfw.efi → winload.efi → ntoskrnl.exe → explorer.exe

Outils de configuration du boot
  msconfig   → GUI : mode sans échec, services, délai de boot
  bcdedit    → CLI : modifier le BCD (timeout, entrées, safeboot)

Mode sans échec
  msconfig → Démarrage → Démarrage sécurisé
  F8 (réactiver avec bcdedit /set bootmenupolicy legacy)

WinRE — Environnement de récupération
  Accès : Shift+Redémarrer | shutdown /r /o /t 0
  Outils : Réparation du démarrage, Restauration système, Point-in-time restore, Désinstaller les MAJ, CMD
  UEFI : bcdboot C:\Windows /s S: /f UEFI (bootrec /fixboot = MBR, "Accès refusé" sur GPT)
  Hors ligne : sfc /offbootdir=C:\ /offwindir=C:\Windows | DISM /Image:C:\ /RestoreHealth /Source:…

Points de restauration
  Créer  : Checkpoint-Computer | Protection du système
  Lister : Get-ComputerRestorePoint
  Restaurer : rstrui.exe | Restore-Computer

Récupération 2026
  Réinstaller maintenant (via Windows Update, garde tout) | Réinitialiser ce PC | Revenir en arrière (10 j)
  Point-in-time restore (instantanés 24 h, tout le volume) | Quick Machine Recovery (incidents de masse)
```
