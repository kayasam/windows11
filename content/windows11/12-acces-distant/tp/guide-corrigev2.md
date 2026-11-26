---
title: "TP 12. Administrer à distance : RSAT, WinRM, RPC et SSH, corrigé guidé"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/12-acces-distant"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/12-acces-distant-guide-corrigev2.md">↓ Télécharger le corrigé (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide-corrigev2" aria-current="page">Corrigé</a></nav>

**Mission** · Configurer quatre façons d'administrer à distance : les consoles du serveur sur PC01 (RSAT), PowerShell à distance (WinRM), les consoles graphiques à distance (RPC) et SSH avec une clé.

**Avant de commencer** · `SRV01` et `PC01` démarrés, `PC01` joint au domaine. Sur **les deux** VM, ouvre une session `FOURNIL\Administrateur`.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/) · [Correction détaillée](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/standard-corrigev2)

---

## A — RSAT

### A1. Lancer l'installation sur PC01

Paramètres → Système → Fonctionnalités facultatives → **Afficher les fonctionnalités** → rechercher `RSAT` → cocher AD DS, DNS, DHCP → **Suivant** → **Ajouter**.

> [!success]- Afficher la correction — A1
> L'installation se fait depuis Windows Update (≈ 10 minutes, Internet obligatoire).
>
> ![w11-11-acces-distant-1](https://cours.kaya.ovh/windows11/assets/captures/w11-11-acces-distant-1.png)
>
> Équivalent PowerShell (administrateur) : `Add-WindowsCapability -Online -Name Rsat.Dns.Tools~~~~0.0.1.0` (et `Rsat.ActiveDirectory.DS-LDS.Tools`, `Rsat.DHCP.Tools`).

### A2. Utiliser les consoles

> [!success]- Afficher la correction — A2
> - `dsa.msc` : `stagiaire` est dans **Fournil → Utilisateurs**.
> - `dnsmgmt.msc` : dans `ad.fournil.lab`, la ligne `PC01` est un enregistrement **Hôte (A)** avec l'adresse de `PC01`.
> - `dhcpmgmt.msc` : la plage du TP 10 (`192.168.3.100` à `192.168.3.200` dans le lab).
>
> On administre le serveur **sans ouvrir de session dessus**. Les consoles utilisent le compte de la session de `PC01`.

---

## B — WinRM

### B1. Constater

> [!success]- Afficher la correction — B1
> - `Test-WSMan srv01` (sur PC01) : réponse normale, `ProductVendor : Microsoft Corporation`.
> - `Test-WSMan PC01` (sur SRV01) : **erreur rouge**.
> - Le service **Windows Remote Management (Gestion WSM)** de PC01 est **arrêté**, en démarrage **Manuel**.
>
> ![w11-12-services-winrm-arrete](https://cours.kaya.ovh/windows11/assets/captures/w11-12-services-winrm-arrete.png)
>
> Windows Server : WinRM actif d'office. Windows 11 : non.

### B2. Activer sur PC01

> [!success]- Afficher la correction — B2
> ![w11-12-enable-psremoting](https://cours.kaya.ovh/windows11/assets/captures/w11-12-enable-psremoting.png)
>
> Service démarré et automatique, écouteur sur le port **5985**, pare-feu ouvert. `Test-WSMan PC01` répond maintenant depuis SRV01.

### B3. Utiliser depuis SRV01

> [!success]- Afficher la correction — B3
> `Invoke-Command` affiche `PC01` puis le service *Spooler* en **Running**. **Aucun mot de passe** : Kerberos (domaine) + `Administrateur` est administrateur de `PC01`.
> Pendant `Enter-PSSession`, l'invite commence par **`[PC01]:`**. `Exit-PSSession` ramène sur SRV01.

---

## C — RPC

### C1. Constater l'échec

> [!success]- Afficher la correction — C1
> La connexion échoue : en général, **« le serveur RPC n'est pas disponible »**. Les consoles graphiques utilisent **RPC** (port 135 + un port choisi à la connexion), pas WinRM : activer WinRM ne suffit pas, et le pare-feu de Windows 11 bloque RPC par défaut.

### C2. Ouvrir le pare-feu de PC01

> [!success]- Afficher la correction — C2
> Les 12 règles passent en vert (icône cochée). Équivalent PowerShell, sur PC01 en administrateur :
> ```powershell
> Enable-NetFirewallRule -DisplayGroup "Gestion à distance des journaux des événements", "Gestion des services à distance"
> ```
> Sur tout un parc, on fait la même chose par **GPO** (règles prédéfinies du pare-feu).

### C3. Réessayer depuis SRV01

> [!success]- Afficher la correction — C3
> - L'arborescence affiche **Observateur d'événements (PC01)** : on lit le journal Système de PC01 depuis le serveur.
> - Dans **Gestion de l'ordinateur (PC01)**, le Spouleur s'arrête puis redémarre ; `Get-Service Spooler` sur PC01 affiche **Running**.

---

## D — SSH avec une clé

### D1. Première connexion

> [!success]- Afficher la correction — D1
> SSH demande de faire confiance à l'**empreinte** du serveur (première connexion seulement) → `yes`. Puis mot de passe. `hostname` → `SRV01`.
>
> ![w11-12-ssh-srv01](https://cours.kaya.ovh/windows11/assets/captures/w11-12-ssh-srv01.png)

### D2. Créer la paire de clés

> [!success]- Afficher la correction — D2
> Dans `C:\Users\<ton profil>\.ssh\` :
> - `id_ed25519` = clé **privée**, reste sur PC01, **ne se partage jamais** ;
> - `id_ed25519.pub` = clé **publique**, se copie sur les serveurs.
>
> (Et `known_hosts`, créé en D1 : l'empreinte de SRV01.)

### D3. Copier la clé publique sur SRV01

> [!success]- Afficher la correction — D3
> Sur **PC01**, dans la session qui a créé la clé, exécute ce bloc. SSH demande le mot de passe du compte pour le premier dépôt.
>
> ```powershell
> $cle = Get-Content "$HOME\.ssh\id_ed25519.pub" -ErrorAction Stop
> $fichier = 'C:\ProgramData\ssh\administrators_authorized_keys'
> ssh Administrateur@srv01.ad.fournil.lab "powershell.exe -NoProfile -Command Add-Content -Path '$fichier' -Value '$cle' -Encoding ascii -ErrorAction Stop; icacls.exe '$fichier' /inheritance:r /grant:r '*S-1-5-32-544:F' '*S-1-5-18:F'"
> ```
>
> Sur **SRV01**, le bloc `Match Group administrators` de `C:\ProgramData\ssh\sshd_config` dirige OpenSSH vers `C:\ProgramData\ssh\administrators_authorized_keys`. Les deux SID de `icacls` désignent les **Administrateurs** et **SYSTEM**, quelle que soit la langue de Windows.

### D4. Vérifier la connexion par clé

> [!success]- Afficher la correction — D4
> ```powershell
> ssh -o PreferredAuthentications=publickey Administrateur@srv01.ad.fournil.lab hostname
> ```
>
> Si `hostname` renvoie `SRV01`, la clé fonctionne. Une demande de phrase secrète concerne la clé privée sur `PC01`.
>
> Si tu obtiens `Permission denied`, vérifie sur **SRV01** la présence de `administrators_authorized_keys`, la ligne `ssh-ed25519` et les droits du fichier avec `icacls`.

[Retour à l'énoncé guidé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide)
