---
title: "TP 07. PowerShell pour l'administrateur, version guidée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/07-powershell"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/07-powershell-guide.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/guide" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/guide-corrigev2">Afficher les corrections</a></nav>

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
