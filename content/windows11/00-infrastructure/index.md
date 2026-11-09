---
title: "00. Infrastructure de référence (fil rouge)"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/00-infrastructure"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/00-infrastructure/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a></div><div class="resource-actions"><a class="resource-download" download href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/00-infrastructure.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!NOTE] Objectif
> Ce chapitre n'a pas de TP — c'est la fiche de référence du **fil rouge Entreprise Fournil** qui traverse toute la formation. Adressage IP, domaine, UO, comptes, DHCP, réseau virtuel : tout ce qui est posé progressivement est récapitulé ici, à consulter à tout moment.

---

## Schéma du lab

```
                              Internet
                                  │
                ┌─────────────────┴──────────────────┐
                │ PC hôte (Windows 11 + Hyper-V)     │
                │  vEthernet (vSwitch-Rennes)        │
                │  192.168.3.254  ← passerelle + NAT │
                │  Default Switch (DHCP + NAT auto)  │
                └───────┬────────────────────┬───────┘
                        │ vSwitch-Rennes     │ Default Switch
                        │ 192.168.3.0/24     │ (172.x, change au reboot)
      ┌─────────────────┼─────────────┐      │
      │                 │             │      │
  ┌───┴────┐      ┌─────┴──┐     ┌────┴───┐ ┌┴───────┐
  │ SRV01  │      │ PC01   │     │ PC02   │ │ MASTER │
  │ .1     │      │ .10    │     │ DHCP   │ │ DHCP   │
  │ WS2025 │      │ W11    │     │ W11    │ │ W11    │
  │ Core   │      │ 26H2   │     │ déployé│ │ réf.   │
  └────────┘      └────────┘     └────────┘ └────────┘
   AD DS/DNS/DHCP  poste admin   chap. 16    chap. 14
   chap. 10        chap. 01→     jamais      jamais
                                 joint ?     joint
```

---

## Tableau d'adressage IP

| Machine | Rôle | IP | Passerelle | DNS | Créée au |
|---------|------|----|------------|-----|----------|
| Hôte `vEthernet (vSwitch-Rennes)` | Passerelle NAT | `192.168.3.254/24` | — | — | chap. 01 |
| **SRV01** | Contrôleur de domaine (AD DS, DNS, DHCP) | `192.168.3.1` | `.254` | `192.168.3.1` | chap. 10 |
| **PC01** | Poste d'administration Windows 11 Pro | `192.168.3.10` | `.254` | `1.1.1.1` → `192.168.3.1` (chap. 10) | chap. 01-02 |
| **PC02** | Poste cible du déploiement | DHCP (`.100`–`.200`) | via DHCP | via DHCP | chap. 16 |
| **MASTER** | VM de référence (image) | DHCP du Default Switch | — | — | chap. 14 |

> [!NOTE] Chronologie
> `PC01` reçoit son IP fixe au chapitre 03. `SRV01` n'existe qu'à partir du chapitre 10 : avant, `PC01` utilise un DNS public. `MASTER` (chapitre 14) n'est **jamais** jointe au domaine et vit sur le **Default Switch** (Internet sans configuration). `PC02` n'apparaît qu'au chapitre 16.

---

## Comptes du lab

| Compte | Où | Mot de passe (lab) | Usage |
|--------|----|--------------------|-------|
| `admin` | PC01 (local, Administrateurs) | `Fournil2026!` | Compte créé à l'installation |
| `Administrateur` | SRV01 puis domaine | `Fournil2026!` | Administration du domaine (Tier 0) |
| DSRM | SRV01 | `Fournil2026!DSRM` | Restauration des services d'annuaire |
| `sguillard` | Domaine | `P@ssw0rd2026!` (à changer) | Utilisateur standard |
| `adm.sguillard` | Domaine | `P@ssw0rd2026!` | Compte d'administration des postes (chap. 11) |

> [!WARNING] Mots de passe de lab uniquement
> Ces mots de passe sont volontairement simples et partagés pour la formation. En production : un mot de passe unique par compte, un coffre (gestionnaire de secrets), et **Windows LAPS** pour les administrateurs locaux (chapitre 11).

---

## Domaine Active Directory

| Paramètre | Valeur |
|-----------|--------|
| **FQDN** | `ad.fournil.lab` |
| **NetBIOS** | `FOURNIL` |
| **Niveau fonctionnel** | `Win2025` (domaine et forêt) |
| **Contrôleur de domaine** | `SRV01` (unique) |

```
ad.fournil.lab
└── OU=Fournil
    ├── OU=Utilisateurs      ← sguillard
    ├── OU=Ordinateurs       ← PC01, PC02 (déplacés depuis CN=Computers)
    ├── OU=Groupes           ← G-Boulangerie, GG-Admins-Postes
    └── OU=Admins            ← adm.sguillard
```

| Objet | Type | Détail |
|-------|------|--------|
| `sguillard` | Utilisateur | `ChangePasswordAtLogon` |
| `adm.sguillard` | Utilisateur | Membre de `GG-Admins-Postes` |
| `G-Boulangerie` | Groupe global de sécurité | Contient `sguillard` — filtrage des GPO |
| `GG-Admins-Postes` | Groupe global de sécurité | Ajouté aux Administrateurs locaux des postes par GPO (chap. 11) |

---

## Étendue DHCP (SRV01)

| Paramètre | Valeur |
|-----------|--------|
| Nom | `vSwitch-Rennes` |
| Plage | `192.168.3.100` → `192.168.3.200` /24 |
| Routeur (003) | `192.168.3.254` |
| DNS (006) | `192.168.3.1` |
| Domaine (015) | `ad.fournil.lab` |

---

## Réseau virtuel et NAT (hôte)

```powershell
New-VMSwitch -Name "vSwitch-Rennes" -SwitchType Internal
New-NetIPAddress -InterfaceAlias "vEthernet (vSwitch-Rennes)" -IPAddress 192.168.3.254 -PrefixLength 24
New-NetNat -Name "NAT-Rennes" -InternalIPInterfaceAddressPrefix "192.168.3.0/24"
```

> [!WARNING] Un seul NAT par préfixe
> Windows n'accepte qu'**un** objet `NetNat` couvrant un même préfixe. Si un ancien lab utilise déjà `192.168.3.0/24` (`Get-NetNat`), réutiliser ce NAT et déplacer simplement l'IP `.254` sur `vEthernet (vSwitch-Rennes)`.

---

## Fichiers et dossiers de travail (hôte)

| Chemin | Contenu |
|--------|---------|
| `D:\HyperV\` | VM et disques (`Set-VMHost`) |
| `D:\ISO\` | ISO Windows 11, Windows Server 2025, ISO générées |
| `D:\Images\` | `install.wim`, `MASTER.wim`, `autounattend.xml` |
| `D:\WinPE\` | Dossier de travail WinPE (`copype`) |
| `D:\ISO-Deploiement\` | Copie de l'ISO à reconstruire (`oscdimg`) |

---

## Récapitulatif express

```
Réseau     192.168.3.0/24 sur vSwitch-Rennes (interne + NAT) — passerelle .254
SRV01      192.168.3.1    Server 2025 Core — AD DS / DNS / DHCP
PC01       192.168.3.10   Windows 11 Pro 26H2 — poste admin
PC02       DHCP           cible du déploiement (chap. 16)
MASTER     Default Switch VM de référence réutilisable (chap. 14)
Domaine    ad.fournil.lab | FOURNIL | Win2025
DHCP       192.168.3.100-200 | routeur .254 | DNS .1
Mot de passe de lab : Fournil2026!
```
