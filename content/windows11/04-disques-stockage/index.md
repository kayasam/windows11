---
title: "04. Gestion des disques et du stockage"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/04-disques-stockage"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/04-disques-stockage/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/04-disques-stockage.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Comprendre les structures de partitionnement Windows, gérer les disques et volumes avec les outils graphiques et en ligne de commande, et découvrir les espaces de stockage.
>
> **Outils :** `diskmgmt.msc`, `diskpart`, PowerShell
> **Commandes à connaître :** `Get-Disk`, `Initialize-Disk`, `New-Partition`, `Format-Volume`, `diskpart`

---

## Concepts fondamentaux

### MBR vs GPT

Les disques sont structurés selon une **table de partitions** qui décrit l'organisation de l'espace. Il en existe deux types :

| | **MBR** (Master Boot Record) | **GPT** (GUID Partition Table) |
|-|------------------------------|-------------------------------|
| **Âge** | Standard depuis les années 80 | Standard depuis les années 2000 (UEFI) |
| **Taille max disque** | 2 To | 18 Eo (exaoctets) |
| **Partitions primaires max** | 4 (dont 1 étendue) | 128 |
| **Redondance** | Aucune | Table dupliquée en début et fin de disque |
| **Démarrage** | BIOS legacy | UEFI (obligatoire pour Windows 11) |
| **Identifiant partition** | Numéro séquentiel | GUID unique |

> [!WARNING] Windows 11 impose GPT
> Windows 11 s'installe uniquement sur un disque GPT avec firmware UEFI. C'est pour cela que l'installeur crée automatiquement un disque GPT avec 4 partitions (Recovery, EFI, MSR, Windows).

### Disques basiques vs dynamiques

| | **Basique** | **Dynamique** |
|-|-------------|---------------|
| **Usage** | Standard, recommandé | Fonctionnalités avancées (RAID logiciel) |
| **Volumes** | Partitions simples | Volumes fractionnés, agrégés, en miroir, RAID-5 |
| **Compatibilité** | Universelle | Windows uniquement |
| **Recommandé** | ✅ Oui (cas général) | ⚠️ Non (remplacé par Storage Spaces) |

> [!TIP] En pratique
> Les disques dynamiques sont une technologie ancienne. Pour le RAID logiciel moderne sous Windows, Microsoft recommande les **Espaces de stockage** (Storage Spaces) plutôt que les disques dynamiques.

### Types de volumes (disque basique GPT)

![Partitions d’un disque GPT — Un disque GPT de base peut contenir une partition EFI, une partition MSR, des données et une partition de récupération.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-04-volumes-gpt.svg)

---

## Outils de gestion

### Gestionnaire de disques — diskmgmt.msc

Interface graphique principale pour la gestion des disques. Accessible via :
- `diskmgmt.msc` dans Exécuter (`Win + R`)
- Clic droit sur le menu Démarrer → **Gestion des disques**
- Gestionnaire de l'ordinateur → Stockage → Gestion des disques

**Opérations disponibles :**
- Initialiser un nouveau disque (MBR ou GPT)
- Créer, supprimer, formater des partitions
- Étendre ou réduire un volume
- Changer la lettre de lecteur


![w11-04-disques-stockage](https://cours.kaya.ovh/windows11/assets/captures/w11-04-disques-stockage.png)

### DiskPart

Outil en ligne de commande puissant, disponible depuis CMD ou PowerShell. Fonctionne en mode interactif ou via un script.

```cmd
diskpart
```

**Commandes essentielles :**

```
list disk                          ← lister les disques
select disk 1                      ← sélectionner le disque 1
list partition                     ← lister les partitions du disque sélectionné
list volume                        ← lister tous les volumes

clean                              ← effacer toute la structure du disque (DESTRUCTIF)
convert gpt                        ← convertir en GPT
convert mbr                        ← convertir en MBR

create partition primary size=10240  ← créer une partition de 10 Go
create partition primary             ← créer une partition avec l'espace restant
format fs=ntfs label="Data" quick    ← formater en NTFS
assign letter=D                      ← attribuer la lettre D:

detail disk                        ← informations détaillées
detail partition                   ← détails de la partition sélectionnée
```

> [!WARNING] DiskPart est destructif
> Les commandes `clean`, `delete partition` et `format` sont **irréversibles**. Toujours vérifier `list disk` et `select disk X` avant toute opération. Un mauvais numéro de disque peut effacer le système.

### PowerShell — module Storage

PowerShell expose toutes les opérations disque via le module `Storage` :

```powershell
# Lister les disques
Get-Disk

# Lister les partitions d'un disque
Get-Partition -DiskNumber 1

# Lister les volumes
Get-Volume

# Initialiser un disque vierge en GPT
Initialize-Disk -Number 1 -PartitionStyle GPT

# Créer une partition et l'assigner automatiquement
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter

# Créer une partition de taille fixe
New-Partition -DiskNumber 1 -Size 20GB -DriveLetter D

# Formater un volume
Format-Volume -DriveLetter D -FileSystem NTFS -NewFileSystemLabel "Data" -Confirm:$false

# Modifier la lettre d'un volume
Get-Partition -DriveLetter D | Set-Partition -NewDriveLetter E

# Étendre un volume à l'espace disponible
Resize-Partition -DriveLetter D -Size (Get-PartitionSupportedSize -DriveLetter D).SizeMax
```

---

## Systèmes de fichiers

| Système | Usage | Taille fichier max | Particularités |
|---------|-------|-------------------|----------------|
| **NTFS** | Windows (standard) | 16 To | Permissions, chiffrement EFS, journalisation, compression |
| **FAT32** | Clés USB, compatibilité | 4 Go par fichier | Compatible tous OS, pas de permissions |
| **exFAT** | Clés USB modernes, SD | 16 Eo | Remplacement de FAT32, pas de permissions |
| **ReFS** | Serveurs, grandes données | 35 Po | Résilience, auto-réparation, pas de compression/chiffrement |

> [!TIP] Quel système de fichiers choisir ?
> - **Disque interne Windows** → NTFS (toujours)
> - **Clé USB / carte SD** → exFAT (si fichiers > 4 Go) ou FAT32 (compatibilité maximale)
> - **Partage réseau / volume de données serveur** → NTFS ou ReFS

---

## Gestion des lettres de lecteur

Windows assigne des lettres aux volumes pour les rendre accessibles dans l'Explorateur :
- **A:** et **B:** réservés historiquement aux lecteurs de disquettes
- **C:** → disque système par convention
- **D:** à **Z:** → volumes de données, lecteurs optiques, lecteurs réseau

Un volume peut aussi être **monté dans un dossier** (point de montage NTFS) au lieu de recevoir une lettre — utile pour dépasser la limite de 26 lettres ou pour une arborescence plus propre.

```powershell
# Monter un volume dans un dossier au lieu d'une lettre
Add-PartitionAccessPath -DiskNumber 1 -PartitionNumber 2 -AccessPath "C:\Données"
```

---

## Espaces de stockage (Storage Spaces)

Les **Espaces de stockage** permettent de regrouper plusieurs disques physiques en un pool, puis de créer des volumes virtuels avec redondance ou agrégation.

![Espaces de stockage — Trois disques physiques alimentent un pool de stockage, qui fournit un espace de stockage sous forme de volume virtuel.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-04-espaces-stockage.svg)

> [!NOTE] Windows 11 vs Windows Server
> Sur **Windows Server**, les Espaces de stockage se gèrent depuis le **Gestionnaire de serveur** (interface riche avec supervision, alertes, remplacement de disques). Sur **Windows 11**, l'interface graphique est dans le **Panneau de configuration** — plus simple, suffisante pour un lab ou un poste de travail.

### Types de résilience

| Type | Disques min | Protection | Usage |
|------|------------|-----------|-------|
| **Simple** (aucune) | 1 | Aucune | Performance, données non critiques |
| **Miroir 2 voies** | 2 | Panne d'1 disque | Données importantes |
| **Miroir 3 voies** | 3 | Panne de 2 disques | Données critiques |
| **Parité** | 3 | Panne d'1 disque | Archivage, grandes capacités |

### En graphique — Panneau de configuration

**Panneau de configuration** → **Système et sécurité** → **Espaces de stockage**

Étapes pour créer un pool avec miroir :

1. Cliquer sur **"Créer un nouveau pool et espace de stockage"**
2. Sélectionner les disques à inclure dans le pool (les disques doivent être vides)
3. Nommer le pool (ex : `Pool-Fournil`)
4. Configurer l'espace de stockage :
   - Nom (ex : `Données-Miroir`)
   - Lettre de lecteur (ex : `F:`)
   - Système de fichiers : **NTFS**
   - Type de résilience : **Miroir bidirectionnel**
   - Taille
5. Cliquer sur **"Créer un espace de stockage"**

Windows formate automatiquement le volume et l'assigne à la lettre choisie.

> [!TIP] Accès rapide
> Taper `storage spaces` ou `espaces de stockage` dans la recherche Windows — Windows 11 redirige directement vers l'interface du Panneau de configuration.

![w11-04-disques-stockage-1](https://cours.kaya.ovh/windows11/assets/captures/w11-04-disques-stockage-1.png)

### En PowerShell

```powershell
# Lister les disques disponibles pour un pool
Get-PhysicalDisk | Where-Object CanPool -eq $true

# Créer un pool de stockage
$disques = Get-PhysicalDisk | Where-Object CanPool -eq $true
New-StoragePool -FriendlyName "Pool-Fournil" `
    -StorageSubSystemFriendlyName (Get-StorageSubSystem).FriendlyName `
    -PhysicalDisks $disques

# Créer un espace de stockage en miroir
New-VirtualDisk -StoragePoolFriendlyName "Pool-Fournil" `
    -FriendlyName "Données-Miroir" `
    -UseMaximumSize `
    -ResiliencySettingName Mirror

# Initialiser, partitionner et formater
Get-VirtualDisk -FriendlyName "Données-Miroir" | Get-Disk |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -AssignDriveLetter |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "Données-Miroir" -Confirm:$false
```

> [!WARNING] Pièges rencontrés sur le lab
> - **« The requested access path is already in use »** : la lettre demandée (`-DriveLetter E`) est déjà prise — typiquement par un lecteur DVD virtuel (ISO montée). Vérifier avec `Get-Volume` avant de choisir une lettre.
> - **`CanPool` menteur** : juste après avoir partitionné un disque, `Get-PhysicalDisk -CanPool $true` peut encore le lister, et `New-StoragePool` échoue (« espace utilisable insuffisant »). Rafraîchir avec `Update-StorageProviderCache -DiscoveryLevel Full`, et désigner les disques explicitement (`Where-Object DeviceId -in '2','3'`).
> - **Capacité réelle** : un miroir 2 voies sur 2 disques de 10 Go donne **8 Go** utilisables sur `PC01`, et non 10 : le pool réserve de l'espace pour ses métadonnées.

> [!TIP] Storage Spaces vs disques dynamiques
> Les Espaces de stockage sont le remplacement moderne des disques dynamiques : plus flexibles, gérables graphiquement ou en PowerShell, compatibles avec les fonctionnalités modernes de Windows.

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> **Table de partitions**
> - **MBR** : legacy BIOS, max 2 To, max 4 partitions primaires
> - **GPT** : UEFI, max 18 Eo, max 128 partitions — *Windows 11*
>
> **Outils**
> - `diskmgmt.msc` : interface graphique
> - `diskpart` : ligne de commande interactive (CMD/PowerShell)
> - `Get-Disk` / `New-Partition` / `Format-Volume` : PowerShell module Storage
>
> **Systèmes de fichiers**
> - **NTFS** : disques Windows (permissions, journalisation)
> - **exFAT** : clés USB modernes
> - **FAT32** : compatibilité maximale (limite 4 Go/fichier)
>
> **Espaces de stockage**
> - Pool de disques → volumes virtuels avec résilience
> - **Types** : Simple, Miroir 2/3 voies, Parité
