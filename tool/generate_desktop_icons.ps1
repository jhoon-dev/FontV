$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$fontProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$source = Join-Path $fontProjectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'
$image = [Drawing.Image]::FromFile($source)
function Resize-FontIcon([string]$Path, [int]$Size) {
    $output = [Drawing.Bitmap]::new($Size, $Size)
    $graphics = [Drawing.Graphics]::FromImage($output)
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($image, 0, 0, $Size, $Size)
    $output.Save($Path, [Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $output.Dispose()
}
try {
    $macIcons = Join-Path $fontProjectRoot 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
    foreach ($size in @(16, 32, 64, 128, 256, 512, 1024)) {
        Resize-FontIcon (Join-Path $macIcons "app_icon_$size.png") $size
    }
    $winResources = Join-Path $fontProjectRoot 'windows/runner/resources'
    Resize-FontIcon (Join-Path $winResources 'msix_logo.png') 1024
    $buffer = [IO.MemoryStream]::new()
    $writer = [IO.BinaryWriter]::new($buffer)
    # ICO directory entries followed by PNG payloads; 0 encodes 256 pixels.
    $sizes = @(16, 32, 48, 64, 128, 256)
    $payloads = @()
    foreach ($size in $sizes) {
        $bitmap = [Drawing.Bitmap]::new($image, $size, $size)
        $png = [IO.MemoryStream]::new()
        $bitmap.Save($png, [Drawing.Imaging.ImageFormat]::Png)
        $payloads += ,$png.ToArray()
        $png.Dispose()
        $bitmap.Dispose()
    }
    $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$sizes.Length)
    $offset = 6 + 16 * $sizes.Length
    for ($i = 0; $i -lt $sizes.Length; $i++) {
        $dimension = [byte]($sizes[$i] % 256)
        $writer.Write($dimension); $writer.Write($dimension)
        $writer.Write([byte]0); $writer.Write([byte]0)
        $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$payloads[$i].Length); $writer.Write([uint32]$offset)
        $offset += $payloads[$i].Length
    }
    foreach ($payload in $payloads) { $writer.Write([byte[]]$payload) }
    $writer.Flush()
    [IO.File]::WriteAllBytes((Join-Path $winResources 'app_icon.ico'), $buffer.ToArray())
    $writer.Dispose(); $buffer.Dispose()
} finally { $image.Dispose() }
