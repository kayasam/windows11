# TP 01. Introduction à Windows 11 et lab Hyper-V, corrigé guidé

**Ta mission.** Sur l’hôte Hyper-V, prépare un réseau de lab et une VM vide. Le TP est terminé quand `PC01` peut démarrer sur l’ISO et possède le point de contrôle `Avant-installation`.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/tp/standard)

## Préparer l’hôte Hyper-V

### A1 — Identifier la version de Windows

Sur l’hôte, lance `winver`. Note l’édition dans **Paramètres → Système → Informations système**, puis la version et le build complet affichés par `winver`.

> [!success]- Afficher la correction — A1
> La version commerciale et le build sont deux informations différentes. Garde le nombre après le point pour comparer le niveau de correctifs.

### A2 — Contrôler la virtualisation

Ouvre **Gestionnaire des tâches → Performances → Processeur**. Repère la ligne **Virtualisation**. Vérifie aussi que ton édition de Windows propose Hyper-V dans `optionalfeatures.exe`.

> [!success]- Afficher la correction — A2
> La virtualisation doit être **Activée**. Si elle est désactivée, vérifie le réglage UEFI avec le formateur. Si l’hyperviseur est déjà lancé, `systeminfo` peut signaler qu’un hyperviseur est détecté au lieu d’afficher les prérequis un par un.

### A3 — Activer Hyper-V

Dans `optionalfeatures.exe`, coche **Hyper-V**, valide et redémarre si Windows le demande. Après reconnexion, ouvre **Gestionnaire Hyper-V**.

> [!success]- Afficher la correction — A3
> Le gestionnaire doit lister l’hôte. Dans PowerShell, `Get-Service vmms` permet de vérifier que le service est `Running`.

## Créer le réseau

### B1 — Définir les dossiers de stockage

Sur l’hôte, crée `D:\HyperV`. Dans **Gestionnaire Hyper-V → Paramètres Hyper-V**, configure ce dossier pour les **disques durs virtuels** et pour les **ordinateurs virtuels**.

> [!success]- Afficher la correction — B1
> Les deux chemins de stockage pointent vers le dossier de lab. Les nouvelles VM et les nouveaux VHDX y seront rangés.

### B2 — Créer le commutateur et le NAT

Dans **Gestionnaire de commutateur virtuel**, crée un commutateur **Interne** nommé `vSwitch-Rennes` si absent. Dans `ncpa.cpl`, sur l’interface hôte `vEthernet (vSwitch-Rennes)`, fixe `192.168.3.254` avec le masque `255.255.255.0`. En PowerShell administrateur, lance `Get-NetNat`. Si le préfixe du lab n’existe pas, utilise `New-NetNat -Name NAT-Rennes -InternalIPInterfaceAddressPrefix 192.168.3.0/24`.

> [!success]- Afficher la correction — B2
> Vérifie que le commutateur est interne et que `Get-NetNat` affiche `192.168.3.0/24`. Si un NAT existe déjà avec une autre configuration, relève son nom et son préfixe avant de demander au formateur quel réseau utiliser. Conserve les NAT d’autres labs.

## Configurer PC01

### C1 — Créer la VM et attacher l’ISO

Sur l’hôte, crée `PC01` en **génération 2** avec 4 Go de mémoire **statique**, 2 vCPU, un VHDX de 64 Go et `vSwitch-Rennes`. Attache l’ISO Windows 11 au lecteur DVD et place le DVD en tête du démarrage.

> [!success]- Afficher la correction — C1
> Dans les paramètres de la VM, la carte réseau est raccordée à `vSwitch-Rennes` et le firmware liste le DVD avant le VHDX.

### C2 — Activer le TPM et contrôler la VM

VM éteinte, ouvre **Paramètres → Sécurité**. Vérifie le démarrage sécurisé avec le modèle **Microsoft Windows**, puis active le **module de plateforme sécurisée**. Vérifie aussi les 4 Go et les 2 processeurs.

> [!success]- Afficher la correction — C2
> Le vTPM doit être activé. Si tu passes par PowerShell, configure d’abord un protecteur de clé local pour le vTPM. Le gestionnaire permet de réaliser ce réglage depuis l’interface.

### C3 — Créer le point avant installation

Dans **Paramètres → Points de contrôle**, sélectionne **Standard** et décoche les points automatiques. VM éteinte, crée un point et renomme-le `Avant-installation`.

> [!success]- Afficher la correction — C3
> Le point figure dans l’arborescence de `PC01`. Il dépend des disques de la VM. Pour conserver une copie indépendante, il faut une sauvegarde.

### C4 — Vérifier le démarrage sur l’ISO

Ouvre la console de `PC01`, démarre-la et appuie sur une touche au message **Press any key to boot from CD or DVD**. Arrête-toi au premier écran de l’installateur.

> [!success]- Afficher la correction — C4
> Si le message passe trop vite, redémarre depuis la console et garde-la active. L’écran d’installation confirme que le lecteur DVD est bien amorçable. La suite se fait au TP 02.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/01-introduction-hyperv/tp/guide)
