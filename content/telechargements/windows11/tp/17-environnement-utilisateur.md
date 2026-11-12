# TP 18. Environnement utilisateur et Microsoft 365

> Durée estimée : 1h30

> Chapitres associés : [18. Environnement utilisateur et Microsoft 365](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/)

---

## Objectifs

- Inspecter et dépanner les profils utilisateurs
- Publier un dossier partagé avec les bonnes permissions
- Préparer l'installation de Microsoft 365 Apps et la configuration de OneDrive par stratégie
- Remettre `PC02` à `stagiaire` avec une check-list et des conseils de sécurité

---

## Prérequis

- `PC02` déployé et joint au domaine (TP 16), `PC01` avec RSAT
- Partage `\\SRV01\Commun` et GPO `GPO-Boulangerie-Utilisateurs` (TP 11)

---

## Partie A — Profils (20 min)

**A1.** Sur `PC01`, liste les profils (hors profils système) avec leur SID et leur date de dernière utilisation. Comment distingue-t-on un compte local d'un compte du domaine ?

**A2.** Où Windows enregistre-t-il l'association SID ↔ dossier de profil ?

**A3.** Un collègue a supprimé `C:\Users\employe1` dans l'Explorateur pour faire de la place. Qu'arrivera-t-il à `employe1` ? Comment supprimer proprement un profil ?

**A4.** Un utilisateur obtient « *Connexion avec un profil temporaire* ». Quelles sont les causes possibles et la procédure de réparation ?

---

## Partie B — Dossiers partagés (20 min)

**B1.** Sur `SRV01`, crée `\\SRV01\Direction` : seuls les membres d'un nouveau groupe `G-Direction` peuvent y écrire, les autres utilisateurs du domaine ne doivent même pas le voir.

**B2.** Vérifie les permissions de partage et les permissions NTFS. Laquelle s'applique quand elles diffèrent ?

**B3.** Depuis `PC01`, monte `\\SRV01\Commun` en `Q:` manuellement, de façon persistante, en PowerShell. Pourquoi ce n'est pas la bonne méthode à l'échelle du Fournil ?

---

## Partie C — Microsoft 365 Apps, OneDrive, Teams (30 min)

**C1.** Écris le fichier `configuration-fournil.xml` de l'Office Deployment Tool : Microsoft 365 Apps pour les entreprises, 64 bits, français, canal Entreprise mensuel, sans Skype ni OneDrive Groove, installation silencieuse, suppression des anciens Office MSI.

**C2.** Quelle commande installe Office avec ce fichier ? Pourquoi Teams n'apparaîtra-t-il pas ?

**C3.** Où trouver les modèles ADMX de OneDrive sur `PC01` ? Copie-les dans le magasin central du domaine.

**C4.** Crée une GPO `GPO-OneDrive` (ordinateurs) : connexion silencieuse, Fichiers à la demande, et **déplacement silencieux des dossiers connus** vers OneDrive. Quelle information manque pour la dernière stratégie dans le lab ?

**C5.** Le nouveau Teams est-il présent sur `PC02` sans rien faire ? Comment le vérifier ?

---

## Partie D — Remise du poste (20 min)

**D1.** Exécute la check-list technique de remise sur `PC02` (domaine, mises à jour, BitLocker, Defender, LAPS, lecteurs, numéro de série).

**D2.** Rédige les 5 conseils de sécurité que tu donnes oralement à `stagiaire` le jour de la remise.

**D3.** `stagiaire` appelle le support : il ne retrouve pas son fichier. Quels outils proposes-tu pour que le technicien voie son écran ?

---


