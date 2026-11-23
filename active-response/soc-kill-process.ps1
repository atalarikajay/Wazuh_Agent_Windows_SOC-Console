# Matikan proses berdasarkan PID atau nama. data.pid atau data.name.
. (Join-Path $PSScriptRoot "soc-common.ps1")
$d = Get-ArData
$pid_ = [string]$d.pid
$name = [string]$d.name
$protected = @("wazuh-agent", "agent-auth", "WatchGuardAgent", "PSANHost", "WGEndpoint", "csrss", "wininit", "winlogon", "lsass", "services", "svchost", "explorer", "System")

if ($pid_ -match '^\d+$') {
    $p = Get-Process -Id ([int]$pid_) -ErrorAction SilentlyContinue
    if ($null -eq $p) { Write-ArLog "PID $pid_ tidak ditemukan"; exit 0 }
    if ($protected -contains $p.ProcessName) { Write-ArLog "PID $pid_ ($($p.ProcessName)) dilindungi, tidak dimatikan"; exit 0 }
    try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Write-ArLog "PID $pid_ ($($p.ProcessName)) dimatikan" }
    catch { Write-ArLog "gagal matikan PID ${pid_}: $($_.Exception.Message)" }
    exit 0
}
if ($name) {
    $n = [System.IO.Path]::GetFileNameWithoutExtension($name)
    if ($protected -contains $n) { Write-ArLog "proses $n dilindungi, tidak dimatikan"; exit 0 }
    $ps = Get-Process -Name $n -ErrorAction SilentlyContinue
    if (-not $ps) { Write-ArLog "proses $n tidak berjalan"; exit 0 }
    foreach ($p in $ps) {
        try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Write-ArLog "proses $n PID $($p.Id) dimatikan" }
        catch { Write-ArLog "gagal matikan $n PID $($p.Id): $($_.Exception.Message)" }
    }
    exit 0
}
Write-ArLog "tidak ada pid atau name di data"
