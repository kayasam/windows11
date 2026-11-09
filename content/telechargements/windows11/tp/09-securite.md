# TP 09. Sécuriser un poste Windows 11

> Durée estimée : 2h

> Chapitres associés : [09. Sécuriser un poste Windows 11](https://cours.kaya.ovh/windows11/windows11/09-securite/)

---

## Objectifs

- Appliquer le moindre privilège sur `PC01`
- Lire et régler l'UAC, connaître Administrator protection
- Vérifier Microsoft Defender et comprendre la protection contre les falsifications
- Ouvrir un port proprement dans le pare-feu, par profil
- Terminer la protection BitLocker laissée « à moitié » par Windows
- Mettre en place et **tester** AppLocker sur l'édition Pro

---

## Prérequis

- `PC01` (TP 03), comptes `admin` (administrateur) et `employe1` (standard, mot de passe `Fournil2026!`)
- **Aucune ISO montée** dans la VM (voir partie D)

---

## Partie A — Moindre privilège (15 min)

**A1.** Qui est administrateur de `PC01` ? Que faut-il penser du compte `admin` utilisé au quotidien ?

**A2.** Ouvre une session `employe1`. Essaie d'installer un logiciel (`winget install Notepad++.Notepad++`) puis de modifier l'heure système. Que se passe-t-il ?

**A3.** Dans `secpol.msc`, retrouve qui a le droit d'« ouvrir une session en tant que tâche » (*Log on as a batch job*). Pourquoi est-ce important pour les tâches planifiées d'un utilisateur standard ?

---

## Partie B — UAC et Administrator protection (15 min)

**B1.** Lis les valeurs UAC du registre. À quel niveau de la réglette correspondent-elles ?

**B2.** Depuis la session `employe1`, lance un terminal **en tant qu'administrateur**. Que demande l'UAC ? Et depuis la session `admin` ?

**B3.** Quelle valeur de `TypeOfAdminApprovalMode` est relevée sur `PC01` ? Que change le passage à `2` ?

---

## Partie C — Defender et pare-feu (25 min)

**C1.** Relève l'état de Defender : protection temps réel, version des signatures, protection contre les falsifications.

**C2.** Essaie de désactiver la protection en temps réel avec `Set-MpPreference`. Que se passe-t-il ? Pourquoi ?

**C3.** Lance une analyse rapide en PowerShell, puis consulte l'historique des menaces.

**C4.** Le Fournil installe sur `PC01` un petit serveur web interne sur le port TCP 8080. Crée la règle de pare-feu entrante, **uniquement** pour le profil Domaine et le réseau `192.168.3.0/24`.

**C5.** Quel est le profil réseau actif de `PC01` ? La règle s'applique-t-elle maintenant ? Et après la jonction au domaine ?

---

## Partie D — BitLocker (30 min)

**D1.** Relève l'état BitLocker de `C:` **sans rien avoir activé**. Le disque est-il chiffré ? Les données sont-elles protégées ?

**D2.** Termine la protection : clé de récupération puis TPM, puis active la protection. Relève l'état final.

**D3.** Un stagiaire obtient `0x80310030` à l'étape TPM. Que se passe-t-il ?

**D4.** Affiche la clé de récupération (48 chiffres). Où le Fournil devrait-il la stocker ?

**D5.** Avant une mise à jour du firmware UEFI, que fais-tu pour éviter de devoir saisir la clé au redémarrage ?

**D6.** Chiffre une clé USB virtuelle (ou le volume `G:` du TP 04) avec BitLocker To Go et un mot de passe.

---

## Partie E — AppLocker sur Windows 11 Pro (25 min)

**E1.** Crée les **règles par défaut** des exécutables et passe la collection en **Appliquer**. Démarre le service nécessaire.

**E2.** Copie `C:\Windows\System32\notepad.exe` en `C:\Temp\bloc.exe`. Teste la politique **sans l'exécuter**, pour `employe1`, sur les deux fichiers.

**E3.** Ouvre une session `employe1` et lance `C:\Temp\bloc.exe`. Que se passe-t-il ? Quel événement est journalisé, où ?

**E4.** Conclusion : AppLocker fonctionne-t-il sur l'édition Pro ?

**E5.** Retire la politique pour la suite de la formation.

---

## Partie F — Bonus

**F1.** Chiffre avec EFS le dossier `C:\Users\admin\Documents\Confidentiel`, puis exporte le certificat EFS. Pourquoi cette exportation est-elle vitale ?

**F2.** Interroge l'état de VBS/Credential Guard sur `PC01`. Explique le résultat.

---

[Ouvrir la correction](https://cours.kaya.ovh/windows11/windows11/09-securite/tp-corrigev2)


[Afficher les corrections](https://cours.kaya.ovh/windows11/windows11/09-securite/tp-corrigev2)
