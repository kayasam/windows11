---
title: "12. Administration et assistance à distance"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/12-acces-distant"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/12-acces-distant.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Configurer et utiliser les différents moyens d'accès distant à un poste Windows 11 : Bureau à distance (RDP), PowerShell Remoting/WinRS, OpenSSH, Assistance rapide (et Remote Help), et les outils RSAT — maintenant que `PC01`, `PC02` et `SRV01` sont joints au domaine `ad.fournil.lab` (chapitres 10 et 16).
>
> **Outils :** `mstsc.exe`, `winrs.exe`, `ssh.exe`, Assistance rapide, RSAT, Windows App
> **Commandes à connaître :** `Enable-PSRemoting`, `Enter-PSSession`, `Invoke-Command`, `ssh`, `Add-WindowsCapability`

---

## Bureau à distance (RDP)

Le **Bureau à distance** (Remote Desktop Protocol, port TCP **3389**) permet de prendre le contrôle graphique complet d'un poste distant.

> [!WARNING] RDP en tant que serveur nécessite Pro/Enterprise/Education
> Windows 11 **Home** peut se connecter à un poste distant (client RDP `mstsc.exe`), mais ne peut pas **héberger** de session Bureau à distance entrante — cette fonctionnalité est réservée aux éditions Pro et supérieures.

### Activation

**Interface graphique :** Paramètres → Système → Bureau à distance → activer le bouton bascule
![w11-10-acces-distant](https://cours.kaya.ovh/windows11/assets/captures/w11-10-acces-distant.png)
Ou : `sysdm.cpl` → onglet **Accès à distance** → cocher **Autoriser les connexions d'assistance à distance à cet ordinateur** et **Autoriser les connexions distantes à cet ordinateur**.
![w11-10-acces-distant-1](https://cours.kaya.ovh/windows11/assets/captures/w11-10-acces-distant-1.png)

```powershell
# Vérifier l'état actuel (1 = désactivé, 0 = activé) — désactivé par défaut sur Windows 11
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections

# Activer le Bureau à distance
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0

# Activer la règle de pare-feu associée (voir chapitre 9)
Enable-NetFirewallRule -DisplayGroup "Bureau à distance"
```

> [!NOTE] La valeur `fDenyTSConnections` est inversée
> `1` signifie **désactivé** (deny), `0` signifie **activé**. C'est la valeur par défaut sur un Windows 11 fraîchement installé — RDP entrant est désactivé tant qu'on ne l'active pas explicitement, en GUI ou via cette clé.

### Se connecter

```cmd
:: Client RDP graphique
mstsc /v:SRV01
```

| Option `mstsc` | Rôle |
|-----------------|------|
| `/v:<ordinateur>` | Machine cible |
| `/admin` | Se connecter à la session console (administration), pas une session utilisateur classique |
| `/multimon` | Utilise plusieurs écrans côté client |
| `/w:<largeur> /h:<hauteur>` | Résolution de la fenêtre |

---

## WinRM, WinRS et PowerShell Remoting

**WinRM** (Windows Remote Management) est le service Microsoft qui expose l'administration à distance via le protocole WS-Management (HTTP/HTTPS, ports **5985/5986**). Il sert de socle à deux outils :

| | PowerShell Remoting | WinRS |
|-|----------------------|-------|
| **Shell distant** | PowerShell complet (objets) | CMD (texte brut) |
| **Cmdlet/commande** | `Enter-PSSession`, `Invoke-Command` | `winrs.exe` |
| **Usage typique** | Administration moderne, scripts | Compatibilité avec scripts CMD hérités |

### Activation

```powershell
# Sur la machine à administrer à distance (SRV01 ou PC01) :
# active le service WinRM, crée l'écouteur et la règle de pare-feu associée
Enable-PSRemoting -Force

# Vérifier que le service WinRM tourne
Get-Service WinRM

# Tester la disponibilité de WinRM sur une machine distante
Test-WSMan -ComputerName SRV01
```

Constaté sur le lab :

| Poste | WinRM par défaut |
|-------|------------------|
| Windows Server 2025 (`SRV01`) | **Actif** (PowerShell Remoting activé d'office) |
| Windows 11 (`PC01`, `PC02`) | **Arrêté**, démarrage manuel — `Enable-PSRemoting` obligatoire |

`Enable-PSRemoting` crée deux règles : `WINRM-HTTP-In-TCP-NoScope` (**Domaine, Privé** — activée) et `WINRM-HTTP-In-TCP` (**Public** — *désactivée*, et limitée au sous-réseau local). Sur un parc, on l'active par **GPO** (*Composants Windows → Gestion à distance de Windows → Service WinRM → Autoriser la gestion à distance du serveur via WinRM*, + règle de pare-feu + service en automatique).

```powershell
# Résultat réel depuis PC01 (Kerberos, aucun mot de passe demandé)
Invoke-Command -ComputerName SRV01, PC02 -ScriptBlock { "$env:COMPUTERNAME : $((Get-CimInstance Win32_OperatingSystem).Caption)" }
# SRV01 : Microsoft Windows Server 2025 Standard Evaluation
# PC02 : Microsoft Windows 11 Professionnel
```

> [!TIP] Kerberos gère l'authentification automatiquement entre membres du domaine
> `PC01` et `SRV01` étant désormais jointes au domaine `ad.fournil.lab` (chapitre 10), le Remoting utilise l'authentification **Kerberos** de façon transparente entre elles — inutile de configurer `TrustedHosts` ni de ressaisir des identifiants à chaque connexion, contrairement à un scénario en groupe de travail.
>
> **Pour mémoire (hors domaine ou entre deux machines en groupe de travail) :** il faudrait déclarer la machine distante dans `TrustedHosts` côté client (`Set-Item WSMan:\localhost\Client\TrustedHosts -Value "NomMachine" -Force`) et fournir systématiquement `-Credential`, faute d'authentification Kerberos disponible.

### PowerShell Remoting : les trois façons de faire

| Cmdlet | Usage |
|--------|-------|
| `Enter-PSSession` | Session interactive **1 vers 1** — comme un SSH, on "entre" dans la console distante |
| `Invoke-Command` | Exécute une commande ou un bloc de script **1 vers N machines**, retourne les résultats localement |
| `New-PSSession` | Crée une session **persistante** réutilisable pour plusieurs commandes successives (évite de rouvrir une connexion à chaque fois) |

```powershell
# Session interactive (authentification Kerberos transparente, compte du domaine courant)
Enter-PSSession -ComputerName SRV01
# (dans la session distante) Get-Service | Where-Object Status -eq Running
Exit-PSSession

# Exécuter une commande à distance sur plusieurs machines sans session interactive
Invoke-Command -ComputerName SRV01, PC02 -ScriptBlock {
    Get-Service -Name "sshd"
}

# Session persistante réutilisable
$session = New-PSSession -ComputerName SRV01
Invoke-Command -Session $session -ScriptBlock { Get-Process }
Invoke-Command -Session $session -ScriptBlock { Get-EventLog -LogName System -Newest 5 }
Remove-PSSession $session
```

> [!TIP] Pourquoi une session persistante (`New-PSSession`) ?
> `Invoke-Command` sans `-Session` ouvre et ferme une connexion à chaque appel. Si plusieurs commandes doivent partager un état (variables, modules importés), `New-PSSession` garde la connexion ouverte et le contexte en mémoire entre les appels.

### WinRS — shell CMD distant

```cmd
:: Exécuter une commande CMD unique sur une machine distante
winrs -r:http://SRV01:5985 ipconfig /all

:: Ouvrir un shell CMD interactif distant
winrs -r:http://SRV01:5985 cmd
```

---

## OpenSSH — l'alternative ouverte et multiplateforme

**OpenSSH** est aujourd'hui intégré à Windows en tant que fonctionnalité optionnelle, et fonctionne **en parallèle** de WinRM plutôt qu'en remplacement — contrairement à WinRM (protocole Microsoft, principalement Windows-à-Windows), SSH est un standard ouvert, universel entre Windows, Linux et macOS.

| | WinRM / PowerShell Remoting | OpenSSH |
|-|-------------------------------|---------|
| **Origine** | Protocole Microsoft (WS-Management) | Standard ouvert, multiplateforme |
| **Port** | 5985 (HTTP) / 5986 (HTTPS) | 22 |
| **Authentification typique** | Kerberos (domaine) ou NTLM+mot de passe | Mot de passe ou **clé publique/privée** |
| **Client dispo nativement** | Windows uniquement | Windows, Linux, macOS |
| **Cas d'usage typique** | Administration Windows pure, scripts PowerShell | Environnements hétérogènes, automatisation cross-platform, habitudes Linux |

### Client OpenSSH (déjà présent)

Le **client** SSH est installé par défaut sur Windows 11 depuis plusieurs versions déjà — rien à installer :

```powershell
Get-Command ssh.exe
```

```cmd
:: Se connecter en SSH à une machine Linux ou Windows (avec serveur SSH actif)
ssh administrateur@SRV01
```

### Serveur OpenSSH

> [!NOTE] Déjà activé sur SRV01 depuis le chapitre 10
> Sur `SRV01`, le serveur OpenSSH tourne déjà (chapitre 10) — rien à réinstaller ici. Le déroulé ci-dessous reste utile pour l'activer sur un poste **Windows 11 client**, où la capacité n'est **pas** installée par défaut (contrairement à Windows Server 2025, où elle est très souvent déjà présente).

```powershell
# Toujours vérifier l'état avant d'installer quoi que ce soit
Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Select-Object Name, State

# Installer uniquement si l'état est "NotPresent" (Feature on Demand, comme RSAT)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Démarrer le service et le passer en démarrage automatique
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

> [!WARNING] La règle de pare-feu OpenSSH ne couvre que le profil Privé
> La règle `OpenSSH-Server-In-TCP` (créée avec la capacité) n'autorise le trafic que sur le profil réseau **Privé** — pas Public, pas Domaine. Or une carte connectée à un switch Hyper-V interne est souvent classée **Public** par défaut (voir chapitre 9), et bascule automatiquement en **Domaine** une fois `SRV01` promu contrôleur de domaine et `PC01` joint au domaine (chapitre 10). Dans les deux cas, la règle scopée Privé uniquement ne s'applique pas, et la connexion échoue en timeout (pas "connection refused").
> ```powershell
> Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" | Select-Object Direction, Action, Profile
> Get-NetConnectionProfile
>
> # Élargir la règle aux trois profils plutôt que de ne corriger qu'un seul cas :
> Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Profile Domain,Private,Public
> ```
> Si la règle elle-même est absente (rare), la créer avec `New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Domain,Private,Public`.

> [!NOTE] Shell par défaut d'une session SSH sur Windows
> Par défaut, une connexion SSH sur Windows ouvre une session **cmd.exe**. Pour que `ssh` ouvre PowerShell par défaut :
> ```powershell
> New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
> ```

### PowerShell Remoting par-dessus SSH

Depuis **PowerShell 7**, `Enter-PSSession` et `New-PSSession` peuvent utiliser le **transport SSH** au lieu de WinRM — utile pour administrer une machine Linux avec PowerShell 7, ou éviter WinRM dans un environnement où seul le port 22 est ouvert.

> [!WARNING] Nécessite PowerShell 7 des deux côtés
> Le paramètre `-HostName` (transport SSH) n'existe que dans **PowerShell 7+** — `Enter-PSSession -HostName` échoue en Windows PowerShell 5.1, qui ne connaît que le transport WinRM classique (`-ComputerName`). `PC01` a déjà PowerShell 7 (installé au chapitre 7 via winget) ; `SRV01`, en Server Core, ne l'a pas encore.

#### Installer PowerShell 7 sur SRV01 (Server Core)

> [!NOTE] Pas de winget sur Server Core
> Contrairement à `PC01`, `winget` n'est **pas présent** sur Windows Server (App Installer n'est pas préinstallé sur les SKUs serveur) — `Get-Command winget.exe` retourne une erreur. Il faut passer par le programme d'installation MSI directement.

**Méthode 1 — version fixe (téléchargement direct du MSI) :**

```powershell
New-Item -Path "C:\Temp" -ItemType Directory -Force
Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.6.9/PowerShell-7.6.9-win-x64.msi" -OutFile "C:\Temp\pwsh7.msi"
msiexec.exe /i C:\Temp\pwsh7.msi /quiet /norestart
```

> [!WARNING] Créer `C:\Temp` avant de télécharger
> Sur une installation Server Core toute fraîche, `C:\Temp` n'existe pas encore. `Invoke-WebRequest` échoue avec "Impossible de trouver une partie du chemin d'accès" si le dossier de destination n'existe pas — le créer d'abord avec `New-Item`.

**Méthode 2 — dernière version via l'API GitHub** (évite de coder un numéro de version en dur) :

```powershell
# Interroger l'API GitHub pour la dernière release stable
$latest = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"

# Filtrer l'asset correspondant au MSI Windows x64
$msiAsset = $latest.assets | Where-Object { $_.name -like "*win-x64.msi" }

# Télécharger et installer
New-Item -Path "C:\Temp" -ItemType Directory -Force
Invoke-WebRequest -Uri $msiAsset.browser_download_url -OutFile "C:\Temp\pwsh7.msi"
msiexec.exe /i C:\Temp\pwsh7.msi /quiet /norestart
```

> [!TIP] Script d'installation officiel Microsoft
> Microsoft documente aussi un script bootstrap qui fait l'équivalent de la Méthode 2 en une ligne :
> ```powershell
> & ([scriptblock]::Create((irm https://aka.ms/install-powershell.ps1))) -UseMSI -Quiet
> ```

Vérifier l'installation :

```powershell
Get-Command "C:\Program Files\PowerShell\7\pwsh.exe"
```

#### Configurer le sous-système SSH pour PowerShell 7

> [!WARNING] Installer pwsh ne suffit pas
> Le serveur SSH ne sait pas encore, à ce stade, quoi lancer quand un client demande une session PowerShell — il faut déclarer explicitement un **sous-système** dans la configuration OpenSSH. Sans cette étape, `Enter-PSSession -HostName` échoue même avec PowerShell 7 correctement installé.

```powershell
Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value 'Subsystem powershell "C:\Program Files\PowerShell\7\pwsh.exe" -sshs -NoLogo -NoProfile'
Restart-Service sshd
```

#### Tester la connexion

Depuis `PC01` (dans `pwsh`, PowerShell 7) :

```powershell
Enter-PSSession -HostName SRV01 -UserName Administrateur
```

### Authentification par clé publique

```powershell
# Générer une paire de clés sur le poste client
ssh-keygen -t ed25519

# Copier la clé publique sur le serveur cible (ajout manuel dans authorized_keys, ou outil dédié sous Linux)
```

> [!TIP] Pourquoi préférer une clé à un mot de passe
> L'authentification par clé évite de transmettre un mot de passe à chaque connexion et permet des connexions non-interactives (scripts, automatisation) sans stocker d'identifiants en clair — c'est la pratique standard en environnement Linux/DevOps, de plus en plus reprise côté Windows.

---

## Assistance rapide (Quick Assist)
![w11-11-acces-distant](https://cours.kaya.ovh/windows11/assets/captures/w11-11-acces-distant.png)

**Quick Assist** est une application pré-installée sur Windows 11 (`MicrosoftCorporationII.QuickAssist`, lancée depuis le menu Démarrer — ce n'est pas un exécutable `.exe` classique dans `System32`, mais une application empaquetée). Elle permet de **partager l'écran** ou de **prendre le contrôle** d'un poste distant, typiquement pour du support utilisateur ponctuel.

### Principe

```
Utilisateur A (assistance à donner)          Utilisateur B (assistance à recevoir)
        │                                              │
        ▼                                              ▼
"Donner de l'assistance" ──► génère un code ──► "Obtenir de l'assistance"
        │                     à 6 chiffres              │
        └──────────────── saisie du code ────────────────┘
                                │
                    Connexion établie (via relais Microsoft),
                    partage d'écran, puis contrôle à distance sur demande
```

> [!WARNING] Compte Microsoft côté technicien
> La personne qui **donne** l'assistance doit se connecter avec un **compte Microsoft** (personnel ou professionnel). Celle qui **reçoit** l'aide saisit seulement le code. Ce n'est pas un outil d'entreprise : aucune journalisation centrale, aucun contrôle de qui peut aider qui — et un vecteur d'arnaque connu (faux supports techniques qui demandent un code Quick Assist).

### Remote Help : la version entreprise

**Remote Help** (module payant d'Intune, inclus dans certaines offres) reprend le principe d'Assistance rapide avec : authentification par le tenant de l'entreprise, rôles (qui peut aider qui), **journal** des sessions, affichage du nom et de la conformité du poste avant de se connecter, élévation UAC possible côté technicien.

### Windows App et le client Bureau à distance

| Client | Usage | Statut |
|--------|-------|--------|
| `mstsc.exe` (Connexion Bureau à distance) | Se connecter à un PC ou un serveur | ✅ Intégré et supporté |
| Application « Bureau à distance » (Store) | AVD, Windows 365 | ❌ Retirée (mai 2025) |
| Client MSRDC (MSI) | AVD, Windows 365 | ❌ Fin de support (mars 2026) |
| **Windows App** | Windows 365, Azure Virtual Desktop, Dev Box, PC (connexion directe en préversion) | ✅ Remplaçant officiel |

Contrairement à RDP, Quick Assist ne nécessite **aucune configuration réseau préalable** (pas de port à ouvrir, pas de règle de pare-feu) : la connexion transite par un relais Microsoft dans le cloud, ce qui la rend utilisable même entre deux réseaux différents sans VPN.

---

## RSAT — Remote Server Administration Tools

**RSAT** regroupe les consoles d'administration Windows Server (AD DS, DNS, DHCP, GPMC...), utilisables **depuis un poste Windows 11 client** pour administrer `SRV01` sans s'y connecter directement.

> [!TIP] Le bon moment pour installer RSAT
> Les rôles AD DS, DNS et DHCP ont déjà été installés et configurés sur `SRV01` au chapitre 10 — les consoles RSAT installées ici seront donc **immédiatement utilisables**, contrairement à une installation anticipée avant que les rôles n'existent côté serveur.

### Installation

**Interface graphique :** Paramètres → Applications → Fonctionnalités facultatives → Ajouter une fonctionnalité → rechercher "RSAT"

![w11-11-acces-distant-1](https://cours.kaya.ovh/windows11/assets/captures/w11-11-acces-distant-1.png)

```powershell
# Lister les fonctionnalités RSAT disponibles (terminal administrateur)
Get-WindowsCapability -Online | Where-Object Name -like "Rsat*" | Select-Object Name, State

# Installer les outils AD DS
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"

# Installer les outils DNS et DHCP
Add-WindowsCapability -Online -Name "Rsat.Dns.Tools~~~~0.0.1.0"
Add-WindowsCapability -Online -Name "Rsat.DHCP.Tools~~~~0.0.1.0"

# Installer la console de gestion des stratégies de groupe (GPMC, utile dès le chapitre 16)
Add-WindowsCapability -Online -Name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
```

| Capacité RSAT | Console installée |
|----------------|--------------------|
| `Rsat.ActiveDirectory.DS-LDS.Tools` | Utilisateurs et ordinateurs AD, Domaines et approbations, Sites et services |
| `Rsat.Dns.Tools` | Gestionnaire DNS |
| `Rsat.DHCP.Tools` | Console DHCP |
| `Rsat.GroupPolicy.Management.Tools` | GPMC (Gestion des stratégies de groupe) |
| `Rsat.ServerManager.Tools` | Gestionnaire de serveur |

> [!NOTE] RSAT nécessite un accès à Windows Update (ou une source WSUS/hors ligne)
> Ces fonctionnalités sont livrées en tant que "Features on Demand" — le poste doit pouvoir joindre Windows Update pour les télécharger, sauf si une source hors ligne (partage réseau avec les fichiers de capacité) est configurée.

---

## Récapitulatif

```
Bureau à distance (RDP, port 3389)
  Désactivé par défaut (fDenyTSConnections=1) | Pro/Enterprise/Education pour héberger
  mstsc /v:machine | Activer via Paramètres ou registre + règle de pare-feu

WinRM / PowerShell Remoting / WinRS
  Domaine : Kerberos automatique, pas de TrustedHosts nécessaire (contrairement au hors-domaine)
  Enter-PSSession (1-to-1) | Invoke-Command (1-to-N) | New-PSSession (persistante)
  winrs -r:http://machine:5985 commande   ← shell CMD distant

OpenSSH — alternative ouverte, en parallèle de WinRM
  Client pré-installé | Serveur : déjà actif sur SRV01 (ch.10) — vérifier avant d'installer sur un client
  ssh user@machine | Enter-PSSession -HostName (PowerShell 7 uniquement, des DEUX côtés)
  Authentification par clé (ssh-keygen) plutôt que mot de passe

PS Remoting sur SSH — installer PS7 sur SRV01 (pas de winget sur Server Core)
  MSI direct (version fixe) OU API GitHub releases/latest (version toujours à jour)
  PUIS déclarer le sous-système "powershell" dans sshd_config → Restart-Service sshd
  (sans cette dernière étape, Enter-PSSession -HostName échoue même avec pwsh installé)

Assistance rapide (Quick Assist)
  App pré-installée | code à 6 chiffres | compte Microsoft côté technicien
  Aucune config réseau (relais cloud) — contrairement à RDP/WinRM/SSH
  Entreprise : Remote Help (Intune, journalisé, RBAC)

Clients Bureau à distance
  mstsc.exe : supporté | appli Bureau à distance/MSRDC : retirées → Windows App (AVD, Windows 365)
  WinRM : actif sur Server, ARRÊTÉ sur Windows 11 → Enable-PSRemoting ou GPO

RSAT
  Installé APRÈS que les rôles existent sur SRV01 (chapitre 10) → immédiatement utilisable
  Add-WindowsCapability -Online -Name "Rsat.XXX.Tools~~~~0.0.1.0"
```
