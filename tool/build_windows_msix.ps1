param(
    [ValidateSet('test', 'store', 'signed')]
    [string]$Mode = 'test',
    [string]$IdentityName = '',
    [string]$Publisher = '',
    [string]$PublisherDisplayName = '',
    [string]$Version = ''
)
$ErrorActionPreference = 'Stop'
$fontProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$fontTestCertificate = $null
$fontTestPfxPath = $null
Push-Location $fontProjectRoot
try {
    $msixArguments = @('run', 'msix:create', '--install-certificate', 'false')
    if ($Version) {
        if ($Version -notmatch '^\d+\.\d+\.\d+\.\d+$') { throw 'Version must contain four numeric components.' }
        $msixArguments += @('--version', $Version)
    }
    if ($Mode -eq 'test') {
        # Each build gets its own short-lived key. The public MSIX package test
        # key is deliberately avoided for packages installed on a user's PC.
        $fontTestSubject = if ($Publisher) { $Publisher } else { 'CN=ToolMoa Font V Development' }
        $fontTestCertificate = New-SelfSignedCertificate -Type CodeSigningCert `
            -Subject $fontTestSubject -FriendlyName 'Font V development signing' `
            -CertStoreLocation 'Cert:/CurrentUser/My' -KeyExportPolicy Exportable `
            -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 `
            -NotAfter (Get-Date).AddDays(30)
        $fontTestPfxPath = Join-Path ([IO.Path]::GetTempPath()) ("FontV-$([guid]::NewGuid().ToString('N')).pfx")
        $fontTestPassword = [Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
        if ($env:GITHUB_ACTIONS -eq 'true') { Write-Output "::add-mask::$fontTestPassword" }
        Export-PfxCertificate -Cert $fontTestCertificate -FilePath $fontTestPfxPath `
            -Password (ConvertTo-SecureString $fontTestPassword -AsPlainText -Force) | Out-Null
        $msixArguments += @('--certificate-path', $fontTestPfxPath,
                            '--certificate-password', $fontTestPassword)
        $Publisher = $fontTestSubject
    }
    if ($Mode -eq 'store') {
        if (!$IdentityName -or !$Publisher -or !$PublisherDisplayName) {
            throw 'Store packaging requires IdentityName, Publisher and PublisherDisplayName from Partner Center.'
        }
        $msixArguments += @('--store', '--sign-msix', 'false')
    } elseif ($Mode -eq 'signed') {
        if (!$env:FONTV_MSIX_CERTIFICATE_PATH -or !$env:FONTV_MSIX_CERTIFICATE_PASSWORD -or !$Publisher) {
            throw 'Signed packaging requires Publisher, FONTV_MSIX_CERTIFICATE_PATH and FONTV_MSIX_CERTIFICATE_PASSWORD.'
        }
        if (!(Test-Path -LiteralPath $env:FONTV_MSIX_CERTIFICATE_PATH -PathType Leaf)) { throw 'Signing certificate does not exist.' }
        $msixArguments += @('--certificate-path', $env:FONTV_MSIX_CERTIFICATE_PATH,
                            '--certificate-password', $env:FONTV_MSIX_CERTIFICATE_PASSWORD)
    }
    if ($IdentityName) { $msixArguments += @('--identity-name', $IdentityName) }
    if ($Publisher) { $msixArguments += @('--publisher', $Publisher) }
    if ($PublisherDisplayName) { $msixArguments += @('--publisher-display-name', $PublisherDisplayName) }

    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    & dart @msixArguments
    if ($LASTEXITCODE -ne 0) { throw 'MSIX packaging failed.' }
    $package = Join-Path $fontProjectRoot 'artifacts/windows/FontV.msix'
    if (!(Test-Path -LiteralPath $package -PathType Leaf)) { throw 'MSIX output is missing.' }
    if ($Mode -ne 'store') {
        $signature = Get-AuthenticodeSignature -LiteralPath $package
        if (!$signature.SignerCertificate) { throw 'MSIX signature is missing.' }
        if ($Mode -eq 'test') {
            # Export only the public certificate. Trust installation is manual.
            [IO.File]::WriteAllBytes((Join-Path $fontProjectRoot 'artifacts/windows/FontV-test.cer'),
                $signature.SignerCertificate.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert))
        } elseif ($signature.Status -ne 'Valid') {
            throw "MSIX signature validation failed: $($signature.Status)"
        }
    }
    Write-Output "Created $package ($Mode)"
} finally {
    if ($fontTestPfxPath -and (Test-Path -LiteralPath $fontTestPfxPath)) {
        Remove-Item -LiteralPath $fontTestPfxPath -Force
    }
    if ($fontTestCertificate) {
        Remove-Item -LiteralPath "Cert:/CurrentUser/My/$($fontTestCertificate.Thumbprint)" -Force
    }
    Pop-Location
}
