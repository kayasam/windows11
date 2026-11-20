---
title: "TP 08. Windows Update et gestion des mises à jour — Correction"
aliases: ["windows11/08-mises-a-jour/tp-corrigev2"]
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/08-mises-a-jour"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/08-mises-a-jour-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/standard">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/standard-corrigev2" aria-current="page">Corrigé</a></nav>

> [!abstract] Parcours TSSR
> Lancer les recherches de mises à jour au début du TP, puis travailler sur la stratégie pendant leur exécution. Lire et adapter le bloc API COM du cours ; ne pas attendre un téléchargement ou un redémarrage pour poursuivre. PSWindowsUpdate est (bonus).

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Chapitres associés : [08. Windows Update et gestion des mises à jour](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/)

---

## Objectifs

- Faire l'état des lieux des mises à jour d'un poste (installées, en attente, échouées)
- Piloter Windows Update en ligne de commande, sans `usoclient`
- Configurer par stratégie locale un anneau « large » (report, échéance, version cible)
- Mettre à jour les applications, pas seulement Windows

---

## Prérequis

- `PC01` avec accès Internet, terminal **administrateur**
- (bonus) Pour le module PSWindowsUpdate, vérifier la politique d’exécution et suivre les consignes de chargement du module ; le script du TP 07 n’est pas un prérequis.

---

## Partie A — État des lieux

**A1.** Liste les 4 derniers correctifs installés. De quand datent-ils ? Qu'en déduis-tu sur l'ISO utilisée ?

> [!success]- Afficher la correction — A1
> ```powershell
> Get-HotFix | Where-Object InstalledOn | Sort-Object InstalledOn -Descending |
>     Select-Object -First 4 HotFixID, Description, InstalledOn
> ```
> > [!WARNING] Pourquoi `Where-Object InstalledOn` ?
> > Testé sur le lab : sans ce filtre, la commande affiche l'erreur *« Exception lors de l'obtention de InstalledOn… La chaîne n'a pas été reconnue en tant que DateTime valide »*. Une mise à jour **en attente de redémarrage** (ici le correctif .NET KB5127694) a une date d'installation vide, que PowerShell ne sait pas trier. Le filtre écarte ces lignes.
>
> ```
> HotFixID  Description     InstalledOn
> --------  -----------     -----------
> KB5129195 Security Update 13/09/2026
> KB5124007 Security Update 13/09/2026
> KB5126052 Update          13/09/2026
> KB5121794 Update          13/09/2026
> ```
> Juste après l'installation, tous datent du **13/09/2026** alors que le poste a été installé en novembre : ce sont les correctifs **intégrés à l'ISO** (« slipstream ») au moment de sa fabrication.
>
> > [!NOTE] Ton résultat sera peut-être différent
> > `PC01` a accès à Internet depuis le TP 03 : Windows Update travaille **en arrière-plan** et peut avoir déjà installé la cumulative du mois. Sur le lab, le 16/11, on voyait `KB5132061` et `KB5132688` datés du 12/11 (jour de l'installation), la cumulative attendant un **redémarrage** (build 26300.9457 → 26300.9974 après redémarrage). C'est normal : le raisonnement reste le même. L'ISO a donc près de deux mois de retard : un poste fraîchement installé n'est **jamais** à jour. D'où les mises à jour dans le master (chapitre 13) ou l'injection hors ligne (chapitre 14).

**A2.** Ouvre **Paramètres → Windows Update → Historique des mises à jour**. Retrouve-y la même information. Y a-t-il des échecs ?

> [!success]- Afficher la correction — A2
> **Paramètres → Windows Update → Historique des mises à jour** : catégories Qualité, Pilotes, Définitions, Autres. Sur `PC01`, une mise à jour de **pilote** (« Microsoft Corporation AudioProcessingObject Driver Update ») installée au premier démarrage, puis les correctifs du mois.
>
> ![w11-08-parametres-historique](https://cours.kaya.ovh/windows11/assets/captures/w11-08-parametres-historique.png)
>
> L'historique complet (avec codes de résultat) est aussi lisible par l'API COM :
> ```powershell
> $s = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()
> $s.QueryHistory(0, $s.GetTotalHistoryCount()) | Select-Object Date, ResultCode, Title
> ```
> `ResultCode` : 1 = en cours (souvent : **redémarrage en attente**), 2 = réussi, 4 = échec, 5 = annulé.

**A3.** Où d'autre peut-on voir rapidement un échec de mise à jour (indice : chapitre 06) ?

> [!success]- Afficher la correction — A3
> Le **Moniteur de fiabilité** (`perfmon /rel`) : sur `PC01`, un avertissement « *Windows Update a échoué* » pour une application Store le 08/11. Et le journal Système, source **WindowsUpdateClient**, ID **20** (échec d'installation) :
> ```powershell
> Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WindowsUpdateClient'; Id=20} -MaxEvents 5
> ```

---

## Partie B — Windows Update en ligne de commande

**B1.** Pourquoi ne faut-il plus compter sur `usoclient StartScan` ?

> [!success]- Afficher la correction — B1
> `usoclient.exe` n'a jamais été documenté et il est explicitement **déprécié** : sur les builds récentes, il peut ne rien déclencher du tout. On ne bâtit pas une procédure dessus.

**B2.** (bonus) Avec l'API COM `Microsoft.Update.Session`, liste les mises à jour **non installées**. Combien y en a-t-il ? De quels types ?

> [!success]- Afficher la correction — B2
> ```powershell
> $session  = New-Object -ComObject Microsoft.Update.Session
> $searcher = $session.CreateUpdateSearcher()
> $result   = $searcher.Search("IsInstalled=0 and IsHidden=0")
> $result.Updates | Select-Object Title, IsDownloaded
> ```
> Le nombre dépend de ce que Windows Update a déjà fait en arrière-plan : **6 mises à jour** sur un `PC01` jamais mis à jour, **3** sur le lab le 16/11 (.NET, pilote audio, cumulative déjà téléchargée en attente de redémarrage). Exemple complet :
> ```
> Outil de suppression de logiciels malveillants Windows x64 - v5.146 (KB890830)
> Mise à jour pour Windows Security platform - KB5007651
> Mise à jour de la sélection disjointe pour Microsoft Defender Antivirus – KB2267602 (version 1.463.186.0)
> 2026-10 .NET Framework Correctif de sécurité (KB5127694)
> 2026-10 Correctif de sécurité (KB5127648) (26300.9711)
> Microsoft Corporation AudioProcessingObject Driver Update (1.0.4.55794)
> ```
> Mélange de types : **cumulative** Windows (KB5127648 → fera passer la build de .9457 à .9711), .NET, Defender (plateforme + définitions), MSRT, pilote.

**B3.** (bonus) Installe le module `PSWindowsUpdate` et liste les mêmes mises à jour. Un collègue écrit `Get-WindowsUpdate | Select-Object KB, Title` et obtient un tableau vide. Pourquoi ?

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

**B4.** (bonus) Installe toutes les mises à jour, sans redémarrer automatiquement. Comment savoir ensuite si un redémarrage est en attente ?

> [!success]- Afficher la correction — B4
> ```powershell
> Install-WindowsUpdate -AcceptAll -IgnoreReboot
> Get-WURebootStatus                       # True si un redémarrage est en attente
> Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
> ```
> À distance, l'agent Windows Update refuse de télécharger/installer dans une session WinRM : on passe par `Invoke-WUJob -ComputerName PC02 -Script {…}`, qui crée une tâche planifiée locale sur la cible.

---

## Partie C — Stratégie locale : anneau « large »

Le Fournil veut que les postes de production reçoivent les correctifs **7 jours** après leur publication, restent en **25H2/26H2** tant que la DSI n'a pas validé la version suivante, et redémarrent au plus tard **3 jours** après l'installation.

**C1.** Dans `gpedit.msc`, retrouve le nœud Windows Update. Combien de sous-dossiers contient-il ? Lequel ne faut-il **surtout pas** remplir sans serveur WSUS ?

> [!success]- Afficher la correction — C1
> `gpedit.msc` → *Configuration ordinateur → Modèles d'administration → Composants Windows → Windows Update* : **quatre** sous-dossiers en 26H2 :
> - Gérer l'expérience utilisateur final
> - Gérer les mises à jour proposées de Windows Server Update Service ← **à ne pas toucher sans WSUS** : « Spécifier l'emplacement intranet du service de mise à jour Microsoft » pointé vers un serveur inexistant bloque toute mise à jour
> - Gérer les mises à jour proposées de Windows Update
> - Stratégies héritées
>
> ![w11-08-gpedit-windows-update-dossiers](https://cours.kaya.ovh/windows11/assets/captures/w11-08-gpedit-windows-update-dossiers.png)
>
> Astuce de navigation : si le volet gauche est trop étroit, double-cliquer sur les dossiers dans le **volet de droite** (Configuration ordinateur → Modèles d'administration → Composants Windows), puis taper `Windows Update` pour sauter au bon dossier.

**C2.** Configure : report qualité 7 jours, version cible `Windows 11` / `26H2`, échéance qualité 3 jours.

> [!success]- Afficher la correction — C2
> Dans **Gérer les mises à jour proposées de Windows Update** :
> - *Choisir quand recevoir les mises à jour qualité* → **Activé**, 7 jours
> - *Sélectionner la version de la mise à jour des fonctionnalités cible* → **Activé**, produit `Windows 11`, version `26H2`
>
> Dans **Gérer l'expérience utilisateur final** :
> - *Specify deadline for automatic updates and restarts for quality update* → **Activé**, échéance 3 jours, période de grâce 1 jour
>
> ![w11-08-gpedit-qualite-7-jours](https://cours.kaya.ovh/windows11/assets/captures/w11-08-gpedit-qualite-7-jours.png)
>
> ![w11-08-gpedit-version-cible](https://cours.kaya.ovh/windows11/assets/captures/w11-08-gpedit-version-cible.png)
>
> ![w11-08-gpedit-echeance](https://cours.kaya.ovh/windows11/assets/captures/w11-08-gpedit-echeance.png)
>
> Dans les listes *Échéance* et *Période de grâce*, utiliser les **flèches** : taper un chiffre au clavier peut sélectionner une autre valeur (« 3 » a donné « 23 » sur le lab).
>
> Puis `gpupdate /force`.

**C3.** Vérifie dans les Paramètres que la stratégie est bien appliquée. (bonus) Confirme les valeurs dans le registre.

> [!success]- Afficher la correction — C3
> ```powershell
> Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" |
>     Select-Object DeferQualityUpdates, DeferQualityUpdatesPeriodInDays, TargetReleaseVersion, ProductVersion, TargetReleaseVersionInfo, ConfigureDeadlineForQualityUpdates
> ```
> Valeurs relevées sur le lab : `DeferQualityUpdates = 1`, `DeferQualityUpdatesPeriodInDays = 7`, `TargetReleaseVersion = 1`, `ProductVersion = Windows 11`, `TargetReleaseVersionInfo = 26H2`, `ConfigureDeadlineForQualityUpdates = 3` (et `ConfigureDeadlineGracePeriod = 1`).
> Côté utilisateur : **Paramètres → Windows Update → Options avancées** : *Me mettre à jour* est grisé (« *non disponible en raison de la stratégie de votre organisation* ») ; tout en bas, **Stratégies de mise à jour configurées** liste les stratégies, en lecture seule :
>
> ![w11-08-parametres-strategies-configurees](https://cours.kaya.ovh/windows11/assets/captures/w11-08-parametres-strategies-configurees.png)

**C4.** Que devra faire la DSI le jour où la version 27H2 sera validée ?

> [!success]- Afficher la correction — C4
> Modifier la stratégie **version cible** (`27H2`) — d'abord dans la GPO de l'anneau pilote, puis, après validation, dans celle de l'anneau large. Sans cette modification, les postes restent sur 26H2 (tant qu'elle est supportée : 24 mois pour Pro).

---

## Partie D — Applications et pilotes

**D1.** Windows Update ne propose plus rien. Le poste est-il à jour ? Vérifie avec WinGet.

> [!success]- Afficher la correction — D1
> Non. Windows Update ne couvre que Windows (et Office/Edge si coché).
> ```powershell
> winget upgrade
> ```
> Sur `PC01` : **5 à 8 mises à jour** d'applications selon la date (Edge, WebView2, OneDrive, App Installer, Terminal…). `winget upgrade --all --silent` (chapitre 05).

**D2.** Un pilote proposé par Windows Update fait planter les postes. Quelle stratégie empêche Windows Update de distribuer les pilotes ?

> [!success]- Afficher la correction — D2
> *Gérer les mises à jour proposées de Windows Update → **Ne pas inclure les pilotes avec les mises à jour Windows*** → Activé (valeur `ExcludeWUDriversInQualityUpdate = 1`). Les pilotes sont alors gérés par l'outil du constructeur ou par Intune/Autopatch, de façon contrôlée.

---

## Partie E — Exercices complémentaires (bonus)

**E1.** Explique en quelques lignes à un responsable pourquoi le Fournil ne montera **pas** de serveur WSUS en 2026, et ce qu'il fera à la place.

> [!success]- Afficher la correction — E1
> - **WSUS est déprécié** depuis septembre 2024 : il fonctionne encore dans Windows Server 2025, mais ne recevra plus aucune évolution. Investir dedans en 2026, c'est construire sur une technologie en fin de vie.
> - Il demande un serveur, du stockage (des centaines de Go), de la maintenance (nettoyage, base WID) et un administrateur qui approuve chaque mise à jour.
> - À la place : les **stratégies Windows Update client** par GPO (gratuites, déjà dans le domaine), en **anneaux** (pilote / large / critique), avec des échéances. Les postes téléchargent chez Microsoft, avec l'**Optimisation de la distribution** (partage entre postes du réseau local) pour économiser la bande passante.
> - Si le Fournil passe à Microsoft 365 Business Premium : **Intune + Autopatch** prendront le relais (Windows, Office, Edge, Teams, pilotes).

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/standard)
