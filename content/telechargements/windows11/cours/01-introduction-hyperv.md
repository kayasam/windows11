# 01. Introduction à Windows 11 et lab Hyper-V

> [!NOTE] Objectif
> Situer Windows 11 (architecture, versions, cycle de vie, offre cloud), puis activer Hyper-V sur le poste hôte et construire le réseau du lab.
>
> **Outils :** `winver`, Gestionnaire Hyper-V, PowerShell
> **Cmdlets à connaître :** `Get-ComputerInfo`, `Enable-WindowsOptionalFeature`, `New-VMSwitch`, `New-NetIPAddress`, `New-NetNat`, `New-VM`, `Set-VMKeyProtector`, `Enable-VMTPM`

> [!INFO] Fil rouge — Fournil
> Réseau `192.168.3.0/24` sur `vSwitch-Rennes`, passerelle NAT `192.168.3.254` — voir [00-infrastructure](https://cours.kaya.ovh/windows11/windows11/00-infrastructure/).

---

## Windows 11 en 2026 : versions et cycle de vie

### Une version par an, des mises à jour chaque mois

Windows 11 suit un modèle **« Windows as a Service »** :

| Type | Fréquence | Exemple |
|------|-----------|---------|
| **Mise à jour de fonctionnalités** (version) | 1 fois par an, au second semestre | 24H2 (2024), 25H2 (2025), **26H2 (septembre 2026)** |
| **Mise à jour de qualité** (cumulative) | Chaque 2ᵉ mardi du mois (*Patch Tuesday*) | KB… de novembre 2026 |

Depuis la 25H2, la nouvelle version arrive sous forme de **package d'activation** (*enablement package*) : les fonctionnalités sont déjà présentes, désactivées, dans les mises à jour mensuelles de la version précédente. Le passage 25H2 → 26H2 se fait donc en un seul redémarrage, comme une mise à jour mensuelle.

| Version | Build | Support Home/Pro | Support Enterprise/Education |
|---------|-------|------------------|------------------------------|
| 24H2 | 26100 | 24 mois | 36 mois |
| 25H2 | 26200 | 24 mois | 36 mois |
| **26H2** | 26300 (lab) | 24 mois | 36 mois |

```powershell
# Version, build et édition du poste
winver
Get-ComputerInfo | Select-Object OsName, OSDisplayVersion, OsBuildNumber
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion') |
    Select-Object DisplayVersion, CurrentBuild, UBR, EditionID
```

> [!WARNING] « Windows 10 Pro » dans le registre d'un Windows 11 ?
> La valeur `ProductName` de `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion` affiche encore **`Windows 10 Pro`** sur un Windows 11 26H2 (constaté sur le lab). Microsoft n'a jamais modifié cette valeur pour compatibilité. Pour identifier un Windows 11 dans un script, tester le **build** : `CurrentBuild -ge 22000`.

### Windows 10 n'est plus supporté

**Windows 10 a atteint sa fin de support le 14 octobre 2025.** Les postes restants ne reçoivent plus de correctifs, sauf souscription au programme payant **ESU** (*Extended Security Updates*). Migrer le parc vers Windows 11 (chapitres 02, 16) est donc la priorité de beaucoup d'entreprises en 2026.

### Architecture en un coup d'œil

![Architecture de Windows 11 : modes utilisateur et noyau, VBS si activée, UEFI, Secure Boot et TPM 2.0.](https://cours.kaya.ovh/windows11/assets/captures/windows11-architecture.svg)

### Windows dans le cloud : Windows 365

| Offre | Principe | Client |
|-------|----------|--------|
| **Windows 365** (Cloud PC) | Un PC Windows 11 hébergé par Microsoft, attribué à un utilisateur, facturé par mois | Navigateur, **Windows App** |
| **Azure Virtual Desktop** | Bureaux et applications virtualisés, multi-sessions, géré par l'entreprise dans Azure | Windows App |
| **Windows 365 Link** | Petit boîtier dédié qui démarre directement sur un Cloud PC | Intégré |

> [!NOTE] Windows App remplace l'application Bureau à distance
> L'application « Bureau à distance » du Store a été retirée en mai 2025 et le client MSRDC en mars 2026, au profit de **Windows App** (Cloud PC, AVD). Le client classique `mstsc.exe` reste supporté pour se connecter à un PC ou un serveur (chapitre 12).

---

## Qu'est-ce qu'un hyperviseur ?

Un **hyperviseur** est un logiciel qui permet de faire tourner plusieurs systèmes d'exploitation (machines virtuelles) sur un seul ordinateur physique.

![Hyper-V sur la machine physique — La partition hôte Windows 11 et les VM PC01, SRV01 et PC02 s’exécutent au-dessus de Hyper-V, directement sur le matériel.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-01-hyperviseur-hyper-v.svg)

### Types d'hyperviseurs

| Type | Fonctionnement | Exemples |
|------|---------------|----------|
| **Type 1** (bare-metal) | Directement sur le matériel, sans OS hôte | Rôle Hyper-V de Windows Server, Azure Local, VMware ESXi, Proxmox |
| **Type 2** (hosted) | Au-dessus d'un OS existant | VirtualBox, VMware Workstation |

> [!TIP] Hyper-V sur Windows 11 — un cas particulier
> Hyper-V sur Windows 11 s'installe **dans** Windows, mais une fois activé, il se comporte comme un hyperviseur de **type 1** : Windows lui-même devient une partition privilégiée qui tourne au-dessus de l'hyperviseur. C'est pourquoi on parle parfois d'hyperviseur "hybride".

---

## Prérequis pour Hyper-V

### Configuration matérielle

| Composant | Minimum requis |
|-----------|---------------|
| Processeur | 64 bits avec SLAT (Second Level Address Translation) |
| RAM | 4 Go minimum (16 Go recommandé pour un lab, 32 Go idéal) |
| Stockage | SSD fortement recommandé |
| Virtualisation | VT-x (Intel) ou AMD-V activé dans le BIOS/UEFI |

### Éditions compatibles

Hyper-V est disponible sur **Windows 11 Pro, Enterprise et Education**. Il n'est **pas inclus** dans Windows 11 Home (sauf manipulation non supportée).

### Vérifier les prérequis

```powershell
# Vérification complète avec systeminfo
systeminfo

# Regarder la section "Configuration requise pour Hyper-V" en bas de la sortie
# Toutes les lignes doivent afficher "Oui"
```

```
Configuration requise pour Hyper-V :     Extensions du mode du moniteur d'ordinateur virtuel : Oui
                                          Virtualisation activée dans le microprogramme : Oui
                                          Traduction d'adresses de second niveau : Oui
                                          Prévention de l'exécution des données disponible : Oui
```

On peut aussi vérifier dans le **Gestionnaire des tâches** → onglet **Performances** → **Processeur** : la ligne "Virtualisation" doit indiquer "Activé".

---

## Activer Hyper-V

### Via PowerShell (méthode recommandée)

```powershell
# Activer Hyper-V et tous ses composants (nécessite un redémarrage)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

### Via l'interface graphique

1. **Paramètres** → **Systemes** → **Fonctionnalités facultatives** → **Plus de fonctionnalités Windows**
2. Cocher **Hyper-V** (inclut les outils de gestion et la plateforme)
3. Redémarrer

![w11-01-hyperv](https://cours.kaya.ovh/windows11/assets/captures/w11-01-hyperv.png)

### Vérifier l'installation

```powershell
# Vérifier que le service est actif
Get-Service vmms

# Lister les cmdlets Hyper-V disponibles
Get-Command -Module Hyper-V | Measure-Object
# Résultat attendu : plus de 200 cmdlets
```

> [!TIP] Pour aller plus loin sur l'installation
> [IT-Connect — Hyper-V : installation sur Windows 11](https://www.it-connect.fr/chapitres/hyper-v-installation-sur-windows-11/)

---

## Les commutateurs virtuels (vSwitch)

Un commutateur virtuel (vSwitch) connecte les cartes réseau des VM entre elles et éventuellement avec le réseau physique.

### Les trois types de vSwitch

![Les trois types de vSwitch — Le switch externe relie les VM au réseau physique, l’interne les relie à l’hôte et le privé relie seulement les VM.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-01-types-vswitch.svg)

| Type | VM ↔ VM | VM ↔ Hôte | VM → Internet | Risque |
|------|---------|-----------|---------------|--------|
| **Externe** | ✅ | ✅ | ✅ | Expose les VM sur le réseau réel |
| **Interne** | ✅ | ✅ | ❌ (sauf NAT) | Isolé du réseau physique |
| **Privé** | ✅ | ❌ | ❌ | Isolé de tout |

> [!WARNING] Pourquoi éviter le switch externe en lab ?
> Un switch externe **partage la carte réseau physique** de l'hôte. Si les VM obtiennent une IP via DHCP de l'entreprise, elles deviennent visibles sur le réseau réel — ça peut créer des conflits (serveur DHCP concurrent, DNS parasite). En lab, on préfère un **switch interne + NAT** : les VM communiquent entre elles et accèdent à Internet **sans polluer le réseau physique**.

### Le Default Switch (commutateur par défaut)

À l'activation de Hyper-V, Windows crée automatiquement un switch appelé **Default Switch**. Il est visible dans le Gestionnaire de commutateur virtuel mais **ne peut pas être supprimé ni modifié**.

![Default Switch — Le commutateur interne automatique de Hyper-V fournit DHCP et NAT. Windows peut changer son sous-réseau au redémarrage.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-01-default-switch.svg)

| Avantage | Inconvénient |
|----------|-------------|
| Aucune configuration nécessaire | L'adresse IP de la passerelle **change à chaque redémarrage** de l'hôte |
| Les VM ont Internet immédiatement | Impossible de fixer la plage réseau |
| Pratique pour un test rapide | Pas de contrôle sur le DHCP ni le DNS |
| | Incompatible avec un lab qui nécessite des IP fixes et un plan d'adressage stable |

> [!WARNING] Pourquoi on n'utilise pas le Default Switch dans ce cours
> Le Default Switch est pratique pour un test rapide, mais son adressage **change à chaque reboot** de l'hôte. Impossible de configurer des IP fixes stables pour les VM, ce qui est indispensable pour monter un lab avec un contrôleur de domaine, du DNS et du DHCP.
>
> **Notre choix** : un switch **interne** avec un NAT configuré manuellement pour `PC01`, `SRV01` et `PC02`. C'est quelques commandes de plus, mais on maîtrise totalement le réseau. `MASTER` (chapitre 14) est la seule exception : elle n'a pas besoin d'IP stable ni de joindre le domaine, elle utilise directement le Default Switch pour son accès Internet.

> [!TIP] Pour aller plus loin sur les commutateurs virtuels
> [IT-Connect — Hyper-V : switchs virtuels externe, interne et privé](https://www.it-connect.fr/chapitres/hyper-v-switchs-virtuels-externe-interne-et-prive/)

---

## Configurer un switch interne avec NAT

C'est la configuration recommandée pour un lab. L'idée :

![Switch interne et passerelle NAT — PC01 et SRV01 utilisent vSwitch-Rennes et la passerelle NAT 192.168.3.254 de l’hôte pour accéder à Internet.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-01-vswitch-nat.svg)

Les VM utilisent la passerelle `.254` sur l'hôte, et Windows traduit les adresses (NAT) pour leur donner accès à Internet.

### Étape par étape en PowerShell

```powershell
# 1) Créer le switch interne
New-VMSwitch -Name "vSwitch-Rennes" -SwitchType Internal

# 2) Vérifier l'interface virtuelle créée sur l'hôte
Get-NetAdapter | Where-Object Name -like "*vSwitch-Rennes*"
# Résultat : une interface "vEthernet (vSwitch-Rennes)" apparaît

# 3) Attribuer une IP à cette interface (ce sera la passerelle des VM)
New-NetIPAddress -InterfaceAlias "vEthernet (vSwitch-Rennes)" `
    -IPAddress 192.168.3.254 `
    -PrefixLength 24

# 4) Créer la règle NAT
New-NetNat -Name "NAT-Rennes" `
    -InternalIPInterfaceAddressPrefix "192.168.3.0/24"
```

### Vérification

```powershell
# Le switch existe ?
Get-VMSwitch -Name "vSwitch-Rennes"

# L'IP est bien configurée ?
Get-NetIPAddress -InterfaceAlias "vEthernet (vSwitch-Rennes)" | 
    Select-Object IPAddress, PrefixLength

# Le NAT est actif ?
Get-NetNat
```

### Configuration côté VM

Chaque VM devra être configurée avec une IP fixe sur ce réseau :

| Paramètre | Valeur |
|-----------|--------|
| Adresse IP | `192.168.3.X` (X = selon la VM) |
| Masque | `255.255.255.0` (/24) |
| Passerelle | `192.168.3.254` |
| DNS | `8.8.8.8` (ou DNS du futur serveur) |

> [!TIP] Supprimer la configuration
> Si tu dois tout refaire proprement :
> ```powershell
> # Supprimer le NAT
> Remove-NetNat -Name "NAT-Rennes" -Confirm:$false
> # Supprimer le switch (supprime aussi l'interface vEthernet)
> Remove-VMSwitch -Name "vSwitch-Rennes" -Force
> ```

---

## Configurer les dossiers par défaut

Avant de créer des VM, il est recommandé de définir **où Hyper-V stocke ses fichiers**. Par défaut, tout va dans `C:\ProgramData\Microsoft\Windows\Hyper-V\`, mais en lab on préfère un dossier dédié (idéalement sur un second disque) pour garder les choses organisées.

### Via l'interface graphique

Dans le **Gestionnaire Hyper-V** → clic droit sur le nom de l'hôte → **Paramètres Hyper-V** :

![w11-01-hyperv-parametres-dossiers](https://cours.kaya.ovh/windows11/assets/captures/w11-01-hyperv-parametres-dossiers.png)

Deux chemins à configurer :

| Paramètre | Contient | Exemple |
|-----------|----------|---------|
| **Disques durs virtuels** | Les fichiers `.vhdx` (le "disque" de chaque VM) | `D:\HyperV\` |
| **Ordinateurs virtuels** | Les fichiers de configuration et d'état des VM | `D:\HyperV\` |

### Via PowerShell

```powershell
# Voir les chemins actuels
Get-VMHost | Select-Object VirtualHardDiskPath, VirtualMachinePath

# Modifier les chemins par défaut
Set-VMHost -VirtualHardDiskPath "D:\HyperV\" `
           -VirtualMachinePath "D:\HyperV\"
```

### Structure du dossier Hyper-V

Une fois les VM créées, le dossier ressemble à ceci :

![w11-01-hyperv-dossier-hyperv](https://cours.kaya.ovh/windows11/assets/captures/w11-01-hyperv-dossier-hyperv.png)

![Fichiers du dossier Hyper-V — Sous D:\HyperV\ se trouvent les dossiers de configuration et de checkpoints, les disques VHDX et un disque différentiel AVHDX.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-01-dossier-hyperv.svg)

| Extension | Type | Description |
|-----------|------|------------|
| `.vhdx` | Disque dur virtuel | Contient le système de fichiers de la VM |
| `.avhdx` | Disque différentiel | Créé automatiquement par un checkpoint — stocke les modifications depuis le checkpoint |
| `.vmcx` | Configuration VM | Paramètres de la VM (RAM, CPU, réseau, etc.) |
| `.vmrs` | État d'exécution | État de la mémoire lors d'une sauvegarde d'état |

> [!WARNING] Fichiers .avhdx et checkpoints
> Quand un checkpoint est actif, Hyper-V crée un fichier `.avhdx` (différentiel) et écrit toutes les nouvelles modifications dedans au lieu du `.vhdx` principal. C'est pourquoi les checkpoints qui s'accumulent dégradent les performances — chaque accès disque doit traverser la chaîne de différentiels. Une raison de plus pour désactiver les checkpoints automatiques.

> [!TIP] Utiliser un second disque
> Si tu as un second SSD (par exemple `D:`), stocke les VM dessus. Ça évite de remplir le disque système et améliore les performances en répartissant les I/O.

---

## Créer une machine virtuelle

### Génération 1 vs Génération 2

| Caractéristique | Génération 1 | Génération 2 |
|----------------|-------------|-------------|
| Firmware | BIOS (legacy) | UEFI |
| Disque de boot | IDE uniquement | SCSI (plus rapide) |
| Secure Boot | ❌ | ✅ |
| TPM virtuel | ❌ | ✅ |
| Boot PXE | Carte réseau legacy | Carte réseau standard |
| OS supportés | 32 et 64 bits | 64 bits uniquement |
| Performances | Bonnes | Meilleures (boot + I/O) |

> [!WARNING] Windows 11 exige la Génération 2
> Windows 11 requiert TPM 2.0 et Secure Boot, qui ne sont disponibles qu'en **Génération 2**. Une VM Génération 1 ne pourra pas installer Windows 11 (l'installeur refusera).

### Types de disques virtuels (VHDX)

| Type | Espace disque | Performance | Usage |
|------|-------------|-------------|-------|
| **Dynamique** | N'utilise que l'espace réellement écrit (grandit au fil du temps) | Légèrement inférieure (~10-15%) | Lab, test, développement |
| **Fixe** | Alloue immédiatement toute la taille définie | Meilleure (pas de fragmentation) | Production |
| **Différentiel** | Stocke uniquement les différences par rapport à un disque parent | Variable | Scénarios de test rapides |

> [!TIP] En lab, utilise des disques dynamiques
> Un disque dynamique de 60 Go ne prendra que ~15 Go sur ton SSD après l'installation de Windows 11. C'est ce qui permet de faire tourner 3 VM sur un SSD de 256 Go.

### Création via l'interface graphique (Gestionnaire Hyper-V)

1. **Action** → **Nouveau** → **Ordinateur virtuel**
2. Nom : `PC01`
3. Génération : **Génération 2**
4. Mémoire : `4096 Mo` (cocher mémoire dynamique)
5. Réseau : `vSwitch-Rennes`
6. Disque : VHDX dynamique, `60 Go`
7. Installation : monter l'ISO Windows 11

![w11-01-hyperv-1](https://cours.kaya.ovh/windows11/assets/captures/w11-01-hyperv-1.png)

### Création via PowerShell

```powershell
# Créer la VM (dossier D:\HyperV\PC01)
New-VM -Name "PC01" `
    -Generation 2 `
    -MemoryStartupBytes 4GB `
    -NewVHDPath "D:\HyperV\PC01\PC01.vhdx" `
    -NewVHDSizeBytes 64GB `
    -SwitchName "vSwitch-Rennes" `
    -Path "D:\HyperV"

# 2 processeurs virtuels minimum (prérequis Windows 11)
Set-VMProcessor -VMName "PC01" -Count 2

# Mémoire STATIQUE pendant l'installation (voir l'avertissement ci-dessous)
Set-VMMemory -VMName "PC01" -DynamicMemoryEnabled $false

# Monter l'ISO Windows 11
Add-VMDvdDrive -VMName "PC01" `
    -Path "D:\ISO\Win11_26H2_French_x64.iso"

# Configurer le boot sur le DVD en premier
$dvd = Get-VMDvdDrive -VMName "PC01"
Set-VMFirmware -VMName "PC01" -FirstBootDevice $dvd

# Activer le TPM virtuel (obligatoire pour Windows 11)
Set-VMKeyProtector -VMName "PC01" -NewLocalKeyProtector
Enable-VMTPM -VMName "PC01"
```

> [!WARNING] Mémoire dynamique et installation de Windows
> Avec la mémoire dynamique, Windows Setup peut réclamer de la RAM plus vite que Hyper-V ne l'alloue : l'application de l'image échoue alors avec `0x800705AA` (ressources insuffisantes), tard et sans cause évidente. Installer en mémoire **statique** (4 à 6 Go), puis réactiver la mémoire dynamique une fois Windows installé si besoin.

> [!TIP] « Press any key to boot from CD or DVD »
> Sur une VM Génération 2, ce message ne reste affiché que quelques secondes. Ouvrir la console (`vmconnect localhost PC01`) **avant** de démarrer la VM et appuyer sur une touche, sinon la VM tente le réseau (PXE) puis échoue avec « No operating system was loaded ».

### Vérifier la VM

```powershell
# Résumé de la VM
Get-VM -Name "PC01" | Format-List Name, Generation, State, MemoryAssigned

# Vérifier que le TPM est activé
Get-VMSecurity -VMName "PC01"

# Démarrer la VM
Start-VM -VMName "PC01"
```

---

## Checkpoints (points de contrôle)

Les checkpoints permettent de **sauvegarder l'état d'une VM** à un instant donné et d'y revenir si nécessaire.

![w11-01-hyperv-3](https://cours.kaya.ovh/windows11/assets/captures/w11-01-hyperv-3.png)

### Deux types de checkpoints

| Type | Capture | Restauration | Usage |
|------|---------|-------------|-------|
| **Production** (défaut) | Utilise VSS pour un état cohérent sur disque | VM redémarre éteinte | Production, serveurs |
| **Standard** | Capture l'état mémoire complet (comme une hibernation) | VM reprend exactement là où elle était | Lab, développement |

```powershell
# Choisir le type de checkpoint pour une VM
Set-VM -Name "PC01" -CheckpointType Standard

# Créer un checkpoint
Checkpoint-VM -Name "PC01" -SnapshotName "Avant-installation"

# Lister les checkpoints
Get-VMCheckpoint -VMName "PC01"

# Restaurer un checkpoint
Restore-VMCheckpoint -VMName "PC01" -Name "Avant-installation" -Confirm:$false

# Supprimer un checkpoint (fusionne le différentiel)
Remove-VMCheckpoint -VMName "PC01" -Name "Avant-installation"
```

### Désactiver les checkpoints automatiques

Par défaut, Hyper-V crée un checkpoint automatique **à chaque démarrage** de la VM. Ces checkpoints s'accumulent, consomment de l'espace disque et peuvent ralentir les performances. En lab, on préfère les créer **manuellement** quand on en a besoin.

```powershell
# Désactiver les checkpoints automatiques sur une VM
Set-VM -Name "PC01" -AutomaticCheckpointsEnabled $false

# Vérifier
Get-VM -Name "PC01" | Select-Object Name, AutomaticCheckpointsEnabled
```

> [!WARNING] Les checkpoints ne remplacent pas les sauvegardes
> Un checkpoint est stocké **sur le même disque** que la VM. Si le disque tombe en panne, tout est perdu. En production, on utilise de vraies sauvegardes (wbadmin, Veeam, etc.).

---

## Export et import de VM

Utile pour dupliquer une VM ou la transférer sur un autre poste.

```powershell
# Exporter une VM (doit être arrêtée ou en pause)
Export-VM -Name "PC01" -Path "D:\Export"

# Importer une VM
Import-VM -Path "D:\Export\PC01\Virtual Machines\*.vmcx" -Copy -GenerateNewId
```

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> - **Activer Hyper-V** : `Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All`
> - **Créer un switch** : `New-VMSwitch -Name "vSwitch-Rennes" -SwitchType Internal`
> - **Configurer le NAT** : `New-NetIPAddress` (passerelle) + `New-NetNat` (règle NAT)
> - **Créer une VM** : `New-VM -Generation 2` + `Set-VMKeyProtector` + `Enable-VMTPM`
> - **Gérer les checkpoints** : `Checkpoint-VM` / `Restore-VMCheckpoint`
> - **Exporter/importer** : `Export-VM` / `Import-VM`
> - **Vérifier** : `Get-VMSwitch` / `Get-VM` / `Get-NetNat` / `Get-VMCheckpoint`

---

## Plan d'adressage du lab — Entreprise Fournil

| Machine | Rôle | IP | Passerelle | DNS |
|---------|------|----|------------|-----|
| Hôte (vEthernet) | Passerelle NAT | `192.168.3.254` | — | — |
| PC01 | Poste admin Windows 11 | `192.168.3.10` | `192.168.3.254` | `8.8.8.8` (puis SRV01) |
| SRV01 | Serveur AD/DNS/DHCP | `192.168.3.1` | `192.168.3.254` | `192.168.3.1` (lui-même) |
| PC02 | Poste déploiement (boot ISO) | DHCP | `192.168.3.254` | via DHCP |
