# TP 05 — Pilotes, applications et WinGet

> Durée estimée : 1h30

> Chapitres associés : [05. Pilotes, applications et WinGet](https://kayasam.github.io/windows11/windows11/05-peripheriques-applications/)

---

## Objectifs

- Inventorier les périphériques et le magasin de pilotes
- Ajouter, exporter et retirer un pilote avec `pnputil`
- Distinguer applications installées et applications provisionnées
- Construire le socle logiciel du Fournil avec WinGet et l'exporter

---

## Prérequis

- `PC01` installé (TP 02), avec accès Internet (TP 03)
- Terminal **administrateur**

---

## Partie A — Périphériques (20 min)

**A1.** Ouvre le Gestionnaire de périphériques. Combien de cartes réseau vois-tu ? Affiche les périphériques cachés : qu'est-ce qui apparaît en plus ?

**A2.** En PowerShell, compte les périphériques présents par classe, puis liste ceux qui ne sont pas en état `OK`.

**A3.** Quel est le nom du pilote utilisé par la carte réseau de `PC01` ? D'où vient-il ?

---

## Partie B — Magasin de pilotes (25 min)

**B1.** Liste les pilotes tiers du magasin avec `pnputil`. Que signifient « Nom publié » et « Nom d'origine » ?

**B2.** Exporte tous les pilotes tiers dans `C:\Sauvegarde\Pilotes`. Dans quelle situation cet export est-il précieux ?

**B3.** Réinjecte l'un des pilotes exportés dans le magasin avec `pnputil /add-driver`. Que répond l'outil, et pourquoi ?

**B4.** Une mise à jour de pilote graphique provoque des écrans noirs depuis hier. Quelles sont tes options, de la plus douce à la plus radicale ?

---

## Partie C — Applications et fonctionnalités (20 min)

**C1.** Liste les applications **provisionnées** de l'image. Quelle est la différence avec `Get-AppxPackage` ?

**C2.** Le Fournil ne veut pas de `Microsoft.BingNews` pour les **futurs** utilisateurs du poste. Retire-le de l'image. Les utilisateurs qui ont déjà un profil le perdent-ils ?

**C3.** Vérifie si `wmic` existe encore sur le poste. Un vieux script du Fournil contient `wmic bios get serialnumber` : réécris-le.

**C4.** Liste les capacités OpenSSH. Lesquelles sont installées ?

---

## Partie D — WinGet : le socle logiciel du Fournil (25 min)

**D1.** Vérifie la version de WinGet et les sources configurées.

**D2.** Cherche « 7zip ». Pourquoi `winget install 7zip` est-il une mauvaise idée ? Installe 7-Zip correctement, pour tous les utilisateurs, sans aucune question.

**D3.** Installe Notepad++ de la même façon.

**D4.** Liste les mises à jour disponibles. Combien y en a-t-il sur un poste tout juste installé, et pourquoi ?

**D5.** Bloque les mises à jour de Microsoft Teams (le Fournil veut valider chaque version), puis mets à jour tout le reste.

**D6.** Exporte la liste des logiciels dans `C:\Temp\socle-fournil.json`. Que contient ce fichier ? Que n'y trouve-t-on pas ?

---

## Partie E — Bonus

**E1.** Installe le module PowerShell `Microsoft.WinGet.Client` et liste les paquets installés sous forme d'objets, triés par nom.

**E2.** Une tâche planifiée en SYSTEM lance `winget upgrade --all` chaque nuit et échoue avec « winget n'est pas reconnu ». Explique et corrige.

---

[Ouvrir la correction](https://kayasam.github.io/windows11/windows11/05-peripheriques-applications/tp-corrigev2)


[Afficher les corrections](https://kayasam.github.io/windows11/windows11/05-peripheriques-applications/tp-corrigev2)
