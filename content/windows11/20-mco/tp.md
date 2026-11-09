---
title: "TP 20 — TP final : maintien en condition opérationnelle"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/20-mco"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://kayasam.github.io/windows11/windows11/20-mco/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://kayasam.github.io/windows11/windows11/20-mco/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://kayasam.github.io/windows11/telechargements/windows11/tp/20-mco.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://kayasam.github.io/windows11/windows11/20-mco/tp" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://kayasam.github.io/windows11/windows11/20-mco/tp-corrigev2">Afficher les corrections</a></nav>

> Durée estimée : 3h

> Chapitres associés : [20. Maintien en condition opérationnelle](https://kayasam.github.io/windows11/windows11/20-mco/) — et tout le reste de la formation

---

## Contexte

Tu reprends la gestion du parc informatique de la boulangerie **Fournil**. Ton prédécesseur est parti sans laisser de documentation. Ta mission : faire l'état des lieux, remettre les postes en conformité, mettre en place une maintenance préventive et prouver que tu sais intervenir vite sur un incident.

Livrable : un dossier `C:\MCO` sur `PC01` contenant l'inventaire, les journaux et le **plan de MCO**.

---

## Prérequis

- `SRV01`, `PC01`, `PC02` démarrés, `PC01` et `PC02` joints au domaine
- WinRM actif sur `PC02` (TP 12)
- Scripts `Get-Inventaire.ps1`, `Test-Poste.ps1`, `Casse-Poste.ps1` (dossier `Ressources/scripts`) copiés sur `PC01` dans `C:\MCO`
- Points de contrôle Hyper-V de `PC01` et `PC02` : `Checkpoint-VM -Name PC01,PC02 -SnapshotName "Avant-TP20"`

---

## Partie A — État des lieux (30 min)

**A1.** Depuis `PC01`, lance l'inventaire de `PC01` et `PC02` avec export dans `C:\MCO\inventaire.csv`. Ouvre le CSV dans Excel (ou `Import-Csv | Out-GridView`).

**A2.** Pour chaque poste, liste les **non-conformités** par rapport aux seuils du chapitre 20 (version, mises à jour, antivirus, BitLocker, disque, uptime).

**A3.** Les versions installées sont-elles supportées ? Jusqu'à quand ? Un poste Pro en 24H2 retrouvé dans un placard le serait-il ?

---

## Partie B — Remise en conformité (45 min)

**B1.** Mets à jour les signatures Defender sur les deux postes. Si la mise à jour échoue, trouve une source alternative.

**B2.** Active BitLocker sur `PC02` avec le TPM, en sauvegardant le mot de passe de récupération dans AD **avant** le chiffrement. Vérifie sur `SRV01` que la clé est bien enregistrée.

**B3.** Vérifie l'état de Windows Update sur `PC02` : dernière mise à jour, stratégie appliquée (report), redémarrage en attente. Lance une recherche de mises à jour.

**B4.** Analyse le magasin de composants de `PC02`. Faut-il le nettoyer ? Avec ou sans `/ResetBase` ?

**B5.** Relance l'inventaire : quelles non-conformités restent ? Pourquoi ?

---

## Partie C — Maintenance préventive (30 min)

**C1.** Sur `PC02`, planifie l'exécution quotidienne de `Test-Poste.ps1` à 8 h 30 sous le compte SYSTEM, avec un journal par jour dans `C:\MCO\Logs`. Range la tâche dans un dossier `\Fournil\`.

**C2.** Lance la tâche manuellement et vérifie son code retour et le journal produit.

**C3.** Pourquoi `Test-Poste.ps1` ne signale-t-il pas ta propre tâche comme suspecte, alors qu'il a détecté celle du TP 19 ?

**C4.** Propose une GPO pour définir l'ordre des sources de mise à jour Defender avec une source de secours.

---

## Partie D — Incident chronométré (30 min)

Ton binôme exécute `Casse-Poste.ps1` sur **ton** `PC02` (pendant ce temps tu exécutes le sien), puis redémarre le poste.

**D1.** Chronomètre : combien de temps pour **détecter** toutes les pannes avec tes outils, sans chercher à la main ?

**D2.** Répare, puis prouve que c'est réparé.

**D3.** Rédige le ticket d'intervention.

---

## Partie E — Fin de vie d'un poste (20 min)

L'ordinateur portable d'une vendeuse est remplacé. Il est joint au domaine, chiffré par BitLocker, géré par LAPS.

**E1.** Écris la procédure complète de sortie du parc, dans l'ordre, avec les commandes.

**E2.** Quelles informations faut-il récupérer **dans AD** avant de supprimer le compte ordinateur ? Pourquoi ?

**E3.** Pourquoi l'effacement d'un disque BitLocker peut-il être quasi instantané ?

---

## Partie F — Le plan de MCO (25 min)

**F1.** Rédige dans `C:\MCO\Plan-MCO.md` le plan de MCO du parc Fournil : tâches, fréquences, responsables, vérifications.

**F2.** Ajoute un calendrier des **échéances de cycle de vie** des versions présentes dans le parc.

**F3.** Ajoute la stratégie de sauvegarde (règle 3-2-1) et la date du prochain **test de restauration**.

---

[Ouvrir la correction](https://kayasam.github.io/windows11/windows11/20-mco/tp-corrigev2)
