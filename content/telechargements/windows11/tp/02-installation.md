# TP 02. Installation, mise à niveau et comptes

> Durée estimée : 1h30

> Chapitres associés : [02. Installation, mise à niveau et comptes](https://cours.kaya.ovh/windows11/windows11/02-installation/)

---

## Objectifs

- Installer Windows 11 Pro 26H2 sur `PC01` avec un **compte local**
- Analyser le résultat : édition, partitions, chiffrement, jonction
- Vérifier la compatibilité d'un poste avant mise à niveau
- Distinguer compte local, Microsoft, professionnel et de domaine

---

## Prérequis

- VM `PC01` créée au TP 01 (Gen 2, TPM, 2 vCPU, mémoire statique, ISO 26H2 montée)
- Carte réseau connectée à `vSwitch-Rennes` (NAT fonctionnel)

---

## Partie A — Installation (40 min)

**A1.** Démarre `PC01` sur l'ISO. Choisis Français, puis **Windows 11 Professionnel**, installation **personnalisée** sur le disque vierge. Pourquoi ne crée-t-on aucune partition à la main ?

**A2.** Pendant l'installation, explique ce que fait chacun des écrans de l'OOBE qui vont suivre.

**A3.** À l'écran **« Il est temps de vous connecter à un réseau »**, que se passe-t-il si la VM n'a pas de réseau ? Et avec le réseau ?

**A4.** Le Fournil veut un **compte local** `admin` sur ce poste de lab. Obtiens-le avec `Shift+F10`. Quelle commande tapes-tu, et que fait-elle exactement ?

**A5.** Termine l'OOBE : nom `admin`, mot de passe `Fournil2026!`, questions de sécurité, refuse toutes les options de confidentialité facultatives.

**A6.** Le poste s'appelle `DESKTOP-XXXXXXX`. Renomme-le `PC01`.

---

## Partie B — Analyser l'installation (20 min)

**B1.** Vérifie l'édition, la version et le build.

**B2.** Liste les partitions du disque. Dans quel ordre sont-elles ? Pourquoi la partition de récupération est-elle placée là ?

**B3.** Vérifie l'état de BitLocker sur `C:`. Que constates-tu, alors que tu n'as rien activé ? Est-ce que les données sont protégées ?

**B4.** Vérifie l'état de WinRE.

**B5.** Avec `dsregcmd /status`, détermine le type de jonction du poste.

---

## Partie C — Compatibilité et mise à niveau (20 min)

**C1.** Vérifie en PowerShell les trois prérequis clés de Windows 11 : TPM 2.0, Secure Boot, processeur.

**C2.** L'ISO est montée dans `PC01`. Lance un **contrôle de compatibilité seul**, sans rien installer, avec `setup.exe`. Récupère le code de sortie. Où trouver le rapport détaillé ?

**C3.** Interprète le rapport : quels critères sont contrôlés ? Sont-ils bloquants ?

**C4.** Un poste Windows 10 22H2 du Fournil a un TPM 1.2. Que te répondra le contrôle de compatibilité ? Que proposes-tu ?

---

## Partie D — Comptes (10 min)

**D1.** Complète le tableau : où est stocké le compte, comment se connecte-t-on, à quoi sert-il ?

| Compte | Exemple | Stocké dans | Usage typique |
|--------|---------|-------------|---------------|
| Local | | | |
| Microsoft | | | |
| Professionnel | | | |
| Domaine | | | |

**D2.** Pourquoi dit-on que le fichier de réponse est la seule méthode **pérenne** pour obtenir un compte local à l'installation ?

---

## Partie E — Bonus

**E1.** Qu'affiche la valeur `ProductName` du registre sur ton `PC01` ? Pourquoi ne faut-il pas s'y fier ?

**E2.** Combien de jours as-tu pour revenir en arrière après une mise à niveau ? Comment portes-tu ce délai à 30 jours ?

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/02-installation/tp-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/02-installation/tp-corrigev2)
