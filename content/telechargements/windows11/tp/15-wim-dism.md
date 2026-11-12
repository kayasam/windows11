# TP 15. Images WIM et DISM

> Durée estimée : 1h45

> Chapitres associés : [15. Images WIM et DISM](https://cours.kaya.ovh/windows11/windows11/15-wim-dism/)

> [!abstract] Niveau
> Socle TSSR : partie B seulement, sur l'`install.wim` de l'ISO officielle. Parties A (capture, suppose `MASTER` du TP 14), C et E : approfondissement. Le TP 16 n'utilise aucune de ces parties.

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

## Partie C — Maintenance hors ligne (30 min) *(approfondissement)*

**C1.** Monte l'index 1 de `MASTER.wim` dans `C:\Mount`.

**C2.** Liste les applications provisionnées de l'image montée et retire `Microsoft.BingWeather`.

**C3.** Ajoute un pilote (`.inf`) à l'image montée. Où trouver un pilote pour le test ?

**C4.** Démonte en **enregistrant**. Que se passe-t-il si on supprime `C:\Mount` sans démonter ?

---

## Partie D — Clé USB (10 min)

**D1.** Pourquoi `MASTER.wim` ne peut-il pas être copié tel quel sur une clé USB de démarrage UEFI ? Découpe-le en morceaux de 3,8 Go.

---

## Partie E — Appliquer depuis WinPE (20 min) *(approfondissement)*

**E1.** Prépare un disque contenant `MASTER.wim` et le script `partition-uefi.txt`. Démarre une VM vierge sur le WinPE du TP 13, avec ce disque attaché.

**E2.** Identifie le disque cible et la lettre du disque d'images. Pourquoi cette étape est-elle vitale ?

**E3.** Partitionne, applique l'image, rends le disque démarrable.

**E4.** Au redémarrage, que voit-on ? Comment l'automatiser ?

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/15-wim-dism/tp-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/15-wim-dism/tp-corrigev2)
