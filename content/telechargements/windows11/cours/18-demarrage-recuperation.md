# 19. Démarrage et récupération

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

![Séquence de démarrage Windows 11 — Le PC passe de l’UEFI et de Secure Boot au gestionnaire de démarrage, au chargeur Windows, au noyau puis à la session utilisateur.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-19-sequence-demarrage.svg)

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
![w11-06-demarrage-recuperation](https://cours.kaya.ovh/windows11/assets/captures/w11-06-demarrage-recuperation.png)
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

### bcdedit — Gestion avancée du BCD *(approfondissement)*

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

![w11-06-demarrage-recuperation-2](https://cours.kaya.ovh/windows11/assets/captures/w11-06-demarrage-recuperation-2.png)

![Options avancées de WinRE — Les options WinRE servent à restaurer le système, réparer le démarrage, utiliser CMD ou retirer une mise à jour.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-19-options-winre.svg)

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
> `bootrec /fixmbr` et `/fixboot` concernent le **MBR/BIOS**. Sur un Windows 11 (GPT/UEFI), `bootrec /fixboot` répond souvent « *Accès refusé* » : c'est normal, il ne sait pas écrire dans la partition EFI. La commande qui répare réellement le démarrage UEFI est **`bcdboot`** (c'est aussi elle qui rend démarrable une image appliquée à la main, chapitre 15, approfondissement). `bootrec /rebuildbcd` reste utile pour rechercher des installations.

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

![w11-06-demarrage-recuperation-1](https://cours.kaya.ovh/windows11/assets/captures/w11-06-demarrage-recuperation-1.png)

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

![w11-19-parametres-recuperation](https://cours.kaya.ovh/windows11/assets/captures/w11-19-parametres-recuperation.png)

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

> [!summary] L'essentiel du chapitre
> **Séquence de boot UEFI**
> - UEFI → Secure Boot → `bootmgfw.efi` → `winload.efi` → `ntoskrnl.exe` → `explorer.exe`
>
> **Outils de configuration du boot**
> - `msconfig` : GUI : mode sans échec, services, délai de boot
> - `bcdedit` : CLI : modifier le BCD (timeout, entrées, safeboot)
>
> **Mode sans échec**
> - `msconfig` → Démarrage → Démarrage sécurisé
> - F8 (réactiver avec `bcdedit /set bootmenupolicy legacy`)
>
> **WinRE — Environnement de récupération**
> - **Accès** : Shift+Redémarrer · `shutdown /r /o /t 0`
> - **Outils** : Réparation du démarrage, Restauration système, Point-in-time restore, Désinstaller les MAJ, CMD
> - **UEFI** : `bcdboot C:\Windows /s S: /f UEFI` (`bootrec /fixboot` = MBR, "Accès refusé" sur GPT)
> - **Hors ligne** : `sfc /offbootdir=C:\ /offwindir=C:\Windows` · `DISM /Image:C:\ /RestoreHealth /Source:…`
>
> **Points de restauration**
> - **Créer** : `Checkpoint-Computer` · Protection du système
> - **Lister** : `Get-ComputerRestorePoint`
> - **Restaurer** : `rstrui.exe` · `Restore-Computer`
>
> **Récupération 2026**
> - Réinstaller maintenant (via Windows Update, garde tout) · Réinitialiser ce PC · Revenir en arrière (10 j)
> - Point-in-time restore (instantanés 24 h, tout le volume) · Quick Machine Recovery (incidents de masse)
