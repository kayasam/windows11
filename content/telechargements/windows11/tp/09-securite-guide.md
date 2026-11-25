# TP 09. Sécuriser un poste Windows 11, version guidée

**Ta mission.** Sur `PC01`, compare un compte standard et un compte administrateur, vérifie les protections du poste puis termine l’activation de BitLocker. Utilise les comptes du TP 03 et les clés propres à ta VM.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/09-securite/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/09-securite/tp/standard)

## Vérifier les droits et l’UAC

### A1 — Identifier les administrateurs locaux

Dans PowerShell sur `PC01`, lance `Get-LocalGroupMember Administrateurs`. Compare la liste avec `admin` et `employe1`.

### A2 — Comparer les demandes d’élévation

Dans la session `employe1`, demande **Exécuter en tant qu’administrateur** sur Terminal et observe la boîte puis annule. Refais le test dans la session `admin`.

## Vérifier Defender et le pare-feu

### B1 — Lire l’état de Defender

Dans PowerShell administrateur sur `PC01`, lance `Get-MpComputerStatus | Select-Object RealTimeProtectionEnabled,AntivirusSignatureVersion,IsTamperProtected`.

### B2 — Tester une analyse rapide

Lance `Start-MpScan -ScanType QuickScan`. Ensuite, ouvre **Sécurité Windows → Protection contre les virus et menaces → Historique de protection** ou relève `QuickScanEndTime` avec `Get-MpComputerStatus`.

### B3 — Créer une règle limitée au réseau du lab

Dans `wf.msc`, crée une règle entrante pour TCP **8080**, nommée **Fournil-Web-8080**. Dans ses propriétés, règle **Étendue → Adresses IP distantes** à `192.168.3.0/24` et garde le seul profil **Domaine**.

## Activer la protection BitLocker

### C1 — Observer l’état initial de C:

Dans PowerShell administrateur sur `PC01`, lance `Get-BitLockerVolume -MountPoint C: | Select-Object VolumeStatus,ProtectionStatus`. Relève aussi si un support d’installation est encore monté dans la VM.

### C2 — Enregistrer la récupération puis activer le TPM

Sur `PC01`, ouvre `control /name Microsoft.BitLockerDriveEncryption`. Pour `C:`, active BitLocker ou termine l’activation selon l’état affiché. Enregistre d’abord la clé de récupération à l’emplacement privé prévu par le formateur. Configure la protection TPM et vérifie l’état final.

### C3 — Confirmer le protecteur sans afficher la clé

Lance `(Get-BitLockerVolume -MountPoint C:).KeyProtector | Select-Object KeyProtectorType,KeyProtectorId`. Confirme que ton enregistrement privé correspond au protecteur de récupération de ce poste.

[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/09-securite/tp/guide-corrigev2)
