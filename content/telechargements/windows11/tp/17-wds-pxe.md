# TP 17. Déployer Windows 11 par le réseau : PXE et WDS (bonus)

> [!abstract] Parcours TSSR — (bonus)
> Chapitre et TP entièrement (bonus). Le principe PXE/TFTP/SMB et le statut de WDS sont expliqués au chapitre 15. Construire le serveur WDS et PC03 ne conditionne aucun TP du socle.

> Chapitres associés : [17. Déployer Windows 11 par le réseau : PXE et WDS](https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/)

---

## Objectifs

- Installer et configurer WDS sur `SRV01`, qui porte déjà le DHCP
- Préparer une image de démarrage qui lance l'installation depuis un partage
- Déployer `PC03` **sans clic** en démarrant sur la carte réseau, avec le fichier de réponse du chapitre 15
- Diagnostiquer un démarrage PXE qui échoue

---

## Fichiers de l’atelier (bonus)

- Sur `SRV01`, télécharge <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/autounattend-iso-officielle.xml" download data-router-ignore>autounattend-iso-officielle.xml</a>, <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/Preparer-Fichier-Reponse.ps1" download data-router-ignore>Preparer-Fichier-Reponse.ps1</a> et <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/postinstall.ps1" download data-router-ignore>postinstall.ps1</a> dans un même dossier. En PowerShell, débloque le script avec `Unblock-File -LiteralPath .\Preparer-Fichier-Reponse.ps1`, puis lance `.\Preparer-Fichier-Reponse.ps1 -NomPoste PC03 -Sortie E:\Deploy\autounattend.xml` une fois le dossier `E:\Deploy` créé. Le XML préparé contient les identifiants du lab. Garde-le dans le partage du lab prévu pour cet atelier et retire-le du partage à la fin.
- Pour personnaliser le démarrage de WinPE, télécharge aussi <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/winpeshl.ini" download data-router-ignore>winpeshl.ini</a> et <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/deploiement.cmd" download data-router-ignore>deploiement.cmd</a>. Le script demande le mot de passe au démarrage de WinPE.

## Prérequis

- TP 15 réussi : `autounattend-iso-officielle.xml` et `postinstall.ps1` fonctionnent (dossier `Ressources/Fichier-reponse/`)
- Les fichiers WinPE téléchargés ci-dessus
- `SRV01` : contrôleur de domaine `ad.fournil.lab` avec DHCP actif (TP 10), OU `OU=Ordinateurs,OU=Fournil`
- ISO officielle Windows 11 26H2 dans `D:\ISO` sur l'hôte
- **70 Go libres** sur l'hôte (disque de données de `SRV01` + `PC03`)

---

## Partie A — Comprendre le démarrage réseau (bonus)

**A1.** Remets dans l'ordre ce qui se passe quand `PC03` démarre sur sa carte réseau, et indique le protocole de chaque étape : chargement de `boot.wim` · ouverture du partage `Deploy$` · obtention d'une adresse IP · téléchargement de `wdsmgfw.efi` · réponse du serveur PXE.

**A2.** En 2026, pourquoi n'importe-t-on **aucune image d'installation** dans WDS ? Qu'est-ce que WDS fait encore pour nous ?

**A3.** Le DHCP et WDS sont sur le même serveur. Quel conflit cela pose-t-il ? Comment le poste apprend-il qu'un serveur PXE existe ?

---

## Partie B — Préparer SRV01 et installer WDS (bonus)

**B1.** Ajoute à `SRV01` un second disque virtuel de 60 Go, formate-le en `E:` (label `Deploiement`), et insère l'ISO officielle dans son lecteur DVD.

**B2.** Installe le rôle WDS puis initialise-le avec le dossier `E:\RemoteInstall`. Vérifie que le chargeur UEFI est bien présent. Que faire s'il manque ?

**B3.** Configure WDS pour qu'il cohabite avec le DHCP, réponde à tous les postes et démarre sans appui sur F12. Vérifie la configuration.

**B4.** Pourquoi ces réglages de réponse seraient-ils dangereux en production ? Propose deux alternatives.

---

## Partie C — Accélérer TFTP (bonus)

**C1.** Règle la taille de bloc TFTP à 16384 et redémarre le service.

**C2.** Pourquoi ne pas mettre systématiquement la valeur la plus grande possible ?

---

## Partie D — L'image de démarrage (bonus)

**D1.** Copie `boot.wim` de l'ISO dans `E:\WinPE` et liste ses images. Laquelle WDS démarre-t-il ? Que se passe-t-il si on l'importe sans modification ?

**D2.** Lis `winpeshl.ini` et `deploiement.cmd`. À quoi sert `winpeshl.ini` ? Pourquoi `deploiement.cmd` commence-t-il par `wpeinit` ? Pourquoi `cmd.exe /k` plutôt que `/c` ?

**D3.** Injecte les deux fichiers dans la bonne image, puis importe le `boot.wim` dans WDS sous le nom `WinPE Fournil - déploiement réseau`.

**D4.** Un collègue propose de modifier directement le `.wim` qui se trouve dans `E:\RemoteInstall\Boot\x64\Images`, « c'est plus rapide ». Qu'en penses-tu ?

---

## Partie E — Le partage de déploiement (bonus)

**E1.** Crée le compte `svc.deploiement` (mot de passe `Fournil2026!`, n'expire jamais) dans `OU=Fournil`. Pourquoi un compte dédié plutôt que `Administrateur` ?

**E2.** Copie le contenu de l'ISO dans `E:\Deploy\Windows11`, et place à la racine de `E:\Deploy` un `autounattend.xml` pour `PC03`, construit à partir de `autounattend-iso-officielle.xml`. Combien de remplacements faut-il ?

**E3.** Comment `postinstall.ps1` arrive-t-il sur le poste, alors qu'il n'y a plus ni DVD ni clé ? Place-le au bon endroit.

**E4.** Partage `E:\Deploy` sous le nom `Deploy$`, en lecture pour `svc.deploiement`. Depuis `PC01`, vérifie que ce compte peut lire `autounattend.xml`.

---

## Partie F — Déployer PC03 (bonus)

**F1.** Crée `PC03` (Gen 2, TPM, 2 vCPU, 4 Go statiques, disque de 64 Go, `vSwitch-Rennes`, **aucun DVD**), avec la carte réseau en premier périphérique de démarrage. Démarre-la et observe les écrans successifs.

**F2.** Combien de temps entre le démarrage et l'écran de connexion final ? Combien de gestes ?

**F3.** Vérifie depuis `SRV01` : OU de `PC03` dans l'AD, enregistrement DNS, journal de post-installation, applications installées.

---

## Partie G — Dépannage (bonus)

**G1.** Un poste affiche « *A boot image was not found* » pour sa carte réseau. Cite trois causes possibles et où les vérifier.

**G2.** Un poste affiche « *La fonctionnalité du client des Services de déploiement Windows est partiellement déconseillée* », puis redémarre et recommence. Explique et corrige.

**G3.** Le poste démarre WinPE, mais l'invite affiche « Partage inaccessible ». Comment diagnostiquer sans redémarrer ?

---

## Partie H — Exercices complémentaires (bonus)

**H1.** Où voir, sur `SRV01`, qu'un poste a demandé un démarrage PXE sans obtenir d'image ?

**H2.** La carte réseau était le premier périphérique de démarrage de `PC03`, et WDS répond à tous les postes sans F12. Pourquoi `PC03` ne se réinstalle-t-il pas en boucle à chaque redémarrage ? Vérifie, puis cite un cas où la boucle se produirait.

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp/standard-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/17-wds-pxe/tp/standard-corrigev2)
