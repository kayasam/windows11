---
title: "TP 03. Configuration et personnalisation"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/03-configuration"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/03-configuration/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/03-configuration/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/03-configuration.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/03-configuration/tp" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/03-configuration/tp-corrigev2">Afficher les corrections</a></nav>

> Durée estimée : 1h15

> Chapitres associés : [03. Configuration et personnalisation](https://cours.kaya.ovh/windows11/windows11/03-configuration/)

---

## Objectifs

- Prendre en main l'interface Windows 11 26H2 et ses raccourcis
- Savoir où trouver un réglage : Paramètres ou Panneau de configuration
- Créer et gérer des comptes locaux (graphique et PowerShell)
- Donner à `PC01` son adresse IP fixe du plan d'adressage
- Manipuler les variables d'environnement

---

## Prérequis

- `PC01` installé (TP 02), session `admin`
- Réseau `vSwitch-Rennes` + NAT opérationnels (TP 01)

---

## Partie A — Interface (15 min)

**A1.** Ouvre le menu Démarrer. Nomme ses trois zones. Masque les recommandations.

**A2.** Ouvre trois fenêtres et organise-les en 50/25/25 avec les Snap Layouts, au clavier uniquement.

**A3.** Crée un bureau virtuel « Admin », place-y un terminal, puis reviens au bureau 1. Quels raccourcis as-tu utilisés ?

**A4.** Aligne la barre des tâches à gauche et masque le bouton Widgets.

---

## Partie B — Paramètres ou Panneau de configuration ? (10 min)

**B1.** Pour chaque réglage, indique l'outil et la commande la plus rapide pour l'ouvrir :
1. Changer l'adresse IP de la carte réseau
2. Voir la RAM, le processeur, le nom du PC
3. Désinstaller un programme `.msi` ancien
4. Ouvrir les options Internet (proxy Win32)
5. Gérer les utilisateurs et groupes locaux

---

## Partie C — Comptes locaux (20 min)

**C1.** Crée, en PowerShell, l'utilisateur standard `employe1` (mot de passe `Fournil2026!`, nom complet « Employé 1 ») et ajoute-le au groupe **Utilisateurs**.

**C2.** Affiche son SID. Quelle partie du SID identifie la machine, et laquelle identifie le compte ?

**C3.** Liste les membres du groupe **Utilisateurs**. Pourquoi y trouve-t-on aussi `admin` et des entrées `AUTORITE NT\…` ?

**C4.** Crée le compte `stagiaire` dans `lusrmgr.msc`, avec « L'utilisateur doit changer le mot de passe à la prochaine ouverture de session ». Désactive-le ensuite en PowerShell.

**C5.** Quels sont les comptes locaux présents par défaut sur le poste ? Lesquels sont désactivés, et pourquoi ?

---

## Partie D — Réseau (20 min)

**D1.** Relève la configuration IP actuelle de `PC01`. D'où vient l'adresse ?

**D2.** Configure en PowerShell : IP `192.168.3.10/24`, passerelle `192.168.3.254`, DNS `1.1.1.1` et `8.8.8.8`.

**D3.** Teste la passerelle, Internet par IP, puis la résolution DNS. Dans quel ordre, et pourquoi cet ordre ?

**D4.** Quel profil réseau (Public/Privé) est appliqué ? Pourquoi ?

---

## Partie E — Variables d'environnement (10 min)

**E1.** Affiche `COMPUTERNAME`, `USERPROFILE` et le `PATH` en PowerShell, puis en CMD.

**E2.** Crée la variable système `FOURNIL_ENV=lab`. Pourquoi ne la vois-tu pas dans le terminal déjà ouvert ?

**E3.** Ajoute `C:\Outils` au `PATH` système **sans l'écraser**.

---

## Partie F — Bonus

**F1.** Réécris la partie D en un script `Set-IPFixe.ps1` paramétrable (`-IP`, `-Passerelle`, `-DNS`).

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/03-configuration/tp-corrigev2)
