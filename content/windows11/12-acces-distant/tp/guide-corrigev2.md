---
title: "TP 12. Administration et assistance à distance, corrigé guidé"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/12-acces-distant"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/12-acces-distant-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Ta mission.** Tu vas administrer `PC02` depuis `PC01` par Bureau à distance et PowerShell. Utilise les deux postes du domaine `ad.fournil.lab` et une session d’administration autorisée. Si `PC02` n’est pas encore disponible, demande la VM préparée pour ce TP ou réalise d’abord le déploiement du TP 16.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/standard)

## Contrôler et utiliser Bureau à distance

### A1 — Mesurer l’état initial depuis PC01

Sur `PC01`, lance `Resolve-DnsName PC02`, puis `Test-NetConnection PC02 -Port 3389`. Relève l’adresse et `TcpTestSucceeded`.

> [!success]- Afficher la correction — A1
> Une résolution réussie identifie la cible. `False` sur le port ne suffit pas à isoler une panne. Vérifie ensuite le réglage RDP et la règle entrante sur `PC02`.

### A2 — Activer RDP sur la machine cible

Depuis la console de `PC02`, ouvre **Paramètres → Système → Bureau à distance** et active RDP dans le lab. Vérifie les règles **Bureau à distance** dans `wf.msc` et garde l’accès limité au réseau autorisé. Sur `PC01`, relance le test du port.

> [!success]- Afficher la correction — A2
> Le TCP 3389 doit répondre. Le choix de la console locale rend ce premier réglage réalisable même si aucun outil d’administration distante n’était encore actif.

### A3 — Ouvrir une session et vérifier l’identité

Sur `PC01`, ouvre `mstsc`, saisis `PC02` et connecte-toi avec le compte autorisé. Dans la session distante, lance `hostname` et `whoami`. Referme la session après le test.

> [!success]- Afficher la correction — A3
> Tu dois lire `PC02` et le compte utilisé. Les administrateurs autorisés et les membres du groupe local **Utilisateurs du Bureau à distance** peuvent ouvrir une session si la stratégie le permet.

## Administrer avec PowerShell

### B1 — Vérifier WinRM sur les machines

Sur `PC02`, lance `Get-Service WinRM` dans Windows PowerShell. Depuis `PC01`, lance `Test-WSMan SRV01` et relève la réponse.

> [!success]- Afficher la correction — B1
> `Get-Service` indique l’état local. Une réponse WSMan confirme qu’un service compatible répond sur `SRV01`. Si elle manque, vérifie le service, le réseau et le profil du pare-feu sur la cible.

### B2 — Activer la gestion à distance de PC02

Dans Windows PowerShell administrateur **sur PC02**, lance `Enable-PSRemoting -Force`. Depuis `PC01`, lance `Test-WSMan PC02`.

> [!success]- Afficher la correction — B2
> La seconde commande doit renvoyer les informations WSMan. Si elle échoue, vérifie le profil réseau de `PC02` et les règles WinRM du profil correspondant dans `wf.msc`.

### B3 — Lire deux postes avec une commande

Sur `PC01`, dans la session autorisée, exécute le bloc et repère la colonne `PSComputerName`.

```powershell
Invoke-Command -ComputerName SRV01,PC02 -ScriptBlock {

    Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version

}
```

> [!success]- Afficher la correction — B3
> Chaque ligne associe une version de Windows à `SRV01` ou `PC02`. Avec les noms du domaine et un compte autorisé, l’authentification peut utiliser la session de domaine en cours.

### B4 — Distinguer session locale et distante

Sur `PC01`, lance `Enter-PSSession -ComputerName SRV01`. Dans l’invite distante, saisis `hostname` puis `Get-Service DHCPServer,DNS`. Termine avec `Exit-PSSession`.

> [!success]- Afficher la correction — B4
> Le nom affiché doit être `SRV01`. Dans le lab, les deux services sont normalement démarrés. Après la sortie, l’invite redevient celle de `PC01`.

## Préparer une assistance

### C1 — Reconnaître une demande d’assistance légitime

Ouvre **Assistance rapide** sur `PC01` et repère les zones **Obtenir de l’aide** et **Aider quelqu’un**. Identifie le technicien avec le formateur avant tout partage d’écran.

> [!success]- Afficher la correction — C1
> Le technicien ouvre une session pour générer un code. L’utilisateur saisit le code et accepte explicitement le partage et, si demandé, le contrôle. Un appel non sollicité est un motif de vérification avec le support officiel.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide)
