---
title: "11. Stratégies de groupe et gestion centralisée"
---

<nav class="chapter-resources" aria-label="Ressources du chapitre" data-course-key="windows11/11-gpo"><div class="resource-buttons"><a class="resource-button" data-resource-kind="markdown" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 24"><rect x="1" y="1" width="30" height="22" rx="3" fill="none" stroke="#34495e" stroke-width="2"/><path d="M5 18V6h3l4 5 4-5h3v12h-3v-7l-4 5-4-5v7Z" fill="#34495e"/><path d="M23 6h3v7h3l-4.5 5-4.5-5h3Z" fill="#34495e"/></svg>
</span><span class="resource-label">Cours</span></a><a class="resource-button" data-resource-kind="quiz" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/quiz/"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="4" y="3" width="24" height="26" rx="6" fill="#7652ad"/><path d="M12 12a4 4 0 1 1 6 3.5c-1.5.8-2 1.4-2 3" fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round"/><circle cx="16" cy="23" r="1.6" fill="#fff"/></svg>
</span><span class="resource-label">Quiz</span></a><a class="resource-button" data-resource-kind="tp" href="https://cours.kaya.ovh/windows11/windows11/11-gpo/tp"><span class="resource-icon"><svg class="resource-symbol" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect x="2" y="4" width="28" height="24" rx="5" fill="#237b60"/><path d="m8 12 5 4-5 4m9 0h7" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
</span><span class="resource-label">TP</span></a></div><div class="resource-actions"><a class="resource-download" download data-router-ignore href="https://cours.kaya.ovh/windows11/telechargements/windows11/cours/11-gpo.md">↓ Télécharger le cours (.md)</a><button type="button" class="support-focus-toggle" aria-pressed="false">Masquer les menus</button></div></nav>

> [!abstract] Parcours TSSR
> Les GPO se créent directement sur **SRV01** (console *Gestion de stratégie de groupe*, installée avec AD DS) : aucun téléchargement n'est nécessaire. Installer les RSAT sur PC01 est facultatif (≈ 10 min). Le partage Commun doit exister avant C ; sa préparation guidée est incluse dans C.
> Les sections marquées (bonus) sont facultatives.

> [!NOTE] Objectif
> Centraliser la configuration des postes du domaine avec les **stratégies de groupe** : comprendre l'ordre d'application, distinguer paramètres ordinateur et utilisateur, cibler une GPO (liaison, filtrage, préférences), diagnostiquer avec `gpresult`. Mettre en place les GPO de sécurité modernes : **Windows LAPS**, sauvegarde des clés **BitLocker** dans AD, administrateurs locaux, anneau Windows Update. Situer **Intune / Entra ID** face aux GPO.
>
> **Outils :** GPMC (`gpmc.msc`, via RSAT), éditeur de GPO, `gpupdate`, `gpresult`, `rsop.msc`
> **Commandes à connaître :** `New-GPO`, `New-GPLink`, `Set-GPRegistryValue`, `Set-GPPermission`, `Get-GPResultantSetOfPolicy`, `Get-LapsADPassword`

> [!INFO] Fil rouge — Fournil
> Le TP crée une GPO par objectif. Sous **Fournil → Ordinateurs**, `GPO-Postes-Admins-Locaux` ajoute le groupe des techniciens et `GPO-Postes-LAPS` prépare le compte local `adm-laps`.
> Sous **Fournil → Utilisateurs**, `GPO-Utilisateurs-Lecteur-Commun` distribue `P:` aux membres de `G-Boulangerie`. Windows Update, la restriction du Panneau de configuration et BitLocker ont leurs propres GPO dans les ateliers facultatifs.

---

## 1. Qu'est-ce qu'une GPO ?

Une **GPO** (*Group Policy Object*) est un ensemble de paramètres stocké dans le domaine et appliqué automatiquement aux **ordinateurs** et aux **utilisateurs** situés dans les conteneurs où elle est liée.

![Les deux parties d’une GPO — Le contrôleur de domaine conserve l’objet GPO dans Active Directory et les fichiers de la stratégie dans SYSVOL.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-11-composition-gpo.svg)

Le poste télécharge et applique les GPO :
- **au démarrage** (paramètres ordinateur) et **à l'ouverture de session** (paramètres utilisateur) ;
- puis **toutes les 90 minutes** (± 30 min aléatoires) en arrière-plan ;
- ou immédiatement avec `gpupdate /force`.

| | Configuration **ordinateur** | Configuration **utilisateur** |
|-|-----------------------------|------------------------------|
| S'applique à | Les ordinateurs de l'UO | Les utilisateurs de l'UO |
| Quand | Démarrage + toutes les 90 min | Ouverture de session + toutes les 90 min |
| Exemples | Pare-feu, BitLocker, LAPS, Windows Update, droits | Lecteurs réseau, fond d'écran, menu Démarrer, restrictions |
| Registre | `HKLM` | `HKCU` |

> [!WARNING] Une GPO s'applique selon l'emplacement de l'objet
> Les paramètres **ordinateur** d'une GPO liée à l'UO *Utilisateurs* ne s'appliquent à rien : il n'y a pas d'ordinateurs dans cette UO. Et inversement. (Le *traitement en boucle de rappel* — *loopback* — permet d'appliquer des paramètres utilisateur selon l'UO de l'**ordinateur** : utile pour un poste de caisse ou un kiosque.)

---

## 2. Ordre d'application : LSDOU

![Ordre d’application LSDOU — Les stratégies s’appliquent dans l’ordre Local, Site, Domaine, UO parente et UO enfant. En règle générale, la dernière prime en cas de conflit.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-11-ordre-lsdou.svg)

**La dernière appliquée gagne** en cas de conflit. Deux exceptions :

| Mécanisme | Effet |
|-----------|-------|
| **Appliqué** (*Enforced*) sur une liaison | La GPO l'emporte sur les GPO des UO enfants et ne peut pas être bloquée |
| **Bloquer l'héritage** sur une UO | Les GPO des niveaux supérieurs ne descendent plus (sauf celles « Appliquées ») |

> [!WARNING] Les stratégies de mot de passe du domaine
> La stratégie de mot de passe des **comptes du domaine** ne se règle que dans une GPO liée **au domaine** (en pratique la *Default Domain Policy*). Liée à une UO, elle ne s'appliquerait qu'aux comptes **locaux** des ordinateurs de cette UO. Pour des règles différentes selon les comptes : les *stratégies de mot de passe affinées* (PSO).

---

## 3. Les outils

| Outil | Rôle |
|-------|------|
| **GPMC** — `gpmc.msc` | Créer, lier, filtrer, sauvegarder, modéliser les GPO. **Déjà présente sur SRV01** (Gestionnaire de serveur → Outils → *Gestion de stratégie de groupe*) ; sur un poste Windows 11 : capacité RSAT `Rsat.GroupPolicy.Management.Tools` |
| **Éditeur de GPO** | Modifier le contenu d'une GPO (clic droit → Modifier depuis GPMC) |
| `gpedit.msc` | Stratégie **locale** du poste (n'existe pas sur Home) |
| `gpupdate /force` | Réappliquer immédiatement |
| `gpresult /r` · `/h rapport.html` | **Ce qui est appliqué** à ce poste/cet utilisateur, et pourquoi une GPO est refusée |
| `rsop.msc` | Jeu de stratégies résultant, en console |
| Module PowerShell `GroupPolicy` | `New-GPO`, `New-GPLink`, `Set-GPRegistryValue`, `Set-GPPermission`, `Backup-GPO`… |

> [!TIP] Où travailler ?
> Dans ce cours, on crée les GPO **sur SRV01**, connecté en `FOURNIL\Administrateur` : la console est déjà là. En entreprise, on évite d'ouvrir une session sur un contrôleur de domaine pour administrer : on installe les **RSAT** sur un poste d'administration (facultatif dans le lab, ≈ 10 minutes de téléchargement par Windows Update) :
> ```powershell
> Add-WindowsCapability -Online -Name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
> Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
> ```

### Créer et lier une GPO en graphique

1. Dans `gpmc.msc`, ouvre **Fournil → Ordinateurs**.
2. Fais un clic droit sur **Ordinateurs** → **Créer un objet GPO dans ce domaine, et le lier ici…** → nom `GPO-Postes-Admins-Locaux` → **OK**.

![w11-11-gpmc-creer-lier](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpmc-creer-lier.png)

3. La GPO apparaît sous l'UO, *Lien activé : Oui*. Clic droit sur la GPO → **Modifier** ouvre l'**Éditeur de gestion des stratégies de groupe**, avec ses deux branches *Configuration ordinateur* et *Configuration utilisateur*.

![w11-11-gpmc-gpo-liee](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpmc-gpo-liee.png)

En PowerShell : `New-GPO -Name "GPO-Postes-Admins-Locaux" | New-GPLink -Target "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"`.

---

## 4. Cibler une GPO

![Ciblage d’une GPO — La liaison définit le périmètre, le filtrage de sécurité règle le droit Appliquer, WMI sélectionne des postes et le ciblage par élément affine les préférences.](https://cours.kaya.ovh/windows11/assets/captures/w11-schema-11-ciblage-gpo.svg)

### Filtrage de sécurité

Par défaut, *Utilisateurs authentifiés* a **Lire** + **Appliquer**. Pour réserver une GPO à un groupe :

Dans GPMC, suis **Utilisateurs → GPO-Utilisateurs-Lecteur-Commun → Délégation → Avancé**. Garde **Lecture** pour **Utilisateurs authentifiés** et décoche **Appliquer la stratégie de groupe**. Ajoute **G-Boulangerie** et autorise **Lecture** et **Appliquer la stratégie de groupe**.

![w11-11-gpmc-etendue-filtrage](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpmc-etendue-filtrage.png)

**En PowerShell** (plus sûr : la lecture est conservée explicitement) :

```powershell
Set-GPPermission -Name "GPO-Utilisateurs-Lecteur-Commun" -TargetName "Utilisateurs authentifiés" -TargetType Group -PermissionLevel GpoRead -Replace
Set-GPPermission -Name "GPO-Utilisateurs-Lecteur-Commun" -TargetName "G-Boulangerie" -TargetType Group -PermissionLevel GpoApply
```

> [!WARNING] Garder la **lecture** pour Utilisateurs authentifiés
> Depuis le correctif MS16-072 (2016), les GPO utilisateur sont lues avec le **compte ordinateur**. Retirer complètement *Utilisateurs authentifiés* (au lieu de ne lui laisser que *Lire*) empêche la GPO de s'appliquer à quiconque — erreur encore très répandue dans les tutoriels.

### Filtre WMI (bonus)

```
SELECT * FROM Win32_OperatingSystem WHERE BuildNumber >= 22000      ← Windows 11 uniquement
```

Coûteux (requête évaluée à chaque application) : à utiliser avec parcimonie.

---

## 5. Stratégies et préférences

| | **Stratégies** (*Policies*) | **Préférences** (*Preferences*, GPP) |
|-|-----------------------------|--------------------------------------|
| Où | Modèles d'administration, Paramètres de sécurité | `… → Préférences` |
| Comportement | **Imposé**, grisé pour l'utilisateur, retiré si la GPO disparaît | **Proposé** une fois (ou à chaque application), l'utilisateur peut modifier ; reste en place (« tatouage ») |
| Exemples | Interdire le Panneau de configuration, report WU, BitLocker | **Lecteurs mappés**, raccourcis, imprimantes, tâches planifiées, valeurs de registre, groupes locaux |
| Ciblage fin | Non (filtrage de la GPO entière) | **Ciblage au niveau de l'élément** (groupe, OS, plage IP…) |

Sur le lab, le lecteur `P:` est une **préférence** : **Utilisateurs → GPO-Utilisateurs-Lecteur-Commun → Modifier**

Dans l’éditeur, ouvre **Configuration utilisateur → Préférences → Paramètres Windows → Mappages de lecteurs** → clic droit → **Nouveau → Lecteur mappé** : action **Mettre à jour**, emplacement `\\SRV01\Commun`, *Reconnecter* coché, libellé `Commun`, lettre **Utiliser : P**.

![w11-11-gpo-preference-lecteur-p](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpo-preference-lecteur-p.png)

Résultat dans la session de `stagiaire`, *Ce PC* → *Emplacements réseau* :

![w11-11-pc01-lecteur-p-stagiaire](https://cours.kaya.ovh/windows11/assets/captures/w11-11-pc01-lecteur-p-stagiaire.png)

*Session `FOURNIL\stagiaire` sur `PC01` : « Commun (P:) » monté par GPO. Le cadenas sur `C:` rappelle que BitLocker est actif.*

---

## 6. Les GPO de sécurité d'un parc moderne

### Administrateurs locaux maîtrisés

Objectif : `G-Admins-Postes` (les techniciens) administrateur de tous les postes, et **pas** les Admins du domaine en usage courant.

| Méthode | Où | Remarque |
|---------|----|---------|
| **Groupes restreints** → « Ce groupe est membre de : Administrateurs » | Paramètres de sécurité → Groupes restreints | Ajoute sans retirer les autres membres (utilisé sur le lab) |
| **Préférences → Utilisateurs et groupes locaux** | Préférences | Plus souple : ajouter/retirer, ciblage par élément |

En graphique : **Ordinateurs → GPO-Postes-Admins-Locaux → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Paramètres Windows → Paramètres de sécurité → Groupes restreints** → clic droit → **Ajouter un groupe…** → `FOURNIL\G-Admins-Postes` → dans la section du **bas**, *Ce groupe est membre de*, **Ajouter…** → `Administrateurs`. (Ne rien mettre dans *Membres de ce groupe*.)

![Groupes restreints — G-Admins-Postes est membre du groupe Administrateurs](https://cours.kaya.ovh/windows11/assets/captures/w11-11-gpo-groupes-restreints.png)

Résultat sur `PC01` après `gpupdate` :

```
Name                      PrincipalSource
----                      ---------------
FOURNIL\Admins du domaine ActiveDirectory
FOURNIL\G-Admins-Postes  ActiveDirectory    ← ajouté par GPO-Postes-Admins-Locaux
PC01\Administrateur       Local
```

### Windows LAPS

**Windows LAPS** (intégré à Windows depuis 2023 — l'ancien « LAPS legacy » à installer en MSI est obsolète) donne à **chaque poste un mot de passe d'administrateur local unique**, aléatoire, changé régulièrement, stocké dans AD (ou Entra ID) et lisible seulement par les personnes autorisées.

```powershell
# Une fois, sur le domaine
Update-LapsADSchema
Set-LapsADComputerSelfPermission -Identity "OU=Ordinateurs,OU=Fournil,DC=ad,DC=fournil,DC=lab"
```

Dans GPMC, suis **Ordinateurs → GPO-Postes-LAPS → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Système → LAPS**.

- **Configurer le répertoire de sauvegarde de mot de passe** → **Activé** → **Active Directory**.
- **Activer le chiffrement du mot de passe** → **Activé**. Le domaine doit être au niveau fonctionnel Windows Server 2016 ou supérieur.
- **Configurer la gestion automatique des comptes** → **Activé**. Choisis **Gérer un compte d’administrateur personnalisé**, saisis `adm-laps` dans **Nom du compte automatique (ou préfixe du nom)**, coche **Activer le compte géré** pour le test et laisse **Choisir au hasard le nom du compte géré** décoché.

> [!example]- Voir le rapport LAPS du lab Fournil
>
> ![Réglages de la GPO LAPS et compte adm-laps](https://cours.kaya.ovh/windows11/assets/captures/w11-11-lab-gpo-laps-compte-auto.png)

> [!important] Compte dédié et Windows 11 24H2
> Avec la gestion automatique, LAPS crée le compte local et l’ajoute aux Administrateurs locaux. Laisse **Nom du compte administrateur à gérer** sur **Non configuré**. Ce paramètre sert à désigner un compte déjà présent en mode manuel. Microsoft recommande de garder le compte Administrateur intégré désactivé et de gérer un compte dédié. [Microsoft Learn — Modes de gestion Windows LAPS](https://learn.microsoft.com/fr-fr/windows-server/identity/laps/laps-concepts-account-management-modes#choosing-a-mode)

Sur `PC01`, actualise les stratégies et vérifie le compte dans **Gestion de l’ordinateur → Utilisateurs et groupes locaux → Utilisateurs**. Sur `SRV01`, dans `dsa.msc`, ouvre **ad.fournil.lab → Fournil → Ordinateurs → PC01 → Propriétés → LAPS**. Le nom `adm-laps` et l’échéance doivent apparaître.

```powershell
Get-LapsADPassword -Identity PC01 | Select-Object ComputerName, Account, ExpirationTimestamp
```

Sur le poste, l’événement **10018** dans **Observateur d’événements → Journaux des applications et des services → Microsoft → Windows → LAPS → Operational** confirme la sauvegarde dans Active Directory.

### Sauvegarde des clés BitLocker dans AD

Dans GPMC, suis **Ordinateurs → GPO-Postes-BitLocker → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Composants Windows → Chiffrement de lecteur BitLocker → Lecteurs du système d’exploitation → Sélectionner la méthode de récupération des lecteurs du système d’exploitation protégés par BitLocker** → **Enregistrer les informations de récupération dans AD DS** + **Ne pas activer BitLocker tant que les informations ne sont pas stockées**.

> [!NOTE] La GPO ne rattrape pas l'existant
> Elle s'applique aux **nouveaux** protecteurs. Pour un poste déjà chiffré (comme `PC01`, TP 09) :
> ```powershell
> $kp = (Get-BitLockerVolume C:).KeyProtector | Where-Object KeyProtectorType -eq RecoveryPassword
> Backup-BitLockerKeyProtector -MountPoint C: -KeyProtectorId $kp.KeyProtectorId
> ```
> La clé apparaît alors sous l'objet ordinateur (`msFVE-RecoveryInformation`), dans l'onglet **Récupération BitLocker** de `dsa.msc`. Cet onglet n'existe qu'après l'installation, sur SRV01, de la fonctionnalité **Visionneuse de mots de passe de récupération BitLocker** : Gestionnaire de serveur → Ajouter des rôles et fonctionnalités → *Fonctionnalités* → *Outils d'administration de serveur distant* → *Outils d'administration de fonctionnalités* → *Outils de Chiffrement de lecteur BitLocker*, ou `Install-WindowsFeature RSAT-Feature-Tools-BitLocker-BdeAducExt`.
>
> ![w11-11-aduc-onglet-bitlocker](https://cours.kaya.ovh/windows11/assets/captures/w11-11-aduc-onglet-bitlocker.png)

### Anneau Windows Update

Dans GPMC, suis **Ordinateurs → GPO-Postes-Windows-Update → Modifier**

Dans l’éditeur, ouvre **Configuration ordinateur → Stratégies → Modèles d’administration → Composants Windows → Windows Update → Gérer les mises à jour proposées de Windows Update → Choisir quand recevoir les mises à jour qualité**. Configure un report de **7 jours** dans le lab.

---

## 7. Diagnostiquer

```powershell
gpupdate /force
gpresult /r                                      # résumé ordinateur + utilisateur
gpresult /scope computer /r
gpresult /user stagiaire /scope user /r
gpresult /h C:\Temp\rsop.html                    # rapport complet, lisible
Get-GPResultantSetOfPolicy -ReportType Html -Path C:\Temp\rsop.html
```

Exemple de résultat attendu sur `PC01` après la GPO des administrateurs locaux.
```
Objets Stratégie de groupe appliqués
    GPO-Postes-Admins-Locaux
    Default Domain Policy
```

| Symptôme | Causes classiques |
|----------|-------------------|
| GPO absente de `gpresult` | Mauvaise UO (poste resté dans `CN=Computers`), liaison désactivée, héritage bloqué |
| GPO « refusée (sécurité) » | Filtrage de sécurité : l'objet n'a pas *Appliquer* — ou *Utilisateurs authentifiés* retiré entièrement |
| GPO « refusée (vide) » | La partie ordinateur/utilisateur concernée est vide |
| Rien ne s'applique | DNS du poste ≠ DC, SYSVOL inaccessible, heure décalée (Kerberos) |

Journal : *Applications et services → Microsoft → Windows → GroupPolicy → Operational*.

---

## 8. Et dans le cloud : Intune et Entra ID

| | GPO (AD sur site) | Intune (Microsoft Entra ID) |
|-|-------------------|------------------------------|
| Prérequis | Poste joint à AD, **en ligne de vue** d'un DC (ou VPN) | Poste joint à Entra (ou hybride), simple accès Internet |
| Contenu | Modèles d'administration, sécurité, préférences | Profils de configuration (*Settings catalog*, CSP), conformité, applications, **ADMX importables** |
| Postes nomades | Mal servis (pas de DC joignable) | Conçu pour |
| Déploiement de Windows | Image + GPO | **Autopilot** (chapitre 16) |
| Rapports | `gpresult` poste par poste | Console de conformité centralisée |

**Jonction hybride** (*Microsoft Entra hybrid join*) : le poste est joint à AD **et** enregistré dans Entra ID grâce à **Entra Connect** ; on peut alors basculer progressivement des GPO vers Intune (*co-management*). Outil d'aide : **Group Policy Analytics** dans Intune (importe une sauvegarde de GPO et indique quels paramètres ont un équivalent cloud).

---

## Récapitulatif

> [!summary] L'essentiel du chapitre
> - GPO = objet AD + fichiers SYSVOL · ordinateur (démarrage) / utilisateur (session) · 90 min
> - **LSDOU** : Local → Site → Domaine → UO → UO enfant (le dernier gagne) · Appliqué / Bloquer l'héritage
> - **Ciblage** : liaison (UO) + filtrage de sécurité (garder LIRE pour Utilisateurs authentifiés) + WMI
> - Stratégies (imposées) vs Préférences (lecteurs, groupes locaux, tâches, ciblage par élément)
> - **Sécurité parc** : Groupes restreints/GPP → G-Admins-Postes · Windows LAPS (`Get-LapsADPassword`)
>   - BitLocker → AD (`Backup-BitLockerKeyProtector` pour l'existant) · anneau WU
> - **Diagnostic** : `gpupdate /force` · `gpresult /r /h` · journal GroupPolicy/Operational
> - **Cloud** : Intune + Entra ID (hybride, Group Policy Analytics)
