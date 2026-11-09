# TP 07 — PowerShell pour l'administrateur

> Durée estimée : 1h30

> Chapitres associés : [07. PowerShell pour l'administrateur](https://kayasam.github.io/windows11/windows11/07-powershell/)

---

## Objectifs

- Trouver une commande et son aide sans Internet
- Exploiter le pipeline : filtrer, trier, sélectionner, mesurer
- Interroger le poste avec CIM (sans WMIC)
- Écrire un script paramétré qui produit un inventaire CSV
- Installer PowerShell 7 correctement et comprendre la politique d'exécution

---

## Prérequis

- `PC01`, session `admin`, Windows Terminal

---

## Partie A — Se repérer (15 min)

**A1.** Quelle version de PowerShell s'ouvre par défaut ? Comment le vérifier ?

**A2.** Liste toutes les cmdlets dont le nom (partie « Nom ») est `Service`.

**A3.** Affiche uniquement les **exemples** de l'aide de `Stop-Service`. Que faire si l'aide est minimale ?

**A4.** Quelles propriétés possède un objet renvoyé par `Get-Service` ? Lesquelles indiquent l'état et le type de démarrage ?

---

## Partie B — Pipeline (20 min)

**B1.** Combien de processus tournent sur le poste ?

**B2.** Affiche les 5 processus les plus gourmands en mémoire, avec une colonne « Mo » arrondie.

**B3.** Liste les services en démarrage automatique mais arrêtés, en n'affichant que leur nom.

**B4.** Exporte la liste des services (nom, nom affiché, état, type de démarrage) dans `C:\Temp\services.csv`, séparateur `;`, ouvrable dans Excel.

---

## Partie C — CIM / WMI (20 min)

**C1.** Le support te demande le **numéro de série** du poste. WMIC a disparu : quelle commande ?

**C2.** Affiche le modèle de la machine, la RAM en Go, la version de Windows et la date du dernier démarrage.

**C3.** Trouve, sans Internet, le nom de la classe CIM qui décrit les cartes réseau.

---

## Partie D — Un script d'inventaire (25 min)

**D1.** Écris `C:\Scripts\Get-InventairePoste.ps1` qui produit **un objet** avec : nom du poste, modèle, numéro de série, processeur, RAM (Go), Windows (édition + version + build), espace libre sur C: (Go), dernier démarrage — et l'exporte dans un CSV dont le chemin est un **paramètre** (par défaut `C:\Temp\inventaire-<poste>.csv`).

**D2.** Lance-le. Que se passe-t-il sur un Windows 11 fraîchement installé ? Corrige **pour ton utilisateur seulement**.

**D3.** Tu télécharges le script depuis un partage Internet et il refuse de se lancer en `RemoteSigned`. Pourquoi ? Que faire ?

---

## Partie E — PowerShell 7 (10 min)

**E1.** Installe PowerShell 7 avec WinGet. Où s'est-il installé ? Lance-le et vérifie sa version.

**E2.** Pourquoi, pour un poste d'administration, préférer l'installeur MSI ? Installe-le.

---

## Partie F — Bonus

**F1.** Dans `pwsh` 7, tape `Get-WmiObject Win32_BIOS`. Ça marche… alors que la commande n'existe pas en PowerShell 7. Explique (indice : `(Get-Command Get-WmiObject).Module.Path`).

---

[Ouvrir la correction](https://kayasam.github.io/windows11/windows11/07-powershell/tp-corrigev2)


[Afficher les corrections](https://kayasam.github.io/windows11/windows11/07-powershell/tp-corrigev2)
