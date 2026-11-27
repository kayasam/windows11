---
title: "TP 19. Démarrage et récupération"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/18-demarrage-recuperation"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="html" href="https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/html/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28 32"><path d="M2 2h24l-2 25-10 3-10-3Z" fill="#e44d26"/><path d="M14 5v22l7-2 2-20Z" fill="#f16529"/><path d="M7 8h15l-.3 3H11l.3 3h10l-.8 9-6.5 2-6.5-2-.4-5h3l.2 2.6 3.7 1 3.7-1 .3-3.6H8Z" fill="#fff"/></svg>
</span><span class="resource-label">HTML</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/18-demarrage-recuperation.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/tp/standard" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/tp/standard-corrigev2">Afficher les corrections</a></nav>


> [!abstract] Parcours TSSR
> Socle : lire le démarrage, accéder à WinRE, tester une restauration et choisir l’outil adapté. Supprimer le BCD pour le réparer et réactiver F8 sont (bonus). Attendre la fin du redémarrage avant de poursuivre.

> Chapitres associés : [19. Démarrage et récupération](https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/)

---

## Objectifs

- Lire et modifier la configuration de démarrage (BCD) sans casser le poste
- Accéder à WinRE de plusieurs façons
- Créer et utiliser des points de restauration
- **Casser puis réparer** le démarrage UEFI d'un poste (bonus)
- Choisir l'outil de récupération adapté à une situation

---

## Prérequis

- `PC02` opérationnel
- **Point de contrôle Hyper-V obligatoire** avant la partie D : `Checkpoint-VM -Name PC02 -SnapshotName "Avant-TP19"`

---

## Partie A — Configuration du démarrage

**A1.** Affiche l'entrée de démarrage courante et le gestionnaire de démarrage avec `bcdedit`. Où est le chargeur ? Quel est le délai d'attente ?

**A2.** (bonus) Renomme l'entrée en « Windows 11 - Fournil » et ramène le délai à 5 secondes.

**A3.** Avec `msconfig`, configure un démarrage en mode sans échec **réseau**, redémarre, vérifie, puis annule. Pourquoi faut-il penser à annuler ?

**A4.** (bonus) Quelle commande réactive le menu F8 ? Est-ce une bonne idée sur un poste de production ?

---

## Partie B — WinRE

**B1.** Vérifie l'état de WinRE et son emplacement.

**B2.** Donne trois façons de démarrer dans WinRE, dont une en ligne de commande.

**B3.** Dans WinRE, liste les options du menu *Dépannage → Options avancées*. Laquelle est nouvelle en 2026 ?

---

## Partie C — Points de restauration

**C1.** Active la protection du système sur `C:` et crée le point « Avant-TP19 ».

**C2.** (bonus) Essaie d'en créer un second immédiatement. Que se passe-t-il ? Pourquoi ?

**C3.** Installe un logiciel avec WinGet, puis restaure le point « Avant-TP19 ». Le logiciel est-il encore là ? Et un document créé entre-temps ?

**C4.** Compare point de restauration et *point-in-time restore*.

---

## Partie D — Casser et réparer le démarrage (bonus)

> Point de contrôle Hyper-V fait ? Sinon, ne commence pas.

**D1.** Supprime l'entrée de démarrage courante : `bcdedit /delete {current}`. Redémarre. Que se passe-t-il ?

**D2.** Depuis WinRE (invite de commandes), identifie la lettre du volume Windows et de la partition EFI.

**D3.** Répare le démarrage avec la bonne commande. Pourquoi pas `bootrec /fixboot` ?

**D4.** Redémarre et vérifie que Windows démarre. Vérifie le BCD.

---

## Partie E — Quelle arme ?

**E1.** Pour chaque situation, propose l'outil :
1. Depuis la mise à jour d'hier, le poste fait un écran bleu au démarrage.
2. Excel plante depuis l'installation d'un complément ce matin.
3. `sfc /scannow` signale des fichiers corrompus qu'il ne peut pas réparer.
4. Le poste d'un stagiaire parti doit être rendu à un nouvel arrivant.
5. Une mise à jour défectueuse empêche 300 postes de démarrer.

---


