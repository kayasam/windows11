---
title: "16. Administration et assistance à distance"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/12-acces-distant"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/12-acces-distant.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!abstract] Parcours TSSR
> À réaliser en J4, APRÈS le TP 15 : `PC02` existe alors et il est joint au domaine. On travaille depuis `PC01` vers `PC02`, avec le compte `FOURNIL\adm.stagiaire` (administrateur des postes, chapitre 10).
> Les sections marquées (bonus) sont facultatives : rien dans la suite n'en dépend.

> [!NOTE] Objectif
> Savoir intervenir sur un poste **sans se déplacer** : prendre la main sur son écran (Bureau à distance), lui envoyer des commandes (PowerShell à distance), ou aider un utilisateur (Assistance rapide).
>
> **Outils :** Paramètres, `mstsc.exe`, `services.msc`, Assistance rapide
> **Commandes à connaître :** `Test-NetConnection`, `Enable-PSRemoting`, `Invoke-Command`, `Enter-PSSession`

---

## Quel outil pour quel besoin ?

| Besoin | Outil | Port | Configuration sur le poste cible |
|--------|-------|------|-----------------------------------|
| Voir et utiliser l'écran d'un poste | **Bureau à distance** (`mstsc`) | TCP 3389 | Désactivé par défaut → à activer |
| Lancer des commandes sur un ou plusieurs postes | **PowerShell à distance** (WinRM) | TCP 5985 | Désactivé par défaut sur Windows 11 → `Enable-PSRemoting` |
| Aider un utilisateur devant son écran | **Assistance rapide** | Aucun (passe par Internet) | Rien : l'utilisateur donne un code |
| Se connecter comme sous Linux (bonus) | **OpenSSH** (`ssh`) | TCP 22 | Serveur SSH à installer sur un poste client |

---

## Bureau à distance (RDP)

Le **Bureau à distance** (Remote Desktop Protocol, port TCP **3389**) affiche l'écran du poste distant dans une fenêtre : on travaille comme si on était assis devant.

> [!WARNING] Il faut Windows 11 Pro (ou Entreprise/Éducation) sur le poste cible
> Windows 11 **Famille** peut se connecter à un autre poste, mais ne peut **pas recevoir** de connexion Bureau à distance.

### Activer le Bureau à distance (sur le poste cible)

**En graphique :** Paramètres → **Système** → **Bureau à distance** → passer le bouton sur **Activé** → **Confirmer**.

![w11-12-parametres-rdp-confirmation](https://cours.kaya.ovh/windows11/assets/captures/w11-12-parametres-rdp-confirmation.png)

Une fois activé, la flèche à droite du bouton affiche le **port** (3389) et l'option **authentification au niveau du réseau** (NLA), cochée par défaut : on la laisse cochée.

![w11-12-parametres-rdp-active](https://cours.kaya.ovh/windows11/assets/captures/w11-12-parametres-rdp-active.png)

> [!TIP] Le pare-feu s'ouvre tout seul
> En activant le bouton, Windows active aussi les règles de pare-feu **Bureau à distance** (port 3389). Rien d'autre à faire.

Ancienne méthode, toujours valable : `sysdm.cpl` → onglet **Utilisation à distance** → **Autoriser les connexions à distance à cet ordinateur**.

![w11-10-acces-distant-1](https://cours.kaya.ovh/windows11/assets/captures/w11-10-acces-distant-1.png)

**En PowerShell** (Terminal administrateur, sur le poste cible) :

```powershell
# 1 = Bureau à distance désactivé, 0 = activé (la valeur est « à l'envers » : fDeny = refuser)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0

# Ouvrir le pare-feu (le bouton des Paramètres le fait tout seul, pas cette commande)
Enable-NetFirewallRule -DisplayGroup "Bureau à distance"
```

**Vérifier depuis un autre poste** que le port répond :

```powershell
Test-NetConnection PC02 -Port 3389
# TcpTestSucceeded : False  → Bureau à distance désactivé (ou pare-feu fermé)
# TcpTestSucceeded : True   → prêt
```

### Qui a le droit de se connecter ?

Deux groupes **locaux** du poste cible :

| Groupe local | Qui y met-on ? |
|--------------|----------------|
| **Administrateurs** | Déjà autorisés, rien à faire. Sur le lab : `GG-Admins-Postes`, donc `adm.stagiaire` (GPO du chapitre 11) |
| **Utilisateurs du Bureau à distance** | Les comptes **non administrateurs** à autoriser |

**En graphique :** Paramètres → Système → Bureau à distance → **Utilisateurs du Bureau à distance**. La fenêtre rappelle que les administrateurs ont **déjà** accès :

![w11-12-utilisateurs-bureau-a-distance](https://cours.kaya.ovh/windows11/assets/captures/w11-12-utilisateurs-bureau-a-distance.png)

**Ajouter…** → taper le nom du compte → **Vérifier les noms** (le nom est souligné s'il existe dans le domaine) → **OK**.

![w11-12-rdp-ajouter-test-vendeur](https://cours.kaya.ovh/windows11/assets/captures/w11-12-rdp-ajouter-test-vendeur.png)

![w11-12-utilisateurs-bureau-a-distance-ok](https://cours.kaya.ovh/windows11/assets/captures/w11-12-utilisateurs-bureau-a-distance-ok.png)

**En PowerShell** (sur le poste cible) :

```powershell
Add-LocalGroupMember -Group "Utilisateurs du Bureau à distance" -Member "FOURNIL\test.vendeur"
Get-LocalGroupMember -Group "Utilisateurs du Bureau à distance"
```

### Se connecter avec `mstsc`

Sur le poste de l'administrateur : menu Démarrer → **Connexion Bureau à distance** (ou `Win + R` → `mstsc`). Taper le nom du poste → **Connexion**.

![w11-12-mstsc-ordinateur-pc02](https://cours.kaya.ovh/windows11/assets/captures/w11-12-mstsc-ordinateur-pc02.png)

Windows propose le compte de la session en cours. Pour en utiliser un autre : **Autres choix** → **Utiliser un autre compte**, puis saisir `FOURNIL\nom` et le mot de passe.

![w11-12-mstsc-identifiants](https://cours.kaya.ovh/windows11/assets/captures/w11-12-mstsc-identifiants.png)

> [!WARNING] Une seule session à la fois sur Windows 11
> Si quelqu'un est déjà connecté sur le poste, `mstsc` prévient qu'il sera **déconnecté** :
>
> ![w11-12-mstsc-autre-utilisateur-connecte](https://cours.kaya.ovh/windows11/assets/captures/w11-12-mstsc-autre-utilisateur-connecte.png)
>
> Sur le poste cible, l'utilisateur voit cette demande. Sans réponse, **il est déconnecté au bout de 30 secondes** (ses programmes restent ouverts, il retrouve sa session en se reconnectant) :
>
> ![w11-12-pc02-autoriser-connexion](https://cours.kaya.ovh/windows11/assets/captures/w11-12-pc02-autoriser-connexion.png)
>
> Sur un poste en production, on **prévient toujours l'utilisateur** avant de se connecter. (Windows Server, lui, accepte deux sessions d'administration en même temps.)

Une fois connecté, la barre en haut de l'écran rappelle le nom du poste distant. On vérifie où l'on est et sous quel compte :

![w11-12-mstsc-session-pc02](https://cours.kaya.ovh/windows11/assets/captures/w11-12-mstsc-session-pc02.png)

> [!TIP] Fermer proprement : se déconnecter, pas la croix
> La **croix** de la barre bleue **déconnecte** seulement : la session reste ouverte sur le poste distant (et le bloque pour les autres). Pour la fermer : menu Démarrer → compte → **Se déconnecter**, ou taper `logoff` dans une invite de commandes.

| Option `mstsc` | Rôle |
|-----------------|------|
| `/v:<ordinateur>` | Poste à joindre : `mstsc /v:PC02` |
| `/w:<largeur> /h:<hauteur>` | Taille de la fenêtre |
| `/admin` | (Serveurs) se connecter à la session d'administration |

### Windows App et les autres clients

| Client | Usage | Statut |
|--------|-------|--------|
| `mstsc.exe` (Connexion Bureau à distance) | Se connecter à un PC ou un serveur | ✅ Intégré et supporté |
| Application « Bureau à distance » (Store) | AVD, Windows 365 | ❌ Retirée (mai 2025) |
| Client MSRDC (MSI) | AVD, Windows 365 | ❌ Fin de support (mars 2026) |
| **Windows App** | PC cloud Windows 365, Azure Virtual Desktop | ✅ Remplaçant officiel |

---

## PowerShell à distance (WinRM)

**WinRM** (*Windows Remote Management*, port **5985**) est le service qui permet d'envoyer des commandes PowerShell à un autre poste, **sans ouvrir son écran**. Avantage : une seule commande peut interroger **plusieurs** postes.

| Poste | WinRM par défaut (constaté sur le lab) |
|-------|-----------------------------------------|
| Windows Server 2025 (`SRV01`) | **Actif** |
| Windows 11 (`PC01`, `PC02`) | **Arrêté**, démarrage manuel → à activer |

### Voir l'état du service

**En graphique :** `services.msc` → tout en bas de la liste : **Windows Remote Management (Gestion WSM)**. La colonne *État* est vide (= arrêté), démarrage *Manuel*.

![w11-12-services-winrm-arrete](https://cours.kaya.ovh/windows11/assets/captures/w11-12-services-winrm-arrete.png)

> [!NOTE] Nom non traduit
> Sur la version testée (26300), le service garde son nom **anglais** : il faut le chercher à la lettre **W**, pas à « Gestion à distance ».

**En PowerShell :**

```powershell
Get-Service WinRM          # sur le poste lui-même
Test-WSMan PC02            # depuis un autre poste : erreur rouge = WinRM ne répond pas
Test-WSMan SRV01           # réponse avec « wsmid » et « ProductVendor : Microsoft Corporation » = OK
```

### Activer PowerShell à distance (sur le poste cible)

Il n'y a **pas de case à cocher** dans les Paramètres : on utilise **une** commande, dans un **Terminal (administrateur)** (`Win + X` → Terminal (administrateur)) :

```powershell
Enable-PSRemoting -Force
```

![w11-12-enable-psremoting](https://cours.kaya.ovh/windows11/assets/captures/w11-12-enable-psremoting.png)

En une commande : le service WinRM démarre et passe en **automatique**, l'**écouteur** HTTP (port 5985) est créé et la **règle de pare-feu** est ouverte (profils Domaine et Privé).

> [!TIP] Sur tout un parc : une GPO (bonus)
> *Configuration ordinateur → Stratégies → Modèles d'administration → Composants Windows → Gestion à distance de Windows (WinRM) → Service WinRM → **Autoriser la gestion à distance du serveur via WinRM*** + service *Gestion à distance de Windows* en **Automatique** + règle de pare-feu prédéfinie **Gestion à distance de Windows**.

### Envoyer des commandes

Deux commandes suffisent :

| Commande | Quand l'utiliser |
|----------|------------------|
| `Invoke-Command` | Lancer **une** commande, sur **un ou plusieurs** postes, et récupérer le résultat |
| `Enter-PSSession` | « Entrer » dans le poste distant pour taper plusieurs commandes, puis `Exit-PSSession` |

```powershell
# Depuis PC01, connecté en FOURNIL\adm.stagiaire
Invoke-Command -ComputerName PC02 -ScriptBlock { hostname; whoami }
# PC02
# fournil\adm.stagiaire
```

Aucun mot de passe n'est demandé : dans un domaine, Windows présente le **ticket Kerberos** de la session ouverte. Il suffit que le compte soit **administrateur** du poste visé (c'est le cas d'`adm.stagiaire` sur les postes).

> [!WARNING] « Accès refusé » : le compte n'est pas administrateur de la cible
> `adm.stagiaire` administre les **postes**, pas le **serveur** : vers `SRV01`, la connexion est refusée.
>
> ![w11-12-enter-pssession-acces-refuse](https://cours.kaya.ovh/windows11/assets/captures/w11-12-enter-pssession-acces-refuse.png)
>
> On ajoute alors `-Credential` avec un compte qui a les droits. Une fenêtre demande le mot de passe :
>
> ![w11-12-enter-pssession-credential](https://cours.kaya.ovh/windows11/assets/captures/w11-12-enter-pssession-credential.png)

Dans la session distante, l'invite commence par **`[SRV01]:`** : chaque commande s'exécute sur le serveur. `Exit-PSSession` ramène sur le poste local.

![w11-12-enter-pssession-srv01](https://cours.kaya.ovh/windows11/assets/captures/w11-12-enter-pssession-srv01.png)

```powershell
Enter-PSSession SRV01 -Credential FOURNIL\Administrateur
[SRV01]: PS> Get-Service DHCPServer, DNS
[SRV01]: PS> Exit-PSSession
```

> [!NOTE] Hors domaine (pour mémoire)
> Entre deux postes en groupe de travail, Kerberos n'est pas disponible : il faut déclarer le poste distant dans `TrustedHosts` côté client et toujours donner `-Credential`. Dans ce cours, tout est dans le domaine : on n'en a pas besoin.

### WinRS — invite de commandes à distance (bonus)

`winrs` passe aussi par WinRM, mais lance des commandes **CMD** (texte) au lieu de PowerShell :

```cmd
winrs -r:PC02 ipconfig
winrs -r:SRV01 -u:FOURNIL\Administrateur -p:MotDePasse hostname
```

Sans `-u`/`-p` vers `SRV01`, on obtient le même « Accès refusé » qu'avec `Enter-PSSession`.

---

## OpenSSH (bonus)

**SSH** (port **22**) est le standard d'administration à distance des serveurs Linux. Windows l'intègre aussi : le **client** `ssh` est installé par défaut sur Windows 11, et le **serveur** tourne déjà sur `SRV01` (chapitre 10).

```powershell
ssh administrateur@SRV01
```

À la **première** connexion, SSH affiche l'empreinte du serveur et demande s'il faut lui faire confiance : taper **`yes`** en entier (pas seulement `y`), puis le mot de passe. Par défaut, on arrive dans une invite **cmd** ; `exit` pour revenir.

![w11-12-ssh-srv01](https://cours.kaya.ovh/windows11/assets/captures/w11-12-ssh-srv01.png)

**Avoir PowerShell au lieu de cmd** (sur `SRV01`, une seule fois) :

```powershell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
```

**Installer le serveur SSH sur un poste Windows 11** (il n'y est pas par défaut) : Paramètres → Système → **Fonctionnalités facultatives** → Afficher les fonctionnalités → *Serveur OpenSSH*, ou :

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service sshd -StartupType Automatic
Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Profile Domain,Private,Public
```

> [!WARNING] La règle de pare-feu SSH n'est ouverte que pour le profil Privé
> Un poste du domaine est en profil **Domaine** : sans la dernière commande, la connexion échoue en **délai d'attente dépassé**.

> [!NOTE] Pour aller plus loin (hors programme)
> Connexion par **clé** au lieu du mot de passe (`ssh-keygen`, puis fichier `C:\ProgramData\ssh\administrators_authorized_keys` pour un compte administrateur), et PowerShell 7 à distance par SSH (`Enter-PSSession -HostName`, PowerShell 7 des deux côtés et ligne `Subsystem powershell` dans `sshd_config`). Pratique courante en environnement mixte Windows/Linux.

---

## Assistance rapide (Quick Assist)

L'**Assistance rapide** est installée sur Windows 11. Elle sert à **aider un utilisateur** : voir son écran, et si il l'accepte, en prendre le contrôle. Ouverture : menu Démarrer → taper **Assistance rapide**, ou `Win + Ctrl + Q`.

![w11-11-acces-distant](https://cours.kaya.ovh/windows11/assets/captures/w11-11-acces-distant.png)

| Zone | Qui l'utilise | Ce qu'il fait |
|------|---------------|---------------|
| **Aide** | L'utilisateur qui a un problème | Saisit le **code à 6 caractères** donné par le technicien, puis accepte le partage |
| **Aider quelqu'un** | Le technicien | Se connecte avec un **compte Microsoft** et obtient un code à transmettre |

![Une session d’Assistance rapide — L’assistant génère un code à six chiffres. La personne aidée le saisit pour ouvrir une session via le relais Microsoft.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-12-assistance-rapide.svg)

En cliquant sur **Aider quelqu'un**, Windows demande un compte Microsoft :

![w11-12-assistance-rapide-compte-microsoft](https://cours.kaya.ovh/windows11/assets/captures/w11-12-assistance-rapide-compte-microsoft.png)

> [!NOTE] Message « énumérer vos clés d'accès ? »
> Au premier clic sur *Aider quelqu'un*, Windows peut demander s'il faut laisser l'Assistance rapide « énumérer vos clés d'accès ». Répondre **Non** suffit.

Aucun port à ouvrir : la connexion passe par un **relais Microsoft** sur Internet. Ça marche donc entre deux réseaux différents, sans VPN.

> [!WARNING] Arnaques au faux support technique
> Les escrocs (« Microsoft a détecté un virus sur votre PC, donnez-moi le code ») utilisent **exactement** cet outil. Message à faire passer aux utilisateurs : *on ne donne un code d'Assistance rapide qu'à une personne du support qu'on a soi-même appelée.*

### Remote Help : la version entreprise (bonus)

**Remote Help** (module payant d'Intune) reprend le même principe avec ce qui manque à l'Assistance rapide :

| | Assistance rapide | Remote Help (Intune) |
|-|-------------------|----------------------|
| Coût | Gratuit, intégré | Licence |
| Technicien | N'importe quel compte Microsoft | Compte de l'entreprise, avec des **rôles** |
| Qui peut aider qui | Aucun contrôle | Contrôlé (groupes) |
| Journal des sessions | Non | Oui |
| Fenêtres UAC côté technicien | Non | Oui |

---

## RSAT — les consoles du serveur sur un poste

Les **RSAT** (*Remote Server Administration Tools*) installent sur un poste Windows 11 les consoles du serveur (Utilisateurs et ordinateurs AD, DNS, DHCP, Gestion des stratégies de groupe). On administre ainsi `SRV01` **sans ouvrir de session dessus**, ce qui est la bonne pratique en entreprise.

Dans ce cours, leur installation est **facultative** et présentée au chapitre 11 (≈ 10 minutes de téléchargement par Windows Update). Rappel :

**En graphique :** Paramètres → Système → **Fonctionnalités facultatives** → **Afficher les fonctionnalités** → rechercher `RSAT`.

![w11-11-acces-distant-1](https://cours.kaya.ovh/windows11/assets/captures/w11-11-acces-distant-1.png)

```powershell
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
Add-WindowsCapability -Online -Name "Rsat.Dns.Tools~~~~0.0.1.0"
Add-WindowsCapability -Online -Name "Rsat.DHCP.Tools~~~~0.0.1.0"
Add-WindowsCapability -Online -Name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
```

> [!NOTE] Internet obligatoire
> Les RSAT sont téléchargées depuis Windows Update. Ne pas redémarrer pendant l'installation.

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> **Bureau à distance (RDP, port 3389)**
> - Désactivé par défaut · Paramètres → Système → Bureau à distance → **Activé** (le pare-feu suit)
> - Autorisés : **Administrateurs** + groupe local **Utilisateurs du Bureau à distance**
> - `mstsc` → nom du poste · *Autres choix* pour changer de compte
> - Windows 11 : **une seule session** → l'utilisateur présent est déconnecté (prévenir avant !)
> - Fermer avec **Se déconnecter** / `logoff`, pas la croix
>
> **PowerShell à distance (WinRM, port 5985)**
> - Actif sur Windows Server, **arrêté** sur Windows 11 → `Enable-PSRemoting -Force` (Terminal administrateur)
> - `Invoke-Command -ComputerName PC02 -ScriptBlock { ... }` · `Enter-PSSession` / `Exit-PSSession`
> - Domaine = Kerberos, pas de mot de passe **si** le compte est admin de la cible ; sinon **Accès refusé** → `-Credential`
>
> **Assistance rapide**
> - **Aide** (l'utilisateur saisit le code) · **Aider quelqu'un** (le technicien, compte Microsoft)
> - Aucun port à ouvrir · attention aux arnaques au faux support
>
> **Bonus** : OpenSSH (`ssh administrateur@SRV01`, taper `yes`), WinRS, Remote Help, RSAT (chapitre 11)
