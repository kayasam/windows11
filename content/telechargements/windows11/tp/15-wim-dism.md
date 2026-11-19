# TP 14. Images WIM et DISM

> [!abstract] Parcours TSSR
> Socle : partie B uniquement, sur install.wim de l’ISO officielle. MASTER et les parties A, C, D, E sont (bonus) ; aucune capture n’est nécessaire pour suivre le TP 15.

> Chapitres associés : [14. Images WIM et DISM](https://cours.kaya.ovh/windows11/windows11/15-wim-dism/)

---

## Objectifs

- Capturer l'image généralisée de `MASTER` depuis l'hôte (bonus)
- Inspecter un fichier WIM (index, tailles, édition)
- Monter une image et la modifier hors ligne (applications, pilotes) (bonus)
- Découper une image pour une clé USB (bonus)
- Appliquer une image à la main depuis Windows PE (bonus)

---

## Prérequis

- Socle : ISO officielle montée et fichier `install.wim` accessible (copie préparée au TP 12), DISM disponible.
- (bonus) Pour A, C, D et E : `MASTER` généralisée et éteinte (TP 13), `MASTER.wim` après capture, WinPE et 40 Go libres sur l’hôte.

---

## Partie A — Capture (bonus)

**A1.** Quel fichier disque faut-il monter pour capturer `MASTER` ? Pourquoi pas `MASTER.vhdx` ?

**A2.** Monte le disque actif en **lecture seule**, repère la lettre du volume Windows, vérifie que c'est bien l'image Fournil.

**A3.** Capture le volume dans `D:\Images\MASTER.wim` (nom « MASTER-Fournil-2026-11 », compression maximale, contrôle d'intégrité). Combien de temps ? Quelle taille ?

**A4.** Démonte le disque. Le point de contrôle de `MASTER` est-il toujours utilisable ?

---

## Partie B — Inspecter

**B1.** Dans un Terminal administrateur sur `PC01`, affiche les informations de l’`install.wim` officiel copié au TP 12 (`C:\Images\install.wim`), repère l’index de Windows 11 Professionnel, puis affiche son détail. Combien d’index ? Quelle édition ? Quelle taille décompressée ?

**B2.** Explique à quoi sert l’index lors d’une installation automatisée. Pourquoi faut-il le vérifier pour chaque nouvelle ISO ? La comparaison avec `MASTER.wim` est (bonus).

---

## Partie C — Maintenance hors ligne (bonus)

**C1.** Monte l'index 1 de `MASTER.wim` dans `C:\Mount`.

**C2.** Liste les applications provisionnées de l'image montée et retire `Microsoft.BingWeather`.

**C3.** Ajoute un pilote (`.inf`) à l'image montée. Où trouver un pilote pour le test ?

**C4.** Démonte en **enregistrant**. Que se passe-t-il si on supprime `C:\Mount` sans démonter ?

---

## Partie D — Clé USB (bonus)

**D1.** Pourquoi `MASTER.wim` ne peut-il pas être copié tel quel sur une clé USB de démarrage UEFI ? Découpe-le en morceaux de 3,8 Go.

---

## Partie E — Appliquer depuis WinPE (bonus)

**E1.** Prépare un disque contenant `MASTER.wim` et le script `partition-uefi.txt`. Démarre une VM vierge sur le WinPE du TP 12, avec ce disque attaché.

**E2.** Identifie le disque cible et la lettre du disque d'images. Pourquoi cette étape est-elle vitale ?

**E3.** Partitionne, applique l'image, rends le disque démarrable.

**E4.** Au redémarrage, que voit-on ? Comment l'automatiser ?

---


