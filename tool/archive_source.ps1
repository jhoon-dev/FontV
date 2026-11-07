$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$fontProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$archiveFolder = Join-Path $fontProjectRoot 'artifacts'
[IO.Directory]::CreateDirectory($archiveFolder) | Out-Null
$archivePath = Join-Path $archiveFolder 'font-v-source.zip'
$sourceFiles = & git -C $fontProjectRoot ls-files --cached --others --exclude-standard
if ($LASTEXITCODE -ne 0 -or !$sourceFiles) { throw 'Cannot enumerate project sources.' }
# Overwrite this generated archive only; source files are never deleted.
$stream = [IO.File]::Open($archivePath, [IO.FileMode]::Create)
$archive = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($relativePath in ($sourceFiles | Sort-Object -Unique)) {
        $absolutePath = [IO.Path]::GetFullPath((Join-Path $fontProjectRoot $relativePath))
        if (!$absolutePath.StartsWith($fontProjectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Source escaped project directory: $relativePath"
        }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $absolutePath, $relativePath.Replace('\', '/')) | Out-Null
    }
} finally { $archive.Dispose(); $stream.Dispose() }
Get-Item -LiteralPath $archivePath | Select-Object FullName, Length
