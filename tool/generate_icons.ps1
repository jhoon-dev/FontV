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
    # Match actual visible heights and bottom edges, not font point sizes.
    $paths = @()
    foreach ($text in @('font', 'V')) {
        $glyphs = [Drawing.Drawing2D.GraphicsPath]::new()
        $glyphs.AddString($text, $family, [int][Drawing.FontStyle]::Regular, 300, [Drawing.PointF]::new(0, 0), $format)
        $bounds = $glyphs.GetBounds()
        $scale = [single](224 / $bounds.Height)
        $normalise = [Drawing.Drawing2D.Matrix]::new($scale, 0, 0, $scale, -$bounds.X * $scale, -$bounds.Y * $scale)
        $glyphs.Transform($normalise)
        $normalise.Dispose()
        $paths += ,$glyphs
    }
    $wordWidth = $paths[0].GetBounds().Width
    $letterWidth = $paths[1].GetBounds().Width
    $left = [single]((1024 - $wordWidth - 40 - $letterWidth) / 2)
    foreach ($pathIndex in @(0, 1)) {
        $x = if ($pathIndex -eq 0) { $left } else { $left + $wordWidth + 40 }
        $position = [Drawing.Drawing2D.Matrix]::new(1, 0, 0, 1, [single]$x, 400)
        $paths[$pathIndex].Transform($position)
        $graphics.FillPath([Drawing.Brushes]::White, $paths[$pathIndex])
        $position.Dispose()
    }
    $output = [Drawing.Bitmap]::new($Size, $Size, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $scaled = [Drawing.Graphics]::FromImage($output)
    $scaled.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $scaled.DrawImage($bitmap, 0, 0, $Size, $Size)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path)) | Out-Null
    $output.Save($Path, [Drawing.Imaging.ImageFormat]::Png)
    $scaled.Dispose(); $output.Dispose(); $format.Dispose(); $family.Dispose(); $paths[0].Dispose(); $paths[1].Dispose(); $graphics.Dispose(); $bitmap.Dispose()
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
