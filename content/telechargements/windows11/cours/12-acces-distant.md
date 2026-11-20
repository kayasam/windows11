# 16. Administrer SRV01 depuis PC01

Tu es sur `PC01`. Ton objectif est de te connecter à `SRV01` avec Windows PowerShell pour vérifier l’état de deux services du serveur.

Prépare `PC01` joint au domaine `ad.fournil.lab`, `SRV01` démarré et un compte du lab autorisé à administrer le serveur. Fais le TP sur le réseau du lab, après le chapitre Active Directory.

## 1. Tester l’accès à SRV01

Sur **PC01**, ouvre **Windows PowerShell**, puis tape :

```powershell
Test-WSMan srv01.ad.fournil.lab
```

Si tu vois `ProductVendor`, le service WinRM de `SRV01` répond. WinRM permet à PowerShell d’exécuter des commandes sur le serveur. Le test confirme la réponse du service. L’étape suivante vérifie les droits du compte.

Si le test échoue, lance `Resolve-DnsName srv01.ad.fournil.lab` depuis `PC01`. Si le nom ne se résout pas, vérifie le réseau du lab et le DNS de `PC01`. Si le nom se résout, demande au formateur de vérifier WinRM sur `SRV01`.

## 2. Ouvrir une session sur le serveur

Toujours sur **PC01**, lance cette commande et saisis le compte autorisé du lab au format `FOURNIL\utilisateur`.

```powershell
Enter-PSSession -ComputerName srv01.ad.fournil.lab -Credential (Get-Credential)
```

Quand l’invite PowerShell commence par le nom de `SRV01` entre crochets, les commandes tapées dans cette fenêtre s’exécutent sur le serveur. Si l’accès est refusé, vérifie le compte choisi et ses droits avec le formateur.

## 3. Vérifier DNS et DHCP, puis revenir sur PC01

Dans la **session distante**, lance :

```powershell
hostname
Get-Service DNS, DHCPServer
```

`hostname` doit afficher `SRV01`. La colonne `Status` te permet de vérifier si les services DNS et DHCP sont démarrés (`Running`).

Tape `Exit-PSSession` pour fermer la session distante. Relance `hostname`. Tu dois revoir `PC01`.

[Faire le TP guidé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide)

[Microsoft Learn · Tester WinRM](https://learn.microsoft.com/powershell/module/microsoft.wsman.management/test-wsman?view=powershell-5.1) · [Microsoft Learn · Ouvrir une session à distance](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/enter-pssession?view=powershell-5.1)
