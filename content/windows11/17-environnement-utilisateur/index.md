---
title: "18. Environnement utilisateur et Microsoft 365"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/17-environnement-utilisateur"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/17-environnement-utilisateur.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Préparer l'environnement de travail de l'utilisateur : comprendre et dépanner les **profils**, donner accès aux **dossiers partagés**, installer et configurer **Microsoft 365 Apps**, **OneDrive** et **Teams** sur le poste, gérer le **partage de documents**, puis **remettre** un poste à un utilisateur en l'accompagnant et en lui transmettant les bons réflexes de sécurité.
>
> **Outils :** `sysdm.cpl` (profils), `fsmgmt.msc`, Office Deployment Tool (`setup.exe /configure`), modèles ADMX OneDrive, Teams bootstrapper, Assistance rapide, application *Obtenir de l'aide*
> **Commandes à connaître :** `Get-CimInstance Win32_UserProfile`, `New-SmbShare`, `Get-SmbShareAccess`, `icacls`, `winget install Microsoft.Office`

> [!INFO] Fil rouge — Fournil
> `stagiaire` reçoit `PC02` : profil propre, lecteur `P:` (chapitre 11), données migrées (chapitre 16), OneDrive et Teams prêts, fiche de remise signée.

> [!NOTE] Lab sans tenant Microsoft 365
> Le lab n'a pas de tenant Microsoft 365. Tout ce qui est **côté poste** (installation, stratégies, fichiers de configuration) est pratiqué ; ce qui exige un compte professionnel (synchronisation réelle, réunions Teams) est présenté.

---

## 1. Les profils utilisateurs

Un **profil** = le dossier `C:\Users\<nom>` (documents, bureau, `AppData`) **+** la ruche de registre `NTUSER.DAT` (chargée en `HKCU` à l'ouverture de session). Il est créé à la **première** ouverture de session, à partir du profil **Default** (`C:\Users\Default`).

```powershell
Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special } |
    Select-Object LocalPath, SID, Loaded, RoamingConfigured, LastUseTime
```

Relevé sur `PC01` :

```
LocalPath               SID                                             Loaded RoamingConfigured
---------               ---                                             ------ -----------------
C:\Users\employe1       S-1-5-21-2996719152-1343562269-1905685070-1002   False             False
C:\Users\admin          S-1-5-21-2996719152-1343562269-1905685070-1000   False             False
C:\Users\Administrateur S-1-5-21-1698369327-3900126831-4215708287-500     True             False
C:\Users\stagiaire      S-1-5-21-1698369327-3900126831-4215708287-1101    True             False
```

Les deux familles de SID se voient : `…-1905685070-xxxx` = comptes **locaux** de `PC01`, `…-4215708287-xxxx` = comptes du **domaine** FOURNIL.

### Les types de profils

| Type | Où vivent les données | Usage 2026 |
|------|------------------------|------------|
| **Local** | Sur le poste | Cas standard, avec OneDrive pour les données |
| **Itinérant** (*roaming*) | Copié vers/depuis un partage à chaque session | Hérité, lent, fragile — à éviter |
| **Obligatoire** (`NTUSER.MAN`) | Partage, en lecture seule | Kiosques, salles de formation |
| **Dossiers redirigés** (GPO) | Documents/Bureau sur un partage | Encore courant sur site ; remplacé par OneDrive KFM |
| **FSLogix** (conteneur VHDX) | Profil complet dans un VHDX sur le réseau | Bureaux virtuels (AVD, RDS, Windows 365) |

### Dépanner un profil

| Symptôme | Cause / solution |
|----------|------------------|
| « *Connexion avec un profil temporaire* » | Profil corrompu ou verrouillé. Dans `HKLM\…\ProfileList`, une clé `SID.bak` en double ; renommer/supprimer la mauvaise, ou supprimer proprement le profil |
| Nouvel utilisateur avec des réglages bizarres | Le profil **Default** a été modifié (attention à `CopyProfile` dans le fichier de réponse) |
| Disque plein de vieux profils | **Paramètres système avancés → Profils des utilisateurs → Supprimer**, ou GPO *Supprimer les profils utilisateur plus anciens qu'un nombre spécifié de jours* |

> [!WARNING] Ne jamais supprimer un profil en effaçant le dossier
> Effacer `C:\Users\stagiaire` à la main laisse la clé `ProfileList` : la prochaine connexion produit un **profil temporaire**. Utiliser `sysdm.cpl` → Profils des utilisateurs, ou :
> ```powershell
> Get-CimInstance Win32_UserProfile | Where-Object LocalPath -eq "C:\Users\employe1" | Remove-CimInstance
> ```

---

## 2. Ressources et dossiers partagés

### Partage + NTFS : deux couches

![Accès réseau et permissions NTFS — Pour ouvrir un fichier via SMB, l’accès doit être autorisé par le partage et par NTFS. La combinaison la plus restrictive s’applique.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-18-permissions-smb-ntfs.svg)

Bonne pratique : partage **« Tout le monde : contrôle total »** (ou *Utilisateurs authentifiés : modifier*), et les vraies restrictions en **NTFS**, par **groupes** (jamais par utilisateur — modèle AGDLP de la formation AD).

```powershell
# Sur SRV01 (lab) : partage + NTFS pour G-Boulangerie
New-SmbShare -Name Commun -Path C:\Partages\Commun -ChangeAccess "FOURNIL\G-Boulangerie" -FullAccess "FOURNIL\Admins du domaine"
icacls C:\Partages\Commun /grant "FOURNIL\G-Boulangerie:(OI)(CI)M"
Get-SmbShareAccess -Name Commun
```

### Accéder aux ressources depuis le poste

| Méthode | Exemple |
|---------|---------|
| Chemin UNC | `\\SRV01\Commun` dans l'Explorateur |
| Lecteur réseau (manuel) | `New-PSDrive -Name P -PSProvider FileSystem -Root \\SRV01\Commun -Persist` ou `net use P: \\SRV01\Commun /persistent:yes` |
| Lecteur réseau (GPO) | Préférence *Mappages de lecteurs* (chapitre 11) — méthode d'entreprise |
| Raccourci / favori | Préférence *Raccourcis* |
| Imprimante partagée | Préférence *Imprimantes* ou *Déploiement d'imprimantes* (GPMC) |

> [!TIP] Énumération basée sur l'accès (ABE)
> Sur le serveur, `Set-SmbShare -Name Commun -FolderEnumerationMode AccessBased` : chaque utilisateur ne **voit** que les dossiers qu'il peut ouvrir. Moins d'appels au support (« je ne peux pas ouvrir Comptabilité »).

---

## 3. Microsoft 365 Apps sur le poste

**Microsoft 365 Apps** (Word, Excel, PowerPoint, Outlook…) s'installe en « Démarrer en un clic » (*Click-to-Run*) depuis le CDN de Microsoft, et se met à jour seul selon un **canal**.

| Canal | Rythme | Pour qui |
|-------|--------|----------|
| **Courant** (*Current*) | Mensuel, dès que prêt | Défaut grand public, petites entreprises |
| **Entreprise mensuel** (*Monthly Enterprise*) | 2ᵉ mardi du mois | Entreprises qui veulent un rythme prévisible |
| **Entreprise semestriel** (*Semi-Annual*) | Janvier / juillet | Postes sensibles (macros, compléments métiers) |

### Installer avec l'Office Deployment Tool (ODT)

```xml
<!-- configuration-fournil.xml — généré sur https://config.office.com -->
<Configuration>
  <Add OfficeClientEdition="64" Channel="MonthlyEnterprise">
    <Product ID="O365BusinessRetail">
      <Language ID="fr-fr" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
    </Product>
  </Add>
  <Updates Enabled="TRUE" />
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="SharedComputerLicensing" Value="0" />
  <RemoveMSI />
</Configuration>
```

```cmd
setup.exe /download configuration-fournil.xml     :: (optionnel) source locale sur un partage
setup.exe /configure configuration-fournil.xml    :: installation silencieuse
```

- `O365BusinessRetail` = Microsoft 365 Apps pour les entreprises (Business Standard/Premium) ; `O365ProPlusRetail` = Apps for enterprise (E3/E5).
- `RemoveMSI` désinstalle les anciennes versions MSI (Office 2016 et antérieures).
- **Teams n'est plus inclus** dans le paquet Microsoft 365 Apps : il s'installe à part (section 5).
- Alternative rapide : `winget install --id Microsoft.Office` (installe avec une configuration par défaut).
- Gestion centralisée : modèles ADMX Office (canal, mises à jour, macros), *Microsoft 365 Apps admin center*, Intune.

> [!NOTE] Pas d'Office dans l'image ?
> On peut l'inclure dans `MASTER` (ODT en mode audit), mais il faut alors le maintenir à jour à chaque rafraîchissement. Beaucoup d'organisations préfèrent l'installer **après** le déploiement (GPO de démarrage, Intune, script de post-installation) : l'utilisateur reçoit toujours la dernière version.

---

## 4. OneDrive et la synchronisation des données

OneDrive est **intégré à Windows 11** (relevé sur `PC01` : `C:\Users\<utilisateur>\AppData\Local\Microsoft\OneDrive\OneDrive.exe`, version 26.198 — installé **par utilisateur** à la première connexion).

### Les réglages qui comptent (GPO)

Les modèles ADMX sont livrés avec le client : `%LOCALAPPDATA%\Microsoft\OneDrive\<version>\adm\OneDrive.admx` (+ `fr\OneDrive.adml` — dossier **`fr`**, pas `fr-FR`, relevé sur le lab ; à renommer en `fr-FR` dans le magasin central) — à copier dans le **magasin central** (`\\ad.fournil.lab\SYSVOL\ad.fournil.lab\Policies\PolicyDefinitions`).

| Stratégie (libellés de l'ADMX OneDrive 26.198) | Effet |
|---|---|
| **Connecter silencieusement les utilisateurs à l'application de synchronisation OneDrive avec leurs informations d'identification Windows** | Pas de saisie : SSO avec le compte Entra (postes joints Entra/hybrides) |
| **Déplacer de manière silencieuse les dossiers connus de Windows vers OneDrive** (ID du tenant) | **KFM** : Bureau, Documents, Images basculent dans OneDrive, sauvegardés en continu |
| **Empêcher les utilisateurs de rediriger leurs dossiers connus de Windows vers leur PC** | Empêche de revenir en arrière |
| **Activer les Fichiers à la demande OneDrive** | Les fichiers n'occupent de la place que s'ils sont ouverts |
| **Autoriser la synchronisation des comptes OneDrive uniquement pour des organisations spécifiques** | Bloque OneDrive personnel / autres tenants (fuite de données) |

```powershell
# Vérifier ce qu'applique la GPO
Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\OneDrive
```

> [!TIP] OneDrive, le « nouvel USMT »
> Avec KFM, les données de l'utilisateur sont **déjà** dans le cloud : un poste neuf ou réinstallé les retrouve à la première connexion. C'est ce qui rend USMT inutile dans un environnement Microsoft 365 (chapitre 16).

---

## 5. Microsoft Teams

**Teams classique est retiré** (2024-2025). Le **nouveau Teams** est une application MSIX (`MSTeams`) — déjà **provisionnée** dans Windows 11 26H2 (relevé : `MSTeams 26276.513.5241.9675` sur `PC01`).

| Besoin | Méthode |
|--------|---------|
| Installer pour tous les utilisateurs d'un poste | `teamsbootstrapper.exe -p` (provisionnement machine) |
| Retirer | `teamsbootstrapper.exe -x` |
| Mettre à jour | Automatique (MSIX) ; `winget upgrade Microsoft.Teams` |
| Désactiver le démarrage automatique | Paramètres de Teams, ou Applications de démarrage (Gestionnaire des tâches) |

> [!NOTE] Teams Personnel vs Teams (travail ou école)
> Windows 11 Home/Pro grand public propose « Microsoft Teams (gratuit) ». En entreprise, on veut l'application **travail ou école** connectée au tenant. Les deux peuvent coexister ; l'icône « Conversation » de la barre des tâches de Windows 11 21H2 a disparu.

---

## 6. Partager des documents et gérer les accès

| Méthode | Avantage | Risque |
|---------|----------|--------|
| Pièce jointe par e-mail | Simple | Versions multiples, fuites, taille limitée |
| Partage de fichiers `\\serveur` | Contrôle NTFS fin, sur site | Inaccessible hors réseau/VPN |
| **Lien OneDrive / SharePoint** | Une seule version, coédition, révocable | Lien « Tout le monde » transféré sans contrôle |
| Équipe Teams | Fichiers dans SharePoint, conversation autour | Prolifération d'équipes |

Règles de base à enseigner aux utilisateurs :

- Partager avec des **personnes précises**, pas « toute personne disposant du lien » ;
- Mettre une **date d'expiration** aux liens externes ;
- Préférer **Lecture** à **Modification** ;
- Vérifier régulièrement **Gérer l'accès** sur les documents sensibles.

Côté administrateur : stratégies de partage du tenant (SharePoint admin center), étiquettes de sensibilité (Purview), rapports d'accès.

---

## 7. Remettre un poste à un utilisateur

### Avant la remise (check-list technicien)

| ✓ | Contrôle | Commande / outil |
|---|----------|------------------|
| ☐ | Poste nommé, joint au domaine, dans la bonne UO | `(Get-CimInstance Win32_ComputerSystem).Domain`, `gpresult /r` |
| ☐ | Windows à jour, logiciels à jour | Windows Update, `winget upgrade` |
| ☐ | BitLocker actif, clé dans AD | `Get-BitLockerVolume`, onglet Récupération BitLocker |
| ☐ | Defender actif, signatures récentes | `Get-MpComputerStatus` |
| ☐ | LAPS opérationnel | `Get-LapsADPassword` |
| ☐ | Données migrées (USMT / OneDrive) | Session test de l'utilisateur |
| ☐ | Lecteurs réseau, imprimantes | Session test |
| ☐ | Microsoft 365 activé, OneDrive synchronisé, Teams connecté | Session de l'utilisateur |
| ☐ | Inventaire mis à jour (GLPI…) | Numéro de série : `(Get-CimInstance Win32_BIOS).SerialNumber` |

### Pendant la remise : accompagner

- Première connexion **avec** l'utilisateur : changement de mot de passe, **Windows Hello** (code PIN, empreinte), MFA ;
- Montrer où sont ses fichiers (OneDrive, `P:`), comment imprimer, comment joindre le support ;
- Présenter **Obtenir de l'aide** (*Get Help*, qui remplace les anciens dépanneurs) et **Assistance rapide** (le support prend la main à distance, chapitre 12) ;
- Faire signer la **fiche de remise** (matériel, numéro de série, accessoires, charte informatique).

### Bonnes pratiques de sécurité à transmettre

| Réflexe | Pourquoi |
|---------|----------|
| `Win + L` dès qu'on quitte son poste | Session ouverte = identité usurpable |
| Windows Hello plutôt qu'un mot de passe tapé | Lié à l'appareil, résistant au hameçonnage |
| MFA partout, ne jamais valider une demande qu'on n'a pas initiée | Attaques par « fatigue MFA » |
| Signaler un e-mail douteux plutôt que cliquer | Hameçonnage = 1ʳᵉ cause d'intrusion |
| Pas de clé USB inconnue ; données pro dans OneDrive, pas sur clé | Malware, perte de données (BitLocker To Go si nécessaire) |
| Ne pas désactiver Defender ni les mises à jour | Défenses de base |

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> - **Profils** : `C:\Users\x` + `NTUSER.DAT` · local / itinérant / obligatoire / redirigé / FSLogix
>   - `Get-CimInstance Win32_UserProfile` · supprimer via `sysdm.cpl` ou `Remove-CimInstance` (jamais le dossier seul)
> - **Partages** : partage large + NTFS par groupes · `\\SRV01\Commun` · ABE · lecteurs par GPO
> - **Microsoft 365 Apps** : ODT `setup.exe /configure config.xml` (`config.office.com`) · canaux · Teams à part
> - **OneDrive** : intégré, par utilisateur · ADMX dans `AppData\…\adm` · SSO silencieux, KFM, Files `On-Demand`, tenants autorisés
> - **Teams** : nouveau Teams MSIX (MSTeams), `teamsbootstrapper -p` · classique retiré
> - **Partage** : liens nominatifs, expiration, lecture seule par défaut
> - **Remise** : check-list technique → session accompagnée (Hello, MFA, Get Help, Assistance rapide) → fiche signée
