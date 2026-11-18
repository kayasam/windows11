# TP 02. Installation, mise à niveau et comptes, version guidée

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

### C2 — Faire un contrôle de compatibilité seul

Sous Windows, avec l’ISO montée, repère la lettre du DVD dans **Ce PC**. Depuis PowerShell administrateur, adapte le chemin et lance le scan suivant.

```powershell
$p = Start-Process 'D:\setup.exe' -ArgumentList '/auto upgrade /quiet /eula accept /compat scanonly /dynamicupdate disable' -Wait -PassThru

'0x{0:X8}' -f $p.ExitCode
```

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/02-installation/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/02-installation/tp/guide-corrigev2)
