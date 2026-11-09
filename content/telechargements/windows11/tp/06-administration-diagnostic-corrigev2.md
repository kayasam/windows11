# TP 06. Processus, services, tâches planifiées et journaux — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h30

> Chapitres associés : [06. Processus, services, tâches planifiées et journaux](https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/)

---

## Objectifs

- Analyser les processus et les applications de démarrage
- Piloter un service (état, type de démarrage, dépendances)
- Créer, tester, exporter une tâche planifiée
- Rechercher efficacement dans les journaux d'événements
- Lire le Moniteur de fiabilité

---

## Prérequis

- `PC01` opérationnel, terminal **administrateur**

---

## Partie A — Processus et démarrage (15 min)

**A1.** Ouvre le Gestionnaire des tâches directement sur la page **Applications de démarrage**. Quelles applications se lancent à l'ouverture de session ? Quel est leur impact ?

> [!success]- Afficher la correction — A1
> `taskmgr /7 /startup` ouvre directement la page (ou `Ctrl+Maj+Échap` → icône **Applications de démarrage**).
>
> ![w11-06-gestionnaire-taches](https://cours.kaya.ovh/windows11/assets/captures/w11-06-gestionnaire-taches.png)
>
> Sur `PC01` : **Microsoft OneDrive** (Activé), **Microsoft Teams** (Désactivé), **Terminal** (Désactivé), **Windows Security notification** (Activé). L'impact est « Non mesuré » tant que le poste n'a pas redémarré plusieurs fois. En haut à droite : *Dernier temps de démarrage du BIOS : 0.9 secondes* (la VM démarre vite).

**A2.** En PowerShell, liste les 5 processus qui consomment le plus de mémoire, avec la mémoire en Mo.

> [!success]- Afficher la correction — A2
> ```powershell
> Get-Process | Sort-Object WorkingSet -Descending |
>     Select-Object -First 5 Name, Id, @{N="Mo";E={[math]::Round($_.WorkingSet/1MB,1)}}
> ```

**A3.** Lance le Bloc-notes, retrouve son PID en CMD, puis ferme-le de force en PowerShell.

> [!success]- Afficher la correction — A3
> ```cmd
> notepad
> tasklist /fi "imagename eq notepad.exe"
> ```
> ```powershell
> Stop-Process -Name notepad -Force      # ou Stop-Process -Id <PID> -Force
> ```

---

## Partie B — Services (20 min)

**B1.** Liste les services en démarrage **automatique** qui ne tournent pas. Est-ce forcément anormal ?

> [!success]- Afficher la correction — B1
> ```powershell
> Get-Service | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -ne "Running" } |
>     Select-Object Name, DisplayName, Status
> ```
> Pas forcément anormal : certains services démarrent puis **s'arrêtent d'eux-mêmes** quand ils n'ont plus rien à faire (`sppsvc`, `gupdate`, `edgeupdate`, `RemoteRegistry` sur déclencheur…). Un service critique (`Dnscache`, `EventLog`, `WinDefend`) arrêté, lui, est un vrai problème.

**B2.** Observe le service **Spouleur d'impression** : état, type de démarrage, services dont il dépend. Arrête-le, puis passe-le en **Désactivé**.

> [!success]- Afficher la correction — B2
> ```powershell
> Get-Service Spooler | Select-Object Name, Status, StartType, ServicesDependedOn, DependentServices
> Stop-Service Spooler
> Set-Service Spooler -StartupType Disabled
> ```
> Le spouleur dépend de **RPCSS** (Appel de procédure distante) et **http**. En `services.msc` : onglet **Dépendances**.

**B3.** Que se passe-t-il si un utilisateur essaie d'imprimer en PDF ? Remets le service en état normal.

> [!success]- Afficher la correction — B3
> Plus aucune imprimante n'apparaît, même « Microsoft Print to PDF » : les applications affichent « Aucune imprimante installée ». Remise en état :
> ```powershell
> Set-Service Spooler -StartupType Automatic
> Start-Service Spooler
> ```
> Désactiver le spouleur reste une mesure de sécurité légitime sur un **serveur** qui n'imprime pas (failles *PrintNightmare* de 2021).

**B4.** Quelle est la différence entre « Automatique » et « Automatique (début différé) » ?

> [!success]- Afficher la correction — B4
> « Automatique (début différé) » démarre le service ~2 minutes après les services automatiques, une fois la session ouverte : le poste est utilisable plus vite. On l'utilise pour ce qui n'est pas urgent au démarrage (Windows Update, agents d'inventaire…).

---

## Partie C — Planificateur de tâches (30 min)

Le Fournil veut un **relevé quotidien de l'espace disque** de chaque poste, pour anticiper les disques pleins.

**C1.** Crée le script `C:\Scripts\Inventaire-Disques.ps1`, qui ajoute une ligne par disque fixe dans `C:\Scripts\inventaire-disques.log` : date, lettre, espace libre en Go.

> [!success]- Afficher la correction — C1
> ```powershell
> New-Item C:\Scripts -ItemType Directory -Force
> @'
> Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
>     "{0} {1} {2:N1} Go libres" -f (Get-Date -Format s), $_.DeviceID, ($_.FreeSpace/1GB)
> } | Add-Content C:\Scripts\inventaire-disques.log
> '@ | Set-Content C:\Scripts\Inventaire-Disques.ps1
> ```
> `DriveType=3` = disques fixes (pas les DVD ni les lecteurs réseau).

**C2.** Crée la tâche `\Fournil\Inventaire-Disques` :
- tous les jours à 07:30,
- sous le compte **SYSTEM**,
- rattrapée si le PC était éteint,
- durée maximale de 30 minutes,
- indépendante de la stratégie d'exécution PowerShell du poste.

> [!success]- Afficher la correction — C2
> ```powershell
> $action    = New-ScheduledTaskAction -Execute "powershell.exe" `
>                 -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\Inventaire-Disques.ps1"
> $trigger   = New-ScheduledTaskTrigger -Daily -At 07:30
> $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
> $settings  = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
> Register-ScheduledTask -TaskName "Inventaire-Disques" -TaskPath "\Fournil\" `
>     -Action $action -Trigger $trigger -Principal $principal -Settings $settings
> ```
> ```
> TaskPath  TaskName           State
> --------  --------           -----
> \Fournil\ Inventaire-Disques Ready
> ```
> - **SYSTEM / ServiceAccount** : pas de mot de passe à gérer, tourne sans session.
> - **`-StartWhenAvailable`** : rattrapage si le PC était éteint.
> - **`-ExecutionPolicy Bypass`** dans l'argument : la tâche fonctionne même si le poste est en `Restricted` (défaut de Windows 11 client).

**C3.** Lance-la immédiatement et vérifie son résultat de trois façons.

> [!success]- Afficher la correction — C3
> ```powershell
> Start-ScheduledTask -TaskPath "\Fournil\" -TaskName "Inventaire-Disques"
> Get-ScheduledTaskInfo -TaskPath "\Fournil\" -TaskName "Inventaire-Disques" |
>     Select-Object LastRunTime, LastTaskResult, NextRunTime
> Get-Content C:\Scripts\inventaire-disques.log
> ```
> ```
> LastRunTime    : 08/11/2026 06:24:27
> LastTaskResult : 0
> NextRunTime    : 08/11/2026 07:30:00
>
> 2026-11-08T06:24:29 C: 36,4 Go libres
> 2026-11-08T06:24:29 F: 8,0 Go libres
> 2026-11-08T06:24:29 G: 10,0 Go libres
> ```
> Trois preuves : `LastTaskResult = 0`, le contenu du journal, et l'onglet **Historique** de `taskschd.msc` (après avoir activé *Activer l'historique de toutes les tâches*).

**C4.** Exporte-la en XML. À quoi ce fichier peut-il servir ?

> [!success]- Afficher la correction — C4
> ```powershell
> Export-ScheduledTask -TaskPath "\Fournil\" -TaskName "Inventaire-Disques" |
>     Set-Content C:\Scripts\Inventaire-Disques.xml
> ```
> Le XML décrit **toute** la tâche (déclencheurs, action, compte, paramètres). Il sert à : la documenter, la versionner, la réimporter sur d'autres postes (`Register-ScheduledTask -Xml`, `schtasks /create /xml`), ou la déployer par **GPO** (Préférences → Tâches planifiées, chapitre 11).

**C5.** Avec `schtasks`, affiche la tâche au format liste. Quelle option permettrait de la lancer sur `PC02` depuis `PC01` ?

> [!success]- Afficher la correction — C5
> ```cmd
> schtasks /query /tn "\Fournil\Inventaire-Disques" /fo LIST
> ```
> ```
> Dossier : \Fournil
> Nom de l'hôte:               PC01
> Nom de la tâche:             \Fournil\Inventaire-Disques
> Prochaine exécution:         08/11/2026 07:30:00
> Statut:                      Prêt
> Mode d'ouverture de session: Interactif /Arrière-plan
> ```
> À distance : `schtasks /run /tn "\Fournil\Inventaire-Disques" /s PC02` (pare-feu et droits admin requis — chapitre 12).

**C6.** Une autre tâche affiche `LastTaskResult = 2147942402`. Diagnostique.

> [!success]- Afficher la correction — C6
> En hexadécimal : `'{0:X}' -f 2147942402` → `80070002` = **ERROR_FILE_NOT_FOUND**. Le programme ou le script de l'action est introuvable : chemin erroné, dossier `C:\Scripts` absent sur ce poste, ou lecteur réseau non disponible pour SYSTEM. Vérifier l'onglet **Actions** de la tâche.

---

## Partie D — Journaux d'événements (20 min)

**D1.** Un collègue tape :
```powershell
Get-WinEvent -LogName System -FilterHashtable @{ Level = 2 }
```
Ça échoue. Pourquoi ? Corrige.

> [!success]- Afficher la correction — D1
> ```
> Le jeu de paramètres ne peut pas être résolu à l'aide des paramètres nommés spécifiés.
> ```
> `-LogName` et `-FilterHashtable` appartiennent à deux jeux de paramètres différents. Le journal se met **dans** la table :
> ```powershell
> Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 }
> ```

**D2.** Liste les 4 derniers démarrages/arrêts du poste (6005, 6006, 6008, 6013).

> [!success]- Afficher la correction — D2
> ```powershell
> Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 6005, 6006, 6008, 6013 } -MaxEvents 4 |
>     Select-Object TimeCreated, Id, Message
> ```
> ```
> 08/11/2026 05:51:34 6013 La durée active du système est de 9 secondes.
> 08/11/2026 05:51:34 6005 Le service d'Enregistrement d'événement a démarré.
> 08/11/2026 05:51:21 6006 Le service d'Enregistrement d'événement a été arrêté.
> 08/11/2026 05:50:14 6005 Le service d'Enregistrement d'événement a démarré.
> ```
> Un **6006** avant le 6005 = arrêt propre. Un **6008** à la place = arrêt inopiné (crash, coupure).

**D3.** Liste les erreurs et événements critiques du journal Système des dernières 24 heures. Quelle est la source la plus fréquente ?

> [!success]- Afficher la correction — D3
> ```powershell
> Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1,2; StartTime = (Get-Date).AddDays(-1) } |
>     Group-Object ProviderName | Sort-Object Count -Descending | Select-Object Count, Name
> ```
> Sur `PC01` : surtout **Microsoft-Windows-DistributedCOM** (10001, bruit classique au premier démarrage) et un **WindowsUpdateClient** ID 20 (échec d'installation d'une mise à jour, chapitre 08).

**D4.** Pourquoi `Get-WinEvent -FilterHashtable` est-il préférable à `Get-WinEvent -LogName System | Where-Object Level -eq 2` ?

> [!success]- Afficher la correction — D4
> Avec `Where-Object`, PowerShell lit **tous** les événements du journal (des dizaines de milliers) puis les filtre en mémoire. Avec `-FilterHashtable`, le **service de journalisation** ne renvoie que les événements correspondants : jusqu'à 100 fois plus rapide, surtout à distance (`-ComputerName`).

**D5.** Crée une **vue personnalisée** dans l'Observateur d'événements : « Fournil — Erreurs 24h » (Critique + Erreur, journaux Système et Application, dernières 24 heures).

> [!success]- Afficher la correction — D5
> `eventvwr.msc` → clic droit sur **Affichages personnalisés** → **Créer une vue personnalisée** : Connecté *Dernières 24 heures*, Niveau *Critique* + *Erreur*, Par journal *Système* + *Application* → nommer « Fournil — Erreurs 24h ». La vue est enregistrée et réutilisable ; clic droit → **Exporter la vue personnalisée** pour la partager.

---

## Partie E — Fiabilité (5 min)

**E1.** Ouvre le Moniteur de fiabilité. Quel est l'indice de stabilité de `PC01` ? Quel avertissement apparaît, et que signifie-t-il ?

> [!success]- Afficher la correction — E1
> `perfmon /rel` :
>
> ![w11-06-moniteur-fiabilite](https://cours.kaya.ovh/windows11/assets/captures/w11-06-moniteur-fiabilite.png)
>
> Indice de stabilité **10** (poste tout neuf). Un avertissement « **Windows Update a échoué** » pour une application Store (`9MSSGKG348SP…`) le 08/11. Un échec isolé de mise à jour d'application n'est pas grave (elle sera retentée) ; une série d'échecs ou des **échecs d'applications** quotidiens feraient baisser l'indice et justifieraient une enquête (chapitre 19).

---

## Partie F — Bonus

**F1.** Crée une tâche planifiée déclenchée par un **événement** : à chaque échec d'ouverture de session (ID 4625 du journal Sécurité), ajouter une ligne dans `C:\Scripts\echecs.log`.

> [!success]- Afficher la correction — F1
> Les cmdlets `New-ScheduledTaskTrigger` ne gèrent pas les déclencheurs sur événement : on passe par `schtasks` (ou la console, **Créer une tâche → Déclencheurs → Sur un événement**).
> ```powershell
> 'Add-Content C:\Scripts\echecs.log "$(Get-Date -Format s) echec ouverture de session"' |
>     Set-Content C:\Scripts\Alerte-4625.ps1
> ```
> ```cmd
> schtasks /create /tn "\Fournil\Alerte-4625" /ru SYSTEM /sc ONEVENT /ec Security ^
>   /mo "*[System[(EventID=4625)]]" ^
>   /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\Alerte-4625.ps1"
> ```
> Test : provoquer un échec d'authentification, par exemple `net use \\127.0.0.1\c$ /user:PC01\admin MauvaisMdp`.
> ```
> 2026-11-08T06:28:14 echec ouverture de session
> ```
>
> > [!WARNING] Testé sur le lab : éviter `-Command` avec des guillemets dans `/tr`
> > Une première version avec `/tr "powershell.exe -Command Add-Content ... ((Get-Date)+' texte')"` se déclenchait bien sur l'événement, mais finissait en `LastTaskResult = 1` : les guillemets imbriqués sont mangés par l'analyse de la ligne de commande. Appeler un **fichier `.ps1`** avec `-File` règle le problème — c'est la règle à retenir pour toute tâche planifiée.
>
> C'est le principe des alertes de sécurité légères, avant d'avoir un SIEM.

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/tp)
