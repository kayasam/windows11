---
title: "TP 06. Processus, services, tâches planifiées et journaux, corrigé guidé"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/06-administration-diagnostic"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/06-administration-diagnostic-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Ta mission.** Sur `PC01`, tu vas reproduire un incident d’impression, le réparer et mettre en place un inventaire disque planifié. Utilise la VM de lab et garde l’accès à sa console.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/tp/standard)

## Observer les processus et les services

### A1 — Repérer le démarrage automatique

Ouvre **Gestionnaire des tâches → Applications de démarrage**. Relève une application activée, son éditeur et son impact affiché.

> [!success]- Afficher la correction — A1
> Cette vue décrit des applications lancées à l’ouverture de session. Elle ne donne pas l’état des services système.

### A2 — Identifier les processus qui occupent la mémoire

Lance `Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 Name,Id,WorkingSet64`. Lis les cinq lignes du haut.

> [!success]- Afficher la correction — A2
> `WorkingSet64` est donné en octets. La première ligne est la plus élevée au moment du relevé. L’ID identifie cette instance du processus.

### A3 — Observer un incident d’impression

Dans `services.msc`, ouvre **Spouleur d’impression**. Relève son état et son type de démarrage, puis arrête-le sur `PC01`. Essaie d’imprimer un fichier de test en PDF.

> [!success]- Afficher la correction — A3
> Les imprimantes ou le PDF peuvent devenir indisponibles. Le service `Spooler` traite aussi les travaux vers les imprimantes virtuelles.

### A4 — Rétablir l’impression

Remets le type de démarrage initial et démarre le spouleur. Refais l’impression avec **Microsoft Print to PDF**.

> [!success]- Afficher la correction — A4
> `Get-Service Spooler` affiche `Running`. Le fichier PDF obtenu démontre que l’impression fonctionne de nouveau.

## Programmer un inventaire disque

### B1 — Préparer le script

Crée `C:\Scripts` puis enregistre ce script dans `C:\Scripts\Inventaire-Disques.ps1`. Teste-le dans PowerShell en administrateur avec `& 'C:\Scripts\Inventaire-Disques.ps1'`.

```powershell
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {

    '{0} {1} {2:N1} Go libres' -f (Get-Date -Format s), $_.DeviceID, ($_.FreeSpace / 1GB)

} | Add-Content 'C:\Scripts\inventaire-disques.log'
```

> [!success]- Afficher la correction — B1
> Le journal doit contenir la date, la lettre et l’espace libre pour chaque disque fixe. Si le script est bloqué, vérifie la politique PowerShell du lab et l’origine du fichier avant de le lancer.

### B2 — Créer la tâche dans le Planificateur

Ouvre `taskschd.msc` sur `PC01`. Dans la bibliothèque, crée le dossier **Fournil** puis la tâche **Inventaire-Disques**. Sélectionne `SYSTEM`, déclenchement quotidien à **07 h 30**, programme `powershell.exe` et arguments `-NoProfile -ExecutionPolicy RemoteSigned -File C:\Scripts\Inventaire-Disques.ps1`. Dans **Paramètres**, coche le rattrapage d’un démarrage manqué et fixe une limite de 30 minutes.

> [!success]- Afficher la correction — B2
> La tâche est **Prête** et son prochain déclenchement est à 07 h 30. Vérifie le chemin du script et les droits du dossier avant de lancer la tâche sous SYSTEM.

### B3 — Lancer et contrôler la tâche

Fais un clic droit sur la tâche → **Exécuter**. Actualise la console, lis le **dernier résultat**, puis ouvre `C:\Scripts\inventaire-disques.log`.

> [!success]- Afficher la correction — B3
> Un dernier résultat `0x0` et une nouvelle ligne datée confirment l’exécution. Si le journal ne change pas, compare l’heure de dernière exécution et vérifie l’action configurée.

## Lire les traces

### C1 — Filtrer les événements du système

Ouvre `eventvwr.msc` → **Journaux Windows → Système → Filtrer le journal actuel**. Sélectionne **24 dernières heures**, **Critique** et **Erreur**. Relève la source et l’heure d’une entrée si la liste en contient.

> [!success]- Afficher la correction — C1
> L’ID seul ne suffit pas. Ouvre l’entrée pour lire le fournisseur, le message et le contexte. Une liste vide est possible.

### C2 — Lire le Moniteur de fiabilité

Ouvre `perfmon /rel` et sélectionne une journée où une erreur ou un avertissement apparaît. Relève l’application et l’heure.

> [!success]- Afficher la correction — C2
> Le Moniteur de fiabilité permet de situer un incident dans le temps. Approfondis avec le journal correspondant si un événement mérite une investigation.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/tp/guide)
