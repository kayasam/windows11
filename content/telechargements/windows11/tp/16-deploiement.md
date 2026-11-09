# TP 16 — Déployer Windows 11 : ISO, réseau, migration, moderne

> Durée estimée : 2h30

> Chapitres associés : [16. Déployer Windows 11 : ISO, réseau, migration, moderne](https://kayasam.github.io/windows11/windows11/16-deploiement/)

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

[Ouvrir la correction](https://kayasam.github.io/windows11/windows11/16-deploiement/tp-corrigev2)


[Afficher les corrections](https://kayasam.github.io/windows11/windows11/16-deploiement/tp-corrigev2)
