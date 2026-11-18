---
title: "TP 08. Windows Update et gestion des mises à jour, version guidée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/08-mises-a-jour"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/08-mises-a-jour-guide.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/guide" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/guide-corrigev2">Afficher les corrections</a></nav>

**Ta mission.** Sur `PC01`, relève les correctifs, consulte ce qui reste disponible et configure l’anneau de mises à jour du Fournil. Continue sur la stratégie pendant que la recherche Windows Update tourne.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/standard)

## Lire l’état des mises à jour

### A1 — Relever les correctifs récents

Dans Windows PowerShell, lance `Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 4 HotFixID,InstalledOn`. Relève les KB et leurs dates.

### A2 — Vérifier l’historique graphique

Ouvre **Paramètres → Windows Update → Historique des mises à jour**. Compare les mises à jour qualité avec tes lignes PowerShell. Si un échec apparaît, relève son code.

### A3 — Chercher les mises à jour disponibles

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

Dans PowerShell administrateur, lance `gpupdate /target:computer /force` puis `Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`. Repère le report, le produit, la version ciblée et l’échéance qualité. Ouvre aussi les options avancées de Windows Update.

## Vérifier les applications

### C1 — Comparer Windows Update et WinGet

Lance `winget upgrade` sur `PC01` et note une application proposée, si la liste en contient.

### C2 — Identifier le réglage des pilotes

Dans `gpedit.msc`, retrouve **Ne pas inclure les pilotes avec les mises à jour Windows**. Relève son état et le chemin de la stratégie.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/08-mises-a-jour/tp/guide-corrigev2)
