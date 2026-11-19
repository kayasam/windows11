# Test-Poste.ps1 — contrôle rapide d'un poste du domaine Fournil
$dc  = '192.168.3.1'
$res = [ordered]@{}

$dns = (Get-DnsClientServerAddress -AddressFamily IPv4 |
        Where-Object ServerAddresses).ServerAddresses
$res['DNS = DC']          = ($dns -contains $dc) -and -not ($dns | Where-Object { $_ -ne $dc })
$res['srv01 -> DC']       = (Resolve-DnsName srv01.ad.fournil.lab -Type A -ErrorAction SilentlyContinue).IPAddress -contains $dc
$res['SMB vers srv01']    = (Test-NetConnection srv01.ad.fournil.lab -Port 445 -WarningAction SilentlyContinue).TcpTestSucceeded
$sp = Get-Service Spooler
$res['Spooler']           = $sp.Status -eq 'Running' -and $sp.StartType -eq 'Automatic'
$res['Pas de blocage sortant local'] = -not (Get-NetFirewallRule -Direction Outbound -Action Block -Enabled True -ErrorAction SilentlyContinue |
                                        Where-Object PolicyStoreSourceType -eq 'Local')
$res['Pas de tâche script à la racine'] = -not (Get-ScheduledTask -TaskPath '\' |
                                        Where-Object { $_.Actions.Execute -match 'powershell|pwsh|cmd|wscript' })
$res['Canal sécurisé']    = Test-ComputerSecureChannel

$res.GetEnumerator() | ForEach-Object {
    $c = if ($_.Value) { 'Green' } else { 'Red' }
    Write-Host ("{0,-35} {1}" -f $_.Key, $(if ($_.Value) {'OK'} else {'KO'})) -ForegroundColor $c
}
