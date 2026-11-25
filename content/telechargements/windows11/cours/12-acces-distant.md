# 12. Administrer SRV01 depuis PC01

> [!abstract] Deux machines, deux rôles
> **PC01** ouvre les connexions et **SRV01** les reçoit. Dans le TP, tu **configures** quatre accès : les consoles du serveur sur PC01 (**RSAT**), PowerShell à distance (**WinRM**), les consoles graphiques à distance (**RPC**) et **SSH avec une clé**. Les autres protocoles montrent comment la méthode change quand tu dois ouvrir un bureau ou accéder à un partage.

> [!note] État du lab après le TP 11
> `PC01` est joint à `ad.fournil.lab`. `SRV01` est démarré et les deux VM sont sur `vSwitch-Rennes`.

> [!tip] Identifiants du lab
> Dans la fenêtre d’identification de Windows, saisis `Administrateur@ad.fournil.lab` et le mot de passe fourni par le formateur.


| Je veux… | J’utilise… | Port TCP à repérer |
| --- | --- | --- |
| Vérifier des services en PowerShell | WinRM | 5985 dans le lab, 5986 en HTTPS |
| Ouvrir le bureau du serveur | RDP | 3389 |
| Ouvrir un terminal | SSH | 22 |
| Lire les événements du serveur | Observateur d’événements sur RPC | 135 pour trouver le service, puis ports négociés |
| Ouvrir un dossier partagé | SMB | 445 |
| Gérer une zone DNS avec une console | RSAT sur `PC01` | Selon la console. Pour cette démo DNS, commence par RPC, port 135 |
| Aider une personne sur sa session (repère) | Assistance rapide | HTTPS sortant, 443 |

## Le même réflexe à chaque fois

**Sur la machine qui reçoit la connexion**, regarde les ports TCP en écoute. Fais-le sur les deux VM pour comparer.

```powershell
hostname
Get-NetTCPConnection -State Listen |
    Sort-Object LocalPort |
    Select-Object LocalAddress, LocalPort, State
```

Une ligne `Listen` indique qu’un service attend des connexions sur cette adresse et ce port. **Depuis la machine qui appelle**, `Test-NetConnection -Port` indique si la connexion TCP atteint la cible. Le test TCP et l’ouverture de session répondent à deux questions différentes : « Puis-je atteindre le service ? » et « Mon compte a-t-il le droit d’y entrer ? ».

> [!example] Relevé du lab depuis l’hôte
> Le 20 novembre 2026, le test TCP a réussi vers `SRV01` sur **22, 135, 445 et 5985**, et vers `PC01` sur **135** parmi les mêmes ports testés. Le **3389** n’a répondu sur aucune des deux VM. Ce relevé mesure la joignabilité depuis l’hôte. Pour constater `Listen`, exécute la commande directement dans la VM.

## 1. WinRM · Vérifier DNS et DHCP

WinRM permet d’exécuter des commandes PowerShell sur un poste ou un serveur Windows à distance. Ici, tu vérifies l’état de DNS et DHCP depuis PC01.

Sur **SRV01**, en Windows PowerShell :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 5985 -ErrorAction SilentlyContinue
```

Sur **PC01**, ouvre Windows PowerShell. `Test-WSMan` doit afficher une réponse contenant `ProductVendor`. La commande suivante ouvre la fenêtre d’identification.

```powershell
Test-WSMan srv01.ad.fournil.lab
Enter-PSSession -ComputerName srv01.ad.fournil.lab -Credential 'Administrateur@ad.fournil.lab'
```

L’invite affiche le nom de **SRV01** entre crochets. Exécute `hostname` et `Get-Service DNS, DHCPServer`, relève les états, puis tape `Exit-PSSession`. Relance `hostname` pour vérifier ton retour sur **PC01**.

> [!warning] Dans l'autre sens, WinRM est fermé
> Windows **Server** accepte PowerShell à distance d'office, Windows **11** non : le service *Windows Remote Management (Gestion WSM)* est **arrêté**. Pour administrer PC01 depuis SRV01, on l'active une fois sur PC01, dans un Terminal **administrateur** :
> ```powershell
> Enable-PSRemoting -Force
> ```
> Ensuite, depuis SRV01 : `Invoke-Command -ComputerName PC01 -ScriptBlock { hostname }`.

![Extrait de la capture du lab. La session est ouverte sur SRV01. Les services DNS et DHCP affichent Running. La capture utilise la forme courte FOURNIL\Administrateur pour le même compte.](https://cours.kaya.ovh/windows11/assets/captures/w11-16-winrm-session-reussie.png)

## 2. RDP · Ouvrir le bureau du serveur

RDP ouvre une session graphique sur un autre ordinateur. Tu peux y utiliser les menus et les consoles de SRV01 comme devant son écran.

Sur **SRV01**, dans **Gestionnaire de serveur → Serveur local → Bureau à distance**, clique sur l’état affiché. Si le formateur a prévu la démo, sélectionne **Autoriser les connexions à distance à cet ordinateur** et laisse l’authentification au niveau du réseau activée. Contrôle l’écoute sur **SRV01** :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 3389 -ErrorAction SilentlyContinue
```

Sur **PC01**, tape `Test-NetConnection srv01.ad.fournil.lab -Port 3389`. Si `TcpTestSucceeded` vaut `True`, ouvre `mstsc`, saisis `srv01.ad.fournil.lab` et connecte-toi avec le compte de l’encadré. Dans le bureau distant, `hostname` doit afficher `SRV01`. Déconnecte-toi après la démo.

## 3. SSH · Ouvrir un terminal

SSH ouvre un terminal distant chiffré. Il sert à administrer une machine en ligne de commande, sous Linux comme sous Windows avec OpenSSH.

Sur **SRV01**, vérifie que le serveur OpenSSH écoute :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue
```

Sur **PC01**, teste `Test-NetConnection srv01.ad.fournil.lab -Port 22`. Pour SSH, la commande utilise la forme courte `FOURNIL\Administrateur` du même compte.

```powershell
ssh -l 'FOURNIL\Administrateur' srv01.ad.fournil.lab
```

À la première connexion, compare l’empreinte avec celle que fournit le formateur. Si SSH dit que la clé a changé, arrête-toi et fais confirmer l’identité du serveur. Dans le terminal distant, teste `hostname` puis tape `exit`.

![Capture du lab. La session SSH est ouverte et hostname renvoie SRV01.](https://cours.kaya.ovh/windows11/assets/captures/w11-12-ssh-srv01.png)

### Se connecter avec une clé plutôt qu'un mot de passe

Une **paire de clés** remplace le mot de passe : la clé **privée** reste sur PC01 et ne se partage jamais, la clé **publique** se copie sur le serveur.

```powershell
# Sur PC01 : créer la paire de clés (Entrée 3 fois dans le lab)
ssh-keygen -t ed25519
# → C:\Users\<profil>\.ssh\id_ed25519 (privée) et id_ed25519.pub (publique)
```

Pour un compte **administrateur**, OpenSSH pour Windows lit les clés autorisées dans **`C:\ProgramData\ssh\administrators_authorized_keys`** (pas dans `.ssh\authorized_keys`). Ce fichier ne doit être accessible qu'aux Administrateurs et à SYSTEM, sinon SSH l'ignore. Le TP montre comment y déposer la clé grâce à WinRM. Ensuite, `ssh administrateur@srv01.ad.fournil.lab` ne demande plus de mot de passe.

## 4. RPC · Consulter les événements à distance

RPC permet à une application d’appeler un service sur une autre machine. Ici, l’Observateur d’événements de PC01 demande les journaux à SRV01.

Sur **SRV01**, vérifie le port d’entrée RPC :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 135 -ErrorAction SilentlyContinue
```

Sur **PC01**, teste `Test-NetConnection srv01.ad.fournil.lab -Port 135`. Ouvre `eventvwr.msc`, fais un clic droit sur **Observateur d’événements (local) → Se connecter à un autre ordinateur**, puis saisis `srv01.ad.fournil.lab`. Ouvre **Journaux Windows → Système**. Le port 135 permet de repérer le service RPC. Si ce premier test réussit et que la console échoue, fais vérifier les droits et les règles de pare-feu de gestion distante des journaux, ainsi que les ports RPC négociés.

> [!warning] Vers un poste Windows 11, le pare-feu bloque RPC
> Pour ouvrir l'Observateur d'événements ou la Gestion de l'ordinateur **de PC01** depuis SRV01, il faut d'abord activer sur PC01 les groupes de règles du pare-feu (désactivés par défaut) : `wf.msc` → **Règles de trafic entrant** → trier par **Groupe** → sélectionner les règles → clic droit → **Activer la règle**.
> - **Gestion à distance des journaux des événements** (Observateur d'événements)
> - **Gestion des services à distance** (Services)
>
> ```powershell
> Enable-NetFirewallRule -DisplayGroup "Gestion à distance des journaux des événements", "Gestion des services à distance"
> ```
> Activer WinRM ne suffit pas : les consoles graphiques passent par **RPC**, pas par WinRM.

## 5. SMB · Accéder au dossier Commun

SMB permet d’ouvrir et de modifier des fichiers sur un partage réseau selon les droits du compte. Ici, tu accèdes au dossier Commun hébergé sur SRV01.

Sur **SRV01**, vérifie l’écoute SMB :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 445 -ErrorAction SilentlyContinue
```

Sur **PC01**, teste `Test-NetConnection srv01.ad.fournil.lab -Port 445`, puis ouvre `\\SRV01\Commun` dans l’Explorateur. Le dossier doit s’ouvrir si le partage du TP GPO existe et si le compte a les droits du partage et du dossier.

## 6. RSAT · Administrer DNS depuis PC01

RSAT fournit les consoles d’administration de Windows Server sur PC01. Tu peux par exemple consulter DNS, DHCP ou Active Directory dans une interface graphique.

Chaque console s’appuie sur ses propres services. Pour la démo, installe seulement **RSAT : outils du serveur DNS** via **Paramètres → Fonctionnalités facultatives**. Si cette entrée est difficile à trouver, recherche **Fonctionnalités facultatives** depuis Démarrer. En Windows PowerShell administrateur sur **PC01**, tu peux aussi exécuter :

```powershell
Add-WindowsCapability -Online -Name Rsat.Dns.Tools~~~~0.0.1.0
```

Sur **SRV01**, contrôle le premier port utilisé pour joindre la gestion DNS à distance :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 135 -ErrorAction SilentlyContinue
```

Sur **PC01**, lance `dnsmgmt.msc`, connecte la console DNS à `SRV01` et ouvre **Zones de recherche directe → ad.fournil.lab**. Vérifie que les enregistrements s’affichent. Le port TCP/UDP 53 sert aux **requêtes DNS**, tandis que la console s’appuie sur la gestion distante.

![Capture du lab. Dans les fonctionnalités facultatives, recherche RSAT et installe uniquement la console nécessaire.](https://cours.kaya.ovh/windows11/assets/captures/w11-11-acces-distant-1.png)

> [!note] Assistance rapide et Bureau à distance
> L’Assistance rapide permet de **partager une session existante** avec l’accord de la personne aidée. Avec **RDP**, le technicien ouvre une session sur la machine distante. L’Assistance rapide utilise une connexion HTTPS sortante vers Microsoft.

[Faire le TP guidé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide)

[Microsoft Learn · Get-NetTCPConnection](https://learn.microsoft.com/powershell/module/nettcpip/get-nettcpconnection?view=windowsserver2025-ps) · [Ports des services Windows](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/service-overview-and-network-port-requirements) · [RSAT](https://learn.microsoft.com/windows-server/remote/remote-server-administration-tools) · [Assistance rapide](https://learn.microsoft.com/windows/client-management/client-tools/quick-assist)
