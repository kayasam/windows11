# TP 12. Administrer à distance : RSAT, WinRM, RPC et SSH

**Mission** · Tu es technicien au Fournil. Tu ne veux plus te déplacer jusqu'au serveur ni jusqu'aux postes. Tu vas **configurer** quatre façons d'administrer à distance, puis vérifier qu'elles marchent :

| Partie | Outil | Sens | Ce que tu configures |
|---|---|---|---|
| A | **RSAT** | PC01 → SRV01 | Les consoles du serveur installées sur PC01 |
| B | **WinRM** | SRV01 → PC01 | PowerShell à distance sur le poste |
| C | **RPC** | SRV01 → PC01 | Le pare-feu du poste pour les consoles à distance |
| D | **SSH** | PC01 → SRV01 | Une connexion par **clé**, sans mot de passe |

**Avant de commencer**
- `SRV01` (contrôleur de domaine) et `PC01` (joint au domaine) sont démarrés, sur `vSwitch-Rennes` (TP 10–11).
- Sur **les deux** VM, ouvre une session avec `FOURNIL\Administrateur`.
- Le serveur SSH de `SRV01` est démarré (TP 10).

> [!tip] Commence par la partie A
> L'installation des RSAT télécharge les consoles depuis Internet : **≈ 10 minutes**. Lance-la, puis fais la partie B pendant qu'elle tourne.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/)

---

## Partie A — RSAT : les consoles du serveur sur PC01

**A1.** Sur `PC01`, installe **en graphique** ces trois outils RSAT :
- *RSAT : outils Active Directory Domain Services Directory et services LDS…*
- *RSAT : outils du serveur DNS*
- *RSAT : outils du serveur DHCP*

Par où passes-tu ? Pendant l'installation, passe à la partie B.

**A2.** Une fois l'installation finie, où trouves-tu les nouvelles consoles sur `PC01` ?

**A3.** Depuis `PC01` :
1. dans **Utilisateurs et ordinateurs Active Directory**, retrouve le compte `stagiaire` ;
2. dans la console **DNS**, connecte-toi à `SRV01` et retrouve l'enregistrement de `PC01` dans la zone `ad.fournil.lab` ;
3. dans la console **DHCP**, retrouve la plage d'adresses de l'étendue.

**A4.** Pourquoi est-il préférable d'administrer le serveur avec les RSAT plutôt qu'en ouvrant une session sur `SRV01` ?

---

## Partie B — WinRM : PowerShell à distance

**B1.** Sur `PC01`, ouvre Windows PowerShell et tape `Test-WSMan srv01`. Puis, sur `SRV01`, tape `Test-WSMan PC01`. Que constates-tu ?

**B2.** Sur `PC01`, ouvre `services.msc`. Dans quel état est le service **Windows Remote Management (Gestion WSM)** ?

**B3.** Active PowerShell à distance sur `PC01`. Vérifie depuis `SRV01` avec `Test-WSMan PC01`.

**B4.** Depuis `SRV01`, lance une commande sur `PC01` sans quitter le serveur :

```powershell
Invoke-Command -ComputerName PC01 -ScriptBlock { hostname; Get-Service Spooler }
```

Un mot de passe est-il demandé ? Pourquoi ?

**B5.** Toujours depuis `SRV01`, entre dans une session sur `PC01`, tape `hostname`, puis ressors. À quoi vois-tu que tu es sur `PC01` ?

---

## Partie C — RPC : les consoles graphiques à distance

**C1.** Sur `SRV01`, ouvre l'**Observateur d'événements** et connecte-le à l'ordinateur `PC01`. Que se passe-t-il ? WinRM est pourtant activé depuis la partie B : pourquoi cela ne suffit-il pas ?

**C2.** Sur `PC01`, ouvre le **Pare-feu Windows Defender avec fonctions avancées de sécurité** (`wf.msc`) et active, dans les **Règles de trafic entrant**, les deux groupes :
- **Gestion à distance des journaux des événements**
- **Gestion des services à distance**

Comment fais-tu pour activer tout un groupe d'un coup ?

**C3.** Sur `SRV01`, recommence C1. Ouvre le journal **Système** de `PC01`.

**C4.** Sur `SRV01`, ouvre **Gestion de l'ordinateur** et connecte-la à `PC01`. Dans **Services**, arrête puis redémarre le **Spouleur d'impression** de `PC01`. Vérifie sur `PC01` que le service a bien redémarré.

**C5.** (bonus) Comment ouvrirais-tu ces règles sur les 35 postes du Fournil sans passer sur chacun ?

---

## Partie D — SSH avec une clé

**D1.** Sur `PC01`, connecte-toi en SSH à `SRV01` avec le mot de passe :

```powershell
ssh administrateur@srv01.ad.fournil.lab
```

Que demande SSH à la toute première connexion ? Tape `hostname`, puis `exit`.

**D2.** Sur `PC01`, crée une paire de clés :

```powershell
ssh-keygen -t ed25519
```

Où sont créés les fichiers ? Lequel ne doit **jamais** quitter `PC01` ?

**D3.** Dépose ta **clé publique** sur `SRV01`. Pour un compte membre des **Administrateurs**, OpenSSH pour Windows la lit dans un fichier particulier : `C:\ProgramData\ssh\administrators_authorized_keys`. Utilise WinRM (partie B) pour l'y copier depuis `PC01`.

**D4.** Reconnecte-toi avec `ssh administrateur@srv01.ad.fournil.lab`. Qu'est-ce qui a changé ?

**D5.** (bonus) Lance une seule commande sur `SRV01` sans ouvrir de terminal interactif : `ssh administrateur@srv01.ad.fournil.lab hostname`. À quoi cela sert-il pour un administrateur ?

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/standard-corrigev2)

[Ouvrir la version guidée](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/standard-corrigev2)
