---
title: "TP 05. Pilotes, applications et WinGet"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/05-peripheriques-applications"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/05-peripheriques-applications.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>


> Durée estimée : 1h30

> Chapitres associés : [05. Pilotes, applications et WinGet](https://cours.kaya.ovh/windows11/windows11/05-peripheriques-applications/)

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


