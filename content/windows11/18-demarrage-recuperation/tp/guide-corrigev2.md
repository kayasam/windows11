---
title: "TP 19. Démarrage et récupération, corrigé guidé"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/18-demarrage-recuperation"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/18-demarrage-recuperation-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Ta mission.** Sur une VM `PC01` de lab, observe le démarrage, ouvre WinRE et teste un point de restauration. Avant de changer le démarrage, garde la console Hyper-V et assure-toi d’avoir la clé de récupération propre à la VM si BitLocker est actif.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/tp/standard)

## Comprendre le démarrage et accéder à WinRE

### A1 — Lire la configuration actuelle (bonus)

Sur `PC01`, dans PowerShell administrateur, lance `bcdedit /enum '{bootmgr}'` puis `bcdedit /enum '{current}'`. Repère `timeout` et le chemin du chargeur.

> [!success]- Afficher la correction — A1
> Le premier bloc décrit le gestionnaire de démarrage, le second le chargeur de l’installation courante. Sur une installation UEFI, le chemin du chargeur de Windows se termine normalement par `winload.efi`.

### A2 — Tester le mode sans échec pour un seul démarrage

Sur `PC01`, maintiens **Maj** en choisissant **Redémarrer**. Dans **Dépannage → Options avancées → Paramètres de démarrage**, clique **Redémarrer**, puis choisis le mode sans échec. Observe le bureau et redémarre normalement.

> [!success]- Afficher la correction — A2
> Le bureau indique le mode sans échec. Le choix effectué dans **Paramètres de démarrage** vaut pour ce démarrage. Ce test ne laisse pas le démarrage sécurisé forcé dans `msconfig`.

### A3 — Vérifier l’environnement de récupération

De retour dans Windows, lance `reagentc /info` en administrateur. Relève l’état et, si WinRE est actif, l’emplacement affiché.

> [!success]- Afficher la correction — A3
> `reagentc /info` indique si Windows a un environnement de récupération configuré. L’emplacement fait souvent référence à la partition de récupération.

### A4 — Repérer les outils de récupération

Retourne une fois dans WinRE. Dans **Options avancées**, trouve **Outil de redémarrage système**, **Restauration du système** et **Invite de commandes**. Choisis **Continuer** pour revenir dans Windows.

> [!success]- Afficher la correction — A4
> Le premier aide à réparer un problème de démarrage, le deuxième utilise les points de restauration et l’invite donne accès aux commandes de diagnostic. Les options visibles dépendent de l’image et de son état.

## Tester une restauration

### B1 — Créer un point avant la modification

Sur `PC01`, ouvre `SystemPropertiesProtection.exe`. Active la protection du volume `C:` si nécessaire puis crée le point `Avant-TP19`.

> [!success]- Afficher la correction — B1
> Le point apparaît dans la liste de restauration avec son heure. En cas de protection désactivée ou de quota insuffisant, configure le volume avant de réessayer.

### B2 — Comparer logiciel et document après restauration

Dans la VM, crée un document de test et installe une application de test prévue par le formateur. Lance `rstrui.exe`, sélectionne `Avant-TP19` et utilise **Rechercher les programmes concernés** avant de restaurer. Après redémarrage, vérifie l’application et le document.

> [!success]- Afficher la correction — B2
> La restauration peut retirer les changements système et le logiciel ajouté après le point. Le fichier personnel n’est normalement pas restauré à un état antérieur. Vérifie le résultat réel pour les deux objets.

## Atelier complémentaire. Identifier les volumes de réparation (bonus)

### C1 — Identifier Windows et l’EFI dans WinRE

Sur la VM de test, ouvre l’invite de commandes dans WinRE. Exécute `diskpart`, `list volume` et `exit`. Compare les tailles et systèmes de fichiers. Pour le volume Windows supposé, vérifie qu’il contient le dossier `Windows`.

> [!success]- Afficher la correction — C1
> Les lettres peuvent être différentes de celles vues sous Windows. La partition EFI est généralement une petite partition FAT32. Identifier ces deux volumes évite de réparer une autre installation.

### C2 — Choisir la commande adaptée sans modifier une VM saine

Dans le cours, retrouve l’exemple de `bcdboot` pour un démarrage UEFI. Sur ta fiche, remplace les lettres par celles que tu as relevées et explique le rôle du volume cible EFI.

> [!success]- Afficher la correction — C2
> `bcdboot` copie les fichiers de démarrage à partir du dossier Windows vers l’EFI identifiée. Le diagnostic et la préparation de la commande peuvent se faire sans supprimer une entrée de démarrage.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/tp/guide)
