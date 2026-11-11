$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$fontProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

. (Join-Path $PSScriptRoot 'icon_drawing.ps1')

$iconsPath = Join-Path $fontProjectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$manifest = Get-Content -Raw (Join-Path $iconsPath 'Contents.json') | ConvertFrom-Json
foreach ($icon in $manifest.images) {
    $size = [double]($icon.size.Split('x')[0]) * [double]($icon.scale.Replace('x',''))
    # iOS and App Store apply their own mask and require an opaque source.
    Write-FontIcon (Join-Path $iconsPath $icon.filename) ([int]$size)
}
$densities = @{mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192}
foreach ($density in $densities.Keys) {
    Write-FontIcon (Join-Path $fontProjectRoot "android/app/src/main/res/mipmap-$density/ic_launcher.png") $densities[$density] -Rounded
    $adaptiveSize = [int]($densities[$density] * 108 / 48)
    Write-FontIcon (Join-Path $fontProjectRoot "android/app/src/main/res/mipmap-$density/ic_launcher_foreground.png") $adaptiveSize -Foreground
}
foreach ($size in @(192, 512)) {
    Write-FontIcon (Join-Path $fontProjectRoot "web/icons/Icon-$size.png") $size -Rounded
    # Maskable images keep a full background and the logo inside the safe circle.
    Write-FontIcon (Join-Path $fontProjectRoot "web/icons/Icon-maskable-$size.png") $size -Inset 0.12
}
Write-FontIcon (Join-Path $fontProjectRoot 'web/favicon.png') 32 -Rounded
Write-FontIcon (Join-Path $fontProjectRoot 'site/apps/fontv/icon.png') 512 -Rounded
Write-FontIcon (Join-Path $fontProjectRoot 'store-assets/google-play-icon.png') 512
Write-FontIcon (Join-Path $fontProjectRoot 'store-assets/app-store-icon.png') 1024
Write-Output 'Generated Font V mobile, browser, website, and store icons.'
