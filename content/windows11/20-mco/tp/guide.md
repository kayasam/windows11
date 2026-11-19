---
title: "TP 21. TP final : maintien en condition opérationnelle, version guidée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/20-mco"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/20-mco/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/20-mco/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/20-mco-guide.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/20-mco/tp/guide" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/20-mco/tp/guide-corrigev2">Afficher les corrections</a></nav>

**Ta mission.** Depuis `PC01`, inventorie `PC01` et `PC02`, traite les écarts puis inscris les contrôles dans un plan de MCO. Utilise les fichiers ci-dessous sur tes postes du domaine.

## Fichiers et vérifications de départ

- Sur `PC01`, crée `C:\MCO` et télécharge <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/Get-Inventaire.ps1" download data-router-ignore>Get-Inventaire.ps1</a> dedans.
- Sur `PC02`, crée `C:\MCO` et télécharge <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/Test-Poste.ps1" download data-router-ignore>Test-Poste.ps1</a> dedans.
- Ouvre Windows PowerShell en administrateur sur chaque poste avec le compte d’administration du lab. Sur chaque copie téléchargée, utilise `Unblock-File -LiteralPath` avec son chemin complet.
- Depuis `PC01`, lance `Test-WSMan PC02`. Si la commande échoue, termine la partie B du [TP 16 sur l’accès distant](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide), puis recommence.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/20-mco/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/20-mco/tp/standard)

## Établir le point de départ

### A1 — Produire le CSV des deux postes

Sur `PC01`, dans la session d’administration du domaine, ouvre PowerShell et lance `C:\MCO\Get-Inventaire.ps1 -ComputerName PC01,PC02 -Csv C:\MCO\inventaire.csv`. Ouvre `C:\MCO\inventaire.csv`. Vérifie que `PC01` et `PC02` ont chacun une ligne. Si `PC02` manque et que PowerShell affiche **Injoignable**, reprends le test `Test-WSMan PC02`.

### A2 — Transformer les mesures en actions

Compare les lignes du CSV aux seuils du chapitre pour la version, les mises à jour, Defender, BitLocker, l’espace disque et le dernier redémarrage. Dans une fiche, note **poste**, **écart**, **priorité** et **action**.

## Corriger et mesurer de nouveau

### B1 — Actualiser Defender

Sur chacun des deux postes, dans PowerShell administrateur, lance `Update-MpSignature`. Relève ensuite `AntivirusSignatureVersion` et `AntivirusSignatureAge` avec `Get-MpComputerStatus`.

### B2 — Sauvegarder la récupération avant de chiffrer PC02 (bonus)

Si tu as passé le chapitre 09 ou l’atelier BitLocker du TP GPO, relève l’état de protection de `PC02` dans le CSV, note l’écart éventuel dans le plan de MCO et passe à B3.

Sinon, sur `PC02`, applique la stratégie BitLocker de l’atelier du TP GPO. Dans PowerShell administrateur, lance `Get-BitLockerVolume -MountPoint C:`. Si aucun protecteur de récupération n’existe, ajoute-le avec `Add-BitLockerKeyProtector -MountPoint C: -RecoveryPasswordProtector | Out-Null`. Lance le bloc suivant.

```powershell
$recovery = (Get-BitLockerVolume -MountPoint C:).KeyProtector |

    Where-Object KeyProtectorType -eq RecoveryPassword | Select-Object -First 1

Backup-BitLockerKeyProtector -MountPoint C: -KeyProtectorId $recovery.KeyProtectorId
```


Sur `SRV01`, vérifie l’enregistrement sous `PC02` avec le contrôle F2 du TP GPO en ciblant `PC02`. Une fois l’enregistrement confirmé, active BitLocker avec le TPM depuis le Panneau de configuration de `PC02` si le volume n’est pas encore protégé.

### B3 — Vérifier Windows Update et relancer un inventaire

Sur `PC02`, relève la dernière KB qualité dans **Windows Update → Historique**, le report appliqué et l’éventuel redémarrage en attente. Lance une recherche. Sur `PC01`, relance l’inventaire en choisissant un deuxième fichier CSV.

## Automatiser un contrôle et préparer la maintenance

### C1 — Planifier le contrôle quotidien

Sur `PC02`, place le script validé `C:\MCO\Test-Poste.ps1` et crée `C:\MCO\Logs`. Dans `taskschd.msc`, crée la tâche **Contrôle-Poste** sous **Fournil**, tous les jours à 8 h 30, sous `SYSTEM`. Utilise `powershell.exe` et les arguments ci-dessous. Vérifie que seuls les administrateurs et SYSTEM peuvent modifier le script.

```text
-NoProfile -ExecutionPolicy RemoteSigned -Command "& 'C:\MCO\Test-Poste.ps1' *> ('C:\MCO\Logs\{0:yyyyMMdd}.log' -f (Get-Date))"
```

### C2 — Valider l’exécution manuelle

Depuis le Planificateur sur `PC02`, exécute la tâche et actualise l’affichage. Lis son dernier résultat, puis ouvre le journal du jour dans `C:\MCO\Logs`.

### C3 — Rédiger le plan de MCO

Sur `PC01`, crée `C:\MCO\Plan-MCO.md`. Pour chaque contrôle, indique **responsable**, **fréquence**, **preuve attendue** et **action en cas d’échec**. Ajoute le prochain test de restauration, la durée de support des versions constatées et la référence à l’inventaire.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/20-mco/tp/guide-corrigev2)
