---
title: "TP 11 — Stratégies de groupe et gestion centralisée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/11-gpo"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://kayasam.github.io/windows11/windows11/11-gpo/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://kayasam.github.io/windows11/windows11/11-gpo/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://kayasam.github.io/windows11/telechargements/windows11/tp/11-gpo.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://kayasam.github.io/windows11/windows11/11-gpo/tp" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://kayasam.github.io/windows11/windows11/11-gpo/tp-corrigev2">Afficher les corrections</a></nav>

> Durée estimée : 2h

> Chapitres associés : [11. Stratégies de groupe et gestion centralisée](https://kayasam.github.io/windows11/windows11/11-gpo/)

---

## Objectifs

- Administrer les GPO depuis `PC01` (RSAT)
- Créer une GPO **ordinateur** de sécurité : admins locaux, Windows LAPS, BitLocker → AD, anneau Windows Update
- Créer une GPO **utilisateur** filtrée sur un groupe : lecteur réseau et restriction
- Diagnostiquer avec `gpresult`

---

## Prérequis

- `SRV01` contrôleur de domaine, `PC01` joint dans `OU=Ordinateurs,OU=Fournil` (TP 10)
- BitLocker actif sur `PC01` avec une clé de récupération (TP 09)
- Session sur `PC01` avec un compte membre de *Admins du domaine* pour ce TP

---

## Partie A — Outils (15 min)

**A1.** Installe sur `PC01` la console GPMC et les outils AD (RSAT). Combien de temps cela prend-il, et pourquoi ?

**A2.** Ouvre `gpmc.msc`. Quelles GPO existent déjà ? Où sont-elles liées ?

**A3.** Où sont stockées physiquement les GPO ? Retrouve le dossier de la *Default Domain Policy*.

---

## Partie B — GPO ordinateur « GPO-Postes-Securite » (45 min)

**B1.** Crée la GPO `GPO-Postes-Securite` et lie-la à `OU=Ordinateurs,OU=Fournil`.

**B2.** Fais en sorte que `FOURNIL\GG-Admins-Postes` soit administrateur local de tous les postes de l'UO. Deux méthodes possibles : lesquelles ? Choisis-en une.

**B3.** Prépare le domaine pour **Windows LAPS**, puis configure la GPO : sauvegarde dans AD, 14 caractères, 30 jours.

**B4.** Configure la sauvegarde des clés de récupération BitLocker du disque système dans AD DS.

**B5.** Ajoute un report de **7 jours** des mises à jour qualité (anneau « large »).

**B6.** Applique sur `PC01` et vérifie **chacun** des quatre réglages.

**B7.** La clé BitLocker n'apparaît pas dans AD. Pourquoi ? Corrige.

**B8.** Le mot de passe LAPS est bien dans AD… mais un technicien ne peut pas s'en servir pour ouvrir une session. Pourquoi ?

---

## Partie C — GPO utilisateur filtrée (35 min)

Sur `SRV01`, un partage `\\SRV01\Commun` est accessible en modification au groupe `G-Boulangerie`.

**C1.** Crée la GPO `GPO-Boulangerie-Utilisateurs`, liée à `OU=Utilisateurs,OU=Fournil`.

**C2.** Ajoute une **préférence** qui monte `\\SRV01\Commun` en `P:`, nommé « Commun ». Pourquoi une préférence et pas une stratégie ?

**C3.** Ajoute la stratégie « Interdire l'accès au Panneau de configuration et à l'application Paramètres du PC ».

**C4.** Restreins la GPO aux membres de `G-Boulangerie`. Quelle erreur classique faut-il éviter ?

**C5.** Ouvre une session `FOURNIL\sguillard` sur `PC01`. Vérifie le lecteur `P:` et la restriction.

**C6.** Crée un utilisateur `test.vendeur` dans `OU=Utilisateurs`, **hors** de `G-Boulangerie`. Que reçoit-il ?

---

## Partie D — Diagnostic (15 min)

**D1.** Avec `gpresult`, affiche les GPO ordinateur puis utilisateur appliquées sur `PC01`. Produis aussi un rapport HTML.

**D2.** Un collègue a déplacé `PC01` dans `CN=Computers` par erreur. Que montre `gpresult` ? Pourquoi ?

**D3.** Où chercher si une GPO ne s'applique pas du tout (aucune trace) ?

---

## Partie E — Bonus

**E1.** Sauvegarde toutes les GPO du domaine dans `C:\Sauvegarde\GPO` en une commande.

**E2.** Explique à quoi servirait **Group Policy Analytics** si le Fournil passait à Intune.

---

[Ouvrir la correction](https://kayasam.github.io/windows11/windows11/11-gpo/tp-corrigev2)
