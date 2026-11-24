---
title: "TP 03. Configuration et personnalisation"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/03-configuration"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/03-configuration/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/03-configuration/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/03-configuration/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/03-configuration.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/03-configuration/tp/standard" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/03-configuration/tp/standard-corrigev2">Afficher les corrections</a></nav>

> [!abstract] Parcours TSSR
> Toutes les parties non marquées (bonus) sont à réaliser ; les exercices complémentaires sont facultatifs.
> **Méthode au choix : interface graphique ou PowerShell. Une seule méthode suffit** pour chaque manipulation ; tu peux changer de méthode selon la question. Les raccourcis clavier sont facultatifs. Le script de la partie F reste un bonus.

> Chapitres associés : [03. Configuration et personnalisation](https://cours.kaya.ovh/windows11/windows11/03-configuration/)

---

## Objectifs

- Prendre en main l'interface Windows 11 26H2 et ses raccourcis
- Savoir où trouver un réglage : Paramètres ou Panneau de configuration
- Créer et gérer des comptes locaux (interface graphique **ou** PowerShell)
- Donner à `PC01` son adresse IP fixe du plan d'adressage
- Manipuler les variables d'environnement

---

## Prérequis

- `PC01` installé (TP 02), session `admin`
- Réseau `vSwitch-Rennes` + NAT opérationnels (TP 01)

---

## Partie A — Interface

**A1.** Ouvre le menu Démarrer. Nomme ses trois zones. Masque les recommandations.

**A2.** Ouvre trois fenêtres et organise-les en 50/25/25 avec les Snap Layouts, à la souris **ou** au clavier.

**A3.** Crée un bureau virtuel « Admin », place-y un terminal, puis reviens au bureau 1, avec la Vue des tâches **ou** les raccourcis clavier. Explique comment tu as procédé.

**A4.** Aligne la barre des tâches à gauche et masque le bouton Widgets.

---

## Partie B — Paramètres ou Panneau de configuration ?

**B1.** Pour chaque réglage, indique l’outil et comment l’ouvrir : chemin dans l’interface graphique **ou** commande d’accès, au choix :
1. Changer l'adresse IP de la carte réseau
2. Voir la RAM, le processeur, le nom du PC
3. Désinstaller un programme `.msi` ancien
4. Ouvrir les options Internet (proxy Win32)
5. Gérer les utilisateurs et groupes locaux

---

## Partie C — Comptes locaux

**C1.** Crée l’utilisateur standard `employe1` (mot de passe `Fournil2026!`, nom complet « Employé 1 ») dans `lusrmgr.msc` **ou** en PowerShell. Vérifie qu’il appartient au groupe **Utilisateurs** et ajoute-le si nécessaire.

**C2.** (bonus) Observe le SID de `employe1`, fourni par le formateur **ou** relevé avec `Get-LocalUser -Name employe1 | Select-Object Name, SID`. Quelle partie du SID identifie la machine, et laquelle identifie le compte ? Il n’est pas nécessaire d’utiliser PowerShell si tu travailles à partir du relevé fourni.

**C3.** Affiche les membres du groupe **Utilisateurs**, dans `lusrmgr.msc` → **Groupes** → **Utilisateurs**, **ou** en PowerShell. Pourquoi y trouve-t-on aussi `admin` et des entrées `AUTORITE NT\…` ?

**C4.** Crée le compte `employe2`, avec « L’utilisateur doit changer le mot de passe à la prochaine ouverture de session ». Vérifie à quel groupe il appartient, puis désactive-le. Utilise `lusrmgr.msc` (propriétés du compte → **Le compte est désactivé**) **ou** PowerShell avec les commandes complémentaires nécessaires.

**C5.** Quels sont les comptes locaux présents par défaut sur le poste ? Lesquels sont désactivés, et pourquoi ?

---

## Partie D — Réseau

**D1.** Relève la configuration IP actuelle de `PC01`, dans les détails de la carte réseau **ou** en PowerShell. D’où vient l’adresse ?

**D2.** Configure dans `ncpa.cpl` **ou** en PowerShell : IP `192.168.3.10/24`, passerelle `192.168.3.254`, DNS `8.8.8.8` et `1.1.1.1`.

**D3.** Teste la passerelle, Internet par IP, puis la résolution DNS, avec les outils de ton choix. Le formateur peut fournir les commandes de test si nécessaire. Dans quel ordre, et pourquoi cet ordre ?

**D4.** Quel profil réseau (Public/Privé) est appliqué ? Consulte les propriétés de la connexion dans les Paramètres **ou** utilise PowerShell. Pourquoi ce profil ?

---

## Partie E — Variables d'environnement

**E1.** Retrouve le nom de l’ordinateur (`COMPUTERNAME`), le dossier du profil courant (`USERPROFILE`) et le `PATH`, avec **une seule méthode au choix** :
- **En graphique** : nom du PC dans les informations système ; ouvrir `%USERPROFILE%` dans la barre d’adresse de l’Explorateur ; consulter `Path` dans `sysdm.cpl` → **Paramètres système avancés** → **Variables d’environnement**.
- **En PowerShell** : afficher `$env:COMPUTERNAME`, `$env:USERPROFILE` et `$env:PATH`.

**E2.** Crée la variable système `FOURNIL_ENV=lab`, dans la fenêtre **Variables d’environnement** → **Variables système** → **Nouvelle**, **ou** en PowerShell. Pourquoi un terminal déjà ouvert peut-il conserver l’ancien environnement ?

**E3.** Ajoute `C:\Outils` au `PATH` système **sans l’écraser**, dans **Variables système** → **Path** → **Modifier** → **Nouveau**, **ou** en PowerShell. Conserve toutes les entrées existantes.

---

## Partie F — Exercices complémentaires (bonus)

**F1.** Réécris la partie D en un script `Set-IPFixe.ps1` paramétrable (`-IP`, `-Passerelle`, `-DNS`).

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/03-configuration/tp/standard-corrigev2)
