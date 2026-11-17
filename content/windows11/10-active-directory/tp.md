---
title: "TP 10. Intégration Active Directory"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/10-active-directory"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/10-active-directory/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/10-active-directory/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/10-active-directory.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>


> Chapitres associés : [10. Intégration Active Directory](https://cours.kaya.ovh/windows11/windows11/10-active-directory/)

---

## Objectifs

- Installer `SRV01` (Windows Server 2025 avec expérience de bureau) et le préparer (IP, nom, SSH)
- Créer la forêt `ad.fournil.lab` (AD DS + DNS) et le DHCP
- Créer la structure d'UO, les utilisateurs et les groupes du Fournil
- Joindre `PC01` au domaine **dans la bonne UO** et vérifier la jonction

---

## Prérequis

- ISO Windows Server 2025 (évaluation) dans `D:\ISO\`
- `PC01` opérationnel sur `vSwitch-Rennes`

---

## Partie A — Installer et préparer SRV01

**A1.** Crée la VM `SRV01` (Gen 2, 4 Go **statiques**, 2 vCPU, 64 Go, `vSwitch-Rennes`) et installe **Windows Server 2025 Standard Evaluation avec l'expérience de bureau** — laquelle des quatre entrées choisir, et laquelle est présélectionnée ? Mot de passe Administrateur : `Fournil2026!`.

**A2.** Depuis **Gestionnaire de serveur → Serveur local** (ou en PowerShell) : IP `192.168.3.1/24`, passerelle `.254`, DNS provisoire `1.1.1.1`, puis nom `SRV01`. Pourquoi un DNS provisoire ?

**A3.** OpenSSH Server est-il installé ? Démarré ? La règle de pare-feu s'applique-t-elle au profil actif ? Corrige ce qu'il faut et connecte-toi depuis `PC01` en SSH **par IP**.

---

## Partie B — Domaine, DNS, DHCP

**B1.** Installe les rôles AD DS, DNS et DHCP (assistant *Ajouter des rôles et fonctionnalités*, ou une seule commande PowerShell).

**B2.** Promeus `SRV01` en premier contrôleur de la forêt `ad.fournil.lab` (NetBIOS `FOURNIL`, niveau `Win2025`). Quelles valeurs proposées par l'assistant faut-il corriger ? Que se passe-t-il à la fin ? Que ne faut-il surtout pas faire pendant le redémarrage qui suit ?

**B3.** Juste après le redémarrage, `Get-ADDomain` répond « *Impossible de trouver un serveur par défaut avec les services Web Active Directory* ». Diagnostique.

**B4.** Vérifie : DNS client de `SRV01`, zones DNS créées, profil réseau.

**B5.** Déclare un redirecteur DNS vers `1.1.1.1`, puis vérifie que `SRV01` résout un nom Internet.

**B6.** Autorise le DHCP dans AD et crée l'étendue `vSwitch-Rennes` `192.168.3.100-200` (routeur `.254`, DNS `.1`, domaine `ad.fournil.lab`). Vérifie ensuite les trois options de l'étendue.

---

## Partie C — Structure du Fournil

**C1.** Crée l'arborescence d'UO : `Fournil` › `Utilisateurs`, `Ordinateurs`, `Groupes`, `Admins` (dans `dsa.msc` ou en PowerShell).

**C2.** Crée l'utilisateur standard `stagiaire` (nom complet *Stagiaire Boulangerie*) et le compte d'administration des postes `adm.stagiaire`, tous deux avec le mot de passe du lab `Fournil2026!`, sans changement imposé à la première ouverture de session.

**C3.** Crée les groupes globaux `G-Boulangerie` et `GG-Admins-Postes`, et peuple-les.

**C4.** Pourquoi faut-il agir **avant** de joindre le premier poste, sur le conteneur où arrivent les nouveaux ordinateurs ?

---

## Partie D — Joindre PC01

**D1.** Sur `PC01`, essaie de résoudre `ad.fournil.lab`. Que se passe-t-il ? Corrige.

**D2.** Vérifie que `PC01` trouve un contrôleur de domaine (enregistrement SRV, port LDAP).

**D3.** Joins `PC01` au domaine (`sysdm.cpl` ou `Add-Computer`), de façon qu'il arrive dans `OU=Ordinateurs,OU=Fournil`.

**D4.** Après redémarrage, vérifie la jonction de quatre façons différentes.

**D5.** Qui est désormais administrateur local de `PC01` ? D'où vient ce changement ?

**D6.** Ouvre une session `FOURNIL\stagiaire` sur `PC01`. Comment saisir le compte, et comment vérifier ensuite que la session est bien une session de domaine ?

---

## Partie E — Exercices complémentaires (bonus)

**E1.** `w32tm /query /source` sur `PC01` renvoie « VM IC Time Synchronization Provider ». Pourquoi est-ce un problème pour un membre du domaine ? Comment corriger ?

**E2.** Le canal sécurisé de `PC01` est cassé (« La relation d'approbation entre cette station de travail et le domaine principal a échoué »). Répare-le sans quitter le domaine.

---


