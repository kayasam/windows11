---
title: "TP 09. Sécuriser un poste Windows 11 — Correction"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/09-securite"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/09-securite/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/09-securite/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/09-securite-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/09-securite/tp">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/09-securite/tp-corrigev2" aria-current="page">Corrigé</a></nav>

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 2h

> Chapitres associés : [09. Sécuriser un poste Windows 11](https://cours.kaya.ovh/windows11/windows11/09-securite/)

---

## Objectifs

- Appliquer le moindre privilège sur `PC01`
- Lire et régler l'UAC, connaître Administrator protection
- Vérifier Microsoft Defender et comprendre la protection contre les falsifications
- Ouvrir un port proprement dans le pare-feu, par profil
- Terminer la protection BitLocker laissée « à moitié » par Windows
- Mettre en place et **tester** AppLocker sur l'édition Pro

---

## Prérequis

- `PC01` (TP 03), comptes `admin` (administrateur) et `employe1` (standard, mot de passe `P@ssw0rd2026!`)
- **Aucune ISO montée** dans la VM (voir partie D)

---

## Partie A — Moindre privilège (15 min)

**A1.** Qui est administrateur de `PC01` ? Que faut-il penser du compte `admin` utilisé au quotidien ?

> [!success]- Afficher la correction — A1
> ```powershell
> Get-LocalGroupMember -Group "Administrateurs"
> ```
> `PC01\admin` (et l'`Administrateur` intégré, désactivé). Utiliser `admin` au quotidien (navigation, messagerie) expose tout le poste : un malware lancé par erreur hérite potentiellement des droits administrateur (après un simple clic UAC). Bonne pratique : un compte **standard** pour le quotidien, un compte d'administration distinct pour l'administration.

**A2.** Ouvre une session `employe1`. Essaie d'installer un logiciel (`winget install Notepad++.Notepad++`) puis de modifier l'heure système. Que se passe-t-il ?

> [!success]- Afficher la correction — A2
> - `winget install` d'un logiciel **machine** : l'installeur demande l'élévation → invite UAC **avec identifiants** d'un administrateur. Sans eux, échec. (Certains paquets s'installent en portée utilisateur, dans le profil : c'est justement ce qu'AppLocker permet d'empêcher.)
> - Changer l'heure système : réservé au droit *Modifier l'heure système* (Administrateurs, Service local) → refusé.

**A3.** Dans `secpol.msc`, retrouve qui a le droit d'« ouvrir une session en tant que tâche » (*Log on as a batch job*). Pourquoi est-ce important pour les tâches planifiées d'un utilisateur standard ?

> [!success]- Afficher la correction — A3
> `secpol.msc` → **Stratégies locales → Attribution des droits utilisateur → Ouvrir une session en tant que tâche** : *Administrateurs, Opérateurs de sauvegarde, Utilisateurs du journal de performances*. **Pas** les Utilisateurs.
> Constaté sur le lab : une tâche planifiée créée pour `employe1` (avec son mot de passe) ne démarre jamais — `LastTaskResult = 0x41303` (« pas encore exécutée »). Les tâches d'un utilisateur standard doivent être de type « exécuter seulement si l'utilisateur est connecté » (session interactive), ou tourner en SYSTEM.

---

## Partie B — UAC et Administrator protection (15 min)

**B1.** Lis les valeurs UAC du registre. À quel niveau de la réglette correspondent-elles ?

> [!success]- Afficher la correction — B1
> ```powershell
> Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" |
>     Select-Object EnableLUA, ConsentPromptBehaviorAdmin, PromptOnSecureDesktop
> ```
> `EnableLUA=1`, `ConsentPromptBehaviorAdmin=5`, `PromptOnSecureDesktop=1` → niveau **par défaut** (« M'avertir uniquement quand des applications tentent d'apporter des modifications », bureau sécurisé).

**B2.** Depuis la session `employe1`, lance un terminal **en tant qu'administrateur**. Que demande l'UAC ? Et depuis la session `admin` ?

> [!success]- Afficher la correction — B2
> - **employe1** : invite UAC demandant **nom et mot de passe** d'un administrateur (*demande d'informations d'identification*).
> - **admin** : invite de **consentement** (bouton « Oui ») sur bureau sécurisé : `admin` possède déjà le jeton administrateur, il lui suffit de l'autoriser.

**B3.** Quelle valeur de `TypeOfAdminApprovalMode` est relevée sur `PC01` ? Que change le passage à `2` ?

> [!success]- Afficher la correction — B3
> `TypeOfAdminApprovalMode = 1` sur `PC01` : **UAC classique**. Avec `2` (**Administrator protection**), l'élévation ne donne plus le jeton administrateur du compte `admin` : Windows crée un **compte fantôme système** distinct, juste le temps de l'opération, et demande une authentification **Windows Hello** (PIN/biométrie) ou le mot de passe. Les contournements d'UAC qui détournent le jeton du même utilisateur ne fonctionnent plus. Réglage : `secpol.msc` → *Contrôle de compte d'utilisateur : configurer le type de mode d'approbation administrateur*, puis redémarrage.

---

## Partie C — Defender et pare-feu (25 min)

**C1.** Relève l'état de Defender : protection temps réel, version des signatures, protection contre les falsifications.

> [!success]- Afficher la correction — C1
> ```powershell
> Get-MpComputerStatus | Select-Object RealTimeProtectionEnabled, IsTamperProtected, AntivirusSignatureVersion, AMRunningMode
> ```
> Sur `PC01` : `RealTimeProtectionEnabled = True`, `IsTamperProtected = True`, `AMRunningMode = Normal`, signatures `1.437.x` — en retard sur la version proposée par Windows Update (`1.463.186.0`, TP 08) : un `Update-MpSignature` s'impose.

**C2.** Essaie de désactiver la protection en temps réel avec `Set-MpPreference`. Que se passe-t-il ? Pourquoi ?

> [!success]- Afficher la correction — C2
> ```powershell
> Set-MpPreference -DisableRealtimeMonitoring $true
> Get-MpComputerStatus | Select-Object RealTimeProtectionEnabled     # toujours True
> ```
> La commande ne renvoie pas d'erreur… mais n'a **aucun effet** : la **protection contre les falsifications** (*Tamper Protection*) ignore les modifications faites par script ou registre, même en administrateur. C'est exactement ce que ferait un malware. Pour la désactiver, il faut passer par l'interface **Sécurité Windows** (interactif) ou par la console Intune/Defender for Endpoint.

**C3.** Lance une analyse rapide en PowerShell, puis consulte l'historique des menaces.

> [!success]- Afficher la correction — C3
> ```powershell
> Update-MpSignature
> Start-MpScan -ScanType QuickScan
> Get-MpThreatDetection        # historique des détections (vide sur un poste sain)
> Get-MpThreat
> ```
> Test sans danger : le fichier de test **EICAR** (chaîne texte standard que tous les antivirus détectent) — Defender le met en quarantaine dès son écriture sur le disque.

**C4.** Le Fournil installe sur `PC01` un petit serveur web interne sur le port TCP 8080. Crée la règle de pare-feu entrante, **uniquement** pour le profil Domaine et le réseau `192.168.3.0/24`.

> [!success]- Afficher la correction — C4
> ```powershell
> New-NetFirewallRule -DisplayName "Fournil - Web interne 8080" -Direction Inbound -Protocol TCP `
>     -LocalPort 8080 -RemoteAddress 192.168.3.0/24 -Profile Domain -Action Allow
> Get-NetFirewallRule -DisplayName "Fournil - Web interne 8080" | Get-NetFirewallAddressFilter
> ```
> On restreint **le profil** (Domaine : le poste est sur le réseau de l'entreprise) **et la source** (le réseau du Fournil). Le préfixe « Fournil - » permet de retrouver ses règles parmi des centaines.

**C5.** Quel est le profil réseau actif de `PC01` ? La règle s'applique-t-elle maintenant ? Et après la jonction au domaine ?

> [!success]- Afficher la correction — C5
> ```powershell
> Get-NetConnectionProfile | Select-Object InterfaceAlias, NetworkCategory    # Public
> ```
> Profil **Public** → la règle (profil Domaine) **ne s'applique pas encore** : le port reste fermé. Après la jonction au domaine (chapitre 10), le profil passe automatiquement en **DomainAuthenticated** et la règle devient active. C'est le piège déjà rencontré avec la règle OpenSSH (profil Privé seulement).

---

## Partie D — BitLocker (30 min)

**D1.** Relève l'état BitLocker de `C:` **sans rien avoir activé**. Le disque est-il chiffré ? Les données sont-elles protégées ?

> [!success]- Afficher la correction — D1
> ```powershell
> Get-BitLockerVolume C: | Select-Object VolumeStatus, ProtectionStatus, EncryptionMethod, KeyProtector
> ```
> ```
> VolumeStatus     : FullyEncrypted
> ProtectionStatus : Off
> EncryptionMethod : XtsAes128
> KeyProtector     : {}
> ```
> Le disque **est chiffré** (chiffrement automatique de l'appareil, 24H2+)… mais **pas protégé** : aucun protecteur, la clé est en clair sur le disque. Un voleur qui démarre le disque sur un autre PC lit tout.

**D2.** Termine la protection : clé de récupération puis TPM, puis active la protection. Relève l'état final.

> [!success]- Afficher la correction — D2
> ```powershell
> Add-BitLockerKeyProtector -MountPoint C: -RecoveryPasswordProtector
> Add-BitLockerKeyProtector -MountPoint C: -TpmProtector
> Resume-BitLocker -MountPoint C:
> Get-BitLockerVolume C: | Select-Object VolumeStatus, ProtectionStatus, KeyProtector
> ```
> ```
> VolumeStatus     : FullyEncrypted
> ProtectionStatus : On
> KeyProtector     : {RecoveryPassword, Tpm}
> ```
> L'ordre compte : **clé de récupération d'abord**. Avec le TPM seul, une modification du démarrage rendrait les données irrécupérables.

**D3.** Un stagiaire obtient `0x80310030` à l'étape TPM. Que se passe-t-il ?

> [!success]- Afficher la correction — D3
> *« Le chiffrement de lecteur BitLocker a détecté la présence d'un média de démarrage amovible (CD ou DVD) »* — vécu sur le lab : l'ISO de Windows était encore montée dans la VM. BitLocker refuse de sceller la clé dans le TPM tant qu'un média de démarrage est présent (la mesure du démarrage serait différente au redémarrage suivant). Sur l'hôte :
> ```powershell
> Get-VMDvdDrive PC01 | Set-VMDvdDrive -Path $null
> ```

**D4.** Affiche la clé de récupération (48 chiffres). Où le Fournil devrait-il la stocker ?

> [!success]- Afficher la correction — D4
> ```powershell
> (Get-BitLockerVolume C:).KeyProtector | Where-Object KeyProtectorType -eq RecoveryPassword |
>     Select-Object KeyProtectorId, RecoveryPassword
> ```
> ```
> KeyProtectorId   : {C41E3312-A988-4435-80C0-D765E10FB5B9}
> RecoveryPassword : 354739-124608-622754-706079-676819-067672-347611-326205
> ```
> Stockage : dans **Active Directory**, automatiquement via GPO (chapitre 11) — sinon dans un coffre de mots de passe d'équipe, **jamais** seulement sur le poste lui-même. L'ID du protecteur (affiché à l'écran de récupération) permet de retrouver la bonne clé.

**D5.** Avant une mise à jour du firmware UEFI, que fais-tu pour éviter de devoir saisir la clé au redémarrage ?

> [!success]- Afficher la correction — D5
> ```powershell
> Suspend-BitLocker -MountPoint C: -RebootCount 1
> ```
> (`manage-bde -protectors -disable C: -RebootCount 1`.) La protection reprend seule après un redémarrage. Windows Update le fait automatiquement pour les mises à jour UEFI qu'il distribue.

**D6.** Chiffre une clé USB virtuelle (ou le volume `G:` du TP 04) avec BitLocker To Go et un mot de passe.

> [!success]- Afficher la correction — D6
> ```powershell
> Enable-BitLocker -MountPoint G: -PasswordProtector -Password (Read-Host -AsSecureString "Mot de passe") -UsedSpaceOnly
> Add-BitLockerKeyProtector -MountPoint G: -RecoveryPasswordProtector
> ```
> Ou clic droit sur le lecteur → **Activer BitLocker** → « Utiliser un mot de passe pour déverrouiller le lecteur ». Sur un vrai support amovible, choisir le mode **compatible** si la clé doit être lue sur d'anciens Windows.

---

## Partie E — AppLocker sur Windows 11 Pro (25 min)

**E1.** Crée les **règles par défaut** des exécutables et passe la collection en **Appliquer**. Démarre le service nécessaire.

> [!success]- Afficher la correction — E1
> `secpol.msc` → **Stratégies de contrôle d'application → AppLocker** :
> 1. **Configurer l'application des règles** → *Règles de l'exécutable* : cocher **Configuré** → **Appliquer les règles** ;
> 2. clic droit sur **Règles de l'exécutable** → **Créer des règles par défaut** (Program Files, Windows, Administrateurs partout).
> ```powershell
> Set-Service AppIDSvc -StartupType Automatic
> Start-Service AppIDSvc
> ```

**E2.** Copie `C:\Windows\System32\notepad.exe` en `C:\Temp\bloc.exe`. Teste la politique **sans l'exécuter**, pour `employe1`, sur les deux fichiers.

> [!success]- Afficher la correction — E2
> ```powershell
> Copy-Item C:\Windows\System32\notepad.exe C:\Temp\bloc.exe
> Get-AppLockerPolicy -Local -Xml | Set-Content C:\Temp\applocker.xml
> Test-AppLockerPolicy -XmlPolicy C:\Temp\applocker.xml -Path C:\Temp\bloc.exe, C:\Windows\System32\notepad.exe -User employe1
> ```
> ```
> FilePath                         PolicyDecision
> --------                         --------------
> C:\Temp\bloc.exe                DeniedByDefault
> C:\Windows\System32\notepad.exe         Allowed
> ```
> Même fichier, deux emplacements, deux décisions : les règles par défaut sont des règles de **chemin**.

**E3.** Ouvre une session `employe1` et lance `C:\Temp\bloc.exe`. Que se passe-t-il ? Quel événement est journalisé, où ?

> [!success]- Afficher la correction — E3
> ```
> Le programme « bloc.exe » n'a pas pu s'exécuter : Ce programme est bloqué par une stratégie de groupe.
> Pour plus d'informations, contactez votre administrateur système
> ```
> Journal : **Observateur d'événements → Applications et services → Microsoft → Windows → AppLocker → EXE and DLL**, ID **8004** : *« L'exécution de %OSDRIVE%\TEMP\BLOC.EXE a été empêchée. »* (8002 = autorisée, 8003 = aurait été empêchée en mode Audit).

**E4.** Conclusion : AppLocker fonctionne-t-il sur l'édition Pro ?

> [!success]- Afficher la correction — E4
> **Oui.** Testé le 08/11/2026 sur Windows 11 **Professionnel 26H2** (build 26300) : la politique est appliquée et bloque. Les nombreux articles qui affirment « Enterprise uniquement » datent d'avant Windows 10 2004. Pour un contrôle plus robuste (non contournable par un admin local), le successeur **App Control for Business** est lui aussi officiellement supporté sur Pro.

**E5.** Retire la politique pour la suite de la formation.

> [!success]- Afficher la correction — E5
> ```powershell
> '<AppLockerPolicy Version="1"><RuleCollection Type="Exe" EnforcementMode="NotConfigured" /></AppLockerPolicy>' |
>     Set-Content C:\Temp\applocker-vide.xml
> Set-AppLockerPolicy -XmlPolicy C:\Temp\applocker-vide.xml
> ```
> (Ou supprimer les règles dans `secpol.msc` et décocher « Configuré ».)

---

## Partie F — Bonus

**F1.** Chiffre avec EFS le dossier `C:\Users\admin\Documents\Confidentiel`, puis exporte le certificat EFS. Pourquoi cette exportation est-elle vitale ?

> [!success]- Afficher la correction — F1
> ```cmd
> cipher /e /s:C:\Users\admin\Documents\Confidentiel
> cipher /x C:\Sauvegarde\efs-admin
> ```
> `cipher /x` exporte le certificat **et sa clé privée** dans un `.pfx` protégé par mot de passe. Sans lui, une réinstallation ou la suppression du profil rend les fichiers **définitivement illisibles**, même pour un administrateur (sauf agent de récupération EFS configuré dans le domaine).

**F2.** Interroge l'état de VBS/Credential Guard sur `PC01`. Explique le résultat.

> [!success]- Afficher la correction — F2
> ```powershell
> Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard |
>     Select-Object VirtualizationBasedSecurityStatus, SecurityServicesConfigured, SecurityServicesRunning
> ```
> `VirtualizationBasedSecurityStatus = 0` : VBS non actif. Dans une VM Hyper-V, il faut exposer la virtualisation au processeur virtuel (**virtualisation imbriquée**, VM éteinte, depuis l'hôte) :
> ```powershell
> Set-VMProcessor -VMName PC01 -ExposeVirtualizationExtensions $true
> ```
> De plus, Credential Guard n'est activé par défaut que sur **Enterprise/Education** joints au domaine.

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/09-securite/tp)
