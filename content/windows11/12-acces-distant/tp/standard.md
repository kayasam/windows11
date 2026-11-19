---
title: "TP 12. Administration et assistance à distance"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/12-acces-distant"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/12-acces-distant.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>


> [!abstract] Parcours TSSR
> À réaliser en J4, APRÈS le TP 16 : `PC02` existe alors et il est joint au domaine. Les questions marquées (bonus) sont facultatives : rien dans la suite n'en dépend.

> Chapitres associés : [12. Administration et assistance à distance](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/)

---

## Objectifs

- Activer le Bureau à distance, choisir qui peut se connecter, se connecter avec `mstsc`
- Activer PowerShell à distance et envoyer des commandes à un autre poste
- Connaître l'Assistance rapide et son risque principal
- (bonus) WinRS, OpenSSH, Remote Help

---

## Prérequis

- `SRV01`, `PC01` et `PC02` allumées, `PC02` joint au domaine (TP 16)
- Sur `PC01` **et** sur `PC02` : session ouverte avec **`FOURNIL\adm.stagiaire`** (administrateur des postes, TP 10–11)
- Le compte `test.vendeur` existe (TP 11, C6). Sinon, crée-le sur `SRV01` dans `dsa.msc` → *Fournil → Utilisateurs*, mot de passe `Fournil2026!`

> [!TIP] Qui fait quoi ?
> **PC01** = ton poste de technicien. **PC02** = le poste à dépanner. Quand une question dit « sur PC02 », travaille dans la console Hyper-V de `PC02`.

---

## Partie A — Bureau à distance

**A1.** Sur `PC01`, dans un Terminal, vérifie si le port du Bureau à distance de `PC02` répond :

```powershell
Test-NetConnection PC02 -Port 3389
```

Que vaut `TcpTestSucceeded` ? Pourquoi ?

**A2.** Sur `PC02`, active le Bureau à distance **en graphique** (Paramètres). Puis, sur `PC01`, relance la commande de A1. Qu'est-ce qui a changé ?

**A3.** Sur `PC02`, toujours dans Paramètres → Bureau à distance, ouvre **Utilisateurs du Bureau à distance** et autorise `test.vendeur`. Lis bien la fenêtre : pourquoi n'a-t-on pas besoin d'y ajouter `adm.stagiaire` ?

**A4.** Sur `PC01`, ouvre **Connexion Bureau à distance** (`mstsc`) et connecte-toi à `PC02` avec le compte `FOURNIL\test.vendeur`.
1. Quel message apparaît sur `PC01` ? Et sur l'écran de `PC02` ? Clique **OK** sur `PC02`.
2. Dans la session distante, ouvre une invite de commandes et tape `hostname` puis `whoami`.
3. Ferme la session avec `logoff`, puis reconnecte `adm.stagiaire` sur la console de `PC02`.

**A5.** Un client te demande comment se connecter à son PC cloud **Windows 365**. Quel logiciel lui conseilles-tu ?

---

## Partie B — PowerShell à distance

**B1.** Sur `PC02`, ouvre `services.msc` et trouve le service **Windows Remote Management (Gestion WSM)**. Quel est son état ? Son type de démarrage ?
Puis, sur `PC01` :

```powershell
Test-WSMan PC02
Test-WSMan SRV01
```

Que constates-tu ?

**B2.** Sur `PC02`, ouvre un **Terminal (administrateur)** (`Win + X`) et active PowerShell à distance :

```powershell
Enable-PSRemoting -Force
```

Relance `Test-WSMan PC02` sur `PC01`.

**B3.** Sur `PC01`, envoie une commande à `PC02` :

```powershell
Invoke-Command -ComputerName PC02 -ScriptBlock { hostname; whoami }
```

Un mot de passe t'a-t-il été demandé ? Pourquoi ?

**B4.** Sur `PC01`, entre dans une session à distance sur le serveur :

```powershell
Enter-PSSession SRV01
```

1. Que se passe-t-il ? Pourquoi ?
2. Recommence en ajoutant `-Credential FOURNIL\Administrateur`. Dans la session, tape `hostname` puis `Get-Service DHCPServer, DNS`. Comment sais-tu que tu es sur le serveur ?
3. Quitte avec `Exit-PSSession`.

**B5.** (bonus) Avec WinRS, exécute `ipconfig` sur `PC02` : `winrs -r:PC02 ipconfig`.

**B6.** (bonus) Le Fournil a 35 postes. Comment activerais-tu PowerShell à distance sur tous sans passer sur chacun ?

---

## Partie C — OpenSSH (bonus)

**C1.** Sur `PC01`, connecte-toi en SSH au serveur : `ssh administrateur@SRV01`. Quelle question est posée à la première connexion, et que faut-il répondre ? Dans quel shell arrives-tu ? Tape `exit` pour sortir.

**C2.** Fais en sorte qu'une connexion SSH sur `SRV01` ouvre PowerShell au lieu de cmd, puis vérifie.

---

## Partie D — Assistance rapide

**D1.** Sur `PC02`, ouvre **Assistance rapide** (menu Démarrer). Quelles sont les deux zones ? Laquelle utilise l'utilisateur qui a besoin d'aide ? Clique sur **Aider quelqu'un** : que te demande-t-on ? Ferme la fenêtre sans te connecter.

**D2.** Quel risque de sécurité faut-il expliquer aux utilisateurs à propos de cet outil ? Quelle consigne simple leur donnes-tu ?

**D3.** (bonus) Cite trois choses que **Remote Help** (Intune) apporte en plus de l'Assistance rapide.

---


