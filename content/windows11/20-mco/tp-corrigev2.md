---
title: "TP 20. TP final : maintien en condition opérationnelle — Correction"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/20-mco"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/20-mco/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/20-mco/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/20-mco-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/20-mco/tp">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/20-mco/tp-corrigev2" aria-current="page">Corrigé</a></nav>

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 3h

> Chapitres associés : [20. Maintien en condition opérationnelle](https://cours.kaya.ovh/windows11/windows11/20-mco/) — et tout le reste de la formation

---

## Contexte

Tu reprends la gestion du parc informatique de la boulangerie **Fournil**. Ton prédécesseur est parti sans laisser de documentation. Ta mission : faire l'état des lieux, remettre les postes en conformité, mettre en place une maintenance préventive et prouver que tu sais intervenir vite sur un incident.

Livrable : un dossier `C:\MCO` sur `PC01` contenant l'inventaire, les journaux et le **plan de MCO**.

---

## Prérequis

- `SRV01`, `PC01`, `PC02` démarrés, `PC01` et `PC02` joints au domaine
- WinRM actif sur `PC02` (TP 12)
- Scripts `Get-Inventaire.ps1`, `Test-Poste.ps1`, `Casse-Poste.ps1` (dossier `Ressources/scripts`) copiés sur `PC01` dans `C:\MCO`
- Points de contrôle Hyper-V de `PC01` et `PC02` : `Checkpoint-VM -Name PC01,PC02 -SnapshotName "Avant-TP20"`

---

## Partie A — État des lieux (30 min)

**A1.** Depuis `PC01`, lance l'inventaire de `PC01` et `PC02` avec export dans `C:\MCO\inventaire.csv`. Ouvre le CSV dans Excel (ou `Import-Csv | Out-GridView`).

> [!success]- Afficher la correction — A1
> ```powershell
> Set-ExecutionPolicy -Scope Process Bypass -Force        # stratégie Restricted par défaut (chapitre 07)
> C:\MCO\Get-Inventaire.ps1 -ComputerName PC01,PC02 -Csv C:\MCO\inventaire.csv
> Import-Csv C:\MCO\inventaire.csv -Delimiter ';' | Out-GridView
> ```
> Le poste local (`PC01`) est interrogé directement, `PC02` par WinRM. Si `PC02` est « *Injoignable* » : WinRM n'y est pas actif (`Enable-PSRemoting` sur `PC02`, ou GPO du chapitre 12).

**A2.** Pour chaque poste, liste les **non-conformités** par rapport aux seuils du chapitre 20 (version, mises à jour, antivirus, BitLocker, disque, uptime).

> [!success]- Afficher la correction — A2
> Résultat obtenu dans le lab :
> ```
> Poste Version Build      C_Libre_Pct DerniereMaj Signatures_j BitLocker
> ----- ------- -----      ----------- ----------- ------------ ---------
> PC01  26H2    26300.9457          34 KB5129195            417 FullyEncrypted / On
> PC02  26H2    26300.9457          60 KB5129195            417 FullyDecrypted / Off
> ```
> | Poste | Non-conformité | Seuil |
> |-------|----------------|-------|
> | Les deux | Signatures antivirus de **417 jours** | > 3 jours |
> | Les deux | Dernière mise à jour du **13/09/2026** (≈ 2 mois) | > 35 jours |
> | `PC02` | **BitLocker désactivé** (conséquence de `PreventDeviceEncryption` dans le fichier de réponse, chapitre 16) | Chiffré et protégé |
>
> Les autres colonnes sont correctes : version supportée, disque > 15 %, uptime court, protection temps réel active.

**A3.** Les versions installées sont-elles supportées ? Jusqu'à quand ? Un poste Pro en 24H2 retrouvé dans un placard le serait-il ?

> [!success]- Afficher la correction — A3
> 26H2 Pro : supportée environ jusqu'en **octobre 2028** (24 mois après sa sortie du 29/09/2026).
> Un poste Pro en **24H2** n'est **plus supporté depuis le 13/10/2026** : plus aucun correctif de sécurité. Mise à niveau prioritaire vers 25H2 ou 26H2 (enablement package, un seul redémarrage — chapitre 08). Un poste Entreprise en 24H2 serait, lui, supporté jusqu'au 12/10/2027.

---

## Partie B — Remise en conformité (45 min)

**B1.** Mets à jour les signatures Defender sur les deux postes. Si la mise à jour échoue, trouve une source alternative.

> [!success]- Afficher la correction — B1
> ```powershell
> Update-MpSignature
> # Update-MpSignature : La mise à jour des définitions de virus et de logiciels espions s'est achevée avec des erreurs.
> ```
> Échec via la source par défaut (Windows Update) dans le lab. Source alternative, le MMPC :
> ```powershell
> Update-MpSignature -UpdateSource MMPC
> # ou
> & "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate -MMPC
> (Get-MpComputerStatus) | Select-Object AntivirusSignatureVersion, AntivirusSignatureAge
> # 1.463.189.0   0
> ```
> Sur `PC01`, la commande a d'abord renvoyé « *Échec de l'appel de procédure distante* » puis « *Échec de chargement du fournisseur* » : la mise à jour a aussi renouvelé la plateforme Defender et le service a **redémarré**. Quelques secondes plus tard : `WinDefend Running`, signatures à jour.
> Pour `PC02` à distance : `Invoke-Command PC02 { Update-MpSignature -UpdateSource MMPC }`.

**B2.** Active BitLocker sur `PC02` avec le TPM, en sauvegardant le mot de passe de récupération dans AD **avant** le chiffrement. Vérifie sur `SRV01` que la clé est bien enregistrée.

> [!success]- Afficher la correction — B2
> ```powershell
> # Sur PC02 (ou via Invoke-Command)
> Remove-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker -Name PreventDeviceEncryption
>
> # 1. Mot de passe de récupération d'abord, sauvegardé dans AD
> Add-BitLockerKeyProtector -MountPoint C: -RecoveryPasswordProtector
> $id = ((Get-BitLockerVolume C:).KeyProtector | Where-Object KeyProtectorType -eq RecoveryPassword)[0].KeyProtectorId
> Backup-BitLockerKeyProtector -MountPoint C: -KeyProtectorId $id
>
> # 2. Chiffrement avec le TPM
> Enable-BitLocker -MountPoint C: -TpmProtector -UsedSpaceOnly -SkipHardwareTest
> ```
> Dans le lab, premier essai **refusé** :
> ```
> Le chiffrement de lecteur BitLocker a détecté la présence d'un média de démarrage amovible (CD ou DVD)
> dans l'ordinateur. Retirez le média, puis redémarrez l'ordinateur avant de configurer BitLocker. (0x80310030)
> ```
> L'ISO de déploiement du TP 16 était toujours montée sur `PC02`. Depuis l'hôte : `Set-VMDvdDrive -VMName PC02 -Path $null`, puis relancer `Enable-BitLocker` — **pas besoin de redémarrer**, malgré le message. 30 secondes plus tard :
> ```
> VolumeStatus         ProtectionStatus EncryptionPercentage Prot
> EncryptionInProgress Off                                81 RecoveryPassword,Tpm
> ```
> `ProtectionStatus` passe à `On` en fin de chiffrement. Vérification sur `SRV01` :
> ```powershell
> Get-ADObject -Filter 'objectClass -eq "msFVE-RecoveryInformation"' `
>     -SearchBase (Get-ADComputer PC02).DistinguishedName -Properties whenCreated
> # Name : 2026-11-08T12:08:42+01:00{156031DA-0532-44E0-8622-418A9763D925}
> ```
> Pourquoi la clé **avant** : si le chiffrement démarre et que la sauvegarde échoue (DC injoignable), on a un poste chiffré dont personne ne connaît la clé. Avec la GPO du chapitre 11 (*Ne pas activer BitLocker tant que les informations de récupération ne sont pas stockées dans AD DS*), Windows l'impose.

**B3.** Vérifie l'état de Windows Update sur `PC02` : dernière mise à jour, stratégie appliquée (report), redémarrage en attente. Lance une recherche de mises à jour.

> [!success]- Afficher la correction — B3
> ```powershell
> Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 3
> Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate
> # DeferQualityUpdates : 1   DeferQualityUpdatesPeriodInDays : 7      ← GPO du chapitre 08
> Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
> ```
> Report de 7 jours : normal pour un anneau « large ». Mais un retard de deux mois signifie que la recherche **échoue** : *Paramètres → Windows Update → Rechercher des mises à jour*, puis le journal (`Get-WindowsUpdateLog` génère `WindowsUpdate.log` sur le Bureau) et l'Observateur *Microsoft-Windows-WindowsUpdateClient/Operational*. L'échec de la mise à jour Defender par la même source (B1) pointe dans la même direction : c'est **un** problème, pas deux.
> En dernier recours : `UsoClient StartInteractiveScan`, ou installer la cumulative à la main depuis le *Catalogue Microsoft Update* (`wusa` ou `Add-WindowsPackage`).

**B4.** Analyse le magasin de composants de `PC02`. Faut-il le nettoyer ? Avec ou sans `/ResetBase` ? *(approfondissement)*

> [!success]- Afficher la correction — B4
> ```cmd
> Dism /Online /Cleanup-Image /AnalyzeComponentStore
> ```
> ```
> Taille réelle du magasin de composants : 11.47 GB
>     Sauvegardes et fonctionnalités désactivées : 3.52 GB
> Nombre de packages récupérables : 2
> Nettoyage du magasin de composants recommandé : Oui
> ```
> ```cmd
> Dism /Online /Cleanup-Image /StartComponentCleanup
> ```
> **Sans** `/ResetBase` sur un poste en production : on veut pouvoir désinstaller la prochaine mise à jour défectueuse (chapitre 18). `/ResetBase` est pour une image de référence juste avant capture.

**B5.** Relance l'inventaire : quelles non-conformités restent ? Pourquoi ?

> [!success]- Afficher la correction — B5
> Signatures : 0 jour. BitLocker `PC02` : `EncryptionInProgress` puis `FullyEncrypted / On`.
> Reste : la **dernière mise à jour** tant que Windows Update n'a pas abouti. C'est normal et attendu : un inventaire n'est pas fait pour être « tout vert » le jour même, mais pour suivre les écarts dans le temps. Noter l'écart dans le plan de MCO avec une échéance.

---

## Partie C — Maintenance préventive (30 min)

**C1.** Sur `PC02`, planifie l'exécution quotidienne de `Test-Poste.ps1` à 8 h 30 sous le compte SYSTEM, avec un journal par jour dans `C:\MCO\Logs`. Range la tâche dans un dossier `\Fournil\`.

> [!success]- Afficher la correction — C1
> ```powershell
> New-Item C:\MCO\Logs -ItemType Directory -Force
> Copy-Item \\PC01\C$\MCO\Test-Poste.ps1 C:\MCO\      # ou Copy-Item -ToSession
>
> $a = New-ScheduledTaskAction -Execute 'powershell.exe' `
>      -Argument '-NoProfile -ExecutionPolicy Bypass -Command "C:\MCO\Test-Poste.ps1 *> C:\MCO\Logs\$(Get-Date -f yyyyMMdd).log"'
> $t = New-ScheduledTaskTrigger -Daily -At 8:30
> Register-ScheduledTask -TaskPath '\Fournil\' -TaskName 'Contrôle santé' -Action $a -Trigger $t -User SYSTEM -RunLevel Highest
> ```
> Les guillemets **simples** autour de l'argument sont essentiels : `$(Get-Date …)` doit être évalué **à chaque exécution**, pas une seule fois à la création de la tâche. `*>` redirige tous les flux, y compris `Write-Host`.

**C2.** Lance la tâche manuellement et vérifie son code retour et le journal produit.

> [!success]- Afficher la correction — C2
> ```powershell
> Start-ScheduledTask -TaskPath '\Fournil\' -TaskName 'Contrôle santé'
> Get-ScheduledTaskInfo -TaskPath '\Fournil\' -TaskName 'Contrôle santé' | Select-Object LastRunTime, LastTaskResult
> # 08/11/2026 12:07:33   0
> Get-Content C:\MCO\Logs\20261108.log
> # DNS = DC                            OK
> # srv01 -> DC                         OK
> # …
> # Canal sécurisé                      OK
> ```
> `LastTaskResult` à **0** = succès ; `267009` = en cours ; `2147942402` (0x80070002) = fichier introuvable (chemin du script).

**C3.** Pourquoi `Test-Poste.ps1` ne signale-t-il pas ta propre tâche comme suspecte, alors qu'il a détecté celle du TP 19 ?

> [!success]- Afficher la correction — C3
> `Test-Poste.ps1` ne cherche que les tâches à la **racine** (`-TaskPath '\'`) qui lancent un interpréteur. La nôtre est rangée dans `\Fournil\`. C'est une convention, pas une sécurité : un attaquant peut aussi créer un dossier. La vraie différence est **organisationnelle** : la tâche est documentée dans le plan de MCO, son script est dans un dossier dont l'écriture est réservée aux administrateurs, et elle est déployée de la même façon sur tous les postes (idéalement par GPO : *Préférences → Paramètres du Panneau de configuration → Tâches planifiées*).

**C4.** Propose une GPO pour définir l'ordre des sources de mise à jour Defender avec une source de secours.

> [!success]- Afficher la correction — C4
> *Configuration ordinateur → Stratégies → Modèles d'administration → Composants Windows → Antivirus Microsoft Defender → Mises à jour des renseignements de sécurité* :
> - **Définir l'ordre des sources pour le téléchargement des mises à jour des renseignements de sécurité** : `InternalDefinitionUpdateServer|MicrosoftUpdateServer|MMPC`
> - **Spécifier l'intervalle de vérification des mises à jour** : 4 heures (par exemple)
> - **Définir le nombre de jours avant que les renseignements de sécurité soient considérés comme obsolètes** : 3
>
> Vérification sur le poste : `Get-MpPreference | Select-Object SignatureFallbackOrder, SignatureUpdateInterval`.

---

## Partie D — Incident chronométré (30 min)

Ton binôme exécute `Casse-Poste.ps1` sur **ton** `PC02` (pendant ce temps tu exécutes le sien), puis redémarre le poste.

**D1.** Chronomètre : combien de temps pour **détecter** toutes les pannes avec tes outils, sans chercher à la main ?

> [!success]- Afficher la correction — D1
> Avec `Test-Poste.ps1`, la détection prend **moins d'une minute** :
> ```
> DNS = DC                            KO
> srv01 -> DC                         KO
> SMB vers srv01                      KO
> Spooler                             KO
> Pas de blocage sortant local        KO
> Pas de tâche script à la racine     KO
> Canal sécurisé                      OK      ← KO après redémarrage
> ```
> Sortie réelle obtenue sur `PC02` juste après `Casse-Poste.ps1`. Comparer avec la durée du TP 19, fait « à la main » : c'est tout l'intérêt de l'outillage. Le script ne trouve que ce qu'il cherche : une panne inédite demande toujours la méthode du chapitre 19.

**D2.** Répare, puis prouve que c'est réparé.

> [!success]- Afficher la correction — D2
> ```powershell
> $carte = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).Name
> Set-DnsClientServerAddress -InterfaceAlias $carte -ResetServerAddresses
> $h = "$env:windir\System32\drivers\etc\hosts"
> (Get-Content $h) | Where-Object { $_ -notmatch 'srv01' } | Set-Content $h
> Clear-DnsClientCache
> Remove-NetFirewallRule -DisplayName "Maintenance - ne pas supprimer"
> Set-Service Spooler -StartupType Automatic; Start-Service Spooler
> Unregister-ScheduledTask -TaskName 'OneDrive Updater Helper' -Confirm:$false
> Remove-Item C:\ProgramData\Updater -Recurse -Force
> ```
> Preuve : `Test-Poste.ps1` → 7 OK (validé dans le lab), plus vérification avec l'utilisateur (lecteur `P:`, impression).

**D3.** Rédige le ticket d'intervention.

> [!success]- Afficher la correction — D3
> Voir le modèle du TP 19 (E2). Ajouter cette fois le **temps de détection** et le **temps de résolution** : ce sont les deux indicateurs qu'un plan de MCO cherche à réduire.

---

## Partie E — Fin de vie d'un poste (20 min)

L'ordinateur portable d'une vendeuse est remplacé. Il est joint au domaine, chiffré par BitLocker, géré par LAPS.

**E1.** Écris la procédure complète de sortie du parc, dans l'ordre, avec les commandes.

> [!success]- Afficher la correction — E1
> ```
> 1. Données     Vérifier la synchronisation OneDrive (KFM) ou migrer avec USMT vers le nouveau poste
>                 scanstate \\SRV01\USMT\%COMPUTERNAME% /i:MigDocs.xml /i:MigApp.xml /ue:*\* /ui:FOURNIL\<vendeuse>
> 2. AD          Récupérer le mot de passe LAPS et la clé BitLocker (voir E2), puis :
>                 Disable-ADAccount -Identity (Get-ADComputer PORTABLE07)
> 3. Effacement  Paramètres → Système → Récupération → Réinitialiser ce PC → Supprimer tout
>                 → « Nettoyer le lecteur » (ou effacement cryptographique, E3)
> 4. Cloud       Supprimer l'appareil d'Intune / Autopilot / Entra ID s'il y est
> 5. AD          Après un délai de sécurité (30 jours) : Remove-ADComputer PORTABLE07
> 6. Inventaire  GLPI : statut « réformé », date, destination, n° de série
> 7. Matériel    Filière DEEE ou don/reconditionnement, avec attestation d'effacement
> ```
> Désactiver avant de supprimer : si un oubli apparaît (un partage, une clé), le compte et ses attributs sont toujours là.

**E2.** Quelles informations faut-il récupérer **dans AD** avant de supprimer le compte ordinateur ? Pourquoi ?

> [!success]- Afficher la correction — E2
> - Le **mot de passe de récupération BitLocker** (objets `msFVE-RecoveryInformation` sous le compte ordinateur) ;
> - le **mot de passe LAPS** (`Get-LapsADPassword PORTABLE07 -AsPlainText`).
>
> Ces deux informations sont stockées **sur l'objet ordinateur** : `Remove-ADComputer` les supprime avec lui. Si le disque doit encore être lu (litige, donnée oubliée), sans elles il est perdu. La corbeille AD (si activée) laisse un délai de rattrapage, mais il ne faut pas compter dessus.

**E3.** Pourquoi l'effacement d'un disque BitLocker peut-il être quasi instantané ?

> [!success]- Afficher la correction — E3
> Sur un disque chiffré, les données ne sont lisibles qu'avec la **clé de chiffrement du volume**, elle-même protégée par le TPM et le mot de passe de récupération. Détruire ces protecteurs (ou réinitialiser le PC, qui régénère les clés) rend les données **illisibles** sans avoir à réécrire tout le disque : c'est l'*effacement cryptographique*. À condition, bien sûr, qu'aucune copie du mot de passe de récupération ne traîne… dans AD (E2) ou ailleurs.

---

## Partie F — Le plan de MCO (25 min)

**F1.** Rédige dans `C:\MCO\Plan-MCO.md` le plan de MCO du parc Fournil : tâches, fréquences, responsables, vérifications.

> [!success]- Afficher la correction — F1
> ```markdown
> # Plan de MCO — parc Fournil (mis à jour le 08/11/2026)
>
> | Fréquence     | Tâche                                          | Qui              | Vérification                    |
> |---------------|------------------------------------------------|------------------|---------------------------------|
> | Quotidienne   | Contrôle santé (tâche \Fournil\Contrôle santé) | Automatique      | C:\MCO\Logs, lecture le lundi   |
> | Hebdomadaire  | Revue signatures AV, échecs Windows Update     | Technicien       | Get-Inventaire.ps1              |
> | Mensuelle     | Patch Tuesday : anneau pilote (PC01) J+0,      | Technicien       | Inventaire : DerniereMaj        |
> |               | anneau large J+7 (GPO report 7 jours)          |                  |                                 |
> | Trimestrielle | Inventaire archivé, test de restauration,      | Responsable info | CSV daté, PV de test            |
> |               | revue admins locaux / LAPS                     |                  |                                 |
> | Annuelle      | Mise à niveau H2, revue cycle de vie, matériel | Responsable info | Tableau des échéances (F2)      |
> | Incident      | Ticket : symptôme, cause, actions, durées      | Technicien       | GLPI                            |
> ```

**F2.** Ajoute un calendrier des **échéances de cycle de vie** des versions présentes dans le parc.

> [!success]- Afficher la correction — F2
> | Version | Édition | Postes | Fin de support | Action |
> |---------|---------|--------|----------------|--------|
> | 26H2 | Pro | PC01, PC02 | ≈ octobre 2028 | Passer en 27H2 au plus tard mi-2028 |
> | 24H2 | Pro | (aucun — à vérifier dans l'inventaire) | **13/10/2026, dépassée** | Mise à niveau immédiate |
> | Windows 10 | — | (aucun) | 14/10/2025 (ESU payantes) | Remplacement / mise à niveau |
> | Windows Server 2025 | — | SRV01 | novembre 2034 (support étendu) | — |
>
> Les dates se vérifient chaque année sur *Windows 11 release information* et *Microsoft Lifecycle*.

**F3.** Ajoute la stratégie de sauvegarde (règle 3-2-1) et la date du prochain **test de restauration**.

> [!success]- Afficher la correction — F3
> - **Copie 1** : les données sur le poste ;
> - **Copie 2** : OneDrive (KFM : Bureau, Documents, Images) — autre support, hors site, versionné 30 jours ;
> - **Copie 3** : partage `\\SRV01\Commun` sauvegardé chaque nuit vers un NAS, avec une copie **hors ligne** ou immuable (protection contre les rançongiciels).
>
> Prochain test de restauration : **février 2027** — restaurer un dossier OneDrive à J-7 et un fichier du NAS, chronométrer, consigner dans un PV.
> Ne figurent **pas** dans la stratégie : les points de restauration et le point-in-time restore (même disque), ni `wbadmin` (déprécié).

---

[Retour à l'énoncé](https://cours.kaya.ovh/windows11/windows11/20-mco/tp)
