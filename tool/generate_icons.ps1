$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$fontProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Write-FontIcon([string]$Path, [int]$Size) {
    $bitmap = [Drawing.Bitmap]::new(1024, 1024, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([Drawing.ColorTranslator]::FromHtml('#D9437B'))
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $family = [Drawing.FontFamily]::new('Segoe UI')
    $format = [Drawing.StringFormat]::GenericTypographic
    # A single type run guarantees the same face, weight, size and baseline.
    # F and V share the capital height; neither letter is scaled separately.
    $wordmark = [Drawing.Drawing2D.GraphicsPath]::new()
    $wordmark.AddString('Font V', $family, [int][Drawing.FontStyle]::Regular, 300, [Drawing.PointF]::new(0, 0), $format)
    $bounds = $wordmark.GetBounds()
    $scale = [single]([Math]::Min(760 / $bounds.Width, 240 / $bounds.Height))
    $left = [single]((1024 - $bounds.Width * $scale) / 2 - $bounds.X * $scale)
    $top = [single]((1024 - $bounds.Height * $scale) / 2 - $bounds.Y * $scale)
    $position = [Drawing.Drawing2D.Matrix]::new($scale, 0, 0, $scale, $left, $top)
    $wordmark.Transform($position)
    $graphics.FillPath([Drawing.Brushes]::White, $wordmark)
    $position.Dispose()
    $output = [Drawing.Bitmap]::new($Size, $Size, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $scaled = [Drawing.Graphics]::FromImage($output)
    $scaled.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $scaled.DrawImage($bitmap, 0, 0, $Size, $Size)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path)) | Out-Null
    $output.Save($Path, [Drawing.Imaging.ImageFormat]::Png)
    $scaled.Dispose(); $output.Dispose(); $format.Dispose(); $family.Dispose(); $wordmark.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
}

$iconsPath = Join-Path $fontProjectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$manifest = Get-Content -Raw (Join-Path $iconsPath 'Contents.json') | ConvertFrom-Json
foreach ($icon in $manifest.images) {
    $size = [double]($icon.size.Split('x')[0]) * [double]($icon.scale.Replace('x',''))
    Write-FontIcon (Join-Path $iconsPath $icon.filename) ([int]$size)
}
$densities = @{mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192}
foreach ($density in $densities.Keys) {
    Write-FontIcon (Join-Path $fontProjectRoot "android/app/src/main/res/mipmap-$density/ic_launcher.png") $densities[$density]
}
foreach ($size in @(192, 512)) {
    Write-FontIcon (Join-Path $fontProjectRoot "web/icons/Icon-$size.png") $size
    Write-FontIcon (Join-Path $fontProjectRoot "web/icons/Icon-maskable-$size.png") $size
}
Write-FontIcon (Join-Path $fontProjectRoot 'web/favicon.png') 32
Write-Output 'Generated Font V icons for iOS, Android, and browser preview.'
