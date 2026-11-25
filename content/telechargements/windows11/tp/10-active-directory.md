# TP 10. Intégration Active Directory

> Chapitres associés : [10. Intégration Active Directory](https://cours.kaya.ovh/windows11/windows11/10-active-directory/)

---

## Objectifs

Tu prépares `SRV01` sur l’hôte Hyper-V, puis tu crées le domaine sur `SRV01`. Le TP est terminé quand `PC01` apparaît dans l’UO `Fournil → Ordinateurs` et que `FOURNIL\stagiaire` peut y ouvrir une session.

- Installer `SRV01` (Windows Server 2025 avec expérience de bureau) et le préparer (IP et nom), puis tester l’accès SSH en (bonus)
- Créer la forêt `ad.fournil.lab` (AD DS + DNS) et le DHCP
- Créer la structure d'UO, les utilisateurs et les groupes du Fournil
- Joindre `PC01` au domaine **dans la bonne UO** et vérifier la jonction

---

## Prérequis

- ISO Windows Server 2025 (évaluation) dans `D:\ISO\`
- `PC01` opérationnel sur `vSwitch-Rennes`

---

## Partie A — Installer et préparer SRV01

**A1.** Depuis l’hôte Hyper-V, crée la VM `SRV01` (Gen 2, 4 Go **statiques**, 2 vCPU, 64 Go, `vSwitch-Rennes`). Installe **Windows Server 2025 Standard Evaluation (expérience utilisateur)** et définis le mot de passe Administrateur du lab `Fournil2026!`.

**A2.** Sur `SRV01`, configure l’adresse `192.168.3.1/24`, la passerelle `192.168.3.254` et le DNS provisoire `1.1.1.1`. Renomme le serveur en `SRV01`, puis redémarre-le. Tu peux utiliser **Gestionnaire de serveur → Serveur local** ou PowerShell.

**A3.** (bonus) Sur `SRV01`, démarre le service OpenSSH Server et vérifie que sa règle de pare-feu autorise le profil réseau actif. Depuis `PC01`, ouvre ensuite une session SSH vers `192.168.3.1`.

---

## Partie B — Domaine, DNS, DHCP

**B1.** Installe les rôles AD DS, DNS et DHCP (assistant *Ajouter des rôles et fonctionnalités*, ou une seule commande PowerShell).

**B2.** Sur `SRV01`, crée la forêt `ad.fournil.lab` avec le nom NetBIOS `FOURNIL` et le niveau fonctionnel `Win2025`. Laisse le serveur terminer son redémarrage automatique, puis ouvre la session `FOURNIL\Administrateur`.

**B3.** Sur `SRV01`, vérifie que `Get-ADDomain` affiche `ad.fournil.lab`. Vérifie ensuite que le DNS client pointe vers le serveur lui-même et que les zones `ad.fournil.lab` et `_msdcs.ad.fournil.lab` existent.

> Si `Get-ADDomain` renvoie une erreur liée aux services Web Active Directory au premier démarrage, attends un court instant puis relance la commande. Voir [la vérification post-promotion dans le cours](https://cours.kaya.ovh/windows11/windows11/10-active-directory/#v%C3%A9rification-post-promotion).

**B4.** Déclare un redirecteur DNS vers `1.1.1.1`, puis vérifie que `SRV01` résout un nom Internet.

**B5.** Autorise le DHCP dans AD et crée l'étendue `vSwitch-Rennes` `192.168.3.100-200` (routeur `.254`, DNS `.1`, domaine `ad.fournil.lab`). Vérifie ensuite les trois options de l'étendue.

---

## Partie C — Structure du Fournil

**C1.** Crée l'arborescence d'UO : `Fournil` › `Utilisateurs`, `Ordinateurs`, `Groupes`, `Admins` (dans `dsa.msc` ou en PowerShell).

**C2.** Dans l’UO `Utilisateurs`, crée le compte `stagiaire` (nom complet *Stagiaire Boulangerie*). Dans l’UO `Admins`, crée le compte `adm.stagiaire`. Utilise le mot de passe du lab `Fournil2026!` pour les deux comptes et décoche le changement obligatoire à la première connexion.

**C3.** Dans l’UO `Groupes`, crée deux groupes de sécurité globaux. Ajoute `stagiaire` à `G-Boulangerie` et `adm.stagiaire` à `G-Admins-Postes`.

**C4.** Pour joindre `PC01` via l’interface graphique en D3, configure maintenant l’UO `Fournil → Ordinateurs` comme destination par défaut des nouveaux postes avec `redircmp`. Si tu utilises PowerShell avec `-OUPath` en D3, passe directement à la partie D.

---

## Partie D — Joindre PC01

**D1.** Sur `PC01`, configure `192.168.3.1` comme seul serveur DNS. Vérifie avec `Resolve-DnsName ad.fournil.lab` que le nom renvoie `192.168.3.1`.

**D2.** Avant de joindre le domaine, vérifie que `PC01` trouve `SRV01` et peut le joindre. Ouvre **PowerShell sur `PC01`**.

1. Demande au DNS quel serveur est le contrôleur du domaine `ad.fournil.lab`.

   ```powershell
   Resolve-DnsName _ldap._tcp.dc._msdcs.ad.fournil.lab -Type SRV | Select-Object NameTarget
   ```

   La colonne `NameTarget` doit afficher `srv01.ad.fournil.lab`.

2. Vérifie que `PC01` peut atteindre le service d’annuaire (LDAP) sur `SRV01`.

   ```powershell
   Test-NetConnection 192.168.3.1 -Port 389
   ```

   Cherche la ligne `TcpTestSucceeded : True`. Si les deux vérifications réussissent, passe à D3.

**D3.** Joins `PC01` au domaine (`sysdm.cpl` ou `Add-Computer`), de façon qu'il arrive dans `OU=Ordinateurs,OU=Fournil`.

**D4.** Après redémarrage, vérifie sur `PC01` qu’il est membre de `ad.fournil.lab`. Sur `SRV01`, vérifie que l’objet `PC01` se trouve dans l’UO `Fournil → Ordinateurs`.

**D5.** Qui est désormais administrateur local de `PC01` ? D'où vient ce changement ?

**D6.** Sur `PC01`, ouvre une session avec `FOURNIL\stagiaire`. Vérifie que `whoami` affiche `fournil\stagiaire`.

---

## Partie E — Exercices complémentaires (bonus)

**E1.** `w32tm /query /source` sur `PC01` renvoie « VM IC Time Synchronization Provider ». Pourquoi est-ce un problème pour un membre du domaine ? Comment corriger ?

**E2.** Le canal sécurisé de `PC01` est cassé (« La relation d'approbation entre cette station de travail et le domaine principal a échoué »). Répare-le sans quitter le domaine.

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp/standard-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp/standard-corrigev2)
