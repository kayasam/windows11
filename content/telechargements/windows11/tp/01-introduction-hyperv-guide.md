# TP 01. Introduction à Windows 11 et lab Hyper-V, version guidée

**Ta mission.** Sur l’hôte Hyper-V, prépare un réseau de lab et une VM vide. Le TP est terminé quand `PC01` peut démarrer sur l’ISO et possède le point de contrôle `Avant-installation`.

**À récupérer sur l’hôte Hyper-V.** Utilise l’ISO française du lab. Si le formateur ne l’a pas déjà mise à disposition, prends l’[ISO Windows 11 x64 de Microsoft](https://www.microsoft.com/fr-fr/software-download/windows11) et vérifie avec lui la version retenue pour la séance. Range l’ISO dans `D:\ISO` ou note son chemin.

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


