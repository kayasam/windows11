# TP 14. Poste de référence : mode audit et Sysprep

> Durée estimée : 2h

> Chapitres associés : [14. Poste de référence : mode audit et Sysprep](https://cours.kaya.ovh/windows11/windows11/14-sysprep-audit/)

> [!abstract] Niveau : approfondissement
> TP facultatif pour un public TSSR : le déploiement du TP 16 (ISO officielle + fichier de réponse) n'a pas besoin de `MASTER`. À réserver à un groupe avancé, ou à montrer en démonstration.

---

## Objectifs

- Installer la VM de référence `MASTER` **sans chiffrement automatique**
- La personnaliser en mode audit (socle logiciel, nettoyage des applications)
- Protéger l'état « prêt à généraliser » par un point de contrôle
- Généraliser avec Sysprep et le fichier de réponse — et **diagnostiquer** les échecs

---

## Prérequis

- `autounattend-installation-master.xml` et `autounattend-fournil-26h2.xml` (TP 13)
- Au moins **40 Go libres** sur le disque de l'hôte

---

## Partie A — Installer MASTER (25 min)

**A1.** Crée l'ISO `unattend-master.iso` contenant `autounattend-installation-master.xml` renommé en `autounattend.xml`.

**A2.** Crée la VM `MASTER` (Gen 2, 6 Go statiques, 2 vCPU, TPM, **Default Switch**) avec deux lecteurs DVD : l'ISO Windows et l'ISO de réponse. Démarre-la.

**A3.** Pourquoi le Default Switch ? Pourquoi `MASTER` ne doit-elle jamais rejoindre le domaine ?

---

## Partie B — Mode audit (30 min)

**B1.** À l'écran « Est-ce le bon pays ou la bonne région ? », passe en mode audit. Que se passe-t-il ? Quel compte est utilisé ?

**B2.** Vérifie l'état BitLocker de `C:` et la valeur `PreventDeviceEncryption`.

**B3.** Installe 7-Zip et Notepad++ **pour tous les utilisateurs** avec WinGet.

**B4.** Retire de l'image `Microsoft.BingNews`, `Clipchamp.Clipchamp`, `Microsoft.MicrosoftSolitaireCollection` et `Microsoft.GamingApp`, pour les futurs utilisateurs **et** l'Administrateur.

**B5.** Crée `C:\Fournil\version-image.txt` contenant la version de l'image et la date. À quoi cela servira-t-il ?

---

## Partie C — Préparer la généralisation (15 min)

**C1.** Depuis l'hôte, copie `autounattend-fournil-26h2.xml` dans `C:\Sysprep\autounattend.xml` de `MASTER` **sans réseau ni partage**.

**C2.** Crée le point de contrôle `Avant-Sysprep`. Pourquoi à ce moment précis ?

---

## Partie D — Sysprep et dépannage (40 min)

**D1.** Lance Sysprep en ligne de commande (généralisation, OOBE, arrêt, fichier de réponse). La VM ne s'éteint pas. Où regarder ?

**D2.** Le journal indique :
```
SYSPRP Package Microsoft.Winget.Source_2026.1108.637.6_neutral__8wekyb3d8bbwe was installed for a user,
but not provisioned for all users.
```
Explique et corrige.

**D3.** Nouvel échec, même code, avec `NotepadPlusPlus_1.0.0.0_neutral__2247w0b46hfww`. Pourquoi ce paquet existe-t-il ? Corrige.

**D4.** Que dois-tu faire au point de contrôle après ces corrections ?

**D5.** Un collègue, qui avait installé `MASTER` **sans** le fichier anti-chiffrement, obtient `0x80310039`. Que lui conseilles-tu ?

**D6.** Sysprep réussit : la VM s'éteint. Pourquoi ne faut-il surtout pas la redémarrer ?

---

## Partie E — Bonus

**E1.** Le mois prochain, décris la procédure complète pour produire `MASTER` v2026.12.

**E2.** Quelle limite Sysprep impose-t-il au nombre de généralisations, et en quoi le point de contrôle la contourne-t-il ?

---


