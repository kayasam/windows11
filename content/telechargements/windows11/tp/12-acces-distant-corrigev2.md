# TP 12. Administration et assistance à distance — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h45

> Chapitres associés : [12. Administration et assistance à distance](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/)

---

## Objectifs

- Activer et utiliser le Bureau à distance
- Administrer plusieurs postes en PowerShell Remoting et WinRS
- Utiliser OpenSSH entre Windows, puis PowerShell Remoting sur SSH
- Installer les RSAT et administrer AD depuis `PC01`
- Connaître les outils d'assistance (Assistance rapide, Remote Help)

---

## Prérequis

- `PC01`, `PC02`, `SRV01` dans le domaine (TP 10, TP 16)
- Session `PC01` avec un compte administrateur des postes

---

## Partie A — Bureau à distance (20 min)

**A1.** Le port RDP de `PC02` est-il ouvert ? Vérifie depuis `PC01` sans ouvrir `mstsc`.

> [!success]- Afficher la correction — A1
> ```powershell
> Test-NetConnection PC02 -Port 3389
> ```
> `TcpTestSucceeded : False` sur le lab : le Bureau à distance est **désactivé par défaut** sur Windows 11 (`fDenyTSConnections = 1`).

**A2.** Active le Bureau à distance sur `PC02` **à distance**, sans t'y connecter graphiquement. Quelle méthode utilises-tu ?

> [!success]- Afficher la correction — A2
> PowerShell Remoting (partie B) :
> ```powershell
> Invoke-Command -ComputerName PC02 -ScriptBlock {
>     Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0
>     Enable-NetFirewallRule -DisplayGroup "Bureau à distance"
> }
> Test-NetConnection PC02 -Port 3389     # True
> ```
> À l'échelle : GPO *Composants Windows → Services Bureau à distance → Hôte de la session… → Connexions → Autoriser les utilisateurs à se connecter à distance*.

**A3.** Connecte-toi à `PC02` avec `mstsc`. Qui a le droit de s'y connecter ? Comment autoriser `stagiaire` ?

> [!success]- Afficher la correction — A3
> `mstsc /v:PC02`. Peuvent se connecter : le groupe local **Administrateurs** et **Utilisateurs du Bureau à distance**.
> ```powershell
> Invoke-Command -ComputerName PC02 -ScriptBlock { Add-LocalGroupMember -SID S-1-5-32-555 -Member "FOURNIL\stagiaire" }
> ```
> (`S-1-5-32-555` = *Utilisateurs du Bureau à distance*, quelle que soit la langue.) Le poste n'accepte qu'**une** session : si `stagiaire` est connecté sur la console, il est déconnecté.

**A4.** Quel client utiliserais-tu pour un PC cloud Windows 365 ?

> [!success]- Afficher la correction — A4
> **Windows App** (Store / WinGet) ou le navigateur. L'application « Bureau à distance » du Store est retirée depuis mai 2025, le client MSRDC depuis mars 2026. `mstsc` ne sait pas se connecter à un Cloud PC.

---

## Partie B — PowerShell Remoting et WinRS (30 min)

**B1.** L'état du service WinRM sur `PC01`, `PC02` et `SRV01`. Que constates-tu ?

> [!success]- Afficher la correction — B1
> ```powershell
> Get-Service WinRM -ComputerName SRV01      # Running
> Get-Service WinRM                          # sur PC01 : Stopped / Manual
> ```
> Windows Server a PowerShell Remoting **activé d'office**, Windows 11 **non** (constaté sur `PC01` et `PC02`).

**B2.** Active PowerShell Remoting sur `PC02`. Quelles règles de pare-feu sont créées, pour quels profils ?

> [!success]- Afficher la correction — B2
> ```powershell
> Enable-PSRemoting -Force
> Get-NetFirewallRule -Name WINRM-HTTP-In-TCP* | Select-Object Name, Enabled, Profile
> ```
> ```
> Name                      Enabled  Profile
> WINRM-HTTP-In-TCP           False  Public
> WINRM-HTTP-In-TCP-NoScope    True  Domain, Private
> ```
> Service WinRM démarré et automatique, écouteur HTTP 5985 créé. Sur **Public**, la règle est désactivée (et limitée au sous-réseau local) : un portable au café n'accepte pas de commandes à distance.

**B3.** Depuis `PC01`, affiche en une commande le nom et la version de Windows de `SRV01` et `PC02`. Pourquoi aucun mot de passe n'est-il demandé ?

> [!success]- Afficher la correction — B3
> ```powershell
> Invoke-Command -ComputerName SRV01, PC02 -ScriptBlock {
>     "$env:COMPUTERNAME : $((Get-CimInstance Win32_OperatingSystem).Caption)"
> }
> ```
> ```
> SRV01 : Microsoft Windows Server 2025 Standard Evaluation
> PC02 : Microsoft Windows 11 Professionnel
> ```
> **Kerberos** : les trois machines sont dans le domaine, le ticket de la session courante suffit. Hors domaine, il faudrait `TrustedHosts` et `-Credential`.

**B4.** Ouvre une session interactive sur `SRV01`, liste les services DHCP et DNS, quitte.

> [!success]- Afficher la correction — B4
> ```powershell
> Enter-PSSession SRV01
> [SRV01]: PS> Get-Service DHCPServer, DNS
> [SRV01]: PS> Exit-PSSession
> ```

**B5.** Avec WinRS, exécute `ipconfig /all` sur `SRV01`.

> [!success]- Afficher la correction — B5
> ```cmd
> winrs -r:SRV01 ipconfig /all
> winrs -r:SRV01 hostname          :: SRV01
> ```

**B6.** Comment activerais-tu WinRM sur les 35 postes du Fournil ?

> [!success]- Afficher la correction — B6
> Une GPO liée à `OU=Ordinateurs` :
> - *Modèles d'administration → Composants Windows → Gestion à distance de Windows (WinRM) → Service WinRM → **Autoriser la gestion à distance du serveur via WinRM*** (filtre IPv4 : `192.168.3.0/24` ou `*`) ;
> - *Paramètres de sécurité → Services système → Gestion à distance de Windows* : **Automatique** ;
> - *Pare-feu Windows Defender → Règles de trafic entrant* : règle prédéfinie **Gestion à distance de Windows**, profil Domaine.

---

## Partie C — OpenSSH (30 min)

**C1.** Le client SSH est-il présent sur `PC01` ? Le port 22 de `SRV01` répond-il ?

> [!success]- Afficher la correction — C1
> ```powershell
> Get-Command ssh.exe                                # C:\WINDOWS\System32\OpenSSH\ssh.exe
> Test-NetConnection SRV01 -Port 22                  # True
> ```
> (Le serveur a été démarré au TP 10 ; sa règle de pare-feu élargie à tous les profils.)

**C2.** Connecte-toi en SSH à `SRV01`. Quel shell obtiens-tu ? Fais en sorte que ce soit PowerShell.

> [!success]- Afficher la correction — C2
> `ssh administrateur@SRV01` → une invite **cmd.exe**. Pour PowerShell, sur `SRV01` :
> ```powershell
> New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
>     -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
> ```

**C3.** Génère une paire de clés ed25519 sur `PC01` et configure l'authentification par clé pour `Administrateur` sur `SRV01`. Quel fichier particulier faut-il utiliser pour un compte administrateur ?

> [!success]- Afficher la correction — C3
> ```powershell
> ssh-keygen -t ed25519                       # sur PC01, clés dans C:\Users\<moi>\.ssh\
> ```
> Pour un membre du groupe **Administrateurs**, OpenSSH Windows ignore `~\.ssh\authorized_keys` : il lit **`C:\ProgramData\ssh\administrators_authorized_keys`**, dont les droits doivent être limités à Administrateurs et SYSTEM.
> ```powershell
> $pub = Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
> Invoke-Command -ComputerName SRV01 -ScriptBlock {
>     param($k) Add-Content C:\ProgramData\ssh\administrators_authorized_keys $k
>     icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "Administrateurs:F" "SYSTEM:F"
> } -ArgumentList $pub
> ssh administrateur@SRV01                    # plus de mot de passe
> ```

**C4.** Installe PowerShell 7 sur `SRV01` (Server Core), déclare le sous-système SSH et ouvre une session `Enter-PSSession -HostName`. *(approfondissement)*

> [!success]- Afficher la correction — C4
> Sur `SRV01` (pas de WinGet sur Server Core) :
> ```powershell
> New-Item C:\Temp -ItemType Directory -Force
> Invoke-WebRequest "https://github.com/PowerShell/PowerShell/releases/download/v7.6.9/PowerShell-7.6.9-win-x64.msi" -OutFile C:\Temp\pwsh7.msi
> msiexec /i C:\Temp\pwsh7.msi /quiet /norestart
> Add-Content C:\ProgramData\ssh\sshd_config 'Subsystem powershell "C:\Program Files\PowerShell\7\pwsh.exe" -sshs -NoLogo -NoProfile'
> Restart-Service sshd
> ```
> Depuis `PC01`, dans **pwsh** :
> ```powershell
> Enter-PSSession -HostName SRV01 -UserName Administrateur
> ```
> Rappel du TP 07 : sur `PC01`, le PowerShell 7 installé par WinGet est la version **MSIX** — sans incidence côté client. Côté serveur, il **faut** le MSI pour que le chemin du `Subsystem` existe.

---

## Partie D — RSAT et assistance (20 min)

**D1.** Installe sur `PC01` les outils AD DS, DNS, DHCP et GPMC. Ouvre `dsa.msc` et crée un utilisateur `test.vendeur` dans `OU=Utilisateurs`.

> [!success]- Afficher la correction — D1
> ```powershell
> "Rsat.ActiveDirectory.DS-LDS.Tools","Rsat.Dns.Tools","Rsat.DHCP.Tools","Rsat.GroupPolicy.Management.Tools" |
>     ForEach-Object { Add-WindowsCapability -Online -Name "$_~~~~0.0.1.0" }
> ```
> Plusieurs minutes (Features on Demand depuis Windows Update). Ne **pas** redémarrer pendant l'installation (vécu sur le lab : échec, à relancer). Puis `dsa.msc` → `OU=Utilisateurs` → Nouvel utilisateur, ou :
> ```powershell
> New-ADUser test.vendeur -Path "OU=Utilisateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab" -AccountPassword (Read-Host -AsSecureString) -Enabled $true
> ```

**D2.** Lance l'Assistance rapide. Qui a besoin d'un compte Microsoft ? Quel risque de sécurité faut-il expliquer aux utilisateurs ?

> [!success]- Afficher la correction — D2
> `Win + Ctrl + Q`, ou menu Démarrer → *Assistance rapide*. Le **technicien** (« Aider quelqu'un ») doit se connecter avec un compte Microsoft ou professionnel ; l'utilisateur (« Obtenir de l'aide ») saisit simplement le code à 6 chiffres, puis accepte le partage ou le contrôle.
> Risque : les **arnaques au faux support** (« Microsoft a détecté un virus, donnez-moi le code affiché ») utilisent exactement cet outil. Message à faire passer : *on ne donne un code Quick Assist qu'à une personne du support qu'on a soi-même appelée.*

**D3.** Quelles différences entre Assistance rapide et Remote Help ?

> [!success]- Afficher la correction — D3
> | | Assistance rapide | Remote Help (Intune) |
> |-|-------------------|----------------------|
> | Coût | Gratuit, intégré | Licence |
> | Identité du technicien | N'importe quel compte Microsoft | Compte du tenant, **rôles RBAC** |
> | Contrôle de qui aide qui | Aucun | Oui (groupes, étendues) |
> | Journalisation | Non | Oui (rapports de sessions) |
> | Infos sur le poste avant connexion | Non | Nom, conformité Intune |
> | Élévation (UAC) côté technicien | Non | Oui |

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp)
