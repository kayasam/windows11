---
title: "TP 01. Introduction à Windows 11 et lab Hyper-V"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/01-introduction-hyperv"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/01-introduction-hyperv.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>


> Durée estimée : 1h30

> Chapitres associés : [01. Introduction à Windows 11 et lab Hyper-V](https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/)

---

## Objectifs

- Identifier précisément la version, le build et l'édition d'un poste Windows 11
- Vérifier les prérequis et activer Hyper-V sur le poste hôte
- Construire le réseau du lab : switch interne + NAT
- Créer la VM `PC01` conforme aux exigences de Windows 11
- Maîtriser les points de contrôle (checkpoints)

---

## Prérequis

- Poste hôte Windows 11 **Pro, Entreprise ou Éducation**, compte administrateur
- ISO Windows 11 26H2 (ou 25H2) française dans `D:\ISO\`
- Terminal PowerShell **administrateur**

---

## Partie A — Identifier son Windows (15 min)

**A1.** Ouvre `winver`. Relève la version et le build complet (avec le numéro après le point).

**A2.** Retrouve les mêmes informations en PowerShell, sans interface graphique.

**A3.** Lis la valeur `ProductName` dans `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion`. Que constates-tu ? Comment un script doit-il tester qu'il tourne sur Windows 11 ?

**A4.** Ton poste est en 25H2. Comment passera-t-il en 26H2, et combien de redémarrages cela demandera-t-il ?

**A5.** Un client a encore 40 postes Windows 10 22H2. Quels sont ses risques et ses options ?

---

## Partie B — Prérequis et activation d'Hyper-V (15 min)

**B1.** Vérifie que le processeur et le firmware permettent Hyper-V. Donne deux méthodes.

**B2.** Active Hyper-V en PowerShell. Faut-il redémarrer ?

**B3.** Vérifie que le service de gestion Hyper-V tourne et compte les cmdlets du module `Hyper-V`.

---

## Partie C — Réseau du lab (20 min)

**C1.** Définis `D:\HyperV` comme dossier par défaut des VM et des disques.

**C2.** Crée le switch interne `vSwitch-Rennes`, donne l'IP `192.168.3.254/24` à son interface hôte, puis crée le NAT `NAT-Rennes` pour `192.168.3.0/24`.

**C3.** `New-NetNat` répond : *« Instance MSFT_NetNat already exists »*. Que se passe-t-il et comment corriger sans casser l'existant ?

**C4.** Pourquoi n'utilise-t-on pas le **Default Switch** pour `PC01` et `SRV01` ? Pourquoi l'utilisera-t-on quand même pour `MASTER` ?

---

## Partie D — Créer la VM PC01 (25 min)

**D1.** Crée `PC01` en PowerShell : Génération 2, 64 Go, `vSwitch-Rennes`, 2 vCPU, 4 Go de mémoire **statique**, ISO Windows 11 montée, démarrage sur le DVD.

**D2.** Ajoute un TPM virtuel. Pourquoi faut-il d'abord un protecteur de clé ?

**D3.** Vérifie : génération, mémoire, processeurs, TPM, Secure Boot.

**D4.** Désactive les checkpoints automatiques et passe en checkpoints **Standard**. Pourquoi ces deux choix en lab ?

**D5.** Ouvre la console de `PC01` puis démarre-la. Que faut-il faire au message *« Press any key to boot from CD or DVD »* ? Que se passe-t-il si on le rate ?

> Ne lance pas l'installation au-delà du premier écran : elle fait l'objet du TP 02.

---

## Partie E — Points de contrôle (15 min)

**E1.** Éteins `PC01`, crée un checkpoint `Avant-installation` et liste les checkpoints.

**E2.** Dans `D:\HyperV\PC01\`, quel nouveau fichier est apparu ? À quoi sert-il ?

**E3.** Explique la différence entre un checkpoint **Standard** et un checkpoint **Production**.

**E4.** Un collègue dit : « J'ai des checkpoints, donc j'ai une sauvegarde ». Réponds-lui.

---

## Partie F — Bonus

**F1.** Écris un script `New-LabVM.ps1` qui prend un paramètre `-Name` et crée une VM conforme à la partie D.

**F2.** Exporte `PC01` (éteinte) dans `D:\Export`, puis réimporte-la sous un nouvel identifiant.

---


