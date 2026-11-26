---
title: "TP 11. Stratégies de groupe et gestion centralisée, corrigé guidé"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/11-gpo"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/11-gpo-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Mission** — Appliquer une GPO aux postes, monter un lecteur pour la boulangerie et configurer un compte de dépannage LAPS.

- **Sur SRV01** — Ouvre une session `FOURNIL\Administrateur`, puis lance `gpmc.msc` pour ouvrir la console **Gestion de stratégie de groupe**.
- **Sur PC01** — Utilise `FOURNIL\Administrateur` pour les tâches qui demandent une élévation. Ouvre les sessions `stagiaire` et `test.vendeur` pour les tests utilisateur.
- **Prérequis** — `PC01` est joint au domaine et se trouve dans **Fournil → Ordinateurs**. Le TP 10 a préparé `stagiaire` et les groupes `G-Admins-Postes` et `G-Boulangerie`. Pour LAPS, `PC01` doit être sous Windows 11 24H2 ou plus récent.

> [!tip] Se repérer dans la console
> Les UO **Ordinateurs** et **Utilisateurs** sont sous **Fournil**. Le lien de la GPO donne son périmètre. Le filtrage précise qui reçoit la GPO dans ce périmètre.

[Chapitre GPO](https://cours.kaya.ovh/windows11/windows11/11-gpo/) · [TP Active Directory guidé](https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp/guide)

## A. Prendre ses repères

### A1 — Comparer deux liens existants

Sur **SRV01**, relève le nom de la GPO liée au domaine et celui de la GPO liée à l’UO **Domain Controllers**.

Sélectionne **ad.fournil.lab**, puis **Objets de stratégie de groupe liés**. Recommence depuis **Domain Controllers**.

> [!success]- Afficher la correction — A1
> **Default Domain Policy** est liée au domaine. **Default Domain Controllers Policy** est liée à l’UO **Domain Controllers**. Une GPO peut exister dans le domaine et être liée à un emplacement précis.

## B. Ajouter les administrateurs locaux

### B1 — Créer la GPO des administrateurs de postes

Sur **SRV01**, crée `GPO-Postes-Admins-Locaux` et lie-la à **Ordinateurs**.

Fais un clic droit sur **Ordinateurs** → **Créer un objet GPO dans ce domaine, et le lier ici…**. Donne le nom indiqué.

> [!success]- Afficher la correction — B1
> Le lien apparaît sous **Ordinateurs**. La création et la liaison peuvent aussi se faire dans PowerShell sur `SRV01`.
>
> ```powershell
> New-GPO -Name 'GPO-Postes-Admins-Locaux' | New-GPLink -Target 'OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab'
> ```
>
> ![w11-11-gpmc-creer-lier](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpmc-creer-lier.png)

### B2 — Ajouter le groupe du domaine au groupe local

Sur **SRV01**, configure la GPO pour ajouter `FOURNIL\G-Admins-Postes` aux **Administrateurs** locaux de `PC01`. Conserve les membres actuels.

**Ordinateurs → GPO-Postes-Admins-Locaux → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Paramètres Windows → Paramètres de sécurité → Groupes restreints**.

1. Fais un clic droit dans **Groupes restreints** → **Ajouter un groupe…**. Sélectionne `FOURNIL\G-Admins-Postes`.
2. Dans **Ce groupe est membre de** (en bas), ajoute **Administrateurs**. Laisse **Membres de ce groupe** (en haut) vide.

> [!success]- Afficher la correction — B2
> Dans la fenêtre **Propriétés** de FOURNIL\G-Admins-Postes, **Ce groupe est membre de** contient **Administrateurs**.
>
> ![Groupes restreints — G-Admins-Postes est membre du groupe Administrateurs](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpo-groupes-restreints.png)

### B3 — Vérifier l’ajout sur PC01

Sur **PC01**, dans la session `FOURNIL\Administrateur`, actualise les stratégies ordinateur et vérifie que `FOURNIL\G-Admins-Postes` figure dans les Administrateurs locaux.

1. Ouvre PowerShell en administrateur et lance `gpupdate /target:computer /force`.
2. Ouvre **Gestion de l’ordinateur → Utilisateurs et groupes locaux → Groupes → Administrateurs**.

> [!success]- Afficher la correction — B3
> `FOURNIL\G-Admins-Postes` est dans la liste. Pour afficher la même liste dans PowerShell sur `PC01` :
>
> ```powershell
> Get-LocalGroupMember Administrateurs
> ```

## C. Distribuer le lecteur Commun

### C1 — Préparer et tester le partage

Sur **SRV01**, prépare le partage `Commun` s’il manque. Sur **PC01**, ouvre `\\SRV01\Commun` dans la session `FOURNIL\stagiaire`, puis crée et supprime un fichier de test.

**Créer le partage sur SRV01, s’il manque.** Dans **Gestionnaire de serveur → Services de fichiers et de stockage → Partages → Tâches → Nouveau partage**, crée un partage SMB nommé `Commun` sur `C:\Partages\Commun`.

| Autorisation | `FOURNIL\G-Boulangerie` |
| --- | --- |
| Partage SMB | Modifier |
| Sécurité du dossier (NTFS) | Modification |

Garde le **Contrôle total** pour les Administrateurs et, sur le dossier, pour `SYSTEM`.

> [!tip]- PowerShell — créer le dossier et le partage Commun
>
> Sur `SRV01`, ouvre PowerShell en administrateur avec `FOURNIL\Administrateur`. Si le dossier et le partage sont à créer, exécute les commandes dans l’ordre.
>
> ```powershell
> $dossier = 'C:\Partages\Commun'
> New-Item -Path $dossier -ItemType Directory -Force
>
> # Sur le dossier : contrôle total pour SYSTEM et les administrateurs.
> icacls $dossier /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' 'FOURNIL\G-Boulangerie:(OI)(CI)M'
> icacls $dossier /inheritance:r
>
> # Sur le partage : modification pour G-Boulangerie.
> New-SmbShare -Name Commun -Path $dossier -FullAccess 'BUILTIN\Administrateurs' -ChangeAccess 'FOURNIL\G-Boulangerie'
> ```
>
> Si le dossier existe déjà, réutilise-le et vérifie ses autorisations avant de créer le partage.

> [!success]- Afficher la correction — C1
> Le fichier peut être créé et supprimé dans la session de `stagiaire`. Si l’accès échoue, vérifie l’appartenance à `G-Boulangerie` et les droits du partage et du dossier. Rouvre la session de `stagiaire` après un changement de groupe.
>
> Sur `SRV01`, tu peux vérifier la présence du partage dans PowerShell :
>
> ```powershell
> Get-SmbShare -Name Commun
> ```

### C2 — Créer la GPO et configurer le lecteur

Sur **SRV01**, crée et lie `GPO-Utilisateurs-Lecteur-Commun` sous **Utilisateurs**. Fais pointer `P:` vers `\\SRV01\Commun`, avec le libellé `Commun`.

**Utilisateurs → GPO-Utilisateurs-Lecteur-Commun → Modifier**

Dans l’éditeur, ouvre **Configuration utilisateur → Préférences → Paramètres Windows → Mappages de lecteurs**.

Fais un clic droit dans **Mappages de lecteurs** → **Nouveau → Lecteur mappé**.

| Champ | Valeur |
| --- | --- |
| Action | Mettre à jour |
| Emplacement | `\\SRV01\Commun` |
| Lettre | `P:` |
| Libellé | `Commun` |
| Reconnecter | Coché |

![w11-11-gpo-preference-lecteur-p](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpo-preference-lecteur-p.png)

> [!success]- Afficher la correction — C2
> La préférence **Mettre à jour** crée le lecteur s’il manque et actualise le mappage s’il existe. La GPO est liée sous **Utilisateurs**.
>
> ```powershell
> New-GPO -Name 'GPO-Utilisateurs-Lecteur-Commun' | New-GPLink -Target 'OU=Utilisateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab'
> ```

### C3 — Réserver le lecteur au groupe Boulangerie

Sur **SRV01**, réserve l’application de la GPO à `G-Boulangerie`. Garde **Lecture** pour **Utilisateurs authentifiés**.

**Utilisateurs → GPO-Utilisateurs-Lecteur-Commun → Délégation → Avancé**

1. Pour **Utilisateurs authentifiés**, conserve **Lecture** et décoche **Appliquer la stratégie de groupe** dans la colonne **Autoriser**.
2. Pour `FOURNIL\G-Boulangerie`, autorise **Lecture** et **Appliquer la stratégie de groupe**.

> [!important] Pourquoi conserver la lecture ?
> `PC01` en a besoin pour lire la GPO utilisateur avec son compte ordinateur.

> [!success]- Afficher la correction — C3
> Dans **Étendue → Filtrage de sécurité**, `G-Boulangerie` apparaît comme groupe autorisé. Dans **Délégation**, **Utilisateurs authentifiés** garde **Lecture**.
>
> Équivalent sur `SRV01` dans PowerShell en administrateur :
>
> ```powershell
> Set-GPPermission -Name 'GPO-Utilisateurs-Lecteur-Commun' -TargetName 'Utilisateurs authentifiés' -TargetType Group -PermissionLevel GpoRead -Replace
> Set-GPPermission -Name 'GPO-Utilisateurs-Lecteur-Commun' -TargetName 'G-Boulangerie' -TargetType Group -PermissionLevel GpoApply
> ```
>
> [Microsoft Learn — Lecture des GPO utilisateur par le compte ordinateur](https://learn.microsoft.com/fr-fr/troubleshoot/windows-server/group-policy/cannot-apply-user-gpo-when-computer-objects-dont-have-read-permissions)
>
> ![Volet Filtrage de sécurité de la console GPO — G-Boulangerie](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpmc-filtrage-g-boulangerie.png)
>
> ![Rapport du lecteur P et du filtre G-Boulangerie](https://cours.kaya.ovh/windows11/assets/captures/w11-11-lab-gpo-lecteur-commun.png)

### C4 — Comparer deux utilisateurs sur le même poste

Sur **PC01**, reconnecte-toi en `FOURNIL\stagiaire` et cherche `P:` dans **Ce PC**. Recommence avec `FOURNIL\test.vendeur`, qui est dans la même UO et hors de `G-Boulangerie`. Note le résultat de chaque session.

Si `test.vendeur` manque, ouvre `dsa.msc` sur **SRV01**. Dans **Utilisateurs**, crée le compte `test.vendeur` et choisis un mot de passe pour le lab. Laisse le compte hors de `G-Boulangerie`.

> [!success]- Afficher la correction — C4
> `Commun (P:)` est visible pour `stagiaire` et absent pour `test.vendeur`. Les deux comptes sont dans la portée du lien, mais seul `stagiaire` appartient au groupe autorisé à appliquer la GPO.
>
> ![w11-11-pc01-lecteur-p-stagiaire](https://cours.kaya.ovh/windows11/assets/captures/w11-11-pc01-lecteur-p-stagiaire.png)

## D. Comprendre pourquoi une GPO s’applique

### D1 — Lire les résultats sur PC01

Sur **PC01**, relève la GPO appliquée à `stagiaire` et celle qui ajoute les administrateurs locaux au poste.

| Session sur PC01 | Commande PowerShell |
| --- | --- |
| `FOURNIL\stagiaire` | `gpresult /scope user /r` |
| `FOURNIL\Administrateur`, PowerShell en administrateur | `gpresult /scope computer /r` |

Cherche **Objets de stratégie de groupe appliqués** dans chaque sortie.

> [!success]- Afficher la correction — D1
> La partie utilisateur affiche `GPO-Utilisateurs-Lecteur-Commun`. La partie ordinateur affiche `GPO-Postes-Admins-Locaux`.
>
> ![Rapport gpresult des stratégies ordinateur appliquées à PC01](https://cours.kaya.ovh/windows11/assets/captures/w11-11-lab-pc01-gpresult.png)

### D2 — Expliquer une GPO absente

**Cas fictif.** Un poste a été déplacé dans **Computers** et ne reçoit plus `GPO-Postes-Admins-Locaux`. Compare l’emplacement de `PC01` dans AD au lien de la GPO. Explique le résultat en gardant `PC01` dans son UO.

**Ordinateurs → GPO-Postes-Admins-Locaux**

Sur **SRV01**, ouvre `dsa.msc` et retrouve **Ordinateurs → PC01**. Compare avec l’emplacement du lien dans la console GPO.

> [!success]- Afficher la correction — D2
> Le poste du collègue est hors de l’UO qui porte le lien. Il faut replacer son compte ordinateur dans la bonne UO, actualiser ses stratégies puis relire le rapport.

## E. Créer un compte de dépannage avec Windows LAPS

### E1 — Préparer Active Directory

Sur **SRV01**, prépare le schéma Windows LAPS et autorise chaque ordinateur de l’UO **Ordinateurs** à sauvegarder ses propres informations.

L’extension du schéma se fait une fois par domaine, avec un compte habilité. Dans PowerShell en administrateur sur **SRV01**, lance les commandes suivantes.

```powershell
Update-LapsADSchema
Set-LapsADComputerSelfPermission -Identity 'OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab'
```

> [!success]- Afficher la correction — E1
> Le schéma reçoit les attributs LAPS. La permission sur l’UO permet à chaque poste d’écrire ses propres données. [Microsoft Learn — Déployer Windows LAPS avec Active Directory](https://learn.microsoft.com/fr-fr/windows-server/identity/laps/laps-scenarios-windows-server-active-directory)

### E2 — Créer et activer adm-laps par GPO

Sur **SRV01**, crée et lie `GPO-Postes-LAPS` sous **Ordinateurs** pour créer `adm-laps` et sauvegarder son mot de passe chiffré dans AD.

**Ordinateurs → GPO-Postes-LAPS → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Système → LAPS**.

| Paramètre LAPS | Valeur |
| --- | --- |
| Configurer le répertoire de sauvegarde de mot de passe | Activé → Active Directory |
| Activer le chiffrement du mot de passe | Activé |
| Configurer la gestion automatique des comptes | Activé |
| Nom du compte administrateur à gérer | Non configuré |

Dans **Configurer la gestion automatique des comptes**, renseigne ces options.

| Option | Valeur |
| --- | --- |
| Spécifiez le compte cible à gérer | Gérer un compte d’administrateur personnalisé |
| Nom du compte automatique (ou préfixe du nom) | `adm-laps` |
| Activer le compte géré | Coché pour le test |
| Choisir au hasard le nom du compte géré | Décoché |

> [!tip] LAPS crée le compte
> La gestion automatique crée `adm-laps` sur le poste. Le champ **Nom du compte administrateur à gérer** sert en mode manuel à désigner un compte déjà présent.

> [!success]- Afficher la correction — E2
> LAPS crée `adm-laps` sur `PC01` et gère son mot de passe. La case **Activer le compte géré** le rend utilisable pendant le TP. Le compte `Administrateur` intégré garde son état désactivé.
>
> ![w11-11-gpo-laps-repertoire-ad](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpo-laps-repertoire-ad.png)
>
> La capture illustre le choix du répertoire de sauvegarde. Si **Configurer la gestion automatique des comptes** manque dans l’éditeur, vérifie la version du modèle `LAPS.admx` et de son fichier de langue dans le magasin central, s’il existe. [Microsoft Learn — Paramètres Windows LAPS](https://learn.microsoft.com/fr-fr/windows-server/identity/laps/laps-management-policy-settings#automaticaccountmanagementenabled)
>
> ![Réglages LAPS du compte adm-laps dans le rapport du lab](https://cours.kaya.ovh/windows11/assets/captures/w11-11-lab-gpo-laps-compte-auto.png)

### E3 — Vérifier le compte et la sauvegarde

Sur **PC01**, vérifie que `adm-laps` est actif et que le compte Administrateur intégré est désactivé. Sur **SRV01**, vérifie la sauvegarde de `adm-laps` dans AD.

1. **Sur PC01**, ouvre PowerShell en administrateur avec `FOURNIL\Administrateur` et lance `gpupdate /target:computer /force`. Vérifie l’état des deux comptes dans **Gestion de l’ordinateur → Utilisateurs et groupes locaux → Utilisateurs**.
2. **Sur SRV01**, dans `dsa.msc`, ouvre **Ordinateurs → PC01 → Propriétés → LAPS**. Vérifie le nom du compte et la date d’expiration. Tu peux afficher le mot de passe si tu as le droit de lecture. Garde-le hors du compte rendu.
3. **Pour tester LAPS**, ouvre brièvement une session `.\adm-laps` sur `PC01` avec le mot de passe récupéré.

> [!success]- Afficher la correction — E3
> `adm-laps` est actif sur le poste, `Administrateur` est désactivé et l’onglet **LAPS** affiche les données de `adm-laps`. Si nécessaire, actualise les informations LAPS sur `PC01` avec `Invoke-LapsPolicyProcessing`, puis consulte **Observateur d’événements → Journaux des applications et des services → Microsoft → Windows → LAPS → Operational**. L’événement **10018** indique la sauvegarde réussie dans AD.
>
> Équivalents PowerShell, depuis `PC01` puis `SRV01` :
>
> ```powershell
> Get-LocalUser -Name 'adm-laps' | Select-Object Name, Enabled
> ```
>
> ```powershell
> Get-LapsADPassword -Identity PC01 | Select-Object ComputerName, Account, ExpirationTimestamp
> ```

## F. Ateliers facultatifs

### F1 — Différer les mises à jour qualité

Sur **SRV01**, crée et lie `GPO-Postes-Windows-Update` sous **Ordinateurs** pour reporter les mises à jour qualité de **7 jours**.

**Ordinateurs → GPO-Postes-Windows-Update → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Composants Windows → Windows Update → Gérer les mises à jour proposées de Windows Update**.

Active **Choisir quand recevoir les mises à jour qualité** et saisis **7 jours**. Sur **PC01**, actualise les stratégies ordinateur avec `FOURNIL\Administrateur`, puis vérifie le réglage dans `rsop.msc`.

> [!success]- Afficher la correction — F1
> Le rapport indique **7 jours**. Vérification équivalente sur `PC01` :
>
> ```powershell
> Get-ItemPropertyValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name DeferQualityUpdatesPeriodInDays
> ```
>
> ![Report de sept jours dans la GPO Windows Update](https://cours.kaya.ovh/windows11/assets/captures/w11-11-lab-gpo-windows-update.png)

### F2 — Bloquer le Panneau de configuration

Sur **SRV01**, crée et lie `GPO-Utilisateurs-Bloquer-Parametres` sous **Utilisateurs**. Réserve le blocage du Panneau de configuration aux membres de `G-Boulangerie`.

**Utilisateurs → GPO-Utilisateurs-Bloquer-Parametres → Modifier**

Dans l’éditeur, ouvre **Configuration utilisateur → Stratégies → Modèles d’administration → Panneau de configuration**.

1. Active **Interdire l’accès au Panneau de configuration et à l’application Paramètres du PC**.
2. Reprends le filtrage de C3 sous **Utilisateurs → GPO-Utilisateurs-Bloquer-Parametres → Délégation → Avancé**.
3. Sur **PC01**, reconnecte `stagiaire` puis `test.vendeur`. Lance `control` dans chaque session.

> [!success]- Afficher la correction — F2
> L’accès est bloqué pour `stagiaire` et le Panneau de configuration s’ouvre pour `test.vendeur`.
>
> ![w11-11-pc01-panneau-interdit](https://cours.kaya.ovh/windows11/assets/captures/w11-11-pc01-panneau-interdit.png)
>
> ![Restriction du Panneau de configuration dans la GPO dédiée](https://cours.kaya.ovh/windows11/assets/captures/w11-11-lab-gpo-bloquer-parametres.png)

### F3 — Sauvegarder une clé de récupération BitLocker

Si `PC01` a déjà un protecteur de récupération du TP 09, crée et lie `GPO-Postes-BitLocker` sous **Ordinateurs** sur **SRV01**. Sauvegarde le protecteur dans AD.

**Ordinateurs → GPO-Postes-BitLocker → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Composants Windows → Chiffrement de lecteur BitLocker → Lecteurs du système d’exploitation**.

1. Active **Sélectionner la méthode de récupération des lecteurs du système d’exploitation protégés par BitLocker**.
2. Coche **Enregistrer les informations de récupération dans AD DS**. Sélectionne **Mots de passe et packages de clés** et coche l’option qui impose la sauvegarde avant l’activation de BitLocker.
3. Sur **PC01**, actualise les stratégies ordinateur. Ouvre PowerShell en administrateur avec `FOURNIL\Administrateur` et sauvegarde le protecteur existant.

```powershell
(Get-BitLockerVolume -MountPoint 'C:').KeyProtector |
    Where-Object KeyProtectorType -eq RecoveryPassword |
    ForEach-Object { Backup-BitLockerKeyProtector -MountPoint 'C:' -KeyProtectorId $_.KeyProtectorId }
```

> [!success]- Afficher la correction — F3
> Sur `SRV01`, dans `dsa.msc`, ouvre **Ordinateurs → PC01 → Propriétés → Récupération BitLocker**, si le composant d’affichage est installé. Une entrée de récupération doit apparaître.
>
> ![Onglet Récupération BitLocker des propriétés de PC01, avec une entrée de récupération](https://cours.kaya.ovh/windows11/assets/captures/w11-11-aduc-onglet-bitlocker.png)
>
> **Vérification PowerShell**
>
> ```powershell
> $pc = Get-ADComputer PC01
> Get-ADObject -SearchBase $pc.DistinguishedName -SearchScope OneLevel -Filter "objectClass -eq 'msFVE-RecoveryInformation'" |
>     Select-Object Name
> ```
>
> ![Sauvegarde de la récupération BitLocker dans Active Directory](https://cours.kaya.ovh/windows11/assets/captures/w11-11-lab-gpo-bitlocker.png)

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/guide)
