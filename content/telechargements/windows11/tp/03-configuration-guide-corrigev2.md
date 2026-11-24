# TP 03. Configuration et personnalisation, corrigé guidé

**Ta mission.** Configure le poste `PC01` installé au TP 02. Tu termines quand le compte standard, les trois tests réseau et les variables d’environnement sont vérifiés.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/03-configuration/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/03-configuration/tp/standard)

## Organiser le poste de travail

### A1 — Régler Démarrer et la barre des tâches

Sur `PC01`, ouvre **Paramètres → Personnalisation → Démarrer** et masque les recommandations disponibles. Dans **Barre des tâches**, masque **Widgets** et règle l’alignement à gauche.

> [!success]- Afficher la correction — A1
> Le bouton Widgets disparaît et les icônes sont alignées à gauche. Les options proposées dans Démarrer peuvent dépendre du build.

### A2 — Organiser fenêtres et bureaux

Ouvre trois fenêtres. Sur la première, lance `Win + Z` et choisis le modèle à trois zones si l’écran le propose. Utilise `Win + Tab` pour créer un bureau **Admin**, et ouvre un terminal sur ce bureau.

> [!success]- Afficher la correction — A2
> Le bureau initial conserve tes fenêtres. **Vue des tâches** présente le bureau **Admin** et permet de revenir au premier.

## Gérer des comptes locaux

### B1 — Créer un compte standard

Ouvre `lusrmgr.msc` → **Utilisateurs → Nouvel utilisateur**. Crée `employe1` avec le mot de passe du lab. Ouvre ses propriétés et vérifie l’onglet **Membre de**.

> [!success]- Afficher la correction — B1
> `employe1` appartient au groupe **Utilisateurs**. Sa session sert aux essais de moindre privilège du TP 09.

### B2 — Lire l’identifiant du compte (bonus)

Dans PowerShell, lance `Get-LocalUser -Name employe1 | Select-Object Name,SID`. Entoure la dernière partie du SID dans ta fiche.

> [!success]- Afficher la correction — B2
> Le dernier nombre est le RID. Le préfixe identifie l’autorité de comptes locale. Renommer un compte ne remplace pas son SID.

### B3 — Désactiver un deuxième compte

Crée `employe2` dans la même console. Coche **L’utilisateur doit changer le mot de passe à la prochaine ouverture de session**. Après vérification de son groupe, désactive-le depuis ses propriétés.

> [!success]- Afficher la correction — B3
> Le compte existe mais est désactivé. `Get-LocalUser -Name employe2` affiche `Enabled : False` dans une sortie détaillée.

## Configurer et tester le réseau

### C1 — Relever la configuration actuelle

Sur `PC01`, lance `ipconfig /all`. Relève l’adresse IPv4, la passerelle et les serveurs DNS de la carte Ethernet.

> [!success]- Afficher la correction — C1
> La ligne **DHCP activé** indique si la configuration IPv4 est obtenue à partir d’un bail. Garde un relevé avant de la changer.

### C2 — Régler l’IPv4 du lab

Ouvre `ncpa.cpl`. Sur **Ethernet → Propriétés → Protocole Internet version 4**, saisis `192.168.3.10`, masque `255.255.255.0`, passerelle `192.168.3.254` et DNS `8.8.8.8` puis `1.1.1.1`. Confirme avec `ipconfig /all`.

> [!success]- Afficher la correction — C2
> La carte doit afficher les valeurs du lab. Le DNS sera remplacé par celui de `SRV01` à la jonction au domaine.

### C3 — Tester dans le bon ordre

Depuis `PC01`, lance `ping 192.168.3.254`, puis `Test-NetConnection 1.1.1.1 -Port 443`, puis `Resolve-DnsName www.microsoft.com`. Note le premier test en défaut.

> [!success]- Afficher la correction — C3
> Les trois étapes isolent respectivement le réseau du lab, la sortie Internet par IP et la résolution DNS. Un ping refusé peut venir du pare-feu de la passerelle. Compare avec le test TCP avant de conclure.

## Modifier une variable système

### D1 — Créer la variable et vérifier sa portée

Ouvre `sysdm.cpl` → **Paramètres système avancés → Variables d’environnement**. Dans **Variables système**, ajoute `FOURNIL_ENV` avec la valeur `lab`. Ouvre un nouveau PowerShell et lance `$env:FOURNIL_ENV`.

> [!success]- Afficher la correction — D1
> Le nouveau processus affiche `lab`. Un terminal déjà lancé peut encore utiliser l’ancien environnement.

### D2 — Ajouter un dossier au PATH

Dans la même fenêtre, sélectionne **Path** dans **Variables système**, clique sur **Modifier → Nouveau**, ajoute `C:\Outils` et ouvre un nouveau terminal. Vérifie que la nouvelle entrée et les anciennes sont visibles dans `$env:Path -split ';'`.

> [!success]- Afficher la correction — D2
> `C:\Outils` s’ajoute à la liste. Les entrées existantes doivent toujours être présentes pour garder leurs commandes accessibles.

[Retour à l’énoncé guidé](https://cours.kaya.ovh/windows11/windows11/03-configuration/tp/guide)
