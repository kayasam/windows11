---
title: "TP 12. Administrer à distance : RSAT, WinRM, RPC et SSH, version guidée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/12-acces-distant"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/12-acces-distant-guide.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>
<nav class="exercise-resources" aria-label="Ressources du TP"><a href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide" aria-current="page">Énoncé</a><a class="exercise-correction" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide-corrigev2">Afficher les corrections</a></nav>

**Mission** · Configurer quatre façons d'administrer à distance : les consoles du serveur sur PC01 (RSAT), PowerShell à distance (WinRM), les consoles graphiques à distance (RPC) et SSH avec une clé.

**Avant de commencer** · `SRV01` et `PC01` démarrés, `PC01` joint au domaine. Sur **les deux** VM, ouvre une session `FOURNIL\Administrateur`.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/) · [Énoncé non guidé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/standard)

---

## A — RSAT (à lancer en premier : ≈ 10 minutes)

### A1. Lancer l'installation sur PC01

1. **Paramètres** → **Système** → **Fonctionnalités facultatives** → **Afficher les fonctionnalités** → **Oui**.
2. Dans la recherche, tape `RSAT` et coche :
   - *RSAT : outils Active Directory Domain Services Directory et services LDS…*
   - *RSAT : outils du serveur DNS*
   - *RSAT : outils du serveur DHCP*
3. **Suivant** → **Ajouter**. Laisse tourner et passe à la partie B.

### A2. Utiliser les consoles (quand l'installation est finie)

1. `Win + R` → `dsa.msc` : ouvre **Fournil → Utilisateurs** et repère `stagiaire`.
2. `Win + R` → `dnsmgmt.msc` → **L'ordinateur suivant** : `srv01.ad.fournil.lab` → **OK**. Ouvre **Zones de recherche directe → ad.fournil.lab** et repère la ligne `PC01`. Note son adresse IP.
3. `Win + R` → `dhcpmgmt.msc` → déplie `srv01.ad.fournil.lab` → **IPv4** → l'étendue → **Pool d'adresses**. Note la plage.

---

## B — WinRM : PowerShell à distance

### B1. Constater

1. Sur **PC01**, dans Windows PowerShell : `Test-WSMan srv01`. Note le résultat.
2. Sur **SRV01**, dans Windows PowerShell : `Test-WSMan PC01`. Note le résultat.
3. Sur **PC01** : `Win + R` → `services.msc` → tout en bas, **Windows Remote Management (Gestion WSM)**. Note son état.

### B2. Activer sur PC01

1. Sur **PC01** : `Win + X` → **Terminal (administrateur)** → **Oui**.
2. Tape : `Enable-PSRemoting -Force`
3. Sur **SRV01**, relance `Test-WSMan PC01`.

### B3. Utiliser depuis SRV01

Sur **SRV01**, dans Windows PowerShell :

```powershell
Invoke-Command -ComputerName PC01 -ScriptBlock { hostname; Get-Service Spooler }
Enter-PSSession PC01
hostname
Exit-PSSession
```

Note si un mot de passe t'a été demandé, et ce qu'affiche l'invite pendant la session.

---

## C — RPC : les consoles graphiques à distance

### C1. Constater l'échec

Sur **SRV01** : `Win + R` → `eventvwr.msc` → clic droit sur **Observateur d'événements (local)** → **Se connecter à un autre ordinateur…** → **Autre ordinateur** : `PC01` → **OK**. Note le message.

### C2. Ouvrir le pare-feu de PC01

1. Sur **PC01** : `Win + R` → `wf.msc` → **Règles de trafic entrant**.
2. Clique sur l'en-tête de colonne **Groupe** pour trier.
3. Sélectionne les 6 règles **Gestion à distance des journaux des événements** (clic sur la première, **Maj + clic** sur la dernière) → clic droit → **Activer la règle**.
4. Fais de même pour les 6 règles **Gestion des services à distance**.

### C3. Réessayer depuis SRV01

1. Recommence C1 : ouvre **Journaux Windows → Système** de `PC01`.
2. `Win + R` → `compmgmt.msc` → clic droit sur **Gestion de l'ordinateur (local)** → **Se connecter à un autre ordinateur…** → `PC01`.
3. **Services et applications → Services** → **Spouleur d'impression** → **Arrêter**, puis **Démarrer**.
4. Sur **PC01**, vérifie avec `Get-Service Spooler`.

---

## D — SSH avec une clé

Tout se fait sur **PC01**, dans Windows PowerShell.

### D1. Première connexion avec le mot de passe

```powershell
ssh administrateur@srv01.ad.fournil.lab
```

Réponds **`yes`** (en entier) à la question sur l'empreinte, puis tape le mot de passe. Tape `hostname`, puis `exit`.

### D2. Créer la paire de clés

```powershell
ssh-keygen -t ed25519
```

Appuie trois fois sur **Entrée** (emplacement par défaut, pas de phrase de passe). Puis regarde ce qui a été créé :

```powershell
Get-ChildItem $env:USERPROFILE\.ssh
```

### D3. Copier la clé publique sur SRV01

```powershell
$cle = Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
Invoke-Command -ComputerName SRV01 -ArgumentList $cle -ScriptBlock {
    param($cle)
    Add-Content -Path C:\ProgramData\ssh\administrators_authorized_keys -Value $cle
    icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "BUILTIN\Administrateurs:F" "SYSTEM:F"
}
```

### D4. Se reconnecter

```powershell
ssh administrateur@srv01.ad.fournil.lab
```

Note ce qui a changé. Tape `exit`.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide-corrigev2)
