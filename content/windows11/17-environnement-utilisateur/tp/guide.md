---
title: "TP 18. Environnement utilisateur et Microsoft 365, version guidée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/17-environnement-utilisateur"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/17-environnement-utilisateur-guide.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/guide" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/guide-corrigev2">Afficher les corrections</a></nav>

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

### C1 — Préparer les réglages Microsoft 365 sans déployer (bonus)

Dans le scénario de la remise, relève les valeurs **64 bits**, **français** et **Canal Entreprise mensuel**. Pour chaque valeur, retrouve le champ correspondant dans la documentation ODT. Sur ta fiche, écris la commande qui utiliserait `configuration-fournil.xml`, sans lancer le déploiement.

### C2 — Vérifier les applications disponibles

Sur `PC02`, vérifie **Paramètres → Applications installées** ou utilise `winget list` pour retrouver Teams. Relève le résultat réel de ta VM.

### C3 — Faire la recette technique

Sur `PC02`, vérifie la jonction, Windows Update, `Get-MpComputerStatus` et `manage-bde -status C:`. **(bonus) Si LAPS a été configuré au TP 11**, vérifie sur `SRV01` la présence des informations LAPS de `PC02` sans afficher le secret. Dans la session `FOURNIL\stagiaire`, ouvre le lecteur `P:` si la GPO s’applique.

### C4 — Expliquer la prise en main à l’utilisateur

Écris deux phrases que tu dirais à `stagiaire` avant un partage d’écran avec le support.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/guide-corrigev2)
