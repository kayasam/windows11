---
title: "TP 19 — Diagnostic et dépannage"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/19-depannage"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://kayasam.github.io/windows11/windows11/19-depannage/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://kayasam.github.io/windows11/windows11/19-depannage/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://kayasam.github.io/windows11/telechargements/windows11/tp/19-depannage.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://kayasam.github.io/windows11/windows11/19-depannage/tp" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://kayasam.github.io/windows11/windows11/19-depannage/tp-corrigev2">Afficher les corrections</a></nav>

> Durée estimée : 2h

> Chapitres associés : [19. Diagnostic et dépannage](https://kayasam.github.io/windows11/windows11/19-depannage/)

---

## Objectifs

- Appliquer une **méthode** de dépannage (symptôme → hypothèse → test → correction → vérification)
- Diagnostiquer un poste en panne avec les outils intégrés (journaux, réseau, services, tâches, pare-feu)
- Réparer **sans réinstaller**
- Documenter l'intervention

---

## Prérequis

- `PC02` joint au domaine, l'utilisateur de test voit son lecteur `P:` et peut imprimer sur l'imprimante PDF
- **Point de contrôle Hyper-V** : `Checkpoint-VM -Name PC02 -SnapshotName "Avant-pannes"`
- Le formateur (ou ton binôme) exécute `Ressources/scripts/Casse-Poste.ps1` en administrateur sur `PC02` **sans te dire ce qu'il fait**, puis redémarre le poste

> Ne lis pas le script avant la fin du TP : c'est l'intérêt de l'exercice.

---

## Partie A — Recueillir les symptômes (15 min)

Ouvre une session avec l'utilisateur de test, puis avec le compte administrateur local.

**A1.** Note **tout** ce qui ne fonctionne pas comme avant (ouverture de session, lecteurs, impression, accès à `\\srv01`, Internet, lenteurs…).

**A2.** Ouvre une fiche d'intervention (modèle au chapitre 19) : date, poste, symptômes, qui est impacté, depuis quand.

---

## Partie B — Réseau et résolution de noms (30 min)

**B1.** Vérifie la configuration IP et DNS de la carte. Qu'est-ce qui est anormal sur un poste du domaine ?

**B2.** Teste la résolution de `srv01.ad.fournil.lab` et de `ad.fournil.lab`. Les résultats sont-ils cohérents entre eux ? Avec `Resolve-DnsName`, d'où vient la réponse pour `srv01` ?

**B3.** Teste la connexion SMB vers `srv01` (port 445). Après avoir corrigé B1 et B2, le test réussit-il ? Sinon, cherche la cause dans le pare-feu.

**B4.** Corrige chaque panne et vérifie : résolution, `Test-NetConnection -Port 445`, accès au partage, canal sécurisé avec le domaine.

---

## Partie C — Services et impression (15 min)

**C1.** Impossible d'imprimer. Trouve le service en cause, son état et son type de démarrage.

**C2.** Retrouve dans le journal **Système** l'événement qui trace le changement de type de démarrage.

**C3.** Corrige et vérifie par une impression de test.

---

## Partie D — Le programme mystère (25 min)

Un utilisateur trouve son poste « lent depuis hier » et voit parfois un processus PowerShell dans le Gestionnaire des tâches.

**D1.** Trouve ce qui lance `powershell.exe` à l'ouverture de session. Cherche dans au moins deux endroits : les emplacements de démarrage (Gestionnaire des tâches, `Run`) et les tâches planifiées.

**D2.** Sous quel compte s'exécute-t-il ? Que fait le script lancé ? Pourquoi le nom de la tâche est-il trompeur ?

**D3.** Si Sysmon est actif (chapitre 19), retrouve la création du processus (ID 1) et sa ligne de commande complète, avec le processus parent.

**D4.** Supprime la persistance et le script. Vérifie après une nouvelle ouverture de session.

---

## Partie E — Vérifier et clore (15 min)

**E1.** Écris un petit script `Test-Poste.ps1` qui vérifie en une passe : DNS = contrôleur de domaine, `srv01` résolu vers la bonne adresse, port 445 ouvert vers `srv01`, Spooler démarré et automatique, aucune règle de pare-feu sortante de blocage personnalisée, aucune tâche planifiée à la racine lançant `powershell.exe`.

**E2.** Complète la fiche d'intervention : causes, corrections, vérifications, recommandations pour éviter la récidive.

**E3.** Combien de pannes as-tu trouvé ? Compare avec le script `Casse-Poste.ps1`.

---

[Ouvrir la correction](https://kayasam.github.io/windows11/windows11/19-depannage/tp-corrigev2)
