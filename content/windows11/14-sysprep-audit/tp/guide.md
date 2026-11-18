---
title: "TP 14. Poste de référence : mode audit et Sysprep, version guidée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/14-sysprep-audit"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/14-sysprep-audit-guide.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp/guide" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp/guide-corrigev2">Afficher les corrections</a></nav>

**Ta mission.** Atelier complémentaire. Prépare `MASTER` pour une capture réalisée au TP 15. Tu termines quand Sysprep a arrêté la VM et que son disque n’a pas redémarré.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp/standard)

## Préparer MASTER

### A1 — Construire le support de réponse

Sur `PC01`, ouvre les outils ADK et prépare un dossier ne contenant que `autounattend-installation-master.xml` renommé `autounattend.xml`. Crée `unattend-master.iso` avec oscdimg, selon la méthode du cours. Monte-la sur l’hôte pour vérifier sa racine.

### A2 — Installer la VM de référence

Sur l’hôte, crée `MASTER` en génération 2, avec 6 Go statiques, 2 vCPU, TPM et **Default Switch**. Monte l’ISO Windows sur le premier DVD et le support de réponse sur le second. Démarre l’installation jusqu’à l’écran du pays.

### A3 — Entrer en mode audit

Dans la console de `MASTER`, à l’écran du pays, appuie sur `Ctrl + Maj + F3`. Attends le redémarrage, puis ferme la fenêtre Sysprep sans lancer la généralisation.

### A4 — Confirmer que le volume peut être généralisé

Sur `MASTER`, lance `manage-bde -status C:` et relève le pourcentage chiffré avant de poursuivre.

### A5 — Installer et tracer le socle

Sur `MASTER`, installe 7-Zip et Notepad++ depuis la source `winget` avec la portée machine comme au TP 05. Crée `C:\Fournil\version-image.txt` avec une version de lab et la date.

## Généraliser puis arrêter

### B1 — Copier le fichier de réponse final

Depuis l’hôte, copie le fichier `autounattend-fournil-26h2.xml` dans `C:\Sysprep\autounattend.xml` sur `MASTER` avec PowerShell Direct. Crée le dossier dans la VM si nécessaire. Vérifie la présence du fichier depuis `MASTER`.

### B2 — Créer un point de retour

Sur l’hôte, crée le point de contrôle `Avant-Sysprep` après toutes les personnalisations. Repère-le dans le Gestionnaire Hyper-V.

### B3 — Lancer Sysprep et lire l’issue

Sur `MASTER`, dans PowerShell administrateur, exécute `& "$env:WINDIR\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown /unattend:C:\Sysprep\autounattend.xml`. Si la VM reste allumée avec une erreur, ouvre `C:\Windows\System32\Sysprep\Panther\setuperr.log`.

### B4 — Remettre le disque prêt à capturer

Sur l’hôte, confirme que `MASTER` est arrêtée et relève `(Get-VMHardDiskDrive -VMName MASTER).Path`. Garde-la éteinte jusqu’à la capture.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp/guide-corrigev2)
