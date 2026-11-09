# TP 13. ADK, Windows PE et fichier de réponse

> Durée estimée : 2h

> Chapitres associés : [13. ADK, Windows PE et fichier de réponse](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/)

---

## Objectifs

- Installer Windows ADK et son module WinPE **dans la bonne version**
- Créer un WinPE personnalisé (PowerShell, clavier français) et le démarrer
- Construire avec WSIM le fichier de réponse `autounattend.xml` du Fournil
- Préparer le petit fichier d'installation de `MASTER` (anti-chiffrement)

---

## Prérequis

- `PC01` (poste d'administration) avec accès Internet, ~10 Go libres
- ISO Windows 11 26H2 montée dans `PC01` ou copiée dans `D:\ISO\` sur l'hôte

---

## Partie A — Installer l'ADK (25 min)

**A1.** Sur `PC01`, quelle version de l'ADK WinGet propose-t-il par défaut ? Et le module WinPE ? Quel problème vois-tu ?

**A2.** Installe en mode silencieux l'ADK **10.1.26100.9457** (Outils de déploiement + USMT) puis le module WinPE correspondant.

**A3.** Liste les dossiers créés sous `Assessment and Deployment Kit`. Où se trouvent `oscdimg.exe`, `copype.cmd`, WSIM, `scanstate.exe` ?

---

## Partie B — Windows PE (40 min)

**B1.** Ouvre l'invite « Environnement de déploiement et d'outils de création d'images » en administrateur. Pourquoi cette invite plutôt qu'un terminal ordinaire ?

**B2.** Crée l'arborescence WinPE amd64 dans `C:\WinPE_amd64`. Que contient-elle ?

**B3.** Monte `boot.wim` et ajoute : WMI, NetFx, Scripting, PowerShell, StorageWMI, DismCmdlets — avec leurs packs `fr-fr`. Dans quel ordre, et pourquoi ?

**B4.** Passe le clavier de WinPE en français, vérifie les paquets, puis démonte en validant.

**B5.** Crée l'ISO `WinPE-Fournil.iso`. Quelle taille fait-elle ?

**B6.** Démarre une VM vierge sur cette ISO. Vérifie que PowerShell fonctionne et liste les disques.

---

## Partie C — Le fichier de réponse avec WSIM (45 min)

**C1.** Copie `install.wim` depuis l'ISO, ouvre WSIM, sélectionne l'image **Windows 11 Professionnel**. Combien d'index contient ce `install.wim` ? Que se passe-t-il au premier chargement ?

**C2.** Passe **windowsPE** : langue fr-FR, disque 0 effacé, partitions EFI 200 Mo / MSR 16 Mo / Windows (tout le reste), installation sur la partition 3, contrat accepté, clé générique Pro.

**C3.** Pourquoi ne crée-t-on pas de partition de récupération dans le fichier ?

**C4.** Passe **specialize** : nom généré automatiquement, organisation Fournil, fuseau `Romance Standard Time`.

**C5.** Passe **oobeSystem** : langue, masquage de tous les écrans, `ProtectYourPC = 3`, compte local `Utilisateur` administrateur avec mot de passe.

**C6.** Valide (0 erreur) et enregistre `autounattend.xml`. Compare avec le fichier fourni `Ressources/Fichier-reponse/autounattend-fournil-26h2.xml`.

---

## Partie D — Le fichier d'installation de MASTER (10 min)

**D1.** Pourquoi faut-il un **second** fichier de réponse pour **installer** `MASTER` ?

**D2.** Ajoute dans un nouveau fichier : passe windowsPE (disque + édition) et, en passe specialize, le composant qui empêche le chiffrement automatique. Pas de passe oobeSystem : pourquoi ?

---

## Partie E — Bonus

**E1.** Le fichier contient un mot de passe en clair. Que propose WSIM ? Est-ce un vrai chiffrement ?

**E2.** Sur une clé USB de 32 Go, comment faire tenir WinPE **et** une image de 8 Go ?

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/13-adk-winpe/tp-corrigev2)
