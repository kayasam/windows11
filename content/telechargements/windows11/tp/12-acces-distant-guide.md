# TP 12. Administrer SRV01 depuis PC01, version guidée

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

### 1. Tester le serveur

Dans **Windows PowerShell sur PC01**, lance `Test-WSMan srv01.ad.fournil.lab`. Est-ce que tu vois le champ `ProductVendor` ?

### 2. Ouvrir la session distante

Depuis **PC01**, lance la commande ci-dessous. Dans la fenêtre d’identification, utilise le compte indiqué dans l’encadré. Attends de voir le nom du serveur entre crochets dans l’invite.

```powershell
Enter-PSSession -ComputerName srv01.ad.fournil.lab -Credential 'Administrateur@ad.fournil.lab'
```

### 3. Vérifier les services et revenir sur PC01

Dans la **session distante**, lance `hostname` puis `Get-Service DNS, DHCPServer`. Note le nom de la machine et le statut des deux services. Tape `Exit-PSSession`, puis relance `hostname`. Quel nom vois-tu maintenant ?


