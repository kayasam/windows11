# TP 16. Déployer Windows 11 : ISO, réseau, migration, moderne — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 2h30

> Chapitres associés : [16. Déployer Windows 11 : ISO, réseau, migration, moderne](https://cours.kaya.ovh/windows11/windows11/16-deploiement/)

> [!NOTE] Tout ce TP a été rejoué sur le lab le 08/11/2026
> Il a fallu **trois** déploiements ratés de `PC02` (pièges B2, B3 et le nom `PC-*`) avant le zéro clic réussi. Ces échecs font désormais partie du TP : ce sont exactement ceux que rencontrent les administrateurs en 2026.

---

## Objectifs

- Construire une ISO de déploiement **zéro clic** à partir de `MASTER.wim`
- Déployer `PC02`, diagnostiquer un échec de Setup, vérifier le résultat
- Joindre `PC02` au domaine et y migrer les données de `stagiaire` avec USMT
- Choisir une méthode de déploiement selon le contexte (WDS, MDT, ConfigMgr, Autopilot)

---

## Prérequis

- `MASTER.wim` (TP 15), `autounattend-fournil-26h2.xml` (TP 13), ISO officielle 26H2
- ADK sur `PC01` (oscdimg, USMT) ; partage `\\SRV01\USMT$`
- **40 Go libres** sur l'hôte

---

## Partie A — L'ISO personnalisée (30 min)

**A1.** Copie le contenu de l'ISO officielle dans `D:\ISO-Deploiement`. Pourquoi `robocopy` plutôt que `Copy-Item` ?

> [!success]- Afficher la correction — A1
> ```powershell
> Mount-DiskImage -ImagePath D:\ISO\Win11_26H2_French_x64.iso      # ex. lettre E:
> robocopy E:\ D:\ISO-Deploiement /E /COPY:DAT /R:1 /W:1
> Dismount-DiskImage -ImagePath D:\ISO\Win11_26H2_French_x64.iso
> ```
> `Copy-Item -Recurse` peut mal copier certains fichiers de démarrage EFI (`boot\EFI_EX`), d'où une ISO qui échoue en toute fin d'installation (`BfspCopyFile`, `0x8007000B`). `robocopy /E /COPY:DAT` duplique fidèlement (débit relevé : ~45 Go/min sur SSD).

**A2.** Remplace `sources\install.wim` par `MASTER.wim`. Quel obstacle rencontres-tu ?

> [!success]- Afficher la correction — A2
> ```powershell
> attrib -r D:\ISO-Deploiement\sources\install.wim
> Copy-Item D:\Images\MASTER.wim D:\ISO-Deploiement\sources\install.wim -Force
> ```
> Obstacle : les fichiers copiés depuis une ISO sont en **lecture seule**. `Copy-Item -Force` passe outre ici, mais un outil comme DISM refusera de monter un `.wim` en lecture seule (TP 15).

**A3.** Dépose le fichier de réponse à la racine. Sous quel nom ?

> [!success]- Afficher la correction — A3
> ```powershell
> Copy-Item C:\…\autounattend-fournil-26h2.xml D:\ISO-Deploiement\autounattend.xml
> ```
> Exactement **`autounattend.xml`**, à la **racine** : c'est le nom que Windows Setup cherche sur les supports amovibles et optiques. Journal de Setup sur le lab : `UnattendSearchExplicitPath: Found usable unattend file for pass [windowsPE] at [D:\autounattend.xml]`.

**A4.** Construis `MASTER-Deploiement.iso` en BIOS + UEFI, **sans** le message « Press any key ». Quel risque cela crée-t-il ?

> [!success]- Afficher la correction — A4
> ```cmd
> set OSC=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg
> "%OSC%\oscdimg.exe" -m -o -u2 -udfver102 ^
>   -bootdata:2#p0,e,bD:\ISO-Deploiement\boot\etfsboot.com#pEF,e,b"%OSC%\efisys_noprompt.bin" ^
>   D:\ISO-Deploiement D:\ISO\MASTER-Deploiement.iso
> ```
> ISO de **9,2 Go** sur le lab. `efisys_noprompt.bin` supprime « *Press any key to boot from CD or DVD* » : vérifié, `PC02` a démarré sans aucune touche.
> **Risque** : un poste qui démarre dessus par erreur est **effacé sans question** (`WillWipeDisk`). Étiqueter, ne pas laisser traîner.

---

## Partie B — Déployer PC02 (30 min)

**B1.** Crée `PC02` (Gen 2, TPM, 2 vCPU, 6 Go statiques, `vSwitch-Rennes`) et démarre-la sur l'ISO. Combien de clics faut-il ?

> [!success]- Afficher la correction — B1
> ```powershell
> New-VM -Name PC02 -Generation 2 -MemoryStartupBytes 6GB -NewVHDPath D:\HyperV\PC02\PC02.vhdx -NewVHDSizeBytes 64GB -SwitchName vSwitch-Rennes -Path D:\HyperV
> Set-VMMemory PC02 -DynamicMemoryEnabled $false; Set-VMProcessor PC02 -Count 2
> Set-VMKeyProtector -VMName PC02 -NewLocalKeyProtector; Enable-VMTPM -VMName PC02
> $dvd = Add-VMDvdDrive PC02 -Path D:\ISO\MASTER-Deploiement.iso -Passthru
> Set-VMFirmware PC02 -FirstBootDevice $dvd
> Start-VM PC02
> ```
> **Zéro clic** : de la mise sous tension à l'écran de connexion, aucune intervention (une quinzaine de minutes). Au redémarrage, Setup a placé *Windows Boot Manager* en tête de l'ordre de démarrage UEFI : l'ISO ne se relance pas en boucle.

**B2.** *(Situation vécue sur le lab)* L'installation s'arrête sur « **Échec de l'installation de Windows 11** ». Comment lire les journaux de Setup sur ce poste ?

> [!success]- Afficher la correction — B2
> Sur l'écran d'erreur : **`Shift + F10`** ouvre une invite. Mais le WinPE de Setup n'a ni PowerShell ni `findstr` : on peut lire avec `type`, ou mieux, **éteindre la VM et monter son disque sur l'hôte** :
> ```powershell
> Mount-VHD D:\HyperV\PC02\PC02.vhdx -ReadOnly
> Get-Content 'E:\$WINDOWS.~BT\Sources\Panther\setupact.log' | Select-String ', Error' | Select-Object -Last 30
> ```
> Emplacements : `$WINDOWS.~BT\Sources\Panther\` (phase WinPE / application), `Windows\Panther\` (après le premier redémarrage), `Windows\Panther\UnattendGC\` (traitement du fichier de réponse en specialize/oobe).
> Les erreurs `hwreqchk`, `OneSettings`, `0x80072EE7` (pas de réseau, télémétrie) sont du **bruit** : chercher les lignes `SP` (Setup Platform).

**B3.** Le journal contient `CAddUnattend::DoExecute: Failed to save copy of answer file to …\Panther\unattend-original.xml (0x80070050)`. Explique et corrige.

> [!success]- Afficher la correction — B3
> ```
> CAddUnattend::DoExecute: Failed to save copy of answer file to …\NewOS\WINDOWS\Panther\unattend-original.xml (0x80070050)
> ExecuteOperations: Operations cannot be sorted. This is a fatal failure.
> ```
> `MASTER` avait été installée avec un fichier de réponse : Setup en avait gardé une copie (`Windows\Panther\unattend-original.xml`) **capturée dans l'image**. Le Setup des médias 24H2+ refuse d'écraser ce fichier (`0x80070050` = *le fichier existe*).
> Correction hors ligne (TP 15) :
> ```cmd
> attrib -r D:\Images\MASTER.wim
> Dism /Mount-Image /ImageFile:D:\Images\MASTER.wim /Index:1 /MountDir:C:\Mount
> del C:\Mount\Windows\Panther\unattend-original.xml C:\Mount\Windows\Panther\unattend.xml
> Dism /Unmount-Image /MountDir:C:\Mount /Commit
> ```
> **Puis, au déploiement suivant**, nouvel échec en fin d'installation :
> ```
> CRelocateOS: Cannot move path …\NewOS\Windows.old from Windows.NEW. Error: 0x000000B7
> ```
> Un dossier `C:\Windows.old` **vide** (et `C:\Recovery`) laissé par le nouveau Setup sur `MASTER` avait aussi été capturé. Même correction hors ligne : `rd C:\Mount\Windows.old` et `rd C:\Mount\Recovery`.
> **Et enfin**, au premier démarrage : « *L'ordinateur a redémarré de manière inattendue* » — `UnattendGC\setuperr.log` : `ComputerName: failed to set the computer name [hr=0x80070057]`. Le fichier de réponse de la v1 du cours utilisait `PC-*` ; le `*` ne fonctionne que **seul**. Corrigé en `*`.
> Règle tirée de tout cela : **avant de distribuer une image, la monter et vérifier sa racine et `Windows\Panther`**, et tester le fichier de réponse sur une VM.

**B4.** Une fois sur le bureau, vérifie : nom du poste, compte créé, version de l'image, logiciels, partitions, fuseau, BitLocker, adresse IP.

> [!success]- Afficher la correction — B4
> ```powershell
> $env:COMPUTERNAME; Get-Content C:\Fournil\version-image.txt
> Get-LocalUser | Select-Object Name, Enabled
> Get-Partition | Select-Object PartitionNumber, Type, @{N='Mo';E={[math]::Round($_.Size/1MB)}}
> Get-BitLockerVolume C: | Select-Object VolumeStatus, ProtectionStatus
> Test-Path 'C:\Program Files\7-Zip\7z.exe'; (Get-TimeZone).Id
> Get-NetIPConfiguration
> ```
> Résultat réel :
> ```
> FOURNIL-AN4OLJL                                   ← nom aléatoire préfixé par RegisteredOrganization
> Image Fournil v2026.11 - 2026-11-08T07:10:21
> 26H2 26300.9457 Professional / Org=Fournil
> Administrateur False · Utilisateur True
> 1 System 200 · 2 Reserved 16 · 3 Basic 64407 · 4 Recovery 910   ← WinRE créé par Setup
> FullyDecrypted / Off                              ← PreventDeviceEncryption hérité de MASTER
> 7-Zip : True · Romance Standard Time
> IP 169.254.x.x                                    ← SRV01 était arrêté ; après redémarrage : 192.168.3.100 (DHCP)
> ```
> BitLocker est **à activer** avant la remise (TP 09) : c'est le revers de `PreventDeviceEncryption`.

**B5.** Le compte `Administrateur` intégré est-il actif sur `PC02` ? Pourquoi est-ce important ?

> [!success]- Afficher la correction — B5
> **Désactivé** (constaté). L'OOBE le désactive quand un autre compte administrateur est créé (`Utilisateur`). Important : en mode audit sur `MASTER`, on l'avait activé avec un mot de passe connu — s'il était resté actif, **tous** les postes déployés auraient eu le même compte administrateur au même mot de passe. LAPS (TP 11) le prendra en charge une fois le poste dans le domaine.

---

## Partie C — Domaine et migration (35 min)

**C1.** Joins `PC02` au domaine dans `OU=Ordinateurs,OU=Fournil`, sous le nom `PC02`.

> [!success]- Afficher la correction — C1
> ```powershell
> Add-Computer -DomainName ad.fournil.lab -NewName PC02 `
>     -OUPath "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab" `
>     -Credential (Get-Credential FOURNIL\Administrateur) -Restart
> ```
> Après redémarrage, sur le lab : `Nom: PC02 / domaine: ad.fournil.lab`, `gpresult` → **GPO-Postes-Securite** appliquée, administrateurs locaux : `FOURNIL\Admins du domaine, FOURNIL\GG-Admins-Postes, PC02\Administrateur, PC02\Utilisateur`.

**C2.** Sur `PC01`, capture le profil de `stagiaire` avec `scanstate` vers `\\SRV01\USMT$\Store\PC01`, en n'incluant que ce profil. Teste d'abord avec `/listfiles`.

> [!success]- Afficher la correction — C2
> ```cmd
> \\SRV01\USMT$\USMT\scanstate.exe C:\Temp\usmt-test /i:\\SRV01\USMT$\USMT\MigUser.xml ^
>     /ue:*\* /ui:FOURNIL\stagiaire /o /c /nocompress /listfiles:C:\Temp\usmt-files.txt
> \\SRV01\USMT$\USMT\scanstate.exe \\SRV01\USMT$\Store\PC01 /i:\\SRV01\USMT$\USMT\MigUser.xml ^
>     /i:\\SRV01\USMT$\USMT\MigApp.xml /ue:*\* /ui:FOURNIL\stagiaire /o /c /l:\\SRV01\USMT$\scan-PC01.log
> ```
> (Les binaires USMT ont été copiés de l'ADK de `PC01` vers `\\SRV01\USMT$\USMT` : un seul emplacement pour tous les postes.)

**C3.** Le magasin fait plusieurs gigaoctets pour quelques documents. Pourquoi ? Que faire ?

> [!success]- Afficher la correction — C3
> Relevés du lab pour deux fichiers de test : **6,9 Go** (MigDocs), **5,8 Go** (MigUser), **8,2 Go** (MigDocs + MigApp). `/listfiles` montre pourquoi : `MigDocs` ramasse les documents de **tout le disque** (`C:\WinPE_amd64`, une ISO de 567 Mo…), et USMT embarque aussi des éléments système — sons de `C:\Windows\Media`, définitions Defender, **cache de l'Optimisation de la distribution** (4,4 Go pour un seul fichier `content.bin`).
> Que faire : tester avec `/listfiles`, vider le cache (`Delete-DeliveryOptimizationCache -Force`), exclure les composants inutiles (`/genconfig:config.xml` puis `/config:config.xml`), restreindre par un XML personnalisé. Et surtout, dans un environnement Microsoft 365 : **OneDrive KFM**, qui rend la migration de données inutile.

**C4.** Sur `PC02`, restaure avec `loadstate`. Ouvre une session `stagiaire` et vérifie ses documents.

> [!success]- Afficher la correction — C4
> Sur `PC02` (joint au domaine), en administrateur :
> ```cmd
> \\SRV01\USMT$\USMT\loadstate.exe \\SRV01\USMT$\Store\PC01 /i:\\SRV01\USMT$\USMT\MigUser.xml ^
>     /i:\\SRV01\USMT$\USMT\MigApp.xml /ue:*\* /ui:FOURNIL\stagiaire /c /l:\\SRV01\USMT$\load-PC02.log
> ```
> Sur le lab : **1,1 minute**, code de sortie **3** (= des erreurs non bloquantes ont été ignorées grâce à `/c` : à lire dans le journal), et :
> ```
> C:\Users\stagiaire\Documents\recette-campagne.txt
> C:\Users\stagiaire\Documents\Planning\semaine46.txt
> Recette du pain de campagne
> Farine T80 1 kg, levain 300 g, eau 650 g, sel 20 g
> ```
> Les mêmes `/i:` qu'au `scanstate` sont obligatoires. À la première connexion de `stagiaire` sur `PC02`, il retrouve ses documents et son fond d'écran.

---

## Partie D — Choisir une méthode (20 min)

**D1.** Pour chaque situation, propose une méthode de déploiement et justifie :
1. Le Fournil (35 postes, un DC, pas de Microsoft 365) renouvelle 10 postes par an.
2. Une chaîne de 200 boulangeries, Microsoft 365 Business Premium, des postes livrés directement en magasin.
3. Un groupe industriel avec ConfigMgr et 8 000 postes.
4. Un client dont le prestataire a monté WDS + MDT en 2019 et qui « veut juste continuer ».

> [!success]- Afficher la correction — D1
> 1. **Le Fournil** (35 postes, DC, pas de M365) : **ISO personnalisée** (ou clé USB) + GPO + USMT. Peu de volume, pas d'infrastructure à entretenir. Envisager Microsoft 365 Business Premium à terme.
> 2. **200 boulangeries, M365 Business Premium** : **Windows Autopilot** + Intune + OneDrive KFM. Les postes partent directement du revendeur vers chaque magasin ; aucun technicien sur place.
> 3. **Groupe industriel, ConfigMgr, 8 000 postes** : **ConfigMgr OSD** (séquences de tâches, PXE, multidiffusion), souvent en co-gestion avec Intune pour préparer la suite.
> 4. **WDS + MDT de 2019** : migration à planifier (voir D2), vers ISO/USB personnalisée à court terme, puis Autopilot ou un outil tiers.

**D2.** Que dirais-tu au client n° 4 sur l'état de WDS et MDT en 2026 ?

> [!success]- Afficher la correction — D2
> - **MDT est retiré depuis le 6 janvier 2026** : plus de support, plus de correctifs, plus de garantie de compatibilité avec les prochaines versions de Windows, téléchargement susceptible de disparaître.
> - **WDS** : depuis la mise à jour **d'avril 2026**, le déploiement *mains libres* (fichier de réponse servi par WDS) est **bloqué par défaut** (faille CVE-2026-0386). Le réactiver (`AllowHandsFreeFunctionality = 1`) rouvre la faille. Le rôle est **déprécié** pour la prochaine version de Windows Server.
> - Leur infrastructure « marche encore », mais c'est une dette : chaque nouvelle version de Windows risque de la casser, sans recours. Proposer un plan de sortie.

---

## Partie E — Bonus

**E1.** Récupère le *hash matériel* de `PC02` pour Autopilot. Que contient le fichier ? À qui l'envoie-t-on ?

> [!success]- Afficher la correction — E1
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope Process -Force
> Install-Script Get-WindowsAutopilotInfo -Force
> Get-WindowsAutopilotInfo -OutputFile C:\Temp\autopilot-PC02.csv
> ```
> Le CSV contient le **numéro de série**, l'**ID de produit Windows** et le **hash matériel** (empreinte du matériel, quelques kilo-octets en Base64). On l'importe dans **Intune → Appareils → Windows → Inscription → Appareils** ; en production, c'est le **constructeur ou le revendeur** qui enregistre directement les postes vendus.

**E2.** Comment `PC02` pourrait-il rejoindre le domaine **automatiquement** pendant le déploiement ?

> [!success]- Afficher la correction — E2
> Composant **`Microsoft-Windows-UnattendedJoin`** en passe **specialize** du fichier de réponse : `JoinDomain = ad.fournil.lab`, `MachineObjectOU`, et des identifiants (`Credentials` : domaine, compte, mot de passe) d'un compte **délégué** pour joindre des ordinateurs. Le poste arrive sur le bureau déjà membre du domaine. Inconvénient : un mot de passe de compte de jonction dans le fichier (d'où un compte aux droits minimaux, et le nettoyage de `Windows\Panther`). Le poste doit joindre le DC au moment de specialize (réseau câblé, DNS par DHCP).

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp)
