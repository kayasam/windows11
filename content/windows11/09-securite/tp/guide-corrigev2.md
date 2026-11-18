---
title: "TP 09. Sécuriser un poste Windows 11, corrigé guidé"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/09-securite"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/09-securite/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/09-securite/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/09-securite/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/09-securite-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/09-securite/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/09-securite/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Ta mission.** Sur `PC01`, compare un compte standard et un compte administrateur, vérifie les protections du poste puis termine l’activation de BitLocker. Utilise les comptes du TP 03 et les clés propres à ta VM.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/09-securite/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/09-securite/tp/standard)

## Vérifier les droits et l’UAC

### A1 — Identifier les administrateurs locaux

Dans PowerShell sur `PC01`, lance `Get-LocalGroupMember Administrateurs`. Compare la liste avec `admin` et `employe1`.

> [!success]- Afficher la correction — A1
> `admin` est administrateur local dans le lab. `employe1` est un compte standard. Utilise-le pour les manipulations du quotidien qui ne demandent pas d’élévation.

### A2 — Comparer les demandes d’élévation

Dans la session `employe1`, demande **Exécuter en tant qu’administrateur** sur Terminal et observe la boîte puis annule. Refais le test dans la session `admin`.

> [!success]- Afficher la correction — A2
> Un compte standard doit fournir des identifiants administrateur selon la stratégie. Un administrateur en mode d’approbation reçoit généralement une demande de consentement.

## Vérifier Defender et le pare-feu

### B1 — Lire l’état de Defender

Dans PowerShell administrateur sur `PC01`, lance `Get-MpComputerStatus | Select-Object RealTimeProtectionEnabled,AntivirusSignatureVersion,IsTamperProtected`.

> [!success]- Afficher la correction — B1
> `RealTimeProtectionEnabled` indique l’état du temps réel. `AntivirusSignatureVersion` relève le niveau de signatures et `IsTamperProtected` indique la protection contre les modifications.

### B2 — Tester une analyse rapide

Lance `Start-MpScan -ScanType QuickScan`. Ensuite, ouvre **Sécurité Windows → Protection contre les virus et menaces → Historique de protection** ou relève `QuickScanEndTime` avec `Get-MpComputerStatus`.

> [!success]- Afficher la correction — B2
> Une analyse terminée peut ne produire aucune alerte. L’heure de fin ou le dernier résultat permet de vérifier l’exécution.

### B3 — Créer une règle limitée au réseau du lab

Dans `wf.msc`, crée une règle entrante pour TCP **8080**, nommée **Fournil-Web-8080**. Dans ses propriétés, règle **Étendue → Adresses IP distantes** à `192.168.3.0/24` et garde le seul profil **Domaine**.

> [!success]- Afficher la correction — B3
> Vérifie le port, le profil et la portée après enregistrement. Si `Get-NetConnectionProfile` indique **Public**, la règle Domaine ne s’applique pas encore.

## Activer la protection BitLocker

### C1 — Observer l’état initial de C:

Dans PowerShell administrateur sur `PC01`, lance `Get-BitLockerVolume -MountPoint C: | Select-Object VolumeStatus,ProtectionStatus`. Relève aussi si un support d’installation est encore monté dans la VM.

> [!success]- Afficher la correction — C1
> `VolumeStatus` indique l’état du chiffrement et `ProtectionStatus` celui de la protection. Un volume déjà chiffré peut encore présenter `Off`.

### C2 — Enregistrer la récupération puis activer le TPM

Sur `PC01`, ouvre `control /name Microsoft.BitLockerDriveEncryption`. Pour `C:`, active BitLocker ou termine l’activation selon l’état affiché. Enregistre d’abord la clé de récupération à l’emplacement privé prévu par le formateur. Configure la protection TPM et vérifie l’état final.

> [!success]- Afficher la correction — C2
> Le résultat attendu est `ProtectionStatus : On` avec des protecteurs `RecoveryPassword` et `Tpm`. Si l’erreur `0x80310030` apparaît dans le lab, vérifie sur l’hôte qu’aucun DVD d’installation n’est encore monté avant de réessayer.

### C3 — Confirmer le protecteur sans afficher la clé

Lance `(Get-BitLockerVolume -MountPoint C:).KeyProtector | Select-Object KeyProtectorType,KeyProtectorId`. Confirme que ton enregistrement privé correspond au protecteur de récupération de ce poste.

> [!success]- Afficher la correction — C3
> Au moins un protecteur `RecoveryPassword` est listé. L’identifiant sert à retrouver l’enregistrement privé. Le TP GPO guidera la sauvegarde du protecteur dans AD.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/09-securite/tp/guide)
