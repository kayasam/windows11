---
title: "TP 11. Stratégies de groupe et gestion centralisée — Correction"
aliases: ["windows11/11-gpo/tp-corrigev2"]
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/11-gpo"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/11-gpo-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/standard">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/standard-corrigev2" aria-current="page">Corrigé</a></nav>

> [!abstract] Parcours TSSR
> Les RSAT sont préchargés et vérifiés en A1. Le partage Commun doit exister avant C ; sa préparation guidée est incluse dans C. Les GPO restent créées et testées par le stagiaire.

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Chapitres associés : [11. Stratégies de groupe et gestion centralisée](https://cours.kaya.ovh/windows11/windows11/11-gpo/)

---

## Objectifs

- Administrer les GPO depuis `PC01` (RSAT)
- Créer une GPO **ordinateur** de sécurité : admins locaux et anneau Windows Update. Windows LAPS est proposé en (bonus)
- Créer une GPO **utilisateur** filtrée sur un groupe : lecteur réseau et restriction
- Diagnostiquer avec `gpresult`

---

## Prérequis

- `SRV01` contrôleur de domaine, `PC01` joint dans `OU=Ordinateurs,OU=Fournil` (TP 10)
- Session `FOURNIL\Administrateur` sur `SRV01` pour créer les GPO ; sur `PC01`, une session `FOURNIL\Administrateur` (ou `PC01\admin`) pour les vérifications, puis `FOURNIL\stagiaire` pour la partie C

---

Après le TP 10, réalise les parties A à D en suivant les étapes du socle. Saute les étapes marquées **(bonus)** si le temps est compté.

## Partie A — Outils

**A1.** Ouvre la console **Gestion de stratégie de groupe** sur `SRV01` (session `FOURNIL\Administrateur`). Où la trouve-t-on ? (bonus : installe aussi les RSAT sur `PC01`.)

> [!success]- Afficher la correction — A1
> Sur `SRV01` : Gestionnaire de serveur → **Outils → Gestion de stratégie de groupe**, ou `Win + R` → `gpmc.msc`. La console a été installée avec le rôle AD DS (*Ajouter les fonctionnalités requises*, TP 10).
>
> (bonus) Sur `PC01`, en Terminal administrateur :
> ```powershell
> Add-WindowsCapability -Online -Name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
> Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
> ```
> Environ **10 minutes** pour les deux sur le lab : ce sont des **Features on Demand** téléchargées depuis Windows Update. Ne pas redémarrer le poste pendant ce temps — vécu sur le lab : un redémarrage en cours d'installation fait échouer l'opération, à relancer.

**A2.** Ouvre `gpmc.msc`. Quelles GPO existent déjà ? Où sont-elles liées ?

> [!success]- Afficher la correction — A2
> Sur un domaine neuf : **Default Domain Policy** (liée au domaine : stratégie de mots de passe, de verrouillage, Kerberos) et **Default Domain Controllers Policy** (liée à l'UO *Domain Controllers* : droits sur les DC, audit).

**A3.** (bonus) Où sont stockées physiquement les GPO ? Retrouve le dossier de la *Default Domain Policy*.

> [!success]- Afficher la correction — A3
> - Objet AD : `CN={31B2F340-016D-11D2-945F-00C04FB984F9},CN=Policies,CN=System,DC=ad,DC=fournil,DC=lab` (GUID fixe de la *Default Domain Policy*).
> - Fichiers : `\\ad.fournil.lab\SYSVOL\ad.fournil.lab\Policies\{31B2F340-016D-11D2-945F-00C04FB984F9}\` (`GPT.INI`, `Machine\`, `User\`).
> Les deux portent un **numéro de version** : un poste ne retraite une GPO que si ce numéro a changé (sauf `gpupdate /force`).

---

## Partie B — GPO ordinateur « GPO-Postes-Securite »

**B1.** Crée la GPO `GPO-Postes-Securite` et lie-la à `OU=Ordinateurs,OU=Fournil` (GPMC ou PowerShell).

> [!success]- Afficher la correction — B1
> GPMC : **Forêt → Domaines → ad.fournil.lab → Fournil** → clic droit sur `Ordinateurs` → **Créer un objet GPO dans ce domaine, et le lier ici…** → `GPO-Postes-Securite`.
>
> ![w11-11-gpmc-creer-lier](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpmc-creer-lier.png)
> ```powershell
> New-GPO -Name "GPO-Postes-Securite" | New-GPLink -Target "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"
> ```

**B2.** Fais en sorte que `FOURNIL\GG-Admins-Postes` soit administrateur local de tous les postes de l'UO. Deux méthodes possibles : lesquelles ? Choisis-en une.

> [!success]- Afficher la correction — B2
> - **Groupes restreints** : *Configuration ordinateur → Stratégies → Paramètres Windows → Paramètres de sécurité → Groupes restreints* → Ajouter `FOURNIL\GG-Admins-Postes` → section **« Ce groupe est membre de »** → `Administrateurs`. (Ne **pas** utiliser la section « Membres de ce groupe » sur *Administrateurs* : elle **remplace** toute la liste et peut retirer l'admin local de secours.)
> - **Préférences** : *Configuration ordinateur → Préférences → Paramètres du Panneau de configuration → Utilisateurs et groupes locaux* → Nouveau groupe local → `Administrateurs (intégré)`, action *Mettre à jour*, ajouter le membre.
>
> Le lab utilise la première méthode.
>
> ![w11-11-gpo-groupes-restreints](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpo-groupes-restreints.png)

**B3.** (bonus) Sur `SRV01`, prépare Active Directory pour **Windows LAPS**. Modifie ensuite `GPO-Postes-Securite`, créée en B1 et liée à `Fournil → Ordinateurs`. Configure la sauvegarde dans AD, une longueur de 14 caractères et un âge de 30 jours.

> [!success]- Afficher la correction — B3
> Sur un DC (module `LAPS` intégré à Windows Server 2025) :
> ```powershell
> Update-LapsADSchema
> Set-LapsADComputerSelfPermission -Identity "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"
> ```
> GPO : *Configuration ordinateur → Stratégies → Modèles d'administration → Système → LAPS* :
> - **Configurer le répertoire de sauvegarde des mots de passe** → Activé → *Active Directory*
> - **Paramètres du mot de passe** → longueur 14, âge 30 jours (valeurs par défaut), complexité *majuscules + minuscules + chiffres + spéciaux*
>
> > [!WARNING] Piège de la liste « Répertoire de sauvegarde »
> > Une fois *Activé* coché, la valeur affichée est **Azure Active Directory** : la changer en **Active Directory**, sinon le mot de passe n'est sauvegardé nulle part (le poste n'est pas joint à Entra ID).
> >
> > ![w11-11-gpo-laps-repertoire-piege](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpo-laps-repertoire-piege.png)
>
> (En PowerShell : `Set-GPRegistryValue … -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\LAPS" -ValueName BackupDirectory -Value 2`, `PasswordLength 14`, `PasswordAgeDays 30`.)

**B4.** Ajoute un report de **7 jours** des mises à jour qualité (anneau « large »).

> [!success]- Afficher la correction — B4
> *Composants Windows → Windows Update → Gérer les mises à jour proposées de Windows Update → **Choisir quand recevoir les mises à jour qualité*** → Activé, **7** jours.

**B5.** Applique la GPO sur `PC01`, puis vérifie le groupe des administrateurs locaux et le report des mises à jour qualité. (bonus) Si tu as fait B3, vérifie aussi Windows LAPS.

> [!success]- Afficher la correction — B5
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
> 2. **LAPS (bonus, seulement si B3 a été réalisé)** — journal *Microsoft-Windows-LAPS/Operational* : 10018 « LAPS a mis à jour Active Directory avec le nouveau mot de passe », 10020, et 10067 « Le compte local configuré est actuellement désactivé » (voir B6). Lecture du mot de passe : sur SRV01, `dsa.msc` → propriétés de `PC01` → onglet **LAPS** → *Afficher le mot de passe* ;
>
> ![w11-11-aduc-onglet-laps](https://cours.kaya.ovh/windows11/assets/captures/w11-11-aduc-onglet-laps.png)
>
> ou en PowerShell (sur SRV01, ou sur PC01 si les RSAT sont installés) :
> ```powershell
> Get-LapsADPassword -Identity PC01 -AsPlainText
> ```
> ```
> ComputerName        : PC01
> Account             : Administrateur
> Password            : [&a!l0wL53#/[S
> ExpirationTimestamp : 17/12/2026 09:21:24
> ```
> 3. **Windows Update** :
> ```powershell
> Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate | Select-Object DeferQualityUpdates*
> # DeferQualityUpdates : 1 / DeferQualityUpdatesPeriodInDays : 7
> ```

**B6.** (bonus) Le mot de passe LAPS est bien dans AD… mais un technicien ne peut pas s'en servir pour ouvrir une session. Pourquoi ?

> [!success]- Afficher la correction — B6
> LAPS gère par défaut le compte **RID 500** (`Administrateur`), qui est **désactivé** sur Windows 11. Le mot de passe change bien, mais le compte reste inutilisable. Solutions :
> - activer le compte `Administrateur` (par GPO : *Options de sécurité → Comptes : état du compte Administrateur*) ;
> - ou faire gérer un autre compte (paramètre **Nom du compte administrateur à gérer**) ; depuis 24H2, **Configurer la gestion automatique des comptes** permet à LAPS de créer ce compte lui-même.

---

## Partie C — GPO utilisateur filtrée

Sur `SRV01`, un partage `\\SRV01\Commun` est accessible en modification au groupe `G-Boulangerie`. Avant C1, prépare-le avec ce modèle guidé (sur SRV01, après le TP 10) :

```powershell
New-Item C:\Partages\Commun -ItemType Directory -Force
icacls C:\Partages\Commun /inheritance:r
icacls C:\Partages\Commun /grant 'SYSTEM:(OI)(CI)F' 'BUILTIN\Administrateurs:(OI)(CI)F' 'FOURNIL\G-Boulangerie:(OI)(CI)M'
New-SmbShare -Name Commun -Path C:\Partages\Commun -ChangeAccess 'FOURNIL\G-Boulangerie' -FullAccess 'FOURNIL\Admins du domaine'
```

Vérifie l’accès avec `stagiaire` avant de créer le mappage.

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
> ![w11-11-gpo-preference-lecteur-p](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpo-preference-lecteur-p.png)
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
> En graphique : GPMC → la GPO → onglet **Étendue** → *Filtrage de sécurité* : ajouter `G-Boulangerie`, retirer *Utilisateurs authentifiés* (puis vérifier qu'il garde **Lecture** dans l'onglet *Délégation*).
>
> ![w11-11-gpmc-etendue-filtrage](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpmc-etendue-filtrage.png)
>
> **Erreur classique** : supprimer *Utilisateurs authentifiés* de l'onglet « Filtrage de sécurité » de GPMC. Depuis MS16-072, le poste lit la GPO avec son **compte ordinateur** ; sans droit de lecture, la GPO n'est plus appliquée à personne. Il faut lui laisser **Lire** (onglet **Délégation** → Avancé).

**C5.** Ferme la session en cours sur `PC01` et ouvre une session `FOURNIL\stagiaire`. Vérifie le lecteur `P:` et la restriction.

> [!success]- Afficher la correction — C5
> ![w11-11-lecteur-p-gpo](https://cours.kaya.ovh/windows11/assets/captures/w11-11-lecteur-p-gpo.png)
>
> **Commun (P:)** apparaît dans *Ce PC → Emplacements réseau*.
>
> ![w11-11-pc01-lecteur-p-stagiaire](https://cours.kaya.ovh/windows11/assets/captures/w11-11-pc01-lecteur-p-stagiaire.png)
>
> `Win + I` (Paramètres) **ne s'ouvre pas du tout**, sans message. `Win + R` → `control` affiche : « *Cette opération a été annulée en raison de restrictions sur cet ordinateur. Contactez votre administrateur système.* »
>
> ![w11-11-pc01-panneau-interdit](https://cours.kaya.ovh/windows11/assets/captures/w11-11-pc01-panneau-interdit.png)
>
> > [!NOTE] Vérifier dans la bonne session
> > `Get-SmbMapping` ou `net use` lancés dans une **autre** session (un Terminal ouvert en `admin`, une session distante) ne montrent pas le lecteur de `stagiaire` : les lecteurs réseau sont propres à chaque session.
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

## Partie D — Diagnostic

**D1.** Avec `gpresult`, affiche les GPO ordinateur puis utilisateur appliquées sur `PC01`. (bonus) Produis aussi un rapport HTML.

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

**D3.** (bonus) Où chercher si une GPO ne s'applique pas du tout (aucune trace) ?

> [!success]- Afficher la correction — D3
> Journal **Applications et services → Microsoft → Windows → GroupPolicy → Operational** (début/fin de traitement, DC contacté, durée, erreurs SYSVOL), et le journal **Système** (source *GroupPolicy*, ID 1058/1030 : SYSVOL ou DNS inaccessible). Vérifier ensuite DNS du poste, `nltest /dsgetdc:ad.fournil.lab`, accès à `\\ad.fournil.lab\SYSVOL`.

---

## Partie E — Exercices complémentaires (bonus)

**E1.** (bonus) Sauvegarde toutes les GPO du domaine dans `C:\Sauvegarde\GPO` en une commande.

> [!success]- Afficher la correction — E1
> ```powershell
> New-Item C:\Sauvegarde\GPO -ItemType Directory -Force
> Backup-GPO -All -Path C:\Sauvegarde\GPO
> ```
> Chaque GPO est sauvegardée dans un dossier `{GUID}` avec un rapport. Restauration : `Restore-GPO -Name … -Path …` ; copie vers un autre domaine : `Import-GPO`.

**E2.** (bonus) Explique à quoi servirait **Group Policy Analytics** si le Fournil passait à Intune.

> [!success]- Afficher la correction — E2
> Dans Intune (*Appareils → Gérer les appareils → Configuration → Importer des ADMX / Analyse de la stratégie de groupe*) : on importe le **rapport XML** d'une GPO (`Get-GPOReport -ReportType Xml`). L'outil indique, paramètre par paramètre, s'il existe un équivalent dans Intune (CSP / *Settings catalog*) et peut créer directement le profil de configuration. C'est le point de départ d'une migration GPO → Intune.

---

## Partie F — Atelier facultatif BitLocker (bonus)

Fais cet atelier si le chapitre 09 a été traité et si `PC01` possède déjà un protecteur de récupération. Si tu as passé le chapitre 09, le TP est terminé après les vérifications de la partie D. Tu peux revenir ici plus tard.

**F1.** (bonus) Configure la sauvegarde des clés de récupération BitLocker du disque système dans AD DS.

> [!success]- Afficher la correction — F1
> *Composants Windows → Chiffrement de lecteur BitLocker → Lecteurs du système d'exploitation → **Sélectionner la méthode de récupération des lecteurs du système d'exploitation protégés par BitLocker*** → Activé :
> - *Enregistrer les informations de récupération dans AD DS* : mots de passe et packages de clés
> - *Ne pas activer BitLocker tant que les informations de récupération ne sont pas stockées dans AD DS* : coché

**F2.** (bonus) La clé BitLocker n'apparaît pas dans AD. Pourquoi ? Corrige.

> [!success]- Afficher la correction — F2
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
> Name                   : 2026-11-16T09:44:08+01:00{C70A756F-74A8-48AD-A7F1-BCA5F7788131}
> msFVE-RecoveryPassword : 647207-041041-218757-495198-503382-593978-662541-156409
> ```
> En graphique : onglet **Récupération BitLocker** des propriétés de `PC01` dans `dsa.msc`, après installation sur SRV01 de la fonctionnalité *Visionneuse de mots de passe de récupération BitLocker* (`Install-WindowsFeature RSAT-Feature-Tools-BitLocker-BdeAducExt`, sans redémarrage).
>
> ![w11-11-aduc-onglet-bitlocker](https://cours.kaya.ovh/windows11/assets/captures/w11-11-aduc-onglet-bitlocker.png)

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/standard)
