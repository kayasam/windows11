# TP 11. Stratégies de groupe et gestion centralisée, corrigé guidé

**Ta mission.** Appliquer une GPO aux postes du Fournil et une autre aux utilisateurs de la boulangerie. À la fin, tu dois pouvoir expliquer pourquoi deux utilisateurs sur le même poste ne reçoivent pas les mêmes réglages.

- **Sur SRV01**, ouvre une session `FOURNIL\Administrateur` pour créer les GPO.
- **Sur PC01**, utilise `PC01\admin` et PowerShell en administrateur pour les tests ordinateur. Pour les tests utilisateur, ouvre la session demandée à chaque étape.

**Avant de commencer.** `PC01` est joint au domaine et placé dans `Fournil → Ordinateurs`. Les comptes et groupes du TP 10 existent. Le volume `C:` a un protecteur de récupération BitLocker issu du TP 09.

[Revoir le chapitre GPO](https://cours.kaya.ovh/windows11/windows11/11-gpo/) · [Reprendre le TP AD guidé](https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp/guide)

## A. Repérer les GPO

### A1 — Ouvrir la console sur SRV01

Sur **`SRV01`**, lance `gpmc.msc` avec **Win + R**. Déplie **Forêt → Domaines → ad.fournil.lab → Fournil**. Tu dois voir les UO `Ordinateurs` et `Utilisateurs`.

> [!success]- Afficher la correction — A1
> **Gestionnaire de serveur → Outils → Gestion de stratégie de groupe** ouvre la même console. Cette console sur `SRV01` suffit pour suivre le TP.

### A2 — Repérer les liens déjà en place

Dans la console, sélectionne `ad.fournil.lab` et regarde l’onglet **Objets de stratégie de groupe liés**. Fais la même chose sur **Domain Controllers**. Relève le nom de la GPO liée à chaque emplacement.

> [!success]- Afficher la correction — A2
> **Default Domain Policy** est liée à la racine du domaine. **Default Domain Controllers Policy** est liée à l’UO **Domain Controllers**. Le lien d’une GPO détermine où ses réglages peuvent s’appliquer.

## B. Configurer les postes

### B1 — Créer et lier la GPO ordinateur

Sur **`SRV01`**, dans `gpmc.msc`, fais un clic droit sur **Fournil → Ordinateurs**. Choisis **Créer un objet GPO dans ce domaine, et le lier ici…**. Saisis `GPO-Postes-Securite`. Vérifie qu’elle apparaît dans les objets liés à `Ordinateurs`.

> [!success]- Afficher la correction — B1
> La GPO est liée à **Fournil → Ordinateurs**. Elle peut donc s’appliquer à `PC01`, dont le compte ordinateur est dans cette UO.

### B2 — Ajouter le groupe des administrateurs de postes

Dans la console, fais un clic droit sur la GPO → **Modifier**. Suis **Configuration ordinateur → Stratégies → Paramètres Windows → Paramètres de sécurité → Groupes restreints**.

1. Fais un clic droit → **Ajouter un groupe…**. Sélectionne `FOURNIL\GG-Admins-Postes`.
2. Dans la zone du bas **Ce groupe est membre de**, ajoute `Administrateurs`. Laisse la zone du haut **Membres de ce groupe** vide.

> [!success]- Afficher la correction — B2
> La fiche indique que `GG-Admins-Postes` est membre de `Administrateurs`. Ce réglage ajoute le groupe du domaine aux administrateurs locaux de `PC01` et conserve les membres déjà présents.

### B3 — Configurer Windows LAPS

Sur **`SRV01`**, lance ces commandes dans PowerShell en administrateur pour préparer l’annuaire.

```powershell
Update-LapsADSchema
Set-LapsADComputerSelfPermission -Identity 'OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab'
```

Dans l’éditeur de la GPO, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Système → LAPS**.

1. Active **Configurer le répertoire de sauvegarde des mots de passe** et sélectionne **Active Directory**.
2. Active **Paramètres du mot de passe**. Saisis **14 caractères**, **30 jours** et la complexité avec majuscules, minuscules, chiffres et caractères spéciaux.

> [!success]- Afficher la correction — B3
> Le schéma contient les attributs LAPS. La permission sur l’UO permet à chaque poste d’écrire ses propres informations LAPS. Dans la GPO, la destination choisie doit être **Active Directory**. [Configurer Windows LAPS avec Active Directory](https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-scenarios-windows-server-active-directory)

### B4 — Configurer la récupération BitLocker

Dans la même GPO, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Composants Windows → Chiffrement de lecteur BitLocker → Lecteurs du système d’exploitation**.

Active **Sélectionner la méthode de récupération des lecteurs du système d’exploitation protégés par BitLocker**. Coche **Enregistrer les informations de récupération dans AD DS** et choisis **mots de passe et packages de clés**. Coche aussi **Ne pas activer BitLocker tant que les informations de récupération ne sont pas stockées dans AD DS**.

> [!success]- Afficher la correction — B4
> Le paramètre doit apparaître activé pour les lecteurs du système, dont `C:`. Le protecteur déjà créé au TP 09 sera sauvegardé explicitement en B7.

### B5 — Reporter les mises à jour qualité

Dans la même GPO, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Composants Windows → Windows Update → Gérer les mises à jour proposées de Windows Update**. Active **Choisir quand recevoir les mises à jour qualité** et saisis **7 jours**.

> [!success]- Afficher la correction — B5
> La stratégie est activée pour les mises à jour **qualité**. La valeur attendue sur `PC01` après application est `DeferQualityUpdatesPeriodInDays : 7`.

### B6 — Appliquer et vérifier la GPO

Sur **`PC01`**, lance dans PowerShell en administrateur.

```powershell
gpupdate /target:computer /force
gpresult /scope computer /r
Get-LocalGroupMember Administrateurs
Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate |
    Select-Object DeferQualityUpdatesPeriodInDays
```

Repère `GPO-Postes-Securite` dans les GPO appliquées, `FOURNIL\GG-Admins-Postes` dans les administrateurs locaux et `7` à la ligne du report.

Sur **`SRV01`**, lance `Get-LapsADPassword -Identity PC01 | Select-Object ComputerName, Account, ExpirationTimestamp`. Repère le compte géré et l’échéance. Termine par BitLocker en B7.

> [!success]- Afficher la correction — B6
> Les trois résultats sur `PC01` confirment la portée de la GPO, l’ajout du groupe et le report. Une échéance LAPS renseignée montre que le serveur possède les informations pour le poste. Si la sortie est vide, vérifie B3 puis le journal **Microsoft → Windows → LAPS → Operational** de `PC01`. L’événement **10018** indique une sauvegarde réussie dans AD.

### B7 — Sauvegarder le protecteur BitLocker existant

Sur **`PC01`**, dans PowerShell en administrateur, lance les commandes.

```powershell
$protecteurs = (Get-BitLockerVolume -MountPoint 'C:').KeyProtector |
    Where-Object KeyProtectorType -eq RecoveryPassword
$protecteurs | ForEach-Object {
    Backup-BitLockerKeyProtector -MountPoint 'C:' -KeyProtectorId $_.KeyProtectorId
}
```

Sur **`SRV01`**, cherche l’enregistrement de récupération sous le compte ordinateur.

```powershell
$pc = Get-ADComputer PC01
Get-ADObject -SearchBase $pc.DistinguishedName -SearchScope OneLevel -Filter "objectClass -eq 'msFVE-RecoveryInformation'" |
    Select-Object Name
```

**À vérifier.** La seconde commande liste au moins une entrée. Si elle manque, vérifie que `$protecteurs` contient un protecteur sur `PC01` et relis les messages de sauvegarde.

> [!success]- Afficher la correction — B7
> `Backup-BitLockerKeyProtector` sauvegarde le protecteur de récupération existant dans AD DS. La présence d’un objet `msFVE-RecoveryInformation` sous `PC01` confirme l’enregistrement. Le nom de l’objet suffit pour cette vérification. [Commande Backup-BitLockerKeyProtector](https://learn.microsoft.com/powershell/module/bitlocker/backup-bitlockerkeyprotector)

### B8 — Vérifier l’état du compte géré par LAPS

Sur **`PC01`**, relève le nom et l’état du compte administrateur intégré.

```powershell
Get-LocalUser | Where-Object { $_.SID.Value -like '*-500' } |
    Select-Object Name, Enabled
```

Compare `Name` avec le compte affiché en B6. Si `Enabled` vaut `False`, que se passe-t-il si quelqu’un tente d’ouvrir une session avec ce compte ?

> [!success]- Afficher la correction — B8
> Par défaut, LAPS gère l’administrateur intégré, dont le SID se termine par `-500`. Le mot de passe peut être sauvegardé alors que le compte reste désactivé. Dans ce cas, l’ouverture de session est refusée. [Compte administrateur géré par Windows LAPS](https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-management-policy-settings#administratoraccountname)

## C. Configurer la session des utilisateurs de la boulangerie

### C1 — Préparer le partage puis créer la GPO utilisateur

Sur **`SRV01`**, vérifie si le partage existe avec `Get-SmbShare -Name Commun -ErrorAction SilentlyContinue`. S’il manque, crée-le dans PowerShell en administrateur.

```powershell
New-Item C:\Partages\Commun -ItemType Directory -Force
icacls C:\Partages\Commun /inheritance:r
icacls C:\Partages\Commun /grant 'SYSTEM:(OI)(CI)F' 'BUILTIN\Administrateurs:(OI)(CI)F' 'FOURNIL\G-Boulangerie:(OI)(CI)M'
New-SmbShare -Name Commun -Path C:\Partages\Commun -ChangeAccess 'FOURNIL\G-Boulangerie' -FullAccess 'FOURNIL\Admins du domaine'
```

Sur **`PC01`**, dans la session `FOURNIL\stagiaire`, ouvre `\\SRV01\Commun` dans l’Explorateur. Crée un fichier de test puis supprime-le. Sur **`SRV01`**, dans `gpmc.msc`, crée et lie `GPO-Boulangerie-Utilisateurs` à **Fournil → Utilisateurs**.

> [!success]- Afficher la correction — C1
> La création et la suppression du fichier valident les droits de partage et du dossier. Le lien de `GPO-Boulangerie-Utilisateurs` doit apparaître dans l’UO `Utilisateurs`.

### C2 — Monter Commun en P:

Sur **`SRV01`**, édite `GPO-Boulangerie-Utilisateurs`. Ouvre **Configuration utilisateur → Préférences → Paramètres Windows → Mappages de lecteurs** → **Nouveau → Lecteur mappé**.

| Champ | Valeur |
| --- | --- |
| Action | **Mettre à jour** |
| Emplacement | `\\SRV01\Commun` |
| Lettre | `P:` |
| Libellé | `Commun` |
| Reconnecter | Coché |

> [!success]- Afficher la correction — C2
> La préférence utilisateur associe `P:` à `\\SRV01\Commun`. Tu vérifieras le lecteur dans la session `stagiaire` en C5.

### C3 — Bloquer le Panneau de configuration

Dans cette GPO, ouvre **Configuration utilisateur → Stratégies → Modèles d’administration → Panneau de configuration**. Active **Interdire l’accès au Panneau de configuration et à l’application Paramètres du PC**.

> [!success]- Afficher la correction — C3
> Le paramètre est **Activé**. La restriction sera observable avec `control` dans la session de `stagiaire`.

### C4 — Réserver l’application de la GPO au groupe

Sur **`SRV01`**, exécute dans PowerShell en administrateur.

```powershell
Set-GPPermission -Name 'GPO-Boulangerie-Utilisateurs' -TargetName 'Utilisateurs authentifiés' -TargetType Group -PermissionLevel GpoRead -Replace
Set-GPPermission -Name 'GPO-Boulangerie-Utilisateurs' -TargetName 'G-Boulangerie' -TargetType Group -PermissionLevel GpoApply
Get-GPPermission -Name 'GPO-Boulangerie-Utilisateurs' -All |
    Select-Object @{Name='Groupe'; Expression={$_.Trustee.Name}}, Permission
```

**À lire.** `G-Boulangerie` a `GpoApply`. `Utilisateurs authentifiés` a `GpoRead`.

> [!success]- Afficher la correction — C4
> `G-Boulangerie` peut lire et appliquer la GPO. `Utilisateurs authentifiés` conserve la lecture pour que `PC01` puisse lire la GPO utilisateur avec son compte ordinateur. [Droits de lecture des GPO utilisateur](https://learn.microsoft.com/en-us/troubleshoot/windows-server/group-policy/cannot-apply-user-gpo-when-computer-objects-dont-have-read-permissions)

### C5 — Tester avec stagiaire

Sur **`PC01`**, ferme la session `stagiaire` si elle est encore ouverte, puis reconnecte-toi en `FOURNIL\stagiaire`. Dans **Ce PC**, cherche `Commun (P:)` et ouvre-le. Lance ensuite `control` via **Win + R**. L’accès au Panneau de configuration doit être bloqué.

> [!success]- Afficher la correction — C5
> `P:` est présent et `control` est bloqué. Si un résultat manque, lance `gpresult /scope user /r` dans cette session. Si la GPO est appliquée et que seul le lecteur manque, reteste `\\SRV01\Commun`.

### C6 — Tester avec un utilisateur hors du groupe

Sur **`SRV01`**, dans `dsa.msc`, crée `test.vendeur` dans **Fournil → Utilisateurs** avec un mot de passe de lab. N’ajoute pas ce compte à `G-Boulangerie`. Sur **`PC01`**, connecte-toi en `FOURNIL\test.vendeur` et refais les deux tests de C5.

> [!success]- Afficher la correction — C6
> `P:` est absent et `control` s’ouvre. Le compte est dans l’UO liée à la GPO, mais il est hors du groupe autorisé. Le filtrage refuse l’application.

## D. Expliquer un résultat avec gpresult

### D1 — Lire les stratégies appliquées

Sur **`PC01`**, lance `gpresult /scope user /r` dans la session `FOURNIL\stagiaire`. Puis ouvre une session `PC01\admin`, lance PowerShell en administrateur et génère le rapport.

```powershell
gpresult /scope computer /r
gpresult /user 'FOURNIL\stagiaire' /h "$env:TEMP\rsop-pc01.html" /f
Start-Process "$env:TEMP\rsop-pc01.html"
```

Repère `GPO-Postes-Securite` côté ordinateur et `GPO-Boulangerie-Utilisateurs` côté utilisateur.

> [!success]- Afficher la correction — D1
> Le rapport HTML montre les GPO appliquées ou refusées et permet de retrouver la **GPO gagnante** pour un paramètre. Si les données utilisateur manquent, vérifie que `stagiaire` a ouvert une session sur ce poste.

### D2 — Vérifier qu’un poste est dans la portée du lien

Cas de dépannage. Le rapport d’un collègue n’affiche plus `GPO-Postes-Securite`. Son poste apparaît sous **Computers** dans AD. Sur **`SRV01`**, compare avec le lab. Regarde où se trouvent le lien de la GPO dans `gpmc.msc` et l’objet `PC01` dans `dsa.msc`.

> [!success]- Afficher la correction — D2
> Dans le lab, le lien et `PC01` sont dans **Fournil → Ordinateurs**. Le poste du collègue est en dehors de la portée du lien. Il faut remettre son objet dans la bonne UO, actualiser la stratégie et vérifier de nouveau `gpresult`.

### D3 — Trouver le journal de diagnostic

Sur **`PC01`**, ouvre `eventvwr.msc`. Déplie **Journaux des applications et des services → Microsoft → Windows → GroupPolicy → Operational**. Ouvre un événement récent et compare son heure à celle de ton dernier `gpupdate`.

> [!success]- Afficher la correction — D3
> Le journal suit le traitement des stratégies et indique les erreurs. Si une erreur concerne le domaine ou SYSVOL, vérifie le DNS du poste et essaie d’ouvrir `\\ad.fournil.lab\SYSVOL`.

## E. Exercices complémentaires

### E1 — Sauvegarder les GPO

Sur **`SRV01`**, crée `C:\Sauvegarde\GPO` et sauvegarde toutes les GPO dans ce dossier. Si tu bloques, utilise `Get-Help Backup-GPO -Examples`.

> [!success]- Afficher la correction — E1
> ```powershell
> New-Item C:\Sauvegarde\GPO -ItemType Directory -Force
> Backup-GPO -All -Path C:\Sauvegarde\GPO
> ```

### E2 — Comprendre à quoi sert Group Policy Analytics

Dans le chapitre GPO, retrouve **Group Policy Analytics**. Si le Fournil passait à Intune, quelle information l’outil donnerait-il sur les réglages à reprendre ?

> [!success]- Afficher la correction — E2
> Après import du rapport XML d’une GPO, l’outil indique quels paramètres ont un équivalent dans Intune. Cela aide à préparer la migration des réglages.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/guide)
