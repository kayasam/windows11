# TP 06. Processus, services, tâches planifiées et journaux, version guidée

**Ta mission.** Sur `PC01`, tu vas reproduire un incident d’impression, le réparer et mettre en place un inventaire disque planifié. Utilise la VM de lab et garde l’accès à sa console.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/tp/standard)

## Observer les processus et les services

### A1 — Repérer le démarrage automatique

Ouvre **Gestionnaire des tâches → Applications de démarrage**. Relève une application activée, son éditeur et son impact affiché.

### A2 — Identifier les processus qui occupent la mémoire

Lance `Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 Name,Id,WorkingSet64`. Lis les cinq lignes du haut.

### A3 — Observer un incident d’impression

Dans `services.msc`, ouvre **Spouleur d’impression**. Relève son état et son type de démarrage, puis arrête-le sur `PC01`. Essaie d’imprimer un fichier de test en PDF.

### A4 — Rétablir l’impression

Remets le type de démarrage initial et démarre le spouleur. Refais l’impression avec **Microsoft Print to PDF**.

## Programmer un inventaire disque

### B1 — Préparer le script

Crée `C:\Scripts` puis enregistre ce script dans `C:\Scripts\Inventaire-Disques.ps1`. Teste-le dans PowerShell en administrateur avec `& 'C:\Scripts\Inventaire-Disques.ps1'`.

```powershell
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {

    '{0} {1} {2:N1} Go libres' -f (Get-Date -Format s), $_.DeviceID, ($_.FreeSpace / 1GB)

} | Add-Content 'C:\Scripts\inventaire-disques.log'
```

### B2 — Créer la tâche dans le Planificateur

Ouvre `taskschd.msc` sur `PC01`. Dans la bibliothèque, crée le dossier **Fournil** puis la tâche **Inventaire-Disques**. Sélectionne `SYSTEM`, déclenchement quotidien à **07 h 30**, programme `powershell.exe` et arguments `-NoProfile -ExecutionPolicy RemoteSigned -File C:\Scripts\Inventaire-Disques.ps1`. Dans **Paramètres**, coche le rattrapage d’un démarrage manqué et fixe une limite de 30 minutes.

### B3 — Lancer et contrôler la tâche

Fais un clic droit sur la tâche → **Exécuter**. Actualise la console, lis le **dernier résultat**, puis ouvre `C:\Scripts\inventaire-disques.log`.

## Lire les traces

### C1 — Filtrer les événements du système

Ouvre `eventvwr.msc` → **Journaux Windows → Système → Filtrer le journal actuel**. Sélectionne **24 dernières heures**, **Critique** et **Erreur**. Relève la source et l’heure d’une entrée si la liste en contient.

### C2 — Lire le Moniteur de fiabilité

Ouvre `perfmon /rel` et sélectionne une journée où une erreur ou un avertissement apparaît. Relève l’application et l’heure.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/tp/guide-corrigev2)
