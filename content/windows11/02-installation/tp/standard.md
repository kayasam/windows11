---
title: "TP 02. Installation, mise à niveau et comptes"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/02-installation"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/02-installation/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/02-installation/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/02-installation/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/02-installation.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>


> [!abstract] Parcours TSSR
> Toutes les parties non marquées (bonus) sont à réaliser ; les exercices complémentaires sont facultatifs.

> Chapitres associés : [02. Installation, mise à niveau et comptes](https://cours.kaya.ovh/windows11/windows11/02-installation/)

---

## Objectifs

- Installer Windows 11 Pro 26H2 sur `PC01` avec un **compte local**
- Analyser le résultat : édition, partitions, chiffrement, jonction
- Vérifier la compatibilité d'un poste avant mise à niveau
- Distinguer compte local, Microsoft, professionnel et de domaine

---

## Prérequis

- VM `PC01` créée au TP 01 (Gen 2, TPM, 2 vCPU, mémoire statique, ISO 26H2 montée)
- Carte réseau connectée à `vSwitch-Rennes` (NAT fonctionnel)

---

## Partie A — Installation

**A1.** Démarre `PC01` sur l'ISO. Choisis Français, coche *J'accepte que tout soit supprimé*, sélectionne **Windows 11 Professionnel** (attention : Famille est présélectionnée) et installe sur l'espace non alloué. Pourquoi ne crée-t-on aucune partition à la main ?

**A2.** Pendant l'installation, explique ce que fait chacun des écrans de l'OOBE qui vont suivre.

**A3.** À l'écran **« Il est temps de vous connecter à un réseau »**, que se passe-t-il si la VM n'a pas de réseau ? Et avec le réseau ?

**A4.** Le Fournil veut un **compte local** `admin` sur ce poste de lab. Obtiens-le avec `Shift+F10`. Quelle commande tapes-tu, et que fait-elle exactement ?

**A5.** Termine l'OOBE : nom `admin`, mot de passe `Fournil2026!`, questions de sécurité, refuse toutes les options de confidentialité facultatives.

**A6.** Le poste s'appelle `DESKTOP-XXXXXXX`. Renomme-le `PC01`, en graphique ou en PowerShell.

---

## Partie B — Analyser l'installation

**B1.** Vérifie l'édition, la version et le build.

**B2.** Liste les partitions du disque. Dans quel ordre sont-elles ? Pourquoi la partition de récupération est-elle placée là ?

**B3.** Vérifie l'état de BitLocker sur `C:`. Que constates-tu, alors que tu n'as rien activé ? Est-ce que les données sont protégées ?

**B4.** Vérifie l'état de WinRE.

**B5.** Avec `dsregcmd /status`, détermine le type de jonction du poste.

---

## Partie C — Compatibilité et mise à niveau

**C1.** Vérifie en PowerShell les trois prérequis clés de Windows 11 : TPM 2.0, Secure Boot, processeur.

**C2.** (bonus) L'ISO est montée dans `PC01`. Lance un **contrôle de compatibilité seul**, sans rien installer, avec `setup.exe`. Récupère le code de sortie. Où trouver le rapport détaillé ?

**C3.** (bonus) Interprète le rapport : quels critères sont contrôlés ? Sont-ils bloquants ?

**C4.** Un poste Windows 10 22H2 du Fournil a un TPM 1.2. Que te répondra le contrôle de compatibilité ? Que proposes-tu ?

---

## Partie D — Comptes

**D1.** Complète le tableau : où est stocké le compte, comment se connecte-t-on, à quoi sert-il ?

| Compte | Exemple | Stocké dans | Usage typique |
|--------|---------|-------------|---------------|
| Local | | | |
| Microsoft | | | |
| Professionnel | | | |
| Domaine | | | |

**D2.** Pourquoi dit-on que le fichier de réponse est la seule méthode **pérenne** pour obtenir un compte local à l'installation ?

---

## Partie E — Exercices complémentaires (bonus)

**E1.** Qu'affiche la valeur `ProductName` du registre sur ton `PC01` ? Pourquoi ne faut-il pas s'y fier ?

**E2.** Combien de jours as-tu pour revenir en arrière après une mise à niveau ? Comment portes-tu ce délai à 30 jours ?

---


