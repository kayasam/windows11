---
title: "07. PowerShell pour l'administrateur"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/07-powershell"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/07-powershell.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!abstract] Première découverte de PowerShell
> Aucune connaissance préalable de PowerShell n’est nécessaire. Le socle consiste à lire des commandes, les essayer une par une, demander de l’aide et filtrer des résultats simples. Le script d’inventaire de la partie D est **(bonus)** ; il n’est pas nécessaire pour suivre la formation.
> Les calculs, les colonnes calculées et la programmation ne font pas partie du socle.

> [!NOTE] Objectif
> Ouvrir Windows PowerShell, reconnaître une commande et ses paramètres, utiliser l’aide, puis afficher quelques informations du poste. On travaille dans la console avec les exemples fournis, sans écrire de programme.
>
> **Outils :** Windows PowerShell 5.1 dans Windows Terminal.
> **Commandes à découvrir :** `Get-Service`, `Get-Process`, `Get-Command`, `Get-Help`, `Select-Object`, `Sort-Object`, `Where-Object`, `Get-CimInstance`.

> [!INFO] Fil rouge — Fournil
> Un technicien doit vérifier les services et retrouver les informations d’un poste. Nous allons lire ces informations avec des commandes courtes. Les scripts complets utilisés plus tard dans la formation sont fournis : il n’est pas demandé de savoir les programmer.

---

## 1. Ouvrir la bonne console

**Windows Terminal** est la fenêtre qui héberge des onglets. **Windows PowerShell** est l’interpréteur qui comprend nos commandes. Dans Terminal, sélectionner **Windows PowerShell** pour ce chapitre.

```powershell
$PSVersionTable.PSVersion
```

Cette commande affiche la version de PowerShell ouverte. Dans le lab, on utilise Windows PowerShell **5.1**, déjà présent. Il n’est pas nécessaire d’installer PowerShell 7 ou un éditeur pour commencer.

> [!TIP] Avancer une commande à la fois
> Saisir une ligne, appuyer sur Entrée et observer le résultat avant de poursuivre. La touche **Tabulation** aide à compléter un nom ; la **flèche vers le haut** rappelle une commande déjà saisie. Utiliser **Ctrl+C** pour interrompre une commande en cours.

---

## 2. Lire une commande et ses paramètres

Une cmdlet suit généralement la forme **Verbe-Nom** :

| Commande | Ce qu’elle demande |
|---|---|
| `Get-Service` | Afficher les services |
| `Get-Process` | Afficher les processus |
| `Get-NetAdapter` | Afficher les cartes réseau |
| `Get-ChildItem` | Afficher le contenu du dossier courant |
| `Get-Date` | Afficher la date et l’heure |

Un **paramètre** précise la demande :

```powershell
Get-Service -Name Spooler
```

- `Get-Service` : la commande.
- `-Name` : le paramètre qui choisit le service par son nom.
- `Spooler` : la valeur, ici le spouleur d’impression.

Comparer avec :

```powershell
Get-Service -Name Sp*
```

L’étoile `*` permet ici de rechercher les services dont le nom commence par `Sp`. Une recherche peut donc renvoyer plusieurs lignes.

> [!WARNING] Lire avant d’exécuter
> Les commandes de consultation du socle ne doivent pas modifier la configuration. Une commande qui commence par `Stop-`, `Remove-` ou `Set-` peut changer l’état du poste : ne pas la lancer uniquement parce qu’elle apparaît dans l’aide.

---

## 3. Trouver une commande et son aide

```powershell
# Chercher les commandes portant sur les services
Get-Command -Noun Service

# Lire les exemples d’une commande, sans l’exécuter
Get-Help Get-Service -Examples
```

`Get-Command` aide à trouver **quelle commande utiliser**. `Get-Help` explique **comment l’utiliser**.

L’aide locale peut être incomplète si elle n’a pas été téléchargée. On peut utiliser les exemples du cours ou la documentation en ligne. Le téléchargement de l’aide avec `Update-Help` n’est pas un prérequis du TP.

---

## 4. Lire les colonnes d’un résultat

```powershell
Get-Service
```

Observer les colonnes :

| Colonne | Signification |
|---|---|
| `Status` | État : `Running` ou `Stopped` |
| `Name` | Nom technique utilisé dans les commandes |
| `DisplayName` | Nom affiché, plus lisible |

Chaque ligne représente un **objet**, ici un service. Les colonnes correspondent à des **propriétés** de cet objet. Pour débuter, il suffit de savoir choisir les colonnes utiles et lire leurs valeurs.

---

## 5. Le pipeline : transmettre un résultat

La barre verticale **`|`**, appelée pipeline, transmet le résultat d’une commande à la suivante. Lire la ligne **de gauche à droite**.

### Choisir les colonnes

```powershell
Get-Service | Select-Object Name, Status
```

Lire : « affiche les services, puis conserve les colonnes Name et Status ».

### Trier

```powershell
Get-Service | Sort-Object Name
```

Lire : « affiche les services, puis trie-les par nom ».

### Filtrer avec une seule condition

```powershell
Get-Service | Where-Object Status -eq Stopped
```

Lire : « affiche les services, puis garde ceux dont Status est égal à Stopped ».

`-eq` signifie **égal à**. On ne demande pas ici de combiner plusieurs conditions ni d’écrire un bloc de programmation.

### Combiner progressivement

Commencer par exécuter `Get-Process` seul, puis ajouter le tri, puis la sélection :

```powershell
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 Name, WorkingSet64
```

La ligne affiche les cinq processus les plus consommateurs de mémoire. `WorkingSet64` est exprimé en **octets** : on conserve la valeur fournie, **sans conversion, sans arrondi et sans colonne calculée**. `-Descending` trie du plus grand au plus petit ; `-First 5` garde les cinq premiers résultats.

Pour simplement compter les processus :

```powershell
Get-Process | Measure-Object
```

Lire la valeur **Count** du résultat. Les autres statistiques ne sont pas demandées.

---

## 6. Lire les informations du poste avec une commande fournie

Windows expose des informations de matériel et de système. **`Get-CimInstance`** permet de les consulter. Pour cette première découverte, les noms à utiliser sont fournis ; il n’est pas demandé de les trouver ou de les mémoriser.

```powershell
# Numéro de série du poste
Get-CimInstance Win32_BIOS | Select-Object SerialNumber

# Fabricant et modèle
Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model

# Nom et version du système, dernier démarrage
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, LastBootUpTime
```

Le but est de **lire le résultat et expliquer son utilité** pour un inventaire ou une demande au support. Aucun calcul de RAM ou d’espace disque n’est demandé dans le socle.

---

## 7. Aller plus loin (bonus)

Ces éléments peuvent être consultés après les premières manipulations. Ils ne sont pas nécessaires pour réussir le socle.

| Notion | Utilité |
|---|---|
| `Get-Member` | Explorer les propriétés d’un objet |
| `Export-Csv` / `Import-Csv` | Enregistrer puis relire des résultats structurés |
| Un fichier `.ps1` | Réunir plusieurs commandes dans un script |
| Des variables et `param(...)` | Conserver des valeurs et rendre un script configurable |
| Un objet personnalisé | Regrouper des informations dans un inventaire |
| PowerShell 7 et VS Code | Découvrir un autre moteur ou un éditeur de scripts |

La **partie D du TP**, entièrement **(bonus)**, propose un script d’inventaire. La construction d’un tel script et ses conversions ne sont pas demandées aux élèves qui découvrent PowerShell.

### Exécuter un script fourni (bonus)

Une commande saisie directement dans la console et un fichier `.ps1` ne sont pas traités de la même manière par la politique d’exécution. Avant de lancer un script, vérifier sa provenance et lire son contenu.

```powershell
Get-ExecutionPolicy -List
```

Si les consignes du lab le demandent et qu’aucune stratégie d’entreprise ne l’interdit, le réglage peut être limité à l’utilisateur :

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Une stratégie d’entreprise peut être prioritaire sur le réglage local. `RemoteSigned` peut encore bloquer un fichier marqué comme provenant d’Internet : lire et vérifier le fichier avant d’envisager son déblocage. La politique d’exécution n’est pas une garantie de sécurité du script.

---

## Récapitulatif

> [!summary] À retenir pour cette première découverte
> - Windows Terminal héberge la console ; Windows PowerShell exécute les commandes.
> - Une commande a un nom, puis éventuellement des paramètres et leurs valeurs.
> - `Get-Command` trouve une commande ; `Get-Help` explique son usage.
> - `|` transmet le résultat à la commande suivante.
> - `Select-Object` choisit les colonnes, `Sort-Object` trie, `Where-Object` filtre.
> - Utiliser les commandes CIM fournies pour lire les informations du poste.
> - **Aucun calcul, aucune écriture de script ni installation de PowerShell 7 n’est exigé dans le socle.**
