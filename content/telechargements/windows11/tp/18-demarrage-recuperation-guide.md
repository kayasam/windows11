# TP 19. Démarrage et récupération, version guidée

**Ta mission.** Sur une VM `PC01` de lab, observe le démarrage, ouvre WinRE et teste un point de restauration. Avant de changer le démarrage, garde la console Hyper-V et assure-toi d’avoir la clé de récupération propre à la VM si BitLocker est actif.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/18-demarrage-recuperation/tp/standard)

## Comprendre le démarrage et accéder à WinRE

### A1 — Lire la configuration actuelle (bonus)

Sur `PC01`, dans PowerShell administrateur, lance `bcdedit /enum '{bootmgr}'` puis `bcdedit /enum '{current}'`. Repère `timeout` et le chemin du chargeur.

### A2 — Tester le mode sans échec pour un seul démarrage

Sur `PC01`, maintiens **Maj** en choisissant **Redémarrer**. Dans **Dépannage → Options avancées → Paramètres de démarrage**, clique **Redémarrer**, puis choisis le mode sans échec. Observe le bureau et redémarre normalement.

### A3 — Vérifier l’environnement de récupération

De retour dans Windows, lance `reagentc /info` en administrateur. Relève l’état et, si WinRE est actif, l’emplacement affiché.

### A4 — Repérer les outils de récupération

Retourne une fois dans WinRE. Dans **Options avancées**, trouve **Outil de redémarrage système**, **Restauration du système** et **Invite de commandes**. Choisis **Continuer** pour revenir dans Windows.

## Tester une restauration

### B1 — Créer un point avant la modification

Sur `PC01`, ouvre `SystemPropertiesProtection.exe`. Active la protection du volume `C:` si nécessaire puis crée le point `Avant-TP19`.

### B2 — Comparer logiciel et document après restauration

Dans la VM, crée un document de test et installe une application de test prévue par le formateur. Lance `rstrui.exe`, sélectionne `Avant-TP19` et utilise **Rechercher les programmes concernés** avant de restaurer. Après redémarrage, vérifie l’application et le document.

## Atelier complémentaire. Identifier les volumes de réparation (bonus)

### C1 — Identifier Windows et l’EFI dans WinRE

Sur la VM de test, ouvre l’invite de commandes dans WinRE. Exécute `diskpart`, `list volume` et `exit`. Compare les tailles et systèmes de fichiers. Pour le volume Windows supposé, vérifie qu’il contient le dossier `Windows`.

### C2 — Choisir la commande adaptée sans modifier une VM saine

Dans le cours, retrouve l’exemple de `bcdboot` pour un démarrage UEFI. Sur ta fiche, remplace les lettres par celles que tu as relevées et explique le rôle du volume cible EFI.


