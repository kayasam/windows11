# TP 12. Administrer SRV01 depuis PC01, corrigé guidé

**Mission** · Depuis `PC01`, vérifie que le serveur Fournil répond et relève l’état de DNS et DHCP.

**Avant de commencer** · Après le TP 11, `PC01` est joint au domaine `ad.fournil.lab`. `SRV01` est démarré. Les deux VM sont sur `vSwitch-Rennes`.

> [!tip] Identifiants du lab
> Dans la fenêtre d’identification de Windows, saisis `Administrateur@ad.fournil.lab` et le mot de passe fourni par le formateur.


[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/)

### 0. Comparer les ports en écoute

Sur les consoles des deux VM, ouvre **Windows PowerShell** et lance les mêmes commandes. Sur `SRV01`, tu peux aussi demander au formateur d’afficher le résultat.

```powershell
hostname
Get-NetTCPConnection -State Listen |
    Where-Object { $_.LocalPort -in 22, 135, 445, 3389, 5985 } |
    Sort-Object LocalPort |
    Select-Object LocalAddress, LocalPort, State
```

Repère le port `5985` sur `SRV01`. Si une ligne apparaît deux fois, compare les adresses locales (par exemple IPv4 et IPv6). Fais ensuite les trois étapes depuis `PC01`.

> [!success]- Afficher la correction
> Le port `5985` est attendu sur `SRV01` lorsque WinRM est disponible en HTTP. `PC01` peut appeler WinRM sans avoir son propre port `5985` en écoute. Les autres ports dépendent des services configurés.

### 1. Tester le serveur

Dans **Windows PowerShell sur PC01**, lance `Test-WSMan srv01.ad.fournil.lab`. Est-ce que tu vois le champ `ProductVendor` ?

> [!success]- Afficher la correction
> Une réponse avec `ProductVendor` indique que le service WinRM répond sur `SRV01`. Si la commande échoue, vérifie le nom avec `Resolve-DnsName srv01.ad.fournil.lab`, puis suis le dépannage du cours.

### 2. Ouvrir la session distante

Depuis **PC01**, lance la commande ci-dessous. Dans la fenêtre d’identification, utilise le compte indiqué dans l’encadré. Attends de voir le nom du serveur entre crochets dans l’invite.

```powershell
Enter-PSSession -ComputerName srv01.ad.fournil.lab -Credential 'Administrateur@ad.fournil.lab'
```

> [!success]- Afficher la correction
> L’invite commence par le nom de `SRV01` entre crochets. Les commandes s’exécutent alors sur le serveur.

### 3. Vérifier les services et revenir sur PC01

Dans la **session distante**, lance `hostname` puis `Get-Service DNS, DHCPServer`. Note le nom de la machine et le statut des deux services. Tape `Exit-PSSession`, puis relance `hostname`. Quel nom vois-tu maintenant ?

> [!success]- Afficher la correction
> Dans la session distante, `hostname` affiche `SRV01`. Les services `DNS` et `DHCPServer` doivent normalement afficher `Running` dans le lab. Après `Exit-PSSession`, `hostname` affiche `PC01`.

[Retour à l’énoncé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide)
