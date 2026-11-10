---
title: "TP 16. Déployer Windows 11 : ISO, réseau, migration, moderne — Correction"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/16-deploiement"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/16-deploiement/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/16-deploiement-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp-corrigev2" aria-current="page">Corrigé</a></nav>

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 2h30

> Chapitres associés : [16. Déployer Windows 11 : ISO, réseau, migration, moderne](https://cours.kaya.ovh/windows11/windows11/16-deploiement/)

---

## Objectifs

- Déployer `PC02` **sans clic** depuis l'ISO **officielle** et un `autounattend.xml` complet (jonction au domaine, applications)
- Vérifier le résultat et savoir où chercher en cas d'échec
- Migrer les données de `stagiaire` avec USMT
- Choisir une méthode de déploiement selon le contexte (WDS, MDT, ConfigMgr, Autopilot)
- *(approfondissement)* Construire une ISO personnalisée à partir de `MASTER.wim`

---

## Prérequis

- ISO officielle Windows 11 26H2
- `autounattend-iso-officielle.xml` et `postinstall.ps1` (dossier `Ressources/Fichier-reponse/`)
- Domaine `ad.fournil.lab` avec DHCP actif et l'OU `OU=Ordinateurs,OU=Fournil` (TP 10)
- ADK sur `PC01` (oscdimg, USMT) ; partage `\\SRV01\USMT$`
- Partie F seulement : `MASTER.wim` (TP 15) et **40 Go libres** sur l'hôte

---

## Partie A — Lire le fichier de réponse (20 min)

**A1.** Ouvre `autounattend-iso-officielle.xml`. Pour chacune des trois passes (`windowsPE`, `specialize`, `oobeSystem`), indique ce qu'elle règle.

> [!success]- Afficher la correction — A1
> | Passe | Quand ? | Ce qu'elle règle dans ce fichier |
> |---|---|---|
> | `windowsPE` | Setup démarré sur l'ISO, avant de copier Windows | langue, **partitions UEFI/GPT** (EFI, MSR, Windows), édition Pro par la clé générique, acceptation du contrat |
> | `specialize` | premier démarrage de Windows installé | nom `PC02`, fuseau horaire, **`PreventDeviceEncryption`**, **jonction au domaine** (`UnattendedJoin`) |
> | `oobeSystem` | écrans d'accueil (OOBE) | écrans masqués, compte local `admin` (Administrateurs), **une** ouverture de session automatique, `FirstLogonCommands` qui lance `postinstall.ps1` |

**A2.** Quel composant fait rejoindre le domaine au poste ? Que doit-il exister dans l'Active Directory avant le déploiement ?

> [!success]- Afficher la correction — A2
> Le composant **`Microsoft-Windows-UnattendedJoin`**, en passe `specialize` : `JoinDomain = ad.fournil.lab`, `MachineObjectOU`, et le compte autorisé à joindre des postes (`Credentials`).
> Il faut que l'OU **`OU=Ordinateurs,OU=Fournil`** existe (sinon la jonction échoue) et que le poste puisse **joindre le DC** à ce moment-là : réseau câblé, DHCP qui donne `SRV01` comme serveur DNS.
> En production, on utilise un compte **délégué** qui ne sait que joindre des ordinateurs, car son mot de passe est lisible dans le fichier.

**A3.** Pourquoi le bloc `AutoLogon` contient-il `<Domain>PC02</Domain>` ?

> [!success]- Afficher la correction — A3
> `admin` est un compte **local**. Sans `<Domain>`, Windows utilise le domaine par défaut du poste, qui vient de devenir `FOURNIL` : il tenterait d'ouvrir `FOURNIL\admin`, qui n'existe pas, et `postinstall.ps1` ne serait jamais lancé. `<Domain>PC02</Domain>` désigne le poste lui-même.

**A4.** À quoi sert `PreventDeviceEncryption` ici, puisqu'on ne fait pas de Sysprep ?

> [!success]- Afficher la correction — A4
> Depuis la 24H2, Windows **chiffre automatiquement** le disque dès l'installation, et garde la clé de récupération sur le poste (ou dans un compte Microsoft). Dans une entreprise, on veut que BitLocker soit activé **par GPO**, avec la clé **sauvegardée dans l'AD** (chapitre 11). `PreventDeviceEncryption` laisse le disque en clair jusqu'à cette activation maîtrisée. Ce n'est donc pas lié à Sysprep : c'est un choix d'administration.

---

## Partie B — Déployer PC02 (40 min)

**B1.** Construis la mini-ISO `reponses-pc02.iso` qui contient le fichier de réponse et `postinstall.ps1`. Sous quel nom le fichier de réponse doit-il y figurer ?

> [!success]- Afficher la correction — B1
> ```powershell
> New-Item D:\Images\reponses-pc02 -ItemType Directory -Force
> Copy-Item ...\Fichier-reponse\autounattend-iso-officielle.xml D:\Images\reponses-pc02\autounattend.xml
> Copy-Item ...\Fichier-reponse\postinstall.ps1 D:\Images\reponses-pc02\
> New-Item D:\ISO -ItemType Directory -Force
> $oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
> & $oscdimg -u2 -udfver102 -lREPONSES D:\Images\reponses-pc02 D:\ISO\reponses-pc02.iso
> ```
> Le fichier doit s'appeler exactement **`autounattend.xml`** et être à la **racine** : c'est le seul nom que Windows Setup cherche sur les supports. La mini-ISO fait environ 650 Ko.

**B2.** Crée `PC02` (Gen 2, TPM, 2 vCPU, 4 Go statiques, `vSwitch-Rennes`) avec **deux** lecteurs DVD : l'ISO officielle et la mini-ISO. Démarre-la. Combien de gestes faut-il ?

> [!success]- Afficher la correction — B2
> ```powershell
> New-VM -Name PC02 -Generation 2 -NewVHDPath D:\HyperV\PC02\PC02.vhdx -NewVHDSizeBytes 64GB -SwitchName vSwitch-Rennes -Path D:\HyperV
> Set-VMMemory PC02 -DynamicMemoryEnabled $false -StartupBytes 4GB; Set-VMProcessor PC02 -Count 2
> Set-VMKeyProtector -VMName PC02 -NewLocalKeyProtector; Enable-VMTPM -VMName PC02
> $dvd = Add-VMDvdDrive PC02 -Path D:\ISO\Win11_26H2_French_x64.iso -Passthru
> Add-VMDvdDrive PC02 -Path D:\ISO\reponses-pc02.iso
> Set-VMFirmware PC02 -FirstBootDevice $dvd
> Start-VM PC02; vmconnect.exe localhost PC02
> ```
> **Un seul geste** : appuyer sur une touche au message « *Press any key to boot from CD or DVD* ». Ensuite, rien : partitionnement, installation, jonction au domaine, ouverture de session, applications, nettoyage et redémarrage s'enchaînent seuls.
> Mesuré sur le lab le 09/11/2026 : **9 minutes** entre la touche (21:44:41) et la fin de la post-installation (21:53:08). La jonction au domaine a eu lieu à 21:49:46, pendant la passe `specialize`.

**B3.** Une fois l'écran de connexion affiché, vérifie : nom du poste, domaine, OU dans l'AD, BitLocker, applications installées, journal de post-installation.

> [!success]- Afficher la correction — B3
> Ouvrir une session `FOURNIL\Administrateur` (ou `PC02\admin`), puis :
> ```powershell
> (Get-CimInstance Win32_ComputerSystem) | Select-Object Name, Domain, PartOfDomain
> Get-BitLockerVolume C: | Select-Object VolumeStatus, ProtectionStatus
> winget list --id Obsidian.Obsidian; winget list --id Microsoft.VisualStudioCode
> Get-Content C:\Windows\Temp\postinstall.log
> ```
> Et sur `SRV01` : `Get-ADComputer PC02 | Select-Object DistinguishedName`.
> Résultat réel du test (fait avec 7-Zip et Notepad++ ; le script installe maintenant Obsidian et VS Code) :
> ```
> PC02 / ad.fournil.lab / True
> FullyDecrypted / Off                       ← PreventDeviceEncryption
> True / True                                ← applications présentes
> 21:52:31  Début post-installation sur PC02 (PC02\admin)
> 21:52:35  WinGet pas encore disponible : enregistrement de App Installer
> 21:52:46  WinGet v1.11.510
> 21:52:53    code retour 0                  ← 7-Zip
> 21:53:08    code retour 0                  ← Notepad++
> CN=PC02,OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab
> ```
> Deux contrôles de sécurité, que `postinstall.ps1` règle à la fin :
> ```powershell
> (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon').AutoAdminLogon   # 0
> Test-Path C:\Windows\Panther\unattend-original.xml                                                 # False
> ```
> Sans ce nettoyage, la session `admin` se rouvrirait seule au redémarrage, et `unattend-original.xml` contiendrait **en clair** le mot de passe du compte qui joint le domaine (constaté sur le lab). BitLocker reste **à activer** avant la remise du poste (chapitre 11 : GPO et clé dans l'AD).

**B4.** Sur un autre poste, la jonction au domaine a échoué mais l'installation est allée au bout. Où chercher la cause ?

> [!success]- Afficher la correction — B4
> Setup **ne s'arrête pas** si la jonction échoue : le poste termine son installation en groupe de travail. Deux journaux sur le poste :
> - **`C:\Windows\debug\NetSetup.LOG`** : la tentative de jonction et son code d'erreur (`0x54b` = domaine introuvable, souvent un problème de DNS ; `0x52e` = identifiants refusés ; une erreur à la création du compte ordinateur = vérifier que l'OU existe) ;
> - **`C:\Windows\Panther\UnattendGC\setupact.log`** : le traitement du composant `UnattendedJoin`.
> Après correction (DNS, OU, mot de passe), on peut joindre le poste à la main avec `Add-Computer`.

---

## Partie C — Domaine et migration (35 min)

**C1.** Depuis `SRV01`, vérifie que `PC02` est bien dans `OU=Ordinateurs,OU=Fournil` et qu'il est enregistré dans le DNS.

> [!success]- Afficher la correction — C1
> Sur `SRV01` :
> ```powershell
> Get-ADComputer PC02 | Select-Object Name, DistinguishedName
> Resolve-DnsName pc02.ad.fournil.lab
> ```
> `DistinguishedName` doit se terminer par `OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab` : le poste y a été créé par `MachineObjectOU`, sans passer par `CN=Computers`. L'enregistrement DNS est créé par le poste lui-même (mise à jour dynamique) avec son adresse DHCP.

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

**E2.** Tu dois déployer 10 postes avec le même support. Comment éviter qu'ils portent tous le nom `PC02` ?

> [!success]- Afficher la correction — E2
> Trois possibilités :
> - `<ComputerName>*</ComputerName>` : Windows génère un nom aléatoire (préfixé par `RegisteredOrganization`, par exemple `FOURNIL-AN4OLJL`), qu'on renomme ensuite (`Rename-Computer`). Un nom du type `PC-*` est **invalide** et fait échouer la passe `specialize` ;
> - un fichier de réponse **par poste** (seul `ComputerName` change), sur des clés USB étiquetées ;
> - en entreprise, un outil qui nomme les postes (Autopilot, ConfigMgr) à partir du numéro de série.

---

## Partie F — L'ISO personnalisée avec une image maître *(approfondissement)*

**F1.** Copie le contenu de l'ISO officielle dans `D:\ISO-Deploiement`. Pourquoi `robocopy` plutôt que `Copy-Item` ?

> [!success]- Afficher la correction — F1
> ```powershell
> Mount-DiskImage -ImagePath D:\ISO\Win11_26H2_French_x64.iso      # ex. lettre E:
> robocopy E:\ D:\ISO-Deploiement /E /COPY:DAT /R:1 /W:1
> Dismount-DiskImage -ImagePath D:\ISO\Win11_26H2_French_x64.iso
> ```
> `Copy-Item -Recurse` peut mal copier certains fichiers de démarrage EFI (`boot\EFI_EX`), d'où une ISO qui échoue en toute fin d'installation (`BfspCopyFile`, `0x8007000B`). `robocopy /E /COPY:DAT` duplique fidèlement (débit relevé : ~45 Go/min sur SSD).

**F2.** Remplace `sources\install.wim` par `MASTER.wim`. Quel obstacle rencontres-tu ?

> [!success]- Afficher la correction — F2
> ```powershell
> attrib -r D:\ISO-Deploiement\sources\install.wim
> Copy-Item D:\Images\MASTER.wim D:\ISO-Deploiement\sources\install.wim -Force
> ```
> Obstacle : les fichiers copiés depuis une ISO sont en **lecture seule**. `Copy-Item -Force` passe outre ici, mais un outil comme DISM refusera de monter un `.wim` en lecture seule (TP 15).

**F3.** Construis `MASTER-Deploiement.iso` en BIOS + UEFI, **sans** le message « Press any key ». Quel risque cela crée-t-il ?

> [!success]- Afficher la correction — F3
> ```cmd
> set OSC=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg
> "%OSC%\oscdimg.exe" -m -o -u2 -udfver102 ^
>   -bootdata:2#p0,e,bD:\ISO-Deploiement\boot\etfsboot.com#pEF,e,b"%OSC%\efisys_noprompt.bin" ^
>   D:\ISO-Deploiement D:\ISO\MASTER-Deploiement.iso
> ```
> ISO de **9,2 Go** sur le lab. `efisys_noprompt.bin` supprime « *Press any key to boot from CD or DVD* » : vérifié, `PC02` a démarré sans aucune touche.
> **Risque** : un poste qui démarre dessus par erreur est **effacé sans question** (`WillWipeDisk`). Étiqueter, ne pas laisser traîner.

**F4.** *(Situation vécue sur le lab)* L'installation s'arrête sur « **Échec de l'installation de Windows 11** ». Comment lire les journaux de Setup sur ce poste ?

> [!success]- Afficher la correction — F4
> Sur l'écran d'erreur : **`Shift + F10`** ouvre une invite. Mais le WinPE de Setup n'a ni PowerShell ni `findstr` : on peut lire avec `type`, ou mieux, **éteindre la VM et monter son disque sur l'hôte** :
> ```powershell
> Mount-VHD D:\HyperV\PC02\PC02.vhdx -ReadOnly
> Get-Content 'E:\$WINDOWS.~BT\Sources\Panther\setupact.log' | Select-String ', Error' | Select-Object -Last 30
> ```
> Emplacements : `$WINDOWS.~BT\Sources\Panther\` (phase WinPE / application), `Windows\Panther\` (après le premier redémarrage), `Windows\Panther\UnattendGC\` (traitement du fichier de réponse en specialize/oobe).
> Les erreurs `hwreqchk`, `OneSettings`, `0x80072EE7` (pas de réseau, télémétrie) sont du **bruit** : chercher les lignes `SP` (Setup Platform).

**F5.** Le journal contient `CAddUnattend::DoExecute: Failed to save copy of answer file to …\Panther\unattend-original.xml (0x80070050)`. Explique et corrige.

> [!success]- Afficher la correction — F5
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

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp)
