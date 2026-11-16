---
title: "TP 07. PowerShell pour l'administrateur"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/07-powershell"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/07-powershell/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/07-powershell.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>


> [!abstract] Parcours TSSR
> Socle en Windows PowerShell 5.1 : aide, objets, pipeline, CIM et script paramétré. Le formateur fournit une trame du script à compléter ; la découverte des syntaxes est guidée. Installer PowerShell 7 est (bonus).

> Chapitres associés : [07. PowerShell pour l'administrateur](https://cours.kaya.ovh/windows11/windows11/07-powershell/)

---

## Objectifs

- Trouver une commande et son aide sans Internet
- Exploiter le pipeline : filtrer, trier, sélectionner, mesurer
- Interroger le poste avec CIM (sans WMIC)
- Écrire un script paramétré qui produit un inventaire CSV
- Installer PowerShell 7 correctement et comprendre la politique d'exécution (bonus)

---

## Prérequis

- `PC01`, session `admin`, Windows Terminal

---

## Partie A — Se repérer

**A1.** Quelle version de PowerShell s'ouvre par défaut ? Comment le vérifier ?

**A2.** Liste toutes les cmdlets dont le nom (partie « Nom ») est `Service`.

**A3.** Affiche uniquement les **exemples** de l'aide de `Stop-Service`. Que faire si l'aide est minimale ?

**A4.** Quelles propriétés possède un objet renvoyé par `Get-Service` ? Lesquelles indiquent l'état et le type de démarrage ?

---

## Partie B — Pipeline

**B1.** Combien de processus tournent sur le poste ?

**B2.** Affiche les 5 processus les plus gourmands en mémoire, avec une colonne « Mo » arrondie.

**B3.** Liste les services en démarrage automatique mais arrêtés, en n'affichant que leur nom.

**B4.** Exporte la liste des services (nom, nom affiché, état, type de démarrage) dans `C:\Temp\services.csv`, séparateur `;`, ouvrable dans Excel.

---

## Partie C — CIM / WMI

**C1.** Le support te demande le **numéro de série** du poste. WMIC a disparu : quelle commande ?

**C2.** Affiche le modèle de la machine, la RAM en Go, la version de Windows et la date du dernier démarrage.

**C3.** (bonus) Trouve, sans Internet, le nom de la classe CIM qui décrit les cartes réseau.

---

## Partie D — Un script d'inventaire

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


