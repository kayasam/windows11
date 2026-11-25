# TP 16. Déployer Windows 11 : ISO, réseau, migration, moderne, corrigé guidé

**Ta mission.** Déploie `PC02` depuis l’ISO officielle et une petite ISO contenant le fichier de réponse. Tu travailleras sur `PC01` pour créer la mini-ISO, sur l’hôte pour démarrer la VM et sur `SRV01` pour vérifier le domaine. Prépare le domaine et le DHCP du TP 10, l’UO `Fournil → Ordinateurs` et les outils ADK du TP 13.

## Fichiers à récupérer sur `PC01`

Crée le dossier `C:\Images\TP15` et enregistre les quatre fichiers ci-dessous dedans. Prépare aussi l’ISO Windows 11 du lab sur l’hôte Hyper-V.

| Fichier | À quoi il sert |
| --- | --- |
| <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/autounattend-iso-officielle.xml" download data-router-ignore>autounattend-iso-officielle.xml</a> | Modèle d’installation de `PC02` |
| <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/Preparer-Fichier-Reponse.ps1" download data-router-ignore>Preparer-Fichier-Reponse.ps1</a> | Crée `autounattend.xml` en demandant les identifiants du lab |
| <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/postinstall.ps1" download data-router-ignore>postinstall.ps1</a> | Installe les applications après le premier démarrage |
| <a href="https://cours.kaya.ovh/windows11/telechargements/windows11/fichiers/MigFournil.xml" download data-router-ignore>MigFournil.xml</a> | Sélectionne les dossiers à migrer avec USMT |

Dans l’ADK du TP 13, vérifie que **Outils de déploiement** et **User State Migration Tool (USMT)** sont installés sur `PC01`. Demande au formateur le mot de passe local du lab et les identifiants du compte autorisé à joindre les VM au domaine..

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/16-deploiement/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp/standard)

## Lire et préparer le support

### A1 — Repérer les trois passes du fichier XML

Sur `PC01`, ouvre `C:\Images\TP15\autounattend-iso-officielle.xml` dans le Bloc-notes. Retrouve `windowsPE`, `specialize` et `oobeSystem`. Pour chacune, associe une action prévue. En `specialize`, repère le domaine et l’UO de destination.

> [!success]- Afficher la correction — A1
> `windowsPE` prépare notamment le disque et l’édition. `specialize` configure le système et la jonction. `oobeSystem` termine l’accueil et lance les actions prévues pour le premier démarrage.

### A2 — Préparer le fichier de réponse et la mini-ISO

1. Sur `PC01`, ouvre **Windows PowerShell** et exécute les commandes suivantes. Saisis les identifiants du lab quand le script les demande.

```powershell
Set-Location C:\Images\TP15
New-Item -ItemType Directory -Force C:\Images\reponses-pc02
Unblock-File -LiteralPath .\Preparer-Fichier-Reponse.ps1
.\Preparer-Fichier-Reponse.ps1 -Sortie C:\Images\reponses-pc02\autounattend.xml
Copy-Item .\postinstall.ps1 C:\Images\reponses-pc02\
Get-ChildItem C:\Images\reponses-pc02 -Name
```

Tu dois voir `autounattend.xml` et `postinstall.ps1`. Si l’exécution du script est désactivée dans le lab, lance `Set-ExecutionPolicy -Scope Process RemoteSigned` dans cette fenêtre, puis relance le script. Le fichier généré et la mini-ISO contiennent les identifiants. Garde-les sur le lab.

2. Sur `PC01`, ouvre **Environnement de déploiement et d’outils de création d’images** depuis Démarrer et lance la commande ci-dessous.

```cmd
oscdimg -u2 -udfver102 -lREPONSES C:\Images\reponses-pc02 C:\Images\reponses-pc02.iso
```

3. Copie `reponses-pc02.iso` sur le disque de l’hôte, à côté de l’ISO officielle. Par PowerShell Direct, ouvre **Windows PowerShell en administrateur sur l’hôte**, puis utilise un compte autorisé sur `PC01`.

```powershell
$session = New-PSSession -VMName PC01 -Credential (Get-Credential)
Copy-Item -FromSession $session -Path C:\Images\reponses-pc02.iso -Destination "$env:USERPROFILE\Downloads"
Remove-PSSession $session
```

Vérifie que `reponses-pc02.iso` est dans le dossier **Téléchargements** de l’hôte.

> [!success]- Afficher la correction — A2
> La racine de la mini-ISO contient `autounattend.xml` et `postinstall.ps1`. Le premier fichier a été généré localement et reprend le nom `PC02`.

## Déployer et vérifier PC02

### B1 — Démarrer la VM sur le bon DVD

Sur l’hôte, crée `PC02` en génération 2, avec TPM, deux vCPU, 4 Go statiques et `vSwitch-Rennes`. Attache l’ISO officielle au DVD de démarrage et la mini-ISO au second lecteur. Utilise un VHDX neuf pour `PC02`. Le fichier de réponse efface le disque 0 de cette VM. Au premier démarrage, appuie une fois sur une touche à l’invitation du DVD. Laisse ensuite la VM redémarrer sur son disque.

> [!success]- Afficher la correction — B1
> Windows Setup détecte `autounattend.xml`. Ensuite, laisse les redémarrages se faire depuis le disque virtuel pour que l’installation et la post-installation se terminent.

### B2 — Contrôler la post-installation sur PC02

Ouvre une session autorisée sur `PC02`. Lance `hostname`, puis `Get-CimInstance Win32_ComputerSystem | Select-Object Domain,PartOfDomain`. Contrôle l’état BitLocker et cherche les applications attendues avec `winget list`. Ouvre `C:\Windows\Temp\postinstall.log`.

> [!success]- Afficher la correction — B2
> Le poste s’appelle `PC02` et indique `ad.fournil.lab` avec `PartOfDomain : True`. Le journal permet de distinguer une application en échec d’une installation Windows terminée.

### B3 — Confirmer l’objet ordinateur et le DNS

Sur `SRV01`, vérifie `PC02` dans `dsa.msc` sous **Fournil → Ordinateurs**. Lance `Resolve-DnsName pc02.ad.fournil.lab` et compare l’adresse à celle relevée sur `PC02`.

> [!success]- Afficher la correction — B3
> L’objet est dans la bonne UO et la réponse DNS correspond au poste. En cas d’échec de jonction, relis le DNS sur `PC02` et `C:\Windows\debug\NetSetup.log`.

## Migrer le profil utilisateur

### C1 — Préparer et tester le partage USMT

Sur `SRV01`, ouvre **Windows PowerShell en administrateur** avec un administrateur du domaine. Si `USMT$` existe déjà, vérifie qu’il pointe vers `C:\USMT`. Si le partage n’existe pas, prépare-le.

```powershell
New-Item -ItemType Directory -Force C:\USMT\USMT, C:\USMT\Store
icacls C:\USMT /inheritance:r /grant:r 'SYSTEM:(OI)(CI)F' 'BUILTIN\Administrateurs:(OI)(CI)F' 'FOURNIL\Admins du domaine:(OI)(CI)F'
New-SmbShare -Name 'USMT$' -Path C:\USMT -FullAccess 'FOURNIL\Admins du domaine'
```

Sur `PC01`, ouvre **Windows PowerShell en administrateur** avec le compte d’administration du domaine. Copie l’outil installé par l’ADK et le XML du TP.

```powershell
$outil = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\User State Migration Tool\amd64'
Test-Path "$outil\scanstate.exe"
Copy-Item "$outil\*" '\\SRV01\USMT$\USMT\' -Recurse -Force
Copy-Item C:\Images\TP15\MigFournil.xml '\\SRV01\USMT$\USMT\'
Test-Path '\\SRV01\USMT$\USMT\scanstate.exe'
Test-Path '\\SRV01\USMT$\USMT\loadstate.exe'
Test-Path '\\SRV01\USMT$\USMT\MigFournil.xml'
```

Si le premier test affiche `False`, installe le composant USMT de l’ADK avant de copier. Si tu obtiens **Accès refusé**, contrôle le compte avec `whoami` et les droits du partage sur `SRV01`. Passe à C2 quand les trois derniers tests affichent `True`.

> [!success]- Afficher la correction — C1
> Les exécutables 64 bits et le XML sont accessibles depuis `PC01`. Le compte administrateur du domaine peut écrire dans le magasin partagé.

### C2 — Capturer le profil de stagiaire sur PC01

Sur `PC01`, connecte-toi en `FOURNIL\stagiaire`. Crée `preuve-usmt.txt` dans **Documents**, écris une ligne dedans et ferme cette session. Reviens dans la session d’administration du domaine et lance **Windows PowerShell en administrateur**.

```powershell
New-Item -ItemType Directory -Force C:\Temp
& '\\SRV01\USMT$\USMT\scanstate.exe' '\\SRV01\USMT$\Store\PC01' '/i:\\SRV01\USMT$\USMT\MigFournil.xml' '/ue:*\*' '/ui:FOURNIL\stagiaire' '/l:C:\Temp\ScanState.log'
$LASTEXITCODE
```

Attends le code `0` avant de continuer. En cas d’échec, lis la fin de `C:\Temp\ScanState.log`. Si le dossier du magasin existe déjà et que tu dois refaire la capture, utilise par exemple `Store\PC01-essai2` dans **les deux** commandes de migration.

> [!success]- Afficher la correction — C2
> Le code `0` confirme que la capture a abouti. Le journal ScanState permet de vérifier la sélection de `FOURNIL\stagiaire`.

### C3 — Restaurer et vérifier le profil sur PC02

Sur `PC02`, ferme la session de `stagiaire` si elle est ouverte. Dans la session d’administration du domaine, lance **Windows PowerShell en administrateur**.

```powershell
New-Item -ItemType Directory -Force C:\Temp
& '\\SRV01\USMT$\USMT\loadstate.exe' '\\SRV01\USMT$\Store\PC01' '/i:\\SRV01\USMT$\USMT\MigFournil.xml' '/ue:*\*' '/ui:FOURNIL\stagiaire' '/l:C:\Temp\LoadState.log'
$LASTEXITCODE
```

Pour un code `0`, ouvre une session `FOURNIL\stagiaire`. Retrouve `preuve-usmt.txt` dans **Documents** et vérifie son contenu. Pour un autre code, lis `C:\Temp\LoadState.log` avant de retenter.

[Référence Microsoft pour ScanState](https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-scanstate-syntax) · [Référence Microsoft pour LoadState](https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-loadstate-syntax)

> [!success]- Afficher la correction — C3
> Le code `0` confirme la restauration. `FOURNIL\stagiaire` retrouve `preuve-usmt.txt` et sa ligne de test sur `PC02`.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/16-deploiement/tp/guide)
