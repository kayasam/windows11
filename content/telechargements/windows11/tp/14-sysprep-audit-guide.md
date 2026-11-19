# TP 14. Poste de référence : mode audit et Sysprep, version guidée (bonus)

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


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/tp/guide-corrigev2)
