# TP 13. ADK, Windows PE et fichier de réponse, corrigé guidé

**Ta mission.** Travaille sur `PC01` avec l’ISO Windows 11 et les fichiers fournis. Tu vas produire une ISO WinPE qui démarre une VM de test et valider un fichier de réponse avant de l’utiliser.

**À récupérer sur `PC01`.** Télécharge le modèle <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/autounattend-fournil-26h2.xml" download data-router-ignore>autounattend-fournil-26h2.xml</a> et enregistre-le dans `C:\Images`. Garde son nom pour l’ouvrir dans WSIM. Prépare l’ISO Windows 11 du lab et les deux installateurs du même numéro de version sur la [page Microsoft ADK et WinPE](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install). Choisis la version `10.1.26100.9457` pour ce lab.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp/standard)

## Préparer les outils

### A1 — Installer deux composants compatibles

Sur `PC01`, installe l’ADK du lab avec **Outils de déploiement** et **USMT**. Puis installe le module WinPE associé à la même version, d’après les installateurs du cours. Vérifie les entrées dans **Applications installées**.

> [!success]- Afficher la correction — A1
> Les outils de déploiement fournissent notamment WSIM et oscdimg. L’add-on ajoute les fichiers de Windows PE. Mélanger l’ADK et un module d’une autre version complique le diagnostic.

### A2 — Ouvrir l’invite de déploiement

Dans le menu Démarrer de `PC01`, cherche **Environnement de déploiement et d’outils de création d’images** et lance-le en administrateur. Tape `where copype`.

> [!success]- Afficher la correction — A2
> La commande doit retrouver `copype.cmd` dans l’ADK. Cette invite charge les chemins des outils.

## Créer et démarrer WinPE

### B1 — Créer l’espace de travail

Dans l’invite ADK, lance `copype amd64 C:\WinPE_amd64`. Vérifie que `C:\WinPE_amd64\media\sources\boot.wim` existe.

> [!success]- Afficher la correction — B1
> Le dossier `media` contient les fichiers de démarrage. `boot.wim` est l’image que WinPE chargera.

### B2 — Produire une ISO

Crée `C:\Temp`, puis lance `MakeWinPEMedia /ISO C:\WinPE_amd64 C:\Temp\WinPE-Fournil.iso` dans l’invite ADK. Copie ensuite l’ISO sur l’hôte Hyper-V.

> [!success]- Afficher la correction — B2
> `WinPE-Fournil.iso` existe. Pour son premier essai, conserve le WinPE standard. [Créer un support WinPE](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-create-usb-bootable-drive?view=windows-11)

### B3 — Vérifier le démarrage dans une VM de test

Sur l’hôte Hyper-V, attache l’ISO à une VM vierge et démarre dessus. Dans l’invite WinPE, utilise `diskpart`, `list disk`, `list volume` puis `exit`.

> [!success]- Afficher la correction — B3
> L’invite WinPE est accessible et DiskPart liste les disques vus par la VM. Le disque système de l’hôte est hors de cette VM.

## Valider un fichier de réponse

### C1 — Choisir l’image dans WSIM

Sur `PC01`, copie `install.wim` depuis le dossier `sources` de l’ISO vers `C:\Images`, ou utilise la copie du formateur. Ouvre **Assistant Gestion d’installation**, sélectionne le WIM et choisis **Windows 11 Professionnel**.

> [!success]- Afficher la correction — C1
> WSIM affiche les composants de l’édition sélectionnée. Si le catalogue manque, lance sa création avec l’image copiée en local dans un dossier accessible en écriture.

### C2 — Lire la passe windowsPE

Dans WSIM, ouvre **Fichier → Ouvrir un fichier de réponses** et sélectionne `C:\Images\autounattend-fournil-26h2.xml`. Le modèle contient un marqueur à la place du mot de passe, que tu peux laisser pour vérifier la structure dans WSIM. Dans **windowsPE**, repère la langue `fr-FR`, la sélection de l’image et la configuration du disque 0 de la VM de test.

> [!success]- Afficher la correction — C2
> La passe agit pendant Setup. EFI et MSR précèdent la partition Windows dans le scénario. Une configuration qui efface le disque 0 doit être testée uniquement sur le disque virtuel prévu.

### C3 — Vérifier les réglages de personnalisation

Dans **specialize**, repère Fournil et `Romance Standard Time`. Dans **oobeSystem**, repère les options OOBE et le compte local. Utilise les valeurs du fichier de lab.

> [!success]- Afficher la correction — C3
> `specialize` personnalise le système installé. `oobeSystem` règle la première ouverture de session. Masquer un mot de passe dans WSIM ne transforme pas le fichier en coffre de secrets.

### C4 — Valider et enregistrer

Dans WSIM, lance **Outils → Valider le fichier de réponses**. Corrige les erreurs signalées puis enregistre une copie `autounattend.xml`.

> [!success]- Afficher la correction — C4
> Le volet des messages ne doit plus afficher d’erreur. Une validation de structure ne remplace pas un essai sur une VM vierge.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp/guide)
