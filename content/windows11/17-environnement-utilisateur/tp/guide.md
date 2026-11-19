---
title: "TP 18. Environnement utilisateur et Microsoft 365, version guidée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/17-environnement-utilisateur"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/17-environnement-utilisateur-guide.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/guide" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/guide-corrigev2">Afficher les corrections</a></nav>

**Ta mission.** Prépare l’environnement utilisateur sur `PC02`, puis contrôle sur `SRV01` qu’un partage de direction est réservé aux personnes prévues. Utilise les comptes et groupes du domaine Fournil.

**Avant A1, sur `PC02`.** Ouvre une session une fois avec `FOURNIL\test.vendeur` et `FOURNIL\stagiaire`, puis ferme chaque session. `test.vendeur` vient de C6 du TP 11. Fais le reste de la partie A avec un administrateur du poste.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/standard)

## Lire les profils sur PC02

### A1 — Retrouver les profils des deux comptes

Sur `PC02`, ouvre `C:\Users` dans l’Explorateur et repère les dossiers créés pour `test.vendeur` et `stagiaire`. Si l’un manque, ouvre sa session puis ferme-la.

**(bonus)** Dans PowerShell administrateur, relie les chemins aux SID et à la dernière utilisation.

```powershell
Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special } |
    Select-Object LocalPath, SID, LastUseTime
```

### A2 — Trouver l’outil de gestion des profils

Ouvre `sysdm.cpl` → **Paramètres système avancés → Profils des utilisateurs → Paramètres**. Repère un profil de test dont la session est fermée et consulte sa taille.

## Contrôler l’accès à un partage

### B1 — Créer le groupe et le partage Direction

Sur `SRV01`, crée le groupe de sécurité global `G-Direction` dans **Fournil → Groupes**. Ajoute `test.vendeur` à ce groupe. Laisse `stagiaire` hors du groupe.

Crée `C:\Partages\Direction`, puis ouvre les propriétés du dossier.

1. **Sécurité → Avancé → Désactiver l’héritage**. Convertis les droits hérités en droits explicites, conserve les entrées d’administration et SYSTEM, retire celles qui donnent accès aux utilisateurs ordinaires puis ajoute `FOURNIL\G-Direction` avec **Modification**.
2. **Partage → Partage avancé**. Publie le dossier sous le nom `Direction`. Dans **Autorisations**, donne **Modifier** à `FOURNIL\G-Direction` et conserve l’accès d’administration. Retire `Tout le monde` si cette entrée est présente.

### B2 — Vérifier avec deux utilisateurs

1. Sur `PC02`, reconnecte `FOURNIL\test.vendeur` pour actualiser son appartenance au groupe. Ouvre `\\SRV01\Direction` et crée `test-direction.txt`.
2. Ferme la session, puis connecte `FOURNIL\stagiaire` et ouvre le même chemin. Windows doit afficher **Accès refusé**.
3. Si le résultat diffère, vérifie le bon compte avec `whoami`, puis contrôle les deux jeux de droits sur `SRV01` avec `Get-SmbShareAccess -Name Direction` et `icacls C:\Partages\Direction`.

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
