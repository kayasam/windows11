# TP 03. Configuration et personnalisation — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h15

> Chapitres associés : [03. Configuration et personnalisation](https://cours.kaya.ovh/windows11/windows11/03-configuration/)

---

## Objectifs

- Prendre en main l'interface Windows 11 26H2 et ses raccourcis
- Savoir où trouver un réglage : Paramètres ou Panneau de configuration
- Créer et gérer des comptes locaux (graphique et PowerShell)
- Donner à `PC01` son adresse IP fixe du plan d'adressage
- Manipuler les variables d'environnement

---

## Prérequis

- `PC01` installé (TP 02), session `admin`
- Réseau `vSwitch-Rennes` + NAT opérationnels (TP 01)

---

## Partie A — Interface (15 min)

**A1.** Ouvre le menu Démarrer. Nomme ses trois zones. Masque les recommandations.

> [!success]- Afficher la correction — A1
> ![w11-03-menu-demarrer-26h2](https://cours.kaya.ovh/windows11/assets/captures/w11-03-menu-demarrer-26h2.png)
>
> Trois zones sur une seule page défilante : **Épinglé**, **Nos recommandations**, **Tout** (vue Catégorie par défaut).
> Masquer les recommandations : **Paramètres → Personnalisation → Accueil** (ou « Démarrer » selon la build) → désactiver *Afficher les fichiers recommandés…* et *Afficher les recommandations…*.

**A2.** Ouvre trois fenêtres et organise-les en 50/25/25 avec les Snap Layouts, au clavier uniquement.

> [!success]- Afficher la correction — A2
> `Win + Z` sur la première fenêtre → choisir la disposition 50/25/25 au clavier (flèches + Entrée) → Windows propose de remplir les autres zones avec les fenêtres ouvertes. Alternative : `Win + ←`, puis `Win + →` puis `Win + ↑`/`↓` sur la moitié droite.

**A3.** Crée un bureau virtuel « Admin », place-y un terminal, puis reviens au bureau 1. Quels raccourcis as-tu utilisés ?

> [!success]- Afficher la correction — A3
> `Win + Ctrl + D` (nouveau bureau) → `Win + X` → **Terminal** → `Win + Tab` pour renommer le bureau (clic droit → Renommer → « Admin ») → `Win + Ctrl + ←` pour revenir au bureau 1.

**A4.** Aligne la barre des tâches à gauche et masque le bouton Widgets.

> [!success]- Afficher la correction — A4
> **Paramètres → Personnalisation → Barre des tâches** → *Comportements de la barre des tâches* → **Alignement : Gauche** ; section *Éléments de la barre des tâches* → désactiver **Widgets**.
> En entreprise, ces réglages se déploient par GPO (*Configuration utilisateur → Modèles d'administration → Menu Démarrer et barre des tâches*).

---

## Partie B — Paramètres ou Panneau de configuration ? (10 min)

**B1.** Pour chaque réglage, indique l'outil et la commande la plus rapide pour l'ouvrir :
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

## Partie C — Comptes locaux (20 min)

**C1.** Crée, en PowerShell, l'utilisateur standard `employe1` (mot de passe `P@ssw0rd2026!`, nom complet « Employé 1 ») et ajoute-le au groupe **Utilisateurs**.

> [!success]- Afficher la correction — C1
> ```powershell
> $mdp = ConvertTo-SecureString "P@ssw0rd2026!" -AsPlainText -Force
> New-LocalUser -Name "employe1" -Password $mdp -FullName "Employé 1" -Description "Poste Fournil"
> Add-LocalGroupMember -Group "Utilisateurs" -Member "employe1"
> ```
> `New-LocalUser` **n'ajoute le compte à aucun groupe** : sans `Add-LocalGroupMember`, il ne pourrait même pas ouvrir de session interactive.

**C2.** Affiche son SID. Quelle partie du SID identifie la machine, et laquelle identifie le compte ?

> [!success]- Afficher la correction — C2
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
> Deux machines clonées sans Sysprep auraient la même partie machine — d'où la généralisation (chapitre 14).

**C3.** Liste les membres du groupe **Utilisateurs**. Pourquoi y trouve-t-on aussi `admin` et des entrées `AUTORITE NT\…` ?

> [!success]- Afficher la correction — C3
> ```powershell
> Get-LocalGroupMember -Group "Utilisateurs" | Select-Object Name, PrincipalSource
> ```
> ```
> Name                                    PrincipalSource
> ----                                    ---------------
> AUTORITE NT\INTERACTIF                  Unknown
> AUTORITE NT\Utilisateurs authentifiés   Unknown
> PC01\admin                              Local
> PC01\defaultuser0                       Local
> PC01\employe1                           Local
> ```
> - `AUTORITE NT\Utilisateurs authentifiés` : tout compte authentifié (y compris, plus tard, les comptes du domaine) est implicitement « utilisateur » du poste.
> - `admin` y figure aussi : l'OOBE ajoute le premier compte à **Utilisateurs** et à **Administrateurs**.
> - `defaultuser0` : compte temporaire de l'OOBE, désactivé, parfois laissé derrière elle — on peut le supprimer.

**C4.** Crée le compte `stagiaire` dans `lusrmgr.msc`, avec « L'utilisateur doit changer le mot de passe à la prochaine ouverture de session ». Désactive-le ensuite en PowerShell.

> [!success]- Afficher la correction — C4
> `lusrmgr.msc` → **Utilisateurs** → clic droit → **Nouvel utilisateur** → cocher *L'utilisateur doit changer le mot de passe à la prochaine ouverture de session*.
> ```powershell
> Disable-LocalUser -Name stagiaire
> Get-LocalUser stagiaire | Select-Object Name, Enabled
> ```

**C5.** Quels sont les comptes locaux présents par défaut sur le poste ? Lesquels sont désactivés, et pourquoi ?

> [!success]- Afficher la correction — C5
> ```powershell
> Get-LocalUser | Select-Object Name, Enabled, Description
> ```
> ```
> Name               Enabled Description
> ----               ------- -----------
> admin                 True
> Administrateur       False Compte d'utilisateur d'administration
> DefaultAccount       False Compte utilisateur géré par le système.
> defaultuser0         False
> Invité               False Compte d'utilisateur invité
> WDAGUtilityAccount   False Compte d'utilisateur géré et utilisé par le système pour les scénarios Windows Defender A...
> ```
> L'**Administrateur** intégré (RID 500) est désactivé : c'est une cible connue des attaquants (nom et SID prévisibles), et il n'est pas soumis à l'UAC. **Invité** l'est aussi pour des raisons évidentes. Les autres sont des comptes système.

---

## Partie D — Réseau (20 min)

**D1.** Relève la configuration IP actuelle de `PC01`. D'où vient l'adresse ?

> [!success]- Afficher la correction — D1
> ```powershell
> Get-NetIPConfiguration
> ```
> Sur `PC01` juste après l'installation : `169.254.85.113`, aucune passerelle. C'est une adresse **APIPA** (169.254.0.0/16) : la carte est en DHCP, mais aucun serveur DHCP n'existe encore sur `vSwitch-Rennes` (`SRV01` n'arrive qu'au chapitre 10). Windows s'attribue alors une adresse « link-local ».

**D2.** Configure en PowerShell : IP `192.168.3.10/24`, passerelle `192.168.3.254`, DNS `1.1.1.1` et `8.8.8.8`.

> [!success]- Afficher la correction — D2
> ```powershell
> $adaptateur = (Get-NetAdapter | Where-Object Status -eq "Up").Name
> Remove-NetIPAddress -InterfaceAlias $adaptateur -Confirm:$false -ErrorAction SilentlyContinue
> Remove-NetRoute -InterfaceAlias $adaptateur -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
> New-NetIPAddress -InterfaceAlias $adaptateur -IPAddress "192.168.3.10" -PrefixLength 24 -DefaultGateway "192.168.3.254"
> Set-DnsClientServerAddress -InterfaceAlias $adaptateur -ServerAddresses "1.1.1.1","8.8.8.8"
> ```

**D3.** Teste la passerelle, Internet par IP, puis la résolution DNS. Dans quel ordre, et pourquoi cet ordre ?

> [!success]- Afficher la correction — D3
> ```powershell
> Test-Connection 192.168.3.254 -Count 2     # 1. la passerelle (réseau local)
> Test-Connection 8.8.8.8 -Count 2           # 2. Internet par IP (routage + NAT)
> Resolve-DnsName google.fr                  # 3. la résolution de noms
> ```
> Sur le lab : `google.fr → 142.251.142.3`.
> L'ordre suit les couches : si la passerelle ne répond pas, inutile de tester Internet ; si Internet répond par IP mais pas par nom, le problème est **DNS**. C'est la méthode de dépannage réseau du chapitre 19.
>
> > [!NOTE] `Test-Connection` en Windows PowerShell 5.1
> > La sortie de `Test-Connection` diffère entre PowerShell 5.1 (`Source`, `Destination`, `IPV4Address`, `Time(ms)`) et PowerShell 7 (`Ping`, `Status`, `Latency`). Pour un simple oui/non dans un script : `Test-Connection 8.8.8.8 -Count 1 -Quiet`.

**D4.** Quel profil réseau (Public/Privé) est appliqué ? Pourquoi ?

> [!success]- Afficher la correction — D4
> ```powershell
> Get-NetConnectionProfile | Select-Object InterfaceAlias, NetworkCategory
> ```
> **Public** : par défaut, tout nouveau réseau est classé Public tant que personne ne dit le contraire. Le pare-feu y est le plus strict (chapitre 09). Il passera automatiquement en **DomainAuthenticated** après la jonction au domaine (chapitre 10).

---

## Partie E — Variables d'environnement (10 min)

**E1.** Affiche `COMPUTERNAME`, `USERPROFILE` et le `PATH` en PowerShell, puis en CMD.

> [!success]- Afficher la correction — E1
> ```powershell
> $env:COMPUTERNAME; $env:USERPROFILE; $env:PATH -split ';'
> ```
> ```cmd
> echo %COMPUTERNAME% & echo %USERPROFILE% & echo %PATH%
> ```

**E2.** Crée la variable système `FOURNIL_ENV=lab`. Pourquoi ne la vois-tu pas dans le terminal déjà ouvert ?

> [!success]- Afficher la correction — E2
> ```powershell
> [System.Environment]::SetEnvironmentVariable("FOURNIL_ENV", "lab", "Machine")
> [System.Environment]::GetEnvironmentVariable("FOURNIL_ENV", "Machine")   # lab
> $env:FOURNIL_ENV                                                          # vide !
> ```
> Un processus reçoit une **copie** des variables au moment de son lancement. Le terminal déjà ouvert garde l'ancienne copie : il faut ouvrir un **nouveau** terminal.

**E3.** Ajoute `C:\Outils` au `PATH` système **sans l'écraser**.

> [!success]- Afficher la correction — E3
> ```powershell
> $ancien = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
> if ($ancien -notlike "*C:\Outils*") {
>     [System.Environment]::SetEnvironmentVariable("PATH", "$ancien;C:\Outils", "Machine")
> }
> ```
> Le test évite d'ajouter `C:\Outils` deux fois si le script est relancé.

---

## Partie F — Bonus

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

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/03-configuration/tp)
