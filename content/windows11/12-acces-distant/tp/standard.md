---
title: "TP 16. Administrer SRV01 depuis PC01"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/12-acces-distant"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/tp/12-acces-distant.md">↓ Télécharger le TP (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>


**Mission** · Depuis `PC01`, vérifie que le serveur Fournil répond et relève l’état de DNS et DHCP.

**Avant de commencer** · `PC01` est joint au domaine `ad.fournil.lab`. `SRV01` est démarré sur le réseau du lab. Utilise le compte autorisé fourni pour administrer `SRV01`.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/)

### 0. Comparer les ports en écoute

Sur les consoles des deux VM, ouvre **Windows PowerShell** et lance les mêmes commandes. Sur `SRV01`, tu peux aussi demander au formateur d’afficher le résultat.

```powershell
hostname
Get-NetTCPConnection -State Listen |
    Where-Object { $_.LocalPort -in 22, 135, 445, 3389, 5985 } |
    Sort-Object LocalPort |
    Select-Object LocalAddress, LocalPort, State
```

Repère le port `5985` sur `SRV01`. Si une ligne apparaît deux fois, compare les adresses locales (par exemple IPv4 et IPv6). Fais ensuite les trois étapes depuis `PC01`.

### 1. Tester le serveur

Depuis `PC01`, vérifie que WinRM répond sur `srv01.ad.fournil.lab`. Note l’information qui te le confirme.

### 2. Ouvrir la session distante

Ouvre une session PowerShell distante sur `SRV01` avec le compte autorisé du lab. Relève l’indice qui te confirme que tu es dans cette session.

### 3. Vérifier les services et revenir sur PC01

Dans la **session distante**, lance `hostname` puis `Get-Service DNS, DHCPServer`. Note le nom de la machine et le statut des deux services. Tape `Exit-PSSession`, puis relance `hostname`. Quel nom vois-tu maintenant ?



[Ouvrir la version guidée](https://cours.kaya.ovh/windows11/windows11/12-acces-distant/tp/guide)
