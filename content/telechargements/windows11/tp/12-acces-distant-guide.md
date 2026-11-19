# TP 16. Administration et assistance à distance, version guidée

**Ta mission.** Tu es technicien sur `PC01`. Tu vas intervenir sur `PC02` sans te déplacer : d'abord en prenant son écran (Bureau à distance), puis en lui envoyant des commandes (PowerShell à distance). Ouvre une session `FOURNIL\adm.stagiaire` sur `PC01` **et** sur `PC02`. Réalise ce TP **après le TP 15**, une fois `PC02` déployé et joint au domaine. Pour le test RDP, utilise aussi `FOURNIL\test.vendeur`, créé en C6 du TP 11.

**Avant A1, contrôle les deux postes.** Sur chaque console, tape `hostname` puis `whoami`. Tu dois avoir `PC01` ou `PC02`, et `fournil\adm.stagiaire`. Si le poste `PC02` manque, reprends le TP 15. Si tu ne peux pas ouvrir une console d’administration sur `PC02`, actualise les stratégies avec `gpupdate /force` depuis un compte administrateur autorisé sur ce poste, puis ferme et rouvre la session. Vérifie que `PC02` est dans l’UO **Fournil → Ordinateurs** et reçoit la GPO de la partie A du TP 11.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/) · [Ouvrir le TP d'origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/standard)

## Bureau à distance

### A1 — Le port est-il ouvert ?

Sur `PC01`, ouvre un Terminal et tape `Test-NetConnection PC02 -Port 3389`. Relève la valeur de `TcpTestSucceeded`.

### A2 — Activer le Bureau à distance sur PC02

Sur `PC02`, ouvre **Paramètres → Système → Bureau à distance**. Passe le bouton sur **Activé**, puis clique **Confirmer**. Retourne sur `PC01` et relance la commande de A1.

### A3 — Autoriser un utilisateur

Sur `PC02`, dans la même page, clique **Utilisateurs du Bureau à distance**. Lis la phrase sous la liste. Clique **Ajouter…**, tape `test.vendeur`, clique **Vérifier les noms**, puis **OK** deux fois.

### A4 — Se connecter avec mstsc

Sur `PC01`, menu Démarrer → **Connexion Bureau à distance**. Tape `PC02`, clique **Connexion**. Choisis **Autres choix → Utiliser un autre compte** et saisis `FOURNIL\test.vendeur` et son mot de passe. Si une confirmation de certificat s’affiche, vérifie que tu as bien saisi `PC02` avant de l’accepter dans le lab. Si Windows affiche un message d’accueil, clique **OK**. Si la connexion est refusée, vérifie l’ajout de `test.vendeur` en A3.

Dans la session distante, ouvre une invite de commandes, tape `hostname` puis `whoami`. Tu dois voir `PC02` et `fournil\test.vendeur`. Ferme la session en tapant `logoff`. Reconnecte ensuite `adm.stagiaire` sur la console de `PC02`.

## PowerShell à distance

### B1 — État de départ

Sur `PC02`, ouvre `services.msc` et descends tout en bas jusqu'à **Windows Remote Management (Gestion WSM)**. Relève son état et son type de démarrage. Sur `PC01`, tape `Test-WSMan PC02` puis `Test-WSMan SRV01`.

### B2 — Activer PowerShell à distance sur PC02

Sur `PC02`, ouvre **Windows PowerShell** en administrateur depuis Démarrer, puis lance `Enable-PSRemoting -Force`. Sur `PC01`, relance `Test-WSMan PC02`.

### B3 — Envoyer une commande

Sur `PC01`, tape :

```powershell
Invoke-Command -ComputerName PC02 -ScriptBlock { hostname; whoami }
```

Note si un mot de passe t'est demandé.

### B4 — Entrer sur le serveur (bonus)

Sur `PC01`, tape `Enter-PSSession SRV01` et lis le message. Recommence avec `Enter-PSSession SRV01 -Credential FOURNIL\Administrateur`. Dans la session, tape `hostname` puis `Get-Service DHCPServer, DNS`. Termine avec `Exit-PSSession`.

## Assistance rapide

### D1 — Découvrir l'outil

Sur `PC02`, menu Démarrer → tape **Assistance rapide**. Repère les zones **Aide** et **Aider quelqu'un**. Clique **Aider quelqu'un**, regarde ce qui est demandé, puis ferme la fenêtre sans te connecter.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide-corrigev2)
