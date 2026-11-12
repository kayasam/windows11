# TP 19. Démarrage et récupération

> Durée estimée : 1h30

> Chapitres associés : [19. Démarrage et récupération](https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/)

---

## Objectifs

- Lire et modifier la configuration de démarrage (BCD) sans casser le poste
- Accéder à WinRE de plusieurs façons
- Créer et utiliser des points de restauration
- **Casser puis réparer** le démarrage UEFI d'un poste
- Choisir l'outil de récupération adapté à une situation

---

## Prérequis

- `PC02` opérationnel
- **Point de contrôle Hyper-V obligatoire** avant la partie D : `Checkpoint-VM -Name PC02 -SnapshotName "Avant-TP19"`

---

## Partie A — Configuration du démarrage (20 min)

**A1.** Affiche l'entrée de démarrage courante et le gestionnaire de démarrage avec `bcdedit`. Où est le chargeur ? Quel est le délai d'attente ?

**A2.** Renomme l'entrée en « Windows 11 - Fournil » et ramène le délai à 5 secondes.

**A3.** Avec `msconfig`, configure un démarrage en mode sans échec **réseau**, redémarre, vérifie, puis annule. Pourquoi faut-il penser à annuler ?

**A4.** Quelle commande réactive le menu F8 ? Est-ce une bonne idée sur un poste de production ?

---

## Partie B — WinRE (15 min)

**B1.** Vérifie l'état de WinRE et son emplacement.

**B2.** Donne trois façons de démarrer dans WinRE, dont une en ligne de commande.

**B3.** Dans WinRE, liste les options du menu *Dépannage → Options avancées*. Laquelle est nouvelle en 2026 ?

---

## Partie C — Points de restauration (20 min)

**C1.** Active la protection du système sur `C:` et crée le point « Avant-TP19 ».

**C2.** Essaie d'en créer un second immédiatement. Que se passe-t-il ? Pourquoi ?

**C3.** Installe un logiciel avec WinGet, puis restaure le point « Avant-TP19 ». Le logiciel est-il encore là ? Et un document créé entre-temps ?

**C4.** Compare point de restauration et *point-in-time restore*.

---

## Partie D — Casser et réparer le démarrage (25 min)

> Point de contrôle Hyper-V fait ? Sinon, ne commence pas.

**D1.** Supprime l'entrée de démarrage courante : `bcdedit /delete {current}`. Redémarre. Que se passe-t-il ?

**D2.** Depuis WinRE (invite de commandes), identifie la lettre du volume Windows et de la partition EFI.

**D3.** Répare le démarrage avec la bonne commande. Pourquoi pas `bootrec /fixboot` ?

**D4.** Redémarre et vérifie que Windows démarre. Vérifie le BCD.

---

## Partie E — Quelle arme ? (10 min)

**E1.** Pour chaque situation, propose l'outil :
1. Depuis la mise à jour d'hier, le poste fait un écran bleu au démarrage.
2. Excel plante depuis l'installation d'un complément ce matin.
3. `sfc /scannow` signale des fichiers corrompus qu'il ne peut pas réparer.
4. Le poste d'un stagiaire parti doit être rendu à un nouvel arrivant.
5. Une mise à jour défectueuse empêche 300 postes de démarrer.

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/tp-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/tp-corrigev2)
