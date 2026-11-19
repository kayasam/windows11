---
title: "TP 07. PowerShell pour l'administrateur — Correction"
aliases: ["windows11/07-powershell/tp-corrigev2"]
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/07-powershell"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/07-powershell-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/standard">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/standard-corrigev2" aria-current="page">Corrigé</a></nav>

> [!abstract] Parcours TSSR
> Socle débutant : lire des commandes, utiliser l’aide et essayer un pipeline simple avec les exemples du cours. Aucun calcul ni script à écrire n’est requis. Les parties D, E et F sont entièrement (bonus).

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Chapitres associés : [07. PowerShell pour l'administrateur](https://cours.kaya.ovh/windows11/windows11/07-powershell/)

---

## Objectifs

- Trouver une commande et lire ses exemples avec le cours ouvert
- Lire un pipeline simple : choisir des colonnes, trier et filtrer avec une seule condition
- Lire les informations du poste avec les commandes CIM fournies
- Écrire un script paramétré qui produit un inventaire CSV (bonus)
- Installer PowerShell 7 correctement et comprendre la politique d'exécution (bonus)

---

## Prérequis

- `PC01`, session `admin`, Windows Terminal

---

## Partie A — Se repérer

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

**A3.** Affiche uniquement les **exemples** de l'aide de `Get-Service`. Que faire si l'aide est minimale ?

> [!success]- Afficher la correction — A3
> ```powershell
> Get-Help Get-Service -Examples
> ```
> Si l'aide se limite à la syntaxe, c'est qu'elle n'a jamais été téléchargée : `Update-Help -UICulture en-US -Force` (terminal administrateur ; l'aide française est incomplète). Si le téléchargement n’est pas possible, utiliser les exemples du cours ; l’aide en ligne nécessite une connexion Internet.

**A4.** Exécute `Get-Service`. Repère les colonnes `Status`, `Name` et `DisplayName`. Laquelle donne l’état du service ? Quelle différence entre le nom technique et le nom affiché ?

> [!success]- Afficher la correction — A4
> ```powershell
> Get-Service
> ```
> `Status` indique l’état (`Running` ou `Stopped`). `Name` est le nom technique à utiliser dans les commandes ; `DisplayName` est le nom affiché à l’utilisateur. Aucune exploration avec Get-Member n’est nécessaire dans le socle.

---

## Partie B — Pipeline

**B1.** Exécute `Get-Process`, puis `Get-Process | Measure-Object`. Combien de processus indique la valeur `Count` ?

> [!success]- Afficher la correction — B1
> ```powershell
> Get-Process | Measure-Object
> ```
> Lire `Count`. Le nombre dépend du poste et des programmes ouverts ; aucune valeur fixe n’est attendue.

**B2.** Avec la commande fournie dans le cours, affiche les cinq processus les plus consommateurs de mémoire avec `Name` et `WorkingSet64`. Garde les valeurs en octets : aucun calcul ni arrondi n’est demandé. Explique le rôle de `-Descending` et de `-First 5`.

> [!success]- Afficher la correction — B2
> ```powershell
> Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 Name, WorkingSet64
> ```
> Lire de gauche à droite : lister les processus, trier la mémoire par ordre décroissant, puis garder les cinq premiers avec les colonnes indiquées. WorkingSet64 est exprimé en octets ; aucune conversion n’est demandée.

**B3.** Avec `Get-Service | Where-Object Status -eq Stopped`, affiche les services arrêtés. Ajoute ensuite `Select-Object Name, Status` pour choisir les colonnes. Que signifie `-eq` ? Un service arrêté est-il toujours en panne ?

> [!success]- Afficher la correction — B3
> ```powershell
> Get-Service | Where-Object Status -eq Stopped | Select-Object Name, Status
> ```
> `-eq` signifie « égal à ». On garde uniquement les services arrêtés. Ce n’est pas nécessairement une panne : certains ne démarrent qu’en cas de besoin.

**B4.** (bonus) Exporte la liste des services (nom, nom affiché, état, type de démarrage) dans `C:\Temp\services.csv`, séparateur `;`, ouvrable dans Excel.

> [!success]- Afficher la correction — B4
> ```powershell
> Get-Service | Select-Object Name, DisplayName, Status, StartType |
>     Export-Csv C:\Temp\services.csv -NoTypeInformation -Delimiter ';' -Encoding UTF8
> ```
> `-Delimiter ';'` : Excel en français attend le point-virgule. `-NoTypeInformation` évite la ligne `#TYPE` en tête (inutile en PowerShell 7, où c'est le défaut).

---

## Partie C — Lire les informations du poste

**C1.** Exécute la commande fournie : `Get-CimInstance Win32_BIOS | Select-Object SerialNumber`. Relève le numéro de série et explique son utilité pour un inventaire ou une demande au support.

> [!success]- Afficher la correction — C1
> ```powershell
> Get-CimInstance Win32_BIOS | Select-Object SerialNumber
> ```
> Le numéro identifie le poste dans un inventaire ou une demande au support. Une VM Hyper-V présente aussi une valeur ; il n’est pas demandé d’étudier les classes CIM ni les anciens outils.

**C2.** Utilise les commandes fournies dans le cours pour afficher le fabricant, le modèle, la version de Windows et la date du dernier démarrage. Aucun calcul de RAM ni conversion d’unité n’est demandé.

> [!success]- Afficher la correction — C2
> ```powershell
> Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model
> Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, LastBootUpTime
> ```
> `Manufacturer` et `Model` décrivent le matériel. `Caption` et `Version` décrivent Windows, `LastBootUpTime` indique son dernier démarrage. Les valeurs sont conservées telles quelles, sans calcul.

**C3.** (bonus) Trouve, sans Internet, le nom de la classe CIM qui décrit les cartes réseau.

> [!success]- Afficher la correction — C3
> ```powershell
> Get-CimClass -ClassName *NetworkAdapter*
> ```
> `Win32_NetworkAdapter` (cartes) et `Win32_NetworkAdapterConfiguration` (IP, DNS, DHCP). En pratique, les cmdlets `Get-NetAdapter` / `Get-NetIPConfiguration` sont plus confortables… et reposent elles-mêmes sur CIM (`MSFT_NetAdapter`).

---

## Partie D — Un script d'inventaire (bonus)

> [!NOTE] Pour aller plus loin uniquement
> Cette partie est facultative. Les variables, paramètres, objets personnalisés et conversions qu’elle utilise ne sont pas à maîtriser pour suivre la suite. Le script Get-Inventaire.ps1 du TP final est fourni séparément.

**D1.** Complète la trame ci-dessous et enregistre-la dans `C:\Scripts\Get-InventairePoste.ps1` qui produit **un objet** avec : nom du poste, modèle, numéro de série, processeur, RAM (Go), Windows (édition + version + build), espace libre sur C: (Go), dernier démarrage — et l'exporte dans un CSV dont le chemin est un **paramètre** (par défaut `C:\Temp\inventaire-<poste>.csv`).

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
>
> ![w11-07-script-refuse-restricted](https://cours.kaya.ovh/windows11/assets/captures/w11-07-script-refuse-restricted.png)
>
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> .\Get-InventairePoste.ps1
> ```
> ```
> Poste       : PC01
> Modele      : Virtual Machine
> NumeroSerie : 5864-9086-3401-7908-0030-5261-69
> Processeur  : 12th Gen Intel(R) Core(TM) i7-12700H
> RAM_Go      : 4
> Windows     : Microsoft Windows 11 Professionnel 26H2 (26300)
> C_Libre_Go  : 35,4
> DernierBoot : 08/11/2026 05:51:25
> ```
> ![w11-07-script-inventaire-ok](https://cours.kaya.ovh/windows11/assets/captures/w11-07-script-inventaire-ok.png)
>
> Le CSV `C:\Temp\inventaire-PC01.csv` contient les 8 colonnes, toutes remplies. Si `Export-Csv` répond *« Impossible de trouver une partie du chemin »*, c'est que `C:\Temp` n'existe pas.
>
> `-Scope CurrentUser` ne demande pas de droits administrateur et ne touche pas les autres utilisateurs. En entreprise, la politique se fixe par **GPO** (*Composants Windows → Windows PowerShell → Activer l'exécution des scripts*), et elle prime sur tout réglage local (portée `MachinePolicy`).

**D3.** Tu télécharges le script depuis un partage Internet et il refuse de se lancer en `RemoteSigned`. Pourquoi ? Que faire ?

> [!success]- Afficher la correction — D3
> Le fichier porte la marque « provenant d'Internet » (flux NTFS `Zone.Identifier`, *Mark of the Web*). En `RemoteSigned`, un tel script doit être **signé**.
> ```powershell
> Get-Item .\script.ps1 -Stream Zone.Identifier     # la marque existe
> Unblock-File .\script.ps1                          # après avoir LU le script !
> ```

---

## Partie E — PowerShell 7 (bonus)

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
> Le paquet MSIX est **par utilisateur** dans son fonctionnement (alias dans le profil) et son chemin change à chaque version. Or beaucoup d'usages d'admin supposent `C:\Program Files\PowerShell\7\pwsh.exe` : sous-système SSH (`sshd_config`, chapitre 16), tâches planifiées en SYSTEM, raccourcis, GPO.
> ```powershell
> winget install --id Microsoft.PowerShell -e --installer-type wix
> Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe'     # True
> ```
> (`wix` = le type d'installeur MSI dans la terminologie WinGet.)

---

## Partie F — Exercices complémentaires (bonus)

**F1.** Dans `pwsh` 7, tape `Get-WmiObject Win32_BIOS`. Ça marche… alors que la commande n'existe pas en PowerShell 7. Explique (indice : `(Get-Command Get-WmiObject).Module.Path`).

> [!success]- Afficher la correction — F1
> ```powershell
> (Get-WmiObject Win32_BIOS).SerialNumber          # fonctionne !
> (Get-Command Get-WmiObject).Module.Path
> # C:\Users\admin\AppData\Local\Temp\remoteIpMoProxy_MicrosoftPowerShellManagement_3.1.0.0_localhost_….psm1
> ```
> PowerShell 7 ne contient pas `Get-WmiObject`. Quand on l'appelle, sa **couche de compatibilité Windows** démarre une session Windows PowerShell 5.1 cachée et crée un module **proxy** (`remoteIpMoProxy_…`) qui lui transmet la commande. Ça dépanne, mais c'est lent, les objets reviennent désérialisés (plus de méthodes) et ça n'existe que sous Windows. → Utiliser `Get-CimInstance`.

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/standard)
