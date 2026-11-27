---
title: "TP 11. Stratégies de groupe et gestion centralisée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/11-gpo"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/11-gpo.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/standard" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp/standard-corrigev2">Afficher les corrections</a></nav>

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

## B. Ajouter les administrateurs locaux

### B1 — Créer la GPO des administrateurs de postes

Sur **SRV01**, crée `GPO-Postes-Admins-Locaux` et lie-la à **Ordinateurs**.

### B2 — Ajouter le groupe du domaine au groupe local

Sur **SRV01**, configure la GPO pour ajouter `FOURNIL\G-Admins-Postes` aux **Administrateurs** locaux de `PC01`. Conserve les membres actuels.

**Ordinateurs → GPO-Postes-Admins-Locaux → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Paramètres Windows → Paramètres de sécurité → Groupes restreints**.

### B3 — Vérifier l’ajout sur PC01

Sur **PC01**, dans la session `FOURNIL\Administrateur`, actualise les stratégies ordinateur et vérifie que `FOURNIL\G-Admins-Postes` figure dans les Administrateurs locaux.

## C. Distribuer le lecteur Commun

### C1 — Préparer et tester le partage

Sur **SRV01**, prépare le partage `Commun` s’il manque. Sur **PC01**, ouvre `\\SRV01\Commun` dans la session `FOURNIL\stagiaire`, puis crée et supprime un fichier de test.

### C2 — Créer la GPO et configurer le lecteur

Sur **SRV01**, crée et lie `GPO-Utilisateurs-Lecteur-Commun` sous **Utilisateurs**. Fais pointer `P:` vers `\\SRV01\Commun`, avec le libellé `Commun`.

**Utilisateurs → GPO-Utilisateurs-Lecteur-Commun → Modifier**

Dans l’éditeur, ouvre **Configuration utilisateur → Préférences → Paramètres Windows → Mappages de lecteurs**.

### C3 — Réserver le lecteur au groupe Boulangerie

Sur **SRV01**, réserve l’application de la GPO à `G-Boulangerie`. Garde **Lecture** pour **Utilisateurs authentifiés**.

**Utilisateurs → GPO-Utilisateurs-Lecteur-Commun → Délégation → Avancé**

### C4 — Comparer deux utilisateurs sur le même poste

Sur **PC01**, reconnecte-toi en `FOURNIL\stagiaire` et cherche `P:` dans **Ce PC**. Recommence avec `FOURNIL\test.vendeur`, qui est dans la même UO et hors de `G-Boulangerie`. Note le résultat de chaque session.

## D. Comprendre pourquoi une GPO s’applique

### D1 — Lire les résultats sur PC01

Sur **PC01**, relève la GPO appliquée à `stagiaire` et celle qui ajoute les administrateurs locaux au poste.

### D2 — Expliquer une GPO absente

**Cas fictif.** Un poste a été déplacé dans **Computers** et ne reçoit plus `GPO-Postes-Admins-Locaux`. Compare l’emplacement de `PC01` dans AD au lien de la GPO. Explique le résultat en gardant `PC01` dans son UO.

**Ordinateurs → GPO-Postes-Admins-Locaux**

## E. Créer un compte de dépannage avec Windows LAPS

### E1 — Préparer Active Directory

Sur **SRV01**, prépare le schéma Windows LAPS et autorise chaque ordinateur de l’UO **Ordinateurs** à sauvegarder ses propres informations.

### E2 — Créer et activer adm-laps par GPO

Sur **SRV01**, crée et lie `GPO-Postes-LAPS` sous **Ordinateurs** pour créer `adm-laps` et sauvegarder son mot de passe chiffré dans AD.

**Ordinateurs → GPO-Postes-LAPS → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Système → LAPS**.

### E3 — Vérifier le compte et la sauvegarde

Sur **PC01**, vérifie que `adm-laps` est actif et que le compte Administrateur intégré est désactivé. Sur **SRV01**, vérifie la sauvegarde de `adm-laps` dans AD.

## F. Ateliers facultatifs

### F1 — Différer les mises à jour qualité

Sur **SRV01**, crée et lie `GPO-Postes-Windows-Update` sous **Ordinateurs** pour reporter les mises à jour qualité de **7 jours**.

**Ordinateurs → GPO-Postes-Windows-Update → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Composants Windows → Windows Update → Gérer les mises à jour proposées de Windows Update**.

### F2 — Bloquer le Panneau de configuration

Sur **SRV01**, crée et lie `GPO-Utilisateurs-Bloquer-Parametres` sous **Utilisateurs**. Réserve le blocage du Panneau de configuration aux membres de `G-Boulangerie`.

**Utilisateurs → GPO-Utilisateurs-Bloquer-Parametres → Modifier**

Dans l’éditeur, ouvre **Configuration utilisateur → Stratégies → Modèles d’administration → Panneau de configuration**.

### F3 — Sauvegarder une clé de récupération BitLocker

Si `PC01` a déjà un protecteur de récupération du TP 09, crée et lie `GPO-Postes-BitLocker` sous **Ordinateurs** sur **SRV01**. Sauvegarde le protecteur dans AD.

**Ordinateurs → GPO-Postes-BitLocker → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Composants Windows → Chiffrement de lecteur BitLocker → Lecteurs du système d’exploitation**.
