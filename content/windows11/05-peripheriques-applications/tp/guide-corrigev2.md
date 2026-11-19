---
title: "TP 05. Pilotes, applications et WinGet, corrigé guidé"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/05-peripheriques-applications"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/05-peripheriques-applications-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

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

### B1 — Distinguer image et session (bonus)

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
