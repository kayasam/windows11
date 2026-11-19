---
title: "TP 02. Installation, mise à niveau et comptes, version guidée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/02-installation"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/02-installation/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/02-installation/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/02-installation/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/02-installation-guide.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/02-installation/tp/guide" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/02-installation/tp/guide-corrigev2">Afficher les corrections</a></nav>

**Ta mission.** Installe Windows 11 Professionnel sur la VM du TP 01. À la fin, vérifie l’édition, l’état de récupération et la compatibilité du poste avant de passer à sa configuration.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/02-installation/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/02-installation/tp/standard)

## Installer et ouvrir la première session

### A1 — Installer Windows 11 Professionnel

Dans la console de `PC01`, démarre sur le DVD. Sélectionne **Français**, puis **Windows 11 Professionnel**. Choisis l’espace non alloué du **disque virtuel de PC01** et lance l’installation.

### A2 — Créer le compte local de lab

À la configuration initiale (OOBE), suis le parcours de compte local du chapitre avec l’ISO du lab, puis crée `admin` avec le mot de passe fourni. Si l’écran réseau bloque, retourne à la procédure du cours pour cette ISO.

### A3 — Nommer le poste

Dans la session `admin`, ouvre **Paramètres → Système → Informations système → Renommer ce PC**. Saisis `PC01`, redémarre et lance `hostname`.

## Lire l’état du poste

### B1 — Confirmer l’édition installée

Sur `PC01`, ouvre `winver` et relève l’édition, la version et le build.

### B2 — Repérer les partitions

Sur `PC01`, ouvre `diskmgmt.msc`. Sur le disque système, repère EFI, le volume Windows `C:` et la partition de récupération. Pour voir aussi la MSR, lance `Get-Partition -DiskNumber 0` si Windows est sur le disque 0.

### B3 — Distinguer chiffrement et protection

Dans PowerShell administrateur sur `PC01`, lance `manage-bde -status C:`. Relève le **pourcentage chiffré** puis l’**état de la protection**.

### B4 — Vérifier WinRE et la jonction

Dans PowerShell administrateur, lance `reagentc /info` puis `dsregcmd /status`. Relève l’état WinRE et les champs `DomainJoined` et `AzureAdJoined`.

## Tester la compatibilité

### C1 — Vérifier TPM et Secure Boot

Sur `PC01`, lance `Get-Tpm` puis `Confirm-SecureBootUEFI` en administrateur. Dans `tpm.msc`, relève aussi la version de spécification.

### C2 — Faire un contrôle de compatibilité seul (bonus)

Sous Windows, avec l’ISO montée, repère la lettre du DVD dans **Ce PC**. Depuis PowerShell administrateur, adapte le chemin et lance le scan suivant.

```powershell
$p = Start-Process 'D:\setup.exe' -ArgumentList '/auto upgrade /quiet /eula accept /compat scanonly /dynamicupdate disable' -Wait -PassThru

'0x{0:X8}' -f $p.ExitCode
```

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/02-installation/tp/guide-corrigev2)
