---
title: "TP 12. Administration et assistance à distance"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/12-acces-distant"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/12-acces-distant.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp-corrigev2">Afficher les corrections</a></nav>

> Durée estimée : 1h45

> Chapitres associés : [12. Administration et assistance à distance](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/)

---

## Objectifs

- Activer et utiliser le Bureau à distance
- Administrer plusieurs postes en PowerShell Remoting et WinRS
- Utiliser OpenSSH entre Windows, puis PowerShell Remoting sur SSH
- Installer les RSAT et administrer AD depuis `PC01`
- Connaître les outils d'assistance (Assistance rapide, Remote Help)

---

## Prérequis

- `PC01`, `PC02`, `SRV01` dans le domaine (TP 10, TP 16)
- Session `PC01` avec un compte administrateur des postes

---

## Partie A — Bureau à distance (20 min)

**A1.** Le port RDP de `PC02` est-il ouvert ? Vérifie depuis `PC01` sans ouvrir `mstsc`.

**A2.** Active le Bureau à distance sur `PC02` **à distance**, sans t'y connecter graphiquement. Quelle méthode utilises-tu ?

**A3.** Connecte-toi à `PC02` avec `mstsc`. Qui a le droit de s'y connecter ? Comment autoriser `sguillard` ?

**A4.** Quel client utiliserais-tu pour un PC cloud Windows 365 ?

---

## Partie B — PowerShell Remoting et WinRS (30 min)

**B1.** L'état du service WinRM sur `PC01`, `PC02` et `SRV01`. Que constates-tu ?

**B2.** Active PowerShell Remoting sur `PC02`. Quelles règles de pare-feu sont créées, pour quels profils ?

**B3.** Depuis `PC01`, affiche en une commande le nom et la version de Windows de `SRV01` et `PC02`. Pourquoi aucun mot de passe n'est-il demandé ?

**B4.** Ouvre une session interactive sur `SRV01`, liste les services DHCP et DNS, quitte.

**B5.** Avec WinRS, exécute `ipconfig /all` sur `SRV01`.

**B6.** Comment activerais-tu WinRM sur les 35 postes du Fournil ?

---

## Partie C — OpenSSH (30 min)

**C1.** Le client SSH est-il présent sur `PC01` ? Le port 22 de `SRV01` répond-il ?

**C2.** Connecte-toi en SSH à `SRV01`. Quel shell obtiens-tu ? Fais en sorte que ce soit PowerShell.

**C3.** Génère une paire de clés ed25519 sur `PC01` et configure l'authentification par clé pour `Administrateur` sur `SRV01`. Quel fichier particulier faut-il utiliser pour un compte administrateur ?

**C4.** Installe PowerShell 7 sur `SRV01` (Server Core), déclare le sous-système SSH et ouvre une session `Enter-PSSession -HostName`.

---

## Partie D — RSAT et assistance (20 min)

**D1.** Installe sur `PC01` les outils AD DS, DNS, DHCP et GPMC. Ouvre `dsa.msc` et crée un utilisateur `test.vendeur` dans `OU=Utilisateurs`.

**D2.** Lance l'Assistance rapide. Qui a besoin d'un compte Microsoft ? Quel risque de sécurité faut-il expliquer aux utilisateurs ?

**D3.** Quelles différences entre Assistance rapide et Remote Help ?

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp-corrigev2)
