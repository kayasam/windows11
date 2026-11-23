# TP 02. Installation, mise à niveau et comptes, corrigé guidé

**Ta mission.** Installe Windows 11 Professionnel sur la VM du TP 01. À la fin, vérifie l’édition, l’état de récupération et la compatibilité du poste avant de passer à sa configuration.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/02-installation/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/02-installation/tp/standard)

## Installer et ouvrir la première session

### A1 — Installer Windows 11 Professionnel

Dans la console de `PC01`, démarre sur le DVD. Sélectionne **Français**, puis **Windows 11 Professionnel**. Choisis l’espace non alloué du **disque virtuel de PC01** et lance l’installation.

> [!success]- Afficher la correction — A1
> L’installateur recrée les partitions nécessaires sur le disque du lab. Si **Famille** est présélectionnée, clique explicitement sur **Professionnel** avant de valider.

### A2 — Créer le compte local de lab

À la configuration initiale (OOBE), suis le parcours de compte local du chapitre avec l’ISO du lab, puis crée `admin` avec le mot de passe fourni. Si l’écran réseau bloque, retourne à la procédure du cours pour cette ISO.

> [!success]- Afficher la correction — A2
> Sur l’ISO testée dans le cours, `Shift+F10` puis `OOBE\BYPASSNRO` redémarrent l’OOBE et permettent de choisir **Je n’ai pas Internet** quand le réseau est déconnecté. Cette procédure dépend de l’ISO. Un fichier de réponse préparé par le formateur permet de créer le compte pendant une installation automatisée.

### A3 — Nommer le poste

Dans la session `admin`, ouvre **Paramètres → Système → Informations système → Renommer ce PC**. Saisis `PC01`, redémarre et lance `hostname`.

> [!success]- Afficher la correction — A3
> La commande affiche `PC01`. Le redémarrage applique le nouveau nom.

## Lire l’état du poste

### B1 — Confirmer l’édition installée

Sur `PC01`, ouvre `winver` et relève l’édition, la version et le build.

> [!success]- Afficher la correction — B1
> L’édition attendue est **Windows 11 Professionnel**. Garde le build réellement installé dans ta fiche plutôt que de recopier celui du cours.

### B2 — Repérer les partitions

Sur `PC01`, ouvre `diskmgmt.msc`. Sur le disque système, repère EFI, le volume Windows `C:` et la partition de récupération. Pour voir aussi la MSR, lance `Get-Partition -DiskNumber 0` si Windows est sur le disque 0.

> [!success]- Afficher la correction — B2
> EFI contient les fichiers du démarrage UEFI, la MSR est réservée à Windows, `C:` contient le système et la partition de récupération héberge généralement WinRE.

### B3 — Distinguer chiffrement et protection

Dans PowerShell administrateur sur `PC01`, lance `manage-bde -status C:`. Relève le **pourcentage chiffré** puis l’**état de la protection**.

> [!success]- Afficher la correction — B3
> Un volume chiffré peut afficher une protection désactivée. Utilise les deux champs pour décrire ton poste. Le TP 09 traite l’activation complète de la protection.

### B4 — Vérifier WinRE et la jonction

Dans PowerShell administrateur, lance `reagentc /info` puis `dsregcmd /status`. Relève l’état WinRE et les champs `DomainJoined` et `AzureAdJoined`.

> [!success]- Afficher la correction — B4
> WinRE est normalement activé. Avant le TP AD, les deux champs de jonction valent `NO` sur une VM installée avec un compte local.

## Tester la compatibilité

### C1 — Vérifier TPM et Secure Boot

Sur `PC01`, lance `Get-Tpm` puis `Confirm-SecureBootUEFI` en administrateur. Dans `tpm.msc`, relève aussi la version de spécification.

> [!success]- Afficher la correction — C1
> TPM présent et prêt, spécification 2.0 et Secure Boot `True` correspondent au paramétrage attendu de la VM.

### C2 — Faire un contrôle de compatibilité seul (bonus)

Sous Windows, avec l’ISO montée, repère la lettre du DVD dans **Ce PC**. Depuis PowerShell administrateur, adapte le chemin et lance le scan suivant.

```powershell
$p = Start-Process 'D:\setup.exe' -ArgumentList '/auto upgrade /quiet /eula accept /compat scanonly /dynamicupdate disable' -Wait -PassThru

'0x{0:X8}' -f $p.ExitCode
```

> [!success]- Afficher la correction — C2
> `0xC1900210` indique qu’aucun problème de compatibilité n’a été détecté. En cas de blocage, consulte les fichiers `CompatData*.xml` et les journaux de Setup dans le dossier Panther. [Options de Windows Setup](https://learn.microsoft.com/fr-fr/windows-hardware/manufacture/desktop/windows-setup-command-line-options?view=windows-11)

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/02-installation/tp/guide)
