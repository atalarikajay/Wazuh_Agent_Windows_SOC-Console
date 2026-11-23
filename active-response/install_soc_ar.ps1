# Pasang script Active Response SOC ke agen Wazuh Windows yang sudah terpasang.
# Jalankan sebagai Administrator, satu baris:
#   iex (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/atalarikajay/Wazuh_Agent_Windows_SOC-Console/main/active-response/install_soc_ar.ps1')
# Sumber lain (share jaringan atau folder lokal) lewat variabel lingkungan sebelum iex:
#   $env:SOC_AR_SOURCE = '\\server\share\active-response'
$ErrorActionPreference = 'Stop'
$base = if ($env:SOC_AR_SOURCE) { $env:SOC_AR_SOURCE.TrimEnd('/\') } else { 'https://raw.githubusercontent.com/atalarikajay/Wazuh_Agent_Windows_SOC-Console/main/active-response' }
$bin  = Join-Path ${env:ProgramFiles(x86)} 'ossec-agent\active-response\bin'
$files = @('soc-common.ps1', 'soc-kill-process.cmd', 'soc-kill-process.ps1',
           'soc-quarantine-file.cmd', 'soc-quarantine-file.ps1', 'soc-block-ip.cmd', 'soc-block-ip.ps1')

if (-not (Test-Path $bin)) { Write-Host "Folder $bin tidak ada. Agen Wazuh belum terpasang." -ForegroundColor Red; exit 1 }

$ProgressPreference = 'SilentlyContinue'
$ok = 0
foreach ($f in $files) {
    $dest = Join-Path $bin $f
    try {
        if ($base -match '^https?://') {
            Invoke-WebRequest -Uri "$base/$f" -OutFile $dest -UseBasicParsing -TimeoutSec 60
        } else {
            Copy-Item (Join-Path $base $f) $dest -Force
        }
        $size = (Get-Item $dest).Length
        if ($size -lt 50) { throw "berkas cuma $size byte, kemungkinan halaman error" }
        Write-Host "  OK   $f ($size byte)" -ForegroundColor Green
        $ok++
    } catch {
        Write-Host "  GAGAL $f : $($_.Exception.Message)" -ForegroundColor Red
    }
}
if ($ok -eq $files.Count) {
    Write-Host "Semua $ok script Active Response SOC terpasang di $bin. Agen tidak perlu direstart." -ForegroundColor Green
    exit 0
}
Write-Host "Hanya $ok dari $($files.Count) berkas terpasang." -ForegroundColor Yellow
exit 1
