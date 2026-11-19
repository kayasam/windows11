[CmdletBinding()]
param(
    [ValidateSet('Deploiement', 'Reference')]
    [string]$Mode = 'Deploiement',
    [ValidatePattern('^PC0[23]$')]
    [string]$NomPoste,
    [string]$Sortie = '.\autounattend.xml'
)

$ErrorActionPreference = 'Stop'
if ($Mode -eq 'Reference' -and $NomPoste) {
    throw 'Réserve -NomPoste à PC02 ou PC03 en mode Deploiement.'
}

$templateName = switch ($Mode) {
    'Deploiement' { 'autounattend-iso-officielle.xml' }
    'Reference'   { 'autounattend-fournil-26h2.xml' }
}
$templatePath = Join-Path $PSScriptRoot $templateName
if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
    throw "Place $templateName dans le même dossier que ce script."
}

$outputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Sortie)
if (Test-Path -LiteralPath $outputPath) {
    throw "Un fichier existe déjà à $outputPath. Choisis un autre chemin ou déplace la copie précédente."
}
if (-not (Test-Path -LiteralPath (Split-Path -Parent $outputPath) -PathType Container)) {
    throw 'Crée le dossier de destination avant de relancer le script.'
}

$xml = [System.Xml.XmlDocument]::new()
$xml.PreserveWhitespace = $true
$xml.Load($templatePath)
$ns = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
$ns.AddNamespace('u', $xml.DocumentElement.NamespaceURI)

$localNodes = @($xml.SelectNodes('//u:Password/u:Value[text()="A_RENSEIGNER_MOT_DE_PASSE_LOCAL"]', $ns))
$expected = if ($Mode -eq 'Deploiement') { 2 } else { 1 }
if ($localNodes.Count -ne $expected) {
    throw 'Le modèle ne contient pas les champs attendus. Retélécharge le XML depuis le TP.'
}

$password = Read-Host 'Mot de passe du compte local de la VM de lab' -AsSecureString
if (-not $password -or $password.Length -eq 0) { throw 'Saisis le mot de passe prévu pour le lab.' }
$localValue = ([pscredential]::new('local', $password)).GetNetworkCredential().Password
foreach ($node in $localNodes) { $node.InnerText = $localValue }

if ($Mode -eq 'Deploiement') {
    $credentials = $xml.SelectSingleNode('//u:Identification/u:Credentials', $ns)
    if (-not $credentials -or $credentials.Password -ne 'A_RENSEIGNER_MOT_DE_PASSE_JONCTION') {
        throw 'Modèle de jonction inattendu. Retélécharge le XML depuis le TP.'
    }
    $join = Get-Credential -UserName 'FOURNIL\Administrateur' -Message 'Compte autorisé à joindre les VM au domaine du lab'
    if (-not $join -or $join.Password.Length -eq 0) { throw 'Saisis un compte de jonction et son mot de passe.' }
    $credentials.Username = $join.GetNetworkCredential().UserName
    $credentials.Password = $join.GetNetworkCredential().Password
    if ($NomPoste) {
        $xml.SelectSingleNode('//u:settings[@pass="specialize"]//u:ComputerName', $ns).InnerText = $NomPoste
        $xml.SelectSingleNode('//u:AutoLogon/u:Domain', $ns).InnerText = $NomPoste
    }
}
if ($xml.OuterXml -match 'A_RENSEIGNER_MOT_DE_PASSE_') {
    throw 'Un marqueur reste dans le XML. Retélécharge le modèle.'
}

# Le fichier généré est propre à la VM et contient les identifiants du lab.
$xml.Save($outputPath)
Write-Output "Fichier de réponse prêt : $outputPath"
