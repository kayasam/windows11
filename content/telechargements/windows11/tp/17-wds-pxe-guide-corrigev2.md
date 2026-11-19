# TP 17. Déployer Windows 11 par le réseau : PXE et WDS, corrigé guidé (bonus)

**Ta mission.** Atelier complémentaire, sur `vSwitch-Rennes` avec `SRV01`, son DHCP et une VM vierge `PC03`. WDS sert au démarrage de WinPE. Windows Setup est lancé ensuite depuis un partage préparé pour le lab.

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
