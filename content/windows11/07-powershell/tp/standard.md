---
title: "TP 07. PowerShell pour l'administrateur"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/07-powershell"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/07-powershell.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/standard" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/standard-corrigev2">Afficher les corrections</a></nav>

> [!abstract] Parcours TSSR
> Socle débutant : lire des commandes, utiliser l’aide et essayer un pipeline simple avec les exemples du cours. Aucun calcul ni script à écrire n’est requis. Les parties D, E et F sont entièrement (bonus).

> Chapitres associés : [07. PowerShell pour l'administrateur](https://cours.kaya.ovh/windows11/windows11/07-powershell/)

---

## Objectifs

- Trouver une commande et lire ses exemples avec le cours ouvert
- Lire un pipeline simple : choisir des colonnes, trier et filtrer avec une seule condition
- Lire les informations du poste avec les commandes CIM fournies
- Écrire un script paramétré qui produit un inventaire CSV (bonus)
- Installer PowerShell 7 correctement et comprendre la politique d'exécution (bonus)

---

## Prérequis

- `PC01`, session `admin`, Windows Terminal

---

## Partie A — Se repérer

**A1.** Quelle version de PowerShell s'ouvre par défaut ? Comment le vérifier ?

**A2.** Liste toutes les cmdlets dont le nom (partie « Nom ») est `Service`.

**A3.** Affiche uniquement les **exemples** de l'aide de `Get-Service`. Que faire si l'aide est minimale ?

**A4.** Exécute `Get-Service`. Repère les colonnes `Status`, `Name` et `DisplayName`. Laquelle donne l’état du service ? Quelle différence entre le nom technique et le nom affiché ?

---

## Partie B — Pipeline

**B1.** Exécute `Get-Process`, puis `Get-Process | Measure-Object`. Combien de processus indique la valeur `Count` ?

**B2.** Avec la commande fournie dans le cours, affiche les cinq processus les plus consommateurs de mémoire avec `Name` et `WorkingSet64`. Garde les valeurs en octets : aucun calcul ni arrondi n’est demandé. Explique le rôle de `-Descending` et de `-First 5`.

**B3.** Avec `Get-Service | Where-Object Status -eq Stopped`, affiche les services arrêtés. Ajoute ensuite `Select-Object Name, Status` pour choisir les colonnes. Que signifie `-eq` ? Un service arrêté est-il toujours en panne ?

**B4.** (bonus) Exporte la liste des services (nom, nom affiché, état, type de démarrage) dans `C:\Temp\services.csv`, séparateur `;`, ouvrable dans Excel.

---

## Partie C — Lire les informations du poste

**C1.** Exécute la commande fournie : `Get-CimInstance Win32_BIOS | Select-Object SerialNumber`. Relève le numéro de série et explique son utilité pour un inventaire ou une demande au support.

**C2.** Utilise les commandes fournies dans le cours pour afficher le fabricant, le modèle, la version de Windows et la date du dernier démarrage. Aucun calcul de RAM ni conversion d’unité n’est demandé.

**C3.** (bonus) Trouve, sans Internet, le nom de la classe CIM qui décrit les cartes réseau.

---

## Partie D — Un script d'inventaire (bonus)

> [!NOTE] Pour aller plus loin uniquement
> Cette partie est facultative. Les variables, paramètres, objets personnalisés et conversions qu’elle utilise ne sont pas à maîtriser pour suivre la suite. Le script Get-Inventaire.ps1 du TP final est fourni séparément.

**D1.** Complète la trame ci-dessous et enregistre-la dans `C:\Scripts\Get-InventairePoste.ps1` qui produit **un objet** avec : nom du poste, modèle, numéro de série, processeur, RAM (Go), Windows (édition + version + build), espace libre sur C: (Go), dernier démarrage — et l'exporte dans un CSV dont le chemin est un **paramètre** (par défaut `C:\Temp\inventaire-<poste>.csv`).

Trame de départ : compléter les champs marqués TODO avec les commandes découvertes dans les parties A à C. Créer `C:\Scripts` et `C:\Temp` si nécessaire. L’écriture intégrale sans trame est (bonus).

```powershell
param([string]$Sortie = "C:\Temp\inventaire-$env:COMPUTERNAME.csv")
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$inv = [pscustomobject]@{
    Poste = $env:COMPUTERNAME
    Modele = $cs.Model
    NumeroSerie = $null   # TODO : interroger le BIOS
    Processeur = $null    # TODO : interroger le processeur
    RAM_Go = $null        # TODO : convertir les octets de $cs.TotalPhysicalMemory
    Windows = $null       # TODO : édition, version et build
    C_Libre_Go = $null    # TODO : espace libre du disque système en Go
    DernierBoot = $os.LastBootUpTime
}
$inv
$inv | Export-Csv -Path $Sortie -NoTypeInformation -Encoding UTF8 -Delimiter ';'
```

Avant de conclure, vérifier qu’aucun champ du CSV n’est resté vide.

> [!TIP] Créer le fichier sans se tromper
> 1. `Win + R` → `notepad` → coller la trame, compléter les `TODO`.
> 2. **Fichier → Enregistrer sous** → nom `C:\Scripts\Get-InventairePoste.ps1` (le Bloc-notes de Windows 11 garde bien l'extension `.ps1` tapée, même si le type affiché est *Fichiers texte*).
> 3. Créer les dossiers avant si besoin : `New-Item C:\Scripts, C:\Temp -ItemType Directory -Force`.
> 4. Dans le Terminal : `cd C:\Scripts` puis `.\Get-InventairePoste.ps1` (le `.\` est obligatoire).

**D2.** Lance-le. Que se passe-t-il sur un Windows 11 fraîchement installé ? Corrige **pour ton utilisateur seulement**.

**D3.** Tu télécharges le script depuis un partage Internet et il refuse de se lancer en `RemoteSigned`. Pourquoi ? Que faire ?

---

## Partie E — PowerShell 7 (bonus)

**E1.** Installe PowerShell 7 avec WinGet. Où s'est-il installé ? Lance-le et vérifie sa version.

**E2.** Pourquoi, pour un poste d'administration, préférer l'installeur MSI ? Installe-le.

---

## Partie F — Exercices complémentaires (bonus)

**F1.** Dans `pwsh` 7, tape `Get-WmiObject Win32_BIOS`. Ça marche… alors que la commande n'existe pas en PowerShell 7. Explique (indice : `(Get-Command Get-WmiObject).Module.Path`).

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/07-powershell/tp/standard-corrigev2)
