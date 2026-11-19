# TP 08. Windows Update et gestion des mises à jour, corrigé guidé

**Ta mission.** Sur `PC01`, relève les correctifs, consulte ce qui reste disponible et configure l’anneau de mises à jour du Fournil. Continue sur la stratégie pendant que la recherche Windows Update tourne.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/standard)

## Lire l’état des mises à jour

### A1 — Relever les correctifs récents

Dans Windows PowerShell, lance `Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 4 HotFixID,InstalledOn`. Relève les KB et leurs dates.

> [!success]- Afficher la correction — A1
> `InstalledOn` donne la date annoncée par Windows. Le nombre de lignes et les KB dépendent de l’ISO et des opérations réalisées sur le poste.

### A2 — Vérifier l’historique graphique

Ouvre **Paramètres → Windows Update → Historique des mises à jour**. Compare les mises à jour qualité avec tes lignes PowerShell. Si un échec apparaît, relève son code.

> [!success]- Afficher la correction — A2
> L’historique peut contenir d’autres catégories et des échecs. `Get-HotFix` donne une vue partielle des correctifs installés.

### A3 — Chercher les mises à jour disponibles (bonus)

Sans lancer d’installation, démarre une recherche dans Windows PowerShell sur `PC01`.

```powershell
$searcher = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()

$result = $searcher.Search('IsInstalled=0 and IsHidden=0')

$result.Updates | Select-Object Title,Type
```

> [!success]- Afficher la correction — A3
> La colonne `Title` identifie les mises à jour proposées. Une sortie vide est possible. Si la recherche échoue, regarde l’état du réseau et le code dans l’historique.

## Configurer l’anneau local

### B1 — Renseigner les paramètres qualité et version

Dans `gpedit.msc` sur `PC01`, ouvre **Configuration ordinateur → Modèles d’administration → Composants Windows → Windows Update**. Dans les politiques de mises à jour proposées, règle le report **qualité** à **7 jours** et la version ciblée à **Windows 11 / 26H2**, selon le scénario du lab. Dans les paramètres d’expérience utilisateur, règle l’échéance **qualité** à **3 jours**.

> [!success]- Afficher la correction — B1
> Les trois valeurs sont visibles dans les stratégies activées. Aucun serveur WSUS n’est nécessaire pour cet anneau. Utilise le chapitre pour retrouver les intitulés si l’ADMX de ton poste présente des variantes.

### B2 — Contrôler les valeurs appliquées

Dans PowerShell administrateur, lance `gpupdate /target:computer /force`. Ouvre **Paramètres → Windows Update → Options avancées** et vérifie que le poste indique des réglages gérés. Dans `gpedit.msc`, relis les réglages activés en B1. **(bonus)** Contrôle aussi les valeurs avec `Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`.

> [!success]- Afficher la correction — B2
> Dans le registre, si tu fais le bonus, les valeurs attendues sont `DeferQualityUpdatesPeriodInDays = 7`, `ProductVersion = Windows 11` et `TargetReleaseVersionInfo = 26H2` et `ConfigureDeadlineForQualityUpdates = 3`. Relis le réglage dans la console de stratégie si une valeur manque.

## Vérifier les applications

### C1 — Comparer Windows Update et WinGet

Lance `winget upgrade` sur `PC01` et note une application proposée, si la liste en contient.

> [!success]- Afficher la correction — C1
> Un poste sans mise à jour Windows en attente peut encore avoir des applications à mettre à jour. La liste de WinGet dépend des logiciels installés et de ses sources.

### C2 — Identifier le réglage des pilotes

Dans `gpedit.msc`, retrouve **Ne pas inclure les pilotes avec les mises à jour Windows**. Relève son état et le chemin de la stratégie.

> [!success]- Afficher la correction — C2
> Une fois activé, ce réglage exclut les pilotes du flux des mises à jour qualité Windows. L’état affiché dans la console indique si ce choix est configuré sur le poste.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/guide)
