# TP 18. Environnement utilisateur et Microsoft 365, corrigé guidé

**Ta mission.** Prépare l’environnement utilisateur sur `PC01` et `PC02`, puis contrôle sur `SRV01` qu’un partage de direction est réservé aux personnes prévues. Utilise les comptes et groupes du domaine Fournil.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/standard)

## Lire les profils sur PC01

### A1 — Associer profil, utilisateur et dernière utilisation

Sur `PC01`, ouvre PowerShell administrateur. Lance `Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special } | Select-Object LocalPath,SID,LastUseTime`. Compare les lignes de `employe1` et `stagiaire` si les deux ont déjà ouvert une session.

> [!success]- Afficher la correction — A1
> `LocalPath` indique le dossier, `SID` l’identité et `LastUseTime` la dernière utilisation connue. Le nom du dossier seul ne permet pas de distinguer de façon fiable un compte local d’un compte de domaine.

### A2 — Trouver l’outil de gestion des profils

Ouvre `sysdm.cpl` → **Paramètres système avancés → Profils des utilisateurs → Paramètres**. Repère un profil de test dont la session est fermée et consulte sa taille.

> [!success]- Afficher la correction — A2
> Cet outil supprime le profil et son enregistrement Windows après validation. Avant toute suppression réelle, confirme le bon compte et sauvegarde les données nécessaires.

## Contrôler l’accès à un partage

### B1 — Créer le groupe et le partage Direction

Sur `SRV01`, crée le groupe de sécurité global `G-Direction` dans **Fournil → Groupes**. Ajoute un compte de test et garde `stagiaire` hors du groupe. Partage `C:\Partages\Direction` en attribuant la modification au groupe via les droits de partage et NTFS. Garde les droits d’administration et SYSTEM.

> [!success]- Afficher la correction — B1
> Les permissions NTFS et SMB doivent toutes deux permettre la modification aux membres de `G-Direction`. Une énumération basée sur l’accès peut masquer des dossiers non autorisés à l’intérieur d’un partage. Elle ne masque pas à elle seule le nom du partage.

### B2 — Vérifier avec deux utilisateurs

Sur `PC01`, après reconnexion, ouvre `\\SRV01\Direction` avec le compte membre et crée un fichier de test. Répète l’accès avec `stagiaire` dans une autre session. Sur `SRV01`, contrôle `Get-SmbShareAccess -Name Direction` et `icacls C:\Partages\Direction`.

> [!success]- Afficher la correction — B2
> Le membre crée le fichier. `stagiaire` reçoit un refus d’accès dans ce scénario. Le résultat combine les permissions de partage, les permissions NTFS et les groupes du jeton de la session.

## Préparer et remettre le poste

### C1 — Préparer les réglages Microsoft 365 sans déployer (bonus)

Dans le scénario de la remise, relève les valeurs **64 bits**, **français** et **Canal Entreprise mensuel**. Pour chaque valeur, retrouve le champ correspondant dans la documentation ODT. Sur ta fiche, écris la commande qui utiliserait `configuration-fournil.xml`, sans lancer le déploiement.

> [!success]- Afficher la correction — C1
> Le fichier utilise `OfficeClientEdition="64"`, `Channel="MonthlyEnterprise"` et `Language ID="fr-fr"`. L’outil ODT porte ces choix vers le poste avec `setup.exe /configure configuration-fournil.xml`. [Options de configuration ODT](https://learn.microsoft.com/en-us/microsoft-365-apps/deploy/office-deployment-tool-configuration-options)

### C2 — Vérifier les applications disponibles

Sur `PC02`, vérifie **Paramètres → Applications installées** ou utilise `winget list` pour retrouver Teams. Relève le résultat réel de ta VM.

> [!success]- Afficher la correction — C2
> L’application peut être absente selon l’image et les licences. Identifie l’application effectivement installée avant de conclure ou de demander le déploiement Office.

### C3 — Faire la recette technique

Sur `PC02`, vérifie la jonction, Windows Update, `Get-MpComputerStatus` et `manage-bde -status C:`. **(bonus) Si LAPS a été configuré au TP 11**, vérifie sur `SRV01` la présence des informations LAPS de `PC02` sans afficher le secret. Dans la session `FOURNIL\stagiaire`, ouvre le lecteur `P:` si la GPO s’applique.

> [!success]- Afficher la correction — C3
> Une fiche de remise distingue les résultats ordinateur des résultats propres à la session. Pour chaque écart, note la preuve et le responsable de sa correction.

### C4 — Expliquer la prise en main à l’utilisateur

Écris deux phrases que tu dirais à `stagiaire` avant un partage d’écran avec le support.

> [!success]- Afficher la correction — C4
> L’utilisateur doit vérifier l’identité du technicien, savoir ce qui sera partagé et donner son consentement avant le contrôle. Il ferme l’assistance une fois l’intervention terminée.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/guide)
