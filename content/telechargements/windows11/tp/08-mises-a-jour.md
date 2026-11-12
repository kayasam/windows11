# TP 08. Windows Update et gestion des mises à jour

> Durée estimée : 1h15

> Chapitres associés : [08. Windows Update et gestion des mises à jour](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/)

---

## Objectifs

- Faire l'état des lieux des mises à jour d'un poste (installées, en attente, échouées)
- Piloter Windows Update en ligne de commande, sans `usoclient`
- Configurer par stratégie locale un anneau « large » (report, échéance, version cible)
- Mettre à jour les applications, pas seulement Windows

---

## Prérequis

- `PC01` avec accès Internet, terminal **administrateur**
- Stratégie d'exécution `RemoteSigned` (TP 07)

---

## Partie A — État des lieux (15 min)

**A1.** Liste les 4 derniers correctifs installés. De quand datent-ils ? Qu'en déduis-tu sur l'ISO utilisée ?

**A2.** Ouvre **Paramètres → Windows Update → Historique des mises à jour**. Retrouve-y la même information. Y a-t-il des échecs ?

**A3.** Où d'autre peut-on voir rapidement un échec de mise à jour (indice : chapitre 06) ?

---

## Partie B — Windows Update en ligne de commande (20 min)

**B1.** Pourquoi ne faut-il plus compter sur `usoclient StartScan` ?

**B2.** Avec l'API COM `Microsoft.Update.Session`, liste les mises à jour **non installées**. Combien y en a-t-il ? De quels types ?

**B3.** Installe le module `PSWindowsUpdate` et liste les mêmes mises à jour. Un collègue écrit `Get-WindowsUpdate | Select-Object KB, Title` et obtient un tableau vide. Pourquoi ?

**B4.** Installe toutes les mises à jour, sans redémarrer automatiquement. Comment savoir ensuite si un redémarrage est en attente ?

---

## Partie C — Stratégie locale : anneau « large » (25 min)

Le Fournil veut que les postes de production reçoivent les correctifs **7 jours** après leur publication, restent en **25H2/26H2** tant que la DSI n'a pas validé la version suivante, et redémarrent au plus tard **3 jours** après l'installation.

**C1.** Dans `gpedit.msc`, retrouve le nœud Windows Update. Combien de sous-dossiers contient-il ? Lequel ne faut-il **surtout pas** remplir sans serveur WSUS ?

**C2.** Configure : report qualité 7 jours, version cible `Windows 11` / `26H2`, échéance qualité 3 jours.

**C3.** Vérifie dans le registre et dans les Paramètres que la stratégie est bien appliquée.

**C4.** Que devra faire la DSI le jour où la version 27H2 sera validée ?

---

## Partie D — Applications et pilotes (10 min)

**D1.** Windows Update ne propose plus rien. Le poste est-il à jour ? Vérifie avec WinGet.

**D2.** Un pilote proposé par Windows Update fait planter les postes. Quelle stratégie empêche Windows Update de distribuer les pilotes ?

---

## Partie E — Bonus

**E1.** Explique en quelques lignes à un responsable pourquoi le Fournil ne montera **pas** de serveur WSUS en 2026, et ce qu'il fera à la place.

---


