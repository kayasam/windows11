# 19. Diagnostic et dépannage

> [!NOTE] Objectif
> Adopter une **méthode** de diagnostic, puis maîtriser les outils de Windows 11 pour chaque famille de pannes : système (journaux, fiabilité, Sysmon), performances, services et applications, réseau, fichiers système. **Tracer et documenter** chaque intervention, maintenant que l'Enregistreur d'actions (PSR) et les dépanneurs MSDT sont en fin de vie.
>
> **Outils :** Observateur d'événements, Moniteur de fiabilité, `resmon`, `perfmon`, Sysmon, *Obtenir de l'aide*, Outil Capture d'écran (enregistrement)
> **Commandes à connaître :** `Get-WinEvent`, `Test-NetConnection`, `Resolve-DnsName`, `Get-NetTCPConnection`, `pktmon`, `sfc`, `DISM /RestoreHealth`, `chkdsk`, `Get-CimInstance`

> [!INFO] Fil rouge — Fournil
> Les pannes du TP sont provoquées sur `PC02` par un script ; on les résout depuis `PC01` autant que possible (Remoting, CIM, journaux).

---

## 1. Une méthode avant les outils

```
1. Recueillir    Qui ? Quoi exactement ? Depuis quand ? Qu'est-ce qui a changé ? Reproductible ?
2. Délimiter     Un poste ou tous ? Un utilisateur ou tous ? Une application ou tout ?
3. Hypothèses    Classer par probabilité ET par facilité de vérification
4. Tester        Une seule modification à la fois — noter chaque test et son résultat
5. Corriger      Puis vérifier avec l'utilisateur que c'est réglé (pas seulement « ça devrait »)
6. Documenter    Ticket : symptôme, cause, solution, durée — pour le prochain
```

> [!TIP] « Qu'est-ce qui a changé ? »
> Neuf pannes sur dix suivent un changement : mise à jour, pilote, logiciel installé, déménagement, nouveau mot de passe. Le Moniteur de fiabilité et `Get-HotFix` répondent souvent à la question en une minute.

---

## 2. Système : journaux, fiabilité, Sysmon

| Outil | Pour quoi | Rappel |
|-------|-----------|--------|
| **Observateur d'événements** | Le détail horodaté | Vues personnalisées, `Get-WinEvent -FilterHashtable` (chapitre 06) |
| **Moniteur de fiabilité** (`perfmon /rel`) | La chronologie : quand ça a commencé | Indice 1-10, plantages, échecs de mise à jour |
| **Obtenir de l'aide** (*Get Help*) | Dépannages guidés (audio, réseau, impression…) | **Remplace les dépanneurs MSDT** (retirés) |
| **Sysmon** (intégré en 26H2) | Traçage fin des processus, connexions, fichiers | Voir ci-dessous |

### Sysmon intégré à Windows 11 26H2

**Sysmon** (*System Monitor*, de la suite Sysinternals) journalise ce que les journaux standard ne voient pas : chaque **création de processus** avec sa ligne de commande et son parent, les **connexions réseau** par processus, les créations de fichiers exécutables, les chargements de pilotes… Depuis 26H2, il fait partie de Windows (fonctionnalité facultative, désactivée par défaut). Testé sur `PC01` :

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Sysmon -All      # pas de redémarrage
sysmon.exe -accepteula -i                                           # installe le pilote et le service
Get-Service Sysmon                                                  # Running, Automatic
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 3
```

```
Id 1 — Création de processus : Image: C:\Windows\System32\notepad.exe …
Id 1 — Création de processus : Image: C:\Windows\System32\smartscreen.exe
Id 5 — Processus terminé : Image: C:\Windows\System32\sysmon.exe
```

| ID Sysmon | Événement |
|-----------|-----------|
| 1 | Création de processus (ligne de commande, hash, processus parent) |
| 3 | Connexion réseau (processus, IP, port) |
| 11 | Création de fichier |
| 13 | Modification de registre |
| 22 | Requête DNS (par processus) |

Sans fichier de configuration, Sysmon journalise beaucoup : en production on utilise une configuration filtrée (`sysmon -c config.xml`, modèles communautaires reconnus), et on envoie les événements à un SIEM. En dépannage, c'est l'outil qui répond à « *quel processus lance ce truc au démarrage ?* » ou « *qui se connecte à cette IP ?* ».

---

## 3. Performances

| Question | Outil |
|----------|-------|
| Qu'est-ce qui consomme, là, maintenant ? | Gestionnaire des tâches (processus, performances, **NPU** en 26H2) |
| Quel processus verrouille ce fichier, utilise ce port ? | Moniteur de ressources (`resmon`) → Disque / Réseau / Processeur (*Handles associés*) |
| Le poste est lent « de temps en temps » | **Collecteur de données** dans `perfmon` (enregistrement sur la durée) |
| Le démarrage est long | Gestionnaire des tâches → Applications de démarrage ; journal *Diagnostics-Performance* (ID 100 : durée du démarrage) |

```powershell
# Collecteur de données : CPU, mémoire, disque toutes les 15 s pendant 1 h
logman create counter Fournil-Perf -c "\Processor(_Total)\% Processor Time" "\Memory\Available MBytes" `
    "\PhysicalDisk(_Total)\Avg. Disk Queue Length" -si 00:00:15 -rf 01:00:00 -o C:\PerfLogs\Fournil-Perf
logman start Fournil-Perf
# … puis ouvrir le .blg dans perfmon

# Durée des derniers démarrages (ms)
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnostics-Performance/Operational'; Id=100} -MaxEvents 5 |
    ForEach-Object { [xml]$x = $_.ToXml(); [pscustomobject]@{ Date=$_.TimeCreated; BootMs=($x.Event.EventData.Data | Where-Object Name -eq 'BootTime').'#text' } }
```

---

## 4. Services et applications

```powershell
# Services automatiques arrêtés (hors ceux qui s'arrêtent normalement)
Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }

# Pourquoi un service ne démarre pas : journal Système, source Service Control Manager
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Service Control Manager'; Level=2} -MaxEvents 10

# Plantages d'applications (Application Error 1000, Application Hang 1002)
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,1002} -MaxEvents 10 | Select-Object TimeCreated, Message
```

Rapports d'erreurs détaillés : `C:\ProgramData\Microsoft\Windows\WER\ReportArchive`. Pour une application qui ne démarre plus pour **un** utilisateur : tester avec un autre profil (profil corrompu ? chapitre 17), puis réinitialiser l'application (Paramètres → Applications → Options avancées → **Réinitialiser**, pour les applications MSIX).

---

## 5. Réseau : du bas vers le haut

![Diagnostic réseau, couche par couche — Vérifier successivement le lien, l’adressage, le DNS, le port du service, l’authentification et l’application.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-19-diagnostic-reseau.svg)

| Étape | Commande | Ce qu'on cherche |
|-------|----------|------------------|
| Carte | `Get-NetAdapter` | `Up`, vitesse, bon réseau |
| IP | `ipconfig /all`, `Get-NetIPConfiguration` | IP valide (pas **169.254** = pas de DHCP), passerelle, DNS = le DC |
| Passerelle | `Test-Connection 192.168.3.254` | Réponse |
| DNS | `Resolve-DnsName srv01.ad.fournil.lab`, `nslookup` | Bonne IP, bon serveur DNS |
| Port | `Test-NetConnection SRV01 -Port 445` | `TcpTestSucceeded : True` |
| Chemin | `tracert`, `pathping`, `Test-NetConnection -TraceRoute` | Où ça s'arrête |
| Connexions | `Get-NetTCPConnection -State Established`, `netstat -ano` | Quel processus parle à qui |
| Capture | `pktmon start --capture`, `pktmon stop`, `pktmon etl2pcap` | Paquets (ouvrable dans Wireshark) |

> [!NOTE] Vécu sur le lab
> `PC02` fraîchement déployé avait une IP **169.254.75.198** : `SRV01` (DHCP) était arrêté. Après redémarrage du serveur : `ipconfig /renew` → `192.168.3.100`, passerelle `.254`, DNS `.1`. Le diagnostic tient en une ligne : *APIPA = le DHCP n'a pas répondu*.

```powershell
# Les classiques, en une passe
Get-NetIPConfiguration
Resolve-DnsName ad.fournil.lab
Test-NetConnection SRV01 -Port 389         # LDAP du DC
Test-NetConnection www.microsoft.com -Port 443
ipconfig /flushdns; ipconfig /registerdns  # cache DNS et enregistrement dynamique
```

`netsh` reste utile pour ce qui n'a pas d'équivalent PowerShell : `netsh winsock reset`, `netsh int ip reset`, `netsh wlan show wlanreport` (rapport Wi-Fi HTML).

---

## 6. Interroger un poste à distance : CIM et WMI

Tout ce qu'on lirait dans les consoles se lit aussi en PowerShell, à distance (WinRM, chapitre 12) :

```powershell
$s = New-CimSession -ComputerName PC02
Get-CimInstance Win32_OperatingSystem -CimSession $s | Select-Object Caption, LastBootUpTime, FreePhysicalMemory
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -CimSession $s | Select-Object DeviceID, FreeSpace
Get-CimInstance Win32_Service -Filter "StartMode='Auto' AND State<>'Running'" -CimSession $s | Select-Object Name, State
Get-CimInstance Win32_QuickFixEngineering -CimSession $s | Sort-Object InstalledOn -Descending | Select-Object -First 3
Remove-CimSession $s
```

---

## 7. Fichiers système et disque

```cmd
sfc /scannow                                   :: vérifie et répare les fichiers protégés
DISM /Online /Cleanup-Image /ScanHealth        :: état du magasin de composants
DISM /Online /Cleanup-Image /RestoreHealth     :: répare le magasin (Windows Update comme source)
sfc /scannow                                   :: à relancer après DISM
chkdsk C: /scan                                :: analyse en ligne du système de fichiers
chkdsk C: /f                                   :: réparation (au prochain démarrage pour C:)
```

Ordre recommandé : **DISM d'abord, puis SFC** (SFC répare à partir du magasin que DISM vient de réparer). Journal : `C:\Windows\Logs\CBS\CBS.log`. Si rien n'y fait : *Réinstaller maintenant* via Windows Update (chapitre 18).

---

## 8. Tracer et documenter les interventions

L'**Enregistreur d'actions** (*Steps Recorder*, `psr.exe`) est **déprécié** : encore présent en 26H2 avec un bandeau d'avertissement, il sera retiré. Les dépanneurs **MSDT** sont déjà retirés. Les remplaçants :

| Besoin | Outil 2026 |
|--------|------------|
| Montrer ce que fait l'utilisateur | **Outil Capture d'écran** (`Win + Maj + R` : enregistrement vidéo de l'écran) |
| Une capture annotée | Outil Capture d'écran (`Win + Maj + S`) |
| Dépannage guidé | Application **Obtenir de l'aide** |
| Prise en main | Assistance rapide, Remote Help (chapitre 12) |
| Garder la trace | **Ticket** dans l'outil de support (GLPI…) : symptôme, diagnostic, actions, résultat, temps passé |
| Prouver l'état d'un poste | Rapports : `gpresult /h`, `msinfo32 /report`, `Get-ComputerInfo`, rapport de batterie `powercfg /batteryreport` |

Un bon compte rendu d'intervention répond à : **quoi** (symptôme), **pourquoi** (cause), **comment** (actions, commandes), **résultat** (vérifié avec l'utilisateur), **prévention** (pour que ça ne revienne pas).

---

## 9. Bonus : démarrer sur un disque virtuel (VHDX natif)

Windows peut **démarrer directement sur un fichier VHDX** stocké sur le disque physique (*native boot*), sans hyperviseur — pratique pour tester une image sur du vrai matériel, ou avoir un second système jetable :

```cmd
diskpart
  create vdisk file=C:\VHD\Test.vhdx maximum=60000 type=expandable
  attach vdisk
  create partition primary
  format quick fs=ntfs label=VHD
  assign letter=V
  exit
Dism /Apply-Image /ImageFile:D:\Images\MASTER.wim /Index:1 /ApplyDir:V:\
bcdboot V:\Windows                       :: ajoute une entrée au menu de démarrage
```

Au redémarrage, le menu propose les deux Windows. Limites : pas d'hibernation, pas de BitLocker sur le VHDX hôte, performances disque légèrement inférieures.

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> - **Méthode** : recueillir → délimiter → hypothèses → tester (une chose à la fois) → corriger → documenter
>   - **"Qu'est-ce qui a changé ?"** : `perfmon /rel`, `Get-HotFix`
> - **Système** : `Get-WinEvent -FilterHashtable` · fiabilité · Get Help (remplace MSDT)
>   - **Sysmon INTÉGRÉ 26H2** : `Enable-WindowsOptionalFeature Sysmon` → `sysmon -i` → journal Sysmon/Operational
> - **Perfs** : `taskmgr` · `resmon` (handles, ports) · logman/perfmon (collecteur) · journal `Diagnostics-Performance` (ID 100)
> - **Réseau** : carte → IP (169.254 = pas de DHCP) → DNS → port (`Test-NetConnection`) → `pktmon`
> - **CIM à distance** : `New-CimSession` → Win32_OperatingSystem / LogicalDisk / Service / QFE
> - **Fichiers système** : `DISM /RestoreHealth` puis `sfc /scannow` · `chkdsk /scan`
> - **Traçabilité** : PSR déprécié → Capture d'écran (Win+Maj+R) + ticket documenté
