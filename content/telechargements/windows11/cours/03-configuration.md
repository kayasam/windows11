# 03. Configuration et personnalisation

> [!NOTE] Objectif
> Maîtriser l'interface Windows 11, gérer les comptes utilisateurs locaux, configurer une adresse IP fixe et manipuler les variables d'environnement.
>
> **Outils :** Paramètres, Panneau de configuration, lusrmgr.msc, ncpa.cpl, PowerShell
> **Commandes à connaître :** `New-LocalUser`, `New-NetIPAddress`, `[System.Environment]::SetEnvironmentVariable`

---

## Interface Windows 11

### Menu Démarrer

Le menu Démarrer de Windows 11 est **centré** par défaut (déplaçable à gauche via Paramètres → Personnalisation → Barre des tâches). Depuis la refonte 25H2, c'est **une seule page défilante** en trois zones :

![w11-03-menu-demarrer-26h2](https://cours.kaya.ovh/windows11/assets/captures/w11-03-menu-demarrer-26h2.png)

*Menu Démarrer de `PC01` (26H2) : Épinglé, Nos recommandations, Tout (vue Catégorie).*

- **Épinglé** : applications choisies par l'utilisateur — clic droit sur une app → **Épingler au menu Démarrer**. « Afficher tout » déplie la grille
- **Nos recommandations** : fichiers récents et applications suggérées. Masquable : Paramètres → Personnalisation → Accueil → désactiver les éléments recommandés (ou par GPO en entreprise)
- **Tout** : toutes les applications installées, en vue **Catégorie**, **Grille** ou **Liste** (menu « Affichage »)
- La **recherche** en haut indexe les applications, fichiers, paramètres et le web

> [!NOTE] Évolution entre les versions
> Jusqu'en 24H2, la liste complète des applications était sur une page séparée (« Toutes les applications »). Depuis 25H2, elle est intégrée en bas du menu, sous la section des recommandations.

> [!TIP] Raccourci clavier
> `Win` ouvre/ferme le menu Démarrer. Taper directement après `Win` lance une recherche.


### Snap Layouts
![w11-03-configuration-1](https://cours.kaya.ovh/windows11/assets/captures/w11-03-configuration-1.png)
Windows 11 introduit les **Snap Layouts** : des dispositions prédéfinies pour organiser plusieurs fenêtres à l'écran.

**Accès :** survoler le bouton Agrandir d'une fenêtre, ou appuyer sur `Win + Z`

```
Dispositions disponibles (sur 1920×1080) :
┌──┬──┐  ┌──┬──┬──┐  ┌──┬─────┐  ┌──────┬──┐
│  │  │  │  │  │  │  │  │     │  │      │  │
└──┴──┘  └──┴──┴──┘  └──┴─────┘  └──────┴──┘
 50/50    33/33/33    33 / 67       67 / 33
```

**Snap Groups** : Windows 11 mémorise les groupes de fenêtres snappées. En survolant l'icône d'une app dans la barre des tâches, on retrouve le groupe d'un clic.

| Raccourci | Action |
|-----------|--------|
| `Win + ←` / `Win + →` | Snap à gauche / droite (50/50) |
| `Win + Z` | Ouvrir les layouts |
| `Win + Haut` | Agrandir |
| `Win + Bas` | Réduire / restaurer |

### Bureaux virtuels

![w11-03-configuration-2](https://cours.kaya.ovh/windows11/assets/captures/w11-03-configuration-2.png)

Les **bureaux virtuels** permettent d'organiser les applications sur plusieurs espaces de travail distincts (ex : un bureau pour le travail, un pour la documentation).

| Raccourci | Action |
|-----------|--------|
| `Win + Tab` | Vue des tâches (voir tous les bureaux) |
| `Win + Ctrl + D` | Créer un nouveau bureau |
| `Win + Ctrl + →` / `←` | Passer d'un bureau à l'autre |
| `Win + Ctrl + F4` | Fermer le bureau actuel |

> [!TIP] Déplacer une fenêtre entre bureaux
> Dans la vue des tâches (`Win + Tab`), glisser-déposer une fenêtre sur le bureau de destination. Ou clic droit sur la fenêtre → Déplacer vers → Bureau X.

### Barre des tâches

![w11-03-configuration-3](https://cours.kaya.ovh/windows11/assets/captures/w11-03-configuration-3.png)
La barre des tâches de Windows 11 est simplifiée par rapport à Windows 10 : les icônes sont centrées, les menus contextuels ont été réduits.

**Personnalisations disponibles :** Paramètres → Personnalisation → Barre des tâches
- Positionnement : gauche ou centre
- Éléments : recherche, vue des tâches, widgets (l'ancien bouton « Conversation »/Chat a disparu avec Teams classique)
- Icônes d'application : toujours visibles ou masquées

---

## Paramètres vs Panneau de configuration

Windows 11 maintient deux interfaces de configuration qui coexistent :

| | **Paramètres** (`ms-settings:`) | **Panneau de configuration** (`control`) |
|-|--------------------------------|----------------------------------------|
| **Interface** | Moderne, tactile, épurée | Classique, Windows Vista/7 |
| **Tendance** | En cours de remplacement du Panneau | Progressivement vidé |
| **Accès** | `Win + I` | Recherche "Panneau" ou `control` |
![w11-03-configuration-4](https://cours.kaya.ovh/windows11/assets/captures/w11-03-configuration-4.png)
### Ce qui est encore dans le Panneau de configuration

Certaines fonctionnalités n'ont pas encore été migrées vers Paramètres :

| Fonction | Outil classique | Disponible dans Paramètres ? |
|----------|----------------|------------------------------|
| Comptes utilisateurs avancés | `lusrmgr.msc` | Partiellement |
| Programmes et fonctionnalités | `appwiz.cpl` | Partiellement (Applications) |
| Options d'alimentation avancées | `powercfg.cpl` | Partiellement |
| Options Internet | `inetcpl.cpl` | Non |
| Configuration IP avancée | `ncpa.cpl` | Partiellement |
| Gestion des couleurs | `colorcpl.exe` | Non |
| Sauvegarde et restauration (Windows 7) | `sdclt.exe` | Non — fonctionnalité héritée, remplacée par l'app **Sauvegarde Windows** + OneDrive (chap. 20) |
| Informations système | Panneau → Système | Oui : depuis 25H2, **Paramètres → Système → Informations système** (cartes ci-dessous) |

![w11-02-parametres-informations-26h2](https://cours.kaya.ovh/windows11/assets/captures/w11-02-parametres-informations-26h2.png)

*Paramètres → Système → Informations système sur `PC01` : stockage, mémoire, processeur, puis les spécifications de l'appareil (« Copier » pour un ticket).*

> [!TIP] Outil de recherche rapide
> Taper le nom d'un paramètre directement dans la recherche Windows — cela fonctionne autant pour les Paramètres modernes que pour les applets du Panneau de configuration.

---

## Gestion des comptes utilisateurs locaux

### La base SAM

Les comptes locaux sont stockés dans la **base SAM** (Security Accounts Manager), une ruche du registre Windows située dans `C:\Windows\System32\config\SAM`. Elle est chargée en mémoire au démarrage et verrouillée par le système — impossible de l'ouvrir directement avec regedit tant que Windows tourne.

```
C:\Windows\System32\config\SAM
        │
        ├── Comptes utilisateurs  (SID, nom, hash du mot de passe, état...)
        └── Groupes locaux        (Administrateurs, Utilisateurs, ...)
```

Chaque compte est identifié par un **SID** (Security Identifier) unique, de la forme `S-1-5-21-XXXXXXXXX-XXXXXXXXX-XXXXXXXXX-XXXX`. C'est le SID, et non le nom du compte, qui est utilisé en interne par Windows pour les permissions NTFS, les jetons d'accès et les journaux d'événements.

> [!TIP] Voir les SID
> ```powershell
> Get-LocalUser | Select-Object Name, SID
> ```

### Comptes et groupes

Il n'existe qu'**un seul type de compte** utilisateur local. Ce sont les **groupes d'appartenance** qui déterminent ce qu'un compte peut faire sur la machine :

| Groupe local | Droits conférés |
|--------------|----------------|
| **Administrateurs** | Accès complet : installation de logiciels, modification des paramètres système, gestion des autres comptes, accès à tous les fichiers |
| **Utilisateurs** | Utilisation courante : lancer des apps, modifier ses propres paramètres, accéder à son profil |
| **Opérateurs de sauvegarde** | Peut sauvegarder et restaurer des fichiers sans tenir compte des permissions NTFS |
| **Utilisateurs du Bureau à distance** | Peut ouvrir une session RDP sur la machine |

Un compte peut appartenir à **plusieurs groupes simultanément** — ses droits sont l'union de tous les groupes auxquels il appartient.

> [!WARNING] Bonnes pratiques
> En entreprise, les utilisateurs travaillent avec un compte membre uniquement du groupe **Utilisateurs** au quotidien. Seuls les administrateurs système ont leur compte dans le groupe **Administrateurs**. Un utilisateur dans le groupe Administrateurs peut contourner la plupart des contrôles de sécurité.

### Créer un compte utilisateur local

**Via Paramètres** (méthode simplifiée) :
Paramètres → Comptes → Autres utilisateurs → Ajouter un autre utilisateur

**Via Gestion de l'ordinateur** (méthode avancée) :
`lusrmgr.msc` → Utilisateurs → clic droit → Nouvel utilisateur
![w11-03-configuration-6](https://cours.kaya.ovh/windows11/assets/captures/w11-03-configuration-6.png)

**Via PowerShell** (méthode automatisable) :
```powershell
# Créer un compte standard
$mdp = ConvertTo-SecureString "Fournil2026!" -AsPlainText -Force
New-LocalUser -Name "employe1" -Password $mdp -FullName "Employé 1" -Description "Poste Fournil"

# Ajouter au groupe Utilisateurs (standard)
Add-LocalGroupMember -Group "Utilisateurs" -Member "employe1"

# Pour en faire un administrateur local
Add-LocalGroupMember -Group "Administrateurs" -Member "employe1"
```

### Gérer les comptes existants

```powershell
# Lister tous les comptes locaux
Get-LocalUser

# Lister les membres d'un groupe
Get-LocalGroupMember -Group "Administrateurs"
Get-LocalGroupMember -Group "Utilisateurs"

# Désactiver un compte
Disable-LocalUser -Name "employe1"

# Supprimer un compte
Remove-LocalUser -Name "employe1"
```

---

## Configuration réseau

### Architecture réseau du lab Fournil

```
Internet
    │
    │ (NAT Windows)
    │
┌───┴────────────────────┐
│  vEthernet (vSwitch-Rennes)   │  192.168.3.254  ← passerelle
│  Hôte Windows 11       │
└───┬────────────────────┘
    │
    │  Switch vSwitch-Rennes (192.168.3.0/24)
    ├──── PC01   192.168.3.10  ← poste admin (ce chapitre)
    ├──── SRV01  192.168.3.1   ← futur serveur AD
    └──── PC02   DHCP           ← futur poste cible
```

### Afficher la configuration réseau actuelle

**En PowerShell :**
```powershell
# Lister les adaptateurs réseau
Get-NetAdapter

# Afficher la configuration IP
Get-NetIPConfiguration

# Voir l'IP actuelle
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.PrefixOrigin -ne "WellKnown"}
```

**En graphique :** `ncpa.cpl` → clic droit sur l'adaptateur → Propriétés → TCP/IPv4

### Configurer une adresse IP fixe

Pour `PC01`, on attribue l'adresse `192.168.3.10/24` avec la passerelle `192.168.3.254`.

**En PowerShell :**
```powershell
# Récupérer le nom de l'adaptateur
$adaptateur = (Get-NetAdapter | Where-Object Status -eq "Up").Name

# Supprimer la configuration DHCP existante
Remove-NetIPAddress -InterfaceAlias $adaptateur -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $adaptateur -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue

# Configurer l'IP fixe
New-NetIPAddress -InterfaceAlias $adaptateur `
    -IPAddress "192.168.3.10" `
    -PrefixLength 24 `
    -DefaultGateway "192.168.3.254"

# Configurer le DNS (provisoire : 8.8.8.8 — sera remplacé par SRV01 au chapitre 10)
Set-DnsClientServerAddress -InterfaceAlias $adaptateur -ServerAddresses "8.8.8.8", "1.1.1.1"
```

**En graphique :**
1. `ncpa.cpl` → clic droit sur l'adaptateur Ethernet → **Propriétés**
2. Sélectionner **Protocole Internet version 4 (TCP/IPv4)** → Propriétés
3. Cocher **"Utiliser l'adresse IP suivante"**
4. Remplir : IP `192.168.3.10`, masque `255.255.255.0`, passerelle `192.168.3.254`
5. Cocher **"Utiliser l'adresse de serveur DNS suivante"** : `8.8.8.8`

![w11-03-configuration-7](https://cours.kaya.ovh/windows11/assets/captures/w11-03-configuration-7.png)

### Vérifier la connectivité

```powershell
# Ping vers la passerelle
Test-Connection -ComputerName 192.168.3.254 -Count 2

# Ping vers Internet
Test-Connection -ComputerName 8.8.8.8 -Count 2

# Résolution DNS
Resolve-DnsName google.fr
```

---

## Variables d'environnement

Les variables d'environnement sont des paires **clé=valeur** accessibles par tous les processus. Elles permettent aux applications de connaître leur contexte (profil utilisateur, chemins système, etc.) sans coder ces valeurs en dur.

### Portées des variables

| Portée | Durée de vie | Héritage |
|--------|-------------|---------|
| **Processus** | Durée du processus uniquement | Héritées du processus parent |
| **Utilisateur** | Persistante, liée au profil | Chargées à la connexion |
| **Système (Machine)** | Persistante, pour tous les utilisateurs | Chargées au démarrage |

Les variables **système** et **utilisateur** sont fusionnées à la connexion. En cas de conflit, la variable **utilisateur** l'emporte (sauf pour `PATH` qui est concaténé).

### Variables courantes

| Variable | Valeur typique | Description |
|----------|---------------|-------------|
| `COMPUTERNAME` | `PC01` | Nom de la machine |
| `USERNAME` | `admin` | Nom de l'utilisateur connecté |
| `USERPROFILE` | `C:\Users\admin` | Dossier du profil |
| `APPDATA` | `C:\Users\admin\AppData\Roaming` | Données d'application utilisateur |
| `TEMP` / `TMP` | `C:\Users\admin\AppData\Local\Temp` | Fichiers temporaires |
| `PATH` | `C:\Windows\System32;...` | Chemins des exécutables |
| `SystemRoot` | `C:\Windows` | Répertoire Windows |
| `ProgramFiles` | `C:\Program Files` | Applications 64 bits |
| `ProgramFiles(x86)` | `C:\Program Files (x86)` | Applications 32 bits |

### Afficher les variables

**En PowerShell :**
```powershell
# Toutes les variables d'environnement
Get-ChildItem Env:

# Une variable spécifique
$env:USERNAME
$env:PATH
```

**En CMD** (`cmd.exe` uniquement, ces commandes ne fonctionnent pas dans PowerShell) :
```cmd
set
echo %USERNAME%
```

### Créer ou modifier une variable

```powershell
# Variable de session uniquement (disparaît à la fermeture du terminal)
$env:FOURNIL_ENV = "lab"

# Variable utilisateur persistante
[System.Environment]::SetEnvironmentVariable("FOURNIL_ENV", "lab", "User")

# Variable système persistante (nécessite des droits admin)
[System.Environment]::SetEnvironmentVariable("FOURNIL_ENV", "lab", "Machine")

# Supprimer une variable
[System.Environment]::SetEnvironmentVariable("FOURNIL_ENV", $null, "User")
```

**En graphique :**
Paramètres → Système → Informations système → **Paramètres système avancés** → onglet Avancé → **Variables d'environnement**
![w11-03-configuration-10](https://cours.kaya.ovh/windows11/assets/captures/w11-03-configuration-10.png)
> [!WARNING] Modification du PATH
> Ne jamais écraser la variable `PATH` entière — cela rendrait la plupart des commandes inaccessibles. Toujours **ajouter** au PATH existant :
> ```powershell
> $ancien = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
> [System.Environment]::SetEnvironmentVariable("PATH", "$ancien;C:\MonDossier", "Machine")
> ```

---

## Récapitulatif

```
Interface Windows 11
  Menu Démarrer    → Win | épinglé + nos recommandations + tout (une seule page)
  Snap Layouts     → Win+Z | 6 dispositions de fenêtres
  Bureaux virtuels → Win+Tab | Win+Ctrl+D/→/←/F4

Comptes locaux
  Créer            → lusrmgr.msc | Paramètres | New-LocalUser
  Administrateur   → Add-LocalGroupMember -Group "Administrateurs"
  Standard         → Add-LocalGroupMember -Group "Utilisateurs"

Réseau IP fixe (PC01)
  IP               → 192.168.3.10/24
  Passerelle       → 192.168.3.254
  DNS              → 8.8.8.8 (provisoire)
  Graphique        → ncpa.cpl → TCP/IPv4 → IP fixe
  PowerShell       → New-NetIPAddress + Set-DnsClientServerAddress

Variables d'environnement
  Afficher         → Get-ChildItem Env: | $env:NOM
  Créer session    → $env:NOM = "valeur"
  Créer persistant → [System.Environment]::SetEnvironmentVariable(...)
  Portées          → Processus < Utilisateur < Machine
```
