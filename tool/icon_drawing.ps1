# Shared vector renderer. Transparent corners are generated only where the
# platform does not apply a mask; store uploads remain full-bleed and opaque.
function Write-FontIcon {
    param([string]$Path, [int]$Size, [switch]$Rounded,
          [single]$Inset = 0, [switch]$Foreground)
    $transparent = $Rounded -or $Foreground
    $pixelFormat = if ($transparent) { [Drawing.Imaging.PixelFormat]::Format32bppArgb } else { [Drawing.Imaging.PixelFormat]::Format24bppRgb }
    $bitmap = [Drawing.Bitmap]::new(1024, 1024, $pixelFormat)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $background = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#D9437B'))
    if ($Rounded) {
        $edge = [single](1024 * $Inset)
        $side = [single](1024 - 2 * $edge)
        $diameter = [single]($side * 0.44)
        $far = [single]($edge + $side - $diameter)
        $shape = [Drawing.Drawing2D.GraphicsPath]::new()
        $shape.AddArc($edge, $edge, $diameter, $diameter, 180, 90)
        $shape.AddArc($far, $edge, $diameter, $diameter, 270, 90)
        $shape.AddArc($far, $far, $diameter, $diameter, 0, 90)
        $shape.AddArc($edge, $far, $diameter, $diameter, 90, 90)
        $shape.CloseFigure()
        $graphics.FillPath($background, $shape)
        $shape.Dispose()
    } elseif (!$Foreground) {
        $graphics.Clear($background.Color)
    }
    $family = [Drawing.FontFamily]::new('Segoe UI')
    $format = [Drawing.StringFormat]::GenericTypographic
    # Preserve the approved face, weight, baseline and proportions in one run.
    $wordmark = [Drawing.Drawing2D.GraphicsPath]::new()
    $wordmark.AddString('Font V', $family, [int][Drawing.FontStyle]::Regular, 300, [Drawing.PointF]::new(0, 0), $format)
    $bounds = $wordmark.GetBounds()
    # Adaptive foreground artwork must remain inside Android's 66/108 safe zone.
    $contentScale = if ($Foreground) { 0.64 } else { 1 - 2 * $Inset }
    $scale = [single]([Math]::Min(760 / $bounds.Width, 240 / $bounds.Height) * $contentScale)
    $left = [single]((1024 - $bounds.Width * $scale) / 2 - $bounds.X * $scale)
    $top = [single]((1024 - $bounds.Height * $scale) / 2 - $bounds.Y * $scale)
    $position = [Drawing.Drawing2D.Matrix]::new($scale, 0, 0, $scale, $left, $top)
    $wordmark.Transform($position)
    $graphics.FillPath([Drawing.Brushes]::White, $wordmark)
    $output = [Drawing.Bitmap]::new($Size, $Size, $pixelFormat)
    $scaled = [Drawing.Graphics]::FromImage($output)
    $scaled.Clear([Drawing.Color]::Transparent)
    $scaled.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    # TileFlip prevents a transparent fringe on full-bleed resize boundaries.
    $attributes = [Drawing.Imaging.ImageAttributes]::new()
    $attributes.SetWrapMode([Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $scaled.DrawImage($bitmap, [Drawing.Rectangle]::new(0, 0, $Size, $Size), 0, 0, 1024, 1024, [Drawing.GraphicsUnit]::Pixel, $attributes)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path)) | Out-Null
    $output.Save($Path, [Drawing.Imaging.ImageFormat]::Png)
    $attributes.Dispose(); $scaled.Dispose(); $output.Dispose()
    $position.Dispose(); $format.Dispose(); $family.Dispose(); $wordmark.Dispose()
    $background.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
}
