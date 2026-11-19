# TP 08. Windows Update et gestion des mises à jour, version guidée

**Ta mission.** Sur `PC01`, relève les correctifs, consulte ce qui reste disponible et configure l’anneau de mises à jour du Fournil. Continue sur la stratégie pendant que la recherche Windows Update tourne.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/standard)

## Lire l’état des mises à jour

### A1 — Relever les correctifs récents

Dans Windows PowerShell, lance `Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 4 HotFixID,InstalledOn`. Relève les KB et leurs dates.

### A2 — Vérifier l’historique graphique

Ouvre **Paramètres → Windows Update → Historique des mises à jour**. Compare les mises à jour qualité avec tes lignes PowerShell. Si un échec apparaît, relève son code.

### A3 — Chercher les mises à jour disponibles (bonus)

Sans lancer d’installation, démarre une recherche dans Windows PowerShell sur `PC01`.

```powershell
$searcher = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()

$result = $searcher.Search('IsInstalled=0 and IsHidden=0')

$result.Updates | Select-Object Title,Type
```

## Configurer l’anneau local

### B1 — Renseigner les paramètres qualité et version

Dans `gpedit.msc` sur `PC01`, ouvre **Configuration ordinateur → Modèles d’administration → Composants Windows → Windows Update**. Dans les politiques de mises à jour proposées, règle le report **qualité** à **7 jours** et la version ciblée à **Windows 11 / 26H2**, selon le scénario du lab. Dans les paramètres d’expérience utilisateur, règle l’échéance **qualité** à **3 jours**.

### B2 — Contrôler les valeurs appliquées

Dans PowerShell administrateur, lance `gpupdate /target:computer /force`. Ouvre **Paramètres → Windows Update → Options avancées** et vérifie que le poste indique des réglages gérés. Dans `gpedit.msc`, relis les réglages activés en B1. **(bonus)** Contrôle aussi les valeurs avec `Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`.

## Vérifier les applications

### C1 — Comparer Windows Update et WinGet

Lance `winget upgrade` sur `PC01` et note une application proposée, si la liste en contient.

### C2 — Identifier le réglage des pilotes

Dans `gpedit.msc`, retrouve **Ne pas inclure les pilotes avec les mises à jour Windows**. Relève son état et le chemin de la stratégie.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/guide-corrigev2)
