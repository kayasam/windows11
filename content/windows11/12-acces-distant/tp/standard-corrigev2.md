---
title: "TP 12. Administrer à distance : RSAT, WinRM, RPC et SSH — Correction"
aliases: ["windows11/12-acces-distant/tp-corrigev2"]
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/12-acces-distant"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/12-acces-distant-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/standard">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/standard-corrigev2" aria-current="page">Corrigé</a></nav>

**Mission** · Configurer quatre façons d'administrer à distance, puis vérifier qu'elles marchent :

| Partie | Outil | Sens | Ce que tu configures |
|---|---|---|---|
| A | **RSAT** | PC01 → SRV01 | Les consoles du serveur installées sur PC01 |
| B | **WinRM** | SRV01 → PC01 | PowerShell à distance sur le poste |
| C | **RPC** | SRV01 → PC01 | Le pare-feu du poste pour les consoles à distance |
| D | **SSH** | PC01 → SRV01 | Une connexion par **clé**, sans mot de passe |

**Avant de commencer** · `SRV01` et `PC01` démarrés, `PC01` joint au domaine, session `FOURNIL\Administrateur` sur les deux VM, serveur SSH démarré sur `SRV01` (TP 10).

> Essaie chaque question avant d'ouvrir **Afficher la correction**.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/)

---

## Partie A — RSAT : les consoles du serveur sur PC01

**A1.** Installer en graphique les outils RSAT AD DS, DNS et DHCP.

> [!success]- Afficher la correction — A1
> **Paramètres** → **Système** → **Fonctionnalités facultatives** → **Afficher les fonctionnalités** → **Oui** à l'invite UAC.
> Dans la recherche, tape `RSAT`, puis coche :
> - *RSAT : outils Active Directory Domain Services Directory et services LDS (Lightweight Directory Services)*
> - *RSAT : outils du serveur DNS*
> - *RSAT : outils du serveur DHCP*
>
> **Suivant** → **Ajouter**. L'avancement s'affiche dans la page des fonctionnalités facultatives.
>
> ![w11-11-acces-distant-1](https://cours.kaya.ovh/windows11/assets/captures/w11-11-acces-distant-1.png)
>
> En PowerShell (Windows PowerShell **administrateur**) :
> ```powershell
> Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
> Add-WindowsCapability -Online -Name Rsat.Dns.Tools~~~~0.0.1.0
> Add-WindowsCapability -Online -Name Rsat.DHCP.Tools~~~~0.0.1.0
> ```
> Les RSAT sont téléchargées depuis Windows Update : **Internet obligatoire**, environ 10 minutes. Ne pas redémarrer pendant l'installation.

**A2.** Où trouver les nouvelles consoles ?

> [!success]- Afficher la correction — A2
> Menu **Démarrer** → **Toutes les applications** → **Outils Windows**. On y retrouve *Utilisateurs et ordinateurs Active Directory*, *DNS* et *DHCP*.
> Raccourcis avec `Win + R` : `dsa.msc` (Active Directory), `dnsmgmt.msc` (DNS), `dhcpmgmt.msc` (DHCP).

**A3.** Retrouver `stagiaire`, l'enregistrement DNS de `PC01` et la plage DHCP, depuis `PC01`.

> [!success]- Afficher la correction — A3
> 1. **Utilisateurs et ordinateurs Active Directory** s'ouvre directement sur le domaine `ad.fournil.lab` : `stagiaire` est dans **Fournil → Utilisateurs**.
> 2. **DNS** : à l'ouverture, la console demande à quel serveur se connecter → **L'ordinateur suivant** → `srv01.ad.fournil.lab` → **OK**. Puis **Zones de recherche directe** → `ad.fournil.lab` : la ligne `PC01` est de type **Hôte (A)**, avec l'adresse IP de `PC01`.
> 3. **DHCP** : `srv01.ad.fournil.lab` apparaît dans la liste (sinon : clic droit sur **DHCP** → **Ajouter un serveur**). **IPv4** → l'étendue → **Pool d'adresses** : la plage configurée au TP 10 (`192.168.3.100` à `192.168.3.200` dans le lab).
>
> Les consoles s'ouvrent **avec le compte de la session** de `PC01` : c'est pour cela qu'on travaille en `FOURNIL\Administrateur`. Un compte sans droits peut lire l'annuaire, mais pas modifier le DNS ni le DHCP.

**A4.** Pourquoi les RSAT plutôt qu'une session sur `SRV01` ?

> [!success]- Afficher la correction — A4
> - On **ne travaille pas sur le contrôleur de domaine** : moins de risques d'erreur ou de mauvaise manipulation sur la machine la plus sensible du réseau.
> - On administre **depuis son poste**, sans ouvrir et fermer de session ailleurs.
> - Une console RSAT peut gérer **plusieurs serveurs** à la fois.

---

## Partie B — WinRM : PowerShell à distance

**B1.** `Test-WSMan srv01` sur PC01, puis `Test-WSMan PC01` sur SRV01.

> [!success]- Afficher la correction — B1
> - Sur `PC01`, `Test-WSMan srv01` répond (lignes `wsmid`, `ProductVendor : Microsoft Corporation`).
> - Sur `SRV01`, `Test-WSMan PC01` affiche une **erreur rouge** : *« La Gestion à distance de Windows ne peut pas terminer l'opération… »*.
>
> **Windows Server** a PowerShell à distance **activé d'office**, **Windows 11 non**.

**B2.** État du service WinRM sur PC01.

> [!success]- Afficher la correction — B2
> Dans `services.msc`, tout en bas (nom non traduit) : **Windows Remote Management (Gestion WSM)**. Colonne *État* **vide** = arrêté ; type de démarrage **Manuel**.
>
> ![w11-12-services-winrm-arrete](https://cours.kaya.ovh/windows11/assets/captures/w11-12-services-winrm-arrete.png)

**B3.** Activer PowerShell à distance sur PC01.

> [!success]- Afficher la correction — B3
> Il n'y a **pas de case à cocher** dans les Paramètres. Sur `PC01` : `Win + X` → **Terminal (administrateur)** → **Oui**, puis :
> ```powershell
> Enable-PSRemoting -Force
> ```
> ![w11-12-enable-psremoting](https://cours.kaya.ovh/windows11/assets/captures/w11-12-enable-psremoting.png)
>
> La commande démarre le service WinRM, le passe en **Automatique**, crée l'écouteur (port **5985**) et ouvre le pare-feu (groupe *Gestion à distance de Windows*). Sur `SRV01`, `Test-WSMan PC01` répond maintenant.

**B4.** `Invoke-Command` de SRV01 vers PC01 : un mot de passe est-il demandé ?

> [!success]- Afficher la correction — B4
> ```
> PC01
>
> Status   Name      DisplayName
> ------   ----      -----------
> Running  Spooler   Spouleur d'impression
> ```
> **Pas de mot de passe** : les deux machines sont dans le domaine, Windows présente le **ticket Kerberos** de la session. Et `FOURNIL\Administrateur` est membre des *Admins du domaine*, donc **administrateur de `PC01`** : c'est obligatoire pour PowerShell à distance.

**B5.** `Enter-PSSession` vers PC01.

> [!success]- Afficher la correction — B5
> ```powershell
> Enter-PSSession PC01
> [PC01]: PS C:\Users\Administrateur\Documents> hostname
> PC01
> [PC01]: PS C:\Users\Administrateur\Documents> Exit-PSSession
> PS C:\Users\Administrateur>
> ```
> L'invite commence par **`[PC01]:`** tant qu'on est dans la session distante. `Exit-PSSession` ramène sur `SRV01`.

---

## Partie C — RPC : les consoles graphiques à distance

**C1.** Observateur d'événements de SRV01 vers PC01 : que se passe-t-il ?

> [!success]- Afficher la correction — C1
> Sur `SRV01` : `eventvwr.msc` → clic droit sur **Observateur d'événements (local)** → **Se connecter à un autre ordinateur…** → **Autre ordinateur** : `PC01` → **OK**.
>
> La connexion **échoue** : le message indique en général que **le serveur RPC n'est pas disponible**.
>
> WinRM ne sert à rien ici : les consoles graphiques (Observateur d'événements, Gestion de l'ordinateur, Services) n'utilisent **pas** WinRM (port 5985) mais **RPC** : le port **135** pour trouver le service, puis un port choisi au moment de la connexion. Et sur Windows 11, le pare-feu bloque ces connexions par défaut.

**C2.** Activer les deux groupes de règles dans `wf.msc` sur PC01.

> [!success]- Afficher la correction — C2
> Sur `PC01` : `Win + R` → `wf.msc` → **Règles de trafic entrant**.
> 1. Clique sur l'en-tête de la colonne **Groupe** pour trier les règles par groupe.
> 2. Clique sur la première règle **Gestion à distance des journaux des événements**, puis **Maj + clic** sur la dernière du groupe (6 règles).
> 3. Clic droit → **Activer la règle** : l'icône devient verte.
> 4. Fais de même pour les 6 règles **Gestion des services à distance**.
>
> Autre méthode : dans le volet de droite, **Filtrer par groupe** → choisir le groupe, puis tout sélectionner (`Ctrl + A`) → **Activer la règle**.
>
> En PowerShell (administrateur, sur `PC01`) :
> ```powershell
> Enable-NetFirewallRule -DisplayGroup "Gestion à distance des journaux des événements", "Gestion des services à distance"
> ```
> Chaque groupe contient des règles pour le port 135 (*RPC-EPMAP*), pour les ports RPC choisis à la connexion (*RPC*) et pour les canaux nommés (*NP-Entrée*).

**C3.** Recommencer C1.

> [!success]- Afficher la correction — C3
> La connexion réussit : le titre de l'arborescence devient **Observateur d'événements (PC01)**. **Journaux Windows → Système** affiche les événements **de PC01**, lus depuis le serveur.

**C4.** Gestion de l'ordinateur de SRV01 vers PC01 : arrêter et redémarrer le Spouleur.

> [!success]- Afficher la correction — C4
> Sur `SRV01` : `compmgmt.msc` → clic droit sur **Gestion de l'ordinateur (local)** → **Se connecter à un autre ordinateur…** → `PC01` → **OK**.
> **Services et applications → Services** → **Spouleur d'impression** → **Arrêter**, puis **Démarrer** (barre d'outils ou clic droit).
>
> Vérification sur `PC01` : `Get-Service Spooler` → **Running**, ou `services.msc`.
>
> Toutes les parties de la console ne marchent pas forcément : *Gestion des disques*, par exemple, a besoin d'un autre groupe de règles (*Gestion des volumes à distance*). On n'ouvre que ce dont on a besoin.

**C5.** (bonus) Ouvrir ces règles sur les 35 postes.

> [!success]- Afficher la correction — C5
> Une **GPO** liée à l'UO des ordinateurs (TP 11) :
> *Configuration ordinateur → Stratégies → Paramètres Windows → Paramètres de sécurité → Pare-feu Windows Defender avec fonctions avancées de sécurité → … → **Règles de trafic entrant*** → clic droit → **Nouvelle règle** → **Prédéfinie** → *Gestion à distance des journaux des événements* → cocher les règles → **Autoriser la connexion**. Même chose pour *Gestion des services à distance*.

---

## Partie D — SSH avec une clé

**D1.** Première connexion SSH avec le mot de passe.

> [!success]- Afficher la correction — D1
> À la **toute première** connexion, SSH ne connaît pas encore le serveur et demande s'il doit lui faire confiance :
> ```
> The authenticity of host 'srv01.ad.fournil.lab (192.168.3.1)' can't be established.
> ED25519 key fingerprint is SHA256:…
> Are you sure you want to continue connecting (yes/no/[fingerprint])?
> ```
> On tape **`yes`** en entier, puis le mot de passe d'`Administrateur`. `hostname` affiche `SRV01`.
>
> ![w11-12-ssh-srv01](https://cours.kaya.ovh/windows11/assets/captures/w11-12-ssh-srv01.png)
>
> L'empreinte est enregistrée dans `.ssh\known_hosts` sur `PC01` : la question ne reviendra plus. Si un jour SSH signale que l'empreinte **a changé**, on s'arrête et on vérifie : le serveur a peut-être été réinstallé… ou ce n'est pas le bon serveur.

**D2.** Créer une paire de clés.

> [!success]- Afficher la correction — D2
> ```powershell
> ssh-keygen -t ed25519
> ```
> - *Enter file in which to save the key* → **Entrée** (emplacement par défaut).
> - *Enter passphrase* → **Entrée**, puis encore **Entrée** (pas de phrase de passe dans le lab).
>
> Deux fichiers sont créés dans le dossier **`.ssh`** de ton profil (par exemple `C:\Users\Administrateur\.ssh\`) :
>
> | Fichier | Rôle | Où va-t-il ? |
> |---|---|---|
> | `id_ed25519` | Clé **privée** | Reste **sur PC01**, ne se partage **jamais** |
> | `id_ed25519.pub` | Clé **publique** | Se copie sur les serveurs auxquels on veut se connecter |
>
> En entreprise, on protège la clé privée par une **phrase de passe** : si quelqu'un vole le fichier, il ne peut pas s'en servir.

**D3.** Déposer la clé publique sur SRV01.

> [!success]- Afficher la correction — D3
> Sur **PC01**, dans la session qui a créé la clé, exécute ce bloc. SSH demande le mot de passe du compte pour le premier dépôt.
>
> ```powershell
> $cle = Get-Content "$HOME\.ssh\id_ed25519.pub" -ErrorAction Stop
> $fichier = 'C:\ProgramData\ssh\administrators_authorized_keys'
> ssh Administrateur@srv01.ad.fournil.lab "powershell.exe -NoProfile -Command Add-Content -Path '$fichier' -Value '$cle' -Encoding ascii -ErrorAction Stop; icacls.exe '$fichier' /inheritance:r /grant:r '*S-1-5-32-544:F' '*S-1-5-18:F'"
> ```
>
> Sur **SRV01**, le bloc `Match Group administrators` de `C:\ProgramData\ssh\sshd_config` dirige OpenSSH vers `C:\ProgramData\ssh\administrators_authorized_keys`. Les deux SID de `icacls` désignent les **Administrateurs** et **SYSTEM**, quelle que soit la langue de Windows.

**D4.** Reconnexion.

> [!success]- Afficher la correction — D4
> ```powershell
> ssh -o PreferredAuthentications=publickey Administrateur@srv01.ad.fournil.lab hostname
> ```
>
> Si `hostname` renvoie `SRV01`, la clé fonctionne. Une demande de phrase secrète concerne la clé privée sur `PC01`.
>
> Si tu obtiens `Permission denied`, vérifie sur **SRV01** la présence de `administrators_authorized_keys`, la ligne `ssh-ed25519` et les droits du fichier avec `icacls`.

**D5.** (bonus) Une commande sans terminal interactif.

> [!success]- Afficher la correction — D5
> ```powershell
> ssh administrateur@srv01.ad.fournil.lab hostname
> SRV01
> ```
> La commande s'exécute sur `SRV01`, le résultat s'affiche sur `PC01` et la connexion se ferme. Avec une clé, il n'y a **aucun mot de passe à taper** : on peut l'utiliser dans un **script** ou une **tâche planifiée**. C'est la méthode habituelle pour administrer des serveurs Linux.

---

## Ce qu'il faut retenir

| Outil | Port | Activé par défaut sur Windows 11 ? | Comment l'activer sur le poste |
|---|---|---|---|
| RSAT | (selon la console) | Non installé | Paramètres → Fonctionnalités facultatives |
| WinRM | 5985 | **Non** | `Enable-PSRemoting -Force` (ou GPO) |
| RPC (consoles MMC) | 135 + ports choisis à la connexion | **Non** (pare-feu fermé) | `wf.msc` : groupes *Gestion à distance des journaux des événements*, *Gestion des services à distance* (ou GPO) |
| SSH | 22 | Client oui, serveur non | Serveur déjà présent sur Windows Server ; clé : `ssh-keygen` + `administrators_authorized_keys` |

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/standard)
