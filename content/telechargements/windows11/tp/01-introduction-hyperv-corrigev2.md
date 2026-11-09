# TP 01 — Introduction à Windows 11 et lab Hyper-V — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h30

> Chapitres associés : [01. Introduction à Windows 11 et lab Hyper-V](https://kayasam.github.io/windows11/windows11/01-introduction-hyperv/)

---

## Objectifs

- Identifier précisément la version, le build et l'édition d'un poste Windows 11
- Vérifier les prérequis et activer Hyper-V sur le poste hôte
- Construire le réseau du lab : switch interne + NAT
- Créer la VM `PC01` conforme aux exigences de Windows 11
- Maîtriser les points de contrôle (checkpoints)

---

## Prérequis

- Poste hôte Windows 11 **Pro, Entreprise ou Éducation**, compte administrateur
- ISO Windows 11 26H2 (ou 25H2) française dans `D:\ISO\`
- Terminal PowerShell **administrateur**

---

## Partie A — Identifier son Windows (15 min)

**A1.** Ouvre `winver`. Relève la version et le build complet (avec le numéro après le point).

> [!success]- Afficher la correction — A1
> `Win + R` → `winver`. Sur le lab formateur : **Version 26H2 (build de système d'exploitation 26300.9711)**.
> Le nombre après le point (UBR, *Update Build Revision*) augmente à chaque mise à jour cumulative : c'est lui qui dit si le poste est à jour.

**A2.** Retrouve les mêmes informations en PowerShell, sans interface graphique.

> [!success]- Afficher la correction — A2
> ```powershell
> Get-ComputerInfo | Select-Object OsName, OSDisplayVersion, OsBuildNumber
> (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion') |
>     Select-Object DisplayVersion, CurrentBuild, UBR, EditionID
> ```
> Résultat sur le lab :
> ```
> DisplayVersion CurrentBuild  UBR EditionID
> -------------- ------------  --- ---------
> 26H2           26300        9711 Professional
> ```

**A3.** Lis la valeur `ProductName` dans `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion`. Que constates-tu ? Comment un script doit-il tester qu'il tourne sur Windows 11 ?

> [!success]- Afficher la correction — A3
> ```powershell
> (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName
> # Windows 10 Pro
> ```
> La valeur indique **Windows 10 Pro** alors que le poste est en Windows 11 26H2 : Microsoft ne l'a jamais modifiée, pour ne pas casser d'anciennes applications.
> Un script doit tester le **build** :
> ```powershell
> $build = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
> if ($build -ge 22000) { "Windows 11" } else { "Windows 10" }
> ```
> `Get-ComputerInfo` (propriété `OsName`) et `winver` affichent bien « Windows 11 ».

**A4.** Ton poste est en 25H2. Comment passera-t-il en 26H2, et combien de redémarrages cela demandera-t-il ?

> [!success]- Afficher la correction — A4
> Par un **package d'activation** (*enablement package*) distribué par Windows Update : le code de la 26H2 est déjà présent, désactivé, dans les mises à jour cumulatives de la 25H2. Le package ne fait qu'**activer** les fonctionnalités : **un seul redémarrage**, quelques minutes, comme une mise à jour mensuelle.
> Une montée depuis la 23H2 ou depuis Windows 10 reste une vraie mise à niveau (réinstallation en place, plus longue).

**A5.** Un client a encore 40 postes Windows 10 22H2. Quels sont ses risques et ses options ?

> [!success]- Afficher la correction — A5
> - **Risque** : Windows 10 n'a plus de correctifs de sécurité depuis le **14 octobre 2025**. Chaque faille découverte depuis reste ouverte.
> - **Options** :
>   1. Vérifier la compatibilité matérielle (TPM 2.0, Secure Boot, processeur) et **mettre à niveau** les postes compatibles (chapitre 02) ;
>   2. Remplacer les postes non compatibles (ou les passer sur **Windows 365**, avec un client léger) ;
>   3. En attendant, souscrire à **ESU** (payant, limité dans le temps) pour garder les correctifs de sécurité.

---

## Partie B — Prérequis et activation d'Hyper-V (15 min)

**B1.** Vérifie que le processeur et le firmware permettent Hyper-V. Donne deux méthodes.

> [!success]- Afficher la correction — B1
> - `systeminfo` → section **Configuration requise pour Hyper-V** : toutes les lignes à **Oui**. Si on lit « Un hyperviseur a été détecté », Hyper-V est déjà actif.
> - Gestionnaire des tâches → **Performances** → **Processeur** → ligne **Virtualisation : Activé**.
> - En PowerShell :
> ```powershell
> Get-ComputerInfo -Property "HyperV*"
> ```

**B2.** Active Hyper-V en PowerShell. Faut-il redémarrer ?

> [!success]- Afficher la correction — B2
> ```powershell
> Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
> ```
> Oui, un **redémarrage** est obligatoire : l'hyperviseur se charge au démarrage, sous Windows.

**B3.** Vérifie que le service de gestion Hyper-V tourne et compte les cmdlets du module `Hyper-V`.

> [!success]- Afficher la correction — B3
> ```powershell
> Get-Service vmms
> Get-Command -Module Hyper-V | Measure-Object
> ```
> `vmms` (*Virtual Machine Management Service*) doit être `Running`. Le module compte plus de 200 cmdlets.

---

## Partie C — Réseau du lab (20 min)

**C1.** Définis `D:\HyperV` comme dossier par défaut des VM et des disques.

> [!success]- Afficher la correction — C1
> ```powershell
> Set-VMHost -VirtualHardDiskPath "D:\HyperV" -VirtualMachinePath "D:\HyperV"
> Get-VMHost | Select-Object VirtualHardDiskPath, VirtualMachinePath
> ```

**C2.** Crée le switch interne `vSwitch-Rennes`, donne l'IP `192.168.3.254/24` à son interface hôte, puis crée le NAT `NAT-Rennes` pour `192.168.3.0/24`.

> [!success]- Afficher la correction — C2
> ```powershell
> New-VMSwitch -Name "vSwitch-Rennes" -SwitchType Internal
> New-NetIPAddress -InterfaceAlias "vEthernet (vSwitch-Rennes)" -IPAddress 192.168.3.254 -PrefixLength 24
> New-NetNat -Name "NAT-Rennes" -InternalIPInterfaceAddressPrefix "192.168.3.0/24"
> ```
> Vérification :
> ```powershell
> Get-VMSwitch vSwitch-Rennes | Select-Object Name, SwitchType
> Get-NetIPAddress -InterfaceAlias "vEthernet (vSwitch-Rennes)" -AddressFamily IPv4
> Get-NetNat | Select-Object Name, InternalIPInterfaceAddressPrefix, Active
> ```

**C3.** `New-NetNat` répond : *« Instance MSFT_NetNat already exists »*. Que se passe-t-il et comment corriger sans casser l'existant ?

> [!success]- Afficher la correction — C3
> Windows n'accepte qu'**un seul** NAT par préfixe. Un ancien lab utilise déjà `192.168.3.0/24` :
> ```powershell
> Get-NetNat | Select-Object Name, InternalIPInterfaceAddressPrefix
> # NAT-Fournil   192.168.3.0/24
> ```
> Deux solutions :
> - **réutiliser** ce NAT : il traduit tout ce qui vient de `192.168.3.0/24`, quel que soit le switch. Il suffit que l'IP `.254` soit sur `vEthernet (vSwitch-Rennes)` (et retirée de l'ancienne interface) ;
> - ou le **supprimer** s'il n'est plus utile : `Remove-NetNat -Name NAT-Fournil`.
>
> C'est exactement le cas rencontré sur le lab formateur lors de sa reconstruction.

**C4.** Pourquoi n'utilise-t-on pas le **Default Switch** pour `PC01` et `SRV01` ? Pourquoi l'utilisera-t-on quand même pour `MASTER` ?

> [!success]- Afficher la correction — C4
> Le Default Switch change de plage IP à **chaque redémarrage de l'hôte** et impose son DHCP/DNS : impossible d'y poser un contrôleur de domaine avec une IP fixe.
> `MASTER` n'a besoin que d'Internet (Windows Update, WinGet) et ne doit **jamais** voir le domaine ni le DHCP de `SRV01` : le Default Switch lui convient parfaitement.

---

## Partie D — Créer la VM PC01 (25 min)

**D1.** Crée `PC01` en PowerShell : Génération 2, 64 Go, `vSwitch-Rennes`, 2 vCPU, 4 Go de mémoire **statique**, ISO Windows 11 montée, démarrage sur le DVD.

> [!success]- Afficher la correction — D1
> ```powershell
> New-VM -Name "PC01" -Generation 2 -MemoryStartupBytes 4GB `
>     -NewVHDPath "D:\HyperV\PC01\PC01.vhdx" -NewVHDSizeBytes 64GB `
>     -SwitchName "vSwitch-Rennes" -Path "D:\HyperV"
> Set-VMProcessor -VMName "PC01" -Count 2
> Set-VMMemory -VMName "PC01" -DynamicMemoryEnabled $false
> $dvd = Add-VMDvdDrive -VMName "PC01" -Path "D:\ISO\Win11_26H2_French_x64.iso" -Passthru
> Set-VMFirmware -VMName "PC01" -FirstBootDevice $dvd
> ```

**D2.** Ajoute un TPM virtuel. Pourquoi faut-il d'abord un protecteur de clé ?

> [!success]- Afficher la correction — D2
> ```powershell
> Set-VMKeyProtector -VMName "PC01" -NewLocalKeyProtector
> Enable-VMTPM -VMName "PC01"
> ```
> Le TPM virtuel conserve des secrets (clés BitLocker, Windows Hello). Hyper-V chiffre son état avec une clé, protégée par le **protecteur de clé** (ici local, via le *Host Guardian*). Sans protecteur, `Enable-VMTPM` refuse de s'exécuter.

**D3.** Vérifie : génération, mémoire, processeurs, TPM, Secure Boot.

> [!success]- Afficher la correction — D3
> ```powershell
> Get-VM PC01 | Format-List Name, Generation, MemoryStartup, ProcessorCount
> Get-VMSecurity -VMName PC01 | Select-Object TpmEnabled
> Get-VMFirmware -VMName PC01 | Select-Object SecureBoot, SecureBootTemplate
> ```
> Sur le lab :
> ```
> Name           : PC01
> Generation     : 2
> MemoryStartup  : 6442450944
> ProcessorCount : 2
> TpmEnabled     : True
> ```
> Le Secure Boot est actif par défaut sur une VM Génération 2, avec le modèle **Microsoft Windows**.

**D4.** Désactive les checkpoints automatiques et passe en checkpoints **Standard**. Pourquoi ces deux choix en lab ?

> [!success]- Afficher la correction — D4
> ```powershell
> Set-VM -Name PC01 -AutomaticCheckpointsEnabled $false -CheckpointType Standard
> ```
> - Les checkpoints automatiques (un à chaque démarrage) s'accumulent, consomment de l'espace et rallongent la chaîne de disques différentiels.
> - Le type **Standard** capture aussi la mémoire : la VM revient exactement là où elle était. C'est ce qu'on veut en lab, pour rejouer une manipulation.

**D5.** Ouvre la console de `PC01` puis démarre-la. Que faut-il faire au message *« Press any key to boot from CD or DVD »* ? Que se passe-t-il si on le rate ?

> Ne lance pas l'installation au-delà du premier écran : elle fait l'objet du TP 02.

> [!success]- Afficher la correction — D5
> ```powershell
> vmconnect.exe localhost PC01
> Start-VM PC01
> ```
> Il faut appuyer sur une touche **dans les 5 secondes**. Sinon, le firmware passe au périphérique suivant (carte réseau, PXE), puis affiche *« No operating system was loaded »*. Il suffit alors de redémarrer la VM (`Ctrl+Alt+Suppr` dans la console, ou `Restart-VM PC01 -Force`) et d'être plus rapide.

---

## Partie E — Points de contrôle (15 min)

**E1.** Éteins `PC01`, crée un checkpoint `Avant-installation` et liste les checkpoints.

> [!success]- Afficher la correction — E1
> ```powershell
> Stop-VM PC01 -Force
> Checkpoint-VM -Name PC01 -SnapshotName "Avant-installation"
> Get-VMCheckpoint -VMName PC01 | Select-Object Name, CreationTime, CheckpointType
> ```

**E2.** Dans `D:\HyperV\PC01\`, quel nouveau fichier est apparu ? À quoi sert-il ?

> [!success]- Afficher la correction — E2
> Un fichier **`PC01_<GUID>.avhdx`** : un disque **différentiel**. Toutes les écritures faites après le checkpoint vont dedans ; `PC01.vhdx` est figé à l'état du checkpoint.
> ```powershell
> (Get-VMHardDiskDrive -VMName PC01).Path   # pointe désormais vers le .avhdx
> ```
> Ce détail sera crucial au chapitre 15 : pour capturer l'image d'une VM qui a un checkpoint, il faut monter le **disque actif** (le `.avhdx`), pas le `.vhdx`.

**E3.** Explique la différence entre un checkpoint **Standard** et un checkpoint **Production**.

> [!success]- Afficher la correction — E3
> | | Standard | Production (défaut) |
> |-|----------|--------------------|
> | Capture | Disque + **mémoire** | Disque seulement, cohérent via VSS dans la VM |
> | Restauration | VM relancée là où elle était | VM redémarre **éteinte**, comme après une coupure propre |
> | Usage | Lab, tests | Serveurs (pas d'état mémoire « figé » incohérent pour un SGBD, un DC…) |

**E4.** Un collègue dit : « J'ai des checkpoints, donc j'ai une sauvegarde ». Réponds-lui.

> [!success]- Afficher la correction — E4
> Faux. Le checkpoint est sur **le même disque** que la VM et dépend du `.vhdx` parent : si le disque de l'hôte meurt ou si le parent est corrompu, tout est perdu. De plus, une longue chaîne de checkpoints dégrade les performances. Une sauvegarde est **une copie ailleurs** (autre disque, autre site), testée par une restauration.

---

## Partie F — Bonus

**F1.** Écris un script `New-LabVM.ps1` qui prend un paramètre `-Name` et crée une VM conforme à la partie D.

> [!success]- Afficher la correction — F1
> ```powershell
> param(
>     [Parameter(Mandatory)][string]$Name,
>     [string]$Iso = "D:\ISO\Win11_26H2_French_x64.iso",
>     [string]$Switch = "vSwitch-Rennes"
> )
> New-VM -Name $Name -Generation 2 -MemoryStartupBytes 4GB `
>     -NewVHDPath "D:\HyperV\$Name\$Name.vhdx" -NewVHDSizeBytes 64GB `
>     -SwitchName $Switch -Path "D:\HyperV" | Out-Null
> Set-VMProcessor -VMName $Name -Count 2
> Set-VMMemory -VMName $Name -DynamicMemoryEnabled $false
> Set-VM -Name $Name -AutomaticCheckpointsEnabled $false -CheckpointType Standard
> Set-VMKeyProtector -VMName $Name -NewLocalKeyProtector
> Enable-VMTPM -VMName $Name
> $dvd = Add-VMDvdDrive -VMName $Name -Path $Iso -Passthru
> Set-VMFirmware -VMName $Name -FirstBootDevice $dvd
> Get-VM $Name
> ```
> Exemple : `.\New-LabVM.ps1 -Name PC02`. Un script de ce type a servi à reconstruire le lab formateur (`Ressources/lab/`).

**F2.** Exporte `PC01` (éteinte) dans `D:\Export`, puis réimporte-la sous un nouvel identifiant.

> [!success]- Afficher la correction — F2
> ```powershell
> Export-VM -Name PC01 -Path D:\Export
> Import-VM -Path (Get-Item "D:\Export\PC01\Virtual Machines\*.vmcx").FullName `
>     -Copy -GenerateNewId -VirtualMachinePath D:\HyperV\PC01-copie -VhdDestinationPath D:\HyperV\PC01-copie
> ```
> `-GenerateNewId` évite le conflit avec la VM d'origine. Attention : la copie a le **même nom de machine et le même SID** côté Windows. Pour multiplier des postes, on passera par Sysprep (chapitre 14).

---

[Retour à l'énoncé](https://kayasam.github.io/windows11/windows11/01-introduction-hyperv/tp)
