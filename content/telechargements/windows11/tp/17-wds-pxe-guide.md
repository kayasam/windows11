# TP 17. Déployer Windows 11 par le réseau : PXE et WDS, version guidée (bonus)

**Ta mission.** Atelier complémentaire, sur `vSwitch-Rennes` avec `SRV01`, son DHCP et une VM vierge `PC03`. WDS sert au démarrage de WinPE. Windows Setup est lancé ensuite depuis un partage préparé pour le lab.

## Fichiers de l’atelier (bonus)

- Sur `SRV01`, télécharge <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/autounattend-iso-officielle.xml" download data-router-ignore>autounattend-iso-officielle.xml</a>, <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/Preparer-Fichier-Reponse.ps1" download data-router-ignore>Preparer-Fichier-Reponse.ps1</a> et <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/postinstall.ps1" download data-router-ignore>postinstall.ps1</a> dans un même dossier. En PowerShell, débloque le script avec `Unblock-File -LiteralPath .\Preparer-Fichier-Reponse.ps1`, puis lance `.\Preparer-Fichier-Reponse.ps1 -NomPoste PC03 -Sortie E:\Deploy\autounattend.xml` une fois le dossier `E:\Deploy` créé. Le XML préparé contient les identifiants du lab. Garde-le dans le partage du lab prévu pour cet atelier et retire-le du partage à la fin.
- Pour personnaliser le démarrage de WinPE, télécharge aussi <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/winpeshl.ini" download data-router-ignore>winpeshl.ini</a> et <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/deploiement.cmd" download data-router-ignore>deploiement.cmd</a>. Le script demande le mot de passe au démarrage de WinPE.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp/standard)

## Préparer le serveur PXE

### A1 — Préparer le volume de déploiement

Sur l’hôte, ajoute à `SRV01` un VHDX de 60 Go. Dans `SRV01`, identifie ce nouveau disque avant de l’initialiser, puis crée le volume NTFS `E:` nommé `Deploiement`.

### A2 — Installer le rôle et vérifier l’UEFI

Sur `SRV01`, installe le rôle **Services de déploiement Windows** avec les outils d’administration. Dans la console WDS, configure le serveur avec `E:\RemoteInstall`. Vérifie que `E:\RemoteInstall\Boot\x64\wdsmgfw.efi` est présent.

### A3 — Configurer la coexistence avec DHCP

Sur `SRV01`, dans les propriétés WDS, règle la coexistence avec le DHCP local selon le chapitre. Limite la réponse PXE au périmètre du lab et conserve une confirmation de démarrage pour les essais.

## Préparer WinPE et le partage

### B1 — Importer une image de démarrage

Sur `SRV01`, importe une **image de démarrage personnalisée** préparée pour le lab dans **WDS → Images de démarrage → Ajouter une image de démarrage**. Donne-lui un nom qui la distingue clairement de l’ISO officielle. Si tu réutilises le WinPE standard du TP 13, prévois de lancer Setup manuellement après son démarrage.

### B2 — Préparer et vérifier le partage SMB

Sur `SRV01`, copie le contenu de l’ISO dans `E:\Deploy\Windows11`, place le fichier de réponse de `PC03` dans `E:\Deploy` et prépare `Deploy$` avec lecture pour le compte de déploiement prévu par le formateur. Place le script de post-installation selon la méthode du chapitre. Depuis `PC01`, vérifie l’accès avec ce compte.

## Démarrer et diagnostiquer PC03

### C1 — Démarrer sur le réseau

Sur l’hôte, crée `PC03` vierge en génération 2, 4 Go statiques, 2 vCPU, 64 Go, TPM et carte sur `vSwitch-Rennes`. Place la carte réseau en tête au premier démarrage et réponds à l’invitation PXE de ta console.

### C2 — Lancer Setup et vérifier le résultat

Dans WinPE standard, lance `wpeinit` si l’initialisation réseau n’est pas terminée. Monte le partage avec `net use Z: \\SRV01\Deploy$ * /user:FOURNIL\svc.deploiement` ou le compte prévu, saisis le mot de passe à l’invite, puis lance `Z:\Windows11\setup.exe /unattend:Z:\autounattend.xml` sur la **VM vierge**. Après le premier démarrage, place le disque avant la carte réseau. Vérifie sur `SRV01` l’objet ordinateur et le DNS.


