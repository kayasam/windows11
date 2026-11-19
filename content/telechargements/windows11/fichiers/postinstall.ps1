# Post-installation lancée à la première ouverture de session (FirstLogonCommands de autounattend-iso-officielle.xml)
# Installe les applications du socle avec WinGet, puis journalise dans C:\Windows\Temp\postinstall.log
$log = 'C:\Windows\Temp\postinstall.log'
function Write-Log($m) { "{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $m | Tee-Object -FilePath $log -Append }

Write-Log "Début post-installation sur $env:COMPUTERNAME ($env:USERDOMAIN\$env:USERNAME)"

try {
    # WinGet (App Installer) n'est pas toujours prêt juste après l'OOBE : on attend qu'il réponde.
    $winget = $null
    for ($i = 0; $i -lt 60 -and -not $winget; $i++) {
        $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
        if (-not $winget) {
            if ($i -eq 0) { Write-Log 'WinGet pas encore disponible : enregistrement de App Installer' }
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction SilentlyContinue
            Start-Sleep 10
        }
    }
    if (-not $winget) { Write-Log 'ÉCHEC : WinGet introuvable après 10 minutes'; exit 1 }
    Write-Log ("WinGet " + (& winget --version))

    # Socle applicatif du Fournil, installé pour TOUS les utilisateurs du poste (--scope machine, dans C:\Program Files)
    # Pour ajouter une application : trouver son identifiant avec  winget search <nom>
    $apps = 'Obsidian.Obsidian', 'Microsoft.VisualStudioCode'
    foreach ($id in $apps) {
        Write-Log "Installation de $id"
        # On ne garde que les lignes utiles : WinGet écrit aussi des centaines de barres de progression illisibles
        & winget install --id $id -e --silent --scope machine --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 |
            Where-Object { "$_" -match 'Found|Successfully|failed|error|No package|already installed' } |
            ForEach-Object { Write-Log "  $_" } | Out-Null
        Write-Log "  code retour $LASTEXITCODE"
    }
} finally {
    # Coupe l’ouverture automatique même si App Installer n’a pas pu démarrer.
    $winlogon = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    try {
        Set-ItemProperty $winlogon -Name AutoAdminLogon -Value '0' -ErrorAction Stop
        foreach ($name in 'DefaultPassword', 'AutoLogonCount') {
            if ($null -ne (Get-ItemPropertyValue $winlogon -Name $name -ErrorAction SilentlyContinue)) {
                Remove-ItemProperty $winlogon -Name $name -ErrorAction Stop
            }
        }
        Write-Log 'Ouverture de session automatique désactivée'
    } catch {
        Write-Log "ÉCHEC du nettoyage Winlogon : $_"
    }

    # Setup peut garder une copie du fichier de réponse avec les identifiants du lab.
    $answerFile = 'C:\Windows\Panther\unattend-original.xml'
    try {
        if (Test-Path -LiteralPath $answerFile) {
            Remove-Item -LiteralPath $answerFile -Force -ErrorAction Stop
            Write-Log 'Copie du fichier de réponse supprimée de C:\Windows\Panther'
        }
    } catch {
        Write-Log "ÉCHEC du nettoyage du fichier de réponse : $_"
    }
}

Write-Log 'Fin post-installation : redémarrage dans 30 s'
# 3. Redémarrer : le poste s'arrête sur l'écran de connexion du domaine, sans session ouverte.
shutdown.exe /r /t 30 /c "Post-installation terminée : redémarrage"
