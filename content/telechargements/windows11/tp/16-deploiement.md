# TP 16. Déployer Windows 11 : ISO, réseau, migration, moderne

> [!abstract] Parcours TSSR
> Socle : déployer PC02 avec l’ISO officielle et les fichiers fournis, migrer un profil de test avec USMT et choisir une méthode selon le contexte. Un petit jeu de documents est préparé avant la capture. L’image maître et l’ISO personnalisée sont (bonus).

> Chapitres associés : [15. Déployer Windows 11 : ISO, réseau, migration, moderne](https://cours.kaya.ovh/windows11/windows11/16-deploiement/)

---

## Objectifs

- Déployer `PC02` **sans clic** depuis l'ISO **officielle** et un `autounattend.xml` complet (jonction au domaine, applications)
- Vérifier le résultat et savoir où chercher en cas d'échec
- Migrer les données de `stagiaire` avec USMT
- Choisir une méthode de déploiement selon le contexte (WDS, MDT, ConfigMgr, Autopilot)
- (bonus) Construire une ISO personnalisée à partir de `MASTER.wim`

---

## Fichiers à récupérer sur `PC01`

Crée le dossier `C:\Images\TP15` et enregistre les quatre fichiers ci-dessous dedans. Prépare aussi l’ISO Windows 11 du lab sur l’hôte Hyper-V.

| Fichier | À quoi il sert |
| --- | --- |
| <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/autounattend-iso-officielle.xml" download data-router-ignore>autounattend-iso-officielle.xml</a> | Modèle d’installation de `PC02` |
| <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/Preparer-Fichier-Reponse.ps1" download data-router-ignore>Preparer-Fichier-Reponse.ps1</a> | Crée `autounattend.xml` en demandant les identifiants du lab |
| <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/postinstall.ps1" download data-router-ignore>postinstall.ps1</a> | Installe les applications après le premier démarrage |
| <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/MigFournil.xml" download data-router-ignore>MigFournil.xml</a> | Sélectionne les dossiers à migrer avec USMT |

Dans l’ADK du TP 13, vérifie que **Outils de déploiement** et **User State Migration Tool (USMT)** sont installés sur `PC01`. Demande au formateur le mot de passe local du lab et les identifiants du compte autorisé à joindre les VM au domaine..

## Prérequis

- ISO officielle Windows 11 26H2
- Les quatre fichiers téléchargés sur `PC01`. Suis la préparation A2 du [TP guidé](https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp/guide) pour créer `autounattend.xml`.
- Domaine `ad.fournil.lab` avec DHCP actif et l'OU `OU=Ordinateurs,OU=Fournil` (TP 10)
- ADK sur `PC01` (oscdimg, USMT) ; partage `\\SRV01\USMT$` créé par l’élève avec la préparation ci-dessous ; compte de lab autorisé à lire les outils et à écrire le magasin et les journaux
- Partie F seulement : `MASTER.wim` (TP 15) et **40 Go libres** sur l'hôte

---

## Partie A — Lire le fichier de réponse

**A1.** Ouvre `autounattend-iso-officielle.xml`. Pour chacune des trois passes (`windowsPE`, `specialize`, `oobeSystem`), indique ce qu'elle règle.

**A2.** Quel composant fait rejoindre le domaine au poste ? Que doit-il exister dans l'Active Directory avant le déploiement ?

**A3.** Pourquoi le bloc `AutoLogon` contient-il `<Domain>PC02</Domain>` ?

**A4.** À quoi sert `PreventDeviceEncryption` ici, puisqu'on ne fait pas de Sysprep ?

---

## Partie B — Déployer PC02

**B1.** Sur `PC01` (où l'ADK est installé), construis la mini-ISO `reponses-pc02.iso` qui contient le fichier de réponse et `postinstall.ps1`, puis copie-la sur l'hôte. Sous quel nom le fichier de réponse doit-il y figurer ?

**B2.** Crée `PC02` (Gen 2, TPM, 2 vCPU, 4 Go statiques, `vSwitch-Rennes`) avec **deux** lecteurs DVD : l'ISO officielle et la mini-ISO. Démarre-la. Combien de gestes faut-il ?

**B3.** Une fois l'écran de connexion affiché, vérifie : nom du poste, domaine, OU dans l'AD, BitLocker, applications installées, journal de post-installation.

**B4.** Sur un autre poste, la jonction au domaine a échoué mais l'installation est allée au bout. Où chercher la cause ?

---

## Partie C — Domaine et migration

**C1.** Depuis `SRV01`, vérifie que `PC02` est bien dans `OU=Ordinateurs,OU=Fournil` et qu'il est enregistré dans le DNS.

Préparation de la migration, à réaliser par chaque élève sous le compte d’administration du domaine. Sur SRV01 :

```powershell
New-Item C:\USMT\USMT,C:\USMT\Store -ItemType Directory -Force
icacls C:\USMT /inheritance:r
icacls C:\USMT /grant 'SYSTEM:(OI)(CI)F' 'FOURNIL\Admins du domaine:(OI)(CI)F'
New-SmbShare -Name 'USMT$' -Path C:\USMT -FullAccess 'FOURNIL\Admins du domaine'
```

Depuis PC01, dans une session d’**administration du domaine**. Si tu es resté en `PC01\admin` (compte local), ouvre d'abord l'accès au partage avec le compte du domaine, dans un Terminal administrateur :

```powershell
net use \\SRV01\USMT$ /user:FOURNIL\Administrateur Fournil2026!
```

> [!WARNING] Sans cette étape
> Un compte local n'a aucun droit sur le partage : la copie affiche une avalanche d'erreurs rouges « *Le nom d'utilisateur ou le mot de passe est incorrect* ».

```powershell
Copy-Item 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\User State Migration Tool\amd64\*' '\\SRV01\USMT$\USMT' -Recurse -Force
Test-Path '\\SRV01\USMT$\USMT\scanstate.exe'
```

Préparer quelques documents identifiables dans le profil de `stagiaire`, fermer sa session et effectuer capture/restauration depuis une session administrateur. **Avant la capture**, vider le cache de l'Optimisation de la distribution (`Delete-DeliveryOptimizationCache -Force`) et vérifier qu'il reste **au moins 10 Go libres** sur `C:` de PC01. Au premier essai, vérifier la liste des fichiers avant de capturer un gros profil. Le magasin doit rester petit pour ce TP ; le volume de données n’est pas un objectif d’évaluation.

**C2.** Sur `PC01`, capture le profil de `stagiaire` avec `scanstate` vers `\\SRV01\USMT$\Store\PC01`, en n'incluant que ce profil. Teste d'abord avec `/listfiles`.

**C3.** Le magasin fait plusieurs gigaoctets pour quelques documents. Pourquoi ? Que faire ?

**C4.** Sur `PC02`, restaure avec `loadstate`. Ouvre une session `stagiaire` et vérifie ses documents.

---

## Partie D — Choisir une méthode

**D1.** Pour chaque situation, propose une méthode de déploiement et justifie :
1. Le Fournil (35 postes, un DC, pas de Microsoft 365) renouvelle 10 postes par an.
2. Une chaîne de 200 boulangeries, Microsoft 365 Business Premium, des postes livrés directement en magasin.
3. Un groupe industriel avec ConfigMgr et 8 000 postes.
4. Un client dont le prestataire a monté WDS + MDT en 2019 et qui « veut juste continuer ».

**D2.** Que dirais-tu au client n° 4 sur l'état de WDS et MDT en 2026 ?

---

## Partie E — Exercices complémentaires (bonus)

**E1.** Récupère le *hash matériel* de `PC02` pour Autopilot. Que contient le fichier ? À qui l'envoie-t-on ?

**E2.** Tu dois déployer 10 postes avec le même support. Comment éviter qu'ils portent tous le nom `PC02` ?

---

## Partie F — L'ISO personnalisée avec une image maître (bonus)

**F1.** Copie le contenu de l'ISO officielle dans `D:\ISO-Deploiement`. Pourquoi `robocopy` plutôt que `Copy-Item` ?

**F2.** Remplace `sources\install.wim` par `MASTER.wim`. Quel obstacle rencontres-tu ?

**F3.** Construis `MASTER-Deploiement.iso` en BIOS + UEFI, **sans** le message « Press any key ». Quel risque cela crée-t-il ?

**F4.** *(Situation vécue sur le lab)* L'installation s'arrête sur « **Échec de l'installation de Windows 11** ». Comment lire les journaux de Setup sur ce poste ?

**F5.** Le journal contient `CAddUnattend::DoExecute: Failed to save copy of answer file to …\Panther\unattend-original.xml (0x80070050)`. Explique et corrige.

---


