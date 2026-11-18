# TP 05. Pilotes, applications et WinGet, version guidée

**Ta mission.** Sur `PC01`, identifie un pilote, exporte le magasin de pilotes tiers puis installe et inventorie le socle logiciel du Fournil.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp/standard)

## Examiner les pilotes

### A1 — Identifier la carte réseau

Lance `devmgmt.msc`, ouvre **Cartes réseau**, puis les propriétés de la carte Ethernet de la VM. Dans l’onglet **Pilote**, relève fournisseur et version.

### A2 — Filtrer les périphériques réellement présents

Dans PowerShell, lance `Get-PnpDevice -PresentOnly | Where-Object Status -ne 'OK'`. Note les périphériques affichés, s’il y en a.

### A3 — Lire l’inventaire des pilotes tiers

Dans PowerShell administrateur, lance `pnputil /enum-drivers`. Pour un pilote, relève **Nom publié** et **Nom d’origine**.

### A4 — Exporter les pilotes

Crée `C:\Sauvegarde\Pilotes`, puis lance `pnputil /export-driver * C:\Sauvegarde\Pilotes` en administrateur. Ouvre le dossier et recherche des fichiers `.inf`.

## Inventorier et équiper le poste

### B1 — Distinguer image et session

Compare `Get-AppxProvisionedPackage -Online | Select-Object DisplayName` en administrateur et `Get-AppxPackage | Select-Object Name` dans ta session.

### B2 — Remplacer une commande WMIC d’inventaire

Dans PowerShell, lance `Get-CimInstance Win32_BIOS | Select-Object SerialNumber`. Repère la colonne renvoyée.

### B3 — Identifier la source WinGet

Sur `PC01`, lance `winget --version`, `winget source list` et `winget search --id 7zip.7zip --exact --source winget`.

### B4 — Installer le socle logiciel

Dans PowerShell administrateur, installe 7-Zip avec `winget install --id 7zip.7zip --exact --source winget --scope machine --silent --accept-package-agreements --accept-source-agreements`. Répète avec l’ID `Notepad++.Notepad++`, puis vérifie avec `winget list`.

### B5 — Exporter la liste des applications

Crée `C:\Temp` et lance `winget export -o C:\Temp\socle-fournil.json`. Ouvre le fichier puis lance `winget upgrade` pour voir l’état des mises à jour des applications.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp/guide-corrigev2)
