# TP 03. Configuration et personnalisation

> [!abstract] Parcours TSSR
> Toutes les parties non marquées (bonus) sont à réaliser ; les exercices complémentaires sont facultatifs.
> **Méthode au choix : interface graphique ou PowerShell. Une seule méthode suffit** pour chaque manipulation ; tu peux changer de méthode selon la question. Les raccourcis clavier sont facultatifs. Le script de la partie F reste un bonus.

> Chapitres associés : [03. Configuration et personnalisation](https://cours.kaya.ovh/windows11/windows11/03-configuration/)

---

## Objectifs

- Prendre en main l'interface Windows 11 26H2 et ses raccourcis
- Savoir où trouver un réglage : Paramètres ou Panneau de configuration
- Créer et gérer des comptes locaux (interface graphique **ou** PowerShell)
- Donner à `PC01` son adresse IP fixe du plan d'adressage
- Manipuler les variables d'environnement

---

## Prérequis

- `PC01` installé (TP 02), session `admin`
- Réseau `vSwitch-Rennes` + NAT opérationnels (TP 01)

---

## Partie A — Interface

**A1.** Ouvre le menu Démarrer. Nomme ses trois zones. Masque les recommandations.

**A2.** Ouvre trois fenêtres et organise-les en 50/25/25 avec les Snap Layouts, à la souris **ou** au clavier.

**A3.** Crée un bureau virtuel « Admin », place-y un terminal, puis reviens au bureau 1, avec la Vue des tâches **ou** les raccourcis clavier. Explique comment tu as procédé.

**A4.** Aligne la barre des tâches à gauche et masque le bouton Widgets.

---

## Partie B — Paramètres ou Panneau de configuration ?

**B1.** Pour chaque réglage, indique l’outil et comment l’ouvrir : chemin dans l’interface graphique **ou** commande d’accès, au choix :
1. Changer l'adresse IP de la carte réseau
2. Voir la RAM, le processeur, le nom du PC
3. Désinstaller un programme `.msi` ancien
4. Ouvrir les options Internet (proxy Win32)
5. Gérer les utilisateurs et groupes locaux

---

## Partie C — Comptes locaux

**C1.** Crée l’utilisateur standard `employe1` (mot de passe `Fournil2026!`, nom complet « Employé 1 ») dans `lusrmgr.msc` **ou** en PowerShell. Vérifie qu’il appartient au groupe **Utilisateurs** et ajoute-le si nécessaire.

**C2.** (bonus) Observe le SID de `employe1`, fourni par le formateur **ou** relevé avec `Get-LocalUser -Name employe1 | Select-Object Name, SID`. Quelle partie du SID identifie la machine, et laquelle identifie le compte ? Il n’est pas nécessaire d’utiliser PowerShell si tu travailles à partir du relevé fourni.

**C3.** Affiche les membres du groupe **Utilisateurs**, dans `lusrmgr.msc` → **Groupes** → **Utilisateurs**, **ou** en PowerShell. Pourquoi y trouve-t-on aussi `admin` et des entrées `AUTORITE NT\…` ?

**C4.** Crée le compte `employe2`, avec « L’utilisateur doit changer le mot de passe à la prochaine ouverture de session ». Vérifie à quel groupe il appartient, puis désactive-le. Utilise `lusrmgr.msc` (propriétés du compte → **Le compte est désactivé**) **ou** PowerShell avec les commandes complémentaires nécessaires.

**C5.** Quels sont les comptes locaux présents par défaut sur le poste ? Lesquels sont désactivés, et pourquoi ?

---

## Partie D — Réseau

**D1.** Relève la configuration IP actuelle de `PC01`, dans les détails de la carte réseau **ou** en PowerShell. D’où vient l’adresse ?

**D2.** Configure dans `ncpa.cpl` **ou** en PowerShell : IP `192.168.3.10/24`, passerelle `192.168.3.254`, DNS `8.8.8.8` et `1.1.1.1`.

**D3.** Teste la passerelle, Internet par IP, puis la résolution DNS, avec les outils de ton choix. Le formateur peut fournir les commandes de test si nécessaire. Dans quel ordre, et pourquoi cet ordre ?

**D4.** Quel profil réseau (Public/Privé) est appliqué ? Consulte les propriétés de la connexion dans les Paramètres **ou** utilise PowerShell. Pourquoi ce profil ?

---

## Partie E — Variables d'environnement

**E1.** Retrouve le nom de l’ordinateur (`COMPUTERNAME`), le dossier du profil courant (`USERPROFILE`) et le `PATH`, avec **une seule méthode au choix** :
- **En graphique** : nom du PC dans les informations système ; ouvrir `%USERPROFILE%` dans la barre d’adresse de l’Explorateur ; consulter `Path` dans `sysdm.cpl` → **Paramètres système avancés** → **Variables d’environnement**.
- **En PowerShell** : afficher `$env:COMPUTERNAME`, `$env:USERPROFILE` et `$env:PATH`.

**E2.** Crée la variable système `FOURNIL_ENV=lab`, dans la fenêtre **Variables d’environnement** → **Variables système** → **Nouvelle**, **ou** en PowerShell. Pourquoi un terminal déjà ouvert peut-il conserver l’ancien environnement ?

**E3.** Ajoute `C:\Outils` au `PATH` système **sans l’écraser**, dans **Variables système** → **Path** → **Modifier** → **Nouveau**, **ou** en PowerShell. Conserve toutes les entrées existantes.

---

## Partie F — Exercices complémentaires (bonus)

**F1.** Réécris la partie D en un script `Set-IPFixe.ps1` paramétrable (`-IP`, `-Passerelle`, `-DNS`).

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/03-configuration/tp/standard-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/03-configuration/tp/standard-corrigev2)
