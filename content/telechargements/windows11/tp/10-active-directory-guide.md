# TP 10. Intégration Active Directory, version guidée

**Ta mission.** Préparer le serveur du Fournil, créer le domaine `ad.fournil.lab`, puis y joindre le poste `PC01`. À la fin, le compte `FOURNIL\stagiaire` doit pouvoir ouvrir une session sur `PC01`, et le poste doit apparaître dans l’UO `Fournil → Ordinateurs` sur le serveur.

**Avant de commencer.** Il te faut l’ISO Windows Server 2025, un accès au Gestionnaire Hyper-V et la VM `PC01` utilisée dans les TP précédents. Elle est raccordée à `vSwitch-Rennes` et utilise l’adresse `192.168.3.10`.

| Machine | Ce que tu y fais |
| --- | --- |
| **Hôte Hyper-V** | Tu crées et démarres la VM `SRV01`. |
| **`SRV01`** | Tu prépares le serveur, puis tu configures le domaine, le DNS, le DHCP et les comptes. |
| **`PC01`** | Tu vérifies l’accès au serveur, tu joins le domaine et tu testes le compte du stagiaire. |

[Retrouver les explications et les captures dans le cours](https://cours.kaya.ovh/windows11/windows11/10-active-directory/)

## A — Préparer le serveur

### A1 — Installer Windows Server sur `SRV01`

1. Sur **l’hôte Hyper-V**, crée une VM de **génération 2** appelée `SRV01`. Donne-lui **4 Go de RAM statique**, **2 processeurs virtuels** et un disque de **64 Go**. Raccorde-la à `vSwitch-Rennes`.
2. Attache l’ISO Windows Server 2025 au lecteur DVD virtuel, puis démarre la VM sur l’ISO.
3. Dans l’installateur, choisis **Windows Server 2025 Standard Evaluation (expérience utilisateur)**. Au premier démarrage, définis le mot de passe Administrateur du lab `Fournil2026!` et ouvre la session.

**Tu peux continuer quand** le bureau s’affiche dans la console de `SRV01` et que le Gestionnaire de serveur s’ouvre.

### A2 — Donner une adresse fixe au serveur

1. Dans **`SRV01`**, ouvre **Gestionnaire de serveur → Serveur local**. Clique sur le lien de la carte **Ethernet**. Dans la fenêtre des connexions réseau, fais un clic droit sur **Ethernet → Propriétés**, puis ouvre **Protocole Internet version 4 (TCP/IPv4)**.
2. Renseigne ces valeurs.

   | Champ | Valeur |
   | --- | --- |
   | Adresse IP | `192.168.3.1` |
   | Masque de sous-réseau | `255.255.255.0` |
   | Passerelle | `192.168.3.254` |
   | DNS préféré, provisoire | `1.1.1.1` |

3. De retour dans **Serveur local**, clique sur le nom de l’ordinateur, puis sur **Modifier…**. Saisis `SRV01` et redémarre la VM.
4. Après reconnexion, lance `hostname` puis `ipconfig` dans PowerShell.

**Résultat attendu.** Le nom est `SRV01` et la carte Ethernet affiche `192.168.3.1`. Le DNS provisoire sert à résoudre les noms Internet pendant la préparation du serveur.

### A3 — Tester l’accès SSH depuis `PC01`

1. Sur **`SRV01`**, ouvre PowerShell **en administrateur**. Lance les commandes ci-dessous. La règle du pare-feu autorise la connexion sur le profil Public pendant la préparation et sur le profil Domaine après la promotion.

   ```powershell
   Start-Service sshd
   Set-Service sshd -StartupType Automatic
   Set-NetFirewallRule -Name OpenSSH-Server-In-TCP -Enabled True -Profile Domain,Private,Public
   ```

2. Sur **`PC01`**, ouvre PowerShell et lance `ssh administrateur@192.168.3.1`. À la première connexion au serveur du lab, valide l’empreinte proposée, puis saisis le mot de passe Administrateur.
3. Dans la session SSH, lance `hostname`. Quand tu as vérifié le résultat, quitte avec `exit`.

**Résultat attendu.** `hostname` affiche `SRV01`. Si la connexion échoue, vérifie que les deux VM sont sur `vSwitch-Rennes` et que `Get-Service sshd` affiche `Running` sur le serveur.

## B — Créer le domaine et configurer ses services

Travaille dans la **console Hyper-V de `SRV01`** pour cette partie, afin de garder l’accès au serveur pendant son redémarrage.

### B1 — Installer les rôles

1. Ouvre **Gestionnaire de serveur → Gérer → Ajouter des rôles et fonctionnalités**. Choisis l’installation basée sur un rôle et sélectionne `SRV01`.
2. Coche **Services de domaine Active Directory**, **Serveur DNS** et **Serveur DHCP**. Accepte l’ajout des outils proposés, puis lance l’installation.

**Résultat attendu.** L’installation réussit et le drapeau du Gestionnaire de serveur propose **Promouvoir ce serveur en contrôleur de domaine**.

### B2 — Créer le domaine `ad.fournil.lab`

1. Clique sur **Promouvoir ce serveur en contrôleur de domaine**. Choisis **Ajouter une nouvelle forêt** et saisis `ad.fournil.lab` comme nom de domaine racine.
2. Dans les **Options du contrôleur de domaine**, laisse les niveaux fonctionnels sur **Windows Server 2025** et conserve **Serveur DNS** et **Catalogue global** cochés. Pour le mot de passe de restauration (DSRM), saisis `Fournil2026!` dans le lab.
3. À la page **Options supplémentaires**, remplace le nom NetBIOS proposé par `FOURNIL`. C’est le nom court que tu utiliseras pour ouvrir les sessions de domaine.
4. Garde les chemins par défaut. Une fois la vérification des prérequis réussie, clique sur **Installer** et laisse la VM terminer son redémarrage automatique. L’avertissement sur la délégation DNS est attendu dans ce lab.

**Résultat attendu.** Après le redémarrage, tu peux ouvrir la session `FOURNIL\Administrateur`.

### B3 — Vérifier le domaine et le DNS

Dans PowerShell sur **`SRV01`**, lance les commandes une par une.

```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName
Get-DnsClientServerAddress -AddressFamily IPv4
Get-DnsServerZone | Select-Object ZoneName
```

- `DNSRoot` affiche `ad.fournil.lab` et `NetBIOSName` affiche `FOURNIL`.
- Sur la ligne de la carte Ethernet, le serveur DNS pointe vers `SRV01` lui-même. Dans le lab, la promotion renseigne `127.0.0.1`.
- La liste des zones contient `ad.fournil.lab` et `_msdcs.ad.fournil.lab`.

Si `Get-ADDomain` signale que les services Web Active Directory sont indisponibles juste après le redémarrage, attends une à deux minutes et relance la commande.

### B4 — Configurer la résolution des noms Internet

1. Sur **`SRV01`**, ouvre `dnsmgmt.msc`. Fais un clic droit sur **SRV01 → Propriétés → Redirecteurs → Modifier…** et ajoute `1.1.1.1`.
2. Dans PowerShell sur **`SRV01`**, lance `Resolve-DnsName www.microsoft.com`.

**Résultat attendu.** La commande renvoie une réponse DNS avec une ou plusieurs adresses IP.

### B5 — Préparer la distribution des adresses IP

1. Sur **`SRV01`**, clique sur le drapeau du Gestionnaire de serveur, puis sur **Terminer la configuration DHCP**. Valide l’autorisation avec le compte de la session de domaine.
2. Ouvre `dhcpmgmt.msc`. Déplie `srv01.ad.fournil.lab`, sélectionne **IPv4**, puis ouvre **Nouvelle étendue…** avec le clic droit. Renseigne les valeurs ci-dessous.

   | Champ | Valeur |
   | --- | --- |
   | Nom de l’étendue | `vSwitch-Rennes` |
   | Début / fin de la plage | `192.168.3.100` / `192.168.3.200` |
   | Longueur du masque | `24` |
   | Routeur | `192.168.3.254`, puis clique sur **Ajouter** |
   | Serveur DNS et domaine DNS | `192.168.3.1` et `ad.fournil.lab` |

3. Garde la durée de bail par défaut. Lorsque l’assistant te demande de configurer les options DHCP, choisis **Oui** pour pouvoir renseigner le routeur et le DNS du tableau. Active l’étendue à la fin de l’assistant.
4. Dans **Options d’étendue**, contrôle les valeurs de **003 Routeur**, **006 Serveurs DNS** et **015 Nom de domaine DNS**.

**Résultat attendu.** L’étendue est active et les trois options reprennent les valeurs du tableau. `PC01` utilise encore son adresse fixe `192.168.3.10`. Tu modifieras seulement son DNS en D1.

## C — Préparer les comptes et l’emplacement du poste

### C1 — Créer les unités d’organisation

1. Sur **`SRV01`**, ouvre `dsa.msc` pour lancer **Utilisateurs et ordinateurs Active Directory**.
2. Fais un clic droit sur `ad.fournil.lab` → **Nouveau → Unité d’organisation**, puis crée `Fournil`.
3. Fais un clic droit **sur `Fournil`** et répète l’action pour créer quatre sous-UO.

   ```text
   Fournil
   ├── Admins
   ├── Groupes
   ├── Ordinateurs
   └── Utilisateurs
   ```

**Résultat attendu.** Quand tu déplies `Fournil`, les quatre UO sont au même niveau.

### C2 — Créer les deux comptes

Dans chaque UO, fais un clic droit → **Nouveau → Utilisateur**. Renseigne le nom et le nom d’ouverture de session indiqués dans le tableau.

| UO | Nom complet | Nom d’ouverture de session |
| --- | --- | --- |
| `Utilisateurs` | Stagiaire Boulangerie | `stagiaire` |
| `Admins` | Admin Postes Stagiaire | `adm.stagiaire` |

Dans ce lab, utilise `Fournil2026!` pour les deux comptes et décoche **L’utilisateur doit changer le mot de passe à la prochaine ouverture de session**.

**Résultat attendu.** Les deux comptes apparaissent dans les UO correspondantes. Garde `stagiaire` pour le test de connexion en D6.

### C3 — Créer les groupes et ajouter leurs membres

1. Dans l’UO `Groupes`, crée `G-Boulangerie` et `GG-Admins-Postes` via **Nouveau → Groupe**. Pour chacun, choisis **Globale** et **Sécurité**.
2. Double-clique sur chaque groupe, puis ouvre **Membres → Ajouter…**. Dans `G-Boulangerie`, ajoute `stagiaire`. Dans `GG-Admins-Postes`, ajoute `adm.stagiaire`. Pour chaque compte, utilise **Vérifier les noms**, puis valide.

**Résultat attendu.** L’onglet **Membres** de chaque groupe affiche le compte prévu.

### C4 — Préparer l’arrivée de `PC01` dans la bonne UO

Sur **`SRV01`**, ouvre PowerShell en administrateur et lance la commande suivante. Elle indique à Active Directory où ranger les nouveaux comptes ordinateurs lors de la jonction par l’interface graphique.

```powershell
redircmp "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"
```

**Résultat attendu.** La commande indique que la redirection a réussi.

## D — Joindre `PC01` au domaine

### D1 — Indiquer à `PC01` où trouver le DNS du domaine

1. Sur **`PC01`**, lance `ncpa.cpl` et ouvre **Ethernet → Propriétés → Protocole Internet version 4 (TCP/IPv4)**.
2. Mets `192.168.3.1` en **DNS préféré** et vide le champ **DNS auxiliaire**. Conserve l’adresse du poste `192.168.3.10` et sa passerelle `192.168.3.254`.
3. Dans PowerShell sur `PC01`, lance `Resolve-DnsName ad.fournil.lab`.

**Résultat attendu.** La réponse contient `192.168.3.1`. `PC01` interroge désormais le DNS du Fournil pour résoudre le nom du domaine.

### D2 — Vérifier que `PC01` trouve le contrôleur de domaine

Dans PowerShell, toujours sur **`PC01`**, fais ces deux tests.

1. Demande au DNS quel serveur assure le rôle de contrôleur pour `ad.fournil.lab`.

   ```powershell
   Resolve-DnsName _ldap._tcp.dc._msdcs.ad.fournil.lab -Type SRV | Select-Object NameTarget
   ```

   **À lire.** `NameTarget` doit afficher `srv01.ad.fournil.lab`. Si le nom ne s’affiche pas, vérifie le DNS de `PC01` en D1 puis les zones sur `SRV01` en B3.

2. Vérifie que `PC01` peut atteindre le service d’annuaire LDAP sur ce serveur.

   ```powershell
   Test-NetConnection 192.168.3.1 -Port 389
   ```

   **À lire.** Cherche `TcpTestSucceeded : True`. Si tu obtiens `False`, vérifie que `SRV01` est démarré et que les deux VM sont sur `vSwitch-Rennes`, puis relance le test.

Quand les deux résultats sont bons, passe à D3.

### D3 — Faire entrer `PC01` dans le domaine

1. Sur **`PC01`**, ouvre `sysdm.cpl` → **Nom de l’ordinateur → Modifier…**.
2. Sélectionne **Domaine** et saisis `ad.fournil.lab`. Quand Windows demande les identifiants, utilise `FOURNIL\Administrateur` et le mot de passe du lab.
3. Lorsque Windows affiche **« Bienvenue dans le domaine ad.fournil.lab »**, valide et redémarre `PC01`.

### D4 — Vérifier la jonction et l’emplacement de `PC01`

- Sur **`PC01`**, ouvre une session avec ton compte local en le préfixant par `PC01\`, par exemple `PC01\admin`. Ouvre `sysdm.cpl` et repère le domaine `ad.fournil.lab` dans l’onglet **Nom de l’ordinateur**.
- Sur **`SRV01`**, ouvre `dsa.msc`. Dans `Fournil → Ordinateurs`, cherche l’objet `PC01`. Actualise la console si elle était ouverte avant la jonction.

**Résultat attendu.** Le domaine est affiché sur le poste et son objet ordinateur est visible dans la bonne UO sur le serveur.

### D5 — Observer les administrateurs locaux de `PC01`

Sur **`PC01`**, lance `Get-LocalGroupMember Administrateurs` dans PowerShell. Repère le groupe `FOURNIL\Admins du domaine`. Windows l’ajoute aux administrateurs locaux lors de la jonction. Tu retrouveras ce réglage dans le TP sur les GPO.

### D6 — Tester le compte du stagiaire

1. Sur **`PC01`**, ferme la session locale, puis choisis **Autre utilisateur**.
2. Saisis `FOURNIL\stagiaire` et le mot de passe du lab. Une fois sur le bureau, ouvre PowerShell et lance `whoami`.

**Résultat attendu.** La commande affiche `fournil\stagiaire`. Tu as vérifié que le poste accepte une ouverture de session avec le compte créé dans le domaine.

[Bonus sur l’heure et le canal sécurisé, partie E du TP](https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp/standard)

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/10-active-directory/tp/guide-corrigev2)
