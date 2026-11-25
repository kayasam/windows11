---
title: "TP 18. Environnement utilisateur et Microsoft 365"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/17-environnement-utilisateur"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/17-environnement-utilisateur.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/standard" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/tp/standard-corrigev2">Afficher les corrections</a></nav>


> [!abstract] Parcours TSSR
> Socle : profils, dossier partagé, rôle de OneDrive/Teams et remise du poste. Le lab n'a pas de tenant Microsoft 365 : l'installation d'Office et les GPO OneDrive sont (bonus).

> Chapitres associés : [18. Environnement utilisateur et Microsoft 365](https://cours.kaya.ovh/windows11/windows11/17-environnement-utilisateur/)

---

## Objectifs

- Voir les profils d'un poste, en supprimer un proprement, réparer un profil temporaire
- Créer un dossier partagé réservé à un groupe
- Savoir à quoi servent OneDrive et Teams
- Remettre `PC02` à un utilisateur avec une check-list et des conseils de sécurité

---

## Prérequis

- `SRV01` et `PC02` allumées, `PC02` joint au domaine (TP 16)
- Sur `PC02` : session `FOURNIL\adm.stagiaire` ; sur `SRV01` : session `FOURNIL\Administrateur`
- `test.vendeur` doit avoir un profil sur `PC02`. Ouvre une fois une session avec ce compte dans la console de `PC02`, puis ferme-la.

---

## Partie A — Profils

**A1.** Sur `PC02`, ouvre la liste des profils en graphique (`sysdm.cpl`). Quels comptes ont un profil ? Comment reconnais-tu un compte du domaine d'un compte local ?

**A2.** Supprime **proprement** le profil de `test.vendeur`. Pourquoi le bouton *Supprimer* est-il grisé quand tu sélectionnes `adm.stagiaire` ?

**A3.** Prépare une panne réaliste :
1. Ouvre une session `FOURNIL\test.vendeur` sur `PC02` (*Changer d'utilisateur* avec `Ctrl + Alt + Suppr`), puis **déconnecte-la**.
2. Reviens en `adm.stagiaire`. Dans l'Explorateur, renomme `C:\Users\test.vendeur` en `test.vendeur.old` (accepte la demande d'autorisation administrateur). C'est ce que fait un collègue qui « fait de la place ».
3. Reconnecte `test.vendeur`. Que se passe-t-il ? Où est enregistré son bureau dans cette session ?

**A4.** Répare le profil de `test.vendeur` pour qu'il retrouve un profil normal. Comment récupérerais-tu ses anciens documents ?

---

## Partie B — Dossier partagé

**B1.** Sur `SRV01`, dans `dsa.msc`, crée le groupe de sécurité global `G-Direction` dans *Fournil → Groupes* et ajoutes-y `test.vendeur`.

**B2.** Toujours sur `SRV01`, avec le **Gestionnaire de serveur**, crée le partage `\\SRV01\Direction` (dossier `C:\Partages\Direction`) : seuls les membres de `G-Direction` peuvent lire et écrire, les autres utilisateurs du domaine n'ont aucun accès. Active l'énumération basée sur l'accès.

**B3.** Sur `PC02` (en `adm.stagiaire`), tape `\\SRV01` dans `Win + R`. Le partage `Direction` apparaît-il ? Ouvre-le : que se passe-t-il ?

**B4.** Le partage donne *Contrôle total* à *Tout le monde*. Pourquoi `adm.stagiaire` ne peut-il quand même pas entrer ?

**B5.** (bonus) Sur `PC02`, connecte `\\SRV01\Commun` en lecteur `Q:` à la main. Pourquoi ce n'est pas la bonne méthode pour les 35 postes du Fournil ?

---

## Partie C — Microsoft 365, OneDrive, Teams

**C1.** Le nouveau Teams est-il installé sur `PC02` sans rien faire ? Vérifie en graphique.

**C2.** Explique avec tes mots, et un exemple au Fournil, la différence entre **synchroniser**, **partager** et **sauvegarder** avec OneDrive.

**C3.** (bonus) Écris le fichier `configuration-fournil.xml` de l'Office Deployment Tool : Microsoft 365 Apps pour les entreprises, 64 bits, français, canal Entreprise mensuel, sans Skype ni Groove, installation silencieuse, suppression des anciens Office. Quelle commande l'utilise ?

**C4.** (bonus) Quelle stratégie OneDrive sauvegarderait automatiquement Bureau, Documents et Images ? Quelle information manque dans le lab pour l'activer ?

---

## Partie D — Remise du poste

**D1.** Passe la check-list technique sur `PC02` (domaine, GPO, mises à jour, BitLocker, Defender, numéro de série). Un point bloque-t-il la remise ? (bonus) Vérifie LAPS si la stratégie a été configurée au TP 11.

**D2.** Rédige les 5 conseils de sécurité que tu donnes oralement à `stagiaire` le jour de la remise.

**D3.** `stagiaire` appelle le support : il ne retrouve pas un fichier. Quels outils proposes-tu ?

---


