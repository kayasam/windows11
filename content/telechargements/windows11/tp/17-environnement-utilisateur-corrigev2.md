# TP 17. Environnement utilisateur et Microsoft 365 — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h30

> Chapitres associés : [17. Environnement utilisateur et Microsoft 365](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/)

---

## Objectifs

- Inspecter et dépanner les profils utilisateurs
- Publier un dossier partagé avec les bonnes permissions
- Préparer l'installation de Microsoft 365 Apps et la configuration de OneDrive par stratégie
- Remettre `PC02` à `sguillard` avec une check-list et des conseils de sécurité

---

## Prérequis

- `PC02` déployé et joint au domaine (TP 16), `PC01` avec RSAT
- Partage `\\SRV01\Commun` et GPO `GPO-Boulangerie-Utilisateurs` (TP 11)

---

## Partie A — Profils (20 min)

**A1.** Sur `PC01`, liste les profils (hors profils système) avec leur SID et leur date de dernière utilisation. Comment distingue-t-on un compte local d'un compte du domaine ?

> [!success]- Afficher la correction — A1
> ```powershell
> Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special } |
>     Select-Object LocalPath, SID, Loaded, LastUseTime
> ```
> ```
> C:\Users\employe1       S-1-5-21-2996719152-1343562269-1905685070-1002   False
> C:\Users\admin          S-1-5-21-2996719152-1343562269-1905685070-1000   False
> C:\Users\Administrateur S-1-5-21-1698369327-3900126831-4215708287-500     True
> C:\Users\sguillard      S-1-5-21-1698369327-3900126831-4215708287-1101    True
> ```
> La partie centrale du SID identifie l'**autorité** : `…1905685070` = la machine `PC01` (comptes locaux), `…4215708287` = le domaine FOURNIL. `-500` = Administrateur (du domaine, ici), `-1101` = un compte créé dans AD.

**A2.** Où Windows enregistre-t-il l'association SID ↔ dossier de profil ?

> [!success]- Afficher la correction — A2
> `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\<SID>` → valeur `ProfileImagePath`.
> ```powershell
> Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Select-Object PSChildName, ProfileImagePath
> ```

**A3.** Un collègue a supprimé `C:\Users\employe1` dans l'Explorateur pour faire de la place. Qu'arrivera-t-il à `employe1` ? Comment supprimer proprement un profil ?

> [!success]- Afficher la correction — A3
> La clé `ProfileList` existe toujours et pointe vers un dossier absent : à sa prochaine connexion, `employe1` obtient un **profil temporaire** (rien n'est conservé à la déconnexion). Suppression propre :
> ```powershell
> Get-CimInstance Win32_UserProfile | Where-Object LocalPath -eq "C:\Users\employe1" | Remove-CimInstance
> ```
> ou **Paramètres système avancés (`sysdm.cpl`) → Profils des utilisateurs → Supprimer**. Réparation après coup : supprimer la clé `ProfileList\<SID>` correspondante.

**A4.** Un utilisateur obtient « *Connexion avec un profil temporaire* ». Quelles sont les causes possibles et la procédure de réparation ?

> [!success]- Afficher la correction — A4
> Causes : `NTUSER.DAT` corrompu ou verrouillé (antivirus, sauvegarde), dossier supprimé (A3), disque plein, droits NTFS cassés sur le profil.
> Procédure : sauvegarder les données de `C:\Users\<nom>` ; dans `ProfileList`, repérer le doublon `<SID>.bak` ; supprimer l'entrée défectueuse (ou retirer `.bak` de la bonne et remettre `State = 0`, `RefCount = 0`) ; redémarrer. En dernier recours, supprimer le profil et restaurer les données (ou laisser OneDrive les resynchroniser).

---

## Partie B — Dossiers partagés (20 min)

**B1.** Sur `SRV01`, crée `\\SRV01\Direction` : seuls les membres d'un nouveau groupe `G-Direction` peuvent y écrire, les autres utilisateurs du domaine ne doivent même pas le voir.

> [!success]- Afficher la correction — B1
> ```powershell
> New-ADGroup -Name G-Direction -GroupScope Global -Path "OU=Groupes,OU=Fournil,DC=ad,DC=fournil,DC=lab"
> New-Item C:\Partages\Direction -ItemType Directory
> # NTFS : on casse l'héritage, on garde Administrateurs + SYSTEM, on ajoute G-Direction en modification
> icacls C:\Partages\Direction /inheritance:r /grant "Administrateurs:(OI)(CI)F" "SYSTEM:(OI)(CI)F" "FOURNIL\G-Direction:(OI)(CI)M"
> New-SmbShare -Name Direction -Path C:\Partages\Direction -FullAccess "Utilisateurs authentifiés" -FolderEnumerationMode AccessBased
> ```
> `AccessBased` (ABE) : le partage n'apparaît pas aux non-membres quand ils parcourent `\\SRV01`.

**B2.** Vérifie les permissions de partage et les permissions NTFS. Laquelle s'applique quand elles diffèrent ?

> [!success]- Afficher la correction — B2
> ```powershell
> Get-SmbShareAccess -Name Direction
> icacls C:\Partages\Direction
> ```
> Pour un accès **par le réseau**, les deux s'appliquent et **la plus restrictive gagne**. En local (session sur le serveur), seul NTFS compte. D'où la convention : partage large, sécurité en NTFS.

**B3.** Depuis `PC01`, monte `\\SRV01\Commun` en `Q:` manuellement, de façon persistante, en PowerShell. Pourquoi ce n'est pas la bonne méthode à l'échelle du Fournil ?

> [!success]- Afficher la correction — B3
> ```powershell
> New-PSDrive -Name Q -PSProvider FileSystem -Root \\SRV01\Commun -Persist
> # ou : net use Q: \\SRV01\Commun /persistent:yes
> ```
> Poste par poste, utilisateur par utilisateur : impossible à maintenir sur 35 postes, rien n'est documenté, la lettre varie. À l'échelle : **préférence GPO** (chapitre 11), avec ciblage par groupe.

---

## Partie C — Microsoft 365 Apps, OneDrive, Teams (30 min)

**C1.** Écris le fichier `configuration-fournil.xml` de l'Office Deployment Tool : Microsoft 365 Apps pour les entreprises, 64 bits, français, canal Entreprise mensuel, sans Skype ni OneDrive Groove, installation silencieuse, suppression des anciens Office MSI.

> [!success]- Afficher la correction — C1
> ```xml
> <Configuration>
>   <Add OfficeClientEdition="64" Channel="MonthlyEnterprise">
>     <Product ID="O365BusinessRetail">
>       <Language ID="fr-fr" />
>       <ExcludeApp ID="Groove" />
>       <ExcludeApp ID="Lync" />
>     </Product>
>   </Add>
>   <Updates Enabled="TRUE" />
>   <Display Level="None" AcceptEULA="TRUE" />
>   <RemoveMSI />
> </Configuration>
> ```
> Le plus simple : le composer sur **config.office.com** (Office Customization Tool) et l'exporter.

**C2.** Quelle commande installe Office avec ce fichier ? Pourquoi Teams n'apparaîtra-t-il pas ?

> [!success]- Afficher la correction — C2
> ```cmd
> setup.exe /configure configuration-fournil.xml
> ```
> (`setup.exe` = l'ODT, téléchargé depuis Microsoft ou `winget install Microsoft.OfficeDeploymentTool`.) Depuis 2024, **Teams n'est plus inclus** dans les nouvelles installations de Microsoft 365 Apps : il se déploie séparément (C5).

**C3.** Où trouver les modèles ADMX de OneDrive sur `PC01` ? Copie-les dans le magasin central du domaine.

> [!success]- Afficher la correction — C3
> Relevé sur `PC01` : `C:\Users\admin\AppData\Local\Microsoft\OneDrive\26.198.1011.0006\adm\OneDrive.admx`, et la langue dans le sous-dossier **`fr`** (pas `fr-FR`).
> ```powershell
> $src = "C:\Users\admin\AppData\Local\Microsoft\OneDrive\26.198.1011.0006\adm"
> $pd  = "\\ad.fournil.lab\SYSVOL\ad.fournil.lab\Policies\PolicyDefinitions"
> New-Item "$pd\fr-FR" -ItemType Directory -Force
> Copy-Item "$src\OneDrive.admx" $pd
> Copy-Item "$src\fr\OneDrive.adml" "$pd\fr-FR\"
> ```
> Si le magasin central n'existe pas encore, le créer en copiant tout `C:\Windows\PolicyDefinitions` d'un poste 26H2.

**C4.** Crée une GPO `GPO-OneDrive` (ordinateurs) : connexion silencieuse, Fichiers à la demande, et **déplacement silencieux des dossiers connus** vers OneDrive. Quelle information manque pour la dernière stratégie dans le lab ?

> [!success]- Afficher la correction — C4
> *Configuration ordinateur → Stratégies → Modèles d'administration → OneDrive* :
> - **Connecter silencieusement les utilisateurs à l'application de synchronisation OneDrive avec leurs informations d'identification Windows** → Activé
> - **Activer les Fichiers à la demande OneDrive** → Activé
> - **Déplacer de manière silencieuse les dossiers connus de Windows vers OneDrive** → Activé, avec l'**ID du tenant** Microsoft 365
>
> Il manque justement l'**ID du tenant** (GUID visible dans le centre d'administration Entra) : le lab n'a pas de tenant. La GPO s'applique (clés sous `HKLM\SOFTWARE\Policies\Microsoft\OneDrive`) mais rien ne se passe tant qu'aucun compte professionnel n'est connecté. Le SSO silencieux exige en plus un poste **joint Entra ou hybride**.

**C5.** Le nouveau Teams est-il présent sur `PC02` sans rien faire ? Comment le vérifier ?

> [!success]- Afficher la correction — C5
> ```powershell
> Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq MSTeams
> Get-AppxPackage -AllUsers MSTeams | Select-Object Name, Version
> ```
> Oui : le nouveau Teams (`MSTeams`, version 26276.x relevée sur `PC01`) est **provisionné dans l'image** Windows 11 26H2 et donc dans `MASTER.wim`. Sur un poste qui ne l'a pas : `teamsbootstrapper.exe -p`.

---

## Partie D — Remise du poste (20 min)

**D1.** Exécute la check-list technique de remise sur `PC02` (domaine, mises à jour, BitLocker, Defender, LAPS, lecteurs, numéro de série).

> [!success]- Afficher la correction — D1
> ```powershell
> (Get-CimInstance Win32_ComputerSystem) | Select-Object Name, Domain
> gpresult /scope computer /r | Select-String "GPO-"
> Get-BitLockerVolume C: | Select-Object VolumeStatus, ProtectionStatus
> Get-MpComputerStatus | Select-Object RealTimeProtectionEnabled, AntivirusSignatureAge
> Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
> (Get-CimInstance Win32_BIOS).SerialNumber
> Get-Content C:\Fournil\version-image.txt
> ```
> Sur un PC02 issu de `MASTER.wim` : `PreventDeviceEncryption` étant capturé dans l'image, BitLocker est **désactivé** → l'activer (TP 09) et sauvegarder la clé dans AD (TP 11) **avant** la remise.

**D2.** Rédige les 5 conseils de sécurité que tu donnes oralement à `sguillard` le jour de la remise.

> [!success]- Afficher la correction — D2
> 1. `Win + L` à chaque fois que tu quittes ton poste.
> 2. Configure Windows Hello (code PIN ou empreinte) : plus besoin de taper ton mot de passe devant quelqu'un.
> 3. N'accepte **jamais** une demande d'authentification (MFA) que tu n'as pas déclenchée — appelle le support.
> 4. Un e-mail qui presse, menace ou promet : ne clique pas, transfère-le au support.
> 5. Tes fichiers de travail vont dans OneDrive ou `P:`, jamais sur une clé USB ou une messagerie personnelle.

**D3.** `sguillard` appelle le support : il ne retrouve pas son fichier. Quels outils proposes-tu pour que le technicien voie son écran ?

> [!success]- Afficher la correction — D3
> - **Assistance rapide** (intégrée, code à 6 chiffres, compte Microsoft/pro requis côté technicien) ;
> - **Remote Help** (Intune, journalisée, intégrée aux rôles RBAC — version entreprise d'Assistance rapide) ;
> - **mstsc /shadow** (RDP, sur postes du domaine, avec GPO autorisant le contrôle à distance) ;
> - en premier recours pour l'utilisateur seul : l'application **Obtenir de l'aide**, et l'**historique des versions** de OneDrive pour retrouver un fichier.

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp)
