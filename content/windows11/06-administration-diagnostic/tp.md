---
title: "TP 06. Processus, services, tâches planifiées et journaux"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/06-administration-diagnostic"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/06-administration-diagnostic/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/06-administration-diagnostic.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>


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

**A2.** En PowerShell, liste les 5 processus qui consomment le plus de mémoire, avec la mémoire en Mo.

**A3.** Lance le Bloc-notes, retrouve son PID en CMD, puis ferme-le de force en PowerShell.

---

## Partie B — Services (20 min)

**B1.** Liste les services en démarrage **automatique** qui ne tournent pas. Est-ce forcément anormal ?

**B2.** Observe le service **Spouleur d'impression** : état, type de démarrage, services dont il dépend. Arrête-le, puis passe-le en **Désactivé**.

**B3.** Que se passe-t-il si un utilisateur essaie d'imprimer en PDF ? Remets le service en état normal.

**B4.** Quelle est la différence entre « Automatique » et « Automatique (début différé) » ?

---

## Partie C — Planificateur de tâches (30 min)

Le Fournil veut un **relevé quotidien de l'espace disque** de chaque poste, pour anticiper les disques pleins.

**C1.** Crée le script `C:\Scripts\Inventaire-Disques.ps1`, qui ajoute une ligne par disque fixe dans `C:\Scripts\inventaire-disques.log` : date, lettre, espace libre en Go.

**C2.** Crée la tâche `\Fournil\Inventaire-Disques` :
- tous les jours à 07:30,
- sous le compte **SYSTEM**,
- rattrapée si le PC était éteint,
- durée maximale de 30 minutes,
- indépendante de la stratégie d'exécution PowerShell du poste.

**C3.** Lance-la immédiatement et vérifie son résultat de trois façons.

**C4.** Exporte-la en XML. À quoi ce fichier peut-il servir ?

**C5.** Avec `schtasks`, affiche la tâche au format liste. Quelle option permettrait de la lancer sur `PC02` depuis `PC01` ?

**C6.** Une autre tâche affiche `LastTaskResult = 2147942402`. Diagnostique.

---

## Partie D — Journaux d'événements (20 min)

**D1.** Un collègue tape :
```powershell
Get-WinEvent -LogName System -FilterHashtable @{ Level = 2 }
```
Ça échoue. Pourquoi ? Corrige.

**D2.** Liste les 4 derniers démarrages/arrêts du poste (6005, 6006, 6008, 6013).

**D3.** Liste les erreurs et événements critiques du journal Système des dernières 24 heures. Quelle est la source la plus fréquente ?

**D4.** Pourquoi `Get-WinEvent -FilterHashtable` est-il préférable à `Get-WinEvent -LogName System | Where-Object Level -eq 2` ?

**D5.** Crée une **vue personnalisée** dans l'Observateur d'événements : « Fournil — Erreurs 24h » (Critique + Erreur, journaux Système et Application, dernières 24 heures).

---

## Partie E — Fiabilité (5 min)

**E1.** Ouvre le Moniteur de fiabilité. Quel est l'indice de stabilité de `PC01` ? Quel avertissement apparaît, et que signifie-t-il ?

---

## Partie F — Bonus

**F1.** Crée une tâche planifiée déclenchée par un **événement** : à chaque échec d'ouverture de session (ID 4625 du journal Sécurité), ajouter une ligne dans `C:\Scripts\echecs.log`.

---


