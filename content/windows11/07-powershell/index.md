---
title: "07. PowerShell pour l'administrateur"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/07-powershell"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/07-powershell.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Utiliser PowerShell pour administrer Windows 11 : distinguer les consoles disponibles, manipuler le pipeline, interroger le système avec **CIM/WMI** (WMIC n'existe plus), écrire un script de base et comprendre la politique d'exécution.
>
> **Outils :** Windows PowerShell 5.1, PowerShell 7, Windows Terminal, VS Code
> **Commandes à connaître :** `Get-Help`, `Get-Command`, `Get-Member`, `Where-Object`, `Select-Object`, `Get-CimInstance`, `Set-ExecutionPolicy`

> [!INFO] Fil rouge — Fournil
> On écrit sur `PC01` un script d'inventaire matériel du poste (`Get-InventairePoste.ps1`), réutilisé au chapitre 20.

---

## Console PowerShell vs Windows Terminal vs ISE vs VS Code

| | Windows PowerShell 5.1 | PowerShell 7+ (Core) | Windows Terminal | ISE | VS Code |
|-|------------------------|------------------------|-------------------|-----|---------|
| **Nature** | Moteur intégré à Windows depuis Windows 7/8 | Moteur multiplateforme (Windows/Linux/macOS), à installer séparément | Application hôte (fenêtre, onglets), pas un moteur | Éditeur graphique historique pour Windows PowerShell | Éditeur de code moderne, avec l'extension **PowerShell** |
| **Présent par défaut sur Windows 11** | Oui | Non — à installer via winget/Microsoft Store | Oui (par défaut depuis Windows 11 21H2+) | Oui, mais déprécié | Non — à installer séparément |
| **Exécutable** | `powershell.exe` | `pwsh.exe` | `wt.exe` (héberge n'importe quelle console) | `powershell_ise.exe` | `code.exe` |
| **Développement actif** | Non — en mode maintenance uniquement | Oui — nouvelles fonctionnalités, releases régulières | Oui | Non — dépréciée | Oui — c'est le remplaçant officiel de l'ISE |

> [!TIP] VS Code + extension PowerShell = successeur officiel de l'ISE
> Microsoft ne développe plus l'ISE et recommande **Visual Studio Code** avec l'extension **PowerShell** pour l'édition et le débogage de scripts : coloration syntaxique, IntelliSense, débogueur pas-à-pas, intégration Git — l'ISE ne propose aucun de ces points au-delà de la coloration basique, et ne fonctionne qu'avec Windows PowerShell 5.1 (pas PowerShell 7).

> [!NOTE] Windows PowerShell 5.1 reste la référence pour l'administration Windows locale
> De nombreux modules d'administration Windows historiques (certains liés à AD, WMI ancien style) ne fonctionnent qu'en Windows PowerShell 5.1. PowerShell 7 est recommandé pour les nouveaux scripts et l'usage multiplateforme, mais sur un poste Windows 11 standard, `powershell.exe` (5.1) reste la commande par défaut tant que PowerShell 7 n'est pas installé explicitement.

**Installer PowerShell 7 avec winget** (déjà présent sur Windows 11) :

```powershell
winget install --id Microsoft.PowerShell --source winget
```

Une fois installé, `pwsh.exe` s'ajoute comme profil dans Windows Terminal, à côté de `powershell.exe` (5.1) — les deux moteurs coexistent sans conflit.

> [!WARNING] Depuis PowerShell 7.6, WinGet installe la version MSIX
> Constaté sur `PC01` : `winget install Microsoft.PowerShell` installe **PowerShell 7.6.9 en paquet MSIX**, dans `C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.9.0_x64__8wekyb3d8bbwe\`, et **plus** dans `C:\Program Files\PowerShell\7\`. `pwsh` se lance normalement (alias dans `%LOCALAPPDATA%\Microsoft\WindowsApps`), mais tout ce qui suppose l'ancien chemin casse : sous-système SSH (chapitre 12), tâches planifiées en SYSTEM, scripts qui appellent `C:\Program Files\PowerShell\7\pwsh.exe`.
> Pour un poste ou un serveur d'administration, préférer le **MSI** :
> ```powershell
> winget install --id Microsoft.PowerShell --installer-type wix     # MSI → C:\Program Files\PowerShell\7
> ```

**Windows Terminal** n'est pas un moteur PowerShell : c'est l'application qui héberge la fenêtre (onglets, panneaux, thèmes). Elle peut ouvrir des profils Windows PowerShell 5.1, PowerShell 7, CMD ou WSL indifféremment.

---

## Cmdlets essentielles

Une cmdlet PowerShell suit toujours la convention **Verbe-Nom** (`Get-Process`, `Stop-Service`, `New-Item`).

| Cmdlet | Rôle |
|--------|------|
| `Get-Process` | Liste les processus en cours d'exécution |
| `Get-Service` | Liste les services et leur état |
| `Get-NetAdapter` | Liste les cartes réseau et leur état |
| `Get-ChildItem` | Liste le contenu d'un dossier (équivalent `dir`/`ls`) |
| `Get-Command` | Recherche une cmdlet par nom ou par verbe/nom |
| `Get-Help` | Affiche l'aide d'une cmdlet |
| `Get-Member` | Liste les propriétés et méthodes des objets renvoyés par une commande |

```powershell
# Découvrir les cmdlets disponibles pour un nom donné
Get-Command -Noun Service

# Aide complète avec exemples (télécharge l'aide à jour la première fois)
Update-Help -Force
Get-Help Get-Service -Full
Get-Help Get-Service -Examples

# Découvrir les propriétés d'un objet renvoyé
Get-Service | Get-Member
```

> [!TIP] PowerShell manipule des objets, pas du texte
> Contrairement à CMD ou Bash, chaque cmdlet renvoie des **objets .NET** avec des propriétés typées, pas de simples lignes de texte. C'est ce qui permet de trier, filtrer et sélectionner des propriétés précises sans découpage de chaînes de caractères (`awk`, `cut`...).

---

## Pipeline et filtrage

Le pipeline (`|`) transmet les objets renvoyés par une cmdlet à la suivante.

| Cmdlet de filtrage | Rôle |
|---------------------|------|
| `Where-Object` | Filtre les objets selon une condition |
| `Select-Object` | Sélectionne certaines propriétés, ou les N premiers/derniers résultats |
| `Sort-Object` | Trie les objets selon une ou plusieurs propriétés |
| `Format-Table` / `Format-List` | Force un affichage en tableau ou en liste |
| `Measure-Object` | Calcule des statistiques (nombre, somme, moyenne...) |
| `ForEach-Object` | Exécute une action pour chaque objet du pipeline |

```powershell
# Processus consommant le plus de mémoire, triés par ordre décroissant
Get-Process | Sort-Object WS -Descending | Select-Object -First 5 Name, WS

# Services arrêtés dont le démarrage est "Automatique" (anomalie potentielle)
Get-Service | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" }

# Compter le nombre de processus en cours
Get-Process | Measure-Object | Select-Object -ExpandProperty Count

# Appliquer une action à chaque élément du pipeline
Get-Service -Name "Sp*" | ForEach-Object { "$($_.Name) : $($_.Status)" }
```

> [!TIP] `$_` représente l'objet courant dans le pipeline
> À l'intérieur d'un bloc de script `{ }` passé à `Where-Object` ou `ForEach-Object`, `$_` désigne l'objet en cours de traitement. Depuis PowerShell 3.0, `Where-Object Status -eq "Stopped"` (syntaxe simplifiée sans `$_`) fonctionne aussi pour les comparaisons simples.

---

## Interroger le système : CIM et WMI

**WMI** (*Windows Management Instrumentation*) est la base de données de gestion de Windows : matériel, système, services, disques, logiciels… Elle est organisée en **classes** (`Win32_BIOS`, `Win32_OperatingSystem`, `Win32_LogicalDisk`…). **CIM** est le standard sur lequel WMI repose ; en PowerShell moderne, on l'interroge avec les cmdlets `*-CimInstance`.

```powershell
# Numéro de série et version du BIOS (étiquette d'inventaire)
Get-CimInstance Win32_BIOS | Select-Object SerialNumber, SMBIOSBIOSVersion, Manufacturer

# Système : version, dernier démarrage
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, LastBootUpTime

# Modèle de la machine, mémoire
Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model, @{N="RAM_Go";E={[math]::Round($_.TotalPhysicalMemory/1GB)}}

# Disques fixes et espace libre (filtre WQL côté WMI)
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, @{N="Libre_Go";E={[math]::Round($_.FreeSpace/1GB,1)}}

# À distance (WinRM, chapitre 12)
Get-CimInstance Win32_OperatingSystem -ComputerName SRV01
```

| Ancien | Moderne | Remarque |
|--------|---------|----------|
| `wmic bios get serialnumber` | `(Get-CimInstance Win32_BIOS).SerialNumber` | **WMIC est supprimé** de Windows 11 (25H2+) |
| `Get-WmiObject Win32_BIOS` | `Get-CimInstance Win32_BIOS` | `Get-WmiObject` ne fait pas partie de PowerShell 7 ; CIM passe par WinRM, plus sûr et compatible pare-feu |

> [!NOTE] « Mais `Get-WmiObject` marche dans mon pwsh 7 ! » — constaté sur le lab
> Dans PowerShell 7.6 sous Windows, `Get-WmiObject` et `Get-EventLog` répondent… via la **couche de compatibilité Windows PowerShell** : pwsh lance en arrière-plan une session 5.1 invisible et lui délègue la commande (le module chargé s'appelle `remoteIpMoProxy_MicrosoftPowerShellManagement_3.1.0.0_localhost_…`). C'est plus lent, les objets reviennent « désérialisés », et ça n'existe pas sous Linux/macOS. Bon réflexe : écrire du code natif (`Get-CimInstance`, `Get-WinEvent`).

> [!TIP] Trouver la bonne classe
> `Get-CimClass -ClassName *disk*` liste les classes dont le nom contient « disk ». Puis `Get-CimInstance <classe> | Get-Member` montre leurs propriétés.

---

## Scripts de base (.ps1) et politique d'exécution

Un script PowerShell est un fichier texte `.ps1` contenant une suite de commandes.

```powershell
# Contenu d'un script simple : verifier-espace-disque.ps1

# Bloc de paramètres : DOIT être la première instruction du script (hors commentaires)
param(
    [string]$Lecteur = "C:"   # valeur par défaut si -Lecteur n'est pas fourni au lancement
)

# Get-PSDrive attend le nom du lecteur SANS le ":" (ex: "C" et non "C:") -> TrimEnd(":") le retire
$disque = Get-PSDrive -Name $Lecteur.TrimEnd(":")

# $disque.Free est en octets : on divise par 1GB (constante PowerShell) et on arrondit à 2 décimales
$libreGo = [math]::Round($disque.Free / 1GB, 2)

# Structure conditionnelle : une seule des deux branches s'exécute
if ($libreGo -lt 10) {
    # Write-Warning affiche le message en jaune, préfixé "AVERTISSEMENT :"
    Write-Warning "Espace disque faible sur $Lecteur : $libreGo Go libres"
} else {
    # Write-Host affiche simplement le message dans la console
    Write-Host "Espace disque OK sur $Lecteur : $libreGo Go libres"
}
```

```powershell
# Exécuter le script avec un paramètre
.\verifier-espace-disque.ps1 -Lecteur "D:"
```

### Politique d'exécution (Execution Policy)

La politique d'exécution contrôle quels scripts `.ps1` PowerShell accepte de lancer — ce n'est **pas** une mesure de sécurité contre un attaquant déterminé (facilement contournable localement), mais un garde-fou contre l'exécution accidentelle de scripts.

| Politique | Comportement |
|-----------|--------------|
| **Restricted** | Aucun script ne s'exécute — seules les commandes interactives sont autorisées. **Par défaut sur Windows 11 client.** |
| **AllSigned** | Seuls les scripts signés par un éditeur de confiance s'exécutent |
| **RemoteSigned** | Les scripts locaux s'exécutent librement ; les scripts téléchargés (zone Internet) doivent être signés. **Par défaut sur Windows Server.** |
| **Unrestricted** | Tous les scripts s'exécutent, avec avertissement pour les scripts téléchargés |
| **Bypass** | Tous les scripts s'exécutent sans aucun avertissement |

Sur un Windows 11 26H2 fraîchement installé (`PC01`), toutes les portées sont à `Undefined` — ce qui équivaut à **`Restricted`** :

```
        Scope ExecutionPolicy
        ----- ---------------
MachinePolicy       Undefined
   UserPolicy       Undefined
      Process       Undefined
  CurrentUser       Undefined
 LocalMachine       Undefined
```

> [!WARNING] `Restricted` bloque aussi les modules
> En `Restricted`, ce ne sont pas seulement vos scripts qui sont refusés : les **modules** installés depuis la PowerShell Gallery (fichiers `.psm1`, `.ps1xml`) ne se chargent pas non plus. Vécu sur le lab avec `Microsoft.WinGet.Client` : *« Échec de la vérification d'AuthorizationManager »* (TP 05).

```powershell
# Consulter la politique actuelle par portée (Process, CurrentUser, LocalMachine...)
Get-ExecutionPolicy -List

# Modifier la politique pour la machine (nécessite un terminal administrateur)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

> [!WARNING] Un fichier téléchargé peut rester bloqué même en RemoteSigned
> Un script `.ps1` téléchargé depuis Internet est marqué par une "zone Internet" (flux alternatif NTFS `Zone.Identifier`) — en `RemoteSigned`, il refusera de s'exécuter tant qu'il n'est pas débloqué :
> ```powershell
> Unblock-File -Path .\script-telecharge.ps1
> ```

---

## Récapitulatif

```
Consoles
  Windows PowerShell 5.1 (intégré, maintenance) vs PowerShell 7 (à installer, actif)
  Windows Terminal = fenêtre hôte, pas un moteur | ISE = déprécié, remplacé par VS Code

Cmdlets et aide
  Verbe-Nom | Get-Help -Full/-Examples | Get-Member pour explorer les objets

CIM / WMI
  Get-CimInstance Win32_BIOS | Win32_OperatingSystem | Win32_ComputerSystem | Win32_LogicalDisk
  WMIC supprimé, Get-WmiObject absent de PS 7 → Get-CimInstance

Pipeline
  Where-Object (filtrer) | Select-Object (choisir) | Sort-Object (trier)
  Measure-Object (statistiques) | ForEach-Object (agir sur chaque élément)

Scripts et politique d'exécution
  Restricted (défaut client) → RemoteSigned (défaut serveur) → Unrestricted → Bypass
  Unblock-File pour un script téléchargé bloqué malgré RemoteSigned

La gestion à distance (PowerShell Remoting, WinRS, OpenSSH) est couverte au chapitre 12,
une fois SRV01 promue en contrôleur de domaine (chapitre 10).
```
