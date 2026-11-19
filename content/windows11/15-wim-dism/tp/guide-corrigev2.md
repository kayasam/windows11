---
title: "TP 14. Images WIM et DISM, corrigé guidé"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/15-wim-dism"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/15-wim-dism/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/15-wim-dism/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/15-wim-dism-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/15-wim-dism/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/15-wim-dism/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Ta mission.** La partie principale se fait sur `PC01` avec `C:\Images\install.wim` du TP 12. Si `MASTER` est prête, poursuis l’atelier complémentaire sur l’hôte.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/15-wim-dism/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/15-wim-dism/tp/standard)

## Inspecter l’image officielle

### A1 — Trouver l’index de Windows Professionnel

Sur `PC01`, dans PowerShell administrateur, lance `dism /Get-WimInfo /WimFile:C:\Images\install.wim`. Note l’index dont le nom correspond à Windows 11 Professionnel et relance avec `/Index:N` en remplaçant `N`.

> [!success]- Afficher la correction — A1
> La seconde sortie confirme l’édition et l’architecture. L’index dépend du contenu du WIM. Relève-le sur l’ISO utilisée au lieu de réutiliser celui d’un autre support.

### A2 — Monter en lecture seule puis libérer le dossier (bonus)

Crée un dossier vide `C:\Mount`. Monte l’index relevé avec `dism /Mount-Image /ImageFile:C:\Images\install.wim /Index:N /MountDir:C:\Mount /ReadOnly`. Vérifie `C:\Mount\Windows\System32`, ferme l’Explorateur sur ce dossier, puis lance `dism /Unmount-Image /MountDir:C:\Mount /Discard`.

> [!success]- Afficher la correction — A2
> Le dossier Windows est lisible sans démarrer l’image. `dism /Get-MountedImageInfo` ne doit plus lister `C:\Mount` après démontage.

## Atelier complémentaire. Capturer la référence (bonus)

### B1 — Identifier le disque actif de MASTER

Sur l’hôte, vérifie que `MASTER` est arrêtée. Lance `Get-VMHardDiskDrive -VMName MASTER` et relève le chemin du disque système.

> [!success]- Afficher la correction — B1
> En présence d’un point de contrôle, le disque actif peut être un `.avhdx`. Son parent seul ne représente pas l’état préparé au TP 13.

### B2 — Monter le disque sans le modifier

Sur l’hôte, monte le chemin actif en lecture seule avec `Mount-VHD -Path $vhdPath -ReadOnly -Passthru | Get-Disk | Get-Partition` après avoir affecté le chemin relevé à `$vhdPath`. Repère la lettre du volume Windows et vérifie la présence du fichier `Fournil\version-image.txt`.

> [!success]- Afficher la correction — B2
> La lettre appartient au volume monté, pas au système de l’hôte. Si aucune lettre n’est visible, vérifie le volume et la procédure du chapitre avant de lancer la capture.

### B3 — Capturer et vérifier le WIM

Sur l’hôte, crée `D:\Images`. Si la lettre du volume monté est `M:`, lance `dism /Capture-Image /ImageFile:D:\Images\MASTER.wim /CaptureDir:M:\ /Name:MASTER-Fournil /Compress:max /CheckIntegrity`. Adapte la lettre puis contrôle avec `dism /Get-WimInfo /WimFile:D:\Images\MASTER.wim`.

> [!success]- Afficher la correction — B3
> Le WIM contient l’image `MASTER-Fournil`. Une erreur au démarrage de la capture invite à vérifier la lettre, l’espace libre et les droits sur le dossier de destination.

### B4 — Démonter proprement le disque

Sur l’hôte, ferme toute fenêtre ouverte sur le volume puis lance `Dismount-VHD -Path $vhdPath`. Vérifie que `MASTER` est toujours arrêtée.

> [!success]- Afficher la correction — B4
> La capture n’a pas écrit sur le disque monté en lecture seule. L’hôte peut libérer le VHDX ou l’AVHDX sans supprimer le point de contrôle.

### B5 — Préparer les fragments pour FAT32

Si `MASTER.wim` dépasse 4 Gio et doit être copié sur FAT32, utilise `dism /Split-Image /ImageFile:D:\Images\MASTER.wim /SWMFile:D:\Images\MASTER.swm /FileSize:3800`. Regroupe les fragments dans le même dossier.

> [!success]- Afficher la correction — B5
> DISM produit `MASTER.swm`, puis `MASTER2.swm` si nécessaire. Les morceaux doivent rester ensemble, et le WIM d’origine reste disponible pour la maintenance.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/15-wim-dism/tp/guide)
