# 10. Active Directory et services réseau

> [!NOTE] Objectif
> Installer `SRV01` (Windows Server 2025 **avec expérience de bureau**), le préparer (IP fixe, nom, SSH), installer les rôles AD DS, DNS et DHCP, promouvoir le serveur en contrôleur de domaine, créer la structure de base (UO, utilisateurs, groupes), configurer le DHCP, puis joindre `PC01` au domaine.
>
> **Outils :** Gestionnaire de serveur, Utilisateurs et ordinateurs Active Directory (`dsa.msc`), DNS (`dnsmgmt.msc`), DHCP (`dhcpmgmt.msc`), PowerShell
> **Commandes à connaître :** `Install-WindowsFeature`, `Install-ADDSForest`, `New-ADOrganizationalUnit`, `New-ADUser`, `Add-DhcpServerv4Scope`, `Add-Computer`

> [!TIP] Deux méthodes à chaque étape
> Chaque étape est d'abord montrée **en graphique** (captures du lab), puis **en PowerShell**. Les deux donnent exactement le même résultat : en TP, choisis celle avec laquelle tu es le plus à l'aise. PowerShell devient indispensable dès qu'il faut répéter l'opération sur plusieurs serveurs.

---

## Installation de Windows Server 2025

### Créer la VM

Comme pour `PC01` (chapitre 01) : Génération 2, **4 Go de mémoire statique**, 2 processeurs, disque de 64 Go, `vSwitch-Rennes`, ISO de Windows Server 2025. Un serveur n'a pas besoin de TPM.

```powershell
New-VM -Name SRV01 -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath D:\HyperV\SRV01\SRV01.vhdx `
    -NewVHDSizeBytes 64GB -SwitchName vSwitch-Rennes -Path D:\HyperV
Set-VMMemory SRV01 -DynamicMemoryEnabled $false
Set-VMProcessor SRV01 -Count 2
Set-VM SRV01 -AutomaticCheckpointsEnabled $false -CheckpointType Standard
$dvd = Add-VMDvdDrive SRV01 -Path D:\ISO\WS2025.iso -Passthru
Set-VMFirmware SRV01 -FirstBootDevice $dvd
```

### Installer l'OS

L'installeur est le même que celui de Windows 11 (chapitre 02) : langue, clavier, case *J'accepte que tout soit supprimé*, puis choix de l'image. L'ISO d'évaluation ne demande pas de clé de produit.

> [!WARNING] Choisir l'image « (expérience utilisateur) »
> L'installeur présélectionne la **première** ligne, *Windows Server 2025 Standard Evaluation* : c'est **Server Core**, sans bureau ni fenêtres. Pour ce cours, cliquer sur la **deuxième** ligne : **Windows Server 2025 Standard Evaluation (expérience utilisateur)**.

![w11-10-srv-setup-image-experience](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-setup-image-experience.png)

Le résumé doit indiquer *Installer Windows Server 2025 Standard Evaluation (expérience utilisateur)* :

![w11-10-srv-setup-pret](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-setup-pret.png)

Sur le lab, l'installation a pris **moins de 5 minutes**. Au premier démarrage, Windows demande le mot de passe de l'**Administrateur** intégré (`Fournil2026!`).

![w11-10-srv-mot-de-passe](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-mot-de-passe.png)

> [!TIP] Ctrl+Alt+Suppr dans une VM
> Pour ouvrir une session sur un serveur, Windows demande *Ctrl+Alt+Suppr*. Dans la console Hyper-V, utiliser le **premier bouton de la barre d'outils** (Ctrl+Alt+Suppr) ou le raccourci **Ctrl+Alt+Fin** : le vrai Ctrl+Alt+Suppr est intercepté par le PC hôte.

Après l'ouverture de session, Windows pose les questions de confidentialité (même piège qu'au chapitre 02 : faire défiler pour trouver **Obligatoire uniquement**), puis le **Gestionnaire de serveur** s'ouvre tout seul. Fermer la fenêtre publicitaire *Windows Admin Center et Azure Arc* (cocher *Ne plus afficher ce message*).

![w11-10-srv-gestionnaire-tableau-de-bord](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-gestionnaire-tableau-de-bord.png)

> [!NOTE] Et Server Core ?
> En production, on préfère souvent **Server Core** : moins de mises à jour, surface d'attaque réduite, moins de ressources. Il s'administre en ligne de commande (`sconfig`, PowerShell) ou à distance depuis un poste muni des outils RSAT. Dans ce cours, on garde l'expérience de bureau pour **voir** ce que l'on configure ; toutes les commandes PowerShell données ici fonctionnent à l'identique sur un Server Core.

---

## Préparation : IP fixe et nom du serveur

Tout se fait depuis **Gestionnaire de serveur → Serveur local** : chaque valeur bleue est un lien cliquable.

![w11-10-srv-serveur-local-avant](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-serveur-local-avant.png)

### IP fixe et DNS provisoire

1. Cliquer sur le lien à côté de **Ethernet** (*Adresse IPv4 attribuée par DHCP…*) : la fenêtre *Connexions réseau* s'ouvre.
2. Clic droit sur **Ethernet** → **Propriétés** → double-clic sur **Protocole Internet version 4 (TCP/IPv4)**.
3. Adresse `192.168.3.1`, masque `255.255.255.0`, passerelle `192.168.3.254`, DNS préféré **`1.1.1.1`** (provisoire).

![w11-10-srv-ipv4-fixe](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-ipv4-fixe.png)

> [!WARNING] Pourquoi un DNS provisoire ?
> `SRV01` n'est pas encore contrôleur de domaine : il n'existe aucun serveur DNS sur le réseau. Sans DNS (même public), le serveur ne résout aucun nom et ne peut ni télécharger de mise à jour ni joindre un site. Ce DNS sera remplacé automatiquement par `127.0.0.1` lors de la promotion (constaté sur le lab).

### Renommer

Cliquer sur le nom actuel (`WIN-XXXXXXXX`) → **Modifier…** → nom `SRV01` → **OK** → **OK** → **Fermer** → **Redémarrer maintenant**.

![w11-10-srv-renommer](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-renommer.png)

### En PowerShell

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.3.1 -PrefixLength 24 -DefaultGateway 192.168.3.254
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 1.1.1.1
Rename-Computer -NewName SRV01 -Restart
```

Après le redémarrage, vérifier : `hostname`, `ipconfig`, puis `Test-NetConnection www.microsoft.com -Port 443` (*TcpTestSucceeded : True*).

> [!TIP] Mises à jour
> Avant de poser un contrôleur de domaine, on lance Windows Update : **Paramètres → Windows Update → Rechercher des mises à jour** (le lien *Windows Update* de la page Serveur local y mène aussi). Une mise à jour cumulative peut prendre 20 à 30 minutes : en formation, la laisser tourner pendant la pause ou la reporter à la fin de la journée.

---

## Activer SSH (pour administrer SRV01 depuis PC01)

Le serveur OpenSSH est **déjà installé** sur Windows Server 2025, mais **arrêté**. La page *Serveur local* affiche un lien *Accès SSH distant : Désactivé*, mais sur la version du lab, **cliquer dessus ne fait rien** : on passe par PowerShell (en administrateur sur SRV01).

```powershell
Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Select-Object Name, State   # Installed
Start-Service sshd
Set-Service sshd -StartupType Automatic
```

> [!TIP] `Get-WindowsCapability` ne marche pas dans PowerShell 7 ?
> Cette commande fait partie du module **DISM**, prévu pour **Windows PowerShell 5.1**. Dans PowerShell 7 (`pwsh`), elle échoue souvent avec « *Classe non enregistrée* ». Deux solutions :
> - la lancer dans **Windows PowerShell** (le plus simple) ;
> - ou, dans PowerShell 7, charger d'abord le module en mode compatibilité (à refaire dans chaque nouvelle fenêtre) :
> ```powershell
> Import-Module Dism -UseWindowsPowerShell
> Get-WindowsCapability -Online -Name OpenSSH.Server*
> ```
> Dans les deux cas, le terminal doit être ouvert **en administrateur**.

> [!WARNING] La règle de pare-feu ne couvre que le profil Privé
> La règle `OpenSSH-Server-In-TCP` n'est active que sur le profil **Privé**. Or la carte de SRV01 est en profil **Public** (puis **Domaine** après la promotion) : le port 22 reste bloqué, silencieusement (*timeout*). On élargit la règle aux trois profils, une fois pour toutes :
> ```powershell
> Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Profile Domain,Private,Public
> ```

Depuis `PC01`, se connecter **par adresse IP** (aucun DNS ne connaît encore le nom `SRV01`) :

```cmd
ssh administrateur@192.168.3.1
```

---

## Installation des rôles AD DS, DNS et DHCP

**En graphique** : Gestionnaire de serveur → **Gérer → Ajouter des rôles et fonctionnalités** (ou le lien *2 Ajouter des rôles et des fonctionnalités* du tableau de bord).

1. *Avant de commencer*, *Type d'installation* (« basée sur un rôle »), *Sélection du serveur* (`SRV01`) : **Suivant** trois fois.
2. *Rôles de serveurs* : cocher **Serveur DHCP**, **Serveur DNS** et **Services de domaine Active Directory**. Pour chacun, une fenêtre propose les outils de gestion : **Ajouter des fonctionnalités**.

![w11-10-srv-roles-fonctionnalites-requises](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-roles-fonctionnalites-requises.png)

![w11-10-srv-roles-coches](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-roles-coches.png)

3. **Suivant** jusqu'à *Confirmation* (pages Fonctionnalités, AD DS, Serveur DNS, Serveur DHCP : rien à changer) → **Installer**. Environ 3 minutes sur le lab.

![w11-10-srv-roles-resultat](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-roles-resultat.png)

**En PowerShell** :

```powershell
Install-WindowsFeature -Name AD-Domain-Services, DNS, DHCP -IncludeManagementTools
Get-WindowsFeature AD-Domain-Services, DNS, DHCP | Select-Object Name, Installed
```

> [!NOTE] Installer un rôle ≠ le configurer
> Le rôle AD DS installé, il n'existe encore **aucun domaine** : c'est la **promotion** (ci-dessous) qui le crée. De même, le rôle DHCP ne distribue rien tant qu'il n'est pas **autorisé** et qu'aucune **étendue** n'est créée.

---

## Promotion en contrôleur de domaine

**En graphique** : à la fin de l'installation (ou depuis le **drapeau** de notification en haut du Gestionnaire de serveur), cliquer sur **Promouvoir ce serveur en contrôleur de domaine**.

> [!WARNING] Trois pièges dans l'assistant
> 1. **Configuration de déploiement** : l'option cochée par défaut est *Ajouter un contrôleur de domaine à un domaine existant*. Il faut choisir **Ajouter une nouvelle forêt**, puis taper le nom de domaine racine `ad.fournil.lab`.
> 2. **Options DNS** : un avertissement jaune *« Il est impossible de créer une délégation pour ce serveur DNS… »* apparaît. Il est **normal** (aucun DNS parent ne connaît `fournil.lab`) : l'ignorer.
> 3. **Options supplémentaires** : le nom NetBIOS proposé est **`AD`** (la première partie du nom de domaine). Le remplacer par **`FOURNIL`**, sinon tous les comptes s'appelleront `AD\…` au lieu de `FOURNIL\…` dans la suite du cours.

![w11-10-srv-adds-nouvelle-foret](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-adds-nouvelle-foret.png)

Page *Options du contrôleur de domaine* : niveaux fonctionnels **Windows Server 2025** (par défaut), *Serveur DNS* et *Catalogue global* cochés, mot de passe **DSRM** (`Fournil2026!` dans le lab ; en production, un mot de passe distinct et rangé au coffre).

![w11-10-srv-adds-options-dc](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-adds-options-dc.png)

![w11-10-srv-adds-netbios-fournil](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-adds-netbios-fournil.png)

Laisser les chemins par défaut, relire le résumé, puis la *Vérification de la configuration requise* doit afficher une coche verte → **Installer**.

![w11-10-srv-adds-verification](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-adds-verification.png)

**En PowerShell** (même résultat) :

```powershell
Install-ADDSForest -DomainName "ad.fournil.lab" -DomainNetbiosName "FOURNIL" `
    -DomainMode "Win2025" -ForestMode "Win2025" -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "Fournil2026!" -AsPlainText -Force) -Force
```

| Paramètre | Rôle |
|-----------|------|
| `-DomainName` | Nom de domaine DNS complet (FQDN) de la forêt |
| `-DomainNetbiosName` | Nom court (affiché dans `FOURNIL\utilisateur`) |
| `-DomainMode` / `-ForestMode` | Niveau fonctionnel : `Win2025` si tous les DC sont en Windows Server 2025 |
| `-InstallDns` | Crée la zone DNS du domaine |
| `-SafeModeAdministratorPassword` | Mot de passe du mode restauration des services d'annuaire (DSRM) |

> [!DANGER] Redémarrage automatique : ne pas interrompre
> Le serveur redémarre seul à la fin de la promotion. Pendant le premier démarrage (« Application des paramètres de l'ordinateur… »), il crée la zone DNS, les enregistrements SRV et active ADWS. Vécu lors d'une première construction du lab : une coupure brutale de la VM à ce moment a produit un DC **inutilisable** (zone DNS absente, ADWS désactivé). Seule issue : réinstaller. **Attendre**, sans forcer l'arrêt.

Après le redémarrage, l'écran de connexion propose **`FOURNIL\Administrateur`** : le compte Administrateur local du serveur est devenu l'administrateur du domaine.

![w11-10-srv-login-domaine](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-login-domaine.png)

### Vérification post-promotion

```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode      # ad.fournil.lab, FOURNIL, Windows2025Domain
Get-Service DNS, NTDS, Netlogon, ADWS                              # Running
Get-DnsClientServerAddress -InterfaceAlias Ethernet -AddressFamily IPv4   # 127.0.0.1
Get-DnsServerZone                                                  # ad.fournil.lab et _msdcs.ad.fournil.lab
Get-NetConnectionProfile                                           # DomainAuthenticated
```

> [!NOTE] « Impossible de trouver un serveur par défaut avec les services Web Active Directory »
> Juste après le redémarrage, `Get-ADDomain` (et la console `dsa.msc`) peuvent renvoyer cette erreur pendant une à deux minutes : le service **ADWS** démarre après NTDS. Attendre puis relancer.

### Redirecteur DNS

Après la promotion, `SRV01` résout les noms Internet en interrogeant directement les serveurs racine. On déclare un **redirecteur**, plus rapide et plus fiable.

**En graphique** : `dnsmgmt.msc` (ou Gestionnaire de serveur → **Outils → DNS**) → clic droit sur **SRV01** → **Propriétés** → onglet **Redirecteurs** → **Modifier…** → `1.1.1.1` → **OK**.

> [!TIP] Menu grisé ?
> Juste après l'ouverture, la console DNS peut afficher un menu contextuel presque entièrement grisé : elle n'est pas encore connectée au service. Sélectionner **SRV01**, appuyer sur **F5**, puis recommencer le clic droit.

![w11-10-srv-dns-redirecteurs](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-dns-redirecteurs.png)

**En PowerShell** :

```powershell
Set-DnsServerForwarder -IPAddress 1.1.1.1
Resolve-DnsName www.microsoft.com
```

---

## Configuration du DHCP

### 1. Autoriser le serveur DHCP dans AD

Sur un domaine, un serveur DHCP doit être **autorisé** dans l'annuaire avant de distribuer la moindre adresse : c'est une protection contre les serveurs DHCP sauvages (*rogue DHCP*).

**En graphique** : Gestionnaire de serveur → **drapeau** de notification → **Terminer la configuration DHCP** → **Suivant** → (*Autorisation* : informations d'identification de l'utilisateur courant) → **Valider** → les deux étapes doivent afficher *Terminé*.

![w11-10-srv-notification-dhcp](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-notification-dhcp.png)

![w11-10-srv-dhcp-autorisation-ok](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-dhcp-autorisation-ok.png)

> [!TIP] Rien ne se passe au premier clic ?
> Sur le lab, le premier clic sur *Terminer la configuration DHCP* n'a rien ouvert ; un second clic, quelques secondes plus tard, a lancé l'assistant.

### 2. Créer l'étendue

**En graphique** : `dhcpmgmt.msc` (ou **Outils → DHCP**) → déplier `srv01.ad.fournil.lab` → **cliquer d'abord sur IPv4**, puis clic droit sur **IPv4** → **Nouvelle étendue…** (si le menu est grisé, c'est que IPv4 n'était pas sélectionné).

![w11-10-srv-dhcp-nouvelle-etendue](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-dhcp-nouvelle-etendue.png)

| Page de l'assistant | Valeur |
|---------------------|--------|
| Nom de l'étendue | `vSwitch-Rennes` |
| Plage d'adresses IP | `192.168.3.100` → `192.168.3.200`, longueur `24` (le masque se remplit seul) |
| Ajout d'exclusions et de retard | rien |
| Durée du bail | 8 jours (défaut) |
| Configurer les options DHCP | *Oui, je veux configurer ces options maintenant* |
| Routeur (passerelle par défaut) | `192.168.3.254` → **Ajouter** |
| Nom de domaine et serveurs DNS | déjà rempli : `ad.fournil.lab`, `192.168.3.1` |
| Serveurs WINS | rien |
| Activer l'étendue | *Oui, je veux activer cette étendue maintenant* |

![w11-10-srv-dhcp-plage](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-dhcp-plage.png)

> [!WARNING] Saisie des adresses IP dans les champs en 4 cases
> Les champs d'adresse IP de la console DHCP sont découpés en quatre cases. Il faut **cliquer au début du champ** (dans la première case) avant de taper. Vécu sur le lab : un clic au milieu du champ « Routeur » a placé la saisie dans la 3ᵉ case, et l'étendue a été créée avec le routeur **`0.0.192.168`**… sans aucun message d'erreur. Toujours **relire les options** à la fin.

À la fin, l'étendue apparaît **Actif** ; ses **Options d'étendue** doivent afficher exactement :

![w11-10-srv-dhcp-options-etendue](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-dhcp-options-etendue.png)

Pour corriger une option fausse : double-clic sur l'option dans *Options d'étendue*, ou en PowerShell `Set-DhcpServerv4OptionValue -ScopeId 192.168.3.0 -Router 192.168.3.254`.

### En PowerShell

```powershell
Add-DhcpServerInDC -DnsName "SRV01.ad.fournil.lab" -IPAddress 192.168.3.1
Add-DhcpServerv4Scope -Name "vSwitch-Rennes" -StartRange 192.168.3.100 -EndRange 192.168.3.200 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -ScopeId 192.168.3.0 -Router 192.168.3.254 -DnsServer 192.168.3.1 -DnsDomain "ad.fournil.lab"

# Vérifier
Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue -ScopeId 192.168.3.0     # 003 = 192.168.3.254, 006 = 192.168.3.1, 015 = ad.fournil.lab
```

---

## Création d'UO, utilisateurs et groupes

Une **UO** (Unité d'Organisation) est un conteneur AD qui sert à ranger les objets et à leur appliquer des GPO (chapitre 11).

### En graphique : Utilisateurs et ordinateurs Active Directory

`dsa.msc` (ou Gestionnaire de serveur → **Outils → Utilisateurs et ordinateurs Active Directory**).

- **Créer une UO** : clic droit sur `ad.fournil.lab` → **Nouveau → Unité d'organisation** → `Fournil`. Puis clic droit sur `Fournil` → même chose pour `Utilisateurs`, `Ordinateurs`, `Groupes` et `Admins`. La case *Protéger le conteneur contre une suppression accidentelle* reste cochée.

![w11-10-srv-aduc-nouveau-menu](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-aduc-nouveau-menu.png)

![w11-10-srv-aduc-arborescence](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-aduc-arborescence.png)

- **Créer un utilisateur** : sélectionner l'UO `Utilisateurs` → bouton **Nouvel utilisateur** de la barre d'outils (ou clic droit → **Nouveau → Utilisateur**). Prénom `Stagiaire`, nom `Boulangerie`, nom d'ouverture de session `stagiaire`.

![w11-10-srv-aduc-nouvel-utilisateur](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-aduc-nouvel-utilisateur.png)

- Page suivante : mot de passe `Fournil2026!` deux fois, et **décocher** *L'utilisateur doit changer le mot de passe à la prochaine ouverture de session* (dans le lab uniquement).

![w11-10-srv-aduc-mot-de-passe](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-aduc-mot-de-passe.png)

> [!WARNING] « Ce mot de passe ne correspond pas aux critères de stratégie de mot de passe »
> Le domaine impose un mot de passe **complexe** d'au moins 7 caractères, qui **ne contient pas le nom du compte** ni son nom complet. Vécu sur le lab : avec le nom complet *Stagiaire Fournil*, `Fournil2026!` est refusé (il contient « Fournil »), et la console crée quand même le compte… **désactivé** et sans mot de passe. Dans ce cas, supprimer le compte et recommencer avec un autre nom complet (ici *Stagiaire Boulangerie*).
>
> ![w11-10-srv-aduc-erreur-complexite](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-aduc-erreur-complexite.png)

- **Créer un groupe** : UO `Groupes` → clic droit → **Nouveau → Groupe** → nom `G-Boulangerie`, étendue **Globale**, type **Sécurité**.
- **Ajouter un membre** : double-clic sur le groupe → onglet **Membres** → **Ajouter…** → taper `stagiaire` → **Vérifier les noms** → **OK**.

### En PowerShell

```powershell
$base = "OU=Fournil,DC=ad,DC=fournil,DC=lab"
New-ADOrganizationalUnit -Name "Fournil" -Path "DC=ad,DC=fournil,DC=lab"
foreach ($ou in "Utilisateurs","Ordinateurs","Groupes","Admins") { New-ADOrganizationalUnit -Name $ou -Path $base }

New-ADUser -Name "Stagiaire Boulangerie" -SamAccountName "stagiaire" -UserPrincipalName "stagiaire@ad.fournil.lab" `
    -Path "OU=Utilisateurs,$base" -AccountPassword (ConvertTo-SecureString "Fournil2026!" -AsPlainText -Force) -Enabled $true

New-ADGroup -Name "G-Boulangerie" -GroupScope Global -GroupCategory Security -Path "OU=Groupes,$base"
Add-ADGroupMember -Identity "G-Boulangerie" -Members "stagiaire"
```

```powershell
# Le compte d'administration des postes, séparé du compte utilisateur (moindre privilège, chap. 09/11)
New-ADUser -Name "Admin Postes Stagiaire" -SamAccountName "adm.stagiaire" -UserPrincipalName "adm.stagiaire@ad.fournil.lab" `
    -Path "OU=Admins,$base" -AccountPassword (ConvertTo-SecureString "Fournil2026!" -AsPlainText -Force) -Enabled $true
New-ADGroup -Name "GG-Admins-Postes" -GroupScope Global -GroupCategory Security -Path "OU=Groupes,$base"
Add-ADGroupMember -Identity "GG-Admins-Postes" -Members "adm.stagiaire"

# Vérifications
Get-ADUser stagiaire -Properties MemberOf | Select-Object DistinguishedName, Enabled, MemberOf
```

> [!NOTE] En PowerShell, l'erreur de complexité est claire
> `New-ADUser` avec un mot de passe refusé affiche une erreur explicite et ne crée **rien** — contrairement à la console graphique, qui laisse un compte désactivé derrière elle.

### Que les nouveaux postes arrivent dans la bonne UO

Par défaut, un poste joint au domaine atterrit dans le conteneur `CN=Computers`, où **aucune GPO ne peut être liée** (ce n'est pas une UO). On change ce conteneur par défaut **avant** de joindre le premier poste (en PowerShell, sur SRV01 — pas d'équivalent graphique) :

```powershell
redircmp "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"
# La redirection a réussi.
```

Autres solutions : préciser l'UO à la jonction (`Add-Computer ... -OUPath "OU=Ordinateurs,..."`), ou déplacer le poste ensuite (glisser-déposer dans `dsa.msc`, ou `Move-ADObject`).

> [!TIP] En production : `-ChangePasswordAtLogon $true`
> Forcer le changement de mot de passe à la première connexion évite qu'un compte garde un mot de passe connu de l'administrateur qui l'a créé. **Dans le lab, on ne l'active pas** : tous les comptes gardent `Fournil2026!`.

---

## Jonction d'un poste au domaine

### 1. Le DNS du poste doit être celui du domaine

Avec le DNS public du chapitre 03, `PC01` ne trouve pas le domaine :

```powershell
Resolve-DnsName ad.fournil.lab        # ad.fournil.lab : Le nom DNS n'existe pas
```

Mettre **uniquement** `192.168.3.1` comme DNS (en graphique : `ncpa.cpl` → IPv4, comme au chapitre 03 ; en PowerShell ci-dessous). Un second DNS public provoquerait des échecs aléatoires.

```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.3.1
Resolve-DnsName ad.fournil.lab                                    # 192.168.3.1
nltest /dsgetdc:ad.fournil.lab                                    # Contrôleur de domaine : \\SRV01.ad.fournil.lab
```

### 2. Joindre

**En graphique** : `Win + R` → `sysdm.cpl` → onglet *Nom de l'ordinateur* → **Modifier…** → *Membre d'un* : **Domaine** → `ad.fournil.lab` → **OK** → identifiants `FOURNIL\Administrateur` / `Fournil2026!` → message **« Bienvenue dans le domaine ad.fournil.lab. »** → **OK** → redémarrer.

![w11-10-pc01-joindre-domaine](https://cours.kaya.ovh/windows11/assets/captures/w11-10-pc01-joindre-domaine.png)

![w11-10-pc01-bienvenue-domaine](https://cours.kaya.ovh/windows11/assets/captures/w11-10-pc01-bienvenue-domaine.png)

**En PowerShell** (terminal administrateur) :

```powershell
Add-Computer -DomainName "ad.fournil.lab" -OUPath "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab" `
    -Credential (Get-Credential "FOURNIL\Administrateur") -Restart
```

### 3. Ouvrir une session de domaine

Écran de connexion → **Autre utilisateur** (en bas à gauche) → `FOURNIL\stagiaire` / `Fournil2026!`. Le texte *Connectez-vous à FOURNIL* confirme que c'est le domaine qui authentifie.

![w11-10-pc01-login-autre-utilisateur](https://cours.kaya.ovh/windows11/assets/captures/w11-10-pc01-login-autre-utilisateur.png)

> [!WARNING] Après la jonction, préfixer les comptes locaux
> Sur un poste joint, `admin` seul désigne désormais… un compte du domaine. Pour le compte local, taper **`PC01\admin`** (ou `.\admin`), à l'écran de connexion comme dans PowerShell (`Get-Credential`).

### Vérifier la jonction

```powershell
(Get-CimInstance Win32_ComputerSystem) | Select-Object Domain, PartOfDomain   # ad.fournil.lab / True
dsregcmd /status | Select-String "DomainJoined|DomainName"                     # YES / FOURNIL
Test-ComputerSecureChannel                                                    # True
Get-NetConnectionProfile                                                      # DomainAuthenticated
```

Côté serveur, dans `dsa.msc`, `PC01` apparaît dans l'UO **Fournil › Ordinateurs** (grâce à `redircmp`).

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> **Installation de SRV01**
> - Image **« (expérience utilisateur) »** (2ᵉ ligne), pas la 1ʳᵉ (Server Core)
> - Ctrl+Alt+Suppr dans la console Hyper-V : bouton de la barre d'outils ou Ctrl+Alt+Fin
>
> **Préparation (Gestionnaire de serveur → Serveur local)**
> - IP fixe `192.168.3.1`, passerelle `.254`, DNS provisoire `1.1.1.1` → nom `SRV01` → redémarrage
> - SSH : déjà installé mais arrêté → `Start-Service sshd` + règle pare-feu sur les 3 profils
>
> **Rôles et promotion**
> - **Gérer → Ajouter des rôles** : AD DS, DNS, DHCP — ou `Install-WindowsFeature`
> - **Promouvoir** : *Ajouter une nouvelle forêt* · NetBIOS **FOURNIL** (pas « AD ») · avertissement de délégation DNS normal
> - Redémarrage automatique : ne jamais couper la VM pendant la finalisation
> - Après promotion : DNS client `127.0.0.1`, redirecteur `1.1.1.1`
>
> **DHCP**
> - Drapeau → *Terminer la configuration DHCP* (autorisation dans AD)
> - `dhcpmgmt.msc` → IPv4 → *Nouvelle étendue* : 100-200, routeur `.254` (relire les options !)
>
> **Structure AD**
> - `dsa.msc` : UO `Fournil` › Utilisateurs, Ordinateurs, Groupes, Admins · `stagiaire`, `adm.stagiaire` · `G-Boulangerie`, `GG-Admins-Postes`
> - Mot de passe refusé s'il contient le nom du compte · `redircmp` avant la première jonction
>
> **Jonction de PC01**
> - DNS du poste = `192.168.3.1` uniquement
> - `sysdm.cpl` → Modifier → Domaine — ou `Add-Computer -OUPath ... -Restart`
> - Session : *Autre utilisateur* → `FOURNIL\stagiaire` · compte local = `PC01\admin`
