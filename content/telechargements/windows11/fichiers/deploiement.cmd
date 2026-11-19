@echo off
setlocal
echo Initialisation du reseau WinPE...
wpeinit
echo Connexion au partage de deploiement. Saisis le mot de passe du compte du lab.
net use Z: \\SRV01\Deploy$ * /user:FOURNIL\svc.deploiement
if errorlevel 1 goto erreur
if not exist Z:\Windows11\setup.exe goto erreur
if not exist Z:\autounattend.xml goto erreur
Z:\Windows11\setup.exe /unattend:Z:\autounattend.xml
exit /b %errorlevel%

:erreur
echo Partage inaccessible ou fichier absent. Verifie ipconfig, les droits SMB et le contenu de Deploy$.
exit /b 1
