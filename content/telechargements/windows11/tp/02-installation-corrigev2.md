# TP 02 — Installation, mise à niveau et comptes — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h30

> Chapitres associés : [02. Installation, mise à niveau et comptes](https://kayasam.github.io/windows11/windows11/02-installation/)

---

## Objectifs

- Installer Windows 11 Pro 26H2 sur `PC01` avec un **compte local**
- Analyser le résultat : édition, partitions, chiffrement, jonction
- Vérifier la compatibilité d'un poste avant mise à niveau
- Distinguer compte local, Microsoft, professionnel et de domaine

---

## Prérequis

- VM `PC01` créée au TP 01 (Gen 2, TPM, 2 vCPU, mémoire statique, ISO 26H2 montée)
- Carte réseau connectée à `vSwitch-Rennes` (NAT fonctionnel)

---

## Partie A — Installation (40 min)

**A1.** Démarre `PC01` sur l'ISO. Choisis Français, puis **Windows 11 Professionnel**, installation **personnalisée** sur le disque vierge. Pourquoi ne crée-t-on aucune partition à la main ?

> [!success]- Afficher la correction — A1
> Sur un disque vierge, l'installeur crée seul la structure GPT/UEFI correcte : EFI, MSR, Windows et récupération. Créer une partition à la main produirait souvent une structure incomplète (pas de partition EFI → poste non démarrable, ou pas de partition de récupération → WinRE stocké sur C:).

**A2.** Pendant l'installation, explique ce que fait chacun des écrans de l'OOBE qui vont suivre.

> [!success]- Afficher la correction — A2
> | Écran | Rôle |
> |-------|------|
> | Pays ou région | Format régional, fuseau proposé |
> | Disposition de clavier | En 26H2 : **Français (Traditionnel, AZERTY)** = l'AZERTY habituel ; **Français (Standard, AZERTY)** = la nouvelle norme AFNOR |
> | Deuxième disposition | « Ignorer » |
> | Réseau | Connexion obligatoire (voir A3) |
> | Nom de l'appareil | Parfois proposé, sinon `DESKTOP-XXXXXXX` |
> | Compte | Microsoft / professionnel / local (si autorisé) |
> | Confidentialité | Localisation, diagnostics, publicité… |
>
> ![w11-02-oobe-clavier](https://kayasam.github.io/windows11/assets/captures/w11-02-oobe-clavier.png)

**A3.** À l'écran **« Il est temps de vous connecter à un réseau »**, que se passe-t-il si la VM n'a pas de réseau ? Et avec le réseau ?

> [!success]- Afficher la correction — A3
> - **Sans réseau** (testé sur 26300.9457) : l'OOBE **bloque**. Le bouton **Suivant** reste grisé, seule l'option « Installer le pilote » est proposée. Débrancher le réseau ne suffit plus à obtenir un compte local.
>
> ![w11-02-oobe-reseau-obligatoire](https://kayasam.github.io/windows11/assets/captures/w11-02-oobe-reseau-obligatoire.png)
>
> - **Avec réseau** : l'OOBE télécharge des mises à jour puis exige un compte **Microsoft** (personnel) ou **professionnel** (Entra ID).

**A4.** Le Fournil veut un **compte local** `admin` sur ce poste de lab. Obtiens-le avec `Shift+F10`. Quelle commande tapes-tu, et que fait-elle exactement ?

> [!success]- Afficher la correction — A4
> `Shift+F10` ouvre une invite de commandes **administrateur** pendant l'OOBE.
> ```cmd
> OOBE\BYPASSNRO
> ```
> Le script `C:\Windows\System32\oobe\BypassNRO.cmd` contient exactement :
> ```cmd
> @echo off
> reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
> shutdown /r /t 0
> ```
> Après le redémarrage, l'écran réseau affiche le lien **« Je n'ai pas Internet »**, qui mène directement à « Qui utilisera cet appareil ? » (compte local).
>
> ![w11-02-oobe-bypassnro-pas-internet](https://kayasam.github.io/windows11/assets/captures/w11-02-oobe-bypassnro-pas-internet.png)
>
> > [!WARNING] Clavier AZERTY dans l'invite de l'OOBE
> > À ce stade le clavier est déjà en AZERTY : le `\` s'obtient avec `AltGr + 8`.
>
> Ce script a été retiré de certaines builds Insider : s'il est absent, on tape directement la ligne `reg add` puis `shutdown /r /t 0`. Et si Microsoft supprime aussi la prise en compte de la clé, il reste le fichier de réponse (chapitre 13).

**A5.** Termine l'OOBE : nom `admin`, mot de passe `Fournil2026!`, questions de sécurité, refuse toutes les options de confidentialité facultatives.

> [!success]- Afficher la correction — A5
> ![w11-02-oobe-compte-local](https://kayasam.github.io/windows11/assets/captures/w11-02-oobe-compte-local.png)
>
> Nom `admin`, mot de passe, puis **trois questions de sécurité** (obligatoires pour un compte local créé dans l'OOBE). Dans « Choisir les paramètres de confidentialité », passer **toutes** les options à **Non** (diagnostic facultatif, localisation, publicité ciblée, reconnaissance vocale en ligne…).

**A6.** Le poste s'appelle `DESKTOP-XXXXXXX`. Renomme-le `PC01`.

> [!success]- Afficher la correction — A6
> ```powershell
> Rename-Computer -NewName PC01 -Restart
> ```
> Ou **Paramètres → Système → Informations système → Renommer ce PC**.

---

## Partie B — Analyser l'installation (20 min)

**B1.** Vérifie l'édition, la version et le build.

> [!success]- Afficher la correction — B1
> ```powershell
> Get-ComputerInfo | Select-Object OsName, OSDisplayVersion, OsBuildNumber
> ```
> ```
> OsName            : Microsoft Windows 11 Professionnel
> OSDisplayVersion  : 26H2
> OsBuildNumber     : 26300
> ```
> ![w11-02-parametres-informations-26h2](https://kayasam.github.io/windows11/assets/captures/w11-02-parametres-informations-26h2.png)

**B2.** Liste les partitions du disque. Dans quel ordre sont-elles ? Pourquoi la partition de récupération est-elle placée là ?

> [!success]- Afficher la correction — B2
> ```powershell
> Get-Partition | Select-Object PartitionNumber, Type, @{N="Mo";E={[math]::Round($_.Size/1MB)}}, DriveLetter
> ```
> ```
> PartitionNumber Type        Mo DriveLetter
> --------------- ----        -- -----------
>               1 System     200
>               2 Reserved    16
>               3 Basic    64411           C
>               4 Recovery   906
> ```
> EFI, MSR, Windows, puis **récupération en fin de disque** : placée après C:, elle peut être agrandie (en réduisant C:) quand une mise à jour de WinRE l'exige. Placée devant, c'était impossible — d'où les échecs de la mise à jour KB5034441 en 2024 sur les vieilles installations.

**B3.** Vérifie l'état de BitLocker sur `C:`. Que constates-tu, alors que tu n'as rien activé ? Est-ce que les données sont protégées ?

> [!success]- Afficher la correction — B3
> ```powershell
> Get-BitLockerVolume -MountPoint C: | Select-Object VolumeStatus, ProtectionStatus, EncryptionPercentage, KeyProtector
> ```
> Sur `PC01`, quelques minutes après l'installation :
> ```
> VolumeStatus         : EncryptionInProgress
> ProtectionStatus     : Off
> EncryptionPercentage : 92
> KeyProtector         : {}
> ```
> Depuis la 24H2, Windows active le **chiffrement automatique de l'appareil** sur les machines compatibles (TPM + Secure Boot), y compris en Pro. Le disque est chiffré… mais la protection est **Off** et il n'y a **aucun protecteur** : la clé est stockée **en clair** sur le disque, en attendant qu'un compte Microsoft/Entra ou un administrateur sauvegarde une clé de récupération.
> Conclusion : **les données ne sont pas protégées** à ce stade. On activera correctement BitLocker au TP 09.

**B4.** Vérifie l'état de WinRE.

> [!success]- Afficher la correction — B4
> ```cmd
> reagentc /info
> ```
> ```
> État WinRE :         Enabled
> Emplacement WinRE :  \\?\GLOBALROOT\device\harddisk0\partition4\Recovery\WindowsRE
> Version de Windows RE : 10.0.26100.9444
> ```
> WinRE est actif, sur la partition 4 (récupération).

**B5.** Avec `dsregcmd /status`, détermine le type de jonction du poste.

> [!success]- Afficher la correction — B5
> ```cmd
> dsregcmd /status
> ```
> ```
> AzureAdJoined : NO
> DomainJoined : NO
> WorkplaceJoined : NO
> ```
> Poste en **groupe de travail**, aucun compte professionnel enregistré.

---

## Partie C — Compatibilité et mise à niveau (20 min)

**C1.** Vérifie en PowerShell les trois prérequis clés de Windows 11 : TPM 2.0, Secure Boot, processeur.

> [!success]- Afficher la correction — C1
> ```powershell
> Get-Tpm | Select-Object TpmPresent, TpmReady, ManufacturerVersion
> Confirm-SecureBootUEFI
> (Get-CimInstance Win32_Processor).Name
> ```
> ```
> TpmPresent : True
> TpmReady   : True
> True
> 12th Gen Intel(R) Core(TM) i7-12700H
> ```
> Pour la version du TPM : `Get-CimInstance -Namespace root\cimv2\security\microsofttpm -ClassName Win32_Tpm | Select-Object SpecVersion` (doit commencer par **2.0**).

**C2.** L'ISO est montée dans `PC01`. Lance un **contrôle de compatibilité seul**, sans rien installer, avec `setup.exe`. Récupère le code de sortie. Où trouver le rapport détaillé ?

> [!success]- Afficher la correction — C2
> ```powershell
> $p = Start-Process D:\setup.exe -ArgumentList '/auto upgrade /compat scanonly /quiet /dynamicupdate disable' -Wait -PassThru
> '0x{0:X8}' -f $p.ExitCode
> ```
> | Code | Signification |
> |------|---------------|
> | `0xC1900210` | Aucun problème de compatibilité : la mise à niveau peut se faire |
> | `0xC1900208` | Application ou pilote incompatible bloquant |
> | `0xC1900200` | Matériel non conforme (TPM, processeur…) |
>
> Sur `PC01`, on obtient **`0xC190010E`** : le poste est **déjà** sur la même build que l'ISO (26300.9457), il n'y a rien à mettre à niveau. Le rapport est néanmoins produit.
>
> Rapports : `C:\$WINDOWS.~BT\Sources\Panther\`
> - `CompatData_<date>.xml` — résultat critère par critère
> - `setupact.log` / `setuperr.log` — journaux détaillés de Setup

**C3.** Interprète le rapport : quels critères sont contrôlés ? Sont-ils bloquants ?

> [!success]- Afficher la correction — C3
> Extrait du `CompatData_….xml` de `PC01` :
> ```xml
> <HardwareItem HardwareType="TpmVersion"><CompatibilityInfo BlockingType="None"/></HardwareItem>
> <HardwareItem HardwareType="UefiSecureBoot"><CompatibilityInfo BlockingType="None"/></HardwareItem>
> <HardwareItem HardwareType="CpuFms"><CompatibilityInfo BlockingType="None"/></HardwareItem>
> <HardwareItem HardwareType="CpuCores"><CompatibilityInfo BlockingType="None"/></HardwareItem>
> <HardwareItem HardwareType="Memory"><CompatibilityInfo BlockingType="None"/></HardwareItem>
> <HardwareItem HardwareType="SystemDiskSize"><CompatibilityInfo BlockingType="None"/></HardwareItem>
> ```
> Sont contrôlés : instructions processeur (SSE4.2, POPCNT…), famille/modèle du CPU (`CpuFms`), nombre de cœurs, version du TPM, UEFI + Secure Boot, mémoire, taille du disque, mode S, espace libre. **`BlockingType="None"`** partout : rien de bloquant. Un critère non respecté apparaîtrait en `BlockingType="Hard"`.

**C4.** Un poste Windows 10 22H2 du Fournil a un TPM 1.2. Que te répondra le contrôle de compatibilité ? Que proposes-tu ?

> [!success]- Afficher la correction — C4
> Le contrôle renvoie `TpmVersion` en **`BlockingType="Hard"`** (code `0xC1900200`) : mise à niveau refusée.
> Propositions :
> 1. Vérifier dans l'UEFI si le TPM peut passer en 2.0 (certains firmwares Intel PTT / AMD fTPM le permettent) ;
> 2. Sinon, **remplacer** le poste (Windows 10 n'a plus de correctifs depuis le 14/10/2025) ;
> 3. En attendant : programme ESU payant, ou Windows 365 avec le vieux poste en client léger.
>
> Contourner le contrôle (Rufus, `AllowUpgradesWithUnsupportedTPMOrCPU`) donne un poste **non supporté** : à proscrire en entreprise.

---

## Partie D — Comptes (10 min)

**D1.** Complète le tableau : où est stocké le compte, comment se connecte-t-on, à quoi sert-il ?

| Compte | Exemple | Stocké dans | Usage typique |
|--------|---------|-------------|---------------|
| Local | | | |
| Microsoft | | | |
| Professionnel | | | |
| Domaine | | | |

> [!success]- Afficher la correction — D1
> | Compte | Exemple | Stocké dans | Usage typique |
> |--------|---------|-------------|---------------|
> | Local | `PC01\admin` | Base **SAM** du poste | Lab, poste isolé, compte de secours |
> | Microsoft | `prenom@outlook.fr` | Cloud Microsoft grand public | Particulier : OneDrive perso, Store, synchronisation |
> | Professionnel | `prenom@fournil.fr` | **Microsoft Entra ID** | Entreprise M365 : Intune, Autopilot, SSO |
> | Domaine | `FOURNIL\sguillard` | **Active Directory** (contrôleurs de domaine) | Entreprise sur site : GPO, Kerberos (chap. 10) |

**D2.** Pourquoi dit-on que le fichier de réponse est la seule méthode **pérenne** pour obtenir un compte local à l'installation ?

> [!success]- Afficher la correction — D2
> Parce que c'est un mécanisme **documenté et supporté** par Microsoft depuis Windows Vista, utilisé par tous les outils de déploiement (Configuration Manager, ISO personnalisées…). `BYPASSNRO`, `ms-cxh:localonly` ou l'installation sans réseau sont des **failles de l'OOBE** que Microsoft referme au fil des builds — ce TP l'a montré : l'installation sans réseau, qui fonctionnait encore en 2025, bloque en 26H2.

---

## Partie E — Bonus

**E1.** Qu'affiche la valeur `ProductName` du registre sur ton `PC01` ? Pourquoi ne faut-il pas s'y fier ?

> [!success]- Afficher la correction — E1
> ```powershell
> (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName
> # Windows 10 Pro
> ```
> Valeur jamais mise à jour par Microsoft, par compatibilité. Tester `CurrentBuild -ge 22000`, ou utiliser `Get-ComputerInfo` (`OsName`).

**E2.** Combien de jours as-tu pour revenir en arrière après une mise à niveau ? Comment portes-tu ce délai à 30 jours ?

> [!success]- Afficher la correction — E2
> 10 jours par défaut.
> ```cmd
> DISM /Online /Get-OSUninstallWindow
> DISM /Online /Set-OSUninstallWindow /Value:30
> ```
> Uniquement juste après une **mise à niveau** (présence de `C:\Windows.old`) : sur une installation propre, il n'y a rien vers quoi revenir.

---

[Retour à l'énoncé](https://kayasam.github.io/windows11/windows11/02-installation/tp)
