# TP 07. PowerShell pour l'administrateur, version guidée

**Ta mission.** Sur `PC01`, ouvre Windows PowerShell. Construis tes commandes par étapes et observe les colonnes renvoyées avant d’ajouter un filtre.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/07-powershell/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/standard)

## Se repérer dans PowerShell

### A1 — Identifier la version du moteur

Saisis `$PSVersionTable.PSVersion` et relève `Major`.

### A2 — Trouver une commande à partir d’un nom

Lance `Get-Command -Noun Service -CommandType Cmdlet`. Repère le verbe de deux commandes, puis ouvre `Get-Help Get-Service -Examples`.

### A3 — Distinguer le nom technique du nom affiché

Lance `Get-Service` et relève les colonnes `Status`, `Name` et `DisplayName` d’un service.

## Trier, filtrer et choisir les colonnes

### B1 — Compter les objets du pipeline

Lance `Get-Process` puis `Get-Process | Measure-Object`. Lis `Count`.

### B2 — Afficher les cinq premières lignes d’un tri

Lance `Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 Name,WorkingSet64`. Relis la première et la dernière ligne.

### B3 — Filtrer les services arrêtés

Lance `Get-Service | Where-Object Status -eq Stopped | Select-Object Name,Status`. Repère une ligne, puis vérifie son type de démarrage dans `services.msc`.

## Extraire les informations d’inventaire

### C1 — Relever le numéro de série

Lance `Get-CimInstance Win32_BIOS | Select-Object SerialNumber` et relève le champ contenant le numéro.

### C2 — Relever modèle, Windows et dernier démarrage

Lance `Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer,Model` puis `Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,LastBootUpTime`.

## Atelier complémentaire. Produire un CSV (bonus)

### D1 — Exporter un inventaire de services (bonus)

Crée `C:\Temp` puis lance `Get-Service | Select-Object Name,DisplayName,Status,StartType | Export-Csv C:\Temp\services.csv -Delimiter ';' -NoTypeInformation -Encoding UTF8`. Vérifie avec `Import-Csv C:\Temp\services.csv -Delimiter ';' | Select-Object -First 3`.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/guide-corrigev2)
