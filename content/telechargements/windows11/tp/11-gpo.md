# TP 11. Stratégies de groupe et gestion centralisée

> [!abstract] Parcours TSSR
> Les RSAT sont préchargés et vérifiés en A1. Le partage Commun doit exister avant C ; sa préparation guidée est incluse dans C. Les GPO restent créées et testées par le stagiaire.

> Chapitres associés : [11. Stratégies de groupe et gestion centralisée](https://cours.kaya.ovh/windows11/windows11/11-gpo/)

---

## Objectifs

- Administrer les GPO depuis `PC01` (RSAT)
- Créer une GPO **ordinateur** de sécurité : admins locaux, Windows LAPS, BitLocker → AD, anneau Windows Update
- Créer une GPO **utilisateur** filtrée sur un groupe : lecteur réseau et restriction
- Diagnostiquer avec `gpresult`

---

## Prérequis

- `SRV01` contrôleur de domaine, `PC01` joint dans `OU=Ordinateurs,OU=Fournil` (TP 10)
- BitLocker actif sur `PC01` avec une clé de récupération (TP 09)
- Session sur `PC01` avec un compte membre de *Admins du domaine* pour ce TP

---

## Partie A — Outils

**A1.** Vérifie sur `PC01` la console GPMC et les outils AD (RSAT), préchargés par le formateur. S’ils manquent, lance leur installation et utilise le poste de secours pendant le téléchargement.

**A2.** Ouvre `gpmc.msc`. Quelles GPO existent déjà ? Où sont-elles liées ?

**A3.** (bonus) Où sont stockées physiquement les GPO ? Retrouve le dossier de la *Default Domain Policy*.

---

## Partie B — GPO ordinateur « GPO-Postes-Securite »

**B1.** Crée la GPO `GPO-Postes-Securite` et lie-la à `OU=Ordinateurs,OU=Fournil`.

**B2.** Fais en sorte que `FOURNIL\GG-Admins-Postes` soit administrateur local de tous les postes de l'UO. Deux méthodes possibles : lesquelles ? Choisis-en une.

**B3.** Prépare le domaine pour **Windows LAPS**, puis configure la GPO : sauvegarde dans AD, 14 caractères, 30 jours.

**B4.** Configure la sauvegarde des clés de récupération BitLocker du disque système dans AD DS.

**B5.** Ajoute un report de **7 jours** des mises à jour qualité (anneau « large »).

**B6.** Applique sur `PC01` et vérifie **chacun** des quatre réglages.

**B7.** La clé BitLocker n'apparaît pas dans AD. Pourquoi ? Corrige.

**B8.** Le mot de passe LAPS est bien dans AD… mais un technicien ne peut pas s'en servir pour ouvrir une session. Pourquoi ?

---

## Partie C — GPO utilisateur filtrée

Sur `SRV01`, un partage `\\SRV01\Commun` est accessible en modification au groupe `G-Boulangerie`. Avant C1, prépare-le avec ce modèle guidé (sur SRV01, après le TP 10) :

```powershell
New-Item C:\Partages\Commun -ItemType Directory -Force
icacls C:\Partages\Commun /inheritance:r
icacls C:\Partages\Commun /grant 'SYSTEM:(OI)(CI)F' 'BUILTIN\Administrateurs:(OI)(CI)F' 'FOURNIL\G-Boulangerie:(OI)(CI)M'
New-SmbShare -Name Commun -Path C:\Partages\Commun -ChangeAccess 'FOURNIL\G-Boulangerie' -FullAccess 'FOURNIL\Admins du domaine'
```

Vérifie l’accès avec `stagiaire` avant de créer le mappage.

**C1.** Crée la GPO `GPO-Boulangerie-Utilisateurs`, liée à `OU=Utilisateurs,OU=Fournil`.

**C2.** Ajoute une **préférence** qui monte `\\SRV01\Commun` en `P:`, nommé « Commun ». Pourquoi une préférence et pas une stratégie ?

**C3.** Ajoute la stratégie « Interdire l'accès au Panneau de configuration et à l'application Paramètres du PC ».

**C4.** Restreins la GPO aux membres de `G-Boulangerie`. Quelle erreur classique faut-il éviter ?

**C5.** Ouvre une session `FOURNIL\stagiaire` sur `PC01`. Vérifie le lecteur `P:` et la restriction.

**C6.** Crée un utilisateur `test.vendeur` dans `OU=Utilisateurs`, **hors** de `G-Boulangerie`. Que reçoit-il ?

---

## Partie D — Diagnostic

**D1.** Avec `gpresult`, affiche les GPO ordinateur puis utilisateur appliquées sur `PC01`. Produis aussi un rapport HTML.

**D2.** Un collègue a déplacé `PC01` dans `CN=Computers` par erreur. Que montre `gpresult` ? Pourquoi ?

**D3.** Où chercher si une GPO ne s'applique pas du tout (aucune trace) ?

---

## Partie E — Exercices complémentaires (bonus)

**E1.** Sauvegarde toutes les GPO du domaine dans `C:\Sauvegarde\GPO` en une commande.

**E2.** Explique à quoi servirait **Group Policy Analytics** si le Fournil passait à Intune.

---


