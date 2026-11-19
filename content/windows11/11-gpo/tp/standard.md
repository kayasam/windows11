---
title: "TP 11. Stratégies de groupe et gestion centralisée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/11-gpo"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/11-gpo.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/standard" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/standard-corrigev2">Afficher les corrections</a></nav>

> [!abstract] Parcours TSSR
> Les RSAT sont préchargés et vérifiés en A1. Le partage Commun doit exister avant C ; sa préparation guidée est incluse dans C. Les GPO restent créées et testées par le stagiaire.

> Chapitres associés : [11. Stratégies de groupe et gestion centralisée](https://cours.kaya.ovh/windows11/windows11/11-gpo/)

---

## Objectifs

- Administrer les GPO depuis `PC01` (RSAT)
- Créer une GPO **ordinateur** de sécurité : admins locaux et anneau Windows Update. Windows LAPS est proposé en (bonus)
- Créer une GPO **utilisateur** filtrée sur un groupe : lecteur réseau et restriction
- Diagnostiquer avec `gpresult`

---

## Prérequis

- `SRV01` contrôleur de domaine, `PC01` joint dans `OU=Ordinateurs,OU=Fournil` (TP 10)
- Session `FOURNIL\Administrateur` sur `SRV01` pour créer les GPO ; sur `PC01`, une session `FOURNIL\Administrateur` (ou `PC01\admin`) pour les vérifications, puis `FOURNIL\stagiaire` pour la partie C

---

Après le TP 10, réalise les parties A à D en suivant les étapes du socle. Saute les étapes marquées **(bonus)** si le temps est compté.

## Partie A — Outils

**A1.** Ouvre la console **Gestion de stratégie de groupe** sur `SRV01` (session `FOURNIL\Administrateur`). Où la trouve-t-on ? (bonus : installe aussi les RSAT sur `PC01`.)

**A2.** Ouvre `gpmc.msc`. Quelles GPO existent déjà ? Où sont-elles liées ?

**A3.** (bonus) Où sont stockées physiquement les GPO ? Retrouve le dossier de la *Default Domain Policy*.

---

## Partie B — GPO ordinateur « GPO-Postes-Securite »

**B1.** Crée la GPO `GPO-Postes-Securite` et lie-la à `OU=Ordinateurs,OU=Fournil` (GPMC ou PowerShell).

**B2.** Fais en sorte que `FOURNIL\GG-Admins-Postes` soit administrateur local de tous les postes de l'UO. Deux méthodes possibles : lesquelles ? Choisis-en une.

**B3.** (bonus) Sur `SRV01`, prépare Active Directory pour **Windows LAPS**. Modifie ensuite `GPO-Postes-Securite`, créée en B1 et liée à `Fournil → Ordinateurs`. Configure la sauvegarde dans AD, une longueur de 14 caractères et un âge de 30 jours.

**B4.** Ajoute un report de **7 jours** des mises à jour qualité (anneau « large »).

**B5.** Applique la GPO sur `PC01`, puis vérifie le groupe des administrateurs locaux et le report des mises à jour qualité. (bonus) Si tu as fait B3, vérifie aussi Windows LAPS.

**B6.** (bonus) Le mot de passe LAPS est bien dans AD… mais un technicien ne peut pas s'en servir pour ouvrir une session. Pourquoi ?

---

## Partie C — GPO utilisateur filtrée

Sur `SRV01`, un partage `\\SRV01\Commun` est accessible en modification au groupe `G-Boulangerie`. Avant C1, prépare-le avec ce modèle guidé (sur SRV01, après le TP 10) :

```powershell
New-Item C:\Partages\Commun -ItemType Directory -Force
icacls C:\Partages\Commun /inheritance:r
icacls C:\Partages\Commun /grant 'SYSTEM:(OI)(CI)F' 'BUILTIN\Administrateurs:(OI)(CI)F' 'FOURNIL\G-Boulangerie:(OI)(CI)M'
New-SmbShare -Name Commun -Path C:\Partages\Commun -ChangeAccess 'FOURNIL\G-Boulangerie' -FullAccess 'FOURNIL\Admins du domaine'
```

Vérifie l’accès avec `stagiaire` avant de créer le mappage.

**C1.** Crée la GPO `GPO-Boulangerie-Utilisateurs`, liée à `OU=Utilisateurs,OU=Fournil`.

**C2.** Ajoute une **préférence** qui monte `\\SRV01\Commun` en `P:`, nommé « Commun ». Pourquoi une préférence et pas une stratégie ?

**C3.** Ajoute la stratégie « Interdire l'accès au Panneau de configuration et à l'application Paramètres du PC ».

**C4.** Restreins la GPO aux membres de `G-Boulangerie`. Quelle erreur classique faut-il éviter ?

**C5.** Ferme la session en cours sur `PC01` et ouvre une session `FOURNIL\stagiaire`. Vérifie le lecteur `P:` et la restriction.

**C6.** Crée un utilisateur `test.vendeur` dans `OU=Utilisateurs`, **hors** de `G-Boulangerie`. Que reçoit-il ?

---

## Partie D — Diagnostic

**D1.** Avec `gpresult`, affiche les GPO ordinateur puis utilisateur appliquées sur `PC01`. (bonus) Produis aussi un rapport HTML.

**D2.** Un collègue a déplacé `PC01` dans `CN=Computers` par erreur. Que montre `gpresult` ? Pourquoi ?

**D3.** (bonus) Où chercher si une GPO ne s'applique pas du tout (aucune trace) ?

---

## Partie E — Exercices complémentaires (bonus)

**E1.** (bonus) Sauvegarde toutes les GPO du domaine dans `C:\Sauvegarde\GPO` en une commande.

**E2.** (bonus) Explique à quoi servirait **Group Policy Analytics** si le Fournil passait à Intune.

---

## Partie F — Atelier facultatif BitLocker (bonus)

Fais cet atelier si le chapitre 09 a été traité et si `PC01` possède déjà un protecteur de récupération. Si tu as passé le chapitre 09, le TP est terminé après les vérifications de la partie D. Tu peux revenir ici plus tard.

**F1.** (bonus) Configure la sauvegarde des clés de récupération BitLocker du disque système dans AD DS.

**F2.** (bonus) La clé BitLocker n'apparaît pas dans AD. Pourquoi ? Corrige.

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/standard-corrigev2)
