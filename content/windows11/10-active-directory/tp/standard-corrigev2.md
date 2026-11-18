---
title: "TP 10. Intégration Active Directory — Correction"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/10-active-directory"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/10-active-directory/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/10-active-directory/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/10-active-directory-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp/standard">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp/standard-corrigev2" aria-current="page">Corrigé</a></nav>

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Chapitres associés : [10. Intégration Active Directory](https://cours.kaya.ovh/windows11/windows11/10-active-directory/)

---

## Objectifs

Tu prépares `SRV01` sur l’hôte Hyper-V, puis tu crées le domaine sur `SRV01`. Le TP est terminé quand `PC01` apparaît dans l’UO `Fournil → Ordinateurs` et que `FOURNIL\stagiaire` peut y ouvrir une session.

- Installer `SRV01` (Windows Server 2025 avec expérience de bureau) et le préparer (IP, nom, SSH)
- Créer la forêt `ad.fournil.lab` (AD DS + DNS) et le DHCP
- Créer la structure d'UO, les utilisateurs et les groupes du Fournil
- Joindre `PC01` au domaine **dans la bonne UO** et vérifier la jonction

---

## Prérequis

- ISO Windows Server 2025 (évaluation) dans `D:\ISO\`
- `PC01` opérationnel sur `vSwitch-Rennes`

---

## Partie A — Installer et préparer SRV01

**A1.** Depuis l’hôte Hyper-V, crée la VM `SRV01` (Gen 2, 4 Go **statiques**, 2 vCPU, 64 Go, `vSwitch-Rennes`). Installe **Windows Server 2025 Standard Evaluation (expérience utilisateur)** et définis le mot de passe Administrateur du lab `Fournil2026!`.

> [!success]- Afficher la correction — A1
> ```powershell
> New-VM -Name SRV01 -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath D:\HyperV\SRV01\SRV01.vhdx `
>     -NewVHDSizeBytes 64GB -SwitchName vSwitch-Rennes -Path D:\HyperV
> Set-VMMemory SRV01 -DynamicMemoryEnabled $false
> Set-VMProcessor SRV01 -Count 2
> $dvd = Add-VMDvdDrive SRV01 -Path D:\ISO\WS2025.iso -Passthru
> Set-VMFirmware SRV01 -FirstBootDevice $dvd
> ```
> (Ou l'assistant *Nouvel ordinateur virtuel* du Gestionnaire Hyper-V, comme pour `PC01`.)
>
> Dans la liste des images de l'ISO française :
> ```
> Windows Server 2025 Standard Evaluation                         ← présélectionnée = Server Core
> Windows Server 2025 Standard Evaluation (expérience utilisateur) ← celle-ci
> Windows Server 2025 Datacenter Evaluation
> Windows Server 2025 Datacenter Evaluation (expérience utilisateur)
> ```
> ![w11-10-srv-setup-image-experience](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-setup-image-experience.png)
>
> Sans la mention « (expérience utilisateur) », c'est **Server Core** (pas de bureau). Installation en moins de 5 minutes sur le lab ; au premier démarrage, saisir le mot de passe de l'Administrateur, puis **Ctrl+Alt+Fin** (ou le bouton Ctrl+Alt+Suppr de la console Hyper-V) pour ouvrir la session. Le **Gestionnaire de serveur** s'ouvre automatiquement.

**A2.** Sur `SRV01`, configure l’adresse `192.168.3.1/24`, la passerelle `192.168.3.254` et le DNS provisoire `1.1.1.1`. Renomme le serveur en `SRV01`, puis redémarre-le. Tu peux utiliser **Gestionnaire de serveur → Serveur local** ou PowerShell.

> [!success]- Afficher la correction — A2
> **En graphique** : Gestionnaire de serveur → **Serveur local** → lien **Ethernet** → clic droit *Ethernet* → **Propriétés** → **IPv4** : `192.168.3.1`, `255.255.255.0`, `192.168.3.254`, DNS `1.1.1.1`. Puis lien du **nom de l'ordinateur** → **Modifier…** → `SRV01` → redémarrer.
>
> ![w11-10-srv-ipv4-fixe](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-ipv4-fixe.png)
>
> **En PowerShell** :
> ```powershell
> New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.3.1 -PrefixLength 24 -DefaultGateway 192.168.3.254
> Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 1.1.1.1
> Rename-Computer -NewName SRV01 -Restart
> Test-NetConnection www.microsoft.com -Port 443     # TcpTestSucceeded : True (après redémarrage)
> ```
> Aucun DNS n'existe encore sur le réseau : sans DNS provisoire, impossible de télécharger les mises à jour ou un module. Il sera remplacé automatiquement par `127.0.0.1` à la promotion.

**A3.** Sur `SRV01`, démarre le service OpenSSH Server et vérifie que sa règle de pare-feu autorise le profil réseau actif. Depuis `PC01`, ouvre ensuite une session SSH vers `192.168.3.1`.

> [!success]- Afficher la correction — A3
> Constat sur `SRV01` fraîchement installé :
> ```
> OpenSSH.Server~~~~0.0.1.0   Installed        ← déjà présent sur Server 2025
> sshd                        Stopped / Manual ← mais arrêté
> OpenSSH-Server-In-TCP       Enabled, Inbound, Allow, Profile : Private
> NetworkCategory             Public           ← la règle ne s'applique pas !
> ```
> ```powershell
> Start-Service sshd; Set-Service sshd -StartupType Automatic
> Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Profile Domain,Private,Public
> ```
> Le lien *Accès SSH distant : Désactivé* de la page *Serveur local* ne fait rien sur la version du lab : on passe par PowerShell.
> Depuis `PC01` : `ssh administrateur@192.168.3.1` (par **IP** : aucun DNS ne connaît encore `SRV01`). Test sans se connecter : `Test-NetConnection 192.168.3.1 -Port 22` → `TcpTestSucceeded : True`.

---

## Partie B — Domaine, DNS, DHCP

**B1.** Installe les rôles AD DS, DNS et DHCP (assistant *Ajouter des rôles et fonctionnalités*, ou une seule commande PowerShell).

> [!success]- Afficher la correction — B1
> ```powershell
> Install-WindowsFeature -Name AD-Domain-Services, DNS, DHCP -IncludeManagementTools
> ```
> `Success : True`, `RestartNeeded : No` — les rôles sont posés, pas encore configurés.
>
> **En graphique** : **Gérer → Ajouter des rôles et fonctionnalités** → Suivant ×3 → cocher *Serveur DHCP*, *Serveur DNS*, *Services de domaine Active Directory* (accepter **Ajouter des fonctionnalités** à chaque fois) → Suivant jusqu'à *Confirmation* → **Installer** (≈ 3 min).
>
> ![w11-10-srv-roles-coches](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-roles-coches.png)

**B2.** Sur `SRV01`, crée la forêt `ad.fournil.lab` avec le nom NetBIOS `FOURNIL` et le niveau fonctionnel `Win2025`. Laisse le serveur terminer son redémarrage automatique, puis ouvre la session `FOURNIL\Administrateur`.

> [!success]- Afficher la correction — B2
> ```powershell
> Install-ADDSForest -DomainName "ad.fournil.lab" -DomainNetbiosName "FOURNIL" `
>     -DomainMode "Win2025" -ForestMode "Win2025" -InstallDns:$true `
>     -SafeModeAdministratorPassword (ConvertTo-SecureString "Fournil2026!" -AsPlainText -Force) -Force
> ```
> **En graphique** : lien **Promouvoir ce serveur en contrôleur de domaine** (fin de l'installation ou drapeau de notification). À corriger dans l'assistant :
> - *Configuration de déploiement* : **Ajouter une nouvelle forêt** (la valeur par défaut est « domaine existant ») → `ad.fournil.lab` ;
> - *Options supplémentaires* : le NetBIOS proposé est **`AD`** → le remplacer par **`FOURNIL`** ;
> - l'avertissement *« Il est impossible de créer une délégation pour ce serveur DNS »* est normal.
>
> ![w11-10-srv-adds-netbios-fournil](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-adds-netbios-fournil.png)
>
> Le serveur **redémarre seul**. Pendant le premier démarrage (« Application des paramètres… »), il crée la zone DNS, les enregistrements SRV, le pool de RID et active ADWS.
> **Ne jamais couper la VM à ce moment.** Vécu lors de la construction du lab : un `Restart-VM -Force` (coupure brutale) pendant cette phase a donné un DC inutilisable — zone `ad.fournil.lab` absente, ADWS *désactivé*, erreurs SAM 16642. Il a fallu réinstaller le serveur.

**B3.** Sur `SRV01`, vérifie que `Get-ADDomain` affiche `ad.fournil.lab`. Vérifie ensuite que le DNS client pointe vers le serveur lui-même et que les zones `ad.fournil.lab` et `_msdcs.ad.fournil.lab` existent.

> [!success]- Afficher la correction — B3
> ```powershell
> Get-ADDomain | Select-Object DNSRoot                                     # ad.fournil.lab
> Get-DnsClientServerAddress -InterfaceAlias Ethernet -AddressFamily IPv4   # {127.0.0.1}
> Get-DnsServerZone | Select-Object ZoneName
> ```
> Les zones attendues sont `ad.fournil.lab` et `_msdcs.ad.fournil.lab`. Le DNS client utilise `127.0.0.1`, l’adresse de boucle locale de `SRV01`.

> Si `Get-ADDomain` renvoie une erreur liée aux services Web Active Directory au premier démarrage, attends un court instant puis relance la commande. Voir [la vérification post-promotion dans le cours](https://cours.kaya.ovh/windows11/windows11/10-active-directory/#v%C3%A9rification-post-promotion).

**B4.** Déclare un redirecteur DNS vers `1.1.1.1`, puis vérifie que `SRV01` résout un nom Internet.

> [!success]- Afficher la correction — B4
> ```powershell
> Set-DnsServerForwarder -IPAddress 1.1.1.1
> Resolve-DnsName www.microsoft.com
> ```
> En graphique : `dnsmgmt.msc` → clic droit **SRV01** → **Propriétés** → onglet **Redirecteurs** → **Modifier…** (si le menu est grisé : F5 puis recommencer).
>
> ![w11-10-srv-dns-redirecteurs](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-dns-redirecteurs.png)
>
> Sans redirecteur, le DNS interroge les serveurs racine : ça marche souvent, mais c'est plus lent et certains réseaux le filtrent.

**B5.** Autorise le DHCP dans AD et crée l'étendue `vSwitch-Rennes` `192.168.3.100-200` (routeur `.254`, DNS `.1`, domaine `ad.fournil.lab`). Vérifie ensuite les trois options de l'étendue.

> [!success]- Afficher la correction — B5
> ```powershell
> Add-DhcpServerInDC -DnsName "SRV01.ad.fournil.lab" -IPAddress 192.168.3.1
> Add-DhcpServerv4Scope -Name "vSwitch-Rennes" -StartRange 192.168.3.100 -EndRange 192.168.3.200 -SubnetMask 255.255.255.0 -State Active
> Set-DhcpServerv4OptionValue -ScopeId 192.168.3.0 -Router 192.168.3.254 -DnsServer 192.168.3.1 -DnsDomain "ad.fournil.lab"
> Get-DhcpServerv4Scope
> ```
> ```
> ScopeId    : 192.168.3.0
> Name       : vSwitch-Rennes
> StartRange : 192.168.3.100
> EndRange   : 192.168.3.200
> State      : Active
> ```
> **En graphique** : drapeau du Gestionnaire de serveur → **Terminer la configuration DHCP** → *Valider* (autorisation dans AD). Puis `dhcpmgmt.msc` → **cliquer sur IPv4**, clic droit → **Nouvelle étendue…** : nom, plage `.100`→`.200` (longueur 24), routeur `192.168.3.254` + **Ajouter**, DNS et domaine déjà remplis, activer l'étendue.
>
> **Vérification indispensable** : `Get-DhcpServerv4OptionValue -ScopeId 192.168.3.0`, ou *Options d'étendue* dans la console :
>
> ![w11-10-srv-dhcp-options-etendue](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-dhcp-options-etendue.png)
>
> > [!WARNING] Vécu sur le lab
> > Un clic au milieu du champ *Routeur* a placé la saisie dans la 3ᵉ case : l'étendue a été créée avec le routeur `0.0.192.168`, sans message d'erreur. Les clients auraient eu une IP mais **pas d'Internet**. Correction : `Set-DhcpServerv4OptionValue -ScopeId 192.168.3.0 -Router 192.168.3.254`.

---

## Partie C — Structure du Fournil

**C1.** Crée l'arborescence d'UO : `Fournil` › `Utilisateurs`, `Ordinateurs`, `Groupes`, `Admins` (dans `dsa.msc` ou en PowerShell).

> [!success]- Afficher la correction — C1
> ```powershell
> New-ADOrganizationalUnit -Name "Fournil" -Path "DC=ad,DC=fournil,DC=lab"
> foreach ($ou in "Utilisateurs","Ordinateurs","Groupes","Admins") {
>     New-ADOrganizationalUnit -Name $ou -Path "OU=Fournil,DC=ad,DC=fournil,DC=lab"
> }
> ```
> En graphique : `dsa.msc` → clic droit `ad.fournil.lab` → **Nouveau → Unité d'organisation** → `Fournil`, puis la même chose sur `Fournil` pour les quatre sous-UO.
>
> ![w11-10-srv-aduc-arborescence](https://cours.kaya.ovh/windows11/assets/captures/w11-10-srv-aduc-arborescence.png)

**C2.** Dans l’UO `Utilisateurs`, crée le compte `stagiaire` (nom complet *Stagiaire Boulangerie*). Dans l’UO `Admins`, crée le compte `adm.stagiaire`. Utilise le mot de passe du lab `Fournil2026!` pour les deux comptes et décoche le changement obligatoire à la première connexion.

> [!success]- Afficher la correction — C2
> ```powershell
> New-ADUser -Name "Stagiaire Boulangerie" -SamAccountName stagiaire -UserPrincipalName stagiaire@ad.fournil.lab `
>     -Path "OU=Utilisateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab" `
>     -AccountPassword (ConvertTo-SecureString "Fournil2026!" -AsPlainText -Force) -Enabled $true
> New-ADUser -Name "Admin Postes Stagiaire" -SamAccountName adm.stagiaire -UserPrincipalName adm.stagiaire@ad.fournil.lab `
>     -Path "OU=Admins,OU=Fournil,DC=ad,DC=fournil,DC=lab" `
>     -AccountPassword (ConvertTo-SecureString "Fournil2026!" -AsPlainText -Force) -Enabled $true
> ```
> En graphique : UO `Utilisateurs` → **Nouvel utilisateur** → prénom, nom, `stagiaire` → mot de passe ×2, **décocher** *L'utilisateur doit changer le mot de passe…*
>
> > [!WARNING] Mot de passe refusé
> > Un mot de passe qui **contient le nom du compte ou le nom complet** est refusé. Vécu sur le lab : avec le nom complet *Stagiaire Fournil*, `Fournil2026!` est refusé… et la console crée quand même le compte **désactivé**. Supprimer le compte et recommencer avec un autre nom complet (*Stagiaire Boulangerie*). PowerShell, lui, refuse proprement sans rien créer.

**C3.** Dans l’UO `Groupes`, crée deux groupes de sécurité globaux. Ajoute `stagiaire` à `G-Boulangerie` et `adm.stagiaire` à `GG-Admins-Postes`.

> [!success]- Afficher la correction — C3
> ```powershell
> New-ADGroup -Name "G-Boulangerie"    -GroupScope Global -GroupCategory Security -Path "OU=Groupes,OU=Fournil,DC=ad,DC=fournil,DC=lab"
> New-ADGroup -Name "GG-Admins-Postes" -GroupScope Global -GroupCategory Security -Path "OU=Groupes,OU=Fournil,DC=ad,DC=fournil,DC=lab"
> Add-ADGroupMember G-Boulangerie -Members stagiaire
> Add-ADGroupMember GG-Admins-Postes -Members adm.stagiaire
> Get-ADUser stagiaire -Properties MemberOf | Select-Object SamAccountName, MemberOf
> ```
> `MemberOf : {CN=G-Boulangerie,OU=Groupes,OU=Fournil,DC=ad,DC=fournil,DC=lab}`
> En graphique : UO `Groupes` → **Nouveau → Groupe** (Globale, Sécurité) ; double-clic sur le groupe → **Membres** → **Ajouter…** → `stagiaire` → **Vérifier les noms**.

**C4.** Pour joindre `PC01` via l’interface graphique en D3, configure maintenant l’UO `Fournil → Ordinateurs` comme destination par défaut des nouveaux postes avec `redircmp`. Si tu utilises PowerShell avec `-OUPath` en D3, passe directement à la partie D.

> [!success]- Afficher la correction — C4
> Par défaut, un poste joint arrive dans **`CN=Computers`**, un *conteneur* et non une UO : **aucune GPO ne peut y être liée**. Les postes y échappent donc aux GPO du Fournil (chapitre 11). Deux parades :
> ```powershell
> redircmp "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"    # défaut du domaine, une fois pour toutes
> ```
> (`La redirection a réussi.` ; pas d'équivalent graphique) ou préciser `-OUPath` à chaque jonction (D3).

---

## Partie D — Joindre PC01

**D1.** Sur `PC01`, configure `192.168.3.1` comme seul serveur DNS. Vérifie avec `Resolve-DnsName ad.fournil.lab` que le nom renvoie `192.168.3.1`.

> [!success]- Afficher la correction — D1
> Avec les DNS `8.8.8.8` / `1.1.1.1` du TP 03 :
> ```
> ad.fournil.lab : Le nom DNS n'existe pas
> ```
> Un DNS public ne connaît pas un domaine interne. Un poste du domaine doit utiliser **le DNS du domaine** (et uniquement lui : un second DNS public produit des échecs aléatoires).
> ```powershell
> Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.3.1"
> Resolve-DnsName ad.fournil.lab        # 192.168.3.1
> ```

**D2.** Avant de joindre le domaine, vérifie que `PC01` trouve `SRV01` et peut le joindre. Ouvre **PowerShell sur `PC01`**.

1. Demande au DNS quel serveur est le contrôleur du domaine `ad.fournil.lab`.

   ```powershell
   Resolve-DnsName _ldap._tcp.dc._msdcs.ad.fournil.lab -Type SRV | Select-Object NameTarget
   ```

   La colonne `NameTarget` doit afficher `srv01.ad.fournil.lab`.

2. Vérifie que `PC01` peut atteindre le service d’annuaire (LDAP) sur `SRV01`.

   ```powershell
   Test-NetConnection 192.168.3.1 -Port 389
   ```

   Cherche la ligne `TcpTestSucceeded : True`. Si les deux vérifications réussissent, passe à D3.

> [!success]- Afficher la correction — D2
> Si la première commande échoue, reviens à D1 et vérifie que `PC01` utilise `192.168.3.1` comme DNS. Sur `SRV01`, la vérification des zones DNS est en B3.
>
> Si `NameTarget` affiche bien `srv01.ad.fournil.lab` mais que `TcpTestSucceeded` vaut `False`, le DNS trouve le bon serveur. Vérifie alors que `SRV01` est démarré, que les deux VM sont sur `vSwitch-Rennes` et que l’adresse de `SRV01` est bien `192.168.3.1`. Relance le test avant de passer à D3.

**D3.** Joins `PC01` au domaine (`sysdm.cpl` ou `Add-Computer`), de façon qu'il arrive dans `OU=Ordinateurs,OU=Fournil`.

> [!success]- Afficher la correction — D3
> ```powershell
> Add-Computer -DomainName "ad.fournil.lab" `
>     -OUPath "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab" `
>     -Credential (Get-Credential FOURNIL\Administrateur) -Restart
> ```
> **En graphique** : `sysdm.cpl` → **Modifier…** → *Domaine* : `ad.fournil.lab` → `FOURNIL\Administrateur` / `Fournil2026!` → *Bienvenue dans le domaine ad.fournil.lab.* → redémarrer. L'interface ne permet pas de choisir l'UO : c'est `redircmp` (C4) qui envoie le poste dans `OU=Ordinateurs`. Vérifié sur le lab : `CN=PC01,OU=Ordinateurs,OU=Fournil,…`.
>
> ![w11-10-pc01-bienvenue-domaine](https://cours.kaya.ovh/windows11/assets/captures/w11-10-pc01-bienvenue-domaine.png)
>
> > [!WARNING] Après la jonction
> > Le compte local s'écrit désormais `PC01\admin` (ou `.\admin`) : `admin` seul désigne un compte du domaine.
>
> En production, on utilise un compte dédié **délégué** pour joindre des postes dans cette UO, pas l'Administrateur du domaine.

**D4.** Après redémarrage, vérifie sur `PC01` qu’il est membre de `ad.fournil.lab`. Sur `SRV01`, vérifie que l’objet `PC01` se trouve dans l’UO `Fournil → Ordinateurs`.

> [!success]- Afficher la correction — D4
> Sur `PC01`, vérifie l’appartenance au domaine.
> ```powershell
> Get-CimInstance Win32_ComputerSystem | Select-Object Domain, PartOfDomain
> ```
> La colonne `Domain` affiche `ad.fournil.lab` et `PartOfDomain` affiche `True`.
>
> Sur `SRV01`, vérifie l’emplacement du compte ordinateur.
> ```powershell
> Get-ADComputer PC01 | Select-Object DistinguishedName
> # CN=PC01,OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab
> ```
> Tu peux aussi ouvrir `dsa.msc` et retrouver `PC01` dans `Fournil → Ordinateurs`.

**D5.** Qui est désormais administrateur local de `PC01` ? D'où vient ce changement ?

> [!success]- Afficher la correction — D5
> ```powershell
> Get-LocalGroupMember Administrateurs
> ```
> ```
> FOURNIL\Admins du domaine   ActiveDirectory
> PC01\admin                  Local
> PC01\Administrateur         Local
> ```
> La jonction ajoute **automatiquement** le groupe *Admins du domaine* aux Administrateurs locaux. Pratique, mais contraire au modèle en tiers : au chapitre 11, une GPO y ajoutera `GG-Admins-Postes` à la place, et LAPS gérera le mot de passe de l'admin local.

**D6.** Sur `PC01`, ouvre une session avec `FOURNIL\stagiaire`. Vérifie que `whoami` affiche `fournil\stagiaire`.

> [!success]- Afficher la correction — D6
> Écran de connexion → **Autre utilisateur** → `FOURNIL\stagiaire` (ou `stagiaire@ad.fournil.lab`), mot de passe `Fournil2026!`. Sous le champ, Windows affiche « Connectez-vous à FOURNIL » : c'est le domaine qui authentifie.
>
> ![w11-10-pc01-login-autre-utilisateur](https://cours.kaya.ovh/windows11/assets/captures/w11-10-pc01-login-autre-utilisateur.png) À la première ouverture, Windows crée le profil `C:\Users\stagiaire`.
>
> Vérifier que c'est bien une session de domaine :
> ```powershell
> whoami                 # fournil\stagiaire
> echo $env:LOGONSERVER  # \\SRV01 : le DC qui a validé la connexion
> whoami /upn            # stagiaire@ad.fournil.lab
> ```
>
> > En production, on crée les comptes avec `-ChangePasswordAtLogon $true` : Windows exigerait alors un nouveau mot de passe à cette première ouverture. Dans le lab, on garde `Fournil2026!` pour tous les comptes afin d'éviter les blocages.

---

## Partie E — Exercices complémentaires (bonus)

**E1.** `w32tm /query /source` sur `PC01` renvoie « VM IC Time Synchronization Provider ». Pourquoi est-ce un problème pour un membre du domaine ? Comment corriger ?

> [!success]- Afficher la correction — E1
> Kerberos tolère **5 minutes** d'écart entre client et DC. Un membre du domaine doit se synchroniser sur la hiérarchie du domaine (le DC qui détient le rôle PDC est la référence). En VM, le service d'intégration **Synchronisation date/heure** de Hyper-V prend le dessus : si l'hôte dérive, toutes les VM dérivent avec lui.
> ```powershell
> # Sur l'hôte : désactiver la synchro d'heure Hyper-V pour les membres du domaine (et le DC)
> Get-VMIntegrationService -VMName PC01 | Where-Object Id -match "2497F4DE-E9FA-4204-80E4-4B75C46419C0" | Disable-VMIntegrationService
> # Sur PC01
> w32tm /config /syncfromflags:domhier /update
> w32tm /resync /force
> w32tm /query /source        # SRV01.ad.fournil.lab
> ```

**E2.** Le canal sécurisé de `PC01` est cassé (« La relation d'approbation entre cette station de travail et le domaine principal a échoué »). Répare-le sans quitter le domaine.

> [!success]- Afficher la correction — E2
> Cause typique : restauration d'un vieux checkpoint de `PC01` — son mot de passe machine ne correspond plus à celui stocké dans AD.
> ```powershell
> Test-ComputerSecureChannel                          # False
> Test-ComputerSecureChannel -Repair -Credential (Get-Credential FOURNIL\Administrateur)
> # ou
> Reset-ComputerMachinePassword -Server SRV01 -Credential (Get-Credential FOURNIL\Administrateur)
> ```
> Pas besoin de sortir/rejoindre le domaine (ce qui perdrait les GPO de sécurité et créerait un nouvel objet).

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp/standard)
