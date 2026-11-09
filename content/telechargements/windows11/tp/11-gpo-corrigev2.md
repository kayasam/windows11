# TP 11. Stratégies de groupe et gestion centralisée — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 2h

> Chapitres associés : [11. Stratégies de groupe et gestion centralisée](https://cours.kaya.ovh/windows11/windows11/11-gpo/)

---

## Objectifs

- Administrer les GPO depuis `PC01` (RSAT)
- Créer une GPO **ordinateur** de sécurité : admins locaux, Windows LAPS, BitLocker → AD, anneau Windows Update
- Créer une GPO **utilisateur** filtrée sur un groupe : lecteur réseau et restriction
- Diagnostiquer avec `gpresult`

---

## Prérequis

- `SRV01` contrôleur de domaine, `PC01` joint dans `OU=Ordinateurs,OU=Fournil` (TP 10)
- BitLocker actif sur `PC01` avec une clé de récupération (TP 09)
- Session sur `PC01` avec un compte membre de *Admins du domaine* pour ce TP

---

## Partie A — Outils (15 min)

**A1.** Installe sur `PC01` la console GPMC et les outils AD (RSAT). Combien de temps cela prend-il, et pourquoi ?

> [!success]- Afficher la correction — A1
> ```powershell
> Add-WindowsCapability -Online -Name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
> Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
> ```
> Plusieurs minutes chacune : ce sont des **Features on Demand** téléchargées depuis Windows Update. Ne pas redémarrer le poste pendant ce temps — vécu sur le lab : un redémarrage en cours d'installation fait échouer l'opération, à relancer.

**A2.** Ouvre `gpmc.msc`. Quelles GPO existent déjà ? Où sont-elles liées ?

> [!success]- Afficher la correction — A2
> Sur un domaine neuf : **Default Domain Policy** (liée au domaine : stratégie de mots de passe, de verrouillage, Kerberos) et **Default Domain Controllers Policy** (liée à l'UO *Domain Controllers* : droits sur les DC, audit).

**A3.** Où sont stockées physiquement les GPO ? Retrouve le dossier de la *Default Domain Policy*.

> [!success]- Afficher la correction — A3
> - Objet AD : `CN={31B2F340-016D-11D2-945F-00C04FB984F9},CN=Policies,CN=System,DC=ad,DC=fournil,DC=lab` (GUID fixe de la *Default Domain Policy*).
> - Fichiers : `\\ad.fournil.lab\SYSVOL\ad.fournil.lab\Policies\{31B2F340-016D-11D2-945F-00C04FB984F9}\` (`GPT.INI`, `Machine\`, `User\`).
> Les deux portent un **numéro de version** : un poste ne retraite une GPO que si ce numéro a changé (sauf `gpupdate /force`).

---

## Partie B — GPO ordinateur « GPO-Postes-Securite » (45 min)

**B1.** Crée la GPO `GPO-Postes-Securite` et lie-la à `OU=Ordinateurs,OU=Fournil`.

> [!success]- Afficher la correction — B1
> GPMC : clic droit sur `OU=Ordinateurs` → **Créer un objet GPO dans ce domaine, et le lier ici**.
> ```powershell
> New-GPO -Name "GPO-Postes-Securite" | New-GPLink -Target "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"
> ```

**B2.** Fais en sorte que `FOURNIL\GG-Admins-Postes` soit administrateur local de tous les postes de l'UO. Deux méthodes possibles : lesquelles ? Choisis-en une.

> [!success]- Afficher la correction — B2
> - **Groupes restreints** : *Configuration ordinateur → Stratégies → Paramètres Windows → Paramètres de sécurité → Groupes restreints* → Ajouter `FOURNIL\GG-Admins-Postes` → section **« Ce groupe est membre de »** → `Administrateurs`. (Ne **pas** utiliser la section « Membres de ce groupe » sur *Administrateurs* : elle **remplace** toute la liste et peut retirer l'admin local de secours.)
> - **Préférences** : *Configuration ordinateur → Préférences → Paramètres du Panneau de configuration → Utilisateurs et groupes locaux* → Nouveau groupe local → `Administrateurs (intégré)`, action *Mettre à jour*, ajouter le membre.
>
> Le lab utilise la première méthode.

**B3.** Prépare le domaine pour **Windows LAPS**, puis configure la GPO : sauvegarde dans AD, 14 caractères, 30 jours.

> [!success]- Afficher la correction — B3
> Sur un DC (module `LAPS` intégré à Windows Server 2025) :
> ```powershell
> Update-LapsADSchema
> Set-LapsADComputerSelfPermission -Identity "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"
> ```
> GPO : *Configuration ordinateur → Stratégies → Modèles d'administration → Système → LAPS* :
> - **Configurer le répertoire de sauvegarde des mots de passe** → Activé → *Active Directory*
> - **Paramètres de mot de passe** → longueur 14, âge 30 jours
>
> (En PowerShell : `Set-GPRegistryValue … -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\LAPS" -ValueName BackupDirectory -Value 2`, `PasswordLength 14`, `PasswordAgeDays 30`.)

**B4.** Configure la sauvegarde des clés de récupération BitLocker du disque système dans AD DS.

> [!success]- Afficher la correction — B4
> *Composants Windows → Chiffrement de lecteur BitLocker → Lecteurs du système d'exploitation → **Sélectionner la méthode de récupération des lecteurs du système d'exploitation protégés par BitLocker*** → Activé :
> - *Enregistrer les informations de récupération dans AD DS* : mots de passe et packages de clés
> - *Ne pas activer BitLocker tant que les informations de récupération ne sont pas stockées dans AD DS* : coché

**B5.** Ajoute un report de **7 jours** des mises à jour qualité (anneau « large »).

> [!success]- Afficher la correction — B5
> *Composants Windows → Windows Update → Gérer les mises à jour proposées de Windows Update → **Choisir quand recevoir les mises à jour qualité*** → Activé, **7** jours.

**B6.** Applique sur `PC01` et vérifie **chacun** des quatre réglages.

> [!success]- Afficher la correction — B6
> ```powershell
> gpupdate /target:computer /force
> gpresult /scope computer /r          # GPO-Postes-Securite dans « Objets Stratégie de groupe appliqués »
> ```
> 1. **Admins locaux** :
> ```powershell
> Get-LocalGroupMember Administrateurs
> ```
> ```
> FOURNIL\Admins du domaine ActiveDirectory
> FOURNIL\GG-Admins-Postes  ActiveDirectory
> PC01\admin                Local
> PC01\Administrateur       Local
> ```
> 2. **LAPS** — journal *Microsoft-Windows-LAPS/Operational* : 10018 « LAPS a mis à jour Active Directory avec le nouveau mot de passe », 10020. Puis sur un poste avec RSAT :
> ```powershell
> Get-LapsADPassword -Identity PC01 -AsPlainText
> ```
> ```
> ComputerName        : PC01
> Account             : Administrateur
> Password            : +X+]3A,&#3X;rj
> PasswordUpdateTime  : 08/11/2026 07:15:06
> ExpirationTimestamp : 08/12/2026 07:15:06
> ```
> 3. **Windows Update** :
> ```powershell
> Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate | Select-Object DeferQualityUpdates*
> # DeferQualityUpdates : 1 / DeferQualityUpdatesPeriodInDays : 7
> ```
> 4. **BitLocker** : voir B7.

**B7.** La clé BitLocker n'apparaît pas dans AD. Pourquoi ? Corrige.

> [!success]- Afficher la correction — B7
> La GPO ne concerne que les protecteurs **créés après** son application. Le protecteur de `PC01` date du TP 09. On l'envoie à la main :
> ```powershell
> $kp = (Get-BitLockerVolume C:).KeyProtector | Where-Object KeyProtectorType -eq RecoveryPassword
> Backup-BitLockerKeyProtector -MountPoint C: -KeyProtectorId $kp.KeyProtectorId
> ```
> Vérification sur `SRV01` :
> ```powershell
> Get-ADObject -Filter "objectClass -eq 'msFVE-RecoveryInformation'" -SearchBase (Get-ADComputer PC01).DistinguishedName -Properties msFVE-RecoveryPassword
> ```
> ```
> Name                   : 2026-11-08T07:02:39+01:00{C41E3312-A988-4435-80C0-D765E10FB5B9}
> msFVE-RecoveryPassword : 354739-124608-622754-706079-676819-067672-347611-326205
> ```
> (Onglet **Récupération BitLocker** de l'objet ordinateur dans *Utilisateurs et ordinateurs Active Directory*, avec la fonctionnalité *Visionneuse de mots de passe de récupération BitLocker*.)

**B8.** Le mot de passe LAPS est bien dans AD… mais un technicien ne peut pas s'en servir pour ouvrir une session. Pourquoi ?

> [!success]- Afficher la correction — B8
> LAPS gère par défaut le compte **RID 500** (`Administrateur`), qui est **désactivé** sur Windows 11. Le mot de passe change bien, mais le compte reste inutilisable. Solutions :
> - activer le compte `Administrateur` (par GPO : *Options de sécurité → Comptes : état du compte Administrateur*) ;
> - ou faire gérer un autre compte (paramètre **Nom du compte administrateur à gérer**) ; depuis 24H2, **Configurer la gestion automatique des comptes** permet à LAPS de créer ce compte lui-même.

---

## Partie C — GPO utilisateur filtrée (35 min)

Sur `SRV01`, un partage `\\SRV01\Commun` est accessible en modification au groupe `G-Boulangerie`.

**C1.** Crée la GPO `GPO-Boulangerie-Utilisateurs`, liée à `OU=Utilisateurs,OU=Fournil`.

> [!success]- Afficher la correction — C1
> ```powershell
> New-GPO -Name "GPO-Boulangerie-Utilisateurs" | New-GPLink -Target "OU=Utilisateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"
> ```

**C2.** Ajoute une **préférence** qui monte `\\SRV01\Commun` en `P:`, nommé « Commun ». Pourquoi une préférence et pas une stratégie ?

> [!success]- Afficher la correction — C2
> *Configuration utilisateur → Préférences → Paramètres Windows → Mappages de lecteurs* → Nouveau → Lecteur mappé :
> - Action : **Mettre à jour** · Emplacement : `\\SRV01\Commun` · Libellé : `Commun` · Lettre : **P** · Reconnecter : coché
>
> Il n'existe **pas** de *stratégie* « mapper un lecteur » : c'est une préférence (comme les imprimantes, les raccourcis). Avantage : le **ciblage au niveau de l'élément** (onglet Commun) permet de ne monter `P:` que pour un groupe, sans créer une GPO par lecteur.

**C3.** Ajoute la stratégie « Interdire l'accès au Panneau de configuration et à l'application Paramètres du PC ».

> [!success]- Afficher la correction — C3
> *Configuration utilisateur → Stratégies → Modèles d'administration → Panneau de configuration → **Interdire l'accès au Panneau de configuration et à l'application Paramètres du PC*** → Activé (registre : `HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoControlPanel = 1`).

**C4.** Restreins la GPO aux membres de `G-Boulangerie`. Quelle erreur classique faut-il éviter ?

> [!success]- Afficher la correction — C4
> ```powershell
> Set-GPPermission -Name "GPO-Boulangerie-Utilisateurs" -TargetName "Utilisateurs authentifiés" -TargetType Group -PermissionLevel GpoRead -Replace
> Set-GPPermission -Name "GPO-Boulangerie-Utilisateurs" -TargetName "G-Boulangerie" -TargetType Group -PermissionLevel GpoApply
> Get-GPPermission -Name "GPO-Boulangerie-Utilisateurs" -All | Select-Object @{N='Qui';E={$_.Trustee.Name}}, Permission
> ```
> ```
> G-Boulangerie                                  GpoApply
> Utilisateurs authentifiés                       GpoRead
> Admins du domaine          GpoEditDeleteModifySecurity
> ...
> ```
> **Erreur classique** : supprimer *Utilisateurs authentifiés* de l'onglet « Filtrage de sécurité » de GPMC. Depuis MS16-072, le poste lit la GPO avec son **compte ordinateur** ; sans droit de lecture, la GPO n'est plus appliquée à personne. Il faut lui laisser **Lire** (onglet **Délégation** → Avancé).

**C5.** Ouvre une session `FOURNIL\stagiaire` sur `PC01`. Vérifie le lecteur `P:` et la restriction.

> [!success]- Afficher la correction — C5
> ![w11-11-lecteur-p-gpo](https://cours.kaya.ovh/windows11/assets/captures/w11-11-lecteur-p-gpo.png)
>
> **Commun (P:)** apparaît dans *Emplacements réseau*. `Win + I` (Paramètres) ne s'ouvre pas : message « *Cette opération a été annulée en raison des restrictions en vigueur sur cet ordinateur* ».
> ```powershell
> gpresult /user stagiaire /scope user /r
> ```
> ```
> Objets Stratégie de groupe appliqués
>     GPO-Boulangerie-Utilisateurs
> ```

**C6.** Crée un utilisateur `test.vendeur` dans `OU=Utilisateurs`, **hors** de `G-Boulangerie`. Que reçoit-il ?

> [!success]- Afficher la correction — C6
> `test.vendeur` est bien dans l'UO, mais n'a pas le droit **Appliquer** : `gpresult` liste `GPO-Boulangerie-Utilisateurs` dans **« Les objets stratégie de groupe n'ont pas été appliqués car ils ont été refusés — Filtrage : refusé (sécurité) »**. Pas de lecteur `P:`, Panneau de configuration accessible.

---

## Partie D — Diagnostic (15 min)

**D1.** Avec `gpresult`, affiche les GPO ordinateur puis utilisateur appliquées sur `PC01`. Produis aussi un rapport HTML.

> [!success]- Afficher la correction — D1
> ```powershell
> gpresult /scope computer /r
> gpresult /scope user /r
> gpresult /h C:\Temp\rsop-pc01.html
> Start-Process C:\Temp\rsop-pc01.html
> ```
> Le rapport HTML détaille chaque paramètre et **la GPO gagnante** (*GPO gagnante* pour chaque réglage), ainsi que les GPO refusées et pourquoi.

**D2.** Un collègue a déplacé `PC01` dans `CN=Computers` par erreur. Que montre `gpresult` ? Pourquoi ?

> [!success]- Afficher la correction — D2
> `gpresult /scope computer /r` n'affiche plus que la **Default Domain Policy** : `GPO-Postes-Securite` est liée à l'UO `Ordinateurs`, que le poste a quittée. `CN=Computers` est un conteneur, pas une UO : on ne peut rien y lier. Les réglages déjà appliqués restent en partie (tatouage des préférences, groupes restreints) mais ne sont plus maintenus. D'où `redircmp` (TP 10).

**D3.** Où chercher si une GPO ne s'applique pas du tout (aucune trace) ?

> [!success]- Afficher la correction — D3
> Journal **Applications et services → Microsoft → Windows → GroupPolicy → Operational** (début/fin de traitement, DC contacté, durée, erreurs SYSVOL), et le journal **Système** (source *GroupPolicy*, ID 1058/1030 : SYSVOL ou DNS inaccessible). Vérifier ensuite DNS du poste, `nltest /dsgetdc:ad.fournil.lab`, accès à `\\ad.fournil.lab\SYSVOL`.

---

## Partie E — Bonus

**E1.** Sauvegarde toutes les GPO du domaine dans `C:\Sauvegarde\GPO` en une commande.

> [!success]- Afficher la correction — E1
> ```powershell
> New-Item C:\Sauvegarde\GPO -ItemType Directory -Force
> Backup-GPO -All -Path C:\Sauvegarde\GPO
> ```
> Chaque GPO est sauvegardée dans un dossier `{GUID}` avec un rapport. Restauration : `Restore-GPO -Name … -Path …` ; copie vers un autre domaine : `Import-GPO`.

**E2.** Explique à quoi servirait **Group Policy Analytics** si le Fournil passait à Intune.

> [!success]- Afficher la correction — E2
> Dans Intune (*Appareils → Gérer les appareils → Configuration → Importer des ADMX / Analyse de la stratégie de groupe*) : on importe le **rapport XML** d'une GPO (`Get-GPOReport -ReportType Xml`). L'outil indique, paramètre par paramètre, s'il existe un équivalent dans Intune (CSP / *Settings catalog*) et peut créer directement le profil de configuration. C'est le point de départ d'une migration GPO → Intune.

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/11-gpo/tp)
