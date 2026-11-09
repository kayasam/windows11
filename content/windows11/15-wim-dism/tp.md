---
title: "TP 15. Images WIM et DISM"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/15-wim-dism"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/15-wim-dism/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/15-wim-dism/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/15-wim-dism.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/15-wim-dism/tp" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/15-wim-dism/tp-corrigev2">Afficher les corrections</a></nav>

> Durée estimée : 1h45

> Chapitres associés : [15. Images WIM et DISM](https://cours.kaya.ovh/windows11/windows11/15-wim-dism/)

---

## Objectifs

- Capturer l'image généralisée de `MASTER` depuis l'hôte
- Inspecter un fichier WIM (index, tailles, édition)
- Monter une image et la modifier hors ligne (applications, pilotes)
- Découper une image pour une clé USB
- Appliquer une image à la main depuis Windows PE

---

## Prérequis

- `MASTER` généralisée et **éteinte** (TP 14), avec son point de contrôle `Avant-Sysprep`
- WinPE personnalisé (TP 13)
- **40 Go libres** sur le disque de l'hôte

---

## Partie A — Capture (30 min)

**A1.** Quel fichier disque faut-il monter pour capturer `MASTER` ? Pourquoi pas `MASTER.vhdx` ?

**A2.** Monte le disque actif en **lecture seule**, repère la lettre du volume Windows, vérifie que c'est bien l'image Fournil.

**A3.** Capture le volume dans `D:\Images\MASTER.wim` (nom « MASTER-Fournil-2026-11 », compression maximale, contrôle d'intégrité). Combien de temps ? Quelle taille ?

**A4.** Démonte le disque. Le point de contrôle de `MASTER` est-il toujours utilisable ?

---

## Partie B — Inspecter (15 min)

**B1.** Affiche les informations de `MASTER.wim`, puis le détail de l'index 1. Combien d'index ? Quelle édition ? Quelle taille décompressée ?

**B2.** Compare avec le `install.wim` de l'ISO officielle.

---

## Partie C — Maintenance hors ligne (30 min)

**C1.** Monte l'index 1 de `MASTER.wim` dans `C:\Mount`.

**C2.** Liste les applications provisionnées de l'image montée et retire `Microsoft.BingWeather`.

**C3.** Ajoute un pilote (`.inf`) à l'image montée. Où trouver un pilote pour le test ?

**C4.** Démonte en **enregistrant**. Que se passe-t-il si on supprime `C:\Mount` sans démonter ?

---

## Partie D — Clé USB (10 min)

**D1.** Pourquoi `MASTER.wim` ne peut-il pas être copié tel quel sur une clé USB de démarrage UEFI ? Découpe-le en morceaux de 3,8 Go.

---

## Partie E — Appliquer depuis WinPE (20 min)

**E1.** Prépare un disque contenant `MASTER.wim` et le script `partition-uefi.txt`. Démarre une VM vierge sur le WinPE du TP 13, avec ce disque attaché.

**E2.** Identifie le disque cible et la lettre du disque d'images. Pourquoi cette étape est-elle vitale ?

**E3.** Partitionne, applique l'image, rends le disque démarrable.

**E4.** Au redémarrage, que voit-on ? Comment l'automatiser ?

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/15-wim-dism/tp-corrigev2)
