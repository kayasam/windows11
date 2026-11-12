---
title: "TP 17. Déployer Windows 11 par le réseau : PXE et WDS"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/17-wds-pxe"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/17-wds-pxe.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>


> Durée estimée : 2h30

> Chapitres associés : [17. Déployer Windows 11 par le réseau : PXE et WDS](https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/)

---

## Objectifs

- Installer et configurer WDS sur `SRV01`, qui porte déjà le DHCP
- Préparer une image de démarrage qui lance l'installation depuis un partage
- Déployer `PC03` **sans clic** en démarrant sur la carte réseau, avec le fichier de réponse du chapitre 16
- Diagnostiquer un démarrage PXE qui échoue

---

## Prérequis

- TP 16 réussi : `autounattend-iso-officielle.xml` et `postinstall.ps1` fonctionnent (dossier `Ressources/Fichier-reponse/`)
- `deploiement.cmd` et `winpeshl.ini` (dossier `Ressources/deploiement-wds/`)
- `SRV01` : contrôleur de domaine `ad.fournil.lab` avec DHCP actif (TP 10), OU `OU=Ordinateurs,OU=Fournil`
- ISO officielle Windows 11 26H2 dans `D:\ISO` sur l'hôte
- **70 Go libres** sur l'hôte (disque de données de `SRV01` + `PC03`)

---

## Partie A — Comprendre le démarrage réseau (15 min)

**A1.** Remets dans l'ordre ce qui se passe quand `PC03` démarre sur sa carte réseau, et indique le protocole de chaque étape : chargement de `boot.wim` · ouverture du partage `Deploy$` · obtention d'une adresse IP · téléchargement de `wdsmgfw.efi` · réponse du serveur PXE.

**A2.** En 2026, pourquoi n'importe-t-on **aucune image d'installation** dans WDS ? Qu'est-ce que WDS fait encore pour nous ?

**A3.** Le DHCP et WDS sont sur le même serveur. Quel conflit cela pose-t-il ? Comment le poste apprend-il qu'un serveur PXE existe ?

---

## Partie B — Préparer SRV01 et installer WDS (25 min)

**B1.** Ajoute à `SRV01` un second disque virtuel de 60 Go, formate-le en `E:` (label `Deploiement`), et insère l'ISO officielle dans son lecteur DVD.

**B2.** Installe le rôle WDS puis initialise-le avec le dossier `E:\RemoteInstall`. Vérifie que le chargeur UEFI est bien présent. Que faire s'il manque ?

**B3.** Configure WDS pour qu'il cohabite avec le DHCP, réponde à tous les postes et démarre sans appui sur F12. Vérifie la configuration.

**B4.** Pourquoi ces réglages de réponse seraient-ils dangereux en production ? Propose deux alternatives.

---

## Partie C — Accélérer TFTP (10 min)

**C1.** Règle la taille de bloc TFTP à 16384 et redémarre le service.

**C2.** Pourquoi ne pas mettre systématiquement la valeur la plus grande possible ?

---

## Partie D — L'image de démarrage (30 min)

**D1.** Copie `boot.wim` de l'ISO dans `E:\WinPE` et liste ses images. Laquelle WDS démarre-t-il ? Que se passe-t-il si on l'importe sans modification ?

**D2.** Lis `winpeshl.ini` et `deploiement.cmd`. À quoi sert `winpeshl.ini` ? Pourquoi `deploiement.cmd` commence-t-il par `wpeinit` ? Pourquoi `cmd.exe /k` plutôt que `/c` ?

**D3.** Injecte les deux fichiers dans la bonne image, puis importe le `boot.wim` dans WDS sous le nom `WinPE Fournil - déploiement réseau`.

**D4.** Un collègue propose de modifier directement le `.wim` qui se trouve dans `E:\RemoteInstall\Boot\x64\Images`, « c'est plus rapide ». Qu'en penses-tu ?

---

## Partie E — Le partage de déploiement (20 min)

**E1.** Crée le compte `svc.deploiement` (mot de passe `Fournil2026!`, n'expire jamais) dans `OU=Fournil`. Pourquoi un compte dédié plutôt que `Administrateur` ?

**E2.** Copie le contenu de l'ISO dans `E:\Deploy\Windows11`, et place à la racine de `E:\Deploy` un `autounattend.xml` pour `PC03`, construit à partir de `autounattend-iso-officielle.xml`. Combien de remplacements faut-il ?

**E3.** Comment `postinstall.ps1` arrive-t-il sur le poste, alors qu'il n'y a plus ni DVD ni clé ? Place-le au bon endroit.

**E4.** Partage `E:\Deploy` sous le nom `Deploy$`, en lecture pour `svc.deploiement`. Depuis `PC01`, vérifie que ce compte peut lire `autounattend.xml`.

---

## Partie F — Déployer PC03 (40 min)

**F1.** Crée `PC03` (Gen 2, TPM, 2 vCPU, 4 Go statiques, disque de 64 Go, `vSwitch-Rennes`, **aucun DVD**), avec la carte réseau en premier périphérique de démarrage. Démarre-la et observe les écrans successifs.

**F2.** Combien de temps entre le démarrage et l'écran de connexion final ? Combien de gestes ?

**F3.** Vérifie depuis `SRV01` : OU de `PC03` dans l'AD, enregistrement DNS, journal de post-installation, applications installées.

---

## Partie G — Dépannage (10 min)

**G1.** Un poste affiche « *A boot image was not found* » pour sa carte réseau. Cite trois causes possibles et où les vérifier.

**G2.** Un poste affiche « *La fonctionnalité du client des Services de déploiement Windows est partiellement déconseillée* », puis redémarre et recommence. Explique et corrige.

**G3.** Le poste démarre WinPE, mais l'invite affiche « Partage inaccessible ». Comment diagnostiquer sans redémarrer ?

---

## Partie H — Bonus

**H1.** Où voir, sur `SRV01`, qu'un poste a demandé un démarrage PXE sans obtenir d'image ?

**H2.** La carte réseau était le premier périphérique de démarrage de `PC03`, et WDS répond à tous les postes sans F12. Pourquoi `PC03` ne se réinstalle-t-il pas en boucle à chaque redémarrage ? Vérifie, puis cite un cas où la boucle se produirait.

---


