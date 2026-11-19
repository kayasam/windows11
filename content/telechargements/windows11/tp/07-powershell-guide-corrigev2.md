# TP 07. PowerShell pour l'administrateur, corrigé guidé

**Ta mission.** Sur `PC01`, ouvre Windows PowerShell. Construis tes commandes par étapes et observe les colonnes renvoyées avant d’ajouter un filtre.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/07-powershell/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/standard)

## Se repérer dans PowerShell

### A1 — Identifier la version du moteur

Saisis `$PSVersionTable.PSVersion` et relève `Major`.

> [!success]- Afficher la correction — A1
> `5` correspond à Windows PowerShell 5.1 dans le lab. Dans une console `pwsh`, la valeur majeure peut être `7`. Le nom de l’application **Terminal** ne suffit pas à identifier le moteur.

### A2 — Trouver une commande à partir d’un nom

Lance `Get-Command -Noun Service -CommandType Cmdlet`. Repère le verbe de deux commandes, puis ouvre `Get-Help Get-Service -Examples`.

> [!success]- Afficher la correction — A2
> Le nom de commande suit généralement le modèle **Verbe-Nom**. `-Examples` affiche des exemples. Si l’aide locale est minimale, le cours et l’aide en ligne donnent des exemples complémentaires.

### A3 — Distinguer le nom technique du nom affiché

Lance `Get-Service` et relève les colonnes `Status`, `Name` et `DisplayName` d’un service.

> [!success]- Afficher la correction — A3
> `Name` sert de référence technique. `DisplayName` est le libellé lisible dans l’interface et `Status` indique l’état actuel.

## Trier, filtrer et choisir les colonnes

### B1 — Compter les objets du pipeline

Lance `Get-Process` puis `Get-Process | Measure-Object`. Lis `Count`.

> [!success]- Afficher la correction — B1
> `Get-Process` produit un objet par processus et `Measure-Object` les compte. La valeur change avec l’activité du poste.

### B2 — Afficher les cinq premières lignes d’un tri

Lance `Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 Name,WorkingSet64`. Relis la première et la dernière ligne.

> [!success]- Afficher la correction — B2
> `-Descending` trie du plus grand au plus petit et `-First 5` garde les cinq premiers objets. La valeur de mémoire reste en octets.

### B3 — Filtrer les services arrêtés

Lance `Get-Service | Where-Object Status -eq Stopped | Select-Object Name,Status`. Repère une ligne, puis vérifie son type de démarrage dans `services.msc`.

> [!success]- Afficher la correction — B3
> `-eq` compare deux valeurs et `Select-Object` choisit les propriétés affichées. Un service manuel arrêté peut être dans son état normal.

## Extraire les informations d’inventaire

### C1 — Relever le numéro de série

Lance `Get-CimInstance Win32_BIOS | Select-Object SerialNumber` et relève le champ contenant le numéro.

> [!success]- Afficher la correction — C1
> `SerialNumber` identifie la machine dans une fiche de support. Une VM peut exposer un numéro généré par l’hyperviseur.

### C2 — Relever modèle, Windows et dernier démarrage

Lance `Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer,Model` puis `Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,LastBootUpTime`.

> [!success]- Afficher la correction — C2
> La première classe décrit l’ordinateur. La seconde donne l’édition, la version du système et la date de démarrage.

## Atelier complémentaire. Produire un CSV (bonus)

### D1 — Exporter un inventaire de services (bonus)

Crée `C:\Temp` puis lance `Get-Service | Select-Object Name,DisplayName,Status,StartType | Export-Csv C:\Temp\services.csv -Delimiter ';' -NoTypeInformation -Encoding UTF8`. Vérifie avec `Import-Csv C:\Temp\services.csv -Delimiter ';' | Select-Object -First 3`.

> [!success]- Afficher la correction — D1
> La première ligne contient les quatre noms de colonne. Le test avec `Import-Csv` confirme que le séparateur et les données sont interprétés correctement.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/guide)
