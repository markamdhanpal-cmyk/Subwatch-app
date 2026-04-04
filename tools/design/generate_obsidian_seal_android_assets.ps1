Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

function New-RoundedRectPath {
    param(
        [System.Drawing.RectangleF]$Rect,
        [float]$Radius
    )

    $diameter = [Math]::Max(1.0, $Radius * 2.0)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($Rect.X, $Rect.Y, $diameter, $diameter, 180, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Y, $diameter, $diameter, 270, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($Rect.X, $Rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-ObsidianSealMark {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.RectangleF]$Bounds
    )

    $amber = [System.Drawing.Color]::FromArgb(0xE7, 0xA1, 0x4C)
    $amberSoft = [System.Drawing.Color]::FromArgb(0xF3, 0xDE, 0xC8)
    $warmIvory = [System.Drawing.Color]::FromArgb(0xF2, 0xEC, 0xE3)
    $slabShadow = [System.Drawing.Color]::FromArgb(0xB1, 0x97, 0x82)
    $slabBorder = [System.Drawing.Color]::FromArgb(0x73, 0x63, 0x58)
    $obsidianInk = [System.Drawing.Color]::FromArgb(0x22, 0x1A, 0x14)
    $trustTeal = [System.Drawing.Color]::FromArgb(0x72, 0xA7, 0x9F)

    $w = $Bounds.Width
    $h = $Bounds.Height
    $x = $Bounds.X
    $y = $Bounds.Y

    $ringWidth = $w * 0.118
    $ringRect = New-Object System.Drawing.RectangleF ($x + ($w * 0.47)), ($y + ($h * 0.08)), ($w * 0.34), ($h * 0.34)
    $ringPen = New-Object System.Drawing.Pen $amber, $ringWidth
    $ringPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $ringPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $Graphics.DrawArc($ringPen, $ringRect, -29.8, 287.6)
    $ringPen.Dispose()

    $stemRect = New-Object System.Drawing.RectangleF ($x + ($w * 0.58)), ($y + ($h * 0.30)), ($w * 0.10), ($h * 0.22)
    $stemPath = New-RoundedRectPath -Rect $stemRect -Radius ($w * 0.05)
    $stemBrush = New-Object System.Drawing.SolidBrush $amber
    $Graphics.FillPath($stemBrush, $stemPath)
    $Graphics.FillEllipse(
        $stemBrush,
        ($x + ($w * 0.63) - ($w * 0.056)),
        ($y + ($h * 0.30) - ($w * 0.056)),
        ($w * 0.112),
        ($w * 0.112)
    )
    $stemPath.Dispose()
    $stemBrush.Dispose()

    $slabRect = New-Object System.Drawing.RectangleF ($x + ($w * 0.16)), ($y + ($h * 0.46)), ($w * 0.68), ($h * 0.31)
    $slabPath = New-RoundedRectPath -Rect $slabRect -Radius ($w * 0.13)
    $slabGradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $slabRect,
        $amberSoft,
        $slabShadow,
        [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
    )
    $Graphics.FillPath($slabGradient, $slabPath)
    $slabGradient.Dispose()
    $slabPen = New-Object System.Drawing.Pen $slabBorder, ($w * 0.03)
    $Graphics.DrawPath($slabPen, $slabPath)
    $slabPen.Dispose()
    $slabPath.Dispose()

    $connectorBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0xE0, $amber))
    $Graphics.FillEllipse(
        $connectorBrush,
        ($x + ($w * 0.63) - ($w * 0.045)),
        ($y + ($h * 0.51) - ($w * 0.045)),
        ($w * 0.09),
        ($w * 0.09)
    )
    $connectorBrush.Dispose()

    $tagRect = New-Object System.Drawing.RectangleF ($x + ($w * 0.24)), ($y + ($h * 0.56)), ($w * 0.10), ($h * 0.10)
    $tagPath = New-RoundedRectPath -Rect $tagRect -Radius ($w * 0.05)
    $tagBrush = New-Object System.Drawing.SolidBrush $trustTeal
    $Graphics.FillPath($tagBrush, $tagPath)
    $tagPath.Dispose()
    $tagBrush.Dispose()

    $lineBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0xD6, $obsidianInk))
    $lineOneRect = New-Object System.Drawing.RectangleF ($x + ($w * 0.39)), ($y + ($h * 0.56)), ($w * 0.28), ($h * 0.05)
    $lineTwoRect = New-Object System.Drawing.RectangleF ($x + ($w * 0.39)), ($y + ($h * 0.64)), ($w * 0.20), ($h * 0.045)
    $lineOnePath = New-RoundedRectPath -Rect $lineOneRect -Radius ($w * 0.024)
    $lineTwoPath = New-RoundedRectPath -Rect $lineTwoRect -Radius ($w * 0.022)
    $Graphics.FillPath($lineBrush, $lineOnePath)
    $Graphics.FillPath($lineBrush, $lineTwoPath)
    $lineOnePath.Dispose()
    $lineTwoPath.Dispose()
    $lineBrush.Dispose()

    $dotBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0xDA, $amber))
    $Graphics.FillEllipse(
        $dotBrush,
        ($x + ($w * 0.21) - ($w * 0.022)),
        ($y + ($h * 0.61) - ($w * 0.022)),
        ($w * 0.044),
        ($w * 0.044)
    )
    $dotBrush.Dispose()
}

function New-Canvas {
    param(
        [int]$Size
    )

    $bitmap = New-Object System.Drawing.Bitmap -ArgumentList @(
        $Size,
        $Size,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    return @($bitmap, $graphics)
}

function Save-Png {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$Path
    )
    $directory = [System.IO.Path]::GetDirectoryName($Path)
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    }
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Draw-LauncherForeground {
    param(
        [string]$Path
    )
    $canvas = New-Canvas -Size 432
    $bitmap = $canvas[0]
    $graphics = $canvas[1]
    try {
        Draw-ObsidianSealMark -Graphics $graphics -Bounds (New-Object System.Drawing.RectangleF 58, 46, 316, 316)
        Save-Png -Bitmap $bitmap -Path $Path
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

function Draw-LaunchMark {
    param(
        [string]$Path
    )
    $canvas = New-Canvas -Size 280
    $bitmap = $canvas[0]
    $graphics = $canvas[1]
    try {
        Draw-ObsidianSealMark -Graphics $graphics -Bounds (New-Object System.Drawing.RectangleF 30, 20, 220, 220)
        Save-Png -Bitmap $bitmap -Path $Path
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

function Draw-LegacyLauncherIcon {
    param(
        [string]$Path,
        [int]$Size
    )
    $canvas = New-Canvas -Size $Size
    $bitmap = $canvas[0]
    $graphics = $canvas[1]
    try {
        $bgRect = New-Object System.Drawing.RectangleF ($Size * 0.02), ($Size * 0.02), ($Size * 0.96), ($Size * 0.96)
        $bgPath = New-RoundedRectPath -Rect $bgRect -Radius ($Size * 0.20)
        $bgGradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $bgRect,
            [System.Drawing.Color]::FromArgb(0x1A, 0x1F, 0x28),
            [System.Drawing.Color]::FromArgb(0x0E, 0x12, 0x18),
            [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
        )
        $graphics.FillPath($bgGradient, $bgPath)
        $bgGradient.Dispose()
        $outerPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(0x45, 0x3B, 0x34), ($Size * 0.022))
        $graphics.DrawPath($outerPen, $bgPath)
        $outerPen.Dispose()
        $bgPath.Dispose()

        Draw-ObsidianSealMark -Graphics $graphics -Bounds (New-Object System.Drawing.RectangleF ($Size * 0.16), ($Size * 0.11), ($Size * 0.68), ($Size * 0.68))
        Save-Png -Bitmap $bitmap -Path $Path
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$resRoot = Join-Path $projectRoot "android\app\src\main\res"

Draw-LauncherForeground -Path (Join-Path $resRoot "drawable-nodpi\ic_launcher_foreground.png")
Draw-LaunchMark -Path (Join-Path $resRoot "drawable-nodpi\launch_mark.png")

$legacySizes = @{
    "mipmap-mdpi\ic_launcher.png" = 48
    "mipmap-hdpi\ic_launcher.png" = 72
    "mipmap-xhdpi\ic_launcher.png" = 96
    "mipmap-xxhdpi\ic_launcher.png" = 144
    "mipmap-xxxhdpi\ic_launcher.png" = 192
}

foreach ($entry in $legacySizes.GetEnumerator()) {
    Draw-LegacyLauncherIcon -Path (Join-Path $resRoot $entry.Key) -Size $entry.Value
}

Write-Output "Generated Obsidian Seal Android launcher/splash assets."
