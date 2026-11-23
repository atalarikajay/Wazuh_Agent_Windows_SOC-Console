# Bagian bersama untuk script active response SOC di Windows.
# Dipanggil lewat dot-source dari tiap script. Membaca JSON active response dari stdin.
$ErrorActionPreference = "Continue"
$script:ArLog = Join-Path ${env:ProgramFiles(x86)} "ossec-agent\active-response\active-responses.log"
if (-not (Test-Path (Split-Path $script:ArLog))) { $script:ArLog = "C:\ProgramData\SOC\active-responses.log" }

function Write-ArLog([string]$msg) {
    $line = "{0} soc-ar: {1}" -f (Get-Date -Format "yyyy/MM/dd HH:mm:ss"), $msg
    try { Add-Content -Path $script:ArLog -Value $line -Encoding UTF8 } catch {}
    Write-Output $line
}

function Read-ArInput {
    try { $raw = [Console]::In.ReadToEnd() } catch { $raw = "" }
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    try { return ($raw | ConvertFrom-Json) } catch { Write-ArLog "JSON stdin tidak sah: $raw"; return $null }
}

function Get-ArData {
    # Mengembalikan objek data dari parameters.alert.data, atau objek kosong.
    $in = Read-ArInput
    if ($null -eq $in) { return [pscustomobject]@{} }
    $cmd = $in.command
    if ($cmd -and $cmd -ne "add") { Write-ArLog "perintah '$cmd' diabaikan"; exit 0 }
    $d = $in.parameters.alert.data
    if ($null -eq $d) { $d = [pscustomobject]@{} }
    return $d
}
