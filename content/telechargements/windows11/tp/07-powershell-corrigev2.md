# TP 07. PowerShell pour l'administrateur — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h30

> Chapitres associés : [07. PowerShell pour l'administrateur](https://cours.kaya.ovh/windows11/windows11/07-powershell/)

---

## Objectifs

- Trouver une commande et son aide sans Internet
- Exploiter le pipeline : filtrer, trier, sélectionner, mesurer
- Interroger le poste avec CIM (sans WMIC)
- Écrire un script paramétré qui produit un inventaire CSV
- Installer PowerShell 7 correctement et comprendre la politique d'exécution

---

## Prérequis

- `PC01`, session `admin`, Windows Terminal

---

## Partie A — Se repérer (15 min)

**A1.** Quelle version de PowerShell s'ouvre par défaut ? Comment le vérifier ?

> [!success]- Afficher la correction — A1
> ```powershell
> $PSVersionTable.PSVersion
> ```
> Sur `PC01` : **5.1.26100.9444** — Windows PowerShell 5.1, intégré à Windows. PowerShell 7 n'est pas installé par défaut.

**A2.** Liste toutes les cmdlets dont le nom (partie « Nom ») est `Service`.

> [!success]- Afficher la correction — A2
> ```powershell
> Get-Command -Noun Service
> ```
> `Get-Service, New-Service, Restart-Service, Resume-Service, Set-Service, Start-Service, Stop-Service, Suspend-Service` (pas de `Remove-Service` en 5.1 : il existe en 7).

**A3.** Affiche uniquement les **exemples** de l'aide de `Stop-Service`. Que faire si l'aide est minimale ?

> [!success]- Afficher la correction — A3
> ```powershell
> Get-Help Stop-Service -Examples
> ```
> Si l'aide se limite à la syntaxe, c'est qu'elle n'a jamais été téléchargée : `Update-Help -UICulture en-US -Force` (terminal administrateur ; l'aide française est incomplète). Sans Internet : `Get-Help Stop-Service -Online` ouvre la page Microsoft Learn sur un autre poste.

**A4.** Quelles propriétés possède un objet renvoyé par `Get-Service` ? Lesquelles indiquent l'état et le type de démarrage ?

> [!success]- Afficher la correction — A4
> ```powershell
> Get-Service | Get-Member -MemberType Property
> ```
> `Status` (Running/Stopped), `StartType` (Automatic/Manual/Disabled), mais aussi `Name`, `DisplayName`, `DependentServices`, `ServicesDependedOn`, `CanStop`…

---

## Partie B — Pipeline (20 min)

**B1.** Combien de processus tournent sur le poste ?

> [!success]- Afficher la correction — B1
> ```powershell
> (Get-Process | Measure-Object).Count       # 161 sur PC01
> ```

**B2.** Affiche les 5 processus les plus gourmands en mémoire, avec une colonne « Mo » arrondie.

> [!success]- Afficher la correction — B2
> ```powershell
> Get-Process | Sort-Object WS -Descending |
>     Select-Object -First 5 Name, @{N='Mo';E={[math]::Round($_.WS/1MB)}}
> ```
> ```
> Name                     Mo
> ----                     --
> MsMpEng                 319
> explorer                190
> StartMenuExperienceHost 165
> SearchHost              119
> msedgewebview2          115
> ```
> `MsMpEng` = le moteur de Microsoft Defender Antivirus, souvent en tête.

**B3.** Liste les services en démarrage automatique mais arrêtés, en n'affichant que leur nom.

> [!success]- Afficher la correction — B3
> ```powershell
> Get-Service | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" } |
>     Select-Object -ExpandProperty Name
> ```
> Sur `PC01` : `edgeupdate`, `MapsBroker`, `sppsvc` — des services qui démarrent puis s'arrêtent normalement.

**B4.** Exporte la liste des services (nom, nom affiché, état, type de démarrage) dans `C:\Temp\services.csv`, séparateur `;`, ouvrable dans Excel.

> [!success]- Afficher la correction — B4
> ```powershell
> Get-Service | Select-Object Name, DisplayName, Status, StartType |
>     Export-Csv C:\Temp\services.csv -NoTypeInformation -Delimiter ';' -Encoding UTF8
> ```
> `-Delimiter ';'` : Excel en français attend le point-virgule. `-NoTypeInformation` évite la ligne `#TYPE` en tête (inutile en PowerShell 7, où c'est le défaut).

---

## Partie C — CIM / WMI (20 min)

**C1.** Le support te demande le **numéro de série** du poste. WMIC a disparu : quelle commande ?

> [!success]- Afficher la correction — C1
> ```powershell
> Get-CimInstance Win32_BIOS | Select-Object SerialNumber, SMBIOSBIOSVersion, Manufacturer
> ```
> ```
> SerialNumber      : 5864-9086-3401-7908-0030-5261-69
> SMBIOSBIOSVersion : Hyper-V UEFI Release v4.1
> Manufacturer      : Microsoft Corporation
> ```
> (Une VM Hyper-V a un numéro de série généré ; sur un PC Dell/HP/Lenovo, c'est le *Service Tag*.)

**C2.** Affiche le modèle de la machine, la RAM en Go, la version de Windows et la date du dernier démarrage.

> [!success]- Afficher la correction — C2
> ```powershell
> Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model, @{N="RAM_Go";E={[math]::Round($_.TotalPhysicalMemory/1GB)}}
> Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, LastBootUpTime
> ```
> ```
> Manufacturer : Microsoft Corporation
> Model        : Virtual Machine
> RAM_Go       : 6
> Caption        : Microsoft Windows 11 Professionnel
> Version        : 10.0.26300
> LastBootUpTime : 08/11/2026 05:51:25
> ```

**C3.** Trouve, sans Internet, le nom de la classe CIM qui décrit les cartes réseau.

> [!success]- Afficher la correction — C3
> ```powershell
> Get-CimClass -ClassName *NetworkAdapter*
> ```
> `Win32_NetworkAdapter` (cartes) et `Win32_NetworkAdapterConfiguration` (IP, DNS, DHCP). En pratique, les cmdlets `Get-NetAdapter` / `Get-NetIPConfiguration` sont plus confortables… et reposent elles-mêmes sur CIM (`MSFT_NetAdapter`).

---

## Partie D — Un script d'inventaire (25 min)

**D1.** Écris `C:\Scripts\Get-InventairePoste.ps1` qui produit **un objet** avec : nom du poste, modèle, numéro de série, processeur, RAM (Go), Windows (édition + version + build), espace libre sur C: (Go), dernier démarrage — et l'exporte dans un CSV dont le chemin est un **paramètre** (par défaut `C:\Temp\inventaire-<poste>.csv`).

> [!success]- Afficher la correction — D1
> ```powershell
> param([string]$Sortie = "C:\Temp\inventaire-$env:COMPUTERNAME.csv")
>
> $os   = Get-CimInstance Win32_OperatingSystem
> $cs   = Get-CimInstance Win32_ComputerSystem
> $bios = Get-CimInstance Win32_BIOS
> $cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1
> $c    = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
> $ver  = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion
>
> $inv = [pscustomobject]@{
>     Poste       = $env:COMPUTERNAME
>     Modele      = $cs.Model
>     NumeroSerie = $bios.SerialNumber
>     Processeur  = $cpu.Name.Trim()
>     RAM_Go      = [math]::Round($cs.TotalPhysicalMemory / 1GB)
>     Windows     = "$($os.Caption) $ver ($($os.BuildNumber))"
>     C_Libre_Go  = [math]::Round($c.FreeSpace / 1GB, 1)
>     DernierBoot = $os.LastBootUpTime
> }
> $inv
> $inv | Export-Csv -Path $Sortie -NoTypeInformation -Encoding UTF8 -Delimiter ';'
> ```
> Construire un `[pscustomobject]` plutôt qu'afficher du texte : le résultat se filtre, s'exporte, se concatène avec celui d'autres postes.

**D2.** Lance-le. Que se passe-t-il sur un Windows 11 fraîchement installé ? Corrige **pour ton utilisateur seulement**.

> [!success]- Afficher la correction — D2
> Le script est refusé : *« … l'exécution de scripts est désactivée sur ce système »*. Sur Windows 11 client, toutes les portées de `Get-ExecutionPolicy -List` sont `Undefined`, donc **`Restricted`**.
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> .\Get-InventairePoste.ps1
> ```
> ```
> Poste       : PC01
> Modele      : Virtual Machine
> NumeroSerie : 5864-9086-3401-7908-0030-5261-69
> Processeur  : 12th Gen Intel(R) Core(TM) i7-12700H
> RAM_Go      : 6
> Windows     : Microsoft Windows 11 Professionnel 26H2 (26300)
> C_Libre_Go  : 35,4
> DernierBoot : 08/11/2026 05:51:25
> ```
> `-Scope CurrentUser` ne demande pas de droits administrateur et ne touche pas les autres utilisateurs. En entreprise, la politique se fixe par **GPO** (*Composants Windows → Windows PowerShell → Activer l'exécution des scripts*), et elle prime sur tout réglage local (portée `MachinePolicy`).

**D3.** Tu télécharges le script depuis un partage Internet et il refuse de se lancer en `RemoteSigned`. Pourquoi ? Que faire ?

> [!success]- Afficher la correction — D3
> Le fichier porte la marque « provenant d'Internet » (flux NTFS `Zone.Identifier`, *Mark of the Web*). En `RemoteSigned`, un tel script doit être **signé**.
> ```powershell
> Get-Item .\script.ps1 -Stream Zone.Identifier     # la marque existe
> Unblock-File .\script.ps1                          # après avoir LU le script !
> ```

---

## Partie E — PowerShell 7 (10 min)

**E1.** Installe PowerShell 7 avec WinGet. Où s'est-il installé ? Lance-le et vérifie sa version.

> [!success]- Afficher la correction — E1
> ```powershell
> winget install --id Microsoft.PowerShell --source winget
> ```
> ```
> Found PowerShell [Microsoft.PowerShell] Version 7.6.9.0
> Successfully installed
> ```
> Surprise constatée sur le lab : depuis la 7.6, le manifeste WinGet propose par défaut le **paquet MSIX** (`Installer Type: msix`). PowerShell s'installe dans `C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.9.0_x64__8wekyb3d8bbwe\` ; `C:\Program Files\PowerShell\7\` n'existe pas.
> ```powershell
> pwsh -NoProfile -Command '$PSVersionTable.PSVersion'      # 7.6.9
> ```

**E2.** Pourquoi, pour un poste d'administration, préférer l'installeur MSI ? Installe-le.

> [!success]- Afficher la correction — E2
> Le paquet MSIX est **par utilisateur** dans son fonctionnement (alias dans le profil) et son chemin change à chaque version. Or beaucoup d'usages d'admin supposent `C:\Program Files\PowerShell\7\pwsh.exe` : sous-système SSH (`sshd_config`, chapitre 12), tâches planifiées en SYSTEM, raccourcis, GPO.
> ```powershell
> winget install --id Microsoft.PowerShell -e --installer-type wix
> Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe'     # True
> ```
> (`wix` = le type d'installeur MSI dans la terminologie WinGet.)

---

## Partie F — Bonus

**F1.** Dans `pwsh` 7, tape `Get-WmiObject Win32_BIOS`. Ça marche… alors que la commande n'existe pas en PowerShell 7. Explique (indice : `(Get-Command Get-WmiObject).Module.Path`).

> [!success]- Afficher la correction — F1
> ```powershell
> (Get-WmiObject Win32_BIOS).SerialNumber          # fonctionne !
> (Get-Command Get-WmiObject).Module.Path
> # C:\Users\admin\AppData\Local\Temp\remoteIpMoProxy_MicrosoftPowerShellManagement_3.1.0.0_localhost_….psm1
> ```
> PowerShell 7 ne contient pas `Get-WmiObject`. Quand on l'appelle, sa **couche de compatibilité Windows** démarre une session Windows PowerShell 5.1 cachée et crée un module **proxy** (`remoteIpMoProxy_…`) qui lui transmet la commande. Ça dépanne, mais c'est lent, les objets reviennent désérialisés (plus de méthodes) et ça n'existe que sous Windows. → Utiliser `Get-CimInstance`.

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/07-powershell/tp)
