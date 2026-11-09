---
title: "TP 16. Déployer Windows 11 : ISO, réseau, migration, moderne"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/16-deploiement"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/16-deploiement/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/16-deploiement.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp-corrigev2">Afficher les corrections</a></nav>

> Durée estimée : 2h30

> Chapitres associés : [16. Déployer Windows 11 : ISO, réseau, migration, moderne](https://cours.kaya.ovh/windows11/windows11/16-deploiement/)

---

## Objectifs

- Construire une ISO de déploiement **zéro clic** à partir de `MASTER.wim`
- Déployer `PC02`, diagnostiquer un échec de Setup, vérifier le résultat
- Joindre `PC02` au domaine et y migrer les données de `sguillard` avec USMT
- Choisir une méthode de déploiement selon le contexte (WDS, MDT, ConfigMgr, Autopilot)

---

## Prérequis

- `MASTER.wim` (TP 15), `autounattend-fournil-26h2.xml` (TP 13), ISO officielle 26H2
- ADK sur `PC01` (oscdimg, USMT) ; partage `\\SRV01\USMT$`
- **40 Go libres** sur l'hôte

---

## Partie A — L'ISO personnalisée (30 min)

**A1.** Copie le contenu de l'ISO officielle dans `D:\ISO-Deploiement`. Pourquoi `robocopy` plutôt que `Copy-Item` ?

**A2.** Remplace `sources\install.wim` par `MASTER.wim`. Quel obstacle rencontres-tu ?

**A3.** Dépose le fichier de réponse à la racine. Sous quel nom ?

**A4.** Construis `MASTER-Deploiement.iso` en BIOS + UEFI, **sans** le message « Press any key ». Quel risque cela crée-t-il ?

---

## Partie B — Déployer PC02 (30 min)

**B1.** Crée `PC02` (Gen 2, TPM, 2 vCPU, 6 Go statiques, `vSwitch-Rennes`) et démarre-la sur l'ISO. Combien de clics faut-il ?

**B2.** *(Situation vécue sur le lab)* L'installation s'arrête sur « **Échec de l'installation de Windows 11** ». Comment lire les journaux de Setup sur ce poste ?

**B3.** Le journal contient `CAddUnattend::DoExecute: Failed to save copy of answer file to …\Panther\unattend-original.xml (0x80070050)`. Explique et corrige.

**B4.** Une fois sur le bureau, vérifie : nom du poste, compte créé, version de l'image, logiciels, partitions, fuseau, BitLocker, adresse IP.

**B5.** Le compte `Administrateur` intégré est-il actif sur `PC02` ? Pourquoi est-ce important ?

---

## Partie C — Domaine et migration (35 min)

**C1.** Joins `PC02` au domaine dans `OU=Ordinateurs,OU=Fournil`, sous le nom `PC02`.

**C2.** Sur `PC01`, capture le profil de `sguillard` avec `scanstate` vers `\\SRV01\USMT$\Store\PC01`, en n'incluant que ce profil. Teste d'abord avec `/listfiles`.

**C3.** Le magasin fait plusieurs gigaoctets pour quelques documents. Pourquoi ? Que faire ?

**C4.** Sur `PC02`, restaure avec `loadstate`. Ouvre une session `sguillard` et vérifie ses documents.

---

## Partie D — Choisir une méthode (20 min)

**D1.** Pour chaque situation, propose une méthode de déploiement et justifie :
1. Le Fournil (35 postes, un DC, pas de Microsoft 365) renouvelle 10 postes par an.
2. Une chaîne de 200 boulangeries, Microsoft 365 Business Premium, des postes livrés directement en magasin.
3. Un groupe industriel avec ConfigMgr et 8 000 postes.
4. Un client dont le prestataire a monté WDS + MDT en 2019 et qui « veut juste continuer ».

**D2.** Que dirais-tu au client n° 4 sur l'état de WDS et MDT en 2026 ?

---

## Partie E — Bonus

**E1.** Récupère le *hash matériel* de `PC02` pour Autopilot. Que contient le fichier ? À qui l'envoie-t-on ?

**E2.** Comment `PC02` pourrait-il rejoindre le domaine **automatiquement** pendant le déploiement ?

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp-corrigev2)
