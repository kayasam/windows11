---
title: "TP 01. Introduction à Windows 11 et lab Hyper-V, version guidée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/01-introduction-hyperv"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/01-introduction-hyperv-guide.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/tp/guide" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/tp/guide-corrigev2">Afficher les corrections</a></nav>

**Ta mission.** Sur l’hôte Hyper-V, prépare un réseau de lab et une VM vide. Le TP est terminé quand `PC01` peut démarrer sur l’ISO et possède le point de contrôle `Avant-installation`.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/tp/standard)

## Préparer l’hôte Hyper-V

### A1 — Identifier la version de Windows

Sur l’hôte, lance `winver`. Note l’édition dans **Paramètres → Système → Informations système**, puis la version et le build complet affichés par `winver`.

### A2 — Contrôler la virtualisation

Ouvre **Gestionnaire des tâches → Performances → Processeur**. Repère la ligne **Virtualisation**. Vérifie aussi que ton édition de Windows propose Hyper-V dans `optionalfeatures.exe`.

### A3 — Activer Hyper-V

Dans `optionalfeatures.exe`, coche **Hyper-V**, valide et redémarre si Windows le demande. Après reconnexion, ouvre **Gestionnaire Hyper-V**.

## Créer le réseau

### B1 — Définir les dossiers de stockage

Sur l’hôte, crée `D:\HyperV`. Dans **Gestionnaire Hyper-V → Paramètres Hyper-V**, configure ce dossier pour les **disques durs virtuels** et pour les **ordinateurs virtuels**.

### B2 — Créer le commutateur et le NAT

Dans **Gestionnaire de commutateur virtuel**, crée un commutateur **Interne** nommé `vSwitch-Rennes` si absent. Dans `ncpa.cpl`, sur l’interface hôte `vEthernet (vSwitch-Rennes)`, fixe `192.168.3.254` avec le masque `255.255.255.0`. En PowerShell administrateur, lance `Get-NetNat`. Si le préfixe du lab n’existe pas, utilise `New-NetNat -Name NAT-Rennes -InternalIPInterfaceAddressPrefix 192.168.3.0/24`.

## Configurer PC01

### C1 — Créer la VM et attacher l’ISO

Sur l’hôte, crée `PC01` en **génération 2** avec 4 Go de mémoire **statique**, 2 vCPU, un VHDX de 64 Go et `vSwitch-Rennes`. Attache l’ISO Windows 11 au lecteur DVD et place le DVD en tête du démarrage.

### C2 — Activer le TPM et contrôler la VM

VM éteinte, ouvre **Paramètres → Sécurité**. Vérifie le démarrage sécurisé avec le modèle **Microsoft Windows**, puis active le **module de plateforme sécurisée**. Vérifie aussi les 4 Go et les 2 processeurs.

### C3 — Créer le point avant installation

Dans **Paramètres → Points de contrôle**, sélectionne **Standard** et décoche les points automatiques. VM éteinte, crée un point et renomme-le `Avant-installation`.

### C4 — Vérifier le démarrage sur l’ISO

Ouvre la console de `PC01`, démarre-la et appuie sur une touche au message **Press any key to boot from CD or DVD**. Arrête-toi au premier écran de l’installateur.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/tp/guide-corrigev2)
