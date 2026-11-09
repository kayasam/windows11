# TP 04 — Disques, volumes et systèmes de fichiers

> Durée estimée : 1h15

> Chapitres associés : [04. Disques, volumes et systèmes de fichiers](https://kayasam.github.io/windows11/windows11/04-disques-stockage/)

---

## Objectifs

- Ajouter des disques à une VM et les préparer (GPT, partition, NTFS)
- Utiliser `diskmgmt.msc`, `diskpart` et le module PowerShell `Storage`
- Monter un volume dans un dossier
- Créer un espace de stockage en miroir et **simuler la panne d'un disque**

---

## Prérequis

- `PC01` opérationnel (TP 03)
- Sur l'**hôte**, créer et attacher trois disques de 10 Go à `PC01` (VM allumée, ajout à chaud) :

```powershell
1..3 | ForEach-Object {
    New-VHD -Path "D:\HyperV\PC01\Data$_.vhdx" -SizeBytes 10GB -Dynamic | Out-Null
    Add-VMHardDiskDrive -VMName PC01 -Path "D:\HyperV\PC01\Data$_.vhdx"
}
```

---

## Partie A — Observer (10 min)

**A1.** Dans `PC01`, liste les disques en PowerShell. Quel est le style de partition des nouveaux disques ?

**A2.** Lance `diskpart` et affiche les disques et les volumes. Quelles lettres sont déjà occupées, et par quoi ?

---

## Partie B — Préparer un disque de données (20 min)

**B1.** Initialise le disque 1 en **GPT**.

**B2.** Crée une partition de **5 Go** avec la lettre `G:`, formatée en NTFS, nommée `Data`.

**B3.** Un collègue a tapé `-DriveLetter E` et obtenu *« The requested access path is already in use »*. Explique.

**B4.** Étends `G:` à tout l'espace disponible du disque, puis vérifie sa taille.

**B5.** Monte aussi ce volume dans le dossier `C:\Donnees`. Vérifie les deux chemins d'accès.

---

## Partie C — Espace de stockage en miroir (25 min)

**C1.** Liste les disques qui peuvent rejoindre un pool. Le disque 1 y figure-t-il ? Que faire si oui ?

**C2.** Crée le pool `Pool-Fournil` avec les disques 2 et 3, puis l'espace `Donnees-Miroir` en **miroir 2 voies**, formaté en NTFS avec la lettre `F:`.

**C3.** Quelle est la taille utilisable de `F:` ? Pourquoi pas 10 Go ?

**C4.** Écris un fichier `F:\recette.txt`.

**C5.** **Simule une panne** : sur l'hôte, détache `Data3.vhdx` de `PC01`. Dans `PC01`, relève l'état du pool, de l'espace et des disques physiques. Le fichier est-il encore lisible ?

**C6.** Rattache le disque. Que se passe-t-il ?

---

## Partie D — Systèmes de fichiers (10 min)

**D1.** Un formateur doit copier une ISO de 8 Go sur une clé USB lisible sur Mac et Linux. Quel système de fichiers ?

**D2.** Pourquoi ne formate-t-on pas un disque de données Windows en exFAT ?

---

## Partie E — Bonus

**E1.** Écris un script DiskPart (`diskpart /s`) qui nettoie le disque 1, le convertit en GPT et crée une partition NTFS unique `Archives` en `H:`. Quelle commande du script est irréversible ?

---

[Ouvrir la correction](https://kayasam.github.io/windows11/windows11/04-disques-stockage/tp-corrigev2)


[Afficher les corrections](https://kayasam.github.io/windows11/windows11/04-disques-stockage/tp-corrigev2)
