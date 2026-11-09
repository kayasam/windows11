# TP 10. Intégration Active Directory — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 2h

> Chapitres associés : [10. Intégration Active Directory](https://cours.kaya.ovh/windows11/windows11/10-active-directory/)

---

## Objectifs

- Installer `SRV01` en Server Core et le préparer (IP, DNS, SSH)
- Créer la forêt `ad.fournil.lab` (AD DS + DNS) et le DHCP
- Créer la structure d'UO, les utilisateurs et les groupes du Fournil
- Joindre `PC01` au domaine **dans la bonne UO** et vérifier la jonction

---

## Prérequis

- ISO Windows Server 2025 (évaluation) dans `D:\ISO\`
- `PC01` opérationnel sur `vSwitch-Rennes`

---

## Partie A — SRV01 en Server Core (25 min)

**A1.** Crée la VM `SRV01` (Gen 2, 4 Go **statiques**, 64 Go, `vSwitch-Rennes`) et installe **Windows Server 2025 Standard Evaluation** — laquelle des quatre entrées choisir ?

> [!success]- Afficher la correction — A1
> ```powershell
> New-VM -Name SRV01 -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath D:\HyperV\SRV01\SRV01.vhdx `
>     -NewVHDSizeBytes 64GB -SwitchName vSwitch-Rennes -Path D:\HyperV
> Set-VMMemory SRV01 -DynamicMemoryEnabled $false
> Set-VMProcessor SRV01 -Count 2
> $dvd = Add-VMDvdDrive SRV01 -Path D:\ISO\ws2025.iso -Passthru
> Set-VMFirmware SRV01 -FirstBootDevice $dvd
> ```
> Dans la liste des images de l'ISO française :
> ```
> 1 Windows Server 2025 Standard Evaluation                         ← celle-ci (Server Core)
> 2 Windows Server 2025 Standard Evaluation (expérience utilisateur)
> 3 Windows Server 2025 Datacenter Evaluation
> 4 Windows Server 2025 Datacenter Evaluation (expérience utilisateur)
> ```
> Sans la mention « (expérience utilisateur) » = **Server Core**. L'image d'évaluation installée affiche `24H2`, build `26100`, `InstallationType : Server Core`.

**A2.** Avec `sconfig` ou en PowerShell : nom `SRV01`, IP `192.168.3.1/24`, passerelle `.254`, DNS provisoire `1.1.1.1`. Pourquoi un DNS provisoire ?

> [!success]- Afficher la correction — A2
> ```powershell
> New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.3.1 -PrefixLength 24 -DefaultGateway 192.168.3.254
> Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 1.1.1.1
> Test-NetConnection www.microsoft.com -Port 443     # TcpTestSucceeded : True
> ```
> Aucun DNS n'existe encore sur le réseau : sans DNS provisoire, impossible de télécharger les mises à jour ou un module. Il sera remplacé automatiquement à la promotion.

**A3.** OpenSSH Server est-il installé ? Démarré ? La règle de pare-feu s'applique-t-elle au profil actif ? Corrige ce qu'il faut et connecte-toi depuis `PC01` en SSH **par IP**.

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
> Depuis `PC01` : `ssh administrateur@192.168.3.1` (par **IP** : aucun DNS ne connaît encore `SRV01`).

---

## Partie B — Domaine, DNS, DHCP (30 min)

**B1.** Installe les rôles AD DS, DNS et DHCP en une commande.

> [!success]- Afficher la correction — B1
> ```powershell
> Install-WindowsFeature -Name AD-Domain-Services, DNS, DHCP -IncludeManagementTools
> ```
> `Success : True`, `RestartNeeded : No` — les rôles sont posés, pas encore configurés.

**B2.** Promeus `SRV01` en premier contrôleur de la forêt `ad.fournil.lab` (NetBIOS `FOURNIL`, niveau `Win2025`). Que se passe-t-il à la fin ? Que ne faut-il surtout pas faire pendant le redémarrage qui suit ?

> [!success]- Afficher la correction — B2
> ```powershell
> Install-ADDSForest -DomainName "ad.fournil.lab" -DomainNetbiosName "FOURNIL" `
>     -DomainMode "Win2025" -ForestMode "Win2025" -InstallDns:$true `
>     -SafeModeAdministratorPassword (ConvertTo-SecureString "Fournil2026!DSRM" -AsPlainText -Force) -Force
> ```
> Le serveur **redémarre seul**. Pendant le premier démarrage (« Application des paramètres… »), il crée la zone DNS, les enregistrements SRV, le pool de RID et active ADWS.
> **Ne jamais couper la VM à ce moment.** Vécu lors de la construction du lab : un `Restart-VM -Force` (coupure brutale) pendant cette phase a donné un DC inutilisable — zone `ad.fournil.lab` absente, ADWS *désactivé*, erreurs SAM 16642. Il a fallu réinstaller le serveur.

**B3.** Juste après le redémarrage, `Get-ADDomain` répond « *Impossible de trouver un serveur par défaut avec les services Web Active Directory* ». Diagnostique.

> [!success]- Afficher la correction — B3
> Les cmdlets `*-AD*` passent par le service **ADWS** (port 9389), qui démarre une à deux minutes après NTDS. Attendre et relancer. Sur un DC sain, la commande répond ensuite (30 s sur le lab).
> Si l'erreur persiste : `Get-Service ADWS` (démarré ?), puis vérifier le DNS client (doit être `127.0.0.1`) et la zone `_msdcs` : les cmdlets localisent le DC par les enregistrements SRV.

**B4.** Vérifie : DNS client de `SRV01`, zones DNS créées, profil réseau.

> [!success]- Afficher la correction — B4
> ```powershell
> Get-DnsClientServerAddress -InterfaceAlias Ethernet -AddressFamily IPv4   # {127.0.0.1}
> Get-DnsServerZone | Select-Object ZoneName
> Get-NetConnectionProfile | Select-Object NetworkCategory                   # DomainAuthenticated
> ```
> Zones : `_msdcs.ad.fournil.lab`, `ad.fournil.lab`, plus les zones inverses par défaut (`0.`, `127.`, `255.in-addr.arpa`). La promotion a bien remplacé le DNS provisoire par `127.0.0.1`.

**B5.** Déclare un redirecteur DNS vers `1.1.1.1`, puis vérifie que `SRV01` résout un nom Internet.

> [!success]- Afficher la correction — B5
> ```powershell
> Set-DnsServerForwarder -IPAddress 1.1.1.1
> Resolve-DnsName www.microsoft.com
> ```
> Sans redirecteur, le DNS interroge les serveurs racine : ça marche souvent, mais c'est plus lent et certains réseaux le filtrent.

**B6.** Autorise le DHCP dans AD et crée l'étendue `192.168.3.100-200` (routeur `.254`, DNS `.1`, domaine `ad.fournil.lab`).

> [!success]- Afficher la correction — B6
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

---

## Partie C — Structure du Fournil (20 min)

**C1.** Crée l'arborescence d'UO : `Fournil` › `Utilisateurs`, `Ordinateurs`, `Groupes`, `Admins`.

> [!success]- Afficher la correction — C1
> ```powershell
> New-ADOrganizationalUnit -Name "Fournil" -Path "DC=ad,DC=fournil,DC=lab"
> foreach ($ou in "Utilisateurs","Ordinateurs","Groupes","Admins") {
>     New-ADOrganizationalUnit -Name $ou -Path "OU=Fournil,DC=ad,DC=fournil,DC=lab"
> }
> ```

**C2.** Crée `sguillard` (doit changer son mot de passe à la première connexion) et le compte d'administration des postes `adm.sguillard`.

> [!success]- Afficher la correction — C2
> ```powershell
> New-ADUser -Name "Samuel Guillard" -SamAccountName sguillard -UserPrincipalName sguillard@ad.fournil.lab `
>     -Path "OU=Utilisateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab" `
>     -AccountPassword (ConvertTo-SecureString "P@ssw0rd2026!" -AsPlainText -Force) -ChangePasswordAtLogon $true -Enabled $true
> New-ADUser -Name "Admin Postes Samuel" -SamAccountName adm.sguillard -UserPrincipalName adm.sguillard@ad.fournil.lab `
>     -Path "OU=Admins,OU=Fournil,DC=ad,DC=fournil,DC=lab" `
>     -AccountPassword (ConvertTo-SecureString "P@ssw0rd2026!" -AsPlainText -Force) -Enabled $true
> ```

**C3.** Crée les groupes globaux `G-Boulangerie` et `GG-Admins-Postes`, et peuple-les.

> [!success]- Afficher la correction — C3
> ```powershell
> New-ADGroup -Name "G-Boulangerie"    -GroupScope Global -GroupCategory Security -Path "OU=Groupes,OU=Fournil,DC=ad,DC=fournil,DC=lab"
> New-ADGroup -Name "GG-Admins-Postes" -GroupScope Global -GroupCategory Security -Path "OU=Groupes,OU=Fournil,DC=ad,DC=fournil,DC=lab"
> Add-ADGroupMember G-Boulangerie -Members sguillard
> Add-ADGroupMember GG-Admins-Postes -Members adm.sguillard
> Get-ADUser sguillard -Properties MemberOf | Select-Object SamAccountName, MemberOf
> ```
> `MemberOf : {CN=G-Boulangerie,OU=Groupes,OU=Fournil,DC=ad,DC=fournil,DC=lab}`

**C4.** Pourquoi faut-il agir **avant** de joindre le premier poste, sur le conteneur où arrivent les nouveaux ordinateurs ?

> [!success]- Afficher la correction — C4
> Par défaut, un poste joint arrive dans **`CN=Computers`**, un *conteneur* et non une UO : **aucune GPO ne peut y être liée**. Les postes y échappent donc aux GPO du Fournil (chapitre 11). Deux parades :
> ```powershell
> redircmp "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"    # défaut du domaine, une fois pour toutes
> ```
> ou préciser `-OUPath` à chaque jonction (D3).

---

## Partie D — Joindre PC01 (25 min)

**D1.** Sur `PC01`, essaie de résoudre `ad.fournil.lab`. Que se passe-t-il ? Corrige.

> [!success]- Afficher la correction — D1
> Avec le DNS `1.1.1.1` du TP 03 :
> ```
> ad.fournil.lab : Le nom DNS n'existe pas
> ```
> Un DNS public ne connaît pas un domaine interne. Un poste du domaine doit utiliser **le DNS du domaine** (et uniquement lui : un second DNS public produit des échecs aléatoires).
> ```powershell
> Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.3.1"
> Resolve-DnsName ad.fournil.lab        # 192.168.3.1
> ```

**D2.** Vérifie que `PC01` trouve un contrôleur de domaine (enregistrement SRV, port LDAP).

> [!success]- Afficher la correction — D2
> ```powershell
> Resolve-DnsName _ldap._tcp.dc._msdcs.ad.fournil.lab -Type SRV | Select-Object NameTarget, Port
> Test-NetConnection 192.168.3.1 -Port 389
> ```
> ```
> NameTarget           Port
> ----------           ----
> srv01.ad.fournil.lab  389
>
> TcpTestSucceeded : True
> ```
> C'est exactement ce que fait Windows lors de la jonction (puis Kerberos 88, SMB 445, RPC 135…).

**D3.** Joins `PC01` au domaine, directement dans `OU=Ordinateurs,OU=Fournil`.

> [!success]- Afficher la correction — D3
> ```powershell
> Add-Computer -DomainName "ad.fournil.lab" `
>     -OUPath "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab" `
>     -Credential (Get-Credential FOURNIL\Administrateur) -Restart
> ```
> En production, on utilise un compte dédié **délégué** pour joindre des postes dans cette UO, pas l'Administrateur du domaine.

**D4.** Après redémarrage, vérifie la jonction de quatre façons différentes.

> [!success]- Afficher la correction — D4
> ```powershell
> (Get-CimInstance Win32_ComputerSystem) | Select-Object Domain, PartOfDomain   # ad.fournil.lab / True
> dsregcmd /status | Select-String "DomainJoined|DomainName"                     # YES / FOURNIL
> Test-ComputerSecureChannel                                                    # True
> nltest /dsgetdc:ad.fournil.lab                                                # \\SRV01.ad.fournil.lab
> ```
> Et côté serveur :
> ```powershell
> Get-ADComputer PC01 | Select-Object DistinguishedName
> # CN=PC01,OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab
> ```
> Bonus : `Get-NetConnectionProfile` → **DomainAuthenticated** (la règle pare-feu « profil Domaine » du TP 09 s'applique désormais).

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

**D6.** Ouvre une session `FOURNIL\sguillard` sur `PC01`. Que demande Windows ?

> [!success]- Afficher la correction — D6
> Écran de connexion → **Autre utilisateur** → `FOURNIL\sguillard` (ou `sguillard@ad.fournil.lab`). Windows exige un **nouveau mot de passe** (`ChangePasswordAtLogon`), conforme à la stratégie du domaine (*Default Domain Policy* : 7 caractères, complexité). Puis création du profil `C:\Users\sguillard`.

---

## Partie E — Bonus

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

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp)
