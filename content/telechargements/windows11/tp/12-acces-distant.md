# TP 16. Administrer SRV01 depuis PC01

**Mission** · Depuis `PC01`, vérifie que le serveur Fournil répond et relève l’état de DNS et DHCP.

**Avant de commencer** · `PC01` est joint au domaine `ad.fournil.lab`. `SRV01` est démarré sur le réseau du lab. Utilise le compte autorisé fourni pour administrer `SRV01`.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/)

### 1. Tester le serveur

Depuis `PC01`, vérifie que WinRM répond sur `srv01.ad.fournil.lab`. Note l’information qui te le confirme.

### 2. Ouvrir la session distante

Ouvre une session PowerShell distante sur `SRV01` avec le compte autorisé du lab. Relève l’indice qui te confirme que tu es dans cette session.

### 3. Vérifier les services et revenir sur PC01

Dans la **session distante**, lance `hostname` puis `Get-Service DNS, DHCPServer`. Note le nom de la machine et le statut des deux services. Tape `Exit-PSSession`, puis relance `hostname`. Quel nom vois-tu maintenant ?



[Ouvrir la version guidée](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide)
