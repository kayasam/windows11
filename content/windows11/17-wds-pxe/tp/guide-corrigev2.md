---
title: "TP 17. Déployer Windows 11 par le réseau : PXE et WDS, corrigé guidé (bonus)"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/17-wds-pxe"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/17-wds-pxe-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Ta mission.** Atelier complémentaire, sur `vSwitch-Rennes` avec `SRV01`, son DHCP et une VM vierge `PC03`. WDS sert au démarrage de WinPE. Windows Setup est lancé ensuite depuis un partage préparé pour le lab.

## Fichiers de l’atelier (bonus)

- Sur `SRV01`, télécharge <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/autounattend-iso-officielle.xml" download data-router-ignore>autounattend-iso-officielle.xml</a>, <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/Preparer-Fichier-Reponse.ps1" download data-router-ignore>Preparer-Fichier-Reponse.ps1</a> et <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/postinstall.ps1" download data-router-ignore>postinstall.ps1</a> dans un même dossier. En PowerShell, débloque le script avec `Unblock-File -LiteralPath .\Preparer-Fichier-Reponse.ps1`, puis lance `.\Preparer-Fichier-Reponse.ps1 -NomPoste PC03 -Sortie E:\Deploy\autounattend.xml` une fois le dossier `E:\Deploy` créé. Le XML préparé contient les identifiants du lab. Garde-le dans le partage du lab prévu pour cet atelier et retire-le du partage à la fin.
- Pour personnaliser le démarrage de WinPE, télécharge aussi <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/winpeshl.ini" download data-router-ignore>winpeshl.ini</a> et <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/deploiement.cmd" download data-router-ignore>deploiement.cmd</a>. Le script demande le mot de passe au démarrage de WinPE.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp/standard)

## Préparer le serveur PXE

### A1 — Préparer le volume de déploiement

Sur l’hôte, ajoute à `SRV01` un VHDX de 60 Go. Dans `SRV01`, identifie ce nouveau disque avant de l’initialiser, puis crée le volume NTFS `E:` nommé `Deploiement`.

> [!success]- Afficher la correction — A1
> `E:` est le volume dédié au lab. Les disques de Windows Server et d’Active Directory ne sont pas concernés.

### A2 — Installer le rôle et vérifier l’UEFI

Sur `SRV01`, installe le rôle **Services de déploiement Windows** avec les outils d’administration. Dans la console WDS, configure le serveur avec `E:\RemoteInstall`. Vérifie que `E:\RemoteInstall\Boot\x64\wdsmgfw.efi` est présent.

> [!success]- Afficher la correction — A2
> `RemoteInstall` contient les fichiers du service PXE, dont le chargeur UEFI x64. Si celui-ci manque, vérifie l’initialisation et l’état de WDS avant de travailler sur WinPE.

### A3 — Configurer la coexistence avec DHCP

Sur `SRV01`, dans les propriétés WDS, règle la coexistence avec le DHCP local selon le chapitre. Limite la réponse PXE au périmètre du lab et conserve une confirmation de démarrage pour les essais.

> [!success]- Afficher la correction — A3
> Le serveur DHCP garde son port et l’option 60 annonce le service PXE lorsque les deux rôles cohabitent sur ce serveur. Un poste du lab doit recevoir un bail puis trouver WDS. [Prise en charge du démarrage WDS](https://learn.microsoft.com/windows/deployment/wds-boot-support)

## Préparer WinPE et le partage

### B1 — Importer une image de démarrage

Sur `SRV01`, importe une **image de démarrage personnalisée** préparée pour le lab dans **WDS → Images de démarrage → Ajouter une image de démarrage**. Donne-lui un nom qui la distingue clairement de l’ISO officielle. Si tu réutilises le WinPE standard du TP 12, prévois de lancer Setup manuellement après son démarrage.

> [!success]- Afficher la correction — B1
> WDS doit lister une image de démarrage pour l’architecture de la VM. Le `boot.wim` officiel lancé en mode client WDS ne remplace pas cette image pour un déploiement Windows 11.

### B2 — Préparer et vérifier le partage SMB

Sur `SRV01`, copie le contenu de l’ISO dans `E:\Deploy\Windows11`, place le fichier de réponse de `PC03` dans `E:\Deploy` et prépare `Deploy$` avec lecture pour le compte de déploiement prévu par le formateur. Place le script de post-installation selon la méthode du chapitre. Depuis `PC01`, vérifie l’accès avec ce compte.

> [!success]- Afficher la correction — B2
> Le partage expose `autounattend.xml` et `Windows11\setup.exe` au compte dédié. Il doit pouvoir lire les fichiers nécessaires. La modification du contenu reste réservée aux administrateurs.

## Démarrer et diagnostiquer PC03

### C1 — Démarrer sur le réseau

Sur l’hôte, crée `PC03` vierge en génération 2, 4 Go statiques, 2 vCPU, 64 Go, TPM et carte sur `vSwitch-Rennes`. Place la carte réseau en tête au premier démarrage et réponds à l’invitation PXE de ta console.

> [!success]- Afficher la correction — C1
> La VM reçoit une adresse, contacte WDS et charge WinPE. Si elle s’arrête avant le choix de l’image, vérifie le rattachement au commutateur, le bail DHCP et la présence de l’image dans WDS.

### C2 — Lancer Setup et vérifier le résultat

Dans WinPE standard, lance `wpeinit` si l’initialisation réseau n’est pas terminée. Monte le partage avec `net use Z: \\SRV01\Deploy$ * /user:FOURNIL\svc.deploiement` ou le compte prévu, saisis le mot de passe à l’invite, puis lance `Z:\Windows11\setup.exe /unattend:Z:\autounattend.xml` sur la **VM vierge**. Après le premier démarrage, place le disque avant la carte réseau. Vérifie sur `SRV01` l’objet ordinateur et le DNS.

> [!success]- Afficher la correction — C2
> `PC03` apparaît sous **Fournil → Ordinateurs** et son nom se résout. Si WinPE est lancé mais que `Z:` n’est pas accessible, vérifie `ipconfig`, la résolution de `SRV01` puis les droits de lecture du compte avant de relancer Setup.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp/guide)
