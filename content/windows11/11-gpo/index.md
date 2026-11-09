---
title: "11. Stratégies de groupe et gestion centralisée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/11-gpo"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/11-gpo.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Centraliser la configuration des postes du domaine avec les **stratégies de groupe** : comprendre l'ordre d'application, distinguer paramètres ordinateur et utilisateur, cibler une GPO (liaison, filtrage, préférences), diagnostiquer avec `gpresult`. Mettre en place les GPO de sécurité modernes : **Windows LAPS**, sauvegarde des clés **BitLocker** dans AD, administrateurs locaux, anneau Windows Update. Situer **Intune / Entra ID** face aux GPO.
>
> **Outils :** GPMC (`gpmc.msc`, via RSAT), éditeur de GPO, `gpupdate`, `gpresult`, `rsop.msc`
> **Commandes à connaître :** `New-GPO`, `New-GPLink`, `Set-GPRegistryValue`, `Set-GPPermission`, `Get-GPResultantSetOfPolicy`, `Get-LapsADPassword`

> [!INFO] Fil rouge — Fournil
> Deux GPO sur le lab (créées et vérifiées le 08/11/2026) :
> - **GPO-Postes-Securite** liée à `OU=Ordinateurs` : LAPS, BitLocker → AD, `GG-Admins-Postes` admin local, anneau WU +7 jours ;
> - **GPO-Boulangerie-Utilisateurs** liée à `OU=Utilisateurs`, filtrée sur `G-Boulangerie` : lecteur `P:` → `\\SRV01\Commun`, Panneau de configuration interdit.

---

## 1. Qu'est-ce qu'une GPO ?

Une **GPO** (*Group Policy Object*) est un ensemble de paramètres stocké dans le domaine et appliqué automatiquement aux **ordinateurs** et aux **utilisateurs** situés dans les conteneurs où elle est liée.

![Les deux parties d’une GPO — Le contrôleur de domaine conserve l’objet GPO dans Active Directory et les fichiers de la stratégie dans SYSVOL.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-11-composition-gpo.svg)

Le poste télécharge et applique les GPO :
- **au démarrage** (paramètres ordinateur) et **à l'ouverture de session** (paramètres utilisateur) ;
- puis **toutes les 90 minutes** (± 30 min aléatoires) en arrière-plan ;
- ou immédiatement avec `gpupdate /force`.

| | Configuration **ordinateur** | Configuration **utilisateur** |
|-|-----------------------------|------------------------------|
| S'applique à | Les ordinateurs de l'UO | Les utilisateurs de l'UO |
| Quand | Démarrage + toutes les 90 min | Ouverture de session + toutes les 90 min |
| Exemples | Pare-feu, BitLocker, LAPS, Windows Update, droits | Lecteurs réseau, fond d'écran, menu Démarrer, restrictions |
| Registre | `HKLM` | `HKCU` |

> [!WARNING] Une GPO s'applique selon l'emplacement de l'objet
> Les paramètres **ordinateur** d'une GPO liée à l'UO *Utilisateurs* ne s'appliquent à rien : il n'y a pas d'ordinateurs dans cette UO. Et inversement. (Le *traitement en boucle de rappel* — *loopback* — permet d'appliquer des paramètres utilisateur selon l'UO de l'**ordinateur** : utile pour un poste de caisse ou un kiosque.)

---

## 2. Ordre d'application : LSDOU

![Ordre d’application LSDOU — Les stratégies s’appliquent dans l’ordre Local, Site, Domaine, UO parente et UO enfant. En règle générale, la dernière prime en cas de conflit.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-11-ordre-lsdou.svg)

**La dernière appliquée gagne** en cas de conflit. Deux exceptions :

| Mécanisme | Effet |
|-----------|-------|
| **Appliqué** (*Enforced*) sur une liaison | La GPO l'emporte sur les GPO des UO enfants et ne peut pas être bloquée |
| **Bloquer l'héritage** sur une UO | Les GPO des niveaux supérieurs ne descendent plus (sauf celles « Appliquées ») |

> [!WARNING] Les stratégies de mot de passe du domaine
> La stratégie de mot de passe des **comptes du domaine** ne se règle que dans une GPO liée **au domaine** (en pratique la *Default Domain Policy*). Liée à une UO, elle ne s'appliquerait qu'aux comptes **locaux** des ordinateurs de cette UO. Pour des règles différentes selon les comptes : les *stratégies de mot de passe affinées* (PSO).

---

## 3. Les outils

| Outil | Rôle |
|-------|------|
| **GPMC** — `gpmc.msc` | Créer, lier, filtrer, sauvegarder, modéliser les GPO. Sur un poste Windows 11 : capacité RSAT `Rsat.GroupPolicy.Management.Tools` |
| **Éditeur de GPO** | Modifier le contenu d'une GPO (clic droit → Modifier depuis GPMC) |
| `gpedit.msc` | Stratégie **locale** du poste (n'existe pas sur Home) |
| `gpupdate /force` | Réappliquer immédiatement |
| `gpresult /r` · `/h rapport.html` | **Ce qui est appliqué** à ce poste/cet utilisateur, et pourquoi une GPO est refusée |
| `rsop.msc` | Jeu de stratégies résultant, en console |
| Module PowerShell `GroupPolicy` | `New-GPO`, `New-GPLink`, `Set-GPRegistryValue`, `Set-GPPermission`, `Backup-GPO`… |

```powershell
# Installer GPMC sur PC01 (Feature on Demand, accès Windows Update requis)
Add-WindowsCapability -Online -Name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
```

---

## 4. Cibler une GPO

![Ciblage d’une GPO — La liaison définit le périmètre, le filtrage de sécurité règle le droit Appliquer, WMI sélectionne des postes et le ciblage par élément affine les préférences.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-11-ciblage-gpo.svg)

### Filtrage de sécurité

Par défaut, *Utilisateurs authentifiés* a **Lire** + **Appliquer**. Pour réserver une GPO à un groupe :

```powershell
Set-GPPermission -Name "GPO-Boulangerie-Utilisateurs" -TargetName "Utilisateurs authentifiés" -TargetType Group -PermissionLevel GpoRead -Replace
Set-GPPermission -Name "GPO-Boulangerie-Utilisateurs" -TargetName "G-Boulangerie" -TargetType Group -PermissionLevel GpoApply
```

> [!WARNING] Garder la **lecture** pour Utilisateurs authentifiés
> Depuis le correctif MS16-072 (2016), les GPO utilisateur sont lues avec le **compte ordinateur**. Retirer complètement *Utilisateurs authentifiés* (au lieu de ne lui laisser que *Lire*) empêche la GPO de s'appliquer à quiconque — erreur encore très répandue dans les tutoriels.

### Filtre WMI

```
SELECT * FROM Win32_OperatingSystem WHERE BuildNumber >= 22000      ← Windows 11 uniquement
```

Coûteux (requête évaluée à chaque application) : à utiliser avec parcimonie.

---

## 5. Stratégies et préférences

| | **Stratégies** (*Policies*) | **Préférences** (*Preferences*, GPP) |
|-|-----------------------------|--------------------------------------|
| Où | Modèles d'administration, Paramètres de sécurité | `… → Préférences` |
| Comportement | **Imposé**, grisé pour l'utilisateur, retiré si la GPO disparaît | **Proposé** une fois (ou à chaque application), l'utilisateur peut modifier ; reste en place (« tatouage ») |
| Exemples | Interdire le Panneau de configuration, report WU, BitLocker | **Lecteurs mappés**, raccourcis, imprimantes, tâches planifiées, valeurs de registre, groupes locaux |
| Ciblage fin | Non (filtrage de la GPO entière) | **Ciblage au niveau de l'élément** (groupe, OS, plage IP…) |

Sur le lab, le lecteur `P:` est une **préférence** (*Configuration utilisateur → Préférences → Paramètres Windows → Mappages de lecteurs*, action « Mettre à jour », `\\SRV01\Commun`, lettre `P`) :

![w11-11-lecteur-p-gpo](https://cours.kaya.ovh/windows11/assets/captures/w11-11-lecteur-p-gpo.png)

*Session `FOURNIL\stagiaire` sur `PC01` : « Commun (P:) » monté par GPO. Le cadenas sur `C:` rappelle que BitLocker est actif.*

---

## 6. Les GPO de sécurité d'un parc moderne

### Administrateurs locaux maîtrisés

Objectif : `GG-Admins-Postes` (les techniciens) administrateur de tous les postes, et **pas** les Admins du domaine en usage courant.

| Méthode | Où | Remarque |
|---------|----|---------|
| **Groupes restreints** → « Ce groupe est membre de : Administrateurs » | Paramètres de sécurité → Groupes restreints | Ajoute sans retirer les autres membres (utilisé sur le lab) |
| **Préférences → Utilisateurs et groupes locaux** | Préférences | Plus souple : ajouter/retirer, ciblage par élément |

Résultat sur `PC01` après `gpupdate` :

```
Name                      PrincipalSource
----                      ---------------
FOURNIL\Admins du domaine ActiveDirectory
FOURNIL\GG-Admins-Postes  ActiveDirectory    ← ajouté par GPO-Postes-Securite
PC01\admin                Local
PC01\Administrateur       Local
```

### Windows LAPS

**Windows LAPS** (intégré à Windows depuis 2023 — l'ancien « LAPS legacy » à installer en MSI est obsolète) donne à **chaque poste un mot de passe d'administrateur local unique**, aléatoire, changé régulièrement, stocké dans AD (ou Entra ID) et lisible seulement par les personnes autorisées.

```powershell
# Une fois, sur le domaine
Update-LapsADSchema
Set-LapsADComputerSelfPermission -Identity "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"
```

GPO : *Configuration ordinateur → Modèles d'administration → Système → LAPS* → **Configurer le répertoire de sauvegarde des mots de passe** = *Active Directory* ; longueur 14 ; âge 30 jours.

```powershell
Get-LapsADPassword -Identity PC01 -AsPlainText
```
```
ComputerName        : PC01
Account             : Administrateur
Password            : +X+]3A,&#3X;rj
PasswordUpdateTime  : 08/11/2026 07:15:06
ExpirationTimestamp : 08/12/2026 07:15:06
```

Journal du poste : *Applications et services → Microsoft → Windows → LAPS → Operational* (10018 « LAPS a mis à jour Active Directory », 10020 « … le compte d'administrateur local »).

> [!WARNING] LAPS gère l'Administrateur intégré… qui est désactivé
> Par défaut, LAPS gère le compte RID 500 (`Administrateur`) — désactivé sur Windows 11. Le mot de passe est bien changé, mais inutilisable tant que le compte est désactivé. Deux choix : activer ce compte (par GPO), ou indiquer un autre compte dans **Nom du compte administrateur à gérer** (depuis 24H2, LAPS peut même **créer et gérer** ce compte lui-même : *Configurer la gestion automatique des comptes*).

### Sauvegarde des clés BitLocker dans AD

GPO : *Composants Windows → Chiffrement de lecteur BitLocker → Lecteurs du système d'exploitation → Sélectionner la méthode de récupération…* → **Enregistrer les informations de récupération dans AD DS** + **Ne pas activer BitLocker tant que les informations ne sont pas stockées**.

> [!NOTE] La GPO ne rattrape pas l'existant
> Elle s'applique aux **nouveaux** protecteurs. Pour un poste déjà chiffré (comme `PC01`, TP 09) :
> ```powershell
> $kp = (Get-BitLockerVolume C:).KeyProtector | Where-Object KeyProtectorType -eq RecoveryPassword
> Backup-BitLockerKeyProtector -MountPoint C: -KeyProtectorId $kp.KeyProtectorId
> ```
> La clé apparaît alors sous l'objet ordinateur (`msFVE-RecoveryInformation`, onglet **Récupération BitLocker** de la console AD).

### Anneau Windows Update

Les stratégies *Windows Update client policies* (chapitre 08) : une GPO par anneau. Sur le lab : report qualité **7 jours** (`DeferQualityUpdatesPeriodInDays = 7`).

---

## 7. Diagnostiquer

```powershell
gpupdate /force
gpresult /r                                      # résumé ordinateur + utilisateur
gpresult /scope computer /r
gpresult /user stagiaire /scope user /r
gpresult /h C:\Temp\rsop.html                    # rapport complet, lisible
Get-GPResultantSetOfPolicy -ReportType Html -Path C:\Temp\rsop.html
```

Extrait réel sur `PC01` :
```
Objets Stratégie de groupe appliqués
    GPO-Postes-Securite
    Default Domain Policy
```

| Symptôme | Causes classiques |
|----------|-------------------|
| GPO absente de `gpresult` | Mauvaise UO (poste resté dans `CN=Computers`), liaison désactivée, héritage bloqué |
| GPO « refusée (sécurité) » | Filtrage de sécurité : l'objet n'a pas *Appliquer* — ou *Utilisateurs authentifiés* retiré entièrement |
| GPO « refusée (vide) » | La partie ordinateur/utilisateur concernée est vide |
| Rien ne s'applique | DNS du poste ≠ DC, SYSVOL inaccessible, heure décalée (Kerberos) |

Journal : *Applications et services → Microsoft → Windows → GroupPolicy → Operational*.

---

## 8. Et dans le cloud : Intune et Entra ID

| | GPO (AD sur site) | Intune (Microsoft Entra ID) |
|-|-------------------|------------------------------|
| Prérequis | Poste joint à AD, **en ligne de vue** d'un DC (ou VPN) | Poste joint à Entra (ou hybride), simple accès Internet |
| Contenu | Modèles d'administration, sécurité, préférences | Profils de configuration (*Settings catalog*, CSP), conformité, applications, **ADMX importables** |
| Postes nomades | Mal servis (pas de DC joignable) | Conçu pour |
| Déploiement de Windows | Image + GPO | **Autopilot** (chapitre 16) |
| Rapports | `gpresult` poste par poste | Console de conformité centralisée |

**Jonction hybride** (*Microsoft Entra hybrid join*) : le poste est joint à AD **et** enregistré dans Entra ID grâce à **Entra Connect** ; on peut alors basculer progressivement des GPO vers Intune (*co-management*). Outil d'aide : **Group Policy Analytics** dans Intune (importe une sauvegarde de GPO et indique quels paramètres ont un équivalent cloud).

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> - GPO = objet AD + fichiers SYSVOL · ordinateur (démarrage) / utilisateur (session) · 90 min
> - **LSDOU** : Local → Site → Domaine → UO → UO enfant (le dernier gagne) · Appliqué / Bloquer l'héritage
> - **Ciblage** : liaison (UO) + filtrage de sécurité (garder LIRE pour Utilisateurs authentifiés) + WMI
> - Stratégies (imposées) vs Préférences (lecteurs, groupes locaux, tâches, ciblage par élément)
> - **Sécurité parc** : Groupes restreints/GPP → GG-Admins-Postes · Windows LAPS (`Get-LapsADPassword`)
>   - BitLocker → AD (`Backup-BitLockerKeyProtector` pour l'existant) · anneau WU
> - **Diagnostic** : `gpupdate /force` · `gpresult /r /h` · journal GroupPolicy/Operational
> - **Cloud** : Intune + Entra ID (hybride, Group Policy Analytics)
