# TP 03. Configuration et personnalisation — Correction

> [!tip] Mot de passe du lab
> Remplace `MOT_DE_PASSE_DU_LAB` par la valeur donnée par le formateur pour le compte concerné.

> [!abstract] Parcours TSSR
> Toutes les parties non marquées (bonus) sont à réaliser ; les exercices complémentaires sont facultatifs.
> **Méthode au choix : interface graphique ou PowerShell. Une seule méthode suffit** pour chaque manipulation ; tu peux changer de méthode selon la question. Les raccourcis clavier sont facultatifs. Le script de la partie F reste un bonus.

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Chapitres associés : [03. Configuration et personnalisation](https://cours.kaya.ovh/windows11/windows11/03-configuration/)

---

## Objectifs

- Prendre en main l'interface Windows 11 26H2 et ses raccourcis
- Savoir où trouver un réglage : Paramètres ou Panneau de configuration
- Créer et gérer des comptes locaux (interface graphique **ou** PowerShell)
- Donner à `PC01` son adresse IP fixe du plan d'adressage
- Manipuler les variables d'environnement

---

## Prérequis

- `PC01` installé (TP 02), session `admin`
- Réseau `vSwitch-Rennes` + NAT opérationnels (TP 01)

---

## Partie A — Interface

**A1.** Ouvre le menu Démarrer. Nomme ses trois zones. Masque les recommandations.

> [!success]- Afficher la correction — A1
> ![w11-03-menu-demarrer-26h2](https://cours.kaya.ovh/windows11/assets/captures/w11-03-menu-demarrer-26h2.png)
>
> Trois zones sur une seule page défilante : **Épinglé**, **Nos recommandations**, **Tout** (vue Catégorie par défaut).
> Masquer les recommandations : **Paramètres → Personnalisation → Démarrer** → rubrique *Recommandée* : désactiver *Afficher les fichiers recommandés…* et *Afficher les recommandations…*. Le bandeau « Vous devez activer Windows » n'empêche pas ces réglages.
>
> ![w11-03-parametres-demarrer-recommandations](https://cours.kaya.ovh/windows11/assets/captures/w11-03-parametres-demarrer-recommandations.png)

**A2.** Ouvre trois fenêtres et organise-les en 50/25/25 avec les Snap Layouts, à la souris **ou** au clavier.

> [!success]- Afficher la correction — A2
> **À la souris** : survoler le bouton **Agrandir** de la fenêtre, choisir la disposition 50/25/25, puis sélectionner les fenêtres pour remplir les zones.
> **Au clavier** : utiliser la méthode ci-dessous.
>
> `Win + Z` sur la première fenêtre → choisir la disposition 50/25/25 au clavier (flèches + Entrée) → Windows propose de remplir les autres zones avec les fenêtres ouvertes. Alternative : `Win + ←`, puis `Win + →` puis `Win + ↑`/`↓` sur la moitié droite.

**A3.** Crée un bureau virtuel « Admin », place-y un terminal, puis reviens au bureau 1, avec la Vue des tâches **ou** les raccourcis clavier. Explique comment tu as procédé.

> [!success]- Afficher la correction — A3
> **En graphique** : ouvrir **Vue des tâches** dans la barre des tâches → **Nouveau bureau** ; renommer ce bureau « Admin », y ouvrir un terminal, puis sélectionner le bureau 1 dans la Vue des tâches.
> **Avec les raccourcis** :
>
> `Win + Ctrl + D` (nouveau bureau) → `Win + X` → **Terminal** → `Win + Tab` pour renommer le bureau (clic droit → Renommer → « Admin ») → `Win + Ctrl + ←` pour revenir au bureau 1.

**A4.** Aligne la barre des tâches à gauche et masque le bouton Widgets.

> [!success]- Afficher la correction — A4
> **Paramètres → Personnalisation → Barre des tâches** → *Comportements de la barre des tâches* → **Alignement : Gauche** ; section *Éléments de la barre des tâches* → désactiver **Widgets**.
> En entreprise, ces réglages se déploient par GPO (*Configuration utilisateur → Modèles d'administration → Menu Démarrer et barre des tâches*).

---

## Partie B — Paramètres ou Panneau de configuration ?

**B1.** Pour chaque réglage, indique l’outil et comment l’ouvrir : chemin dans l’interface graphique **ou** commande d’accès, au choix :
1. Changer l'adresse IP de la carte réseau
2. Voir la RAM, le processeur, le nom du PC
3. Désinstaller un programme `.msi` ancien
4. Ouvrir les options Internet (proxy Win32)
5. Gérer les utilisateurs et groupes locaux

> [!success]- Afficher la correction — B1
> | Réglage | Outil | Commande rapide |
> |---------|-------|-----------------|
> | IP de la carte | Paramètres → Réseau et Internet, ou **Connexions réseau** | `ncpa.cpl` |
> | RAM, CPU, nom du PC | **Paramètres → Système → Informations système** | `ms-settings:about` |
> | Désinstaller un `.msi` ancien | Paramètres → Applications, ou **Programmes et fonctionnalités** | `appwiz.cpl` |
> | Options Internet | Panneau de configuration uniquement | `inetcpl.cpl` |
> | Utilisateurs et groupes locaux | Console MMC | `lusrmgr.msc` |
>
> ![w11-02-parametres-informations-26h2](https://cours.kaya.ovh/windows11/assets/captures/w11-02-parametres-informations-26h2.png)

---

## Partie C — Comptes locaux

**C1.** Crée l’utilisateur standard `employe1` (mot de passe `MOT_DE_PASSE_DU_LAB`, nom complet « Employé 1 ») dans `lusrmgr.msc` **ou** en PowerShell. Vérifie qu’il appartient au groupe **Utilisateurs** et ajoute-le si nécessaire.

> [!success]- Afficher la correction — C1
> **En graphique** : `lusrmgr.msc` → **Utilisateurs** → **Nouvel utilisateur** ; renseigner `employe1`, le nom complet « Employé 1 » et le mot de passe du lab. Vérifier ensuite l’onglet **Membre de** : le groupe **Utilisateurs** doit être présent.
> **En PowerShell** :
>
> ```powershell
> $mdp = Read-Host "Mot de passe du compte à créer" -AsSecureString
> New-LocalUser -Name "employe1" -Password $mdp -FullName "Employé 1" -Description "Poste Fournil"
> Add-LocalGroupMember -Group "Utilisateurs" -Member "employe1"
> ```
> `New-LocalUser` **n'ajoute le compte à aucun groupe** : sans `Add-LocalGroupMember`, il ne pourrait même pas ouvrir de session interactive.

**C2.** (bonus) Observe le SID de `employe1`, fourni par le formateur **ou** relevé avec `Get-LocalUser -Name employe1 | Select-Object Name, SID`. Quelle partie du SID identifie la machine, et laquelle identifie le compte ? Il n’est pas nécessaire d’utiliser PowerShell si tu travailles à partir du relevé fourni.

> [!success]- Afficher la correction — C2
> **Sans PowerShell** : interpréter le relevé fourni ci-dessous. Les nombres propres à la machine et le RID du compte peuvent différer sur ton poste.
> **Pour obtenir le relevé en PowerShell** :
>
> ```powershell
> Get-LocalUser employe1 | Select-Object Name, SID
> ```
> ```
> Name     SID
> ----     ---
> employe1 S-1-5-21-2996719152-1343562269-1905685070-1002
> ```
> - `S-1-5-21-2996719152-1343562269-1905685070` : identifiant de la **machine** (commun à tous ses comptes locaux).
> - `1002` : le **RID** du compte (500 = Administrateur intégré, 501 = Invité, 1000+ = comptes créés).
>
> Deux machines clonées sans Sysprep auraient la même partie machine — d'où la généralisation (chapitre 13).

**C3.** Affiche les membres du groupe **Utilisateurs**, dans `lusrmgr.msc` → **Groupes** → **Utilisateurs**, **ou** en PowerShell. Pourquoi y trouve-t-on aussi `admin` et des entrées `AUTORITE NT\…` ?

> [!success]- Afficher la correction — C3
> **En graphique** : `lusrmgr.msc` → **Groupes** → double-clic sur **Utilisateurs** ; lire la liste des membres.
> **En PowerShell** :
>
> ```powershell
> Get-LocalGroupMember -Group "Utilisateurs" | Select-Object Name, PrincipalSource
> ```
> ```
> Name                                    PrincipalSource
> ----                                    ---------------
> AUTORITE NT\INTERACTIF                  Unknown
> AUTORITE NT\Utilisateurs authentifiés   Unknown
> PC01\employe1                           Local
> ```
> - `AUTORITE NT\INTERACTIF` et `AUTORITE NT\Utilisateurs authentifiés` sont des **groupes spéciaux** : tout compte authentifié (y compris, plus tard, les comptes du domaine) est implicitement « utilisateur » du poste.
> - `admin` n'y figure **pas** sur le lab 26H2 : l'OOBE l'a placé uniquement dans **Administrateurs** (`Get-LocalGroupMember Administrateurs` → `PC01\admin`, `PC01\Administrateur`). Il reste un utilisateur authentifié, il n'a donc pas besoin d'être listé ici.
> - Sur certaines builds, un compte `defaultuser0` (compte temporaire de l'OOBE, désactivé) traîne aussi : on peut le supprimer.

**C4.** Crée le compte `employe2`, avec « L’utilisateur doit changer le mot de passe à la prochaine ouverture de session ». Vérifie à quel groupe il appartient, puis désactive-le. Utilise `lusrmgr.msc` (propriétés du compte → **Le compte est désactivé**) **ou** PowerShell avec les commandes complémentaires nécessaires.

> [!success]- Afficher la correction — C4
> `lusrmgr.msc` → **Utilisateurs** → clic droit → **Nouvel utilisateur** → cocher *L'utilisateur doit changer le mot de passe à la prochaine ouverture de session* → **Créer** puis **Fermer**.
>
> ![w11-03-lusrmgr-nouvel-utilisateur](https://cours.kaya.ovh/windows11/assets/captures/w11-03-lusrmgr-nouvel-utilisateur.png)
>
> Contrairement à `New-LocalUser`, la console ajoute **d'elle-même** le compte au groupe **Utilisateurs** :
> ```powershell
> Get-LocalGroupMember Utilisateurs        # PC01\employe2 apparaît
> Disable-LocalUser -Name employe2
> Get-LocalUser employe2 | Select-Object Name, Enabled
> ```
> Désactivation en graphique : double-clic sur le compte → cocher **Le compte est désactivé**.
>
> > [!NOTE] Pourquoi pas un compte local `stagiaire` ?
> > Le compte `stagiaire` sera créé **dans le domaine** au chapitre 10. Un compte local du même nom sur `PC01` sèmerait la confusion à l'ouverture de session (« Votre compte a été désactivé »).

**C5.** Quels sont les comptes locaux présents par défaut sur le poste ? Lesquels sont désactivés, et pourquoi ?

> [!success]- Afficher la correction — C5
> **En graphique** : `lusrmgr.msc` → **Utilisateurs** ; ouvrir les propriétés des comptes pour vérifier la case **Le compte est désactivé**. Comparer les comptes réellement présents sur le poste au relevé ci-dessous.
> **En PowerShell** :
>
> ```powershell
> Get-LocalUser | Select-Object Name, Enabled, Description
> ```
> ```
> Name               Enabled Description
> ----               ------- -----------
> admin                 True
> Administrateur       False Compte d'utilisateur d'administration
> DefaultAccount       False Compte utilisateur géré par le système.
> employe1              True Poste Fournil
> Invité               False Compte d'utilisateur invité
> WDAGUtilityAccount   False Compte d'utilisateur géré et utilisé par le système pour les scénarios Windows Defender A...
> ```
> L'**Administrateur** intégré (RID 500) est désactivé : c'est une cible connue des attaquants (nom et SID prévisibles), et il n'est pas soumis à l'UAC. **Invité** l'est aussi pour des raisons évidentes. Les autres sont des comptes système.

---

## Partie D — Réseau

**D1.** Relève la configuration IP actuelle de `PC01`, dans les détails de la carte réseau **ou** en PowerShell. D’où vient l’adresse ?

> [!success]- Afficher la correction — D1
> **En graphique** : `ncpa.cpl` → double-clic sur **Ethernet** → **Détails** ; relever IPv4, masque, passerelle et état DHCP.
> **En PowerShell** :
>
> ```powershell
> Get-NetIPConfiguration
> ```
> Sur `PC01` juste après l'installation : `169.254.85.113`, aucune passerelle. C'est une adresse **APIPA** (169.254.0.0/16) : la carte est en DHCP, mais aucun serveur DHCP n'existe encore sur `vSwitch-Rennes` (`SRV01` n'arrive qu'au chapitre 10). Windows s'attribue alors une adresse « link-local ».

**D2.** Configure dans `ncpa.cpl` **ou** en PowerShell : IP `192.168.3.10/24`, passerelle `192.168.3.254`, DNS `8.8.8.8` et `1.1.1.1`.

> [!success]- Afficher la correction — D2
> ```powershell
> $adaptateur = (Get-NetAdapter | Where-Object Status -eq "Up").Name
> Remove-NetIPAddress -InterfaceAlias $adaptateur -Confirm:$false -ErrorAction SilentlyContinue
> Remove-NetRoute -InterfaceAlias $adaptateur -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
> New-NetIPAddress -InterfaceAlias $adaptateur -IPAddress "192.168.3.10" -PrefixLength 24 -DefaultGateway "192.168.3.254"
> Set-DnsClientServerAddress -InterfaceAlias $adaptateur -ServerAddresses "8.8.8.8","1.1.1.1"
> ```
> **En graphique** : `ncpa.cpl` → clic droit **Ethernet** → **Propriétés** → **Protocole Internet version 4 (TCP/IPv4)** → **Propriétés** → *Utiliser l'adresse IP suivante* et *Utiliser l'adresse de serveur DNS suivante*.
>
> ![w11-03-configuration-7](https://cours.kaya.ovh/windows11/assets/captures/w11-03-configuration-7.png)

**D3.** Teste la passerelle, Internet par IP, puis la résolution DNS, avec les outils de ton choix. Le formateur peut fournir les commandes de test si nécessaire. Dans quel ordre, et pourquoi cet ordre ?

> [!success]- Afficher la correction — D3
> ```powershell
> Test-Connection 192.168.3.254 -Count 2     # 1. la passerelle (réseau local)
> Test-Connection 8.8.8.8 -Count 2           # 2. Internet par IP (routage + NAT)
> Resolve-DnsName google.fr                  # 3. la résolution de noms
> ```
> Sur le lab : `google.fr → 172.217.22.35` (l'adresse varie).
> L'ordre suit les couches : si la passerelle ne répond pas, inutile de tester Internet ; si Internet répond par IP mais pas par nom, le problème est **DNS**. C'est la méthode de dépannage réseau du chapitre 20.
>
> > [!NOTE] `Test-Connection` en Windows PowerShell 5.1
> > La sortie de `Test-Connection` diffère entre PowerShell 5.1 (`Source`, `Destination`, `IPV4Address`, `Time(ms)`) et PowerShell 7 (`Ping`, `Status`, `Latency`). Pour un simple oui/non dans un script : `Test-Connection 8.8.8.8 -Count 1 -Quiet`.

**D4.** Quel profil réseau (Public/Privé) est appliqué ? Consulte les propriétés de la connexion dans les Paramètres **ou** utilise PowerShell. Pourquoi ce profil ?

> [!success]- Afficher la correction — D4
> **En graphique** : **Paramètres → Réseau et Internet → Ethernet** ; consulter le type de profil réseau. Retenir le profil effectivement affiché sur ton poste.
> **En PowerShell** :
>
> ```powershell
> Get-NetConnectionProfile | Select-Object InterfaceAlias, NetworkCategory
> ```
> **Public** : par défaut, tout nouveau réseau est classé Public tant que personne ne dit le contraire. Le pare-feu y est le plus strict (chapitre 09). Il passera automatiquement en **DomainAuthenticated** après la jonction au domaine (chapitre 10).

---

## Partie E — Variables d'environnement

**E1.** Retrouve le nom de l’ordinateur (`COMPUTERNAME`), le dossier du profil courant (`USERPROFILE`) et le `PATH`, avec **une seule méthode au choix** :
- **En graphique** : nom du PC dans les informations système ; ouvrir `%USERPROFILE%` dans la barre d’adresse de l’Explorateur ; consulter `Path` dans `sysdm.cpl` → **Paramètres système avancés** → **Variables d’environnement**.
- **En PowerShell** : afficher `$env:COMPUTERNAME`, `$env:USERPROFILE` et `$env:PATH`.

> [!success]- Afficher la correction — E1
> **En graphique** : nom du PC dans **Paramètres → Système → Informations système** ; dossier du profil en ouvrant `%USERPROFILE%` dans l’Explorateur ; valeur de `Path` dans `sysdm.cpl` → **Paramètres système avancés → Variables d’environnement**.
> **En PowerShell** (une seule méthode suffit) :
>
> ```powershell
> $env:COMPUTERNAME; $env:USERPROFILE; $env:PATH -split ';'
> ```
> **Autre possibilité, facultative : CMD**.
> ```cmd
> echo %COMPUTERNAME% & echo %USERPROFILE% & echo %PATH%
> ```

**E2.** Crée la variable système `FOURNIL_ENV=lab`, dans la fenêtre **Variables d’environnement** → **Variables système** → **Nouvelle**, **ou** en PowerShell. Pourquoi un terminal déjà ouvert peut-il conserver l’ancien environnement ?

> [!success]- Afficher la correction — E2
> **En graphique** : ouvrir **Variables d’environnement** → **Variables système** → **Nouvelle** ; nom `FOURNIL_ENV`, valeur `lab`, puis valider les fenêtres.
> **En PowerShell**, dans un terminal administrateur :
>
> ```powershell
> [System.Environment]::SetEnvironmentVariable("FOURNIL_ENV", "lab", "Machine")
> [System.Environment]::GetEnvironmentVariable("FOURNIL_ENV", "Machine")   # lab
> $env:FOURNIL_ENV                                                          # vide !
> ```
> Un processus reçoit une **copie** des variables au moment de son lancement. Le terminal déjà ouvert garde l'ancienne copie : il faut ouvrir un **nouveau** terminal.

**E3.** Ajoute `C:\Outils` au `PATH` système **sans l’écraser**, dans **Variables système** → **Path** → **Modifier** → **Nouveau**, **ou** en PowerShell. Conserve toutes les entrées existantes.

> [!success]- Afficher la correction — E3
> **En graphique** : **Variables d’environnement → Variables système → Path → Modifier → Nouveau** ; ajouter `C:\Outils`, sans supprimer les lignes existantes, puis valider.
> **En PowerShell**, dans un terminal administrateur :
>
> ```powershell
> $ancien = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
> if ($ancien -notlike "*C:\Outils*") {
>     [System.Environment]::SetEnvironmentVariable("PATH", "$ancien;C:\Outils", "Machine")
> }
> ```
> Le test évite d'ajouter `C:\Outils` deux fois si le script est relancé.

---

## Partie F — Exercices complémentaires (bonus)

**F1.** Réécris la partie D en un script `Set-IPFixe.ps1` paramétrable (`-IP`, `-Passerelle`, `-DNS`).

> [!success]- Afficher la correction — F1
> ```powershell
> param(
>     [Parameter(Mandatory)][string]$IP,
>     [int]$Prefixe = 24,
>     [Parameter(Mandatory)][string]$Passerelle,
>     [string[]]$DNS = @("1.1.1.1")
> )
> $carte = (Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1).Name
> Remove-NetIPAddress -InterfaceAlias $carte -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
> Remove-NetRoute -InterfaceAlias $carte -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
> New-NetIPAddress -InterfaceAlias $carte -IPAddress $IP -PrefixLength $Prefixe -DefaultGateway $Passerelle | Out-Null
> Set-DnsClientServerAddress -InterfaceAlias $carte -ServerAddresses $DNS
> Get-NetIPConfiguration -InterfaceAlias $carte
> ```
> `.\Set-IPFixe.ps1 -IP 192.168.3.10 -Passerelle 192.168.3.254 -DNS 1.1.1.1,8.8.8.8`
> (Nécessite d'autoriser les scripts : `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`, chapitre 07.)

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/03-configuration/tp/standard)
