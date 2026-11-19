# TP 11. Stratégies de groupe et gestion centralisée, version guidée

**Ta mission.** Appliquer une GPO aux postes du Fournil et une autre aux utilisateurs de la boulangerie. À la fin, tu dois pouvoir expliquer pourquoi deux utilisateurs sur le même poste ne reçoivent pas les mêmes réglages.

- **Sur SRV01**, ouvre une session `FOURNIL\Administrateur` pour créer les GPO.
- **Sur PC01**, utilise `PC01\admin` et PowerShell en administrateur pour les tests ordinateur. Pour les tests utilisateur, ouvre la session demandée à chaque étape.

**Avant de commencer.** `PC01` est joint au domaine et placé dans `Fournil → Ordinateurs`. Les comptes et groupes du TP 10 existent. Tu peux faire les parties A à D directement après le TP 10.

[Revoir le chapitre GPO](https://cours.kaya.ovh/windows11/windows11/11-gpo/) · [Reprendre le TP AD guidé](https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp/guide)

## A. Repérer les GPO

### A1 — Ouvrir la console sur SRV01

Sur **`SRV01`**, lance `gpmc.msc` avec **Win + R**. Déplie **Forêt → Domaines → ad.fournil.lab → Fournil**. Tu dois voir les UO `Ordinateurs` et `Utilisateurs`.

### A2 — Repérer les liens déjà en place

Dans la console, sélectionne `ad.fournil.lab` et regarde l’onglet **Objets de stratégie de groupe liés**. Fais la même chose sur **Domain Controllers**. Relève le nom de la GPO liée à chaque emplacement.

## B. Configurer les postes

### B1 — Créer et lier la GPO ordinateur

Sur **`SRV01`**, dans `gpmc.msc`, fais un clic droit sur **Fournil → Ordinateurs**. Choisis **Créer un objet GPO dans ce domaine, et le lier ici…**. Saisis `GPO-Postes-Securite`. Vérifie qu’elle apparaît dans les objets liés à `Ordinateurs`.

### B2 — Ajouter le groupe des administrateurs de postes

Dans la console, fais un clic droit sur la GPO → **Modifier**. Suis **Configuration ordinateur → Stratégies → Paramètres Windows → Paramètres de sécurité → Groupes restreints**.

1. Fais un clic droit → **Ajouter un groupe…**. Sélectionne `FOURNIL\GG-Admins-Postes`.
2. Dans la zone du bas **Ce groupe est membre de**, ajoute `Administrateurs`. Laisse la zone du haut **Membres de ce groupe** vide.

### B3 — Configurer Windows LAPS

Sur **`SRV01`**, lance ces commandes dans PowerShell en administrateur pour préparer l’annuaire.

```powershell
Update-LapsADSchema
Set-LapsADComputerSelfPermission -Identity 'OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab'
```

Sur `SRV01`, ouvre `gpmc.msc` et retrouve `GPO-Postes-Securite` sous `Fournil → Ordinateurs`. C’est la GPO créée en B1. Fais un clic droit dessus → **Modifier**, puis ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Système → LAPS**.

1. Active **Configurer le répertoire de sauvegarde des mots de passe** et sélectionne **Active Directory**.
2. Active **Paramètres du mot de passe**. Saisis **14 caractères**, **30 jours** et la complexité avec majuscules, minuscules, chiffres et caractères spéciaux.

### B4 — Reporter les mises à jour qualité

Dans la même GPO, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Composants Windows → Windows Update → Gérer les mises à jour proposées de Windows Update**. Active **Choisir quand recevoir les mises à jour qualité** et saisis **7 jours**.

### B5 — Appliquer et vérifier la GPO

Sur **`PC01`**, lance dans PowerShell en administrateur.

```powershell
gpupdate /target:computer /force
gpresult /scope computer /r
Get-LocalGroupMember Administrateurs
Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate |
    Select-Object DeferQualityUpdatesPeriodInDays
```

Repère `GPO-Postes-Securite` dans les GPO appliquées, `FOURNIL\GG-Admins-Postes` dans les administrateurs locaux et `7` à la ligne du report.

Sur **`SRV01`**, lance `Get-LapsADPassword -Identity PC01 | Select-Object ComputerName, Account, ExpirationTimestamp`. Repère le compte géré et l’échéance.

### B6 — Vérifier l’état du compte géré par LAPS

Sur **`PC01`**, relève le nom et l’état du compte administrateur intégré.

```powershell
Get-LocalUser | Where-Object { $_.SID.Value -like '*-500' } |
    Select-Object Name, Enabled
```

Compare `Name` avec le compte affiché en B5. Si `Enabled` vaut `False`, que se passe-t-il si quelqu’un tente d’ouvrir une session avec ce compte ?

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

### C2 — Monter Commun en P:

Sur **`SRV01`**, édite `GPO-Boulangerie-Utilisateurs`. Ouvre **Configuration utilisateur → Préférences → Paramètres Windows → Mappages de lecteurs** → **Nouveau → Lecteur mappé**.

| Champ | Valeur |
| --- | --- |
| Action | **Mettre à jour** |
| Emplacement | `\\SRV01\Commun` |
| Lettre | `P:` |
| Libellé | `Commun` |
| Reconnecter | Coché |

### C3 — Bloquer le Panneau de configuration

Dans cette GPO, ouvre **Configuration utilisateur → Stratégies → Modèles d’administration → Panneau de configuration**. Active **Interdire l’accès au Panneau de configuration et à l’application Paramètres du PC**.

### C4 — Réserver l’application de la GPO au groupe

Sur **`SRV01`**, exécute dans PowerShell en administrateur.

```powershell
Set-GPPermission -Name 'GPO-Boulangerie-Utilisateurs' -TargetName 'Utilisateurs authentifiés' -TargetType Group -PermissionLevel GpoRead -Replace
Set-GPPermission -Name 'GPO-Boulangerie-Utilisateurs' -TargetName 'G-Boulangerie' -TargetType Group -PermissionLevel GpoApply
Get-GPPermission -Name 'GPO-Boulangerie-Utilisateurs' -All |
    Select-Object @{Name='Groupe'; Expression={$_.Trustee.Name}}, Permission
```

**À lire.** `G-Boulangerie` a `GpoApply`. `Utilisateurs authentifiés` a `GpoRead`.

### C5 — Tester avec stagiaire

Sur **`PC01`**, ferme la session `stagiaire` si elle est encore ouverte, puis reconnecte-toi en `FOURNIL\stagiaire`. Dans **Ce PC**, cherche `Commun (P:)` et ouvre-le. Lance ensuite `control` via **Win + R**. L’accès au Panneau de configuration doit être bloqué.

### C6 — Tester avec un utilisateur hors du groupe

Sur **`SRV01`**, dans `dsa.msc`, crée `test.vendeur` dans **Fournil → Utilisateurs** avec un mot de passe de lab. N’ajoute pas ce compte à `G-Boulangerie`. Sur **`PC01`**, connecte-toi en `FOURNIL\test.vendeur` et refais les deux tests de C5.

## D. Expliquer un résultat avec gpresult

### D1 — Lire les stratégies appliquées

Sur **`PC01`**, lance `gpresult /scope user /r` dans la session `FOURNIL\stagiaire`. Puis ouvre une session `PC01\admin`, lance PowerShell en administrateur et génère le rapport.

```powershell
gpresult /scope computer /r
gpresult /user 'FOURNIL\stagiaire' /h "$env:TEMP\rsop-pc01.html" /f
Start-Process "$env:TEMP\rsop-pc01.html"
```

Repère `GPO-Postes-Securite` côté ordinateur et `GPO-Boulangerie-Utilisateurs` côté utilisateur.

### D2 — Vérifier qu’un poste est dans la portée du lien

Cas de dépannage. Le rapport d’un collègue n’affiche plus `GPO-Postes-Securite`. Son poste apparaît sous **Computers** dans AD. Sur **`SRV01`**, compare avec le lab. Regarde où se trouvent le lien de la GPO dans `gpmc.msc` et l’objet `PC01` dans `dsa.msc`.

### D3 — Trouver le journal de diagnostic

Sur **`PC01`**, ouvre `eventvwr.msc`. Déplie **Journaux des applications et des services → Microsoft → Windows → GroupPolicy → Operational**. Ouvre un événement récent et compare son heure à celle de ton dernier `gpupdate`.

## E. Exercices complémentaires

### E1 — Sauvegarder les GPO

Sur **`SRV01`**, crée `C:\Sauvegarde\GPO` et sauvegarde toutes les GPO dans ce dossier. Si tu bloques, utilise `Get-Help Backup-GPO -Examples`.

### E2 — Comprendre à quoi sert Group Policy Analytics

Dans le chapitre GPO, retrouve **Group Policy Analytics**. Si le Fournil passait à Intune, quelle information l’outil donnerait-il sur les réglages à reprendre ?

## F. Atelier facultatif — Sauvegarder la récupération BitLocker dans AD

Fais cet atelier si le chapitre 09 a été traité et si `PC01` possède déjà un protecteur de récupération. Si tu as passé le chapitre 09, le TP est terminé après les vérifications de la partie D. Tu peux revenir ici plus tard.

### F1 — Configurer la récupération BitLocker

Dans la même GPO, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Composants Windows → Chiffrement de lecteur BitLocker → Lecteurs du système d’exploitation**.

Active **Sélectionner la méthode de récupération des lecteurs du système d’exploitation protégés par BitLocker**. Coche **Enregistrer les informations de récupération dans AD DS** et choisis **mots de passe et packages de clés**. Coche aussi **Ne pas activer BitLocker tant que les informations de récupération ne sont pas stockées dans AD DS**.

### F2 — Sauvegarder le protecteur BitLocker existant

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

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/guide-corrigev2)
