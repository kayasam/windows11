---
title: "02. Installation, mise à niveau et comptes"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/02-installation"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/02-installation/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/02-installation/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/02-installation.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Connaître les prérequis matériels de Windows 11, choisir l'édition, réaliser une installation propre, mettre à niveau un poste existant, et comprendre les trois types de comptes (local, Microsoft, professionnel).
>
> **Outils :** ISO Windows 11, Gestionnaire Hyper-V, `setup.exe`
> **Commandes à connaître :** `Shift+F10`, `setup.exe /auto upgrade`, `dsregcmd /status`, `Get-LocalUser`

> [!INFO] Fil rouge — Fournil
> On installe `PC01` (Windows 11 Pro 26H2) dans la VM créée au chapitre 01.

---

## Configuration requise

Windows 11 impose des **exigences matérielles strictes** par rapport à Windows 10. Ces prérequis visent à garantir un socle de sécurité minimal (TPM, Secure Boot, VBS).

| Composant | Minimum requis |
|-----------|---------------|
| Processeur | 1 GHz, 2 cœurs minimum, 64 bits, compatible |
| RAM | 4 Go |
| Stockage | 64 Go |
| Firmware | UEFI avec **Secure Boot** |
| TPM | **Version 2.0** |
| Carte graphique | DirectX 12 avec pilote WDDM 2.0 |
| Écran | 720p, 9 pouces minimum |
| Connexion | Compte Microsoft requis pour l'édition Home (contournable) |

### Pourquoi ces exigences ?

```
Windows 10                              Windows 11
┌─────────────────────┐                 ┌─────────────────────┐
│ Sécurité logicielle │                 │ Sécurité matérielle │
│ (antivirus, pare-feu)│                │ (TPM + Secure Boot) │
│                     │                 │         +           │
│ BIOS ou UEFI        │                 │ Sécurité logicielle │
│ TPM optionnel       │                 │                     │
│ Secure Boot optionnel│                │ UEFI obligatoire    │
└─────────────────────┘                 └─────────────────────┘
```

| Technologie | Rôle |
|-------------|------|
| **TPM 2.0** | Puce de sécurité qui stocke les clés de chiffrement (BitLocker), les certificats et les mesures d'intégrité du boot |
| **Secure Boot** | Vérifie que chaque composant chargé au démarrage (bootloader, drivers) est signé numériquement — empêche les rootkits |
| **VBS** | Virtualisation-Based Security — isole les processus critiques du noyau dans un environnement protégé par l'hyperviseur |

> [!TIP] En VM Hyper-V
> La Génération 2 fournit le TPM virtuel et le Secure Boot. C'est pour cela qu'on a activé le TPM dans le chapitre 1 avec `Enable-VMTPM`.

---

## Les éditions de Windows 11

| Édition | Public cible | Fonctionnalités clés |
|---------|-------------|---------------------|
| **Home** | Grand public | Windows Hello, Device Encryption, Snap Layouts, DirectStorage |
| **Pro** | Professionnels, PME | Home + **Hyper-V**, **BitLocker**, **Bureau à distance (hôte)**, **GPO locale**, jonction AD / Entra ID, Windows Update client policies, App Control for Business |
| **Enterprise** | Grandes entreprises (abonnement E3/E5) | Pro + Credential Guard activé par défaut, **Hotpatch**, Windows Autopatch, suppression d'applis préinstallées par GPO, 36 mois de support |
| **Education** | Écoles, universités | ≈ Enterprise avec licences éducation |

### Ce qui nous intéresse pour cette formation

| Fonctionnalité | Home | Pro | Enterprise |
|----------------|------|-----|------------|
| Hyper-V | ❌ | ✅ | ✅ |
| BitLocker | ❌ | ✅ | ✅ |
| Bureau à distance (hôte) | ❌ | ✅ | ✅ |
| Jonction domaine AD | ❌ | ✅ | ✅ |
| Group Policy (gpedit.msc) | ❌ | ✅ | ✅ |
| App Control for Business / AppLocker | ❌ | ✅ (testé au TP 09) | ✅ |
| Hotpatch (mises à jour sans redémarrage) | ❌ | ❌ | ✅ |
| RAM max | 128 Go | 2 To | 6 To |

> [!NOTE] AppLocker sur Pro
> Longtemps réservé à Enterprise, AppLocker s'applique aussi sur Pro depuis Windows 10 2004 — la documentation Microsoft reste ambiguë, c'est pourquoi le TP 09 le vérifie en vrai sur `PC01`. Son successeur, **App Control for Business** (ex-WDAC), est officiellement supporté sur Pro.

> [!WARNING] Windows 11 Home est insuffisant pour un environnement professionnel
> Pas de Hyper-V, pas de BitLocker, pas de jonction au domaine, pas de GPO. Pour cette formation et en entreprise, il faut au minimum **Windows 11 Pro**.

---

## Obtenir l'ISO Windows 11

Trois méthodes officielles depuis le site Microsoft :

| Méthode | Usage |
|---------|-------|
| **Assistant d'installation** | Mise à niveau d'un Windows 10/11 existant |
| **Outil de création de support** | Créer une clé USB bootable |
| **Téléchargement ISO** | Télécharger le fichier ISO directement (pour VM ou gravure) |

Pour le lab, on utilise le **téléchargement ISO direct** qu'on monte ensuite dans Hyper-V.

---

## Installation propre

### Lancer l'installation

1. Démarrer la VM (ou le PC) sur l'ISO
2. Appuyer sur une touche quand le message "Press any key to boot from CD or DVD" apparaît

### Écrans de l'installation

#### 1. Langue et clavier

- Langue : **Français**
- Format horaire : **Français (France)**
- Clavier : **Français** (ou Français AZERTY)

#### 2. Installer maintenant

Cliquer sur **Installer maintenant**. L'écran "Le programme d'installation démarre" apparaît.

#### 3. Clé de produit

- En entreprise : entrer la clé de licence volume
- En lab : cliquer sur **"Je n'ai pas de clé de produit"** → choisir **Windows 11 Pro**

> [!TIP] Sans clé de produit
> Windows 11 s'installe et fonctionne normalement sans clé. Certaines personnalisations sont limitées et un filigrane "Activer Windows" apparaît, mais tout le reste fonctionne pour un lab.

#### 4. Choix de l'édition

Si on n'a pas entré de clé, l'installeur demande quelle édition installer. Choisir **Windows 11 Pro**.

#### 5. Type d'installation

| Option | Description |
|--------|------------|
| **Mise à niveau** | Conserve fichiers, paramètres et applications (depuis Windows 10) |
| **Personnalisée** | Installation propre — formate le disque et installe un système neuf |

Pour le lab : **Personnalisée (avancé)**.

#### 6. Partitionnement du disque

Sur un disque vierge (cas de notre VM), l'installeur propose l'espace non alloué.

- Sélectionner **Espace non alloué** → **Suivant**
- Windows crée automatiquement les partitions nécessaires :

```
Disque 0 (64 Go)
├── Partition 1 : Système EFI (100 à 200 Mo)  ← bootloader UEFI
├── Partition 2 : MSR (16 Mo)                 ← réservé Microsoft
├── Partition 3 : Windows (≈ 63 Go)           ← système C:
└── Partition 4 : Récupération (≈ 900 Mo)     ← WinRE, en FIN de disque
```

Relevé réel sur `PC01` (26H2) :

```
PartitionNumber Type        MB DriveLetter
--------------- ----        -- -----------
              1 System     200
              2 Reserved    16
              3 Basic    64411           C
              4 Recovery   906
```

> [!NOTE] Pourquoi la récupération est-elle à la fin ?
> Les anciennes installations plaçaient WinRE **avant** C:. Quand une mise à jour de WinRE demandait plus de place, impossible d'agrandir la partition coincée devant le système. Placée **après** C:, elle peut être agrandie en réduisant C: (cas célèbre de la mise à jour KB5034441 en 2024).

> [!TIP] Partitions automatiques
> Il n'est pas nécessaire de créer manuellement les partitions. L'installeur gère tout seul la structure GPT/UEFI. Ne touche pas aux partitions système/EFI/récupération.

#### 7. Installation

L'installeur copie les fichiers, installe les fonctionnalités et les mises à jour. La VM redémarre plusieurs fois. **Ne pas appuyer sur une touche** lors des redémarrages (sinon on relance l'installeur).

---

## OOBE — Premier démarrage

Après l'installation, Windows lance l'**OOBE** (Out-Of-Box Experience) : l'assistant de configuration initiale.

### Étapes de l'OOBE

```
Région → Clavier → Réseau → Mises à jour → Nom du PC
  → Compte → Vie privée → Personnalisation → Bureau
```

#### Région et clavier

- Pays : **France**
- Disposition clavier : **Français**
- Deuxième disposition : **Ignorer**

#### Nom du PC

Donner un nom parlant à la machine : `PC01`

> [!TIP] Nommer le PC dès le départ
> Le nom du PC est utilisé dans le réseau, le DNS et Active Directory. Mieux vaut le définir dès l'OOBE plutôt que de le changer après (un changement nécessite un redémarrage et peut causer des problèmes en domaine).

#### Connexion réseau et compte Microsoft

L'OOBE demande une connexion Internet et un **compte Microsoft**. En lab et en entreprise, on veut un **compte local** à la place.

---

## Les trois types de comptes

| Type | Exemple | Où vit le compte | Usage |
|------|---------|------------------|-------|
| **Local** | `PC01\admin` | Base SAM du poste | Lab, poste isolé, compte de secours |
| **Compte Microsoft** (MSA) | `prenom@outlook.fr` | Cloud Microsoft (grand public) | Particuliers : synchronisation, OneDrive perso, Store |
| **Compte professionnel** (Entra ID) | `prenom@fournil.fr` | **Microsoft Entra ID** (ex-Azure AD) | Entreprises M365 : Intune, Autopilot, OneDrive pro, SSO |
| **Compte de domaine** (AD DS) | `FOURNIL\stagiaire` | Active Directory sur site | Entreprises avec contrôleurs de domaine (chapitre 10) |

Un poste peut être, au choix ou en combinaison :

```
Groupe de travail ──── comptes locaux (+ éventuellement MSA)
Joint à AD ─────────── comptes du domaine (chap. 10)
Joint à Entra ID ───── comptes professionnels, géré par Intune (chap. 16)
Joint hybride ──────── AD + Entra ID en même temps (synchronisation Entra Connect)
```

```cmd
:: Voir le type de jonction d'un poste
dsregcmd /status
```

Sur `PC01` à ce stade : `AzureAdJoined : NO`, `DomainJoined : NO` (groupe de travail).

---

## Obtenir un compte local à l'installation

Sur Windows 11 Home **et Pro**, l'OOBE impose un compte Microsoft ou professionnel et une connexion Internet. Les contournements « historiques » ont été supprimés un par un :

| Méthode | Statut fin 2026 |
|---------|-----------------|
| `Shift+F10` → `OOBE\BYPASSNRO` | ⚠️ **Variable selon la build** : retiré de certaines builds Insider 26300, mais encore présent sur l'ISO publique 26300.9457 du lab (`C:\Windows\System32\oobe\BypassNRO.cmd`) |
| `Shift+F10` → `start ms-cxh:localonly` | ❌ Bloqué depuis les builds 26120/26220.6772 |
| Clé `HKLM\...\OOBE\BypassNRO = 1` + redémarrage | ⚠️ Ce que fait le script ci-dessus ; **non documenté**, peut disparaître à tout moment |
| E-mail bidon type `no@thankyou.com` | ❌ Ne fonctionne plus |

> [!WARNING] Ne pas bâtir une procédure sur un contournement
> Microsoft retire ces astuces au fil des builds : ce qui marche sur l'ISO de septembre peut échouer sur celle de décembre. En formation comme en production, on présente ces méthodes comme **culture**, et on s'appuie sur les méthodes pérennes ci-dessous.

Les méthodes **pérennes**, celles qu'un administrateur utilise :

### 1. Le fichier de réponse (méthode professionnelle)

Un `autounattend.xml` à la racine du support d'installation masque les écrans de compte en ligne et crée le compte local :

```xml
<OOBE>
  <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
  <HideLocalAccountScreen>true</HideLocalAccountScreen>
</OOBE>
<UserAccounts>
  <LocalAccounts>
    <LocalAccount wcm:action="add">
      <Name>admin</Name><Group>Administrators</Group>
      <Password><Value>Fournil2026!</Value><PlainText>true</PlainText></Password>
    </LocalAccount>
  </LocalAccounts>
</UserAccounts>
```

C'est **la méthode supportée par Microsoft**, et celle qu'on construira proprement avec Windows SIM au chapitre 13. Le lab formateur a été installé ainsi, en zéro clic.

### 2. Ce qui se passe vraiment sans réseau (testé sur 26300.9457)

Débrancher le réseau **ne suffit plus**. Sur le lab, sans carte réseau connectée, l'OOBE bloque sur cet écran : bouton **Suivant grisé**, aucune autre issue que « Installer le pilote ».

![w11-02-oobe-reseau-obligatoire](https://cours.kaya.ovh/windows11/assets/captures/w11-02-oobe-reseau-obligatoire.png)

Après `Shift+F10` → `OOBE\BYPASSNRO` (qui ne fait qu'écrire la clé `BypassNRO=1` puis redémarrer), le même écran affiche le lien **« Je n'ai pas Internet »**, qui mène directement à la création d'un compte local :

![w11-02-oobe-bypassnro-pas-internet](https://cours.kaya.ovh/windows11/assets/captures/w11-02-oobe-bypassnro-pas-internet.png)

![w11-02-oobe-compte-local](https://cours.kaya.ovh/windows11/assets/captures/w11-02-oobe-compte-local.png)

Ça fonctionne **aujourd'hui sur cette build** — rien ne garantit que ce sera le cas sur la prochaine ISO.

### 3. Pro : « Configurer pour le travail ou l'école »

Sur l'édition **Pro** connectée au réseau, l'OOBE propose **Configurer pour une utilisation professionnelle ou scolaire** : connexion avec un compte **Entra ID** (jonction Entra/Intune, voire Autopilot si le poste est enregistré, chapitre 16). Selon les builds, un lien **Options de connexion → Joindre un domaine à la place** crée un compte local en vue d'une jonction AD ultérieure : à vérifier sur l'ISO utilisée.

### 4. Rufus (poste physique, cas ponctuel)

**Rufus** génère une clé USB dont l'image contient déjà un fichier de réponse (compte local, pas d'Internet requis, contrôle TPM désactivable). C'est en réalité la méthode n° 1, automatisée par un outil tiers.

> [!WARNING] Ne pas désactiver les contrôles TPM/Secure Boot en entreprise
> Rufus et certaines clés de registre (`LabConfig\BypassTPMCheck`) permettent d'installer Windows 11 sur du matériel non compatible. Le poste fonctionne mais n'est **pas supporté** : Microsoft peut lui refuser des mises à jour, et il n'a pas le socle de sécurité (TPM pour BitLocker, VBS) que Windows 11 suppose.

---

## Configuration post-OOBE

Une fois le bureau atteint, quelques réglages immédiats :

### Vie privée

Lors de l'OOBE, désactiver **toutes les options de télémétrie** (localisation, données de diagnostic, publicité, expériences personnalisées, etc.).

### Questions de sécurité

Windows demande 3 questions de sécurité pour le compte local. En lab, on peut mettre des réponses simples (on ne s'en servira probablement pas).

### Vérifier l'installation

```powershell
# Nom du PC
hostname

# Édition et version de Windows
Get-ComputerInfo | Select-Object OsName, OsVersion, OsBuildNumber

# Architecture
[Environment]::Is64BitOperatingSystem

# Espace disque disponible
Get-PSDrive C | Select-Object Used, Free, @{N="TotalGo";E={[math]::Round(($_.Used+$_.Free)/1GB,1)}}
```

---

## Mise à niveau d'un poste existant

### Vérifier la compatibilité

| Outil | Usage |
|-------|-------|
| **Contrôle d'intégrité du PC** (*PC Health Check*) | Un poste, interface graphique |
| `Get-Tpm`, `Confirm-SecureBootUEFI` | Script, à grande échelle |
| Rapport de compatibilité d'Intune / Autopatch | Parc géré dans le cloud |

```powershell
Get-Tpm | Select-Object TpmPresent, TpmReady, ManufacturerVersion
Confirm-SecureBootUEFI                      # True = Secure Boot actif
(Get-CimInstance Win32_Processor).Name      # comparer à la liste des processeurs supportés
```

### Les trois chemins

| Depuis | Méthode | Durée |
|--------|---------|-------|
| Windows 11 24H2/25H2 → 26H2 | Windows Update — **package d'activation** | 1 redémarrage |
| Windows 11 23H2 ou antérieur | Windows Update ou ISO — mise à niveau complète | 30 à 90 min |
| **Windows 10** 22H2 | Assistant d'installation, ISO (`setup.exe`), ou Windows Update si éligible | 30 à 90 min |

La **mise à niveau en place** conserve les applications, les paramètres et les fichiers. Elle se lance depuis l'ISO montée :

```cmd
:: Interactive
D:\setup.exe

:: Sans intervention, avec contrôle préalable de compatibilité uniquement
D:\setup.exe /auto upgrade /compat scanonly /quiet
:: Code de sortie 0xC1900210 = aucun problème de compatibilité

:: Mise à niveau silencieuse réelle, sans télémétrie dynamique
D:\setup.exe /auto upgrade /quiet /eula accept /dynamicupdate disable
```

> [!TIP] Retour arrière
> Pendant **10 jours** après une mise à niveau, *Paramètres → Système → Récupération → Revenir en arrière* restaure la version précédente (dossier `C:\Windows.old`). Le délai se règle avec `DISM /Online /Set-OSUninstallWindow /Value:30`.

### Installation propre ou mise à niveau ?

| | Mise à niveau en place | Installation propre (ou image, chap. 16) |
|-|------------------------|------------------------------------------|
| Applications et données | Conservées | Perdues → migration (USMT, OneDrive, chap. 16) |
| Durée de l'intervention | Courte | Plus longue (réinstaller les applications) |
| « Hygiène » du poste | Hérite des problèmes du système précédent | Poste propre, standardisé |
| En entreprise | Parc homogène et sain | Changement de matériel, poste instable |

---

## Récapitulatif

```
Prérequis matériels  → TPM 2.0, Secure Boot, UEFI, 4 Go RAM, 64 Go, 2 cœurs
Édition entreprise   → Pro minimum (Hyper-V, BitLocker, GPO, domaine, App Control)
Comptes              → local (SAM) | Microsoft | professionnel (Entra ID) | domaine (AD)
                       dsregcmd /status pour voir la jonction
Compte local à l'OOBE→ fichier de réponse (pérenne) | sans réseau : BLOQUÉ en 26H2
                       BYPASSNRO → "Je n'ai pas Internet" (marche sur 26300.9457, fragile)
                       BYPASSNRO : selon la build, ms-cxh:localonly : bloqué → jamais en procédure
Mise à niveau        → 24H2/25H2 → 26H2 : package d'activation (1 redémarrage)
                       Windows 10 → setup.exe /auto upgrade (fin de support W10 : 14/10/2025)
                       10 jours pour revenir en arrière (Windows.old)
Vérification         → winver, Get-ComputerInfo, Get-Tpm, Confirm-SecureBootUEFI
```
