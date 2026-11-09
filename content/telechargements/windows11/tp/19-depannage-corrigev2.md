# TP 19. Diagnostic et dépannage — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 2h

> Chapitres associés : [19. Diagnostic et dépannage](https://cours.kaya.ovh/windows11/windows11/19-depannage/)

---

## Objectifs

- Appliquer une **méthode** de dépannage (symptôme → hypothèse → test → correction → vérification)
- Diagnostiquer un poste en panne avec les outils intégrés (journaux, réseau, services, tâches, pare-feu)
- Réparer **sans réinstaller**
- Documenter l'intervention

---

## Prérequis

- `PC02` joint au domaine, l'utilisateur de test voit son lecteur `P:` et peut imprimer sur l'imprimante PDF
- **Point de contrôle Hyper-V** : `Checkpoint-VM -Name PC02 -SnapshotName "Avant-pannes"`
- Le formateur (ou ton binôme) exécute `Ressources/scripts/Casse-Poste.ps1` en administrateur sur `PC02` **sans te dire ce qu'il fait**, puis redémarre le poste

> Ne lis pas le script avant la fin du TP : c'est l'intérêt de l'exercice.

---

## Partie A — Recueillir les symptômes (15 min)

Ouvre une session avec l'utilisateur de test, puis avec le compte administrateur local.

**A1.** Note **tout** ce qui ne fonctionne pas comme avant (ouverture de session, lecteurs, impression, accès à `\\srv01`, Internet, lenteurs…).

> [!success]- Afficher la correction — A1
> Ce que l'on observe sur `PC02` après `Casse-Poste.ps1` :
> - ouverture de session domaine **lente** ou « *Aucun serveur d'authentification disponible* » pour un compte jamais connecté sur ce poste (les identifiants en cache fonctionnent encore) ;
> - lecteur `P:` **déconnecté** (croix rouge), `\\srv01` inaccessible ;
> - **impossible d'imprimer** (« *Le service Spouleur d'impression local n'est pas en cours d'exécution* ») ;
> - GPO non appliquées (`gpupdate` échoue) ;
> - Internet **fonctionne** (8.8.8.8 répond) : piège classique, l'utilisateur dit « le réseau marche ».
>
> Le compte administrateur **local** est indispensable : sans DC joignable, un compte domaine jamais mis en cache ne peut pas ouvrir de session.

**A2.** Ouvre une fiche d'intervention (modèle au chapitre 19) : date, poste, symptômes, qui est impacté, depuis quand.

> [!success]- Afficher la correction — A2
> ```
> Date / heure : 2026-11-08 14:10        Technicien : …
> Poste : PC02 (FOURNIL-…)               Utilisateur : …
> Symptômes : P: absent, \\srv01 inaccessible, impression KO, session lente
> Impact : 1 utilisateur, bloquant (pas d'accès aux fichiers)
> Depuis : ce matin, après redémarrage — changement récent : inconnu
> ```
> La question « **qu'est-ce qui a changé ?** » est la plus rentable de toutes.

---

## Partie B — Réseau et résolution de noms (30 min)

**B1.** Vérifie la configuration IP et DNS de la carte. Qu'est-ce qui est anormal sur un poste du domaine ?

> [!success]- Afficher la correction — B1
> ```powershell
> Get-NetIPConfiguration
> Get-DnsClientServerAddress -AddressFamily IPv4
> ```
> Le serveur DNS est **8.8.8.8**. Un poste du domaine doit utiliser **uniquement** les DNS du domaine (`SRV01`, 192.168.3.1 dans le lab) : un DNS public ne connaît pas `ad.fournil.lab`, donc plus de localisation du DC (enregistrements SRV), plus de GPO, plus d'authentification Kerberos.
> **Panne 1 trouvée : DNS.**

**B2.** Teste la résolution de `srv01.ad.fournil.lab` et de `ad.fournil.lab`. Les résultats sont-ils cohérents entre eux ? Avec `Resolve-DnsName`, d'où vient la réponse pour `srv01` ?

> [!success]- Afficher la correction — B2
> ```powershell
> Resolve-DnsName ad.fournil.lab          # échec : nom introuvable (le DNS public ne connaît pas la zone)
> Resolve-DnsName srv01.ad.fournil.lab    # réussit !... vers 192.168.3.250
> ```
> Incohérent : le domaine ne résout pas, mais `srv01` si, et vers une adresse qui n'existe pas. `Resolve-DnsName` affiche la section **Answer** sans serveur interrogé, et `Get-DnsClientCache` montre l'entrée avec un TTL fixe : la réponse vient du fichier **hosts**, consulté **avant** le DNS.
> ```powershell
> Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String -NotMatch '^\s*#'
> # 192.168.3.250	srv01 srv01.ad.fournil.lab
> ```
> **Panne 2 trouvée : fichier hosts.** Le fichier hosts est aussi une technique de logiciel malveillant (rediriger un site bancaire, bloquer les mises à jour d'un antivirus) : toujours le regarder.

**B3.** Teste la connexion SMB vers `srv01` (port 445). Après avoir corrigé B1 et B2, le test réussit-il ? Sinon, cherche la cause dans le pare-feu.

> [!success]- Afficher la correction — B3
> ```powershell
> Test-NetConnection srv01.ad.fournil.lab -Port 445
> # TcpTestSucceeded : False   — même après correction du DNS et du hosts
> ```
> Le ping (`PingSucceeded : True`) passe, mais pas le TCP 445 : quelque chose filtre. Côté serveur, le 445 répond depuis `PC01` → le blocage est **sur le poste**. On cherche les règles **sortantes** de blocage (rares par défaut) :
> ```powershell
> Get-NetFirewallRule -Direction Outbound -Action Block -Enabled True -ErrorAction SilentlyContinue |
>     Select-Object DisplayName, Profile, PolicyStoreSourceType
> # Maintenance - ne pas supprimer   Any   Local
> Get-NetFirewallRule -DisplayName "Maintenance - ne pas supprimer" | Get-NetFirewallPortFilter
> # Protocol TCP  RemotePort 445
> ```
> `PolicyStoreSourceType Local` : créée sur le poste, pas par une GPO. Le nom rassurant est volontaire.
> **Panne 3 trouvée : règle de pare-feu.**

**B4.** Corrige chaque panne et vérifie : résolution, `Test-NetConnection -Port 445`, accès au partage, canal sécurisé avec le domaine.

> [!success]- Afficher la correction — B4
> ```powershell
> # 1. DNS : revenir au DHCP (qui distribue le DNS du domaine)…
> Set-DnsClientServerAddress -InterfaceAlias Ethernet -ResetServerAddresses
> # …ou fixer explicitement : -ServerAddresses 192.168.3.1
> # (nom de la carte : (Get-NetAdapter | Where-Object Status -eq 'Up').Name)
>
> # 2. hosts : retirer la ligne ajoutée
> $h = "$env:windir\System32\drivers\etc\hosts"
> (Get-Content $h) | Where-Object { $_ -notmatch 'srv01' } | Set-Content $h
> Clear-DnsClientCache
>
> # 3. Pare-feu
> Remove-NetFirewallRule -DisplayName "Maintenance - ne pas supprimer"
> ```
> Vérifications :
> ```powershell
> Resolve-DnsName srv01.ad.fournil.lab          # 192.168.3.1, depuis le DNS
> Test-NetConnection srv01 -Port 445            # TcpTestSucceeded : True
> Test-ComputerSecureChannel                    # True
> nltest /dsgetdc:ad.fournil.lab                # DC: \\SRV01…
> gpupdate /force
> ```
> Ensuite reconnexion de l'utilisateur : `P:` revient.

---

## Partie C — Services et impression (15 min)

**C1.** Impossible d'imprimer. Trouve le service en cause, son état et son type de démarrage.

> [!success]- Afficher la correction — C1
> ```powershell
> Get-Service Spooler | Select-Object Name, Status, StartType
> # Spooler  Stopped  Disabled
> ```
> Méthode générique (chapitre 19) : les services **automatiques arrêtés**, puis les services **désactivés** inhabituels.
> **Panne 4 trouvée : spouleur.**

**C2.** Retrouve dans le journal **Système** l'événement qui trace le changement de type de démarrage.

> [!success]- Afficher la correction — C2
> ```powershell
> Get-WinEvent -FilterHashtable @{ LogName='System'; ProviderName='Service Control Manager'; Id=7040 } -MaxEvents 5 |
>     Format-List TimeCreated, Message
> # Le type de démarrage du service Spouleur d'impression est passé de Démarrage automatique à désactivé.
> ```
> L'ID **7040** donne le *quand* : on peut le rapprocher des autres changements (règle de pare-feu, tâche planifiée) et en déduire qu'il s'agit d'une seule action.

**C3.** Corrige et vérifie par une impression de test.

> [!success]- Afficher la correction — C3
> ```powershell
> Set-Service Spooler -StartupType Automatic
> Start-Service Spooler
> ```
> Paramètres → Imprimantes → *Microsoft Print to PDF* → imprimer une page de test.

---

## Partie D — Le programme mystère (25 min)

Un utilisateur trouve son poste « lent depuis hier » et voit parfois un processus PowerShell dans le Gestionnaire des tâches.

**D1.** Trouve ce qui lance `powershell.exe` à l'ouverture de session. Cherche dans au moins deux endroits : les emplacements de démarrage (Gestionnaire des tâches, `Run`) et les tâches planifiées.

> [!success]- Afficher la correction — D1
> Gestionnaire des tâches → **Applications de démarrage** : rien d'anormal. Clés `Run` : rien non plus. La persistance est dans le **Planificateur de tâches** :
> ```powershell
> Get-ScheduledTask | Where-Object { $_.Actions.Execute -match 'powershell|pwsh|cmd|wscript' -and
>                                    $_.TaskPath -notlike '\Microsoft\*' } |
>     Select-Object TaskPath, TaskName, State
> # \   OneDrive Updater Helper   Ready
> ```
> Les tâches légitimes de Microsoft sont rangées sous `\Microsoft\…` ; une tâche à la **racine** qui lance un interpréteur de script mérite toujours un regard. Outil complet : **Autoruns** (Sysinternals), onglet *Scheduled Tasks*.

**D2.** Sous quel compte s'exécute-t-il ? Que fait le script lancé ? Pourquoi le nom de la tâche est-il trompeur ?

> [!success]- Afficher la correction — D2
> ```powershell
> $t = Get-ScheduledTask -TaskName 'OneDrive Updater Helper'
> $t.Principal.UserId          # SYSTEM
> $t.Triggers                  # MSFT_TaskLogonTrigger (à chaque ouverture de session)
> $t.Actions.Arguments         # -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\ProgramData\Updater\upd.ps1
> Get-Content C:\ProgramData\Updater\upd.ps1   # Start-Sleep 600
> ```
> Le script est inoffensif (il attend 10 minutes), mais tout y est : exécution en **SYSTEM**, fenêtre **cachée**, **contournement** de la stratégie d'exécution, dossier `ProgramData` accessible en écriture, et un **nom** qui imite un composant légitime (OneDrive ne crée pas de tâche à ce nom ni à la racine). C'est exactement la forme des persistances réelles.

**D3.** Si Sysmon est actif (chapitre 19), retrouve la création du processus (ID 1) et sa ligne de commande complète, avec le processus parent.

> [!success]- Afficher la correction — D3
> ```powershell
> Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Sysmon/Operational'; Id=1 } -MaxEvents 200 |
>     Where-Object Message -match 'upd\.ps1' | Select-Object -First 1 | Format-List TimeCreated, Message
> ```
> On y lit `Image: …\powershell.exe`, `CommandLine: … -File C:\ProgramData\Updater\upd.ps1`, `User: AUTORITE NT\Système`, `ParentImage: C:\Windows\System32\svchost.exe` (le service Planificateur) — confirmation que c'est bien une **tâche planifiée** et non une clé `Run` (le parent serait alors `explorer.exe`).

**D4.** Supprime la persistance et le script. Vérifie après une nouvelle ouverture de session.

> [!success]- Afficher la correction — D4
> ```powershell
> Unregister-ScheduledTask -TaskName 'OneDrive Updater Helper' -Confirm:$false
> Remove-Item C:\ProgramData\Updater -Recurse -Force
> ```
> En situation réelle, **avant** de supprimer : exporter la tâche (`Export-ScheduledTask`) et copier le script pour analyse, puis se demander **comment** c'est arrivé (compte compromis ? admin local trop répandu ? → LAPS, Administrator protection, chapitre 09).
> **Panne 5 trouvée : persistance.**

---

## Partie E — Vérifier et clore (15 min)

**E1.** Écris un petit script `Test-Poste.ps1` qui vérifie en une passe : DNS = contrôleur de domaine, `srv01` résolu vers la bonne adresse, port 445 ouvert vers `srv01`, Spooler démarré et automatique, aucune règle de pare-feu sortante de blocage personnalisée, aucune tâche planifiée à la racine lançant `powershell.exe`.

> [!success]- Afficher la correction — E1
> ```powershell
> # Test-Poste.ps1 — contrôle rapide d'un poste du domaine Fournil
> $dc  = '192.168.3.1'
> $res = [ordered]@{}
>
> $dns = (Get-DnsClientServerAddress -AddressFamily IPv4 |
>         Where-Object ServerAddresses).ServerAddresses
> $res['DNS = DC']          = ($dns -contains $dc) -and -not ($dns | Where-Object { $_ -ne $dc })
> $res['srv01 -> DC']       = (Resolve-DnsName srv01.ad.fournil.lab -Type A -ErrorAction SilentlyContinue).IPAddress -contains $dc
> $res['SMB vers srv01']    = (Test-NetConnection srv01.ad.fournil.lab -Port 445 -WarningAction SilentlyContinue).TcpTestSucceeded
> $sp = Get-Service Spooler
> $res['Spooler']           = $sp.Status -eq 'Running' -and $sp.StartType -eq 'Automatic'
> $res['Pas de blocage sortant local'] = -not (Get-NetFirewallRule -Direction Outbound -Action Block -Enabled True -ErrorAction SilentlyContinue |
>                                         Where-Object PolicyStoreSourceType -eq 'Local')
> $res['Pas de tâche script à la racine'] = -not (Get-ScheduledTask -TaskPath '\' |
>                                         Where-Object { $_.Actions.Execute -match 'powershell|pwsh|cmd|wscript' })
> $res['Canal sécurisé']    = Test-ComputerSecureChannel
>
> $res.GetEnumerator() | ForEach-Object {
>     $c = if ($_.Value) { 'Green' } else { 'Red' }
>     Write-Host ("{0,-35} {1}" -f $_.Key, $(if ($_.Value) {'OK'} else {'KO'})) -ForegroundColor $c
> }
> ```
> Testé sur `PC02` : avant les pannes, 7 OK ; juste après `Casse-Poste.ps1`, **6 KO** — le canal sécurisé reste OK tant que le poste n'a pas redémarré (le DC est encore en cache) ; après les corrections de B4, C3 et D4, 7 OK. Ce script devient l'outil de vérification du TP 20.

**E2.** Complète la fiche d'intervention : causes, corrections, vérifications, recommandations pour éviter la récidive.

> [!success]- Afficher la correction — E2
> ```
> Causes : 1. DNS remplacé par 8.8.8.8   2. entrée hosts srv01 → .250
>          3. règle pare-feu sortante TCP 445   4. Spooler désactivé
>          5. tâche planifiée SYSTEM « OneDrive Updater Helper » (persistance)
> Corrections : (commandes de B4, C3, D4)
> Vérification : Test-Poste.ps1 tout OK, P: présent, impression OK, gpupdate OK
> Durée : 1h10
> Recommandations : retirer les droits admin locaux (LAPS + Administrator protection),
>   forcer le DNS par DHCP/GPO, pare-feu géré par GPO (fusion des règles locales désactivée),
>   App Control / AppLocker sur ProgramData, Sysmon activé sur le parc.
> ```
> La recommandation « *fusion des règles locales désactivée* » (GPO pare-feu → *Paramètres → Appliquer les règles de pare-feu locales : Non*) aurait rendu la panne 3 inopérante.

**E3.** Combien de pannes as-tu trouvé ? Compare avec le script `Casse-Poste.ps1`.

> [!success]- Afficher la correction — E3
> Le script installe **5 pannes** : DNS, hosts, pare-feu, spouleur, tâche planifiée. Les plus souvent ratées :
> - **hosts** : masquée tant que le DNS est faux, elle n'apparaît qu'**après** la première correction (d'où l'importance de **revérifier** après chaque correction) ;
> - **tâche planifiée** : aucun symptôme visible, sauf si l'on cherche activement.
>
> Restaurer le point de contrôle Hyper-V *Avant-pannes* remet tout d'aplomb, mais en production il n'existe pas : d'où la méthode.

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/19-depannage/tp)
