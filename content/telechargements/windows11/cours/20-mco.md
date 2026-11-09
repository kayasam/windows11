# 20. Maintien en condition opérationnelle

> [!NOTE] Objectif
> Passer du dépannage au coup par coup à une **maintenance organisée** du parc : savoir ce que l'on a (inventaire), savoir dans quel état c'est (santé), garder les postes à jour et supportés (cycle de vie), protéger les données (sauvegarde), et retirer proprement un poste en fin de vie.
>
> **Outils :** `Get-CimInstance`, `Get-HotFix`, `Get-MpComputerStatus`, `Get-BitLockerVolume`, DISM, Planificateur de tâches, agent GLPI, Intune / Autopatch (rapports)
> **Scripts fournis :** `Ressources/scripts/Get-Inventaire.ps1`, `Ressources/scripts/Test-Poste.ps1`

> [!INFO] Fil rouge — Fournil
> Le parc de la boulangerie Fournil compte deux postes de lab (`PC01`, `PC02`) et le serveur `SRV01`. On met en place l'inventaire, le contrôle de santé et la procédure de fin de vie, puis on termine par le **TP final**.

---

## 1. Les trois maintenances

| Type | But | Exemples sur un poste Windows 11 |
|------|-----|-----------------------------------|
| **Préventive** | Éviter la panne | Mises à jour, signatures antivirus, nettoyage disque, sauvegardes, contrôle de santé planifié |
| **Corrective** | Réparer | Chapitres 18 et 19 : WinRE, SFC/DISM, dépannage réseau… |
| **Évolutive** | Suivre le cycle de vie | Mise à niveau de version (25H2 → 26H2), renouvellement matériel, migration Windows 10 → 11 |

Le MCO, c'est surtout de la **préventive** et de l'**évolutive** — pour faire le moins possible de corrective.

---

## 2. Cycle de vie : savoir ce qui est encore supporté

Chaque **version** de Windows 11 (mise à jour de fonctionnalités annuelle, en H2) a sa propre date de fin :

| Édition | Durée de support d'une version |
|---------|--------------------------------|
| Famille, **Pro** | **24 mois** |
| **Entreprise**, Éducation | **36 mois** |

| Version | Fin Famille / Pro | Fin Entreprise / Éducation |
|---------|-------------------|----------------------------|
| 23H2 | 11/11/2025 (terminé) | **10/11/2026** |
| 24H2 | **13/10/2026 (terminé)** | 12/10/2027 |
| 25H2 | 12/10/2027 | 10/10/2028 |
| 26H2 | ≈ octobre 2028 | ≈ octobre 2029 |

> [!WARNING] Novembre 2026
> Un poste **Pro** encore en 24H2 ne reçoit **plus** de correctifs de sécurité depuis le 13 octobre 2026. La version 23H2 Entreprise s'arrête le 10 novembre 2026. Vérifier dans l'inventaire (colonne `Version`) et planifier la mise à niveau (25H2 et 26H2 sont des *enablement packages* rapides au-dessus de 24H2, chapitre 08).
>
> **Windows 10** est hors support depuis le 14/10/2025 ; seuls les postes inscrits aux **ESU** (mises à jour de sécurité étendues, payantes en entreprise) reçoivent encore des correctifs.

Source de référence : la page *Windows 11 release information* de Microsoft (à consulter en début de chaque année).

---

## 3. Inventaire : savoir ce que l'on a

### En PowerShell

Le script `Ressources/scripts/Get-Inventaire.ps1` collecte, par CIM et registre, l'essentiel d'un poste et l'exporte en CSV (séparateur `;` pour Excel en français) :

```powershell
.\Get-Inventaire.ps1 -ComputerName PC01,PC02,PC09 -Csv C:\MCO\inventaire.csv |
    Format-Table Poste, Version, Build, C_Libre_Pct, DerniereMaj, Signatures_j, BitLocker
```

Résultat réel dans le lab, lancé depuis `PC01` :

```
AVERTISSEMENT : Injoignable : PC09

Poste Version Build      C_Libre_Pct DerniereMaj Signatures_j BitLocker
----- ------- -----      ----------- ----------- ------------ ---------
PC01  26H2    26300.9457          34 KB5129195            417 FullyEncrypted / On
PC02  26H2    26300.9457          60 KB5129195            417 FullyDecrypted / Off
```

Trois anomalies en une ligne de commande :
- **Signatures Defender vieilles de 417 jours** sur les deux postes — alors qu'Internet fonctionne (voir section 4) ;
- **`PC02` non chiffré** : hérité de `PreventDeviceEncryption` capturé dans l'image (chapitre 14) ;
- dernière mise à jour cumulative du **13/09/2026** : deux mois de retard.

> [!TIP] Le poste local et WinRM
> WinRM est **arrêté par défaut** sur Windows 11 (chapitre 12), y compris sur le poste d'administration lui-même : le script interroge donc le poste local directement et les autres par `Invoke-Command`. Première version du script : `if ($ComputerName -eq $env:COMPUTERNAME)` — sur un **tableau**, `-eq` filtre au lieu de comparer, la condition était vraie et seul `PC01` était inventorié. Toujours tester un script sur **plusieurs** postes.

### Outils d'inventaire de parc

| Outil | Contexte |
|-------|----------|
| **GLPI** + agent GLPI (ex-FusionInventory) | Open source, très répandu en France : inventaire matériel/logiciel automatique, parc, tickets |
| **Intune** (*Appareils*, *Endpoint analytics*) | Postes gérés dans le cloud : conformité, inventaire, scores de démarrage et de fiabilité |
| **Configuration Manager** (SCCM) | Grands parcs historiques sur site |
| **Lansweeper**, OCS Inventory… | Inventaire réseau sans agent / avec agent |

Le script PowerShell dépanne et sert à **vérifier** un point précis ; pour un parc, un outil d'inventaire avec historique est indispensable.

---

## 4. Santé du parc : les indicateurs à surveiller

| Indicateur | Commande | Seuil d'alerte (exemple) |
|------------|----------|--------------------------|
| Version supportée | `(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion` | Fin de support < 3 mois |
| Dernière mise à jour | `Get-HotFix \| Sort-Object InstalledOn -Desc \| Select -First 1` | > 35 jours |
| Redémarrage en attente | clé `…\WindowsUpdate\Auto Update\RebootRequired` | Présente depuis > 7 jours |
| Signatures antivirus | `(Get-MpComputerStatus).AntivirusSignatureAge` | > 3 jours |
| Protection temps réel | `(Get-MpComputerStatus).RealTimeProtectionEnabled` | `False` |
| BitLocker | `Get-BitLockerVolume C:` | `ProtectionStatus Off` sur un portable |
| Espace disque | `Get-CimInstance Win32_LogicalDisk` | < 15 % libre |
| Uptime | `(Get-CimInstance Win32_OperatingSystem).LastBootUpTime` | > 30 jours (mises à jour non appliquées) |
| Fiabilité | `Get-CimInstance Win32_ReliabilityStabilityMetrics` | Indice < 5 |

### Constaté dans le lab : Defender ne se met plus à jour

```powershell
Update-MpSignature
# Update-MpSignature : La mise à jour des définitions de virus et de logiciels espions s'est achevée avec des erreurs.
```

Après 1 min 20, échec via la source par défaut (Windows Update). En forçant la source **MMPC** (Microsoft Malware Protection Center, téléchargement direct) :

```powershell
& "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate -MMPC
(Get-MpComputerStatus).AntivirusSignatureAge      # 0  — version 1.437.1.0 → 1.463.189.0
```

Pendant la mise à jour, le moteur et la plateforme Defender peuvent être renouvelés : le service redémarre et une commande lancée au même moment échoue avec « *Échec de l'appel de procédure distante* ». Attendre quelques secondes et relancer.

> [!TIP] Ordre de mise à jour des signatures
> Par GPO : *Composants Windows → Antivirus Microsoft Defender → Mises à jour des renseignements de sécurité → Définir l'ordre des sources* (`InternalDefinitionUpdateServer|MicrosoftUpdateServer|MMPC`). Ajouter **MMPC** en secours évite qu'un Windows Update bloqué laisse l'antivirus aveugle.

### Contrôle planifié

Le script `Test-Poste.ps1` (TP 19) se planifie chaque matin, avec journalisation :

```powershell
$a = New-ScheduledTaskAction -Execute 'powershell.exe' `
     -Argument '-NoProfile -ExecutionPolicy Bypass -Command "C:\MCO\Test-Poste.ps1 *> C:\MCO\Logs\$(Get-Date -f yyyyMMdd).log"'
$t = New-ScheduledTaskTrigger -Daily -At 8:30
Register-ScheduledTask -TaskPath '\Fournil\' -TaskName 'Contrôle santé' -Action $a -Trigger $t -User SYSTEM -RunLevel Highest
```

Remarquer la différence avec la tâche malveillante du TP 19 : rangée dans un **dossier** à son nom (`\Fournil\`), nom explicite, script dans un dossier protégé (`C:\MCO`, droits d'écriture réservés aux administrateurs) et **documentée**.

---

## 5. Maintenance préventive du système

### Maintenance automatique

Windows exécute chaque jour (par défaut à **2 h**, ou dès que le poste est inactif) la *maintenance automatique* : défragmentation/TRIM, analyses Defender, nettoyage du magasin de composants, diagnostics. Elle se configure dans *Panneau de configuration → Sécurité et maintenance → Maintenance*, ou par GPO (*Composants Windows → Planificateur de maintenance*). Un poste toujours éteint la nuit la rattrape à la prochaine période d'inactivité.

### Magasin de composants (WinSxS)

```cmd
Dism /Online /Cleanup-Image /AnalyzeComponentStore
```

Sur `PC02` :

```
Taille réelle du magasin de composants : 11.47 GB
    Partagé avec Windows : 7.94 GB
    Sauvegardes et fonctionnalités désactivées : 3.52 GB
Nombre de packages récupérables : 2
Nettoyage du magasin de composants recommandé : Oui
```

```cmd
Dism /Online /Cleanup-Image /StartComponentCleanup
```

> [!WARNING] `/ResetBase`
> `/StartComponentCleanup /ResetBase` libère davantage mais rend **impossible la désinstallation** des mises à jour déjà installées. À éviter sur un poste en production (on perd une arme du chapitre 18) ; utile sur une image de référence juste avant capture.

### Espace disque

- **Assistant Stockage** (*Paramètres → Système → Stockage*) : nettoyage automatique des fichiers temporaires, de la corbeille, des fichiers OneDrive non utilisés (*Fichiers à la demande*). Pilotable par GPO (*Composants Windows → Assistant Stockage*).
- `cleanmgr` reste présent mais Microsoft oriente vers l'Assistant Stockage.

---

## 6. Sauvegarde des données

| Solution | Statut 2026 | Usage |
|----------|-------------|-------|
| **OneDrive** + *Déplacement des dossiers connus* (KFM) | Recommandé | Bureau, Documents, Images synchronisés et versionnés (chapitre 17) |
| Application **Sauvegarde Windows** | Actuel | Dossiers, paramètres, applications et identifiants vers OneDrive ; restauration à l'OOBE d'un nouveau poste |
| **Historique des fichiers** | Toujours présent | Copies versionnées vers un disque externe ou un partage ; pratique hors Microsoft 365 |
| *Sauvegarde et restauration (Windows 7)*, `wbadmin` (image système) | **Déprécié**, encore présent | Ne plus construire de procédure dessus |
| Point de restauration, point-in-time restore | Actuel | **Pas des sauvegardes** : même disque que les données |
| Solution tierce (Veeam Agent, Acronis…) | — | Image complète, sauvegarde centralisée |

> [!IMPORTANT] Règle 3-2-1
> **3** copies, sur **2** supports différents, dont **1** hors site. Une synchronisation (OneDrive) n'est pas une sauvegarde au sens strict : une suppression ou un chiffrement par rançongiciel se synchronise… d'où l'importance de la **corbeille OneDrive** et de la **restauration à une date antérieure** (*Restaurer votre OneDrive*, 30 jours).

Et une sauvegarde non testée n'existe pas : prévoir **un test de restauration** dans le plan de MCO.

---

## 7. Fin de vie d'un poste

```
1. Données       Vérifier que les données utilisateur sont sauvegardées / migrées (USMT, OneDrive — ch. 16-17)
2. Effacement    Réinitialiser ce PC → Supprimer tout + nettoyer le lecteur
                 ou, si BitLocker actif : effacer les protecteurs (manage-bde) puis réinitialiser
                 = « effacement cryptographique » : sans clé, les données sont illisibles
3. Annuaire      Désactiver puis supprimer le compte ordinateur dans AD
                 (la clé de récupération BitLocker et le mot de passe LAPS sont stockés dessus : les récupérer avant si besoin)
4. Cloud         Retirer de Intune / Autopilot / Entra ID le cas échéant
5. Inventaire    Marquer le poste « réformé » dans GLPI (n° de série, date, destination)
6. Matériel      Filière DEEE ou reconditionnement ; certificat d'effacement si sous-traité
```

> [!TIP] Réutiliser un poste
> Pour **réattribuer** un poste à un autre utilisateur, pas besoin de réinstaller : *Réinitialiser ce PC* (ou redéploiement par l'ISO du chapitre 16) suffit. Avec Intune : *Autopilot Reset*.

---

## 8. Le plan de MCO

Le MCO s'écrit : qui fait quoi, à quelle fréquence, comment on le vérifie.

| Fréquence | Action | Vérification |
|-----------|--------|--------------|
| Quotidienne | Contrôle santé planifié (`Test-Poste.ps1`) | Journaux `C:\MCO\Logs`, alertes |
| Hebdomadaire | Revue des signatures AV, des échecs de mises à jour | Inventaire / console |
| Mensuelle (Patch Tuesday, 2ᵉ mardi) | Anneaux de mises à jour : pilote → large (chapitre 08) | Rapport de conformité |
| Trimestrielle | Inventaire complet, test de restauration, revue des comptes admin et LAPS | CSV archivé, PV de test |
| Annuelle | Mise à niveau de version (H2), revue du cycle de vie, renouvellement matériel | Plan de migration |
| À chaque intervention | Ticket documenté (chapitre 19) | Base de connaissances |

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> - MCO = préventive + corrective + évolutive (viser le moins de corrective possible)
> - **Cycle de vie** : Pro 24 mois / Entreprise 36 mois par version
>   - **nov. 2026** : 24H2 Pro HORS support (13/10/2026), 23H2 Ent. fin 10/11/2026, Win10 hors support (ESU)
> - **Inventaire** : `Get-Inventaire.ps1` (CIM, local + `Invoke-Command`) → CSV · GLPI, Intune pour un parc
> - **Santé** : version, dernière KB, reboot en attente, AntivirusSignatureAge, BitLocker, disque, uptime
>   - Defender bloqué ? `MpCmdRun -SignatureUpdate -MMPC` ; GPO ordre des sources avec MMPC en secours
> - **Maintenance** : maintenance automatique, `Dism /AnalyzeComponentStore` → /StartComponentCleanup (pas /ResetBase en prod)
> - **Sauvegarde** : OneDrive KFM + Sauvegarde Windows · Historique des fichiers · `wbadmin` déprécié · 3-2-1 + test de restauration
> - **Fin de vie** : données → effacement (réinit. / crypto-erase BitLocker) → AD (récupérer LAPS/BitLocker) → Intune → GLPI → DEEE
