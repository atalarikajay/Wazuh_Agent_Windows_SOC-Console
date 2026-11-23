# Karantina, hapus, atau pulihkan file. data.path, data.mode = quarantine | delete | restore.
. (Join-Path $PSScriptRoot "soc-common.ps1")
$d = Get-ArData
$path = [string]$d.path
$mode = if ($d.mode) { [string]$d.mode } else { "quarantine" }
$qdir = "C:\ProgramData\SOC\Quarantine"
if (-not (Test-Path $qdir)) { New-Item -ItemType Directory -Path $qdir -Force | Out-Null }

$forbidden = @("C:\Windows\", "C:\Program Files (x86)\ossec-agent\", "C:\Program Files\WatchGuard\", "C:\Program Files (x86)\WatchGuard\", "C:\ProgramData\Panda Security\")

if (-not $path) { Write-ArLog "path kosong"; exit 0 }
foreach ($f in $forbidden) {
    if ($path.StartsWith($f, [System.StringComparison]::OrdinalIgnoreCase) -and $mode -ne "restore") {
        Write-ArLog "path $path berada di folder terlindung, ditolak"; exit 0
    }
}

if ($mode -eq "restore") {
    # path adalah berkas .quar di folder karantina, tujuan dibaca dari .json pendampingnya
    $meta = "$path.json"
    if (-not (Test-Path $meta)) { Write-ArLog "meta $meta tidak ada"; exit 0 }
    $m = Get-Content $meta -Raw | ConvertFrom-Json
    try { Move-Item -Path $path -Destination $m.original -Force -ErrorAction Stop; Remove-Item $meta -Force
          Write-ArLog "dipulihkan $path ke $($m.original)" }
    catch { Write-ArLog "gagal pulihkan: $($_.Exception.Message)" }
    exit 0
}

if (-not (Test-Path -LiteralPath $path)) { Write-ArLog "file $path tidak ada"; exit 0 }

# matikan proses yang berasal dari file itu supaya bisa dipindah
Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -ieq $path } | ForEach-Object {
    try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; Write-ArLog "proses $($_.Id) dari file dimatikan" } catch {}
}

if ($mode -eq "delete") {
    try { Remove-Item -LiteralPath $path -Force -ErrorAction Stop; Write-ArLog "dihapus $path" }
    catch { Write-ArLog "gagal hapus ${path}: $($_.Exception.Message)" }
    exit 0
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$dest = Join-Path $qdir ("{0}_{1}.quar" -f $stamp, [System.IO.Path]::GetFileName($path))
try {
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
    Move-Item -LiteralPath $path -Destination $dest -Force -ErrorAction Stop
    @{ original = $path; quarantined_at = (Get-Date).ToString("o"); sha256 = $hash } | ConvertTo-Json | Set-Content "$dest.json" -Encoding UTF8
    # hanya SYSTEM dan Administrators yang boleh menyentuh
    icacls $dest /inheritance:r /grant:r "SYSTEM:F" "Administrators:F" | Out-Null
    Write-ArLog "dikarantina $path ke $dest sha256=$hash"
} catch { Write-ArLog "gagal karantina ${path}: $($_.Exception.Message)" }
