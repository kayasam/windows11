# TP 16. Administrer SRV01 depuis PC01, version guidée

**Mission** · Depuis `PC01`, vérifie que le serveur Fournil répond et relève l’état de DNS et DHCP.

**Avant de commencer** · `PC01` est joint au domaine `ad.fournil.lab`. `SRV01` est démarré sur le réseau du lab. Utilise le compte autorisé fourni pour administrer `SRV01`.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/)

### 1. Tester le serveur

Dans **Windows PowerShell sur PC01**, lance `Test-WSMan srv01.ad.fournil.lab`. Est-ce que tu vois le champ `ProductVendor` ?

### 2. Ouvrir la session distante

Depuis **PC01**, lance la commande ci-dessous. Dans la fenêtre d’identification, saisis le compte autorisé du lab au format `FOURNIL\utilisateur`. Attends de voir le nom du serveur entre crochets dans l’invite.

```powershell
Enter-PSSession -ComputerName srv01.ad.fournil.lab -Credential (Get-Credential)
```

### 3. Vérifier les services et revenir sur PC01

Dans la **session distante**, lance `hostname` puis `Get-Service DNS, DHCPServer`. Note le nom de la machine et le statut des deux services. Tape `Exit-PSSession`, puis relance `hostname`. Quel nom vois-tu maintenant ?

[Ouvrir le corrigé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide-corrigev2)
