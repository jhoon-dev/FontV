$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$fontvRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$outputPath = Join-Path $fontvRoot 'store-assets/feature-graphic.png'
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($outputPath)) | Out-Null
$canvas = [Drawing.Bitmap]::new(1024, 500, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
$graphics = [Drawing.Graphics]::FromImage($canvas)
$graphics.Clear([Drawing.ColorTranslator]::FromHtml('#D9437B'))
$graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$center = [Drawing.StringFormat]::new()
$center.Alignment = [Drawing.StringAlignment]::Center
$center.LineAlignment = [Drawing.StringAlignment]::Center
$family = [Drawing.FontFamily]::new('Segoe UI')
$logo = [Drawing.Drawing2D.GraphicsPath]::new()
# Preserve the approved single-run wordmark: same face, weight and baseline.
$logo.AddString('Font V', $family, [int][Drawing.FontStyle]::Regular, 145, [Drawing.PointF]::new(0, 0), [Drawing.StringFormat]::GenericTypographic)
$bounds = $logo.GetBounds()
$matrix = [Drawing.Drawing2D.Matrix]::new()
$matrix.Translate([single](512 - ($bounds.X + $bounds.Width / 2)), [single](197 - ($bounds.Y + $bounds.Height / 2)))
$logo.Transform($matrix)
$graphics.FillPath([Drawing.Brushes]::White, $logo)
$subtitle = [Drawing.Font]::new('Segoe UI', 30, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
$credit = [Drawing.Font]::new('Segoe UI', 20, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
$graphics.DrawString('Explore your system fonts.', $subtitle, [Drawing.Brushes]::White, [Drawing.RectangleF]::new(80, 285, 864, 60), $center)
$graphics.DrawString('ToolMoa · jhoon-dev', $credit, [Drawing.Brushes]::White, [Drawing.RectangleF]::new(80, 397, 864, 40), $center)
$canvas.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
$credit.Dispose(); $subtitle.Dispose(); $matrix.Dispose(); $logo.Dispose(); $family.Dispose(); $center.Dispose(); $graphics.Dispose(); $canvas.Dispose()
Write-Output $outputPath
