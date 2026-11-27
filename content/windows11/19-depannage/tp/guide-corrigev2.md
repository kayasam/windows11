---
title: "TP 20. Diagnostic et dépannage, corrigé guidé"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/19-depannage"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/19-depannage/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="html" href="https://cours.kaya.ovh/windows11/windows11/19-depannage/html/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28 32"><path d="M2 2h24l-2 25-10 3-10-3Z" fill="#e44d26"/><path d="M14 5v22l7-2 2-20Z" fill="#f16529"/><path d="M7 8h15l-.3 3H11l.3 3h10l-.8 9-6.5 2-6.5-2-.4-5h3l.2 2.6 3.7 1 3.7-1 .3-3.6H8Z" fill="#fff"/></svg>
</span><span class="resource-label">HTML</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/19-depannage/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/19-depannage/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/19-depannage-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/19-depannage/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/19-depannage/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Ta mission.** Le formateur a préparé un incident sur une VM du domaine. Sur le poste indiqué, relève les symptômes, fais une correction à la fois et rejoue le test qui échouait. Termine par un ticket avec des preuves.

**À récupérer sur le poste indiqué par le formateur (normalement `PC02`).** Crée `C:\MCO` et enregistre <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/Test-Poste.ps1" download data-router-ignore>Test-Poste.ps1</a> dans ce dossier. Le formateur te donne une VM où l’incident est déjà présent. Commence par A1 et utilise le script en C5 pour les contrôles de fin.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/19-depannage/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/19-depannage/tp/standard)

## Commencer le ticket

### A1 — Reproduire et dater le symptôme

Dans la session utilisateur du poste concerné, teste l’ouverture de `\\SRV01\Commun` et une impression PDF. Note l’heure, le nom du poste, le compte utilisé et le message exact.

> [!success]- Afficher la correction — A1
> La fiche distingue les symptômes observés des causes supposées. Deux symptômes sur le même poste peuvent venir de services différents.

## Isoler les problèmes réseau

### B1 — Contrôler le DNS configuré

Sur le poste incident, lance `ipconfig /all` et `Get-DnsClientServerAddress -AddressFamily IPv4`. Repère le DNS de la carte active et compare-le avec `192.168.3.1`, l’adresse de `SRV01` dans ce lab.

> [!success]- Afficher la correction — B1
> Le poste joint doit utiliser le DNS du domaine. Si un DNS public a été mis sur la carte du lab, remets `192.168.3.1` et refais le test avant de toucher au pare-feu.

### B2 — Comparer la résolution locale et la réponse de SRV01

Sur le poste incident, lance `Resolve-DnsName srv01.ad.fournil.lab`, puis `nslookup srv01.ad.fournil.lab 192.168.3.1`. Si les adresses diffèrent, lis `C:\Windows\System32\drivers\etc\hosts` et recherche uniquement une entrée concernant `SRV01`.

> [!success]- Afficher la correction — B2
> La réponse du DNS du lab doit être `192.168.3.1`. Une entrée locale erronée peut expliquer un résultat différent. Retire seulement l’entrée de l’incident confirmée par le formateur, puis vide le cache avec `Clear-DnsClientCache`.

### B3 — Vérifier le transport jusqu’au partage

Une fois le nom corrigé, lance `Test-NetConnection srv01.ad.fournil.lab -Port 445`. Si le résultat est `False`, ouvre `wf.msc` et examine les règles sortantes de blocage sur le poste.

> [!success]- Afficher la correction — B3
> Une règle de démonstration peut bloquer le TCP 445. Identifie son nom et sa portée avant de désactiver uniquement cette règle. Le port répond ensuite, et `\\SRV01\Commun` doit s’ouvrir dans une session autorisée.

## Réparer et documenter les autres symptômes

### C1 — Lire l’état du service et les traces

Sur le poste, lance `Get-Service Spooler | Select-Object Status,StartType`. Dans `eventvwr.msc`, filtre **Système** sur l’événement **7040** et regarde si une entrée concerne le spouleur.

> [!success]- Afficher la correction — C1
> Le service peut être arrêté et désactivé dans ce scénario. L’événement 7040 trace un changement du type de démarrage. Relève le message correspondant au bon service.

### C2 — Vérifier l’impression après correction

Sur le poste du lab, rétablis le type de démarrage attendu du spouleur, démarre le service et imprime un document de test avec **Microsoft Print to PDF**.

> [!success]- Afficher la correction — C2
> `Get-Service Spooler` doit afficher `Running`. Le PDF sauvegardé est la preuve que le service rend de nouveau sa fonction.

### C3 — Examiner la tâche inconnue en lecture seule

Sur le poste incident, ouvre `taskschd.msc`. Pour la tâche indiquée par le formateur, relève le déclencheur, le compte et le chemin de l’action. Si Sysmon est déjà présent, compare avec les événements de création de processus.

> [!success]- Afficher la correction — C3
> Identifie la tâche à partir de ses propriétés, pas seulement de son nom. Garde la date et le chemin dans la fiche et fais confirmer la tâche avant toute action.

### C4 — Neutraliser la tâche du scénario

Après validation par le formateur, exporte la tâche pour la fiche puis désactive uniquement celle du scénario. Rouvre la session utilisateur et vérifie que le symptôme ne revient pas. Une fois la preuve enregistrée, retire cette tâche de test du Planificateur pour que le contrôle final soit également propre.

> [!success]- Afficher la correction — C4
> Le symptôme ne revient pas à la reconnexion. Le test suivant peut signaler la présence d’une tâche même désactivée, jusqu’à son retrait. Conserve l’export comme preuve d’intervention.

### C5 — Rejouer les contrôles avant de clôturer

Dans Windows PowerShell en administrateur sur le poste en panne, exécute `Unblock-File -LiteralPath C:\MCO\Test-Poste.ps1` sur la copie téléchargée, puis `C:\MCO\Test-Poste.ps1`. Lis les lignes `OK` et `KO`. Pour chaque `KO` restant, indique le contrôle à reprendre dans le ticket. Rejoue aussi l’ouverture du partage avec le compte prévu et l’impression de test.

> [!success]- Afficher la correction — C5
> Le script aide à vérifier DNS, SMB et Spooler, tandis que les tests en session confirment le service rendu. Le ticket indique pour chaque symptôme la cause confirmée, l’action et la preuve après réparation.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/19-depannage/tp/guide)
