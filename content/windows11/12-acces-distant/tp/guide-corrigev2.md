---
title: "TP 16. Administration et assistance à distance, corrigé guidé"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/12-acces-distant"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/12-acces-distant-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Ta mission.** Tu es technicien sur `PC01`. Tu vas intervenir sur `PC02` sans te déplacer : d'abord en prenant son écran (Bureau à distance), puis en lui envoyant des commandes (PowerShell à distance). Ouvre une session `FOURNIL\adm.stagiaire` sur `PC01` **et** sur `PC02`. Réalise ce TP **après le TP 15**, une fois `PC02` déployé et joint au domaine. Pour le test RDP, utilise aussi `FOURNIL\test.vendeur`, créé en C6 du TP 11.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/) · [Ouvrir le TP d'origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/standard)

## Bureau à distance

### A1 — Le port est-il ouvert ?

Sur `PC01`, ouvre un Terminal et tape `Test-NetConnection PC02 -Port 3389`. Relève la valeur de `TcpTestSucceeded`.

> [!success]- Afficher la correction — A1
> `TcpTestSucceeded : False`. L'adresse de `PC02` s'affiche (le nom est trouvé), mais le port 3389 est fermé : le Bureau à distance est **désactivé par défaut** sur Windows 11.

### A2 — Activer le Bureau à distance sur PC02

Sur `PC02`, ouvre **Paramètres → Système → Bureau à distance**. Passe le bouton sur **Activé**, puis clique **Confirmer**. Retourne sur `PC01` et relance la commande de A1.

> [!success]- Afficher la correction — A2
> ![w11-12-parametres-rdp-confirmation](https://cours.kaya.ovh/windows11/assets/captures/w11-12-parametres-rdp-confirmation.png)
>
> Le bouton indique **Activé**, port **3389**. Sur `PC01`, `TcpTestSucceeded` passe à **True** : le pare-feu a été ouvert automatiquement.

### A3 — Autoriser un utilisateur

Sur `PC02`, dans la même page, clique **Utilisateurs du Bureau à distance**. Lis la phrase sous la liste. Clique **Ajouter…**, tape `test.vendeur`, clique **Vérifier les noms**, puis **OK** deux fois.

> [!success]- Afficher la correction — A3
> La phrase dit **« FOURNIL\adm.stagiaire a déjà un accès »** : les administrateurs du poste sont toujours autorisés. Seuls les comptes **non administrateurs**, comme `test.vendeur`, doivent être ajoutés.
>
> ![w11-12-utilisateurs-bureau-a-distance-ok](https://cours.kaya.ovh/windows11/assets/captures/w11-12-utilisateurs-bureau-a-distance-ok.png)

### A4 — Se connecter avec mstsc

Sur `PC01`, menu Démarrer → **Connexion Bureau à distance**. Tape `PC02`, clique **Connexion**. Choisis **Autres choix → Utiliser un autre compte** et saisis `FOURNIL\test.vendeur` et son mot de passe. Lis le message, réponds **Oui**, puis regarde l'écran de `PC02` et clique **OK**.

Dans la session distante, ouvre une invite de commandes, tape `hostname` puis `whoami`. Ferme la session en tapant `logoff`. Reconnecte ensuite `adm.stagiaire` sur la console de `PC02`.

> [!success]- Afficher la correction — A4
> `PC01` prévient qu'un autre utilisateur est connecté et sera déconnecté ; `PC02` demande à `adm.stagiaire` s'il autorise la connexion (sinon, déconnexion au bout de 30 secondes). **Windows 11 n'accepte qu'une session à la fois.**
>
> ![w11-12-pc02-autoriser-connexion](https://cours.kaya.ovh/windows11/assets/captures/w11-12-pc02-autoriser-connexion.png)
>
> Dans la session : `PC02` et `fournil\test.vendeur`.
>
> ![w11-12-mstsc-session-pc02](https://cours.kaya.ovh/windows11/assets/captures/w11-12-mstsc-session-pc02.png)

## PowerShell à distance

### B1 — État de départ

Sur `PC02`, ouvre `services.msc` et descends tout en bas jusqu'à **Windows Remote Management (Gestion WSM)**. Relève son état et son type de démarrage. Sur `PC01`, tape `Test-WSMan PC02` puis `Test-WSMan SRV01`.

> [!success]- Afficher la correction — B1
> Service **arrêté** (colonne *État* vide), démarrage **Manuel**. `Test-WSMan PC02` affiche une erreur rouge ; `Test-WSMan SRV01` répond. Windows Server a PowerShell à distance activé d'office, Windows 11 non.
>
> ![w11-12-services-winrm-arrete](https://cours.kaya.ovh/windows11/assets/captures/w11-12-services-winrm-arrete.png)

### B2 — Activer PowerShell à distance sur PC02

Sur `PC02`, ouvre **Windows PowerShell** en administrateur depuis Démarrer, puis lance `Enable-PSRemoting -Force`. Sur `PC01`, relance `Test-WSMan PC02`.

> [!success]- Afficher la correction — B2
> ![w11-12-enable-psremoting](https://cours.kaya.ovh/windows11/assets/captures/w11-12-enable-psremoting.png)
>
> Le service démarre, l'écouteur et la règle de pare-feu sont créés. `Test-WSMan PC02` répond maintenant.

### B3 — Envoyer une commande

Sur `PC01`, tape :

```powershell
Invoke-Command -ComputerName PC02 -ScriptBlock { hostname; whoami }
```

Note si un mot de passe t'est demandé.

> [!success]- Afficher la correction — B3
> Résultat : `PC02` puis `fournil\adm.stagiaire`. **Pas de mot de passe** : dans un domaine, Windows utilise le ticket Kerberos de ta session, et `adm.stagiaire` est administrateur de `PC02`.

### B4 — Entrer sur le serveur (bonus)

Sur `PC01`, tape `Enter-PSSession SRV01` et lis le message. Recommence avec `Enter-PSSession SRV01 -Credential FOURNIL\Administrateur`. Dans la session, tape `hostname` puis `Get-Service DHCPServer, DNS`. Termine avec `Exit-PSSession`.

> [!success]- Afficher la correction — B4
> Premier essai : **Accès refusé**, car `adm.stagiaire` n'est pas administrateur du serveur. Avec `-Credential`, une fenêtre demande le mot de passe, puis l'invite commence par `[SRV01]:`.
>
> ![w11-12-enter-pssession-srv01](https://cours.kaya.ovh/windows11/assets/captures/w11-12-enter-pssession-srv01.png)

## Assistance rapide

### D1 — Découvrir l'outil

Sur `PC02`, menu Démarrer → tape **Assistance rapide**. Repère les zones **Aide** et **Aider quelqu'un**. Clique **Aider quelqu'un**, regarde ce qui est demandé, puis ferme la fenêtre sans te connecter.

> [!success]- Afficher la correction — D1
> **Aide** = l'utilisateur saisit le code donné par le technicien. **Aider quelqu'un** = le technicien doit se connecter avec un **compte Microsoft**. Si Windows demande d'« énumérer vos clés d'accès », réponds **Non**.
>
> Attention aux arnaques : on ne donne un code qu'à une personne du support qu'on a soi-même appelée.
>
> ![w11-12-assistance-rapide-compte-microsoft](https://cours.kaya.ovh/windows11/assets/captures/w11-12-assistance-rapide-compte-microsoft.png)

[Retour à l'énoncé guidé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide)
