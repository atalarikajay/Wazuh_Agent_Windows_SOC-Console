# Bagian bersama untuk script active response SOC di Windows.
# Dipanggil lewat dot-source dari tiap script. Membaca JSON active response dari stdin.
$ErrorActionPreference = "Continue"
$script:ArLog = Join-Path ${env:ProgramFiles(x86)} "ossec-agent\active-response\active-responses.log"
if (-not (Test-Path (Split-Path $script:ArLog))) { $script:ArLog = "C:\ProgramData\SOC\active-responses.log" }

function Write-ArLog([string]$msg) {
    $line = "{0} soc-ar: {1}" -f (Get-Date -Format "yyyy/MM/dd HH:mm:ss"), $msg
    # Agen Wazuh memegang berkas log ini, jadi buka dengan mode berbagi baca tulis, bukan Add-Content.
    try {
        $fs = New-Object IO.FileStream($script:ArLog, [IO.FileMode]::Append, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
        $sw = New-Object IO.StreamWriter($fs, (New-Object Text.UTF8Encoding $false))
        $sw.WriteLine($line); $sw.Close()
    } catch {}
    Write-Output $line
}

function Read-ArInput {
    # Agen mengirim JSON satu baris lalu MENUNGGU jawaban, stdin tidak pernah ditutup.
    # Jadi baca satu baris saja. ReadToEnd membuat script menggantung selamanya.
    try { $raw = [Console]::In.ReadLine() } catch { $raw = "" }
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
