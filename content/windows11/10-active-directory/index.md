---
title: "10. Active Directory et services réseau"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/10-active-directory"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/10-active-directory/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/10-active-directory.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Installer `SRV01` (Windows Server 2025, Server Core), la préparer (IP fixe, renommage, mises à jour, SSH), installer les rôles AD DS, DNS et DHCP, promouvoir le serveur en contrôleur de domaine, créer la structure de base (UO, utilisateurs, groupes), puis configurer le DHCP.
>
> **Outils :** PowerShell (Server Core = pas de GUI), `sconfig`
> **Commandes à connaître :** `Install-ADDSForest`, `Add-Computer`, `New-ADUser`, `New-ADOrganizationalUnit`, `Add-DhcpServerv4Scope`

---

## Installation de Windows Server 2025 en Server Core

> [!NOTE] Server Core = sans interface graphique
> "Server Core" est une installation minimale de Windows Server, sans Explorateur ni Bureau — uniquement une invite de commandes au démarrage. L'administration se fait en ligne de commande, via `sconfig` (menu texte) ou à distance. C'est l'installation recommandée en production (surface d'attaque réduite, moins de mises à jour, moins de ressources consommées).

### Créer la VM

Depuis l'hôte (PowerShell administrateur) :

```powershell
New-VM -Name "SRV01" -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath "D:\VMs\SRV01\SRV01.vhdx" -NewVHDSizeBytes 64GB -SwitchName "vSwitch-Rennes"
Set-VMDvdDrive -VMName "SRV01" -Path "D:\ISO\WindowsServer2025-eval.iso"
Set-VMProcessor -VMName "SRV01" -Count 2
```

Équivalent graphique : Gestionnaire Hyper-V → **Nouveau** → **Ordinateur virtuel** → suivre l'assistant (Génération 2, 4096 Mo, réseau `vSwitch-Rennes`, disque dur virtuel de 64 Go, installer depuis un fichier image ISO).

### Installer l'OS

Démarrer la VM et lancer l'installation. Au choix de l'image, plusieurs entrées sont proposées :

```
Windows Server 2025 Standard Evaluation
Windows Server 2025 Standard Evaluation (Desktop Experience)
Windows Server 2025 Datacenter Evaluation
Windows Server 2025 Datacenter Evaluation (Desktop Experience)
```

Les entrées **sans** la mention "(Desktop Experience)" correspondent à **Server Core** — c'est ce choix qu'il faut sélectionner. Suivre ensuite l'assistant (licence, "Personnalisé : installer uniquement Windows", disque cible), puis définir le mot de passe Administrateur au premier démarrage (en mode texte).

---

## Préparation : IP fixe et renommage (sconfig)

`sconfig` se lance automatiquement à l'ouverture de session sur une installation Server Core.

```
1) Domain/Workgroup
2) Computer Name
...
8) Network Settings
...
```

**Renommer :** taper `2` → saisir `SRV01` → confirmer le redémarrage (peut être différé).

**IP fixe :** taper `8` → sélectionner l'index de la carte réseau → `1` (Set Network Adapter Address) → `S` (Static) → saisir l'adresse IP (`192.168.3.1`), le masque (`255.255.255.0`) et la passerelle (`192.168.3.254`).

**DNS :** toujours dans le même menu `8) Network Settings` → `2` (Set DNS Servers) → saisir un DNS public provisoire, par exemple `1.1.1.1`.

> [!WARNING] Sans DNS, pas de mise à jour possible
> `SRV01` n'est pas encore contrôleur de domaine à ce stade — il n'y a donc pas encore de serveur DNS sur le réseau. Sans DNS configuré (même provisoire), le serveur ne peut résoudre aucun nom d'hôte et `Install-WindowsUpdate` (section suivante) échoue silencieusement. Ce DNS public sera remplacé plus tard : une fois `SRV01` promu contrôleur de domaine avec `-InstallDns:$true`, il se reconfigure lui-même sur **`127.0.0.1`** (constaté sur le lab).

Équivalent PowerShell (accessible via `sconfig` → `15) Exit to Command Line`, ou directement) :

```powershell
Rename-Computer -NewName "SRV01" -Restart
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.3.1 -PrefixLength 24 -DefaultGateway 192.168.3.254
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "1.1.1.1"
```

Une fois redémarrée, vérifier que le nom et l'IP sont bien pris en compte :

```cmd
hostname
ipconfig
```

---

## Mise à jour

Avant d'installer quoi que ce soit, mettre le serveur à jour — un contrôleur de domaine qui démarre avec des failles connues n'a rien d'un bon point de départ.

```powershell
# Rechercher, télécharger et installer les mises à jour disponibles (module PSWindowsUpdate, voir chapitre 8)
Install-Module PSWindowsUpdate -Force
Get-WindowsUpdate
Install-WindowsUpdate -AcceptAll -AutoReboot
```

> [!NOTE] Pas d'interface graphique pour suivre la progression
> Sur Server Core, tout se passe en ligne de commande — pas de barre de progression façon "Paramètres Windows". `Get-WindowsUpdate` permet de vérifier l'état avant et après.

---

## Activer SSH

Activer le serveur OpenSSH dès maintenant permet d'administrer `SRV01` confortablement depuis `PC01` pour la suite de ce chapitre, plutôt que de rester sur la console Hyper-V (voir le détail du fonctionnement d'OpenSSH au chapitre 12).

> [!NOTE] Souvent déjà installé sur Windows Server 2025
> Contrairement à Windows 11 client, la capacité **OpenSSH Server** est fréquemment **déjà présente** sur Windows Server 2025 (préinstallée ou ajoutée par une image d'évaluation à jour). Toujours vérifier son état avant de lancer l'installation, plutôt que de supposer qu'elle est absente.

```powershell
# Vérifier l'état actuel avant d'installer quoi que ce soit
Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Select-Object Name, State

# Installer uniquement si l'état est "NotPresent"
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

> [!WARNING] La règle de pare-feu ne couvre que le profil Privé — pas Public
> La règle `OpenSSH-Server-In-TCP` (créée automatiquement avec la capacité, ou à défaut manuellement) n'est active que sur le profil réseau **Privé**. Or une carte réseau connectée à un switch Hyper-V interne est souvent classée **Public** par défaut, faute pour Windows de pouvoir confirmer qu'il s'agit d'un réseau de confiance (voir chapitre 9). Résultat : la règle existe et est activée, mais **ne s'applique pas** au profil actif — le port 22 reste bloqué, silencieusement (timeout à la connexion, pas "connection refused").
>
> Vérifier la règle et le profil actif, et corriger si besoin :
> ```powershell
> # La règle existe-t-elle, et sur quel(s) profil(s) s'applique-t-elle ?
> Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue |
>     Select-Object Direction, Action, Profile
>
> # Quel est le profil actif sur cette carte réseau ?
> Get-NetConnectionProfile
>
> # Si le profil actif est Public alors que la règle est scopée Privé : passer la carte en Privé
> Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private
> ```
> Si la règle elle-même est absente (rare, mais possible selon l'image), la créer avec `New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22`.
>
> [!TIP] Anticiper le prochain changement de profil
> Une fois `SRV01` promu contrôleur de domaine (plus loin dans ce chapitre), son profil réseau passera automatiquement en **Domaine** — un profil que la règle `OpenSSH-Server-In-TCP` (scopée Privé uniquement) ne couvre toujours pas. Pour éviter de retomber sur le même symptôme après la promotion, élargir directement la règle plutôt que de ne jouer que sur le profil :
> ```powershell
> Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Profile Domain,Private,Public
> ```

Depuis `PC01`, se connecter **par adresse IP**, pas par nom :

```cmd
ssh administrateur@192.168.3.1
```

> [!WARNING] Le nom `SRV01` n'est pas encore résolvable
> Aucun serveur DNS n'existe encore sur le réseau à ce stade (le rôle DNS n'est installé qu'à la section suivante, et le domaine n'existe pas avant la promotion). `ssh administrateur@SRV01` échouerait donc avec une erreur de résolution de nom — utiliser l'IP directement. Une fois `PC01` joint au domaine (plus loin dans ce chapitre), la résolution par nom fonctionnera normalement via le DNS intégré à Active Directory.

> [!TIP] Toute la suite de ce chapitre peut se faire via cette session SSH
> Une fois connecté, les commandes PowerShell qui suivent (rôles, promotion, DHCP, UO) peuvent être tapées directement dans cette session SSH depuis `PC01`, au lieu de rester sur la console Hyper-V de `SRV01`.

---

## Installation des rôles AD DS, DNS et DHCP

```powershell
# Installer le rôle Active Directory Domain Services + ses outils d'administration
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Installer le rôle DNS (généralement ajouté automatiquement lors de la promotion, mais peut être posé avant)
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Installer le rôle DHCP (configuré plus tard, une fois le domaine et les OU en place)
Install-WindowsFeature -Name DHCP -IncludeManagementTools
```

```powershell
# Vérifier les rôles installés
Get-WindowsFeature | Where-Object Installed -eq $true | Select-Object Name, DisplayName
```

> [!NOTE] `Install-WindowsFeature` pose le rôle, mais ne le configure pas
> Installer le rôle AD DS ne crée pas de domaine : c'est une étape **préalable**. Le domaine n'existe qu'après l'étape de **promotion** (`Install-ADDSForest`, ci-dessous). De même, installer le rôle DHCP ne crée aucune étendue tant qu'elle n'est pas explicitement définie — ce sera fait en toute fin de chapitre.

---

## Promotion en contrôleur de domaine

```powershell
# Le module ADDSDeployment fournit Install-ADDSForest (chargé automatiquement au premier appel,
# mais peut être importé explicitement)
Import-Module ADDSDeployment

# Créer une nouvelle forêt et promouvoir SRV01 en premier contrôleur de domaine
Install-ADDSForest `
    -DomainName "ad.fournil.lab" `
    -DomainNetbiosName "FOURNIL" `
    -DomainMode "Win2025" `
    -ForestMode "Win2025" `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "MotDePasseDSRM!2025" -AsPlainText -Force) `
    -Force:$true
```

| Paramètre | Rôle |
|-----------|------|
| `-DomainName` | Nom de domaine DNS complet (FQDN) de la forêt |
| `-DomainNetbiosName` | Nom court NetBIOS (compatibilité, affiché dans `FOURNIL\utilisateur`) |
| `-DomainMode` / `-ForestMode` | Niveau fonctionnel du domaine/de la forêt — `Win2025` pour le niveau le plus récent, disponible uniquement si tous les contrôleurs de domaine sont sous Windows Server 2025 |
| `-InstallDns` | Installe et configure automatiquement le rôle DNS pour le domaine |
| `-SafeModeAdministratorPassword` | Mot de passe du mode restauration des services d'annuaire (DSRM) — **distinct** du mot de passe Administrateur habituel |

> [!WARNING] Redémarrage automatique
> `Install-ADDSForest` redémarre automatiquement `SRV01` à la fin du processus — si la commande a été lancée depuis la session SSH ouverte plus haut, la connexion se coupe brutalement au redémarrage. C'est normal, il suffit de se reconnecter une fois le serveur revenu en ligne.

> [!DANGER] Ne jamais couper la VM pendant la finalisation
> Le premier démarrage après promotion (« Application des paramètres de l'ordinateur… ») crée la zone DNS, les enregistrements SRV, le pool RID et active ADWS. Vécu lors de la reconstruction du lab : un `Restart-VM -Force` (= coupure électrique) à ce moment a produit un DC **inutilisable** — zone `ad.fournil.lab` absente, service ADWS désactivé, erreurs SAM 16642 (« pool d'identificateurs dépeuplé »). Seule issue raisonnable en lab : réinstaller le serveur. Laisser `Install-ADDSForest` redémarrer seul, et attendre.

### Vérification post-promotion

```powershell
# Sur SRV01, une fois redémarré
Get-ADDomain
Get-ADForest
Get-Service DNS, NTDS, Netlogon, ADWS
Get-DnsClientServerAddress -InterfaceAlias Ethernet -AddressFamily IPv4   # doit afficher 127.0.0.1
Get-DnsServerZone                                                          # ad.fournil.lab et _msdcs.ad.fournil.lab
```

> [!NOTE] « Impossible de trouver un serveur par défaut avec les services Web Active Directory »
> Juste après le redémarrage, `Get-ADDomain` peut renvoyer cette erreur pendant une à deux minutes : le service **ADWS** (sur lequel reposent toutes les cmdlets `*-AD*`) démarre après NTDS. Attendre puis relancer. Si l'erreur persiste, vérifier que le DNS du serveur pointe bien sur `127.0.0.1` : les cmdlets localisent le DC via les enregistrements SRV du DNS.

Après la promotion, `SRV01` résout les noms Internet en interrogeant directement les serveurs racine. Pour plus de rapidité (et parce que certains réseaux filtrent ces requêtes), on déclare un **redirecteur** :

```powershell
Set-DnsServerForwarder -IPAddress 1.1.1.1
```

---

## Jonction d'un poste au domaine

Depuis `PC01` (terminal administrateur) :

```powershell
# Rejoindre le domaine ad.fournil.lab (demande les identifiants d'un compte autorisé à joindre des postes)
Add-Computer -DomainName "ad.fournil.lab" -Credential (Get-Credential "FOURNIL\Administrateur") -Restart
```

> [!WARNING] PC01 doit pouvoir résoudre le domaine en DNS
> La jonction au domaine échoue si `PC01` ne peut pas résoudre `ad.fournil.lab` en DNS — ce qui suppose que sa configuration réseau pointe vers `SRV01` comme serveur DNS (et non un DNS public). Vérifier avant la jonction :
> ```powershell
> Resolve-DnsName ad.fournil.lab
> Get-DnsClientServerAddress -InterfaceAlias "Ethernet"
> ```
> Si le DNS configuré n'est pas `SRV01`, le corriger avec `Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.3.1"` avant de relancer `Add-Computer`.

Une fois le redémarrage terminé, se connecter avec un compte du domaine (`FOURNIL\utilisateur`) confirme la jonction.

```powershell
# Vérifier l'appartenance au domaine
(Get-CimInstance Win32_ComputerSystem).Domain
(Get-CimInstance Win32_ComputerSystem).PartOfDomain
```

---

## Création d'UO, utilisateurs et groupes

Une **UO** (Unité d'Organisation) est un conteneur AD permettant de structurer les objets (utilisateurs, ordinateurs, groupes) et d'y appliquer des GPO spécifiques (chapitre 16).

```powershell
# Créer une structure d'UO
New-ADOrganizationalUnit -Name "Fournil" -Path "DC=ad,DC=fournil,DC=lab"
New-ADOrganizationalUnit -Name "Utilisateurs" -Path "OU=Fournil,DC=ad,DC=fournil,DC=lab"
New-ADOrganizationalUnit -Name "Ordinateurs" -Path "OU=Fournil,DC=ad,DC=fournil,DC=lab"
New-ADOrganizationalUnit -Name "Groupes" -Path "OU=Fournil,DC=ad,DC=fournil,DC=lab"

# Créer un utilisateur dans l'UO Utilisateurs
New-ADUser -Name "Stagiaire Fournil" `
    -SamAccountName "stagiaire" `
    -UserPrincipalName "stagiaire@ad.fournil.lab" `
    -Path "OU=Utilisateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab" `
    -AccountPassword (ConvertTo-SecureString "Fournil2026!" -AsPlainText -Force) `
    -Enabled $true

# Créer un groupe de sécurité (dans l'UO Groupes) et y ajouter l'utilisateur
New-ADGroup -Name "G-Boulangerie" -GroupScope Global -GroupCategory Security -Path "OU=Groupes,OU=Fournil,DC=ad,DC=fournil,DC=lab"
Add-ADGroupMember -Identity "G-Boulangerie" -Members "stagiaire"
```

```powershell
# Un compte d'administration des postes, séparé du compte utilisateur (moindre privilège, chap. 09/11)
New-ADOrganizationalUnit -Name "Admins" -Path "OU=Fournil,DC=ad,DC=fournil,DC=lab"
New-ADUser -Name "Admin Postes Stagiaire" -SamAccountName "adm.stagiaire" `
    -UserPrincipalName "adm.stagiaire@ad.fournil.lab" `
    -Path "OU=Admins,OU=Fournil,DC=ad,DC=fournil,DC=lab" `
    -AccountPassword (ConvertTo-SecureString "Fournil2026!" -AsPlainText -Force) -Enabled $true
New-ADGroup -Name "GG-Admins-Postes" -GroupScope Global -GroupCategory Security -Path "OU=Groupes,OU=Fournil,DC=ad,DC=fournil,DC=lab"
Add-ADGroupMember -Identity "GG-Admins-Postes" -Members "adm.stagiaire"
```

```powershell
# Vérifications
Get-ADUser -Identity "stagiaire" -Properties MemberOf
Get-ADGroupMember -Identity "G-Boulangerie"
```

### Que les nouveaux postes arrivent dans la bonne UO

Par défaut, un poste joint au domaine atterrit dans le conteneur `CN=Computers`, où **aucune GPO ne peut être liée** (ce n'est pas une UO). Deux solutions :

```powershell
# 1) Changer le conteneur par défaut des nouveaux ordinateurs (une fois pour toutes)
redircmp "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"

# 2) Ou déplacer chaque poste après jonction
Get-ADComputer PC01 | Move-ADObject -TargetPath "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"
```

On peut aussi choisir l'UO au moment de la jonction : `Add-Computer ... -OUPath "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"`.

> [!TIP] En production : `-ChangePasswordAtLogon $true`
> Forcer le changement de mot de passe à la première connexion évite qu'un compte reste durablement avec un mot de passe défini (et donc connu) par l'administrateur qui l'a créé. **Dans le lab, on ne l'active pas** : tous les comptes gardent `Fournil2026!`, ce qui évite les blocages pendant la formation.

---

## Configuration du DHCP

Installer le rôle DHCP ne suffit pas : sans **étendue** (scope) définie, le serveur ne distribue aucune adresse. Cette étape arrive en dernier, une fois le domaine et la structure d'UO en place.

```powershell
# Autoriser le serveur DHCP dans l'annuaire AD (obligatoire pour qu'il puisse distribuer des baux)
Add-DhcpServerInDC -DnsName "SRV01.ad.fournil.lab" -IPAddress 192.168.3.1

# Créer une étendue pour le réseau vSwitch-Rennes
Add-DhcpServerv4Scope -Name "vSwitch-Rennes" -StartRange 192.168.3.100 -EndRange 192.168.3.200 -SubnetMask 255.255.255.0 -State Active

# Définir la passerelle (l'hôte, voir chapitre 1) et le DNS (SRV01) distribués aux clients de cette étendue
Set-DhcpServerv4OptionValue -ScopeId 192.168.3.0 -Router 192.168.3.254 -DnsServer 192.168.3.1 -DnsDomain "ad.fournil.lab"
```

> [!WARNING] Un DHCP non autorisé dans AD ne distribue rien
> Sur un contrôleur de domaine, un serveur DHCP doit être explicitement **autorisé** (`Add-DhcpServerInDC`) dans l'annuaire avant de pouvoir répondre aux requêtes des clients — une protection contre les serveurs DHCP non approuvés (rogue DHCP) sur le réseau.

```powershell
# Vérifier l'étendue et les baux distribués
Get-DhcpServerv4Scope
Get-DhcpServerv4Lease -ScopeId 192.168.3.0
```

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> **Installation Server Core (SRV01)**
> - `New-VM -Generation 2 -SwitchName "vSwitch-Rennes"` → ISO "(Server Core)", pas "(Desktop Experience)"
>
> **Préparation (`sconfig`)**
> - Renommage (2) → IP fixe + DNS provisoire 1.1.1.1 (8) → hostname/ipconfig pour vérifier
> - Sans DNS, Windows Update ne résout rien
>
> **Mise à jour**
> - `Install-Module PSWindowsUpdate` → `Install-WindowsUpdate -AcceptAll -AutoReboot`
>
> **Activer SSH**
> - `Get-WindowsCapability` d'abord (souvent déjà Installed sur WS2025) → `Start-Service sshd`
> - Règle OpenSSH-Server-In-TCP scopée Privé uniquement → vérifier `Get-NetConnectionProfile`
> - Carte sur vSwitch interne = souvent Public par défaut → `Set-NetConnectionProfile -NetworkCategory Private`
> - Se connecter par IP (192.168.3.1) : pas encore de DNS pour résoudre "SRV01"
>
> **Rôles**
> - `Install-WindowsFeature -Name AD-Domain-Services,DNS,DHCP -IncludeManagementTools`
>
> **Promotion en contrôleur de domaine**
> - `Install-ADDSForest -DomainName ad.fournil.lab -DomainMode Win2025 -ForestMode Win2025 -InstallDns:$true`
> - Redémarrage automatique attendu · mot de passe DSRM distinct
>
> **Jonction d'un poste (PC01)**
> - Le DNS du poste DOIT pointer vers SRV01 avant la jonction
> - `Add-Computer -DomainName ad.fournil.lab -Credential ... -Restart`
>
> **Structure AD**
> - `New-ADOrganizationalUnit` → `New-ADUser` → `New-ADGroup` → `Add-ADGroupMember`
> - -ChangePasswordAtLogon $true pour les comptes créés en production (pas dans le lab)
>
> **DHCP (en dernier, une fois le domaine et les UO en place)**
> - `Add-DhcpServerInDC` (autorisation obligatoire sur un DC) → `Add-DhcpServerv4Scope`
