# TP 12. Administration et assistance à distance

> [!abstract] Parcours TSSR
> À réaliser en J4, APRÈS le TP 16 : PC02 existe alors et est joint au domaine. Activer WinRM depuis la console Hyper-V de PC02 en B2 AVANT A2, puis reprendre A et B. OpenSSH est (bonus).

> Chapitres associés : [12. Administration et assistance à distance](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/)

---

## Objectifs

- Activer et utiliser le Bureau à distance
- Administrer plusieurs postes en PowerShell Remoting ; WinRS (bonus)
- Utiliser OpenSSH entre Windows, puis PowerShell Remoting sur SSH (bonus)
- Vérifier les RSAT déjà utilisés au TP 11 ; installation et nouvel exercice AD (bonus)
- Connaître les outils d'assistance (Assistance rapide, Remote Help)

---

## Prérequis

- `PC01`, `PC02`, `SRV01` dans le domaine (TP 10, TP 16)
- Session `PC01` avec un compte administrateur des postes

---

## Partie A — Bureau à distance

**A1.** Le port RDP de `PC02` est-il ouvert ? Vérifie depuis `PC01` sans ouvrir `mstsc`.

**A2.** Active le Bureau à distance sur `PC02` **à distance**, sans t'y connecter graphiquement. Quelle méthode utilises-tu ?

**A3.** Connecte-toi à `PC02` avec `mstsc`. Qui a le droit de s'y connecter ? Comment autoriser `stagiaire` ?

**A4.** Quel client utiliserais-tu pour un PC cloud Windows 365 ?

---

## Partie B — PowerShell Remoting et WinRS

**B1.** L'état du service WinRM sur `PC01`, `PC02` et `SRV01`. Que constates-tu ?

**B2.** Active PowerShell Remoting sur `PC02`. Quelles règles de pare-feu sont créées, pour quels profils ?

**B3.** Depuis `PC01`, affiche en une commande le nom et la version de Windows de `SRV01` et `PC02`. Pourquoi aucun mot de passe n'est-il demandé ?

**B4.** Ouvre une session interactive sur `SRV01`, liste les services DHCP et DNS, quitte.

**B5.** (bonus) Avec WinRS, exécute `ipconfig /all` sur `SRV01`.

**B6.** Comment activerais-tu WinRM sur les 35 postes du Fournil ?

---

## Partie C — OpenSSH (bonus)

**C1.** Le client SSH est-il présent sur `PC01` ? Le port 22 de `SRV01` répond-il ?

**C2.** Connecte-toi en SSH à `SRV01`. Quel shell obtiens-tu ? Fais en sorte que ce soit PowerShell.

**C3.** Génère une paire de clés ed25519 sur `PC01` et configure l'authentification par clé pour `Administrateur` sur `SRV01`. Quel fichier particulier faut-il utiliser pour un compte administrateur ?

**C4.** Installe PowerShell 7 sur `SRV01` (Server Core), déclare le sous-système SSH et ouvre une session `Enter-PSSession -HostName`. (bonus)

---

## Partie D — RSAT et assistance

**D1.** (bonus) Installe sur `PC01` les outils AD DS, DNS, DHCP et GPMC. Ouvre `dsa.msc` et crée un utilisateur `test.vendeur` dans `OU=Utilisateurs`.

**D2.** Lance l'Assistance rapide. Qui a besoin d'un compte Microsoft ? Quel risque de sécurité faut-il expliquer aux utilisateurs ?

**D3.** Quelles différences entre Assistance rapide et Remote Help ?

---


