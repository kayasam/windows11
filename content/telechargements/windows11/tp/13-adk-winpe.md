# TP 13. ADK, Windows PE et fichier de réponse

> [!abstract] Parcours TSSR
> ADK, WinPE et catalogue WSIM sont préchargés ou mis en cache par le formateur. Socle : vérifier les outils, créer un WinPE standard, puis compléter et valider un fichier de réponse fourni. PowerShell dans WinPE et la préparation de MASTER sont (bonus).

> Chapitres associés : [12. ADK, Windows PE et fichier de réponse](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/)

---

## Objectifs

- Installer Windows ADK et son module WinPE **dans la bonne version**
- Créer et démarrer un WinPE standard ; personnalisation PowerShell et clavier français (bonus)
- Construire avec WSIM le fichier de réponse `autounattend.xml` du Fournil
- Préparer le petit fichier d'installation de `MASTER` (anti-chiffrement) (bonus)

---

## Fichier du TP

Télécharge <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/autounattend-fournil-26h2.xml" download data-router-ignore>autounattend-fournil-26h2.xml</a> dans `C:\Images` sur `PC01`. Ouvre cette copie dans WSIM. Garde le marqueur de mot de passe tant que tu vérifies seulement la structure.

## Prérequis

- `PC01` (poste d'administration) avec accès Internet, ~10 Go libres
- ISO Windows 11 26H2 montée dans `PC01` ou copiée dans `D:\ISO\` sur l'hôte

---

## Partie A — Installer l'ADK

**A1.** Sur `PC01`, quelle version de l'ADK WinGet propose-t-il par défaut ? Et pour le module WinPE ? Quelle version Microsoft indique-t-il pour l’ISO Windows 11 26H2 du lab ?

**A2.** Installe en mode silencieux l'ADK **10.1.26100.9457** (Outils de déploiement + USMT) puis le module WinPE correspondant.

**A3.** Liste les dossiers créés sous `Assessment and Deployment Kit`. Où se trouvent `oscdimg.exe`, `copype.cmd`, WSIM, `scanstate.exe` ?

---

## Partie B — Windows PE

**B1.** Ouvre l'invite « Environnement de déploiement et d'outils de création d'images » en administrateur. Pourquoi cette invite plutôt qu'un terminal ordinaire ?

**B2.** Crée l'arborescence WinPE amd64 dans `C:\WinPE_amd64`. Que contient-elle ?

**B3.** Monte `boot.wim` et ajoute : WMI, NetFx, Scripting, PowerShell, StorageWMI, DismCmdlets — avec leurs packs `fr-fr`. Dans quel ordre, et pourquoi ? (bonus)

**B4.** Passe le clavier de WinPE en français, vérifie les paquets, puis démonte en validant. (bonus)

**B5.** Crée l'ISO `WinPE-Fournil.iso`. Quelle taille fait-elle ?

**B6.** Démarre une VM vierge sur cette ISO. Dans l’invite CMD de WinPE standard, utilise `diskpart`, `list disk`, `list volume`, puis `exit`. PowerShell ne sera disponible que si tu as réalisé B3 et B4 (bonus).

---

## Partie C — Le fichier de réponse avec WSIM

**C1.** Copie `install.wim` de l'ISO dans `C:\Images` (ou utilise la copie préparée par le formateur), ouvre WSIM (« Assistant Gestion d'installation » dans le menu Démarrer), sélectionne l'image **Windows 11 Pro**. Combien d'index contient ce `install.wim` ? Que se passe-t-il au premier chargement ?

**C2.** Ouvre le fichier fourni `autounattend-fournil-26h2.xml` dans WSIM, puis vérifie et adapte la passe **windowsPE** : langue fr-FR, disque 0 effacé, partitions EFI 200 Mo / MSR 16 Mo / Windows (tout le reste), installation sur la partition 3, contrat accepté, clé générique Pro.

**C3.** Pourquoi ne crée-t-on pas de partition de récupération dans le fichier ?

**C4.** Passe **specialize** : nom généré automatiquement, organisation Fournil, fuseau `Romance Standard Time`.

**C5.** Passe **oobeSystem** : langue, masquage de tous les écrans, `ProtectYourPC = 3`, compte local `Utilisateur` administrateur avec mot de passe.

**C6.** Valide (0 erreur) et enregistre `autounattend.xml`. Compare avec le fichier fourni `Ressources/Fichier-reponse/autounattend-fournil-26h2.xml`.

---

## Partie D — Le fichier d'installation de MASTER (bonus)

**D1.** Pourquoi faut-il un **second** fichier de réponse pour **installer** `MASTER` ?

**D2.** Ajoute dans un nouveau fichier : passe windowsPE (disque + édition) et, en passe specialize, le composant qui empêche le chiffrement automatique. Pas de passe oobeSystem : pourquoi ?

---

## Partie E — Exercices complémentaires (bonus)

**E1.** Le fichier contient un mot de passe en clair. Que propose WSIM ? Est-ce un vrai chiffrement ?

**E2.** Sur une clé USB de 32 Go, comment faire tenir WinPE **et** une image de 8 Go ?

---

[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp/standard-corrigev2)
