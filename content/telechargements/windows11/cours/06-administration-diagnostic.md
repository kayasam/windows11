# 06. Processus, services, tâches planifiées et journaux

> [!NOTE] Objectif
> Maîtriser les outils de surveillance et d'administration intégrés à Windows 11 : analyser les performances, gérer les services et processus, **automatiser avec le Planificateur de tâches**, lire les journaux d'événements.
>
> **Outils :** Gestionnaire des tâches, Gestionnaire de l'ordinateur, Planificateur de tâches, Observateur d'événements, Moniteur de fiabilité, Moniteur de ressources, Moniteur de performances
> **Commandes à connaître :** `Get-Process`, `Get-Service`, `Register-ScheduledTask`, `schtasks`, `Get-WinEvent`, `tasklist`, `sc`

> [!INFO] Fil rouge — Fournil
> Sur `PC01`, on crée la tâche planifiée `\Fournil\Inventaire-Disques`, qui consigne chaque matin l'espace libre des disques.

---

## Gestionnaire des tâches

![w11-05-administration-diagnostic](https://cours.kaya.ovh/windows11/assets/captures/w11-05-administration-diagnostic.png)

Le **Gestionnaire des tâches** (`taskmgr`) est l'outil de surveillance en temps réel de Windows. Il a été entièrement revu dans Windows 11.

**Accès :**
- `Ctrl + Shift + Échap` (raccourci direct)
- `Ctrl + Alt + Suppr` → Gestionnaire des tâches
- Clic droit sur la barre des tâches → Gestionnaire des tâches
- Recherche Windows : `taskmgr`

### Onglets principaux

#### Processus

Vue unifiée des applications, processus d'arrière-plan et processus Windows. Colonnes disponibles :

| Colonne | Description |
|---------|-------------|
| **CPU** | % de temps processeur utilisé |
| **Mémoire** | RAM consommée (ensemble de travail) |
| **Disque** | Débit I/O en Mo/s |
| **Réseau** | Bande passante utilisée en Mbit/s |
| **GPU** | % d'utilisation du GPU |

Clic droit sur un processus → **Terminer la tâche** (force la fermeture), **Ouvrir l'emplacement du fichier**, **Propriétés**, **Analyser la chaîne d'attente**.

> [!WARNING] Terminer un processus système
> Tuer certains processus système (`svchost.exe`, `lsass.exe`, `csrss.exe`) peut provoquer un crash immédiat ou un redémarrage forcé. Toujours identifier un processus avant de le terminer.

#### Performances

Graphiques temps réel pour CPU, Mémoire, Disque, Réseau, GPU. Cliquer sur chaque composant pour les détails.

```
CPU       → fréquence, cœurs logiques, virtualisation, cache L1/L2/L3
Mémoire   → utilisée, disponible, en cache, type (DDR4/5), vitesse, slots
Disque    → débit lecture/écriture, temps d'accès, % d'utilisation
Réseau    → débit envoi/réception, nom de l'adaptateur
GPU       → % moteur, mémoire dédiée/partagée
```

Lien **"Ouvrir le Moniteur de ressources"** en bas pour aller plus loin.

#### Démarrage (Applications de démarrage)

Liste toutes les applications qui se lancent au démarrage de Windows avec leur **impact** (Aucun / Faible / Moyen / Élevé).

- Clic droit → **Désactiver** pour empêcher une app de démarrer automatiquement
- Ne supprime pas l'application, juste son lancement automatique

> [!TIP] Optimisation du démarrage
> Un impact "Élevé" signifie que l'application ralentit le démarrage. Désactiver les apps non essentielles (OneDrive, Teams, Spotify...) peut réduire significativement le temps de démarrage.

#### Services

Vue simplifiée des services Windows. Pour la gestion complète, utiliser `services.msc`.

#### En ligne de commande

```powershell
# Lister les processus
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# Processus par consommation mémoire
Get-Process | Sort-Object WorkingSet -Descending | Select-Object Name, @{N="Mo";E={[math]::Round($_.WorkingSet/1MB,1)}} | Select-Object -First 10

# Terminer un processus par nom
Stop-Process -Name "notepad" -Force

# Terminer par PID
Stop-Process -Id 1234 -Force
```

```cmd
tasklist                          ← liste tous les processus
tasklist /fi "imagename eq chrome.exe"
taskkill /im notepad.exe /f       ← forcer la fermeture
taskkill /pid 1234 /f
```

---

## Gestionnaire de l'ordinateur

`compmgmt.msc` — console MMC centralisée regroupant plusieurs outils d'administration.

**Accès :** Clic droit sur le menu Démarrer → **Gestion de l'ordinateur**

![Gestion de l’ordinateur — La console regroupe les outils système, le stockage, et les services et applications.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-06-gestion-ordinateur.svg)

### Services — services.msc

Un **service** est un processus en arrière-plan qui démarre avec Windows, sans session utilisateur.

| Type de démarrage | Comportement |
|-------------------|-------------|
| **Automatique** | Démarre au démarrage de Windows |
| **Automatique (début différé)** | Démarre après les services critiques (réduit l'impact au boot) |
| **Manuel** | Démarre uniquement à la demande |
| **Désactivé** | Ne peut pas démarrer |

```powershell
# Lister tous les services
Get-Service

# Filtrer par état
Get-Service | Where-Object Status -eq "Running"
Get-Service | Where-Object Status -eq "Stopped"

# Démarrer / arrêter / redémarrer un service
Start-Service -Name "spooler"
Stop-Service -Name "spooler"
Restart-Service -Name "spooler"

# Changer le type de démarrage
Set-Service -Name "spooler" -StartupType Automatic
Set-Service -Name "spooler" -StartupType Disabled
```

```cmd
sc query                           ← lister les services
sc query spooler                   ← état du service Spooler
sc start spooler
sc stop spooler
sc config spooler start= disabled  ← (espace après = obligatoire)
```

---

## Observateur d'événements
![w11-05-administration-diagnostic-3](https://cours.kaya.ovh/windows11/assets/captures/w11-05-administration-diagnostic-3.png)
`eventvwr.msc` — centralise tous les journaux système, applicatifs et de sécurité.

**Accès :** Recherche Windows → "Observateur d'événements" ou `eventvwr.msc`

### Structure des journaux

![Journaux de l’Observateur d’événements — Les journaux Windows couvrent les applications, la sécurité, le système et l’installation. Les autres journaux sont classés par composant.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-06-journaux-evenements.svg)

### Niveaux de sévérité

| Niveau | Icône | Description |
|--------|-------|-------------|
| **Informations** | ℹ️ | Opération normale |
| **Avertissement** | ⚠️ | Problème potentiel, système toujours fonctionnel |
| **Erreur** | ❌ | Défaillance d'une fonctionnalité |
| **Critique** | 🔴 | Défaillance grave ayant causé un arrêt |
| **Succès de l'audit** | ✅ | Opération auditée réussie (journal Sécurité) |
| **Échec de l'audit** | 🔒 | Opération auditée refusée (journal Sécurité) |

### Filtrer les événements

Dans l'Observateur d'événements, **clic droit sur un journal** → **Filtrer le journal actuel** :
- Niveau (Critique, Erreur, Avertissement...)
- ID d'événement (ex : 4625 = échec de connexion, 7036 = changement d'état service)
- Source (nom du composant qui a généré l'événement)
- Plage de dates

### IDs d'événements courants

| Journal | ID | Signification |
|---------|----|--------------|
| Sécurité | **4624** | Ouverture de session réussie |
| Sécurité | **4625** | Échec d'ouverture de session |
| Sécurité | **4648** | Ouverture de session avec credentials explicites |
| Système | **6005** | Démarrage du journal (= démarrage Windows) |
| Système | **6006** | Arrêt propre du journal (= arrêt Windows) |
| Système | **6008** | Arrêt inopiné (crash, coupure de courant) |
| Système | **7036** | Changement d'état d'un service |
| Application | **1000** | Crash d'une application |

### En PowerShell

```powershell
# Lire les 20 derniers événements du journal Système
Get-WinEvent -LogName System -MaxEvents 20

# Filtrer par niveau (2=Erreur, 3=Avertissement, 1=Critique)
Get-WinEvent -LogName System | Where-Object Level -eq 2 | Select-Object -First 10

# Filtrer par ID d'événement
Get-WinEvent -LogName Security | Where-Object Id -eq 4625 | Select-Object -First 5

# Filtrer côté journal (BEAUCOUP plus rapide que Where-Object) : erreurs des dernières 24 h
Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    StartTime = (Get-Date).AddHours(-24)
    Level     = 2
}

# Démarrages / arrêts / crashs
Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 6005, 6006, 6008, 6013 } -MaxEvents 10

# Rechercher dans tous les journaux
Get-WinEvent -ListLog * | Where-Object RecordCount -gt 0 | Select-Object LogName, RecordCount
```

> [!WARNING] `-LogName` et `-FilterHashtable` ne se combinent pas
> Le nom du journal se met **dans** la table de hachage. `Get-WinEvent -LogName System -FilterHashtable @{...}` échoue avec « *Le jeu de paramètres ne peut pas être résolu à l'aide des paramètres nommés spécifiés* » (erreur présente dans la v1 de ce cours, corrigée).

> [!NOTE] `Get-EventLog` : à oublier
> `Get-EventLog` existe encore dans Windows PowerShell 5.1, mais **pas dans PowerShell 7**, et il ne lit que les journaux « classiques ». `Get-WinEvent` lit tous les journaux (y compris *Applications et services*) et filtre côté système.

### Moniteur de fiabilité

`perfmon /rel` (ou recherche « Afficher l'historique de fiabilité ») : une frise chronologique, jour par jour, des **plantages d'applications, échecs de mises à jour et erreurs Windows**, avec un indice de stabilité de 1 à 10. C'est la première chose à ouvrir face à « *mon PC plante depuis quelque temps* ».

```powershell
Get-CimInstance Win32_ReliabilityStabilityMetrics | Select-Object -First 1 SystemStabilityIndex, TimeGenerated
```

---

## Planificateur de tâches

Le **Planificateur de tâches** (`taskschd.msc`) exécute un programme ou un script selon un **déclencheur** : heure, démarrage, ouverture de session, inactivité, **événement** du journal…

![Anatomie d’une tâche planifiée — Une tâche combine le moment du déclenchement, l’action à exécuter, l’identité et les conditions d’exécution.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-06-tache-planifiee.svg)

Windows en contient déjà plus de 250 (`(Get-ScheduledTask).Count` → 254 sur `PC01`) : défragmentation, mises à jour, télémétrie… On range les siennes dans un **dossier dédié** (`\Fournil\`).

### Créer une tâche en PowerShell

```powershell
$action    = New-ScheduledTaskAction -Execute "powershell.exe" `
                -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\Inventaire-Disques.ps1"
$trigger   = New-ScheduledTaskTrigger -Daily -At 07:30
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

Register-ScheduledTask -TaskName "Inventaire-Disques" -TaskPath "\Fournil\" `
    -Action $action -Trigger $trigger -Principal $principal -Settings $settings

Start-ScheduledTask -TaskPath "\Fournil\" -TaskName "Inventaire-Disques"    # test immédiat
Get-ScheduledTaskInfo -TaskPath "\Fournil\" -TaskName "Inventaire-Disques"  # LastTaskResult = 0 → OK
```

| Option | Pourquoi |
|--------|----------|
| `-ExecutionPolicy Bypass` dans l'argument | La tâche ne dépend pas de la stratégie d'exécution du poste (chap. 07) |
| `SYSTEM` + `ServiceAccount` | Tourne sans session ouverte, sans mot de passe à stocker |
| `-StartWhenAvailable` | Si le PC était éteint à 07:30, la tâche s'exécute au démarrage suivant |
| `-ExecutionTimeLimit` | Un script bloqué ne tourne pas indéfiniment |

### Exporter, importer, piloter à distance

```powershell
# Exporter en XML (sauvegarde, documentation, déploiement)
Export-ScheduledTask -TaskPath "\Fournil\" -TaskName "Inventaire-Disques" | Set-Content C:\Scripts\Inventaire-Disques.xml

# Importer sur un autre poste
Register-ScheduledTask -TaskName "Inventaire-Disques" -TaskPath "\Fournil\" -Xml (Get-Content C:\Scripts\Inventaire-Disques.xml -Raw)
```

```cmd
:: L'outil historique, toujours utile (et capable d'agir à distance avec /s)
schtasks /query /tn "\Fournil\Inventaire-Disques" /fo LIST
schtasks /run   /tn "\Fournil\Inventaire-Disques" /s PC02
schtasks /create /xml C:\Scripts\Inventaire-Disques.xml /tn "\Fournil\Inventaire-Disques" /s PC02
```

> [!TIP] Codes de résultat
> `LastTaskResult` : `0` = succès ; `267009` (0x41301) = en cours ; `267011` (0x41303) = jamais exécutée ; `2147942402` (0x80070002) = fichier introuvable (chemin du script faux). Le journal *Microsoft-Windows-TaskScheduler/Operational* (désactivé par défaut, « Activer l'historique de toutes les tâches ») détaille chaque exécution.

---

## Moniteur de ressources et Moniteur de performances

> [!NOTE] En pratique
> Ces deux outils sont **rarement utilisés** au quotidien par les administrateurs. Le Gestionnaire des tâches et l'Observateur d'événements couvrent 95% des besoins. Le Moniteur de ressources sort occasionnellement pour une investigation très ciblée (identifier un processus qui verrouille un fichier, tracer une connexion réseau suspecte). Le Moniteur de performances (`perfmon`) est surtout utilisé sur **Windows Server** dans des contextes de troubleshooting avancé (SQL Server, IIS, analyses de capacité). Il est utile de savoir qu'ils existent et à quoi ils servent.

### Moniteur de ressources — `resmon.exe`

Vue temps réel décomposée par processus : quel processus accède à quel fichier, quelle connexion TCP est ouverte, quelle page mémoire est utilisée.

**Cas d'usage réel :** identifier quel processus verrouille un fichier qu'on ne peut pas supprimer → onglet **Disque** → section **Fichiers associés**.

### Moniteur de performances — `perfmon.exe`

Enregistre des **compteurs** (CPU, RAM, disque, réseau) sur la durée et génère des rapports. Utile pour prouver un problème de performance à un responsable ou un éditeur logiciel.

Compteurs utiles à connaître :
- `\Memory\Available MBytes` — RAM disponible (alerte si < 200 Mo)
- `\Memory\Pages/sec` — pagination intensive (alerte si > 20 en continu)
- `\PhysicalDisk(_Total)\Avg. Disk Queue Length` — file d'attente I/O (alerte si > 2)

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> **Outils du quotidien (à maîtriser)**
> - `taskmgr` : processus, performances, démarrage, services
> - `services.msc` : gérer les services (`Get-Service`, sc)
> - `eventvwr.msc` : journaux Application/Sécurité/Système (`Get-WinEvent -FilterHashtable`)
>   - **IDs clés** : 4624/4625 (connexions), 6005/6008 (boot/crash), 1000 (crash app)
>   - `Get-EventLog` : PS 5.1 seulement → `Get-WinEvent`
> - `perfmon /rel` : moniteur de fiabilité (indice 1-10, frise des incidents)
> - `taskschd.msc` → `Register-ScheduledTask` (Action + Trigger + Principal + Settings)
>   - `Export-ScheduledTask` / `schtasks /s` (à distance) · LastTaskResult 0 = OK
>
> **Outils avancés (savoir qu'ils existent)**
> - `resmon` : détail par processus et par fichier/connexion
> - `perfmon` : compteurs sur la durée, surtout utile sur Windows Server
