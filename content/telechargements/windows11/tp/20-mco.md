# TP 21. TP final : maintien en condition opérationnelle

> [!abstract] Parcours TSSR
> Évaluation du socle : A, B (hors B4 et hors B2 si BitLocker a été reporté), C (hors C4) et F. Utiliser les scripts fournis et une trame de plan MCO. L’incident répété, la procédure complète de sortie du parc et la maintenance avancée sont (bonus). Les principes de sortie du parc sont expliqués dans le cours.

> Chapitres associés : [21. Maintien en condition opérationnelle](https://cours.kaya.ovh/windows11/windows11/20-mco/) — et tout le reste de la formation

---

## Contexte

Tu reprends la gestion du parc informatique de la boulangerie **Fournil**. Ton prédécesseur est parti sans laisser de documentation. Ta mission : faire l'état des lieux, remettre les postes en conformité, mettre en place une maintenance préventive et prouver que tu sais intervenir vite sur un incident.

Livrable : un dossier `C:\MCO` sur `PC01` contenant l'inventaire, les journaux et le **plan de MCO**.

---

## Prérequis

- `SRV01`, `PC01`, `PC02` démarrés, `PC01` et `PC02` joints au domaine
- WinRM actif sur `PC02` (TP 12)
- Scripts `Get-Inventaire.ps1`, `Test-Poste.ps1`, `Casse-Poste.ps1` (dossier `Ressources/scripts`) copiés sur `PC01` dans `C:\MCO`
- Points de contrôle Hyper-V de `PC01` et `PC02` : `Checkpoint-VM -Name PC01,PC02 -SnapshotName "Avant-TP21"`

---

## Partie A — État des lieux

**A1.** Depuis `PC01`, lance l'inventaire de `PC01` et `PC02` avec export dans `C:\MCO\inventaire.csv`. Ouvre le CSV dans Excel (ou `Import-Csv | Out-GridView`).

**A2.** Pour chaque poste, liste les **non-conformités** par rapport aux seuils du chapitre 21 (version, mises à jour, antivirus, BitLocker, disque, uptime).

**A3.** Les versions installées sont-elles supportées ? Jusqu'à quand ? Un poste Pro en 24H2 retrouvé dans un placard le serait-il ?

---

## Partie B — Remise en conformité

**B1.** Mets à jour les signatures Defender sur les deux postes. Si la mise à jour échoue, trouve une source alternative.

**B2.** (bonus) Si tu as passé le chapitre 09 ou l’atelier BitLocker du TP GPO, relève l’état de protection de `PC02` dans le CSV, note l’écart éventuel dans le plan de MCO et passe à B3. Sinon, active BitLocker sur `PC02` avec le TPM, en sauvegardant le mot de passe de récupération dans AD **avant** le chiffrement. Vérifie sur `SRV01` que la clé est bien enregistrée.

**B3.** Vérifie l'état de Windows Update sur `PC02` : dernière mise à jour, stratégie appliquée (report), redémarrage en attente. Lance une recherche de mises à jour.

**B4.** (bonus) Analyse le magasin de composants de `PC02`. Faut-il le nettoyer ? Avec ou sans `/ResetBase` ?

**B5.** Relance l'inventaire : quelles non-conformités restent ? Pourquoi ?

---

## Partie C — Maintenance préventive

**C1.** Sur `PC02`, planifie l'exécution quotidienne de `Test-Poste.ps1` à 8 h 30 sous le compte SYSTEM, avec un journal par jour dans `C:\MCO\Logs`. Range la tâche dans un dossier `\Fournil\`.

**C2.** Lance la tâche manuellement et vérifie son code retour et le journal produit.

**C3.** Pourquoi `Test-Poste.ps1` ne signale-t-il pas ta propre tâche comme suspecte, alors qu'il a détecté celle du TP 20 ?

**C4.** (bonus) Propose une GPO pour définir l'ordre des sources de mise à jour Defender avec une source de secours.

---

## Partie D — Incident complémentaire (bonus)

Ton binôme exécute `Casse-Poste.ps1` sur **ton** `PC02` (pendant ce temps tu exécutes le sien), puis redémarre le poste.

**D1.** Détecte toutes les pannes avec tes outils automatisés, puis explique les résultats obtenus.

**D2.** Répare, puis prouve que c'est réparé.

**D3.** Rédige le ticket d'intervention.

---

## Partie E — Fin de vie d'un poste (bonus)

L'ordinateur portable d'une vendeuse est remplacé. Il est joint au domaine, chiffré par BitLocker, géré par LAPS.

**E1.** Écris la procédure complète de sortie du parc, dans l'ordre, avec les commandes.

**E2.** Quelles informations faut-il récupérer **dans AD** avant de supprimer le compte ordinateur ? Pourquoi ?

**E3.** Pourquoi l'effacement d'un disque BitLocker peut-il être quasi instantané ?

---

## Partie F — Le plan de MCO

Trame du livrable à compléter dans `Plan-MCO.md` :

```markdown
Plan MCO — Fournil
## Périmètre et inventaire
Postes, versions, utilisateurs et date du contrôle : …
## Écarts et décisions
Écart / risque / action / responsable / échéance / preuve : …
## Maintenance planifiée
Tâche / fréquence / compte d’exécution / journal / contrôle du résultat : …
## Cycle de vie
Version / fin de support vérifiée / date de revue / migration prévue : …
## Sauvegarde et restauration
Données / règle 3-2-1 / emplacement / responsable / date du test de restauration : …
```

La trame ne vaut pas validation : chaque ligne doit correspondre à l’état observé sur le lab.

**F1.** Rédige dans `C:\MCO\Plan-MCO.md` le plan de MCO du parc Fournil : tâches, fréquences, responsables, vérifications.

**F2.** Ajoute un calendrier des **échéances de cycle de vie** des versions présentes dans le parc.

**F3.** Ajoute la stratégie de sauvegarde (règle 3-2-1) et la date du prochain **test de restauration**.

---


