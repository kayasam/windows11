# TP 08 — Windows Update et gestion des mises à jour — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h15

> Chapitres associés : [08. Windows Update et gestion des mises à jour](https://kayasam.github.io/windows11/windows11/08-mises-a-jour/)

---

## Objectifs

- Faire l'état des lieux des mises à jour d'un poste (installées, en attente, échouées)
- Piloter Windows Update en ligne de commande, sans `usoclient`
- Configurer par stratégie locale un anneau « large » (report, échéance, version cible)
- Mettre à jour les applications, pas seulement Windows

---

## Prérequis

- `PC01` avec accès Internet, terminal **administrateur**
- Stratégie d'exécution `RemoteSigned` (TP 07)

---

## Partie A — État des lieux (15 min)

**A1.** Liste les 4 derniers correctifs installés. De quand datent-ils ? Qu'en déduis-tu sur l'ISO utilisée ?

> [!success]- Afficher la correction — A1
> ```powershell
> Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 4 HotFixID, Description, InstalledOn
> ```
> ```
> HotFixID  Description     InstalledOn
> --------  -----------     -----------
> KB5129195 Security Update 13/09/2026
> KB5124007 Security Update 13/09/2026
> KB5126052 Update          13/09/2026
> KB5121794 Update          13/09/2026
> ```
> Tous datent du **13/09/2026** alors que le poste a été installé le 08/11 : ce sont les correctifs **intégrés à l'ISO** (« slipstream ») au moment de sa fabrication. L'ISO a donc près de deux mois de retard : un poste fraîchement installé n'est **jamais** à jour. D'où les mises à jour dans le master (chapitre 14) ou l'injection hors ligne (chapitre 15).

**A2.** Ouvre **Paramètres → Windows Update → Historique des mises à jour**. Retrouve-y la même information. Y a-t-il des échecs ?

> [!success]- Afficher la correction — A2
> **Paramètres → Windows Update → Historique des mises à jour** : catégories Qualité, Pilotes, Définitions, Autres. Sur `PC01`, une mise à jour de **pilote** (« Microsoft Corporation AudioProcessingObject Driver Update ») installée au premier démarrage.
> L'historique complet (avec codes de résultat) est aussi lisible par l'API COM :
> ```powershell
> $s = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()
> $s.QueryHistory(0, $s.GetTotalHistoryCount()) | Select-Object Date, ResultCode, Title
> ```
> `ResultCode` : 2 = réussi, 4 = échec, 5 = annulé.

**A3.** Où d'autre peut-on voir rapidement un échec de mise à jour (indice : chapitre 06) ?

> [!success]- Afficher la correction — A3
> Le **Moniteur de fiabilité** (`perfmon /rel`) : sur `PC01`, un avertissement « *Windows Update a échoué* » pour une application Store le 08/11. Et le journal Système, source **WindowsUpdateClient**, ID **20** (échec d'installation) :
> ```powershell
> Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WindowsUpdateClient'; Id=20} -MaxEvents 5
> ```

---

## Partie B — Windows Update en ligne de commande (20 min)

**B1.** Pourquoi ne faut-il plus compter sur `usoclient StartScan` ?

> [!success]- Afficher la correction — B1
> `usoclient.exe` n'a jamais été documenté et il est explicitement **déprécié** : sur les builds récentes, il peut ne rien déclencher du tout. On ne bâtit pas une procédure dessus.

**B2.** Avec l'API COM `Microsoft.Update.Session`, liste les mises à jour **non installées**. Combien y en a-t-il ? De quels types ?

> [!success]- Afficher la correction — B2
> ```powershell
> $session  = New-Object -ComObject Microsoft.Update.Session
> $searcher = $session.CreateUpdateSearcher()
> $result   = $searcher.Search("IsInstalled=0 and IsHidden=0")
> $result.Updates | Select-Object Title, IsDownloaded
> ```
> **6 mises à jour** sur `PC01` :
> ```
> Outil de suppression de logiciels malveillants Windows x64 - v5.146 (KB890830)
> Mise à jour pour Windows Security platform - KB5007651
> Mise à jour de la sélection disjointe pour Microsoft Defender Antivirus – KB2267602 (version 1.463.186.0)
> 2026-10 .NET Framework Correctif de sécurité (KB5127694)
> 2026-10 Correctif de sécurité (KB5127648) (26300.9711)
> Microsoft Corporation AudioProcessingObject Driver Update (1.0.4.55794)
> ```
> Mélange de types : **cumulative** Windows (KB5127648 → fera passer la build de .9457 à .9711), .NET, Defender (plateforme + définitions), MSRT, pilote.

**B3.** Installe le module `PSWindowsUpdate` et liste les mêmes mises à jour. Un collègue écrit `Get-WindowsUpdate | Select-Object KB, Title` et obtient un tableau vide. Pourquoi ?

> [!success]- Afficher la correction — B3
> ```powershell
> Install-Module PSWindowsUpdate -Force
> Get-WindowsUpdate
> ```
> ```
> Found [6] Updates in pre search criteria
> KB890830   Outil de suppression de logiciels malveillants Windows x64 - v5.146
> KB5007651  Mise à jour pour Windows Security platform
> KB2267602  Mise à jour de la sélection disjointe pour Microsoft Defender Antivirus
> KB5127694  2026-10 .NET Framework Correctif de sécurité
> KB5127648  2026-10 Correctif de sécurité (26300.9711)
>            Microsoft Corporation AudioProcessingObject Driver Update
> ```
> Constaté sur le lab : `Get-WindowsUpdate` renvoie **une collection** (un seul objet qui en contient six). `Select-Object` s'applique à cette collection et produit une ligne vide. Il faut la « déplier » :
> ```powershell
> Get-WindowsUpdate | ForEach-Object { $_ } | Select-Object KB, Title
> ```
> (C'est aussi pourquoi le module PowerShell n'est pas Microsoft : il a ses particularités.)

**B4.** Installe toutes les mises à jour, sans redémarrer automatiquement. Comment savoir ensuite si un redémarrage est en attente ?

> [!success]- Afficher la correction — B4
> ```powershell
> Install-WindowsUpdate -AcceptAll -IgnoreReboot
> Get-WURebootStatus                       # True si un redémarrage est en attente
> Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
> ```
> À distance, l'agent Windows Update refuse de télécharger/installer dans une session WinRM : on passe par `Invoke-WUJob -ComputerName PC02 -Script {…}`, qui crée une tâche planifiée locale sur la cible.

---

## Partie C — Stratégie locale : anneau « large » (25 min)

Le Fournil veut que les postes de production reçoivent les correctifs **7 jours** après leur publication, restent en **25H2/26H2** tant que la DSI n'a pas validé la version suivante, et redémarrent au plus tard **3 jours** après l'installation.

**C1.** Dans `gpedit.msc`, retrouve le nœud Windows Update. Combien de sous-dossiers contient-il ? Lequel ne faut-il **surtout pas** remplir sans serveur WSUS ?

> [!success]- Afficher la correction — C1
> `gpedit.msc` → *Configuration ordinateur → Modèles d'administration → Composants Windows → Windows Update* : **quatre** sous-dossiers en 26H2 :
> - Gérer l'expérience utilisateur final
> - Gérer les mises à jour proposées de Windows Server Update Service ← **à ne pas toucher sans WSUS** : « Spécifier l'emplacement intranet du service de mise à jour Microsoft » pointé vers un serveur inexistant bloque toute mise à jour
> - Gérer les mises à jour proposées de Windows Update
> - Stratégies héritées

**C2.** Configure : report qualité 7 jours, version cible `Windows 11` / `26H2`, échéance qualité 3 jours.

> [!success]- Afficher la correction — C2
> Dans **Gérer les mises à jour proposées de Windows Update** :
> - *Choisir quand recevoir les mises à jour qualité* → **Activé**, 7 jours
> - *Sélectionner la version de la mise à jour des fonctionnalités cible* → **Activé**, produit `Windows 11`, version `26H2`
>
> Dans **Gérer l'expérience utilisateur final** :
> - *Specify deadline for automatic updates and restarts for quality update* → **Activé**, échéance 3 jours, période de grâce 1 jour
>
> Puis `gpupdate /force`.

**C3.** Vérifie dans le registre et dans les Paramètres que la stratégie est bien appliquée.

> [!success]- Afficher la correction — C3
> ```powershell
> Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" |
>     Select-Object DeferQualityUpdates, DeferQualityUpdatesPeriodInDays, TargetReleaseVersion, ProductVersion, TargetReleaseVersionInfo, ConfigureDeadlineForQualityUpdates
> ```
> Valeurs attendues : `DeferQualityUpdatesPeriodInDays = 7`, `ProductVersion = Windows 11`, `TargetReleaseVersionInfo = 26H2`, `ConfigureDeadlineForQualityUpdates = 3`.
> Côté utilisateur : **Paramètres → Windows Update → Options avancées → Stratégies de mise à jour configurées** liste les stratégies, en lecture seule ; un bandeau « *Certains paramètres sont gérés par votre organisation* » apparaît.

**C4.** Que devra faire la DSI le jour où la version 27H2 sera validée ?

> [!success]- Afficher la correction — C4
> Modifier la stratégie **version cible** (`27H2`) — d'abord dans la GPO de l'anneau pilote, puis, après validation, dans celle de l'anneau large. Sans cette modification, les postes restent sur 26H2 (tant qu'elle est supportée : 24 mois pour Pro).

---

## Partie D — Applications et pilotes (10 min)

**D1.** Windows Update ne propose plus rien. Le poste est-il à jour ? Vérifie avec WinGet.

> [!success]- Afficher la correction — D1
> Non. Windows Update ne couvre que Windows (et Office/Edge si coché).
> ```powershell
> winget upgrade
> ```
> Sur `PC01` : **8 mises à jour** d'applications (WebView2, OneDrive, Teams, App Installer, Outlook, Terminal…). `winget upgrade --all --silent` (chapitre 05).

**D2.** Un pilote proposé par Windows Update fait planter les postes. Quelle stratégie empêche Windows Update de distribuer les pilotes ?

> [!success]- Afficher la correction — D2
> *Gérer les mises à jour proposées de Windows Update → **Ne pas inclure les pilotes avec les mises à jour Windows*** → Activé (valeur `ExcludeWUDriversInQualityUpdate = 1`). Les pilotes sont alors gérés par l'outil du constructeur ou par Intune/Autopatch, de façon contrôlée.

---

## Partie E — Bonus

**E1.** Explique en quelques lignes à un responsable pourquoi le Fournil ne montera **pas** de serveur WSUS en 2026, et ce qu'il fera à la place.

> [!success]- Afficher la correction — E1
> - **WSUS est déprécié** depuis septembre 2024 : il fonctionne encore dans Windows Server 2025, mais ne recevra plus aucune évolution. Investir dedans en 2026, c'est construire sur une technologie en fin de vie.
> - Il demande un serveur, du stockage (des centaines de Go), de la maintenance (nettoyage, base WID) et un administrateur qui approuve chaque mise à jour.
> - À la place : les **stratégies Windows Update client** par GPO (gratuites, déjà dans le domaine), en **anneaux** (pilote / large / critique), avec des échéances. Les postes téléchargent chez Microsoft, avec l'**Optimisation de la distribution** (partage entre postes du réseau local) pour économiser la bande passante.
> - Si le Fournil passe à Microsoft 365 Business Premium : **Intune + Autopatch** prendront le relais (Windows, Office, Edge, Teams, pilotes).

---

[Retour à l'énoncé](https://kayasam.github.io/windows11/windows11/08-mises-a-jour/tp)
