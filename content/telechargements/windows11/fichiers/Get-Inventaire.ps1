<#
  Get-Inventaire.ps1 — chapitre 21 (MCO)
  Inventaire et état de santé d'un ou plusieurs postes, exporté en CSV.
  Exemple : .\Get-Inventaire.ps1 -ComputerName PC01,PC02 -Csv C:\MCO\inventaire.csv
  Prérequis : WinRM actif sur les postes (chapitre 16).
#>
param(
    [string[]]$ComputerName = $env:COMPUTERNAME,
    [string]$Csv
)

$collecte = {
    $os   = Get-CimInstance Win32_OperatingSystem
    $cs   = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $cv   = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $c    = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $mp   = Get-MpComputerStatus -ErrorAction SilentlyContinue
    $bl   = Get-BitLockerVolume -MountPoint C: -ErrorAction SilentlyContinue
    $maj  = Get-HotFix | Where-Object InstalledOn | Sort-Object InstalledOn -Descending | Select-Object -First 1
    $rp   = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'

    [pscustomobject]@{
        Poste          = $env:COMPUTERNAME
        Edition        = $os.Caption
        Version        = $cv.DisplayVersion
        Build          = '{0}.{1}' -f $cv.CurrentBuildNumber, $cv.UBR
        Modele         = $cs.Model
        NumeroSerie    = $bios.SerialNumber
        RAM_Go         = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
        C_Libre_Go     = [math]::Round($c.FreeSpace / 1GB, 1)
        C_Libre_Pct    = [math]::Round(100 * $c.FreeSpace / $c.Size)
        DemarreDepuis_j = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
        DerniereMaj    = $maj.HotFixID
        DerniereMaj_le = $maj.InstalledOn
        RedemarrageMaj = $rp
        Defender_Actif = $mp.RealTimeProtectionEnabled
        Signatures_j   = $mp.AntivirusSignatureAge
        BitLocker      = if ($bl) { "$($bl.VolumeStatus) / $($bl.ProtectionStatus)" } else { 'n/a' }
    }
}

# Le poste local est interrogé directement (WinRM est arrêté par défaut sur Windows 11)
$distants = $ComputerName | Where-Object { $_ -notin $env:COMPUTERNAME, 'localhost', '.' }
$resultat = @()
if ($distants.Count -lt $ComputerName.Count) { $resultat += & $collecte }
if ($distants) {
    $resultat += Invoke-Command -ComputerName $distants -ScriptBlock $collecte -ErrorVariable ko -ErrorAction SilentlyContinue |
                 Select-Object * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName
    $ko | ForEach-Object { Write-Warning "Injoignable : $($_.TargetObject)" }
}

if ($Csv) { $resultat | Export-Csv $Csv -NoTypeInformation -Encoding UTF8 -Delimiter ';' }
$resultat
