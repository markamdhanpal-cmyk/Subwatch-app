param(
    [Parameter(Mandatory = $true)]
    [string]$DeviceId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("airtel_heavy", "weak_mid_range")]
    [string]$DeviceClass,

    [string]$ArtifactsRoot = "D:\Subscription killer\signoff_artifacts",
    [string]$DateStamp = "",
    [string]$PackageName = "app.subscriptionkiller",
    [int]$FreshWaitSeconds = 45,
    [int]$RestoreWaitSeconds = 25,
    [switch]$CollectRuntime,
    [switch]$SkipReboot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Adb {
    param(
        [string[]]$CommandArgs,
        [switch]$AllowFailure
    )
    $output = & adb @CommandArgs 2>&1
    if (-not $AllowFailure -and $LASTEXITCODE -ne 0) {
        throw "adb command failed: adb $($CommandArgs -join ' ')`n$output"
    }
    return ($output | Out-String).TrimEnd()
}

function Save-Text {
    param(
        [string]$Path,
        [string]$Text
    )
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $Text | Out-File -FilePath $Path -Encoding utf8
}

function Append-Text {
    param(
        [string]$Path,
        [string]$Text
    )
    $Text | Out-File -FilePath $Path -Encoding utf8 -Append
}

function Get-MemTotalKb {
    param([string]$Meminfo)
    $match = [regex]::Match($Meminfo, "MemTotal:\s+(\d+)\s+kB")
    if (-not $match.Success) {
        return $null
    }
    return [int64]$match.Groups[1].Value
}

function Parse-PhaseTimingMs {
    param(
        [string]$LogText,
        [string]$PhaseLabel
    )
    $startLine = $LogText -split "`r?`n" | Where-Object { $_ -match "loadInitial.*(start|starting)" } | Select-Object -First 1
    $endLine = $LogText -split "`r?`n" | Where-Object { $_ -match "loadInitial.*(success|complete|completed|finished)" } | Select-Object -First 1
    if (-not $startLine -or -not $endLine) {
        return @{
            ParseStatus = "parse_failed"
            Start = ""
            End = ""
            DurationMs = ""
            Note = "Could not find loadInitial start/success markers in log."
        }
    }

    $timestampRegex = "^(?<mon>\d{2})-(?<day>\d{2})\s+(?<time>\d{2}:\d{2}:\d{2}\.\d{3})"
    $sm = [regex]::Match($startLine, $timestampRegex)
    $em = [regex]::Match($endLine, $timestampRegex)
    if (-not $sm.Success -or -not $em.Success) {
        return @{
            ParseStatus = "parse_failed"
            Start = $startLine
            End = $endLine
            DurationMs = ""
            Note = "Found markers but could not parse timestamps."
        }
    }

    $year = (Get-Date).Year
    $startText = "$year-$($sm.Groups['mon'].Value)-$($sm.Groups['day'].Value) $($sm.Groups['time'].Value)"
    $endText = "$year-$($em.Groups['mon'].Value)-$($em.Groups['day'].Value) $($em.Groups['time'].Value)"
    try {
        $start = [datetime]::ParseExact($startText, "yyyy-MM-dd HH:mm:ss.fff", $null)
        $end = [datetime]::ParseExact($endText, "yyyy-MM-dd HH:mm:ss.fff", $null)
        $duration = [int64]($end - $start).TotalMilliseconds
        return @{
            ParseStatus = "ok"
            Start = $startText
            End = $endText
            DurationMs = $duration
            Note = "$PhaseLabel timing parsed from logcat."
        }
    } catch {
        return @{
            ParseStatus = "parse_failed"
            Start = $startText
            End = $endText
            DurationMs = ""
            Note = "Timestamp parse threw exception: $($_.Exception.Message)"
        }
    }
}

if ([string]::IsNullOrWhiteSpace($DateStamp)) {
    $DateStamp = Get-Date -Format "yyyy-MM-dd"
}

$runRoot = Join-Path $ArtifactsRoot ("qualifying_device_{0}" -f $DateStamp)
$deviceRoot = Join-Path $runRoot ("{0}_{1}" -f $DeviceClass, $DeviceId)
New-Item -ItemType Directory -Path $deviceRoot -Force | Out-Null

$deviceInfoPath = Join-Path $deviceRoot "device_info.txt"
$countsPath = Join-Path $deviceRoot "corpus_counts.txt"
$qualificationPath = Join-Path $deviceRoot "qualification_verdict.txt"
$scenarioPath = Join-Path $deviceRoot "scenario_truth_table.csv"

$devicesList = Invoke-Adb -CommandArgs @("devices", "-l")
$model = Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "getprop", "ro.product.model")
$operator = Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "getprop", "gsm.sim.operator.alpha")
$memInfo = Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "cat", "/proc/meminfo")
$lowRam = Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "getprop", "ro.config.low_ram")

$deviceInfoText = @(
    "device_id=$DeviceId"
    "device_class_target=$DeviceClass"
    "timestamp_ist=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
    ""
    "[adb devices -l]"
    $devicesList
    ""
    "[ro.product.model]"
    $model
    ""
    "[gsm.sim.operator.alpha]"
    $operator
    ""
    "[ro.config.low_ram]"
    $lowRam
    ""
    "[/proc/meminfo]"
    $memInfo
) -join "`r`n"
Save-Text -Path $deviceInfoPath -Text $deviceInfoText

$sms = Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "content", "query", "--uri", "content://sms", "--projection", "body")
$airtel = ([regex]::Matches($sms, "airtel", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
$jio = ([regex]::Matches($sms, "jio", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
$wynk = ([regex]::Matches($sms, "wynk", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
$promo = ([regex]::Matches($sms, "offer|discount|cashback|coupon|promo", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
$hindiHinglish = ([regex]::Matches($sms, "aapka|khatam|shuru|muft|abhi|validity|recharge", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
$totalRows = ([regex]::Matches($sms, "(?m)^Row:")).Count
$airtelShare = if (($airtel + $jio) -gt 0) { [math]::Round($airtel / ($airtel + $jio), 4) } else { 0.0 }

$countsText = @(
    "device_id=$DeviceId"
    "device_class_target=$DeviceClass"
    "total_sms_rows=$totalRows"
    "airtel=$airtel"
    "jio=$jio"
    "airtel_share=$airtelShare"
    "wynk=$wynk"
    "promo=$promo"
    "hindi_hinglish=$hindiHinglish"
) -join "`r`n"
Save-Text -Path $countsPath -Text $countsText

$deviceLine = $devicesList -split "`r?`n" | Where-Object { $_ -match [regex]::Escape($DeviceId) } | Select-Object -First 1
$isPhysical = $true
if (-not $deviceLine) { $isPhysical = $false }
if ($deviceLine -match "emulator" -or $model -match "sdk_gphone|emulator") { $isPhysical = $false }

$memTotalKb = Get-MemTotalKb -Meminfo $memInfo
$bundleEvidencePresent = ($wynk -gt 0) -or ($promo -gt 0) -or ($hindiHinglish -gt 0)
$airtelPass = $isPhysical -and ($airtelShare -ge 0.55) -and ($airtel -ge 300) -and $bundleEvidencePresent
$weakPass = $isPhysical -and ($null -ne $memTotalKb) -and ($memTotalKb -le 8500000)

$qualifyPass = $false
$reasons = New-Object System.Collections.Generic.List[string]
if (-not $isPhysical) { $reasons.Add("Rejected: device is not verified as physical Android.") }

if ($DeviceClass -eq "airtel_heavy") {
    $qualifyPass = $airtelPass
    if ($airtelShare -lt 0.55) { $reasons.Add("Rejected: airtel_share=$airtelShare (< 0.55).") }
    if ($airtel -lt 300) { $reasons.Add("Rejected: airtel_count=$airtel (< 300).") }
    if (-not $bundleEvidencePresent) { $reasons.Add("Rejected: missing Airtel bundle/noise evidence (wynk/promo/hindi_hinglish).") }
} else {
    $qualifyPass = $weakPass
    if ($null -eq $memTotalKb) { $reasons.Add("Rejected: MemTotal missing from /proc/meminfo.") }
    if ($null -ne $memTotalKb -and $memTotalKb -gt 8500000) { $reasons.Add("Rejected: MemTotal=$memTotalKb (> 8,500,000 kB upper bound).") }
}

$qualificationText = @(
    "device_id=$DeviceId"
    "device_class_target=$DeviceClass"
    "is_physical_android=$isPhysical"
    "mem_total_kb=$memTotalKb"
    "airtel_share=$airtelShare"
    "airtel_count=$airtel"
    "bundle_evidence_present=$bundleEvidencePresent"
    "qualification_status=$(if($qualifyPass){'PASS'}else{'FAIL'})"
    ""
    "[reasons]"
) + $(if ($reasons.Count -eq 0) { "All gating checks passed." } else { $reasons })
Save-Text -Path $qualificationPath -Text ($qualificationText -join "`r`n")

$templatePath = Join-Path $PSScriptRoot "scenario_truth_table_template.csv"
if (Test-Path $templatePath) {
    Copy-Item -Path $templatePath -Destination $scenarioPath -Force
    (Get-Content $scenarioPath -Raw).Replace("__DEVICE_ID__", $DeviceId).Replace("__DEVICE_CLASS__", $DeviceClass) | Out-File -FilePath $scenarioPath -Encoding utf8
}

if (-not $qualifyPass) {
    Write-Output "QUALIFICATION_FAILED: $DeviceClass on $DeviceId"
    Write-Output "See: $qualificationPath"
    exit 2
}

Write-Output "QUALIFICATION_PASSED: $DeviceClass on $DeviceId"

if (-not $CollectRuntime) {
    Write-Output "Runtime collection skipped (use -CollectRuntime to continue)."
    exit 0
}

$logFreshPath = Join-Path $deviceRoot "log_fresh.txt"
$logForcePath = Join-Path $deviceRoot "log_force_kill.txt"
$logRebootPath = Join-Path $deviceRoot "log_reboot.txt"
$snapFreshPath = Join-Path $deviceRoot "snapshot_fresh.json"
$snapForcePath = Join-Path $deviceRoot "snapshot_force_kill.json"
$snapRebootPath = Join-Path $deviceRoot "snapshot_reboot.json"
$timingFreshPath = Join-Path $deviceRoot "timing_fresh_ms.txt"
$timingRestorePath = Join-Path $deviceRoot "timing_restore_ms.txt"
$dashboardPath = Join-Path $deviceRoot "dashboard.png"
$reviewPath = Join-Path $deviceRoot "review_queue.png"
$usabilityPath = Join-Path $deviceRoot "usability_notes.txt"
$verifyPath = Join-Path $deviceRoot "package_verification.txt"

# Fresh run
Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "run-as", $PackageName, "rm", "-f", "files/ledger_snapshot.json") -AllowFailure | Out-Null
Invoke-Adb -CommandArgs @("-s", $DeviceId, "logcat", "-c") | Out-Null
Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "am", "force-stop", $PackageName) | Out-Null
Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "monkey", "-p", $PackageName, "-c", "android.intent.category.LAUNCHER", "1") | Out-Null
Start-Sleep -Seconds $FreshWaitSeconds
$logFresh = Invoke-Adb -CommandArgs @("-s", $DeviceId, "logcat", "-d")
Save-Text -Path $logFreshPath -Text $logFresh

$freshTiming = Parse-PhaseTimingMs -LogText $logFresh -PhaseLabel "fresh_scan"
$freshTimingText = @(
    "phase=fresh_scan"
    "parse_status=$($freshTiming.ParseStatus)"
    "start=$($freshTiming.Start)"
    "end=$($freshTiming.End)"
    "duration_ms=$($freshTiming.DurationMs)"
    "note=$($freshTiming.Note)"
) -join "`r`n"
Save-Text -Path $timingFreshPath -Text $freshTimingText

$snapFresh = Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "run-as", $PackageName, "cat", "files/ledger_snapshot.json") -AllowFailure
Save-Text -Path $snapFreshPath -Text $snapFresh
& adb -s $DeviceId exec-out screencap -p > $dashboardPath

# Force-kill restore
Invoke-Adb -CommandArgs @("-s", $DeviceId, "logcat", "-c") | Out-Null
Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "am", "force-stop", $PackageName) | Out-Null
Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "monkey", "-p", $PackageName, "-c", "android.intent.category.LAUNCHER", "1") | Out-Null
Start-Sleep -Seconds $RestoreWaitSeconds
$logForce = Invoke-Adb -CommandArgs @("-s", $DeviceId, "logcat", "-d")
Save-Text -Path $logForcePath -Text $logForce

$restoreTiming = Parse-PhaseTimingMs -LogText $logForce -PhaseLabel "restore_after_force_kill"
$restoreTimingText = @(
    "phase=restore_after_force_kill"
    "parse_status=$($restoreTiming.ParseStatus)"
    "start=$($restoreTiming.Start)"
    "end=$($restoreTiming.End)"
    "duration_ms=$($restoreTiming.DurationMs)"
    "note=$($restoreTiming.Note)"
) -join "`r`n"
Save-Text -Path $timingRestorePath -Text $restoreTimingText

$snapForce = Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "run-as", $PackageName, "cat", "files/ledger_snapshot.json") -AllowFailure
Save-Text -Path $snapForcePath -Text $snapForce
& adb -s $DeviceId exec-out screencap -p > $reviewPath

# Reboot continuity
if ($SkipReboot) {
    Save-Text -Path $logRebootPath -Text "REBOOT_SKIPPED: user requested -SkipReboot."
    Save-Text -Path $snapRebootPath -Text "REBOOT_SKIPPED: user requested -SkipReboot."
} else {
    Invoke-Adb -CommandArgs @("-s", $DeviceId, "reboot")
    Start-Sleep -Seconds 15
    $ready = $false
    for ($i = 0; $i -lt 48; $i++) {
        Start-Sleep -Seconds 5
        $state = (Invoke-Adb -CommandArgs @("-s", $DeviceId, "get-state") -AllowFailure)
        if ($state -match "device") {
            $ready = $true
            break
        }
    }
    if (-not $ready) {
        Save-Text -Path $logRebootPath -Text "REBOOT_FAILED: device did not reconnect within timeout."
        Save-Text -Path $snapRebootPath -Text "REBOOT_FAILED: no reboot snapshot captured."
    } else {
        Invoke-Adb -CommandArgs @("-s", $DeviceId, "logcat", "-c") | Out-Null
        Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "monkey", "-p", $PackageName, "-c", "android.intent.category.LAUNCHER", "1") | Out-Null
        Start-Sleep -Seconds $RestoreWaitSeconds
        $logReboot = Invoke-Adb -CommandArgs @("-s", $DeviceId, "logcat", "-d")
        Save-Text -Path $logRebootPath -Text $logReboot
        $snapReboot = Invoke-Adb -CommandArgs @("-s", $DeviceId, "shell", "run-as", $PackageName, "cat", "files/ledger_snapshot.json") -AllowFailure
        Save-Text -Path $snapRebootPath -Text $snapReboot
    }
}

if ($DeviceClass -eq "weak_mid_range") {
    $usabilityTemplate = @(
        "device_id=$DeviceId"
        "device_class=weak_mid_range"
        "frozen_gt_3s_during_scan="
        "dashboard_render_delay_gt_2s_after_success="
        "obvious_hitching_while_scrolling="
        "severe_trust_damaging_jank="
        "notes="
    ) -join "`r`n"
    Save-Text -Path $usabilityPath -Text $usabilityTemplate
}

$mandatory = @(
    "device_info.txt",
    "corpus_counts.txt",
    "qualification_verdict.txt",
    "log_fresh.txt",
    "log_force_kill.txt",
    "snapshot_fresh.json",
    "snapshot_force_kill.json",
    "timing_fresh_ms.txt",
    "timing_restore_ms.txt",
    "scenario_truth_table.csv",
    "dashboard.png"
)

if ($SkipReboot) {
    $mandatory += "log_reboot.txt"
    $mandatory += "snapshot_reboot.json"
} else {
    $mandatory += "log_reboot.txt"
    $mandatory += "snapshot_reboot.json"
}

if ($DeviceClass -eq "weak_mid_range") {
    $mandatory += "usability_notes.txt"
}

$missing = New-Object System.Collections.Generic.List[string]
foreach ($file in $mandatory) {
    $full = Join-Path $deviceRoot $file
    if (-not (Test-Path $full)) {
        $missing.Add($file)
    }
}

$verificationText = @(
    "device_id=$DeviceId"
    "device_class=$DeviceClass"
    "collect_runtime=true"
    "mandatory_file_check=$(if($missing.Count -eq 0){'PASS'}else{'FAIL'})"
    "missing_files=$(if($missing.Count -eq 0){''}else{($missing -join ',')})"
) -join "`r`n"
Save-Text -Path $verifyPath -Text $verificationText

if ($missing.Count -gt 0) {
    Write-Output "PACKAGE_INCOMPLETE: missing $($missing -join ', ')"
    exit 3
}

Write-Output "PACKAGE_READY_FOR_REVIEW: $deviceRoot"
