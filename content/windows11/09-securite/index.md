---
title: "09 — Sécuriser un poste Windows 11"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/09-securite"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://kayasam.github.io/windows11/windows11/09-securite/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://kayasam.github.io/windows11/windows11/09-securite/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://kayasam.github.io/windows11/telechargements/windows11/cours/09-securite.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Appliquer le **moindre privilège** (comptes, groupes, élévation), configurer les protections natives de Windows 11 — UAC et *Administrator protection*, Microsoft Defender, Smart App Control, pare-feu, BitLocker, EFS —, restreindre l'exécution des applications (AppLocker / App Control for Business) et découvrir les stratégies de sécurité locales.
>
> **Outils :** Sécurité Windows, `secpol.msc`, `gpedit.msc`, `wf.msc`, `manage-bde`, `cipher.exe`
> **Commandes à connaître :** `Get-LocalGroupMember`, `Get-MpComputerStatus`, `New-NetFirewallRule`, `Add-BitLockerKeyProtector`, `Resume-BitLocker`, `Set-AppLockerPolicy`, `Test-AppLockerPolicy`

> [!INFO] Fil rouge — Fournil
> Sur `PC01` : BitLocker correctement protégé (TPM + clé de récupération), Defender vérifié, AppLocker testé — et **validé sur l'édition Pro**.

---

## Comptes, privilèges et moindre privilège

### Le principe

> Chaque compte ne dispose **que** des droits nécessaires à sa tâche, **et seulement le temps nécessaire**.

| Mauvaise pratique | Bonne pratique |
|-------------------|----------------|
| L'utilisateur est administrateur de son poste « pour installer ses logiciels » | Utilisateur **standard** ; les logiciels arrivent par WinGet/Intune/GPO |
| Un seul compte pour la messagerie et l'administration | Deux comptes : `sguillard` (usage courant) et `adm.sguillard` (administration des postes) |
| Le même mot de passe d'administrateur local sur tous les postes | **Windows LAPS** : un mot de passe unique et changeant par poste (chapitre 11) |
| Les admins du domaine ouvrent des sessions sur les postes | Modèle en *tiers* : les comptes T0 ne touchent jamais un poste de travail |

### Qui est administrateur de ce poste ?

```powershell
Get-LocalGroupMember -Group "Administrateurs"
```

Sur `PC01` après installation : `PC01\admin` (et l'`Administrateur` intégré, désactivé). Après la jonction au domaine (chapitre 10), le groupe **Admins du domaine** y est ajouté automatiquement.

### Droits utilisateur

Au-delà des groupes, Windows attribue des **droits** (*user rights*) : ouvrir une session localement, via le Bureau à distance, en tant que tâche, arrêter le système, déboguer des programmes… Ils se consultent dans `secpol.msc` → **Stratégies locales → Attribution des droits utilisateur**.

```cmd
:: Exporter les droits pour les lire en texte
secedit /export /cfg C:\Temp\droits.inf /areas USER_RIGHTS
```

> [!NOTE] Vécu sur un lab : quand les droits bloquent même l'administrateur du domaine
> Une GPO de *tiering* qui place « Admins du domaine » dans **Interdire l'ouverture de session locale** sur les postes empêche… l'administrateur du domaine de s'y connecter, y compris par PowerShell Direct (« *Les informations d'identification ne sont pas valides* »). C'est voulu (protection des comptes T0), mais à connaître avant de chercher une panne.

### UAC… et Administrator protection

L'**UAC** (ci-dessous) donne à un administrateur deux jetons et ne sert le jeton complet qu'après confirmation. Sa limite : le jeton administrateur appartient au **même** compte, ce qu'exploitent de nombreux contournements d'UAC.

**Administrator protection** (Windows 11 24H2+, activée par défaut dans les *security baselines* depuis octobre 2026) change le modèle :

| | UAC classique (*Admin Approval Mode*) | Administrator protection |
|-|---------------------------------------|---------------------------|
| Jeton administrateur | Celui du compte, « débloqué » | Celui d'un **compte fantôme** système, distinct, créé à la volée |
| Confirmation | Clic « Oui » | **Windows Hello** (code PIN, biométrie) ou mot de passe |
| Durée | Tant que le processus vit | **Juste à temps** : détruit à la fin de l'opération |
| Profil | Le même | Séparé (pas d'accès aux fichiers du profil courant) |

Activation : **Sécurité Windows → Protection du compte → Administrator protection** (selon les builds), ou stratégie *Contrôle de compte d'utilisateur : configurer le type de mode d'approbation administrateur* (`secpol.msc`) → **Mode d'approbation administrateur avec protection administrateur**. Valeur de registre : `TypeOfAdminApprovalMode` = `2` (`1` = UAC classique, valeur relevée sur `PC01`).

---
## Contrôle du compte utilisateur (UAC)
![w11-07-securite](https://kayasam.github.io/windows11/assets/captures/w11-07-securite.png)

Le **UAC** (User Account Control) empêche une application de s'exécuter avec des privilèges administrateur sans confirmation explicite de l'utilisateur. Il protège contre l'exécution silencieuse de code malveillant ou de modifications système non désirées.

### Principe : le jeton à deux niveaux

Un compte administrateur reçoit **deux jetons d'accès** à l'ouverture de session :

```
Ouverture de session (compte administrateur)
      │
      ▼
 Jeton standard          Jeton administrateur complet
 (utilisé par défaut)    (activé uniquement sur demande)
      │                         │
      ▼                         ▼
 Explorer.exe, apps        Invite élevée, action nécessitant
 courantes                 des privilèges admin (UAC prompt)
```

Le **bureau sécurisé** (secure desktop) assombrit l'écran lors de l'invite UAC : seule l'invite UAC elle-même peut y répondre, ce qui empêche un malware de simuler un clic automatique.

### Niveaux de notification UAC

**Accès :** Panneau de configuration → Comptes d'utilisateurs → Modifier les paramètres de contrôle de compte d'utilisateur
![w11-07-securite-1](https://kayasam.github.io/windows11/assets/captures/w11-07-securite-1.png)

| Niveau | Comportement |
|--------|--------------|
| **Toujours m'avertir** | Notification + bureau sécurisé pour toute action admin ou modification de paramètres Windows |
| **M'avertir uniquement si des applications tentent des modifications (par défaut)** | Notification + bureau sécurisé, mais pas pour les modifications faites depuis les Paramètres Windows eux-mêmes |
| **M'avertir uniquement si des applications tentent des modifications (sans bureau sécurisé)** | Comme ci-dessus, sans assombrir l'écran — moins sûr |
| **Ne jamais m'avertir** | UAC désactivé — toute application s'exécute avec les privilèges du compte sans confirmation |

> [!WARNING] Ne jamais désactiver complètement l'UAC
> Le niveau "Ne jamais m'avertir" désactive aussi le bureau sécurisé et affaiblit fortement la posture de sécurité du poste. À proscrire hors environnement de test isolé.

### Gestion en PowerShell / registre

```powershell
# Lire le niveau UAC actuel (clé de registre)
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" |
    Select-Object EnableLUA, ConsentPromptBehaviorAdmin, PromptOnSecureDesktop

# Désactiver le bureau sécurisé (déconseillé en production)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name PromptOnSecureDesktop -Value 0
```

---

## Microsoft Defender Antivirus (Sécurité Windows)

**Microsoft Defender Antivirus** est la solution antimalware native de Windows 11, activée par défaut tant qu'aucun antivirus tiers n'est installé. État relevé sur `PC01` : protection en temps réel **active**, **protection contre les falsifications** (*Tamper Protection*) **active** — ce qui empêche un script, même administrateur, de désactiver Defender par le registre ou `Set-MpPreference`.

> [!NOTE] Defender Antivirus ≠ Defender for Endpoint
> **Defender Antivirus** est l'antivirus gratuit intégré. **Microsoft Defender for Endpoint** (licence M365 E5 ou Business Premium) est l'**EDR** : il collecte la télémétrie du poste, détecte les comportements suspects, permet d'isoler un poste à distance depuis une console cloud.

![w11-07-securite-2](https://kayasam.github.io/windows11/assets/captures/w11-07-securite-2.png)

### Types de protection

| Protection | Rôle |
|------------|------|
| **Protection en temps réel** | Analyse les fichiers à l'accès (ouverture, exécution, téléchargement) |
| **Protection fournie par le cloud** | Envoie des échantillons suspects aux serveurs Microsoft pour analyse rapide |
| **Protection contre les rançongiciels (accès contrôlé aux dossiers)** | Bloque les applications non autorisées à modifier des dossiers protégés (Documents, Images…) |
| **Protection réseau** | Bloque les connexions vers des sites malveillants ou hameçonnage |

### Types d'analyse

| Analyse | Description |
|---------|--------------|
| **Rapide** | Vérifie les emplacements les plus susceptibles d'héberger un malware (mémoire, démarrage) |
| **Complète** | Analyse tous les fichiers et programmes présents sur le disque |
| **Personnalisée** | Analyse un dossier ou lecteur spécifique |
| **Hors ligne** | Redémarre dans un environnement minimal avant Windows pour détecter les rootkits |

### Exclusions

Une exclusion empêche Defender d'analyser un fichier, dossier, type de fichier ou processus donné. Utile pour éviter les faux positifs sur des outils de développement ou d'administration, mais **chaque exclusion est un angle mort** pour l'antivirus.

**Interface graphique :** Sécurité Windows → Protection contre les virus et menaces → Gérer les paramètres → Ajouter ou supprimer des exclusions

```powershell
# Lister les exclusions actuelles
Get-MpPreference | Select-Object ExclusionPath, ExclusionExtension, ExclusionProcess

# Ajouter une exclusion de dossier
Add-MpPreference -ExclusionPath "C:\Dev\Projets"

# Ajouter une exclusion de processus
Add-MpPreference -ExclusionProcess "vagrant.exe"

# Supprimer une exclusion
Remove-MpPreference -ExclusionPath "C:\Dev\Projets"
```

> [!WARNING] Exclusions = risque
> Un dossier exclu n'est plus scanné : un malware qui s'y installe (ex : un dossier de téléchargement mal choisi) passera inaperçu. Limiter les exclusions au strict nécessaire et les documenter.

### Commandes PowerShell essentielles

```powershell
# État général de Defender
Get-MpComputerStatus

# Forcer une mise à jour des définitions
Update-MpSignature

# Lancer une analyse rapide
Start-MpScan -ScanType QuickScan

# Lancer une analyse complète
Start-MpScan -ScanType FullScan

# Désactiver temporairement la protection en temps réel (test uniquement)
Set-MpPreference -DisableRealtimeMonitoring $true
```

---

## Pare-feu Windows Defender

Le pare-feu filtre le trafic réseau entrant et sortant selon des **règles** appliquées par **profil réseau**.

### Profils réseau

| | Domaine | Privé | Public |
|-|---------|-------|--------|
| **Contexte** | Poste joint à un AD, contrôleur de domaine détecté sur le réseau | Réseau domestique ou de confiance, déclaré manuellement | Réseau non fiable (Wi-Fi café, aéroport, hotspot…) |
| **Attribution** | Automatique — Windows détecte le domaine, aucun choix possible | Manuel — l'utilisateur (ou un admin) choisit ce profil | Par défaut sur tout nouveau réseau tant qu'il n'est pas reclassé |
| **Niveau de confiance** | Élevé | Moyen | Faible |
| **Découverte réseau** | Activée | Activée | Désactivée |
| **Partage de fichiers/imprimantes** | Autorisé selon règles | Autorisé selon règles | Bloqué par défaut |
| **Règles entrantes par défaut** | Les plus permissives (services d'administration à distance, etc.) | Intermédiaires | Les plus restrictives — seul le strict minimum est ouvert |

> [!NOTE] Un profil ne s'applique pas au PC mais à la carte réseau
> Le profil réseau (Domaine/Privé/Public) est associé à **chaque connexion réseau** (carte Ethernet, Wi-Fi, adaptateur virtuel), pas à l'ordinateur dans son ensemble. Un poste avec deux cartes actives peut donc appliquer deux profils différents simultanément — le pare-feu applique alors les règles de chaque profil sur l'interface correspondante.

### Changer de profil réseau

Le changement de profil se fait via **Paramètres → Réseau et Internet**, sur la connexion concernée — pas via le pare-feu lui-même.

**Interface graphique (Windows 11) :**
Paramètres → Réseau et Internet → sélectionner la connexion (Wi-Fi ou Ethernet) → **Propriétés** → section "Profil réseau" → choisir **Public** ou **Privé**.
![w11-07-securite-3](https://kayasam.github.io/windows11/assets/captures/w11-07-securite-3.png)

> [!NOTE] Le profil Domaine n'est jamais choisi manuellement
> Le profil **Domaine** est attribué automatiquement par Windows lorsque le poste est joint à un AD et qu'un contrôleur de domaine est joignable sur le réseau. Il n'apparaît pas comme option sélectionnable dans Paramètres — seuls Public et Privé le sont.

**En PowerShell (par interface réseau) :**

```powershell
# Voir le profil actuellement appliqué à chaque interface
Get-NetConnectionProfile

# Changer le profil d'une interface précise (identifiée par son alias ou son index)
Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private
Set-NetConnectionProfile -InterfaceAlias "Wi-Fi" -NetworkCategory Public
```

> [!WARNING] NetworkCategory ne connaît que Public et Private
> Le paramètre `-NetworkCategory` de `Set-NetConnectionProfile` n'accepte que `Public` ou `Private` : impossible de forcer manuellement `DomainAuthenticated`, ce profil restant sous le contrôle exclusif de la détection automatique du domaine.

### Console graphique : wf.msc

![w11-07-securite-4](https://kayasam.github.io/windows11/assets/captures/w11-07-securite-4.png)

**Accès :** `Win + R` → `wf.msc` (Pare-feu Windows Defender avec fonctions avancées de sécurité)

> [!WARNING] wf.msc n'indique pas clairement le profil actif
> La section "Vue d'ensemble" de `wf.msc` liste **toujours les trois profils** (Domaine, Privé, Public) avec l'état de leur pare-feu respectif (activé/désactivé) — mais elle n'identifie pas de façon évidente lequel est réellement appliqué à la connexion en cours. Pour connaître à coup sûr le profil actif, préférer `Get-NetConnectionProfile` en PowerShell ou Paramètres → Réseau et Internet → Propriétés de la connexion, qui l'affichent sans ambiguïté.

- **Règles de trafic entrant** : contrôlent les connexions initiées depuis l'extérieur vers le poste (ex : autoriser RDP)
- **Règles de trafic sortant** : contrôlent les connexions initiées depuis le poste vers l'extérieur (souvent tout autorisé par défaut)
- Une règle se définit par : programme, port, protocole, portée (IP source/destination), profil, action (autoriser/bloquer)

### Gestion en PowerShell

```powershell
# Lister les règles actives
Get-NetFirewallRule | Where-Object Enabled -eq True | Select-Object DisplayName, Direction, Action

# Autoriser le Bureau à distance (RDP) sur le profil privé
New-NetFirewallRule -DisplayName "Autoriser RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow -Profile Private

# Bloquer un programme spécifique
New-NetFirewallRule -DisplayName "Bloquer app" -Direction Outbound -Program "C:\Apps\suspect.exe" -Action Block

# Voir l'état du pare-feu par profil
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction

# Activer/désactiver le pare-feu sur un profil
Set-NetFirewallProfile -Profile Public -Enabled True
```

### Gestion en ligne de commande (netsh)

```cmd
:: Afficher l'état du pare-feu
netsh advfirewall show allprofiles

:: Autoriser un port entrant
netsh advfirewall firewall add rule name="Autoriser 8080" dir=in action=allow protocol=TCP localport=8080

:: Désactiver le pare-feu sur un profil (déconseillé)
netsh advfirewall set publicprofile state off
```

> [!TIP] netsh vs PowerShell
> `netsh advfirewall` reste largement utilisé en scripts hérités, mais les cmdlets `*-NetFirewall*` sont la méthode recommandée : sortie objet, plus lisible, plus facile à filtrer.

---

## BitLocker — Chiffrement de volume

<iframe width="560" height="315" src="https://www.youtube.com/embed/JZ40VNsv8Lg?si=9TlAZ5N4qdFphTwH" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

**BitLocker** chiffre l'intégralité d'un volume (système ou données) pour protéger les données en cas de vol ou de perte physique du disque.

### Prérequis

- **TPM 2.0** (Trusted Platform Module) — puce qui stocke la clé de chiffrement de façon sécurisée, liée au matériel
- Sans TPM : possible en mode dégradé avec une clé USB de démarrage (`Autoriser BitLocker sans TPM compatible` via GPO)
- Édition **Pro, Enterprise ou Education** (non disponible en Home)

### Fonctionnement

```
Volume système (C:)
      │
      ▼
 Clé de chiffrement de volume (FVEK)
 chiffrée par la clé maître (VMK)
      │
      ▼
 VMK scellée dans le TPM
 (liée à l'état de démarrage : BCD, BIOS/UEFI, Secure Boot)
      │
      ▼
 Si l'état de démarrage change (BIOS modifié, disque déplacé...)
 → TPM refuse de libérer la clé → demande de la clé de récupération
```

### Depuis 24H2 : le chiffrement automatique de l'appareil

Sur un PC compatible (TPM 2.0 + Secure Boot), **Windows 11 24H2+ chiffre le disque système tout seul** dès l'installation, y compris en édition Pro. Relevé sur `PC01` quelques minutes après l'installation, sans aucune action :

```
VolumeStatus     : FullyEncrypted
ProtectionStatus : Off
KeyProtector     : {}          ← aucun protecteur !
```

« Chiffré » mais **pas protégé** : tant qu'aucun protecteur n'est ajouté, la clé est stockée **en clair** sur le disque. Windows l'« active » quand un compte Microsoft ou Entra ID peut recevoir la clé de récupération ; avec un compte local ou de domaine, il reste dans cet état intermédiaire. À l'administrateur de finir le travail :

```powershell
Add-BitLockerKeyProtector -MountPoint C: -RecoveryPasswordProtector   # 1. la clé de récupération (à sauvegarder !)
Add-BitLockerKeyProtector -MountPoint C: -TpmProtector                # 2. le TPM
Resume-BitLocker -MountPoint C:                                       # 3. activer la protection
Get-BitLockerVolume C: | Select-Object VolumeStatus, ProtectionStatus, KeyProtector
# FullyEncrypted / On / {RecoveryPassword, Tpm}   ← constaté sur PC01
```

> [!WARNING] Deux pièges rencontrés sur le lab
> - **`0x80310030`** — *« BitLocker a détecté la présence d'un média de démarrage amovible (CD ou DVD) »* : le protecteur TPM est refusé tant qu'une ISO est montée dans la VM (ou une clé USB de démarrage branchée). Éjecter, puis recommencer.
> - Sur une **machine de référence** (master) : ce chiffrement automatique fait échouer Sysprep (`0x80310039`). Il faut l'**empêcher dès l'installation** (`PreventDeviceEncryption`, chapitre 13).

Empêcher le chiffrement automatique (master, ou parc où BitLocker est géré par GPO) :

```cmd
reg add HKLM\SYSTEM\CurrentControlSet\Control\BitLocker /v PreventDeviceEncryption /t REG_DWORD /d 1 /f
```

### Activation manuelle

**Interface graphique :** Panneau de configuration\Système et sécurité\Chiffrement de lecteur BitLocker

![w11-07-securite-5](https://kayasam.github.io/windows11/assets/captures/w11-07-securite-5.png)

L'assistant graphique force un déroulé dans le bon ordre et ne laisse pas passer d'étape :

1. **Comment sauvegarder la clé de récupération** — choix obligatoire avant toute chose : compte Microsoft, fichier, ou **imprimer la clé**. Impossible de continuer sans valider une de ces options.
2. **Étendue du chiffrement** — uniquement l'espace utilisé (plus rapide, recommandé pour un poste neuf) ou le disque entier
3. **Mode de chiffrement** — nouveau mode (disque fixe) ou compatible (disque amovible)
4. **Lancer le chiffrement** → redémarrage éventuel puis progression visible dans le Panneau de configuration

> [!TIP] En pratique, privilégier la GUI
> L'assistant graphique gère automatiquement l'ordre correct des opérations (protecteur de récupération créé **avant** le démarrage du chiffrement) et affiche une progression claire. C'est la méthode la plus fiable pour une première activation, y compris en formation.

```powershell
# Ajouter D'ABORD un protecteur de récupération — sinon le volume système
# reste bloqué en "Waiting For Activation" sans jamais chiffrer réellement
Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryPasswordProtector

# Puis activer BitLocker avec le protecteur TPM
Enable-BitLocker -MountPoint "C:" -TpmProtector -UsedSpaceOnly

# Voir l'état du chiffrement
Get-BitLockerVolume -MountPoint "C:"

# Si le statut reste "Waiting For Activation" malgré tout, forcer la reprise
Resume-BitLocker -MountPoint "C:"

# Consulter la clé de récupération générée
(Get-BitLockerVolume -MountPoint "C:").KeyProtector
```

> [!WARNING] Piège fréquent avec `Enable-BitLocker` seul
> Lancer `Enable-BitLocker -TpmProtector` **sans** avoir ajouté au préalable un `RecoveryPasswordProtector` peut laisser le volume système en statut **"Waiting For Activation"** : le protecteur est créé mais le chiffrement ne démarre jamais réellement, même après redémarrage. C'est ce qui explique qu'une activation "en pur PowerShell" peut sembler ne rien faire alors que l'assistant graphique, lui, fonctionne du premier coup — il impose de sauvegarder la clé de récupération (y compris par impression) avant de lancer quoi que ce soit.

### Clé de récupération

La **clé de récupération** (48 chiffres) permet de déverrouiller le volume si le TPM refuse de libérer la clé automatiquement (changement matériel, mise à jour firmware, oubli du mot de passe). Elle doit être **sauvegardée** :

- Dans **Active Directory** (poste joint au domaine) — automatiquement par GPO, chapitre 11
- Dans **Microsoft Entra ID / Intune** (poste joint à Entra)
- Dans un compte Microsoft (particulier)
- Imprimée, ou fichier `.txt` sur un support **séparé** du poste

```powershell
# Sauvegarder a posteriori la clé d'un poste joint au domaine
$kp = (Get-BitLockerVolume C:).KeyProtector | Where-Object KeyProtectorType -eq RecoveryPassword
Backup-BitLockerKeyProtector -MountPoint C: -KeyProtectorId $kp.KeyProtectorId
```

### BitLocker To Go (supports amovibles)

Clic droit sur une clé USB → **Activer BitLocker** → déverrouillage par **mot de passe** (pas de TPM sur une clé). Le mode de chiffrement « **compatible** » (AES-CBC) permet de lire la clé sur d'anciennes versions de Windows. En GPO : *Composants Windows → Chiffrement de lecteur BitLocker → Lecteurs de données amovibles → Refuser l'accès en écriture aux lecteurs amovibles non protégés par BitLocker*.

```powershell
Enable-BitLocker -MountPoint E: -PasswordProtector -Password (Read-Host -AsSecureString "Mot de passe") -UsedSpaceOnly
Add-BitLockerKeyProtector -MountPoint E: -RecoveryPasswordProtector
```

> [!WARNING] Sans clé de récupération sauvegardée = données perdues
> Si le TPM refuse de libérer la clé et qu'aucune clé de récupération n'a été sauvegardée, les données du volume sont **définitivement inaccessibles**.

```cmd
:: Suspendre BitLocker (ex : avant une mise à jour BIOS) sans déchiffrer
manage-bde -protectors -disable C: -RebootCount 1

:: Déverrouiller un volume avec la clé de récupération
manage-bde -unlock D: -RecoveryPassword <clé-48-chiffres>

:: Désactiver BitLocker et déchiffrer le volume
manage-bde -off C:
```

---

## EFS — Encrypting File System

**EFS** chiffre des **fichiers ou dossiers individuels**, contrairement à BitLocker qui chiffre le volume entier. Basé sur un certificat lié au profil utilisateur Windows.

> [!NOTE] Une technologie ancienne, toujours là
> EFS date de Windows 2000. Il fonctionne toujours en 26H2 et reste au programme, mais il est peu utilisé : gestion des certificats délicate, pas de protection contre un administrateur qui a les clés de récupération. Microsoft pousse aujourd'hui **Personal Data Encryption** (PDE, Enterprise, déverrouillage par Windows Hello) pour les dossiers connus, et **Purview/étiquettes de sensibilité** pour les documents.

| | BitLocker | EFS |
|-|-----------|-----|
| **Granularité** | Volume entier | Fichier / dossier |
| **Protège contre** | Vol du disque/PC (poste éteint) | Autre utilisateur du même poste (poste allumé) |
| **Clé** | TPM + clé de récupération | Certificat utilisateur (profil Windows) |
| **Édition** | Pro/Enterprise/Education | Pro/Enterprise/Education |
| **Accessible si l'OS est corrompu** | Non (nécessite déverrouillage) | Le fichier reste chiffré même copié ailleurs |

### Utilisation

**Interface graphique :** Clic droit sur un fichier/dossier → Propriétés → Avancé → Chiffrer le contenu pour sécuriser les données

![w11-07-securite-7](https://kayasam.github.io/windows11/assets/captures/w11-07-securite-7.png)

> [!NOTE] Pas de module PowerShell dédié pour EFS
> Contrairement à Defender (`*-Mp*`), au pare-feu (`*-NetFirewall*`) ou à BitLocker (`*-BitLocker*`), il n'existe **aucune cmdlet native pour EFS**. `cipher.exe` est le seul outil en ligne de commande — c'est un exécutable autonome, donc les commandes ci-dessous fonctionnent à l'identique en invite de commandes **et** en PowerShell.

```cmd
:: Chiffrer un dossier et son contenu
cipher /e /s:C:\Users\Sam\Documents\Confidentiel

:: Déchiffrer
cipher /d /s:C:\Users\Sam\Documents\Confidentiel

:: Afficher l'état de chiffrement des fichiers d'un dossier
cipher /c C:\Users\Sam\Documents\Confidentiel

:: Sauvegarder le certificat EFS (clé privée) — indispensable avant réinstallation
cipher /x C:\Backup\efs-cert.pfx
```

**Alternative 100% PowerShell (sans passer par `cipher.exe`) :** les méthodes `.NET` `File.Encrypt()` / `File.Decrypt()` pilotent directement l'API EFS de Windows.

```powershell
# Chiffrer un fichier
[System.IO.File]::Encrypt("C:\Users\Sam\Documents\Confidentiel\notes.txt")

# Déchiffrer un fichier
[System.IO.File]::Decrypt("C:\Users\Sam\Documents\Confidentiel\notes.txt")

# Vérifier l'attribut de chiffrement sur les fichiers d'un dossier
Get-ChildItem "C:\Users\Sam\Documents\Confidentiel" | Select-Object Name, Attributes
```

> [!TIP] `cipher.exe` reste préférable pour un dossier entier
> `[System.IO.File]::Encrypt()` s'applique fichier par fichier — pas de option récursive native. Pour chiffrer un dossier avec tout son contenu (et les nouveaux fichiers qui y seront créés), `cipher /e /s:` reste la commande la plus simple, en CMD comme en PowerShell.

> [!WARNING] Sauvegarder le certificat EFS
> Le déchiffrement repose sur le certificat du profil utilisateur. En cas de réinstallation de Windows ou de suppression du profil **sans avoir exporté le certificat**, les fichiers chiffrés deviennent **définitivement illisibles**, même par un administrateur.

---

## Restreindre les applications : AppLocker et App Control for Business

### AppLocker

**AppLocker** restreint l'exécution des applications à une liste autorisée (*allowlisting*), par utilisateur ou groupe.

| Type de règle | Contrôle |
|---------------|----------|
| **Exécutable** | `.exe`, `.com` |
| **Windows Installer** | `.msi`, `.msp` |
| **Script** | `.ps1`, `.bat`, `.cmd`, `.vbs`, `.js` |
| **Application empaquetée** | MSIX / Store |
| **DLL** (optionnel, coûteux) | `.dll` |

| Condition | Principe | Robustesse |
|-----------|----------|------------|
| **Éditeur** | Signature numérique | Élevée — survit aux mises à jour |
| **Chemin** | Emplacement du fichier | Faible si le dossier est inscriptible par l'utilisateur |
| **Hash** | Empreinte du fichier exact | Élevée mais rigide |

**Chemin GPMC / gpedit.msc / secpol.msc :** `Configuration ordinateur → Paramètres Windows → Paramètres de sécurité → Stratégies de contrôle d'application → AppLocker`

![w11-08-mises-a-jour-restrictions-2](https://kayasam.github.io/windows11/assets/captures/w11-08-mises-a-jour-restrictions-2.png)

> [!TIP] Toujours commencer en mode Audit
> Le mode **Audit uniquement** journalise sans bloquer (journal *Applications et services → Microsoft → Windows → AppLocker*, événement **8003** « aurait été empêché »). On passe en **Appliquer** une fois la liste validée.

> [!NOTE] Règles par défaut indispensables
> Les 3 règles par défaut — tout le monde peut exécuter depuis `%PROGRAMFILES%` et `%WINDIR%`, les Administrateurs partout — évitent de bloquer Windows lui-même. Clic droit sur **Règles de l'exécutable → Créer des règles par défaut**.

> [!WARNING] Le service « Identité de l'application » (`AppIDSvc`)
> AppLocker s'appuie sur `AppIDSvc`. Par défaut en démarrage manuel déclenché, on le passe en **Automatique** sur les postes où AppLocker est appliqué (`Set-Service AppIDSvc -StartupType Automatic`).

```powershell
# Générer des règles Éditeur à partir des exécutables d'un dossier
Get-AppLockerFileInformation -Directory "C:\Program Files\7-Zip" -Recurse -FileType Exe |
    New-AppLockerPolicy -RuleType Publisher -User Everyone -Xml | Out-File C:\Temp\7zip.xml

# Politique effective du poste
Get-AppLockerPolicy -Effective -Xml

# Tester sans appliquer
Test-AppLockerPolicy -XmlPolicy C:\Temp\applocker.xml -Path C:\Temp\bloc.exe -User employe1

# Appliquer une politique locale
Set-AppLockerPolicy -XmlPolicy C:\Temp\applocker.xml
```

### AppLocker fonctionne-t-il sur Windows 11 Pro ? — testé sur le lab

La documentation de Microsoft reste ambiguë et beaucoup de sites affirment encore « Enterprise uniquement ». Test sur `PC01` (Pro 26H2) : règles par défaut en mode **Appliquer**, copie de `notepad.exe` en `C:\Temp\bloc.exe`, exécution par l'utilisateur standard `employe1` :

```
PS> Test-AppLockerPolicy ... -User employe1
C:\Temp\bloc.exe                 DeniedByDefault
C:\Windows\System32\notepad.exe  Allowed

PS (employe1)> C:\Temp\bloc.exe
Le programme « bloc.exe » n'a pas pu s'exécuter : Ce programme est bloqué par une stratégie de groupe.

Journal AppLocker/EXE and DLL — ID 8004 : L'exécution de %OSDRIVE%\TEMP\BLOC.EXE a été empêchée.
```

**AppLocker est bien appliqué sur Windows 11 Pro.**

### App Control for Business (ex-WDAC / Device Guard)

Successeur plus strict d'AppLocker, **renommé** *App Control for Business* (anciennement *Windows Defender Application Control*, et avant *Device Guard*). La politique est appliquée **par le noyau**, dès le démarrage, et peut être rendue non modifiable même par un administrateur. Officiellement supportée sur **Pro**.

| | AppLocker | App Control for Business |
|-|-----------|--------------------------|
| Niveau | Mode utilisateur (service AppIDSvc) | Noyau (intégrité du code) |
| Contournable par un admin local | Oui | Non (politique signée) |
| Par utilisateur/groupe | Oui | Non — tout le poste |
| Outils | GPO, `*-AppLockerPolicy` | *App Control Policy Wizard*, `New-CIPolicy`, Intune |
| Complexité | Modérée | Élevée |

### Smart App Control

Sur les installations **neuves** de Windows 11, **Smart App Control** (Sécurité Windows → Contrôle des applications et du navigateur) bloque les applications non signées ou de mauvaise réputation, en s'appuyant sur le cloud de Microsoft. Il démarre en mode **Évaluation** puis s'active ou se désactive seul selon l'usage du poste. Sur `PC01` : `VerifiedAndReputablePolicyState = 2` (évaluation). Depuis 26H2, on peut l'activer ou le désactiver **sans réinstaller** Windows. Pensé pour les particuliers et les PME sans gestion centralisée : en entreprise, on lui préfère App Control géré.

---

## Sécurité basée sur la virtualisation : Credential Guard et intégrité de la mémoire

Ces protections reposent sur **VBS** : une partie du système s'exécute dans un conteneur isolé par l'hyperviseur (VTL1), inaccessible même à un noyau Windows compromis.

```
Windows 11 (VBS activé)
      ├── Noyau Windows normal (VTL0) — peut être compromis par un pilote malveillant
      └── Conteneur sécurisé (VTL1)
            ├── Credential Guard → isole les secrets de LSASS (hash NTLM, tickets Kerberos)
            └── Intégrité de la mémoire (HVCI) → seul du code noyau signé et vérifié s'exécute
```

- **Credential Guard** bloque le vol d'identifiants en mémoire (*Pass-the-Hash*, *Pass-the-Ticket*, mimikatz). Il est **activé par défaut** depuis 22H2 sur les postes **Enterprise/Education joints à un domaine** qui ont le matériel compatible.
- **Intégrité de la mémoire** : Sécurité Windows → Sécurité de l'appareil → Isolation du noyau. Activée par défaut sur les PC neufs compatibles.

```powershell
Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard |
    Select-Object VirtualizationBasedSecurityStatus, SecurityServicesConfigured, SecurityServicesRunning
# VBSStatus 2 = actif ; SecurityServicesRunning 1 = Credential Guard, 2 = HVCI
```

> [!WARNING] VBS dans une VM Hyper-V
> Sur `PC01`, `VirtualizationBasedSecurityStatus = 0` : la VM n'expose pas la virtualisation. Il faudrait activer la **virtualisation imbriquée** depuis l'hôte (`Set-VMProcessor PC01 -ExposeVirtualizationExtensions $true`, VM éteinte). À traiter comme une démonstration.

---

## Stratégies de sécurité locales et baselines

Tout ce qui précède se règle poste par poste dans `secpol.msc` (stratégie de sécurité locale) et `gpedit.msc` (stratégie de groupe locale). En entreprise, on ne règle **jamais** poste par poste : on déploie des **GPO** depuis le domaine (chapitre 11).

| Outil | Rôle |
|-------|------|
| `secpol.msc` | Stratégies de compte (mots de passe, verrouillage), stratégies locales (droits, options de sécurité, audit), pare-feu, AppLocker |
| `gpedit.msc` | Tout `secpol` + les **modèles d'administration** (des milliers de réglages Windows, Edge, Office…) |
| `gpresult /h rapport.html` | Ce qui est réellement appliqué, et par quelle stratégie |
| **Security baselines** Microsoft | Jeux de GPO recommandés par Microsoft pour chaque version (téléchargés avec le *Security Compliance Toolkit*), importables dans un domaine ; applicables en local avec `LGPO.exe` |

> [!TIP] La stratégie de mot de passe locale
> `secpol.msc` → **Stratégies de comptes → Stratégie de mot de passe** : longueur minimale, complexité, durée de vie. Sur un poste **joint au domaine**, c'est la *Default Domain Policy* qui s'applique aux comptes du domaine — et sur le lab, elle a aussi refusé la création d'un compte **local** au mot de passe trop simple (`InvalidPasswordException`).

---

## Récapitulatif

```
Moindre privilège
  Utilisateur standard + compte d'admin séparé (adm.xxx) | LAPS pour l'admin local (chap. 11)
  Get-LocalGroupMember Administrateurs | secpol.msc → Attribution des droits utilisateur

UAC — Contrôle du compte utilisateur
  Jeton standard vs jeton admin | bureau sécurisé | 4 niveaux de notification
  Administrator protection : compte fantôme juste-à-temps + Windows Hello (TypeOfAdminApprovalMode=2)

Microsoft Defender Antivirus
  Protection temps réel, cloud, accès contrôlé aux dossiers, protection contre les falsifications
  Get-MpComputerStatus | Start-MpScan | Add-MpPreference -ExclusionPath

Pare-feu Windows Defender
  Profils : Domaine > Privé > Public (confiance décroissante)
  Profil = par carte réseau, pas par PC | changement : Réseau et Internet > Propriétés
  wf.msc (GUI) | New-NetFirewallRule (PowerShell) | netsh advfirewall (CLI)

BitLocker — chiffrement de volume
  24H2+ : chiffrement AUTOMATIQUE mais Protection Off, sans protecteur → à finaliser :
    Add-BitLockerKeyProtector -RecoveryPasswordProtector → -TpmProtector → Resume-BitLocker
  ISO/clé de démarrage présente → 0x80310030 | master → PreventDeviceEncryption (sinon Sysprep KO)
  Clé de récupération → AD / Entra (Backup-BitLockerKeyProtector) | BitLocker To Go (mot de passe)

EFS — chiffrement de fichiers (ancien, toujours présent)
  Certificat utilisateur | cipher /e | /d | /x (sauvegarde certificat)

Restreindre les applications
  AppLocker : règles Exe/MSI/Script/Appx, Éditeur > Hash > Chemin, Audit puis Appliquer, AppIDSvc
              TESTÉ : appliqué sur Windows 11 Pro 26H2 (événement 8004)
  App Control for Business (ex-WDAC) : noyau, non contournable | Smart App Control : PC neufs, cloud

VBS : Credential Guard (défaut sur Enterprise joint au domaine) | intégrité mémoire (HVCI)
Baselines : secpol.msc / gpedit.msc en local → GPO de domaine (chap. 11) | gpresult /h
```
