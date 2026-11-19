# TP 15. Déployer Windows 11 : ISO, réseau, migration, moderne, version guidée

**Ta mission.** Déploie `PC02` depuis l’ISO officielle et une petite ISO contenant le fichier de réponse. Tu travailleras sur `PC01` pour créer la mini-ISO, sur l’hôte pour démarrer la VM et sur `SRV01` pour vérifier le domaine. Prépare le domaine et le DHCP du TP 10, l’UO `Fournil → Ordinateurs` et les outils ADK du TP 12.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/16-deploiement/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp/standard)

## Lire et préparer le support

### A1 — Repérer les trois passes du fichier XML

Sur `PC01`, ouvre `autounattend-iso-officielle.xml` fourni. Retrouve `windowsPE`, `specialize` et `oobeSystem`. Pour chacune, associe une action prévue. En `specialize`, repère le domaine et l’UO de destination.

### A2 — Construire la mini-ISO sur PC01

Dans `C:\Images\reponses-pc02`, mets `postinstall.ps1` et une copie du fichier XML nommée `autounattend.xml`. Dans l’invite de déploiement ADK sur `PC01`, exécute `oscdimg -u2 -udfver102 -lREPONSES C:\Images\reponses-pc02 C:\Images\reponses-pc02.iso`. Transfère l’ISO sur l’hôte avec PowerShell Direct ou le moyen fourni.

## Déployer et vérifier PC02

### B1 — Démarrer la VM sur le bon DVD

Sur l’hôte, crée `PC02` en génération 2, avec TPM, deux vCPU, 4 Go statiques et `vSwitch-Rennes`. Attache l’ISO officielle au DVD de démarrage et la mini-ISO au second lecteur. Démarre et appuie une fois sur une touche à l’invitation du DVD.

### B2 — Contrôler la post-installation sur PC02

Ouvre une session autorisée sur `PC02`. Lance `hostname`, puis `Get-CimInstance Win32_ComputerSystem | Select-Object Domain,PartOfDomain`. Contrôle l’état BitLocker et cherche les applications attendues avec `winget list`. Ouvre `C:\Windows\Temp\postinstall.log`.

### B3 — Confirmer l’objet ordinateur et le DNS

Sur `SRV01`, vérifie `PC02` dans `dsa.msc` sous **Fournil → Ordinateurs**. Lance `Resolve-DnsName pc02.ad.fournil.lab` et compare l’adresse à celle relevée sur `PC02`.

## Migrer le profil utilisateur

### C1 — Capturer le profil de stagiaire

Sur `PC01`, crée un fichier reconnaissable dans **Documents** de `stagiaire` puis ferme sa session. Fais confirmer l’accès administrateur au partage `\\SRV01\USMT$` préparé selon le cours. Dans la procédure ScanState du chapitre, repère `/ui:FOURNIL\stagiaire` et les fichiers MigUser et MigApp. Exécute la capture vers `\\SRV01\USMT$\Store\PC01` et relève son code retour.

### C2 — Restaurer et vérifier côté utilisateur

Sur `PC02`, dans la session administrateur, utilise LoadState avec le même magasin et les mêmes fichiers XML de migration. Après succès, ouvre une session `FOURNIL\stagiaire` et recherche le document de test.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp/guide-corrigev2)
