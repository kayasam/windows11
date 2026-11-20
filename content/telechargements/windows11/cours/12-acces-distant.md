# 16. Administrer SRV01 depuis PC01

Le but est de choisir le bon accès selon la tâche. Dans le TP, tu gardes le même scénario : depuis `PC01`, vérifier l’état de DNS et DHCP sur `SRV01`. Les autres accès sont présentés en démos courtes.

**Prépare le lab.** `PC01` est joint à `ad.fournil.lab`, `SRV01` est démarré et les deux VM sont sur `vSwitch-Rennes`. Utilise le compte autorisé fourni pour le lab.

| Je veux… | J’utilise… | Port TCP à repérer |
| --- | --- | --- |
| Vérifier des services en PowerShell | WinRM | 5985 dans le lab, 5986 en HTTPS |
| Ouvrir le bureau du serveur | RDP | 3389 |
| Ouvrir un terminal | SSH | 22 |
| Lire les événements du serveur | Observateur d’événements sur RPC | 135 pour trouver le service, puis ports négociés |
| Ouvrir un dossier partagé | SMB | 445 |
| Gérer une zone DNS avec une console | RSAT sur `PC01` | Selon la console. Pour cette démo DNS, commence par RPC, port 135 |
| Aider une personne sur sa session | Assistance rapide | HTTPS sortant, 443 |

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

Sur **SRV01**, en Windows PowerShell :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 5985 -ErrorAction SilentlyContinue
```

Sur **PC01**, ouvre Windows PowerShell. `Test-WSMan` doit afficher une réponse contenant `ProductVendor`. Entre ensuite dans la session avec le compte autorisé du lab.

```powershell
Test-WSMan srv01.ad.fournil.lab
Enter-PSSession -ComputerName srv01.ad.fournil.lab -Credential (Get-Credential)
```

L’invite affiche le nom de **SRV01** entre crochets. Exécute `hostname` et `Get-Service DNS, DHCPServer`, relève les états, puis tape `Exit-PSSession`. Relance `hostname` pour vérifier ton retour sur **PC01**.

![Capture du lab. La première tentative est refusée. Avec un compte autorisé, la session s’ouvre et DNS et DHCP affichent Running.](https://cours.kaya.ovh/windows11/assets/captures/w11-12-enter-pssession-srv01.png)

## 2. RDP · Ouvrir le bureau du serveur

Sur **SRV01**, dans **Gestionnaire de serveur → Serveur local → Bureau à distance**, clique sur l’état affiché. Si le formateur a prévu la démo, sélectionne **Autoriser les connexions à distance à cet ordinateur** et laisse l’authentification au niveau du réseau activée. Contrôle l’écoute sur **SRV01** :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 3389 -ErrorAction SilentlyContinue
```

Sur **PC01**, tape `Test-NetConnection srv01.ad.fournil.lab -Port 3389`. Si `TcpTestSucceeded` vaut `True`, ouvre `mstsc`, saisis `srv01.ad.fournil.lab` et connecte-toi. Dans le bureau distant, `hostname` doit afficher `SRV01`. Déconnecte-toi après la démo.

## 3. SSH · Ouvrir un terminal

Sur **SRV01**, vérifie que le serveur OpenSSH écoute :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue
```

Sur **PC01**, teste `Test-NetConnection srv01.ad.fournil.lab -Port 22`. Pour ouvrir la session, remplace `utilisateur` par le compte autorisé pour OpenSSH.

```powershell
ssh -l 'FOURNIL\utilisateur' srv01.ad.fournil.lab
```

À la première connexion, compare l’empreinte avec celle que fournit le formateur. Si SSH dit que la clé a changé, arrête-toi et fais confirmer l’identité du serveur. Dans le terminal distant, teste `hostname` puis tape `exit`.

![Capture du lab. La session SSH est ouverte et hostname renvoie SRV01.](https://cours.kaya.ovh/windows11/assets/captures/w11-12-ssh-srv01.png)

## 4. RPC · Consulter les événements à distance

Sur **SRV01**, vérifie le port d’entrée RPC :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 135 -ErrorAction SilentlyContinue
```

Sur **PC01**, teste `Test-NetConnection srv01.ad.fournil.lab -Port 135`. Ouvre `eventvwr.msc`, fais un clic droit sur **Observateur d’événements (local) → Se connecter à un autre ordinateur**, puis saisis `srv01.ad.fournil.lab`. Ouvre **Journaux Windows → Système**. Le port 135 permet de repérer le service RPC. Si ce premier test réussit et que la console échoue, fais vérifier les droits et les règles de pare-feu de gestion distante des journaux, ainsi que les ports RPC négociés.

## 5. SMB · Accéder au dossier Commun

Sur **SRV01**, vérifie l’écoute SMB :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 445 -ErrorAction SilentlyContinue
```

Sur **PC01**, teste `Test-NetConnection srv01.ad.fournil.lab -Port 445`, puis ouvre `\\SRV01\Commun` dans l’Explorateur. Le dossier doit s’ouvrir si le partage du TP GPO existe et si le compte a les droits du partage et du dossier.

## 6. RSAT · Administrer DNS depuis PC01

RSAT fournit les **consoles d’administration** sur `PC01`. Chaque console s’appuie sur ses propres services. Pour la démo, installe seulement **RSAT : outils du serveur DNS** via **Paramètres → Fonctionnalités facultatives**. Si cette entrée est difficile à trouver, recherche **Fonctionnalités facultatives** depuis Démarrer. En Windows PowerShell administrateur sur **PC01**, tu peux aussi exécuter :

```powershell
Add-WindowsCapability -Online -Name Rsat.Dns.Tools~~~~0.0.1.0
```

Sur **SRV01**, contrôle le premier port utilisé pour joindre la gestion DNS à distance :

```powershell
Get-NetTCPConnection -State Listen -LocalPort 135 -ErrorAction SilentlyContinue
```

Sur **PC01**, lance `dnsmgmt.msc`, connecte la console DNS à `SRV01` et ouvre **Zones de recherche directe → ad.fournil.lab**. Vérifie que les enregistrements s’affichent. Le port TCP/UDP 53 sert aux **requêtes DNS**, tandis que la console s’appuie sur la gestion distante.

![Capture du lab. Dans les fonctionnalités facultatives, recherche RSAT et installe uniquement la console nécessaire.](https://cours.kaya.ovh/windows11/assets/captures/w11-11-acces-distant-1.png)

## 7. Assistance rapide · Aider quelqu’un sur sa session

Sur **PC01**, ouvre **Assistance rapide**. Pour la démo, l’aidant se connecte, fournit un code et la personne aidée autorise le partage d’écran. Les deux postes ont besoin d’Internet.

```powershell
Get-NetTCPConnection -State Listen -LocalPort 443 -ErrorAction SilentlyContinue
```

Ce contrôle montre les éventuels services HTTPS **locaux**. Assistance rapide utilise une connexion **sortante** vers Microsoft : l’outil peut fonctionner même si la commande ne retourne rien. Pour observer les connexions sortantes HTTPS pendant la démo, compare avec `Get-NetTCPConnection -State Established -RemotePort 443`. Plusieurs applications peuvent utiliser ce même port.

![Capture du lab. L’aidant choisit Aider quelqu’un et la personne aidée saisit le code dans la zone Aide.](https://cours.kaya.ovh/windows11/assets/captures/w11-11-acces-distant.png)

[Faire le TP guidé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide)

[Microsoft Learn · Get-NetTCPConnection](https://learn.microsoft.com/powershell/module/nettcpip/get-nettcpconnection?view=windowsserver2025-ps) · [Ports des services Windows](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/service-overview-and-network-port-requirements) · [RSAT](https://learn.microsoft.com/windows-server/remote/remote-server-administration-tools) · [Assistance rapide](https://learn.microsoft.com/windows/client-management/client-tools/quick-assist)
