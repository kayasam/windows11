# 00. Infrastructure de référence (fil rouge)

> [!NOTE] Objectif
> Ce chapitre n'a pas de TP — c'est la fiche de référence du **fil rouge Entreprise Fournil** qui traverse toute la formation. Adressage IP, domaine, UO, comptes, DHCP, réseau virtuel : tout ce qui est posé progressivement est récapitulé ici, à consulter à tout moment.

---

## Schéma du lab

![Réseau du lab Fournil — L’hôte Hyper-V relie Internet à vSwitch-Rennes pour SRV01, PC01 et PC02, et au Default Switch pour MASTER.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-00-lab-fournil.svg)

---

## Tableau d'adressage IP

| Machine | Rôle | IP | Passerelle | DNS | Créée au |
|---------|------|----|------------|-----|----------|
| Hôte `vEthernet (vSwitch-Rennes)` | Passerelle NAT | `192.168.3.254/24` | — | — | chap. 01 |
| **SRV01** | Contrôleur de domaine (AD DS, DNS, DHCP) | `192.168.3.1` | `.254` | `192.168.3.1` | chap. 10 |
| **PC01** | Poste d'administration Windows 11 Pro | `192.168.3.10` | `.254` | `1.1.1.1` → `192.168.3.1` (chap. 10) | chap. 01-02 |
| **PC02** | Poste cible du déploiement | DHCP (`.100`–`.200`) | via DHCP | via DHCP | chap. 16 |
| **MASTER** | VM de référence (image) — *approfondissement* | DHCP du Default Switch | — | — | chap. 14 |

> [!NOTE] Chronologie
> `PC01` reçoit son IP fixe au chapitre 03. `SRV01` n'existe qu'à partir du chapitre 10 : avant, `PC01` utilise un DNS public. `MASTER` (chapitre 14) n'est **jamais** jointe au domaine et vit sur le **Default Switch** (Internet sans configuration). `PC02` n'apparaît qu'au chapitre 16.

---

## Comptes du lab

| Compte | Où | Mot de passe (lab) | Usage |
|--------|----|--------------------|-------|
| `admin` | PC01 (local, Administrateurs) | `Fournil2026!` | Compte créé à l'installation |
| `Administrateur` | SRV01 puis domaine | `Fournil2026!` | Administration du domaine (Tier 0) |
| DSRM | SRV01 | `Fournil2026!` | Restauration des services d'annuaire |
| `stagiaire` | Domaine | `Fournil2026!` | Utilisateur standard |
| `adm.stagiaire` | Domaine | `Fournil2026!` | Compte d'administration des postes (chap. 11) |

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

![Arborescence Active Directory — Dans ad.fournil.lab, l’UO Fournil regroupe les utilisateurs, les ordinateurs, les groupes et les comptes d’administration.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-00-uo-fournil.svg)

| Objet | Type | Détail |
|-------|------|--------|
| `stagiaire` | Utilisateur | Utilisateur standard, mot de passe `Fournil2026!` (pas de changement imposé dans le lab) |
| `adm.stagiaire` | Utilisateur | Membre de `GG-Admins-Postes` |
| `G-Boulangerie` | Groupe global de sécurité | Contient `stagiaire` — filtrage des GPO |
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
| `D:\Images\` | `autounattend.xml`, mini-ISO de réponses ; `install.wim`, `MASTER.wim` (approfondissement) |
| `D:\WinPE\` | Dossier de travail WinPE (`copype`) |
| `D:\ISO-Deploiement\` | Copie de l'ISO à reconstruire (`oscdimg`) |

---

## Récapitulatif express

> [!summary] L'essentiel du lab en un coup d'œil
> - **Réseau** : `192.168.3.0/24` sur `vSwitch-Rennes` (interne + NAT), passerelle `192.168.3.254`
> - **SRV01** : `192.168.3.1`, Windows Server 2025 Core — AD DS, DNS, DHCP
> - **PC01** : `192.168.3.10`, Windows 11 Pro 26H2 — poste d'administration
> - **PC02** : adresse DHCP — cible du déploiement (chapitre 16)
> - **MASTER** *(approfondissement)* : sur `Default Switch` — VM de référence (chapitre 14), inutile pour le déploiement du chapitre 16
> - **Domaine** : `ad.fournil.lab`, NetBIOS `FOURNIL`, niveau fonctionnel `Win2025`
> - **DHCP** : plage `192.168.3.100` → `192.168.3.200`, routeur `.254`, DNS `.1`
> - **Comptes** : `admin`, `Administrateur`, `stagiaire`, `adm.stagiaire`
> - **Mot de passe de lab** : `Fournil2026!`, pour tous les comptes
