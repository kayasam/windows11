# TP 18 — Démarrage et récupération — Correction

> Essaie chaque question avant d'ouvrir **Afficher la correction**. Chaque réponse se replie indépendamment.

> Durée estimée : 1h30

> Chapitres associés : [18. Démarrage et récupération](https://kayasam.github.io/windows11/windows11/18-demarrage-recuperation/)

---

## Objectifs

- Lire et modifier la configuration de démarrage (BCD) sans casser le poste
- Accéder à WinRE de plusieurs façons
- Créer et utiliser des points de restauration
- **Casser puis réparer** le démarrage UEFI d'un poste
- Choisir l'outil de récupération adapté à une situation

---

## Prérequis

- `PC02` opérationnel
- **Point de contrôle Hyper-V obligatoire** avant la partie D : `Checkpoint-VM -Name PC02 -SnapshotName "Avant-TP18"`

---

## Partie A — Configuration du démarrage (20 min)

**A1.** Affiche l'entrée de démarrage courante et le gestionnaire de démarrage avec `bcdedit`. Où est le chargeur ? Quel est le délai d'attente ?

> [!success]- Afficher la correction — A1
> Terminal **administrateur** (sinon : « *Le périphérique système demandé est introuvable* »).
> ```cmd
> bcdedit /enum {current}
> bcdedit /enum {bootmgr}
> ```
> Sur `PC02` :
> ```
> identificateur          {current}
> device                  partition=C:
> path                    \WINDOWS\system32\winload.efi
> description             Windows 11
> recoverysequence        {89169cc5-db5e-11f1-b9a5-00155d38011d}     ← l'entrée WinRE associée
> bootmenupolicy          Standard
> timeout                 30
> ```
> Le chargeur est `winload.efi` sur `C:` ; le gestionnaire de démarrage et le magasin BCD sont dans la partition **EFI**.

**A2.** Renomme l'entrée en « Windows 11 - Fournil » et ramène le délai à 5 secondes.

> [!success]- Afficher la correction — A2
> ```cmd
> bcdedit /set {current} description "Windows 11 - Fournil"
> bcdedit /timeout 5
> ```
> Le délai ne sert que s'il y a plusieurs entrées (ex. démarrage VHDX natif, chapitre 19).

**A3.** Avec `msconfig`, configure un démarrage en mode sans échec **réseau**, redémarre, vérifie, puis annule. Pourquoi faut-il penser à annuler ?

> [!success]- Afficher la correction — A3
> `msconfig` → onglet **Démarrer** → **Démarrage sécurisé** → *Réseau* → OK → redémarrer. Vérification : « Mode sans échec » dans les coins de l'écran, `bcdedit /enum {current}` montre `safeboot Network`.
> Il faut **décocher** ensuite : `msconfig` écrit `safeboot` dans le BCD, et le poste redémarrera **indéfiniment** en mode sans échec. En ligne de commande : `bcdedit /deletevalue {current} safeboot`.

**A4.** Quelle commande réactive le menu F8 ? Est-ce une bonne idée sur un poste de production ?

> [!success]- Afficher la correction — A4
> ```cmd
> bcdedit /set {current} bootmenupolicy legacy
> ```
> Utile en lab ou sur un poste de dépannage. En production, on préfère le démarrage avancé (Shift + Redémarrer) : le menu F8 rallonge chaque démarrage et peut être utilisé par n'importe qui devant le poste.

---

## Partie B — WinRE (15 min)

**B1.** Vérifie l'état de WinRE et son emplacement.

> [!success]- Afficher la correction — B1
> ```cmd
> reagentc /info
> ```
> ```
> État WinRE :         Enabled
> Emplacement WinRE :  \\?\GLOBALROOT\device\harddisk0\partition4\Recovery\WindowsRE
> Version de Windows RE : 10.0.26100.9444
> ```
> WinRE est dans la partition 4, la partition de **récupération** créée par Setup en fin de disque (chapitre 13). Si `Disabled` : `reagentc /enable`.

**B2.** Donne trois façons de démarrer dans WinRE, dont une en ligne de commande.

> [!success]- Afficher la correction — B2
> 1. Menu Démarrer ou écran de connexion → Marche/arrêt → **Maj + Redémarrer** ;
> 2. **Paramètres → Système → Récupération → Démarrage avancé → Redémarrer maintenant** ;
> 3. `shutdown /r /o /t 0` (ou `reagentc /boottore` puis redémarrage) ;
> 4. automatiquement après **trois** démarrages ratés consécutifs.

**B3.** Dans WinRE, liste les options du menu *Dépannage → Options avancées*. Laquelle est nouvelle en 2026 ?

> [!success]- Afficher la correction — B3
> Réparation du démarrage · Paramètres (mode sans échec…) · Invite de commandes · Désinstaller des mises à jour · Paramètres du microprogramme UEFI · Restauration du système · Récupération de l'image système (héritée) — et, nouveauté 2026, **Point-in-time restore** (quand il est activé).

---

## Partie C — Points de restauration (20 min)

**C1.** Active la protection du système sur `C:` et crée le point « Avant-TP18 ».

> [!success]- Afficher la correction — C1
> ```powershell
> Enable-ComputerRestore -Drive "C:\"
> Checkpoint-Computer -Description "Avant-TP18" -RestorePointType MODIFY_SETTINGS
> Get-ComputerRestorePoint | Select-Object SequenceNumber, Description, CreationTime
> ```
> ```
> SequenceNumber Description CreationTime
> -------------- ----------- ------------
>              1 Avant-TP18  20261108104924.848358-000
> ```
> La protection est **désactivée par défaut** sur les postes déployés (et en VM) : il faut l'activer, idéalement par GPO.

**C2.** Essaie d'en créer un second immédiatement. Que se passe-t-il ? Pourquoi ?

> [!success]- Afficher la correction — C2
> Aucun point n'est créé, seulement un **avertissement** (pas une erreur, donc facile à rater dans un script) :
> ```
> AVERTISSEMENT : Impossible de créer un point de restauration du système, car il en a été créé un
> au cours des dernières 1440 minutes. … créez la valeur DWORD SystemRestorePointCreationFrequency
> sous la clé HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore.
> ```
> Windows limite à **un point par 24 heures** (via `Checkpoint-Computer`). Pour un script de maintenance qui doit toujours en créer un : `SystemRestorePointCreationFrequency = 0`.

**C3.** Installe un logiciel avec WinGet, puis restaure le point « Avant-TP18 ». Le logiciel est-il encore là ? Et un document créé entre-temps ?

> [!success]- Afficher la correction — C3
> `rstrui.exe` → choisir « Avant-TP18 » → **Rechercher les programmes concernés** (liste ce qui sera retiré) → Terminer → redémarrage.
> Le logiciel installé après le point **disparaît** (registre et fichiers de programme restaurés). Le document créé dans `Documents` **reste** : les points de restauration ne touchent pas aux fichiers personnels.

**C4.** Compare point de restauration et *point-in-time restore*.

> [!success]- Afficher la correction — C4
> | | Point de restauration | Point-in-time restore |
> |-|-----------------------|-----------------------|
> | Contenu | Système (registre, pilotes, programmes) | **Tout le volume**, fichiers compris |
> | Création | Avant installations / manuel, 1 par 24 h | Automatique, toutes les 24 h par défaut |
> | Restauration | Windows ou WinRE | WinRE uniquement |
> | Données utilisateur | Intactes | **Revenues à l'état de l'instantané** (attention aux documents récents) |

---

## Partie D — Casser et réparer le démarrage (25 min)

> Point de contrôle Hyper-V fait ? Sinon, ne commence pas.

**D1.** Supprime l'entrée de démarrage courante : `bcdedit /delete {current}`. Redémarre. Que se passe-t-il ?

> [!success]- Afficher la correction — D1
> ```cmd
> bcdedit /delete {current}
> ```
> Au redémarrage, le gestionnaire de démarrage ne trouve plus d'entrée Windows : selon le firmware, erreur `0xc000000f`/« *Aucun système d'exploitation* » ou bascule vers WinRE (*Réparation automatique*). Dans Hyper-V, la VM peut tenter le démarrage réseau puis afficher « *No operating system was loaded* » : démarrer alors sur l'ISO Windows (Réparer l'ordinateur) ou forcer WinRE.

**D2.** Depuis WinRE (invite de commandes), identifie la lettre du volume Windows et de la partition EFI.

> [!success]- Afficher la correction — D2
> ```cmd
> diskpart
> list volume
> ```
> Repérer le volume **NTFS** de ~63 Go (Windows — souvent `C:`, mais pas toujours) et le volume **FAT32** de 200 Mo sans lettre (EFI) :
> ```cmd
> select volume 3
> assign letter=S
> exit
> ```

**D3.** Répare le démarrage avec la bonne commande. Pourquoi pas `bootrec /fixboot` ?

> [!success]- Afficher la correction — D3
> ```cmd
> bcdboot C:\Windows /s S: /f UEFI
> ```
> `bcdboot` recopie le gestionnaire de démarrage dans la partition EFI et **recrée** le magasin BCD avec une entrée pour ce Windows. C'est la commande validée au chapitre 15 sur `PC03` (« *Boot files successfully created* »).
> `bootrec /fixboot` écrit un secteur de démarrage **MBR/BIOS** : sur un disque GPT/UEFI il répond souvent « *Accès refusé* » et ne répare rien.

**D4.** Redémarre et vérifie que Windows démarre. Vérifie le BCD.

> [!success]- Afficher la correction — D4
> `wpeutil reboot` (ou Continuer) → Windows démarre. `bcdedit /enum {current}` : nouvelle entrée `Windows Boot Manager` / `Windows 11`. La `description` personnalisée (A2) a disparu : l'entrée a été recréée à neuf. Revenir au point de contrôle Hyper-V si besoin : `Restore-VMSnapshot -VMName PC02 -Name Avant-TP18`.

---

## Partie E — Quelle arme ? (10 min)

**E1.** Pour chaque situation, propose l'outil :
1. Depuis la mise à jour d'hier, le poste fait un écran bleu au démarrage.
2. Excel plante depuis l'installation d'un complément ce matin.
3. `sfc /scannow` signale des fichiers corrompus qu'il ne peut pas réparer.
4. Le poste d'un stagiaire parti doit être rendu à un nouvel arrivant.
5. Une mise à jour défectueuse empêche 300 postes de démarrer.

> [!success]- Afficher la correction — E1
> 1. **Écran bleu après une mise à jour** : WinRE → **Désinstaller des mises à jour** (la dernière qualité) ; sinon **point-in-time restore** ; sinon mode sans échec pour un pilote.
> 2. **Excel plante après un complément** : désactiver le complément (`excel /safe`), réparer Office ; pas besoin de toucher Windows. Le point de restauration est possible mais disproportionné.
> 3. **SFC ne répare pas** : `DISM /Online /Cleanup-Image /RestoreHealth` puis `sfc /scannow` ; en dernier recours **Réinstaller maintenant** via Windows Update (garde applications et fichiers).
> 4. **Poste à réattribuer** : **Réinitialiser ce PC** en supprimant tout (ou redéploiement par l'ISO, chapitre 16 ; ou *réinitialisation Autopilot* en environnement Intune). Ne pas oublier de retirer le profil de l'ancien utilisateur… et ses données.
> 5. **300 postes bloqués par une mise à jour** : **Quick Machine Recovery** (WinRE + correctif distribué par Windows Update), piloté par Intune ; à défaut, désinstallation de la mise à jour en WinRE poste par poste.

---

[Retour à l'énoncé](https://kayasam.github.io/windows11/windows11/18-demarrage-recuperation/tp)
