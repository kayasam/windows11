---
title: "08. Windows Update et gestion des mises à jour"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/08-mises-a-jour"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/08-mises-a-jour.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Comprendre les types de mises à jour de Windows 11, les piloter sur un poste puis sur un parc (stratégies *Windows Update client policies*), connaître le paysage 2026 (WSUS déprécié, Autopatch, Hotpatch) et ne pas oublier les **applications** et les **pilotes**.
>
> **Outils :** Paramètres → Windows Update, `gpedit.msc`, WinGet
> **Commandes à connaître :** `Get-HotFix`, `Get-WindowsUpdateLog`, `Microsoft.Update.Session` (COM), `PSWindowsUpdate`, `winget upgrade --all`

> [!INFO] Fil rouge — Fournil
> `PC01` sert de poste « pilote » : il reçoit les mises à jour en premier, les autres postes du Fournil 7 jours plus tard.

---

## Windows Update


**Windows Update** est le service natif de distribution des mises à jour Windows. Deux grandes catégories :

| Type | Contenu | Fréquence |
|------|---------|-----------|
| **Mise à jour de qualité** (quality update) | Correctifs de sécurité, correctifs de bugs | Mensuelle (Patch Tuesday, 2ᵉ mardi du mois) |
| **Mise à jour de fonctionnalité** (feature update) | Nouvelle version annuelle de Windows 11 (ex : 25H2 → 26H2), via un **package d'activation** depuis 24H2/25H2 | 1 fois par an (septembre-octobre) |
| **Mise à jour facultative** (« non-security preview », 4ᵉ semaine) | Nouveautés et correctifs non liés à la sécurité, en avant-première du Patch Tuesday suivant | Mensuelle, au choix de l'utilisateur ou de la stratégie |
| **Pilotes, définitions Defender** | Pilotes constructeurs, signatures antivirus | Variable / plusieurs fois par jour |

### Configuration de base

**Accès :** Paramètres → Windows Update

![w11-08-mises-a-jour-restrictions](https://cours.kaya.ovh/windows11/assets/captures/w11-08-mises-a-jour-restrictions.png)

| Option | Rôle |
|--------|------|
| **Recevez les dernières mises à jour dès qu'elles sont disponibles** | Reçoit en avance les mises à jour non liées à la sécurité (fonctionnalités, améliorations), avant leur déploiement progressif à tous les postes — l'inverse d'un report |
| **Suspendre les mises à jour** | Reporte **toutes** les mises à jour par tranches sélectionnables (1 semaine ci-dessus), cumulables jusqu'à 5 semaines au total |
| **Historique des mises à jour** | Liste des mises à jour installées, avec possibilité de désinstaller les plus récentes |
| **Options avancées** | Sous-page : heures d'activité, redémarrage, mises à jour facultatives, stratégies appliquées… |
| **Programme Windows Insider** | Inscription à un canal de préversion (Dev/Beta/Release Preview) |

**Options avancées** (sous-page) :

![w11-08-mises-a-jour-restrictions-1](https://cours.kaya.ovh/windows11/assets/captures/w11-08-mises-a-jour-restrictions-1.png)

| Option | Rôle |
|--------|------|
| **Obtenir des mises à jour pour d'autres produits Microsoft** | Inclut Office et d'autres produits Microsoft dans le cycle Windows Update |
| **Me mettre à jour** | Redémarre dès que possible pour terminer une mise à jour en attente, même pendant les heures d'activité (avec notification 15 min avant) |
| **Télécharger les mises à jour par des connexions limitées** | Autorise le téléchargement même sur une connexion mesurée (data limitée) |
| **M'informer lorsqu'un redémarrage est requis** | Notification avant tout redémarrage automatique |
| **Heures d'activité** | Plage horaire pendant laquelle Windows évite de redémarrer automatiquement |
| **Mises à jour facultatives** | Pilotes et fonctionnalités proposés mais non installés automatiquement |
| **Optimisation de la distribution** | Partage de bande passante en pair-à-pair (P2P) pour les téléchargements de mise à jour |
| **Récupération** | Réinitialiser le poste, démarrage avancé, revenir à la version précédente |
| **Redémarrer des applications** | Rouvre automatiquement les applications ouvertes après un redémarrage lié à une mise à jour |
| **Stratégies de mise à jour configurées** | Affiche en lecture seule les stratégies imposées par GPO/Intune (report, etc.) |

> [!NOTE] Pas de "Différer les mises à jour" en tant que tel dans l'interface
> Sur les versions récentes de Windows 11, il n'y a plus de curseur "différer" directement dans Paramètres. Le report de mises à jour se configure via **Windows Update for Business** (GPO/Intune, voir section suivante) — une fois appliqué, il apparaît en lecture seule dans **Options avancées → Stratégies de mise à jour configurées**, mais ne se règle pas depuis cet écran.

> [!TIP] Pourquoi reporter les mises à jour ?
> Une mise à jour de fonctionnalité peut introduire une régression sur un parc de postes. Reporter permet de laisser la communauté et Microsoft identifier les problèmes avant que la mise à jour n'atteigne les postes de production.

### Commandes utiles

```cmd
:: Forcer une recherche de mises à jour (voir avertissement ci-dessous)
usoclient StartScan
```

> [!WARNING] `usoclient` est déprécié et souvent inopérant sur Windows 11 récent
> `usoclient` (Update Session Orchestrator) n'a jamais été officiellement documenté par Microsoft, et depuis plusieurs mises à jour cumulatives, il est explicitement **déprécié** : exécuté tel quel, il peut ne rien faire et se contenter d'afficher un message de dépréciation dans le journal, sans réellement déclencher le scan. Ne pas s'y fier pour une automatisation en production — utiliser plutôt l'API native ci-dessous, le module `PSWindowsUpdate`, ou l'app Paramètres.

**Alternative 100% native (API COM, aucun module à installer) :**

```powershell
# Forcer une recherche de mises à jour via l'API Windows Update, sans passer par usoclient
$session = New-Object -ComObject Microsoft.Update.Session
$searcher = $session.CreateUpdateSearcher()
$result = $searcher.Search("IsInstalled=0")
$result.Updates | Select-Object Title, IsDownloaded, IsMandatory
```

Cette API COM (`Microsoft.Update.Session`) est intégrée à Windows depuis toujours — c'est ce que Paramètres → Windows Update et `usoclient` utilisent en coulisses. Elle permet aussi de scripter le téléchargement et l'installation, mais demande plus de code (création d'un `UpdateDownloader` puis d'un `UpdateInstaller`) que le simple scan ci-dessus.

> [!TIP] Module `PSWindowsUpdate` pour un pilotage complet en PowerShell
> Il n'existe **aucune cmdlet native** couvrant scan + téléchargement + installation en une ligne. Le module communautaire `PSWindowsUpdate` (PowerShell Gallery) comble ce manque avec des cmdlets prêtes à l'emploi :
> ```powershell
> Install-Module PSWindowsUpdate -Force
> Get-WindowsUpdate                      # scan
> Install-WindowsUpdate -AcceptAll -AutoReboot   # télécharge + installe
> ```
> Ce n'est pas un module Microsoft officiel, mais il est très largement utilisé en entreprise et bien plus fiable que `usoclient`.

```powershell
# Consulter l'historique des mises à jour installées
Get-HotFix | Sort-Object InstalledOn -Descending

# Générer un journal lisible de Windows Update (fichier .log sur le Bureau par défaut)
Get-WindowsUpdateLog
```

---

## Gérer les mises à jour d'un parc

### Le vocabulaire a changé

| Ancien nom | Nom 2026 | Ce que c'est |
|-----------|----------|--------------|
| Windows Update for Business (WUfB) | **Windows Update client policies** | Les stratégies (GPO/Intune) de report, d'échéance et de redémarrage — gratuites, Pro et plus |
| WUfB *deployment service* | Intégré à **Windows Autopatch** | Service cloud d'orchestration des anneaux (licences Microsoft 365 E3/E5 ou Business Premium) |
| WSUS | **Déprécié** (septembre 2024) | Fonctionne toujours dans Windows Server 2025, mais plus aucune évolution |

![Sources et pilotage des mises à jour — Windows Update et Autopatch utilisent le cloud Microsoft. WSUS et ConfigMgr utilisent un serveur interne.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-08-sources-mises-a-jour.svg)

### Principe des anneaux de déploiement (rings)

![Anneaux de déploiement — Le déploiement démarre sur le pilote, s’élargit à la production après 7 jours et atteint les postes critiques après 14 jours.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-08-anneaux-windows-update.svg)

On crée **une GPO par anneau**, filtrée sur un groupe de postes (chapitre 11).

### Configuration via GPO

Les paramètres sont rangés sous le nœud **Windows Update**, en **quatre** sous-dossiers (libellés relevés dans l'ADMX de la 26H2) :

![Stratégies GPO pour Windows Update — Sous Windows Update, quatre dossiers distinguent l’expérience utilisateur, WSUS, les mises à jour Windows Update et les stratégies héritées.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-08-gpo-windows-update.svg)

| Dossier | Paramètre | Rôle |
|---------|-----------|------|
| … proposées de Windows Update | **Choisir quand recevoir les mises à jour qualité** | Report de 0 à 30 jours |
| | **Choisir quand recevoir les versions d'évaluation et les mises à jour des fonctionnalités** | Report de 0 à 365 jours |
| | **Sélectionner la version de la mise à jour des fonctionnalités cible** | Bloquer le parc sur `Windows 11` / `25H2` tant que la 26H2 n'est pas validée |
| | **Ne pas inclure les pilotes avec les mises à jour Windows** | Les pilotes passent par un autre canal (constructeur, Intune) |
| | **Activer les mises à jour facultatives** | Fonctionnalités en déploiement progressif |
| Gérer l'expérience utilisateur final | **Specify deadline for automatic updates and restarts…** (qualité / fonctionnalités) | Échéance : au-delà, installation et redémarrage forcés (libellé non traduit dans l'ADMX français) |
| | **Spécifier une plage d'heures d'activité pour les redémarrages automatiques** | Protège les heures de travail |
| | **Supprimer l'accès à la fonctionnalité Interrompre les mises à jour** | L'utilisateur ne peut plus « suspendre 5 semaines » |

> [!NOTE] Ne pas confondre avec le dossier WSUS
> Le dossier **« … de Windows Server Update Service »** contient « Spécifier l'emplacement intranet du service de mise à jour Microsoft ». Le configurer **sans** serveur WSUS bloque toute mise à jour du poste : erreur classique quand une vieille GPO traîne dans un domaine.

### Clés de registre correspondantes

```powershell
# Ce qui est réellement appliqué par GPO
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction SilentlyContinue
# DeferQualityUpdatesPeriodInDays, DeferFeatureUpdatesPeriodInDays, TargetReleaseVersionInfo, ExcludeWUDriversInQualityUpdate…
```

Et dans **Paramètres → Windows Update → Options avancées → Stratégies de mise à jour configurées** (lecture seule).

> [!WARNING] Pro minimum
> Windows 11 Home ne lit pas ces stratégies : seul « Suspendre les mises à jour » existe.

---

## Les nouveautés à connaître

| Technologie | Pour qui | Principe |
|-------------|----------|----------|
| **Package d'activation** | Toutes éditions | La nouvelle version annuelle (26H2) s'active en un redémarrage (chapitre 01) |
| **Hotpatch** | **Enterprise** 24H2+ (Intune/Autopatch), processeurs compatibles | Correctifs de sécurité appliqués **en mémoire, sans redémarrage** la plupart des mois ; redémarrage seulement aux mois « de base » (un par trimestre) |
| **Windows Autopatch** | M365 E3/E5, Business Premium | Microsoft gère les anneaux, les échéances, Office, Edge, Teams et les pilotes |
| **Orchestration des mises à jour d'applications** | 26H2 | Les applications compatibles peuvent faire passer leurs mises à jour par le moteur de Windows Update |
| **Point-in-time restore** | 24H2+ | Retour arrière rapide après une mise à jour qui casse (chapitre 18) |

---

## Ne pas oublier les applications et les pilotes

Windows Update ne met à jour **que Windows** (et, si l'option est cochée, Office/Edge). Un poste « à jour » peut avoir un 7-Zip ou un lecteur PDF vulnérable depuis deux ans.

| Quoi | Comment |
|------|---------|
| Logiciels Win32 | `winget upgrade --all` (chapitre 05), Intune, Autopatch |
| Applications du Store | Store → Téléchargements et mises à jour ; `winget upgrade` les voit aussi |
| Microsoft 365 Apps | Canal de mise à jour d'Office (chapitre 17) |
| Pilotes et firmwares | Windows Update (mises à jour facultatives), outil constructeur (Dell Command Update, HP Image Assistant, Lenovo Vantage), Autopatch |

Sur `PC01` fraîchement installé : **8 logiciels** à mettre à jour selon `winget upgrade` (TP 05).

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> **Windows Update**
> - Qualité (mensuelle, Patch Tuesday) vs Fonctionnalité (annuelle, package d'activation)
> - Suspendre (5 sem. max) · Heures d'activité · `usoclient` (déprécié) → API COM / PSWindowsUpdate
> - `Get-HotFix` · `Get-WindowsUpdateLog` · Fiabilité (`perfmon /rel`) pour les échecs
>
> **Parc**
> - "Windows Update client policies" (ex-WUfB) : GPO Composants Windows → Windows Update (4 dossiers)
> - Report qualité 0-30 j · fonctionnalités 0-365 j · version cible · exclure les pilotes · échéances
> - **WSUS** : déprécié (2024) · Autopatch : cloud, licences M365 · Hotpatch : Enterprise, sans redémarrage
> - **Anneaux** : pilote → large → critique (une GPO par anneau)
>
> **Applications et pilotes**
> - `winget upgrade --all` · outils constructeurs · Autopatch
