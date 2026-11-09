# TP 14 — Poste de référence : mode audit et Sysprep — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 2h

> Chapitres associés : [14. Poste de référence : mode audit et Sysprep](https://kayasam.github.io/windows11/windows11/14-sysprep-audit/)

---

## Objectifs

- Installer la VM de référence `MASTER` **sans chiffrement automatique**
- La personnaliser en mode audit (socle logiciel, nettoyage des applications)
- Protéger l'état « prêt à généraliser » par un point de contrôle
- Généraliser avec Sysprep et le fichier de réponse — et **diagnostiquer** les échecs

---

## Prérequis

- `autounattend-installation-master.xml` et `autounattend-fournil-26h2.xml` (TP 13)
- Au moins **40 Go libres** sur le disque de l'hôte

---

## Partie A — Installer MASTER (25 min)

**A1.** Crée l'ISO `unattend-master.iso` contenant `autounattend-installation-master.xml` renommé en `autounattend.xml`.

> [!success]- Afficher la correction — A1
> ```powershell
> New-Item D:\Images\unattend-master -ItemType Directory -Force
> Copy-Item C:\…\autounattend-installation-master.xml D:\Images\unattend-master\autounattend.xml
> & "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" `
>     -n -m D:\Images\unattend-master D:\ISO\unattend-master.iso
> ```
> `-n` autorise les noms longs ; pas besoin de `-bootdata` : cette ISO ne démarre pas, Windows Setup y **cherche** juste `autounattend.xml`.

**A2.** Crée la VM `MASTER` (Gen 2, 6 Go statiques, 2 vCPU, TPM, **Default Switch**) avec deux lecteurs DVD : l'ISO Windows et l'ISO de réponse. Démarre-la.

> [!success]- Afficher la correction — A2
> ```powershell
> New-VM -Name MASTER -Generation 2 -MemoryStartupBytes 6GB -NewVHDPath D:\HyperV\MASTER\MASTER.vhdx `
>     -NewVHDSizeBytes 64GB -SwitchName "Default Switch" -Path D:\HyperV
> Set-VMMemory MASTER -DynamicMemoryEnabled $false
> Set-VMProcessor MASTER -Count 2
> Set-VMKeyProtector -VMName MASTER -NewLocalKeyProtector; Enable-VMTPM -VMName MASTER
> $dvd = Add-VMDvdDrive MASTER -Path D:\ISO\Win11_26H2_French_x64.iso -Passthru
> Add-VMDvdDrive MASTER -Path D:\ISO\unattend-master.iso
> Set-VMFirmware MASTER -FirstBootDevice $dvd
> Start-VM MASTER; vmconnect localhost MASTER
> ```
> Installation sans aucun écran (édition Pro, disque partitionné), puis arrêt sur l'OOBE.

**A3.** Pourquoi le Default Switch ? Pourquoi `MASTER` ne doit-elle jamais rejoindre le domaine ?

> [!success]- Afficher la correction — A3
> - **Default Switch** : Internet immédiat (DHCP + NAT de l'hôte) pour WinGet et Windows Update, sans consommer d'adresse ni voir le DHCP de `SRV01`.
> - **Jamais de domaine** : la jonction écrit dans l'image des informations propres au poste (compte ordinateur, canal sécurisé, GPO appliquées) — Sysprep refuse d'ailleurs un membre du domaine. Les postes déployés rejoindront le domaine **après** déploiement.

---

## Partie B — Mode audit (30 min)

**B1.** À l'écran « Est-ce le bon pays ou la bonne région ? », passe en mode audit. Que se passe-t-il ? Quel compte est utilisé ?

> [!success]- Afficher la correction — B1
> `Ctrl + Maj + F3`. La VM redémarre et ouvre une session **Administrateur** (le compte intégré, RID 500), sans mot de passe, et la fenêtre *Outil de préparation système v.3.14* s'affiche :
>
> ![w11-14-mode-audit-sysprep](https://kayasam.github.io/windows11/assets/captures/w11-14-mode-audit-sysprep.png)
>
> Particularité constatée sur le lab : `net user Administrateur` indique **« Compte : actif Non »** — Windows ouvre quand même la session en mode audit. D'où l'impossibilité d'administrer `MASTER` à distance tant qu'on ne lui donne pas un mot de passe et qu'on ne l'active pas.

**B2.** Vérifie l'état BitLocker de `C:` et la valeur `PreventDeviceEncryption`.

> [!success]- Afficher la correction — B2
> ```powershell
> Get-BitLockerVolume C: | Select-Object VolumeStatus, ProtectionStatus
> Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker | Select-Object PreventDeviceEncryption
> ```
> ```
> VolumeStatus     : FullyDecrypted
> ProtectionStatus : Off
> PreventDeviceEncryption : 1
> ```
> Grâce au composant `SecureStartup-FilterDriver` du fichier d'installation. Sans lui : `FullyEncrypted` et Sysprep échouera (D5).

**B3.** Installe 7-Zip et Notepad++ **pour tous les utilisateurs** avec WinGet.

> [!success]- Afficher la correction — B3
> ```powershell
> winget install --id 7zip.7zip -e --silent --scope machine --accept-package-agreements --accept-source-agreements
> winget install --id Notepad++.Notepad++ -e --silent --scope machine --accept-package-agreements
> ```
> ```
> Found 7-Zip [7zip.7zip] Version 26.06 … Successfully installed
> Found Notepad++ [Notepad++.Notepad++] Version 8.9.9 … Successfully installed
> ```
> (`--scope machine` : dans `Program Files`, pour tous les utilisateurs. Ces deux commandes vont pourtant chacune laisser un paquet « utilisateur » qui bloquera Sysprep — voir D2/D3.)

**B4.** Retire de l'image `Microsoft.BingNews`, `Clipchamp.Clipchamp`, `Microsoft.MicrosoftSolitaireCollection` et `Microsoft.GamingApp`, pour les futurs utilisateurs **et** l'Administrateur.

> [!success]- Afficher la correction — B4
> ```powershell
> foreach ($app in 'Microsoft.BingNews','Clipchamp.Clipchamp','Microsoft.MicrosoftSolitaireCollection','Microsoft.GamingApp') {
>     Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $app | Remove-AppxProvisionedPackage -Online
>     Get-AppxPackage -AllUsers $app | Remove-AppxPackage -AllUsers
> }
> ```
> Les deux commandes sont nécessaires : la première retire le modèle (futurs profils), la seconde la copie installée pour l'Administrateur (sinon Sysprep peut la signaler).

**B5.** Crée `C:\Fournil\version-image.txt` contenant la version de l'image et la date. À quoi cela servira-t-il ?

> [!success]- Afficher la correction — B5
> ```powershell
> New-Item C:\Fournil -ItemType Directory -Force
> "Image Fournil v2026.11 - $(Get-Date -Format s)" | Set-Content C:\Fournil\version-image.txt
> ```
> Sur n'importe quel poste déployé, un coup d'œil à ce fichier (ou un inventaire, chapitre 07) dit **de quelle image il est issu** : précieux en dépannage (« ce bug ne touche que les postes en v2026.11 »).

---

## Partie C — Préparer la généralisation (15 min)

**C1.** Depuis l'hôte, copie `autounattend-fournil-26h2.xml` dans `C:\Sysprep\autounattend.xml` de `MASTER` **sans réseau ni partage**.

> [!success]- Afficher la correction — C1
> ```powershell
> Get-VMIntegrationService -VMName MASTER | Where-Object Id -match "6C09BB55-D683-4DA0-8931-C9BF705F6480" | Enable-VMIntegrationService
> Copy-VMFile -Name MASTER -SourcePath C:\…\autounattend-fournil-26h2.xml `
>     -DestinationPath C:\Sysprep\autounattend.xml -CreateFullPath -FileSource Host
> ```
> Le service s'appelle *Interface de services d'invité* sur un hôte français — d'où le filtre sur son **GUID**, identique dans toutes les langues.

**C2.** Crée le point de contrôle `Avant-Sysprep`. Pourquoi à ce moment précis ?

> [!success]- Afficher la correction — C2
> ```powershell
> Checkpoint-VM -Name MASTER -SnapshotName "Avant-Sysprep"
> ```
> C'est le dernier état **personnalisé mais pas généralisé**. Le mois suivant, on y revient en quelques secondes pour mettre l'image à jour, au lieu de tout réinstaller.

---

## Partie D — Sysprep et dépannage (40 min)

**D1.** Lance Sysprep en ligne de commande (généralisation, OOBE, arrêt, fichier de réponse). La VM ne s'éteint pas. Où regarder ?

> [!success]- Afficher la correction — D1
> Fermer d'abord la fenêtre Sysprep du mode audit (une seule instance possible), puis :
> ```cmd
> C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Sysprep\autounattend.xml
> ```
> Si la VM ne s'éteint pas (ou si une fenêtre « Sysprep n'a pas pu valider votre installation de Windows » apparaît) :
> ```
> C:\Windows\System32\Sysprep\Panther\setuperr.log
> C:\Windows\System32\Sysprep\Panther\setupact.log
> ```

**D2.** Le journal indique :
```
SYSPRP Package Microsoft.Winget.Source_2026.1108.637.6_neutral__8wekyb3d8bbwe was installed for a user,
but not provisioned for all users.
```
Explique et corrige.

> [!success]- Afficher la correction — D2
> ```
> SYSPRP WinMain:Hit failure while pre-validate sysprep generalize internal providers; hr = 0x80073cf2
> ```
> À sa première utilisation, WinGet télécharge son **index de paquets** sous forme d'application MSIX (`Microsoft.Winget.Source`), installée **pour l'utilisateur courant** (l'Administrateur), pas provisionnée. Sysprep refuse de généraliser une image contenant une application « installée pour un utilisateur mais pas pour tous ».
> ```powershell
> Get-AppxPackage Microsoft.Winget.Source | Remove-AppxPackage
> ```
> Rien de cassé : WinGet la retéléchargera au premier usage sur les postes déployés.

**D3.** Nouvel échec, même code, avec `NotepadPlusPlus_1.0.0.0_neutral__2247w0b46hfww`. Pourquoi ce paquet existe-t-il ? Corrige.

> [!success]- Afficher la correction — D3
> L'installeur de Notepad++ enregistre un paquet MSIX **« sparse »** (identité d'application sans contenu) pour ajouter « Modifier avec Notepad++ » au **nouveau menu contextuel** de Windows 11 — enregistré pour l'utilisateur qui installe, même avec `--scope machine`.
> ```powershell
> Select-String C:\Windows\System32\Sysprep\Panther\setupact.log -Pattern "not provisioned"
> Get-AppxPackage NotepadPlusPlus | Remove-AppxPackage
> ```
> Méthode générale : **lire le nom exact** dans `setupact.log`, retirer, relancer. Sysprep s'arrête au premier paquet trouvé : sur le lab, il a fallu trois essais (BitLocker, WinGet, Notepad++) avant que `MASTER` s'éteigne en 90 secondes.

**D4.** Que dois-tu faire au point de contrôle après ces corrections ?

> [!success]- Afficher la correction — D4
> Le **refaire**, sinon chaque rafraîchissement mensuel retombera sur les mêmes paquets :
> ```powershell
> Get-VMCheckpoint -VMName MASTER | Remove-VMCheckpoint
> Checkpoint-VM -Name MASTER -SnapshotName "Avant-Sysprep"
> ```
> (Et noter dans la procédure : « retirer `Microsoft.Winget.Source` et `NotepadPlusPlus` juste avant Sysprep ».)

**D5.** Un collègue, qui avait installé `MASTER` **sans** le fichier anti-chiffrement, obtient `0x80310039`. Que lui conseilles-tu ?

> [!success]- Afficher la correction — D5
> ```
> SYSPRP BitLocker-Sysprep: BitLocker is on for the OS volume. Turn BitLocker off to run Sysprep. (0x80310039)
> ```
> Le chiffrement automatique a chiffré `MASTER`. En théorie, `manage-bde -off C:` puis attendre le déchiffrement. **En pratique, sur le lab, en mode audit** : `manage-bde -off C:` et `Disable-BitLocker` échouent avec `0x8007007A` (« La zone de données passée à un appel système est insuffisante »), même après ajout d'un protecteur. Conseil : **réinstaller `MASTER`** avec le fichier anti-chiffrement (A1/A2) — c'est ce qui a été fait.

**D6.** Sysprep réussit : la VM s'éteint. Pourquoi ne faut-il surtout pas la redémarrer ?

> [!success]- Afficher la correction — D6
> Au prochain démarrage, la machine généralisée jouerait **specialize** puis **oobeSystem** pour elle-même : nouveau SID, nom `PC-xxxx`, compte `Utilisateur`… L'image serait « consommée ». On capture le disque **éteint** (TP 15). Pour une nouvelle version, on revient au point de contrôle.

---

## Partie E — Bonus

**E1.** Le mois prochain, décris la procédure complète pour produire `MASTER` v2026.12.

> [!success]- Afficher la correction — E1
> 1. `Restore-VMSnapshot -VMName MASTER -Name Avant-Sysprep -Confirm:$false` ; `Start-VM MASTER` (retour en mode audit) ;
> 2. Windows Update (jusqu'à « à jour »), `winget upgrade --all --scope machine`, mises à jour du Store ;
> 3. `Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase` (image plus légère) ;
> 4. mettre à jour `C:\Fournil\version-image.txt` → v2026.12 ;
> 5. retirer les paquets utilisateur (`Microsoft.Winget.Source`, `NotepadPlusPlus`, tout ce que signale `setupact.log`) ;
> 6. nouveau point de contrôle `Avant-Sysprep` ;
> 7. Sysprep → capture (TP 15) → nouvelle ISO (TP 16).

**E2.** Quelle limite Sysprep impose-t-il au nombre de généralisations, et en quoi le point de contrôle la contourne-t-il ?

> [!success]- Afficher la correction — E2
> Une même installation de Windows ne peut être généralisée qu'un nombre limité de fois (compteur interne, historiquement 3 sans `SkipRearm`, 1 001 aujourd'hui). En revenant toujours au point de contrôle **d'avant** Sysprep, on repart d'un compteur inchangé : on ne « regénéralise » jamais une image déjà généralisée.

---

[Retour à l'énoncé](https://kayasam.github.io/windows11/windows11/14-sysprep-audit/tp)
