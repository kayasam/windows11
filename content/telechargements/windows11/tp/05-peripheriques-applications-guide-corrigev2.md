# TP 05. Pilotes, applications et WinGet, corrigé guidé

**Ta mission.** Sur `PC01`, identifie un pilote, exporte le magasin de pilotes tiers puis installe et inventorie le socle logiciel du Fournil.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp/standard)

## Examiner les pilotes

### A1 — Identifier la carte réseau

Lance `devmgmt.msc`, ouvre **Cartes réseau**, puis les propriétés de la carte Ethernet de la VM. Dans l’onglet **Pilote**, relève fournisseur et version.

> [!success]- Afficher la correction — A1
> Dans cette VM, la carte attendue est l’adaptateur réseau virtuel Hyper-V. Le fournisseur et la version permettent de distinguer son pilote d’un périphérique caché ou d’une autre carte.

### A2 — Filtrer les périphériques réellement présents

Dans PowerShell, lance `Get-PnpDevice -PresentOnly | Where-Object Status -ne 'OK'`. Note les périphériques affichés, s’il y en a.

> [!success]- Afficher la correction — A2
> Avec `-PresentOnly`, la liste ignore les périphériques historiques déconnectés. Si elle est vide, aucun périphérique présent ne ressort avec un statut différent de `OK`.

### A3 — Lire l’inventaire des pilotes tiers

Dans PowerShell administrateur, lance `pnputil /enum-drivers`. Pour un pilote, relève **Nom publié** et **Nom d’origine**.

> [!success]- Afficher la correction — A3
> `oemN.inf` est le nom sous lequel le pilote a été publié dans le magasin local. Le nom d’origine correspond au fichier INF fourni par l’éditeur.

### A4 — Exporter les pilotes

Crée `C:\Sauvegarde\Pilotes`, puis lance `pnputil /export-driver * C:\Sauvegarde\Pilotes` en administrateur. Ouvre le dossier et recherche des fichiers `.inf`.

> [!success]- Afficher la correction — A4
> L’export contient les paquets tiers présents. S’il n’y en a aucun dans B1, l’absence de fichiers exportés est cohérente.

## Inventorier et équiper le poste

### B1 — Distinguer image et session

Compare `Get-AppxProvisionedPackage -Online | Select-Object DisplayName` en administrateur et `Get-AppxPackage | Select-Object Name` dans ta session.

> [!success]- Afficher la correction — B1
> Le premier inventaire concerne les applications qui seront provisionnées pour les futurs profils. Le second décrit les paquets installés pour l’utilisateur courant.

### B2 — Remplacer une commande WMIC d’inventaire

Dans PowerShell, lance `Get-CimInstance Win32_BIOS | Select-Object SerialNumber`. Repère la colonne renvoyée.

> [!success]- Afficher la correction — B2
> `SerialNumber` remplit le même besoin d’inventaire que l’ancienne commande `wmic bios get serialnumber`.

### B3 — Identifier la source WinGet

Sur `PC01`, lance `winget --version`, `winget source list` et `winget search --id 7zip.7zip --exact --source winget`.

> [!success]- Afficher la correction — B3
> La recherche doit identifier le paquet `7zip.7zip` de la source `winget`. Ce résultat permet de choisir un paquet sans ambiguïté.

### B4 — Installer le socle logiciel

Dans PowerShell administrateur, installe 7-Zip avec `winget install --id 7zip.7zip --exact --source winget --scope machine --silent --accept-package-agreements --accept-source-agreements`. Répète avec l’ID `Notepad++.Notepad++`, puis vérifie avec `winget list`.

> [!success]- Afficher la correction — B4
> Les entrées 7-Zip et Notepad++ sont affichées. `--scope machine` cible le poste et `--exact` utilise l’identifiant choisi.

### B5 — Exporter la liste des applications

Crée `C:\Temp` et lance `winget export -o C:\Temp\socle-fournil.json`. Ouvre le fichier puis lance `winget upgrade` pour voir l’état des mises à jour des applications.

> [!success]- Afficher la correction — B5
> Le JSON contient des identifiants de paquets exportables et leurs sources. Les logiciels que WinGet ne sait pas associer à une source peuvent manquer. Windows Update et WinGet couvrent des inventaires différents.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp/guide)
