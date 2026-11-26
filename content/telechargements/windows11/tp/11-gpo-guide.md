# TP 11. Stratégies de groupe et gestion centralisée, version guidée

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

## B. Ajouter les administrateurs locaux

### B1 — Créer la GPO des administrateurs de postes

Sur **SRV01**, crée `GPO-Postes-Admins-Locaux` et lie-la à **Ordinateurs**.

Fais un clic droit sur **Ordinateurs** → **Créer un objet GPO dans ce domaine, et le lier ici…**. Donne le nom indiqué.

### B2 — Ajouter le groupe du domaine au groupe local

Sur **SRV01**, configure la GPO pour ajouter `FOURNIL\G-Admins-Postes` aux **Administrateurs** locaux de `PC01`. Conserve les membres actuels.

**Ordinateurs → GPO-Postes-Admins-Locaux → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Paramètres Windows → Paramètres de sécurité → Groupes restreints**.

1. Fais un clic droit dans **Groupes restreints** → **Ajouter un groupe…**. Sélectionne `FOURNIL\G-Admins-Postes`.
2. Dans **Ce groupe est membre de** (en bas), ajoute **Administrateurs**. Laisse **Membres de ce groupe** (en haut) vide.

### B3 — Vérifier l’ajout sur PC01

Sur **PC01**, dans la session `FOURNIL\Administrateur`, actualise les stratégies ordinateur et vérifie que `FOURNIL\G-Admins-Postes` figure dans les Administrateurs locaux.

1. Ouvre PowerShell en administrateur et lance `gpupdate /target:computer /force`.
2. Ouvre **Gestion de l’ordinateur → Utilisateurs et groupes locaux → Groupes → Administrateurs**.

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

### C3 — Réserver le lecteur au groupe Boulangerie

Sur **SRV01**, réserve l’application de la GPO à `G-Boulangerie`. Garde **Lecture** pour **Utilisateurs authentifiés**.

**Utilisateurs → GPO-Utilisateurs-Lecteur-Commun → Délégation → Avancé**

1. Pour **Utilisateurs authentifiés**, conserve **Lecture** et décoche **Appliquer la stratégie de groupe** dans la colonne **Autoriser**.
2. Pour `FOURNIL\G-Boulangerie`, autorise **Lecture** et **Appliquer la stratégie de groupe**.

> [!important] Pourquoi conserver la lecture ?
> `PC01` en a besoin pour lire la GPO utilisateur avec son compte ordinateur.

### C4 — Comparer deux utilisateurs sur le même poste

Sur **PC01**, reconnecte-toi en `FOURNIL\stagiaire` et cherche `P:` dans **Ce PC**. Recommence avec `FOURNIL\test.vendeur`, qui est dans la même UO et hors de `G-Boulangerie`. Note le résultat de chaque session.

Si `test.vendeur` manque, ouvre `dsa.msc` sur **SRV01**. Dans **Utilisateurs**, crée le compte `test.vendeur` et choisis un mot de passe pour le lab. Laisse le compte hors de `G-Boulangerie`.

## D. Comprendre pourquoi une GPO s’applique

### D1 — Lire les résultats sur PC01

Sur **PC01**, relève la GPO appliquée à `stagiaire` et celle qui ajoute les administrateurs locaux au poste.

| Session sur PC01 | Commande PowerShell |
| --- | --- |
| `FOURNIL\stagiaire` | `gpresult /scope user /r` |
| `FOURNIL\Administrateur`, PowerShell en administrateur | `gpresult /scope computer /r` |

Cherche **Objets de stratégie de groupe appliqués** dans chaque sortie.

### D2 — Expliquer une GPO absente

**Cas fictif.** Un poste a été déplacé dans **Computers** et ne reçoit plus `GPO-Postes-Admins-Locaux`. Compare l’emplacement de `PC01` dans AD au lien de la GPO. Explique le résultat en gardant `PC01` dans son UO.

**Ordinateurs → GPO-Postes-Admins-Locaux**

Sur **SRV01**, ouvre `dsa.msc` et retrouve **Ordinateurs → PC01**. Compare avec l’emplacement du lien dans la console GPO.

## E. Créer un compte de dépannage avec Windows LAPS

### E1 — Préparer Active Directory

Sur **SRV01**, prépare le schéma Windows LAPS et autorise chaque ordinateur de l’UO **Ordinateurs** à sauvegarder ses propres informations.

L’extension du schéma se fait une fois par domaine, avec un compte habilité. Dans PowerShell en administrateur sur **SRV01**, lance les commandes suivantes.

```powershell
Update-LapsADSchema
Set-LapsADComputerSelfPermission -Identity 'OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab'
```

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

> [!example]- Voir les réglages LAPS du lab
>
> ![Rapport de la GPO du compte adm-laps](https://cours.kaya.ovh/windows11/assets/captures/w11-11-lab-gpo-laps-compte-auto.png)

### E3 — Vérifier le compte et la sauvegarde

Sur **PC01**, vérifie que `adm-laps` est actif et que le compte Administrateur intégré est désactivé. Sur **SRV01**, vérifie la sauvegarde de `adm-laps` dans AD.

1. **Sur PC01**, ouvre PowerShell en administrateur avec `FOURNIL\Administrateur` et lance `gpupdate /target:computer /force`. Vérifie l’état des deux comptes dans **Gestion de l’ordinateur → Utilisateurs et groupes locaux → Utilisateurs**.
2. **Sur SRV01**, dans `dsa.msc`, ouvre **Ordinateurs → PC01 → Propriétés → LAPS**. Vérifie le nom du compte et la date d’expiration. Tu peux afficher le mot de passe si tu as le droit de lecture. Garde-le hors du compte rendu.
3. **Pour tester LAPS**, ouvre brièvement une session `.\adm-laps` sur `PC01` avec le mot de passe récupéré.

## F. Ateliers facultatifs

### F1 — Différer les mises à jour qualité

Sur **SRV01**, crée et lie `GPO-Postes-Windows-Update` sous **Ordinateurs** pour reporter les mises à jour qualité de **7 jours**.

**Ordinateurs → GPO-Postes-Windows-Update → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Composants Windows → Windows Update → Gérer les mises à jour proposées de Windows Update**.

Active **Choisir quand recevoir les mises à jour qualité** et saisis **7 jours**. Sur **PC01**, actualise les stratégies ordinateur avec `FOURNIL\Administrateur`, puis vérifie le réglage dans `rsop.msc`.

### F2 — Bloquer le Panneau de configuration

Sur **SRV01**, crée et lie `GPO-Utilisateurs-Bloquer-Parametres` sous **Utilisateurs**. Réserve le blocage du Panneau de configuration aux membres de `G-Boulangerie`.

**Utilisateurs → GPO-Utilisateurs-Bloquer-Parametres → Modifier**

Dans l’éditeur, ouvre **Configuration utilisateur → Stratégies → Modèles d’administration → Panneau de configuration**.

1. Active **Interdire l’accès au Panneau de configuration et à l’application Paramètres du PC**.
2. Reprends le filtrage de C3 sous **Utilisateurs → GPO-Utilisateurs-Bloquer-Parametres → Délégation → Avancé**.
3. Sur **PC01**, reconnecte `stagiaire` puis `test.vendeur`. Lance `control` dans chaque session.

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


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/guide-corrigev2)
