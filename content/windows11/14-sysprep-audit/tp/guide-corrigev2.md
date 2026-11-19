---
title: "TP 13. Poste de référence : mode audit et Sysprep, corrigé guidé (bonus)"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/14-sysprep-audit"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/14-sysprep-audit-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Ta mission.** Atelier complémentaire. Prépare `MASTER` pour une capture réalisée au TP 14. Tu termines quand Sysprep a arrêté la VM et que son disque n’a pas redémarré.

## Fichiers de l’atelier (bonus)

- <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/autounattend-installation-master.xml" download data-router-ignore>autounattend-installation-master.xml</a> sert à installer `MASTER`. Utilise une copie nommée `autounattend.xml` à la racine de la mini-ISO.
- <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/autounattend-fournil-26h2.xml" download data-router-ignore>autounattend-fournil-26h2.xml</a> et <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/Preparer-Fichier-Reponse.ps1" download data-router-ignore>Preparer-Fichier-Reponse.ps1</a> servent à préparer le fichier de Sysprep. Télécharge les deux fichiers dans le même dossier. Sous Windows PowerShell, lance `.\Preparer-Fichier-Reponse.ps1 -Mode Reference` depuis ce dossier, puis saisis le mot de passe local du lab. Copie le fichier généré `autounattend.xml` vers `C:\Sysprep\autounattend.xml` dans `MASTER`. Utilise deux dossiers distincts pour les deux fichiers portant ce nom.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp/standard)

## Préparer MASTER

### A1 — Construire le support de réponse

Sur `PC01`, ouvre les outils ADK et prépare un dossier ne contenant que `autounattend-installation-master.xml` renommé `autounattend.xml`. Crée `unattend-master.iso` avec oscdimg, selon la méthode du cours. Monte-la sur l’hôte pour vérifier sa racine.

> [!success]- Afficher la correction — A1
> `autounattend.xml` est à la racine. Ce fichier prépare l’installation de la référence et contient le réglage de prévention du chiffrement automatique prévu par le lab.

### A2 — Installer la VM de référence

Sur l’hôte, crée `MASTER` en génération 2, avec 6 Go statiques, 2 vCPU, TPM et **Default Switch**. Monte l’ISO Windows sur le premier DVD et le support de réponse sur le second. Démarre l’installation jusqu’à l’écran du pays.

> [!success]- Afficher la correction — A2
> Les deux DVD sont présents et `MASTER` n’est pas jointe au domaine. Le Default Switch sert aux téléchargements pendant la préparation.

### A3 — Entrer en mode audit

Dans la console de `MASTER`, à l’écran du pays, appuie sur `Ctrl + Maj + F3`. Attends le redémarrage, puis ferme la fenêtre Sysprep sans lancer la généralisation.

> [!success]- Afficher la correction — A3
> Le bureau s’ouvre avec l’administrateur intégré. Le mode audit permet de préparer l’image avant l’accueil de son futur utilisateur.

### A4 — Confirmer que le volume peut être généralisé

Sur `MASTER`, lance `manage-bde -status C:` et relève le pourcentage chiffré avant de poursuivre.

> [!success]- Afficher la correction — A4
> Le volume de référence doit être déchiffré. Si un chiffrement est en cours ou déjà actif, fais vérifier le fichier de réponse d’installation et l’état du volume avant Sysprep.

### A5 — Installer et tracer le socle

Sur `MASTER`, installe 7-Zip et Notepad++ depuis la source `winget` avec la portée machine comme au TP 05. Crée `C:\Fournil\version-image.txt` avec une version de lab et la date.

> [!success]- Afficher la correction — A5
> Les applications sont listées dans `winget list`. Le fichier de version permettra de reconnaître l’image après capture.

## Généraliser puis arrêter

### B1 — Copier le fichier de réponse final

Depuis l’hôte, copie le fichier de référence personnalisé ci-dessus dans `C:\Sysprep\autounattend.xml` sur `MASTER` avec PowerShell Direct. Crée le dossier dans la VM si nécessaire. Vérifie la présence du fichier depuis `MASTER`.

> [!success]- Afficher la correction — B1
> Le fichier final sert à l’OOBE des postes issus de l’image. Il est distinct du fichier qui a installé `MASTER`. La copie doit être lisible à l’emplacement donné à Sysprep.

### B2 — Créer un point de retour

Sur l’hôte, crée le point de contrôle `Avant-Sysprep` après toutes les personnalisations. Repère-le dans le Gestionnaire Hyper-V.

> [!success]- Afficher la correction — B2
> Le point permet de revenir à la référence préparée si la généralisation échoue. Il doit précéder la commande Sysprep.

### B3 — Lancer Sysprep et lire l’issue

Sur `MASTER`, dans PowerShell administrateur, exécute `& "$env:WINDIR\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown /unattend:C:\Sysprep\autounattend.xml`. Si la VM reste allumée avec une erreur, ouvre `C:\Windows\System32\Sysprep\Panther\setuperr.log`.

> [!success]- Afficher la correction — B3
> Une réussite se termine par l’arrêt de la VM. En cas d’échec, relève d’abord le premier code et le nom exact du paquet, s’il est mentionné. Compare les paquets du profil et les paquets provisionnés avant de corriger.

### B4 — Remettre le disque prêt à capturer

Sur l’hôte, confirme que `MASTER` est arrêtée et relève `(Get-VMHardDiskDrive -VMName MASTER).Path`. Garde-la éteinte jusqu’à la capture.

> [!success]- Afficher la correction — B4
> Le chemin actif peut être un `.avhdx` en présence d’un point de contrôle. Un démarrage de `MASTER` consommerait l’OOBE préparé pour les postes issus de l’image.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp/guide)
