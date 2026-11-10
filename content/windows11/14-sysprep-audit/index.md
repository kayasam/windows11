---
title: "14. Poste de référence : mode audit et Sysprep"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/14-sysprep-audit"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/14-sysprep-audit.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Créer la VM de référence `MASTER`, la personnaliser en **mode audit**, puis la généraliser avec Sysprep en appliquant le fichier de réponse construit au chapitre 13. `MASTER` est pensée pour être **réutilisée** dans le temps (mises à jour périodiques de l'image) grâce à un simple point de contrôle Hyper-V. Savoir **diagnostiquer un échec de Sysprep** — trois pièges modernes ont été rencontrés en construisant le lab.
>
> **Outils :** `sysprep.exe`, `Copy-VMFile`, `Checkpoint-VM`
> **Fichiers à connaître :** `C:\Windows\System32\Sysprep\Panther\setupact.log` / `setuperr.log`, `autounattend-installation-master.xml`, `autounattend-fournil-26h2.xml`

> [!abstract] Niveau : approfondissement
> L'image maître est la méthode des **grands parcs**. Le déploiement du chapitre 16 (ISO officielle + `autounattend.xml`) **n'en dépend pas**. Pour un public TSSR, ce chapitre peut être présenté en démonstration (principe de Sysprep, pourquoi généraliser, mode audit) sans faire réaliser toute la chaîne.

> [!INFO] Fil rouge — Fournil
> `MASTER` : Windows 11 Pro 26H2, 7-Zip + Notepad++, applications grand public retirées, fichier `C:\Fournil\version-image.txt`. Généralisée avec succès le 08/11/2026 après avoir résolu les trois pièges ci-dessous.

---

## Créer la VM de référence MASTER

Depuis l'hôte (PowerShell administrateur) :

```powershell
New-VM -Name "MASTER" -Generation 2 -MemoryStartupBytes 6GB -NewVHDPath "D:\HyperV\MASTER\MASTER.vhdx" -NewVHDSizeBytes 64GB -SwitchName "Default Switch" -Path "D:\HyperV"
Set-VMProcessor -VMName "MASTER" -Count 2
Set-VMMemory -VMName "MASTER" -DynamicMemoryEnabled $false
Set-VMKeyProtector -VMName "MASTER" -NewLocalKeyProtector
Enable-VMTPM -VMName "MASTER"
$dvd = Add-VMDvdDrive -VMName "MASTER" -Path "D:\ISO\Win11_26H2_French_x64.iso" -Passthru
Add-VMDvdDrive -VMName "MASTER" -Path "D:\ISO\unattend-master.iso"      # le petit fichier de réponse (ci-dessous)
Set-VMFirmware -VMName "MASTER" -FirstBootDevice $dvd
```

> [!DANGER] Installer MASTER **avec** `PreventDeviceEncryption`
> Sans précaution, Windows 11 26H2 chiffre automatiquement le disque de `MASTER` (BitLocker) dès l'installation, et **Sysprep refuse ensuite de généraliser** (`0x80310039`) — sans retour en arrière possible en mode audit (voir *Dépanner Sysprep* plus bas). On installe donc `MASTER` avec `Ressources/Fichier-reponse/autounattend-installation-master.xml` (chapitre 13), placé à la racine d'une petite ISO :
> ```powershell
> New-Item D:\Images\unattend-master -ItemType Directory -Force
> Copy-Item ...\autounattend-installation-master.xml D:\Images\unattend-master\autounattend.xml
> & "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" -n -m D:\Images\unattend-master D:\ISO\unattend-master.iso
> ```
> Ce fichier partitionne le disque, choisit l'édition Pro, active `PreventDeviceEncryption` et **s'arrête à l'OOBE** (pas de passe oobeSystem).

> [!WARNING] Désactiver la mémoire dynamique pour l'installation
> La mémoire dynamique (activée par défaut sur certains hôtes) peut faire échouer l'application de l'image Windows pendant Setup — celui-ci peut demander de la RAM plus vite que Hyper-V n'arrive à la lui allouer, provoquant une erreur `0x800705AA` ("ressources système insuffisantes") en pleine installation, souvent tard dans le processus et sans cause évidente dans les logs. Une mémoire **statique** d'au moins 6 Go pour l'installation évite ce problème (on peut la redescendre après, une fois Windows installé).

Installer Windows 11 normalement (voir chapitre 2 pour le détail de l'installation depuis l'ISO) — **jusqu'à l'écran OOBE**, sans aller plus loin.

> [!NOTE] Pourquoi le "Default Switch" plutôt que vSwitch-Rennes ?
> `MASTER` ne rejoint jamais le domaine et n'a besoin de parler à aucune autre machine du lab — en revanche, le mode audit (ci-dessous) nécessite Internet pour Windows Update et `winget`. Le **Default Switch** créé automatiquement par Hyper-V fournit DHCP + NAT vers Internet sans configuration, indépendamment du réseau `vSwitch-Rennes`/`192.168.3.0/24` du lab. Plus simple, et ça évite de consommer une adresse dans la plage DHCP de `SRV01`.

---

## Mode Audit

**À l'écran OOBE "Région ?"**, appuyer sur **`Ctrl + Shift + F3`**. Windows redémarre automatiquement et rouvre une session sous le compte **Administrateur intégré**, sans jamais terminer l'OOBE ni créer de profil utilisateur final.

![w11-14-mode-audit-sysprep](https://cours.kaya.ovh/windows11/assets/captures/w11-14-mode-audit-sysprep.png)

*`MASTER` en mode audit (26H2) : la fenêtre « Outil de préparation système v.3.14 » s'ouvre à chaque connexion.*

Une fenêtre **"Outil de préparation du système (Sysprep)"** s'affiche à chaque connexion tant que la machine reste en mode audit — on peut la fermer sans rien valider, elle réapparaîtra plus tard. **Elle doit être fermée** avant de lancer Sysprep en ligne de commande (une seule instance à la fois).

> [!NOTE] Le compte Administrateur en mode audit
> Constaté sur le lab : la session tourne sous `Administrateur`, **sans mot de passe** et marqué **inactif** (`net user Administrateur` → *Compte : actif Non*) — Windows l'ouvre quand même, c'est le principe du mode audit. Conséquence : impossible d'administrer `MASTER` à distance (PowerShell Direct, `Enter-PSSession`) tant qu'on ne lui a pas donné un mot de passe **et** qu'on ne l'a pas activé (`net user Administrateur <mdp> /active:yes`). Penser à le **désactiver à nouveau** avant Sysprep pour ne pas livrer un compte actif au mot de passe connu dans l'image.

C'est dans cet état qu'on personnalise `MASTER` : mises à jour Windows, applications standard, nettoyage.

| Action | Commande / emplacement |
|--------|------------------------|
| Rechercher les mises à jour Windows | `Paramètres > Windows Update` |
| Mettre à jour les apps Microsoft Store | Microsoft Store → `...` → Téléchargements et mises à jour |
| Installer un logiciel standard | `winget install --id 7zip.7zip -e --scope machine --silent` (ou `winget import` du socle, chapitre 05) |
| Mettre à jour tous les logiciels installés | `winget upgrade --all` |
| Retirer les applications grand public **de l'image** | `Get-AppxProvisionedPackage -Online \| Where DisplayName -eq Microsoft.BingNews \| Remove-AppxProvisionedPackage -Online` (+ `Remove-AppxPackage -AllUsers`) |
| Désinstaller une application inutile | `Paramètres > Applications > Applications installées` |
| Nettoyer les fichiers temporaires | `cleanmgr.exe` |
| **Juste avant Sysprep** : retirer les paquets « utilisateur » | `Get-AppxPackage Microsoft.Winget.Source, NotepadPlusPlus \| Remove-AppxPackage` (voir *Dépanner Sysprep*) |

> [!NOTE] En conditions réelles
> C'est ici que serait installée la suite logicielle standard de l'entreprise, les pilotes additionnels, les réglages par défaut — sans jamais avoir eu à créer de compte utilisateur ni à terminer l'OOBE.

---

## Transférer le fichier de réponse vers MASTER

Le fichier `autounattend.xml` construit au chapitre 13 existe sur l'hôte — il faut le faire parvenir dans `MASTER`. `Copy-VMFile` copie un fichier depuis l'hôte directement vers une VM en cours d'exécution, sans passer par le réseau ni par un disque de transfert :

```powershell
Get-VMIntegrationService -VMName "MASTER" | Where-Object { $_.Id -match "6C09BB55-D683-4DA0-8931-C9BF705F6480" } | Enable-VMIntegrationService
Copy-VMFile -Name "MASTER" -SourcePath "D:\Images\autounattend.xml" -DestinationPath "C:\Sysprep\autounattend.xml" -CreateFullPath -FileSource Host
```

> [!WARNING] Le nom du service est localisé, pas son identifiant
> `Enable-VMIntegrationService -Name "Guest Service Interface"` échoue sur un hôte en français avec *"Aucun composant d'intégration ne porte le nom spécifié"* : le nom affiché est traduit (`Interface de services d'invité` en français) et dépend de la langue de l'hôte. L'`Id` du composant, lui, est un GUID **fixe**, identique quelle que soit la langue — filtrer dessus (`6C09BB55-D683-4DA0-8931-C9BF705F6480`, l'identifiant du Guest Service Interface) évite ce problème. Pour vérifier le nom localisé sur ta machine : `Get-VMIntegrationService -VMName "MASTER" | Select-Object Name, Enabled, Id`.

> [!TIP] Pourquoi pas un partage réseau ou un disque virtuel de transfert ?
> `Copy-VMFile` s'appuie sur le canal d'intégration Hyper-V (VMBus) entre l'hôte et la VM — il fonctionne même sans réseau configuré côté VM, et évite de créer/monter/démonter un VHD juste pour faire transiter un fichier de quelques kilo-octets. Ce service d'intégration est désactivé par défaut (contrairement à l'heartbeat ou la synchronisation d'horloge) ; il faut l'activer explicitement une fois par VM.

---

## Un point de contrôle avant de généraliser

Avant de lancer Sysprep, on protège l'état actuel de `MASTER` (personnalisée, en mode audit, pas encore généralisée) avec un point de contrôle :

```powershell
Checkpoint-VM -Name "MASTER" -SnapshotName "Avant-Sysprep"
```

> [!TIP] Pourquoi un checkpoint et pas une sauvegarde complète ?
> `Export-VM` copie l'intégralité des fichiers de la VM — lourd et lent, pensé pour déplacer une VM d'un hôte à un autre. `Checkpoint-VM` ne stocke que les différences depuis ce point dans le temps : création quasi instantanée, et `Restore-VMSnapshot` permet de revenir exactement à cet état (personnalisation faite, pas encore généralisée) en quelques secondes le jour où l'on veut rafraîchir l'image.

---

## Sysprep : généraliser MASTER

Terminal administrateur sur `MASTER` :

```cmd
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Sysprep\autounattend.xml
```

| Option | Effet |
|--------|-------|
| `/generalize` | Supprime les informations propres à la machine (SID, pilotes spécifiques, identité) |
| `/oobe` | Prochain démarrage → écran d'accueil OOBE (au lieu du bureau) |
| `/shutdown` | Éteint la VM une fois l'opération terminée |
| `/unattend:` | Applique le fichier de réponse (passes `specialize` et `oobeSystem`, chapitre 13) au prochain démarrage |

Équivalent graphique : dans la fenêtre "Outil de préparation du système", sélectionner "Passer en mode OOBE", cocher **Généraliser**, choisir **Arrêter**, puis **OK** — le fichier de réponse n'est en revanche appliqué que via la ligne de commande `/unattend:`.

Sysprep affiche une progression puis éteint la VM automatiquement. Compter généralement 2 à 5 minutes.

> [!WARNING] Ne pas redémarrer MASTER après Sysprep
> Un redémarrage normal déclencherait l'OOBE et rendrait la généralisation inutile. Le chapitre 15 capture l'image directement depuis le fichier VHDX de la VM éteinte.

---

## Dépanner Sysprep : les trois pièges rencontrés sur le lab

**Symptôme commun** : Sysprep affiche « *Sysprep n'a pas pu valider votre installation de Windows* » (ou, lancé en ligne de commande, ne fait rien et la VM ne s'éteint pas). Le diagnostic est **toujours** dans :

```
C:\Windows\System32\Sysprep\Panther\setuperr.log    ← les erreurs
C:\Windows\System32\Sysprep\Panther\setupact.log    ← le détail (chercher le nom du coupable)
```

### 1. BitLocker — `0x80310039`

```
SYSPRP BitLocker-Sysprep: BitLocker is on for the OS volume. Turn BitLocker off to run Sysprep. (0x80310039)
```

**Cause** : le chiffrement automatique de l'appareil (24H2+) a chiffré `MASTER`.
**Piège dans le piège** : en mode audit, `manage-bde -off C:` et `Disable-BitLocker` échouent avec `0x8007007A` (« La zone de données passée à un appel système est insuffisante »), même après ajout d'un protecteur. Il a fallu **réinstaller `MASTER`**.
**Prévention** : installer `MASTER` avec `PreventDeviceEncryption` (composant `Microsoft-Windows-SecureStartup-FilterDriver`, chapitre 13). Vérification en mode audit : `Get-BitLockerVolume C:` → `FullyDecrypted`.
**Revers** : la valeur `PreventDeviceEncryption = 1` est **capturée dans l'image** : constaté sur `PC02` déployé depuis `MASTER.wim` (`FullyDecrypted / Off`, valeur toujours à 1). Les postes déployés ne s'auto-chiffrent donc jamais. Deux options : retirer la valeur en **toute dernière commande** avant `sysprep /generalize /shutdown` (non testé dans le lab : le chiffrement pourrait démarrer s'il s'écoule du temps ou un redémarrage entre les deux), ou — mieux en entreprise — activer BitLocker par GPO/Intune avec sauvegarde de la clé dans AD (chapitres 09 et 11).
```powershell
Remove-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker -Name PreventDeviceEncryption
```

### 2. Paquet d'application non provisionné — `0x80073cf2`

```
SYSPRP Package Microsoft.Winget.Source_2026.1108.637.6_neutral__8wekyb3d8bbwe was installed for a user,
but not provisioned for all users. This package will not function properly in the sysprep image.
SYSPRP WinMain:Hit failure while pre-validate sysprep generalize internal providers; hr = 0x80073cf2
```

**Cause** : une application MSIX installée **pour le seul compte Administrateur** pendant le mode audit. Les deux coupables trouvés sur le lab :

| Paquet | Pourquoi il est là |
|--------|--------------------|
| `Microsoft.Winget.Source` | L'index des paquets que **WinGet** télécharge pour l'utilisateur à sa première utilisation |
| `NotepadPlusPlus_1.0.0.0` | Le paquet « sparse » que l'installeur de **Notepad++** enregistre pour son entrée dans le menu contextuel de Windows 11 — même avec `--scope machine` |

Les mises à jour automatiques du Store pendant le mode audit (avec Internet) produisent le même symptôme avec d'autres applications.

**Correction** (lire le nom exact dans `setupact.log`, retirer, relancer) :

```powershell
Select-String C:\Windows\System32\Sysprep\Panther\setupact.log -Pattern "not provisioned"
Get-AppxPackage Microsoft.Winget.Source | Remove-AppxPackage
Get-AppxPackage NotepadPlusPlus        | Remove-AppxPackage
```

Sysprep peut échouer **plusieurs fois de suite** sur des paquets différents : il s'arrête au premier trouvé. Sur le lab : trois tentatives (BitLocker, puis WinGet, puis Notepad++) avant la réussite — `MASTER` éteinte en 90 secondes.

### 3. Reprendre le point de contrôle

Après chaque correction, **refaire** le point de contrôle `Avant-Sysprep` : sinon, au prochain rafraîchissement de l'image, on retombe sur le même échec.

```powershell
Get-VMCheckpoint -VMName MASTER | Remove-VMCheckpoint
Checkpoint-VM -Name MASTER -SnapshotName "Avant-Sysprep"
```

### 4. Le piège qui n'apparaît qu'au déploiement : `unattend-original.xml` *(approfondissement)*

Sysprep réussit, la capture aussi… et c'est le **déploiement** qui échoue (« *Échec de l'installation de Windows 11* », chapitre 16). Cause trouvée dans `$WINDOWS.~BT\Sources\Panther\setupact.log` du poste cible :

```
CAddUnattend::DoExecute: Failed to save copy of answer file to
  E:\$WINDOWS.~BT\NewOS\WINDOWS\Panther\unattend-original.xml (0x80070050)
ExecuteOperations: Operations cannot be sorted. This is a fatal failure.
```

`MASTER` ayant été installée **avec** un fichier de réponse, Setup en a gardé une copie dans `C:\Windows\Panther\unattend-original.xml` ; Sysprep `/unattend:` y a ajouté `unattend.xml`. Ces fichiers sont **capturés avec l'image**, et le nouveau moteur de Setup (médias 24H2+) refuse d'écraser `unattend-original.xml` : erreur `0x80070050` (*le fichier existe*).

**Correction** (validée sur le lab) — avant la capture, ou hors ligne dans le WIM :

```powershell
# Juste avant Sysprep, sur MASTER
Remove-Item C:\Windows\Panther\unattend-original.xml -ErrorAction SilentlyContinue
# … ou après capture, dans l'image montée (chapitre 15)
Dism /Mount-Image /ImageFile:D:\Images\MASTER.wim /Index:1 /MountDir:C:\Mount
del C:\Mount\Windows\Panther\unattend-original.xml C:\Mount\Windows\Panther\unattend.xml
Dism /Unmount-Image /MountDir:C:\Mount /Commit
```

### 5. Encore au déploiement : un `Windows.old` vide dans l'image — `0x800700B7` *(approfondissement)*

Une fois le n° 4 corrigé, le déploiement suivant est allé plus loin… puis a échoué en phase *Finalize* :

```
CRelocateOS: Cannot move path E:\$WINDOWS.~BT\NewOS\Windows.old from Windows.NEW. Error: 0x000000B7
Operation failed: Relocate OS from E:\$WINDOWS.~BT\NewOS to E:\. Error: 0x800700B7
```

Le nouveau Setup avait laissé sur `MASTER` deux dossiers **vides** à la racine, `C:\Windows.old` et `C:\Recovery`, capturés dans le WIM. Lors du déploiement, Setup applique l'image dans un dossier intermédiaire (`NewOS`) puis la déplace : il trouve un `Windows.old` qu'il veut créer lui-même et abandonne (*existe déjà*).

**Correction** (validée sur le lab) : vérifier la **racine** de l'image avant de la distribuer, et y supprimer ces dossiers.

```cmd
Dism /Mount-Image /ImageFile:D:\Images\MASTER.wim /Index:1 /MountDir:C:\Mount
dir /a C:\Mount
rd C:\Mount\Windows.old
rd C:\Mount\Recovery
Dism /Unmount-Image /MountDir:C:\Mount /Commit
```

Ou, en amont, sur `MASTER` avant Sysprep : `rd C:\Windows.old` et `rd C:\Recovery` s'ils sont vides.

> [!TIP] Le fichier de réponse contient des mots de passe
> Raison de plus pour nettoyer `Windows\Panther` : sans cela, chaque poste déployé embarque le fichier de réponse de `MASTER`… avec son mot de passe.

### Autres erreurs classiques

| Message / code | Cause | Solution |
|----------------|-------|----------|
| « Sysprep est déjà en cours » / rien ne se passe | La fenêtre Sysprep du mode audit est ouverte | La fermer (`Stop-Process -Name sysprep`) |
| *Fatal error … reached the maximum number of generalizations* | Plus de 1 001 généralisations sur la même installation | Repartir d'une image propre — d'où le point de contrôle **avant** Sysprep |
| Machine jointe au domaine | On ne généralise pas un membre du domaine | `MASTER` reste en groupe de travail |
| Poste mis à niveau depuis une version antérieure | Sysprep refuse une installation issue d'une mise à niveau | Toujours partir d'une installation propre |

---

## Rafraîchir l'image plus tard *(approfondissement)*

Le mois suivant, pour produire une nouvelle version de l'image avec les derniers correctifs :

```powershell
Restore-VMSnapshot -VMName "MASTER" -Name "Avant-Sysprep" -Confirm:$false
Start-VM -Name "MASTER"
```

`MASTER` redémarre exactement dans l'état du checkpoint : personnalisée, en mode audit, pas encore généralisée. Il suffit alors de refaire les mises à jour (`winget upgrade --all`, Windows Update), **retirer à nouveau les paquets utilisateur** (`Microsoft.Winget.Source` revient dès qu'on utilise WinGet), reprendre un nouveau checkpoint, puis relancer Sysprep — sans jamais reconstruire la VM depuis zéro.

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> **VM MASTER**
> - `New-VM` (Gen2, TPM, Default Switch pour Internet) → ISO Windows + ISO "unattend-master"
>   - (PreventDeviceEncryption, sinon BitLocker bloque Sysprep) → installation jusqu'à l'OOBE
> - Ctrl+Shift+F3 → mode audit (Administrateur intégré, sans mot de passe, "inactif")
>   - → mises à jour, logiciels (WinGet), retrait des apps provisionnées
> - `Copy-VMFile` (Guest Service Interface) → `autounattend.xml` (chapitre 13) dans `C:\Sysprep`
>
> - **Avant Sysprep** : retirer les paquets "utilisateur" (Microsoft.Winget.Source, NotepadPlusPlus…)
> - `Checkpoint-VM "Avant-Sysprep"`
>   - → `sysprep /generalize /oobe /shutdown /unattend:...`
>   - → capture (chapitre 15)
>
> **Échec ? `setuperr.log` / `setupact.log` (Panther)**
> - 0x80310039 BitLocker · 0x80073cf2 paquet "not provisioned" → `Remove-AppxPackage` → re-checkpoint
>
> **Rafraîchir plus tard**
> - `Restore-VMSnapshot "Avant-Sysprep"` → mode audit → nouveau checkpoint → re-sysprep → nouvelle capture
