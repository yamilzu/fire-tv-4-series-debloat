[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Target,
    [string]$Adb = 'adb.exe',
    [ValidateSet('Audit', 'Apply', 'Restore')][string]$Action = 'Audit',
    [ValidateSet('Apps', 'Telemetry', 'Demos', 'Alexa')][string]$Group,
    [string]$StateFile,
    [switch]$Approve
)

$ErrorActionPreference = 'Stop'
$groups = @{
    Apps = @(
        'com.amazon.bueller.music'
        'com.amazon.bueller.photos'
        'com.amazon.shoptv.client'
        'com.amazon.gamehub'
    )
    Telemetry = @(
        'com.amazon.wirelessmetrics.service'
        'com.amazon.perfc'
        'com.amazon.perfcollection'
        'com.amazon.dp.logger'
        'com.amazon.logan'
        'com.amazon.neo.minerva.logcat'
        'com.amazon.ceviche'
        'com.amazon.tv.developer.dataservice'
    )
    Demos = @(
        'com.amazon.tv.democontent.provider'
        'com.amazon.tmm.tutorial'
        'com.amazon.tv.releasenotes'
    )
    Alexa = @(
        'com.amazon.alexadirectivebrokerservice'
        'amazon.speech.davs.davcservice'
        'com.amazon.alexamediaplayer.runtime.ftv'
        'com.amazon.alexa.externalmediaplayer.fireos'
        'com.amazon.alexa.datastore.app'
        'com.amazon.tv.alexaalerts'
        'com.amazon.tv.alexanotifications'
        'com.amazon.aca'
        'com.amazon.firetv.androidskillconnectioncapability'
    )
}

function Invoke-Tv {
    $result = & $Adb -s $Target shell @args
    if ($LASTEXITCODE -ne 0) {
        throw "ADB failed: $args. $result"
    }
    $result
}

function Get-PackageState($Package) {
    $user = Invoke-Tv dumpsys package $Package |
        Where-Object { $_ -match '^\s*User 0: .*installed=true .*enabled=[0-4]\b' } |
        Select-Object -First 1
    if ($user -match 'enabled=([0-4])\b') {
        return [int]$Matches[1]
    }
    throw "Could not verify installed user-0 state for $Package."
}

function Test-CoreServices {
    foreach ($service in 'tv_input', 'audio') {
        if (-not ((Invoke-Tv service check $service) -match ': found$')) {
            throw "Service unavailable: $service"
        }
    }
    foreach ($intent in 'android.settings.SETTINGS', 'android.intent.action.MAIN') {
        $category = @()
        if ($intent -eq 'android.intent.action.MAIN') {
            $category = @('-c', 'android.intent.category.HOME')
        }
        if (-not ((Invoke-Tv cmd package resolve-activity --brief --user 0 -a $intent @category) -match '^[\w.]+/')) {
            throw "Activity unavailable: $intent"
        }
    }
}

function Restore-Package($Entry) {
    if ((Get-PackageState $Entry.Package) -ne $Entry.Enabled) {
        $mode = @('default-state', 'enable')[[int]$Entry.Enabled]
        Invoke-Tv pm $mode --user 0 $Entry.Package
        if ((Get-PackageState $Entry.Package) -ne $Entry.Enabled) {
            throw "Restore did not verify for $($Entry.Package)."
        }
    }
}

if ($Action -ne 'Audit' -and (-not $Approve -or -not $StateFile)) {
    throw 'Apply and Restore require -Approve and -StateFile.'
}
if ($Action -eq 'Apply' -and (-not $Group -or (Test-Path -LiteralPath $StateFile))) {
    throw 'Apply requires one -Group and a new state file.'
}

$model = Invoke-Tv getprop ro.product.model
$build = Invoke-Tv getprop ro.build.display.id
$fingerprint = Invoke-Tv getprop ro.build.fingerprint
if ($model -ne 'AFTNA1322D' -or $build -ne 'RS8185.3898N.0033018558976') {
    throw "Unsupported device or build: $model / $build"
}

if ($Action -eq 'Restore') {
    $saved = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json
    if ($saved.Fingerprint -ne $fingerprint -or $saved.Target -ne $Target -or -not $groups.ContainsKey([string]$saved.Group)) {
        throw 'State file does not match this target and build.'
    }
    foreach ($entry in $saved.Entries) {
        if ($entry.Package -notin $groups[$saved.Group] -or $entry.Enabled -notin 0, 1) {
            throw 'Unexpected state-file entry.'
        }
    }
    $failures = @()
    foreach ($entry in $saved.Entries) {
        try { Restore-Package $entry }
        catch { $failures += $_ }
    }
    if ($failures.Count) { throw ($failures -join [Environment]::NewLine) }
    Test-CoreServices
    return
}

Test-CoreServices
$selected = if ($Group) { @($Group) } else { @('Apps', 'Telemetry', 'Demos', 'Alexa') }
$entries = foreach ($name in $selected) {
    foreach ($package in $groups[$name]) {
        [pscustomobject]@{
            Group = $name
            Package = $package
            Enabled = Get-PackageState $package
        }
    }
}
if ($Action -eq 'Audit') {
    $entries
    return
}

$changes = @($entries | Where-Object { $_.Enabled -in 0, 1 })
if (-not $changes.Count) {
    Write-Output 'No enabled packages in this group.'
    return
}
$snapshot = @{
    Fingerprint = $fingerprint
    Target = $Target
    Group = $Group
    Entries = $changes
} | ConvertTo-Json -Depth 4
New-Item -ItemType File -Path $StateFile -Value $snapshot | Out-Null
Write-Output "Rollback state saved to $StateFile"

$attempted = @()
try {
    foreach ($entry in $changes) {
        $attempted += $entry
        Invoke-Tv pm disable-user --user 0 $entry.Package
        if ((Get-PackageState $entry.Package) -ne 3) {
            throw "Disable did not verify for $($entry.Package)."
        }
    }
    Test-CoreServices
} catch {
    foreach ($entry in $attempted) {
        try { Restore-Package $entry }
        catch { Write-Warning "Rollback failed for $($entry.Package): $_" }
    }
    throw
}
Write-Output 'Batch verified. Test playback, HDMI and the remote before continuing.'
