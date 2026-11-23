---
title: "TP 13. ADK, Windows PE et fichier de réponse, version guidée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/13-adk-winpe"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/13-adk-winpe-guide.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>


**Ta mission.** Travaille sur `PC01` avec l’ISO Windows 11 et les fichiers fournis. Tu vas produire une ISO WinPE qui démarre une VM de test et valider un fichier de réponse avant de l’utiliser.

**À récupérer sur `PC01`.** Télécharge le modèle <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/autounattend-fournil-26h2.xml" download data-router-ignore>autounattend-fournil-26h2.xml</a> et enregistre-le dans `C:\Images`. Garde son nom pour l’ouvrir dans WSIM. Prépare l’ISO Windows 11 du lab et les deux installateurs du même numéro de version sur la [page Microsoft ADK et WinPE](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install). Choisis la version `10.1.26100.9457` pour ce lab.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp/standard)

## Préparer les outils

### A1 — Installer deux composants compatibles

Sur `PC01`, installe l’ADK du lab avec **Outils de déploiement** et **USMT**. Puis installe le module WinPE associé à la même version, d’après les installateurs du cours. Vérifie les entrées dans **Applications installées**.

### A2 — Ouvrir l’invite de déploiement

Dans le menu Démarrer de `PC01`, cherche **Environnement de déploiement et d’outils de création d’images** et lance-le en administrateur. Tape `where copype`.

## Créer et démarrer WinPE

### B1 — Créer l’espace de travail

Dans l’invite ADK, lance `copype amd64 C:\WinPE_amd64`. Vérifie que `C:\WinPE_amd64\media\sources\boot.wim` existe.

### B2 — Produire une ISO

Crée `C:\Temp`, puis lance `MakeWinPEMedia /ISO C:\WinPE_amd64 C:\Temp\WinPE-Fournil.iso` dans l’invite ADK. Copie ensuite l’ISO sur l’hôte Hyper-V.

### B3 — Vérifier le démarrage dans une VM de test

Sur l’hôte Hyper-V, attache l’ISO à une VM vierge et démarre dessus. Dans l’invite WinPE, utilise `diskpart`, `list disk`, `list volume` puis `exit`.

## Valider un fichier de réponse

### C1 — Choisir l’image dans WSIM

Sur `PC01`, copie `install.wim` depuis le dossier `sources` de l’ISO vers `C:\Images`, ou utilise la copie du formateur. Ouvre **Assistant Gestion d’installation**, sélectionne le WIM et choisis **Windows 11 Professionnel**.

### C2 — Lire la passe windowsPE

Dans WSIM, ouvre **Fichier → Ouvrir un fichier de réponses** et sélectionne `C:\Images\autounattend-fournil-26h2.xml`. Le modèle contient un marqueur à la place du mot de passe, que tu peux laisser pour vérifier la structure dans WSIM. Dans **windowsPE**, repère la langue `fr-FR`, la sélection de l’image et la configuration du disque 0 de la VM de test.

### C3 — Vérifier les réglages de personnalisation

Dans **specialize**, repère Fournil et `Romance Standard Time`. Dans **oobeSystem**, repère les options OOBE et le compte local. Utilise les valeurs du fichier de lab.

### C4 — Valider et enregistrer

Dans WSIM, lance **Outils → Valider le fichier de réponses**. Corrige les erreurs signalées puis enregistre une copie `autounattend.xml`.


