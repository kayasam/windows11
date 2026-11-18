# TP 03. Configuration et personnalisation, version guidée

**Ta mission.** Configure le poste `PC01` installé au TP 02. Tu termines quand le compte standard, les trois tests réseau et les variables d’environnement sont vérifiés.

[Revoir le cours](https://cours.kaya.ovh/windows11/windows11/03-configuration/) · [Ouvrir le TP d’origine et les exercices complémentaires](https://cours.kaya.ovh/windows11/windows11/03-configuration/tp/standard)

## Organiser le poste de travail

### A1 — Régler Démarrer et la barre des tâches

Sur `PC01`, ouvre **Paramètres → Personnalisation → Démarrer** et masque les recommandations disponibles. Dans **Barre des tâches**, masque **Widgets** et règle l’alignement à gauche.

### A2 — Organiser fenêtres et bureaux

Ouvre trois fenêtres. Sur la première, lance `Win + Z` et choisis le modèle à trois zones si l’écran le propose. Utilise `Win + Tab` pour créer un bureau **Admin**, et ouvre un terminal sur ce bureau.

## Gérer des comptes locaux

### B1 — Créer un compte standard

Ouvre `lusrmgr.msc` → **Utilisateurs → Nouvel utilisateur**. Crée `employe1` avec le mot de passe du lab. Ouvre ses propriétés et vérifie l’onglet **Membre de**.

### B2 — Lire l’identifiant du compte

Dans PowerShell, lance `Get-LocalUser -Name employe1 | Select-Object Name,SID`. Entoure la dernière partie du SID dans ta fiche.

### B3 — Désactiver un deuxième compte

Crée `employe2` dans la même console. Coche **L’utilisateur doit changer le mot de passe à la prochaine ouverture de session**. Après vérification de son groupe, désactive-le depuis ses propriétés.

## Configurer et tester le réseau

### C1 — Relever la configuration actuelle

Sur `PC01`, lance `ipconfig /all`. Relève l’adresse IPv4, la passerelle et les serveurs DNS de la carte Ethernet.

### C2 — Régler l’IPv4 du lab

Ouvre `ncpa.cpl`. Sur **Ethernet → Propriétés → Protocole Internet version 4**, saisis `192.168.3.10`, masque `255.255.255.0`, passerelle `192.168.3.254` et DNS `8.8.8.8` puis `1.1.1.1`. Confirme avec `ipconfig /all`.

### C3 — Tester dans le bon ordre

Depuis `PC01`, lance `ping 192.168.3.254`, puis `Test-NetConnection 1.1.1.1 -Port 443`, puis `Resolve-DnsName www.microsoft.com`. Note le premier test en défaut.

## Modifier une variable système

### D1 — Créer la variable et vérifier sa portée

Ouvre `sysdm.cpl` → **Paramètres système avancés → Variables d’environnement**. Dans **Variables système**, ajoute `FOURNIL_ENV` avec la valeur `lab`. Ouvre un nouveau PowerShell et lance `$env:FOURNIL_ENV`.

### D2 — Ajouter un dossier au PATH

Dans la même fenêtre, sélectionne **Path** dans **Variables système**, clique sur **Modifier → Nouveau**, ajoute `C:\Outils` et ouvre un nouveau terminal. Vérifie que la nouvelle entrée et les anciennes sont visibles dans `$env:Path -split ';'`.

[Ouvrir le corrigé guidé](https://cours.kaya.ovh/windows11/windows11/03-configuration/tp/guide-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/03-configuration/tp/guide-corrigev2)
