# TP 12. Administration et assistance à distance, version guidée

**Ta mission.** Tu vas administrer `PC02` depuis `PC01` par Bureau à distance et PowerShell. Utilise les deux postes du domaine `ad.fournil.lab` et une session d’administration autorisée. Si `PC02` n’est pas encore disponible, demande la VM préparée pour ce TP ou réalise d’abord le déploiement du TP 16.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/standard)

## Contrôler et utiliser Bureau à distance

### A1 — Mesurer l’état initial depuis PC01

Sur `PC01`, lance `Resolve-DnsName PC02`, puis `Test-NetConnection PC02 -Port 3389`. Relève l’adresse et `TcpTestSucceeded`.

### A2 — Activer RDP sur la machine cible

Depuis la console de `PC02`, ouvre **Paramètres → Système → Bureau à distance** et active RDP dans le lab. Vérifie les règles **Bureau à distance** dans `wf.msc` et garde l’accès limité au réseau autorisé. Sur `PC01`, relance le test du port.

### A3 — Ouvrir une session et vérifier l’identité

Sur `PC01`, ouvre `mstsc`, saisis `PC02` et connecte-toi avec le compte autorisé. Dans la session distante, lance `hostname` et `whoami`. Referme la session après le test.

## Administrer avec PowerShell

### B1 — Vérifier WinRM sur les machines

Sur `PC02`, lance `Get-Service WinRM` dans Windows PowerShell. Depuis `PC01`, lance `Test-WSMan SRV01` et relève la réponse.

### B2 — Activer la gestion à distance de PC02

Dans Windows PowerShell administrateur **sur PC02**, lance `Enable-PSRemoting -Force`. Depuis `PC01`, lance `Test-WSMan PC02`.

### B3 — Lire deux postes avec une commande

Sur `PC01`, dans la session autorisée, exécute le bloc et repère la colonne `PSComputerName`.

```powershell
Invoke-Command -ComputerName SRV01,PC02 -ScriptBlock {

    Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version

}
```

### B4 — Distinguer session locale et distante

Sur `PC01`, lance `Enter-PSSession -ComputerName SRV01`. Dans l’invite distante, saisis `hostname` puis `Get-Service DHCPServer,DNS`. Termine avec `Exit-PSSession`.

## Préparer une assistance

### C1 — Reconnaître une demande d’assistance légitime

Ouvre **Assistance rapide** sur `PC01` et repère les zones **Obtenir de l’aide** et **Aider quelqu’un**. Identifie le technicien avec le formateur avant tout partage d’écran.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide-corrigev2)
