# TP 18. Environnement utilisateur et Microsoft 365, version guidée

**Ta mission.** Prépare l’environnement utilisateur sur `PC01` et `PC02`, puis contrôle sur `SRV01` qu’un partage de direction est réservé aux personnes prévues. Utilise les comptes et groupes du domaine Fournil.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/standard)

## Lire les profils sur PC01

### A1 — Associer profil, utilisateur et dernière utilisation

Sur `PC01`, ouvre PowerShell administrateur. Lance `Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special } | Select-Object LocalPath,SID,LastUseTime`. Compare les lignes de `employe1` et `stagiaire` si les deux ont déjà ouvert une session.

### A2 — Trouver l’outil de gestion des profils

Ouvre `sysdm.cpl` → **Paramètres système avancés → Profils des utilisateurs → Paramètres**. Repère un profil de test dont la session est fermée et consulte sa taille.

## Contrôler l’accès à un partage

### B1 — Créer le groupe et le partage Direction

Sur `SRV01`, crée le groupe de sécurité global `G-Direction` dans **Fournil → Groupes**. Ajoute un compte de test et garde `stagiaire` hors du groupe. Partage `C:\Partages\Direction` en attribuant la modification au groupe via les droits de partage et NTFS. Garde les droits d’administration et SYSTEM.

### B2 — Vérifier avec deux utilisateurs

Sur `PC01`, après reconnexion, ouvre `\\SRV01\Direction` avec le compte membre et crée un fichier de test. Répète l’accès avec `stagiaire` dans une autre session. Sur `SRV01`, contrôle `Get-SmbShareAccess -Name Direction` et `icacls C:\Partages\Direction`.

## Préparer et remettre le poste

### C1 — Préparer les réglages Microsoft 365 sans déployer

Dans le scénario de la remise, relève les valeurs **64 bits**, **français** et **Canal Entreprise mensuel**. Pour chaque valeur, retrouve le champ correspondant dans la documentation ODT. Sur ta fiche, écris la commande qui utiliserait `configuration-fournil.xml`, sans lancer le déploiement.

### C2 — Vérifier les applications disponibles

Sur `PC02`, vérifie **Paramètres → Applications installées** ou utilise `winget list` pour retrouver Teams. Relève le résultat réel de ta VM.

### C3 — Faire la recette technique

Sur `PC02`, vérifie la jonction, Windows Update, `Get-MpComputerStatus` et `manage-bde -status C:`. Sur `SRV01`, vérifie la présence des informations LAPS de `PC02` sans afficher le secret. Dans la session `FOURNIL\stagiaire`, ouvre le lecteur `P:` si la GPO s’applique.

### C4 — Expliquer la prise en main à l’utilisateur

Écris deux phrases que tu dirais à `stagiaire` avant un partage d’écran avec le support.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/guide-corrigev2)
