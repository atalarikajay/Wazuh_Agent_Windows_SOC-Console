# Blok atau buka blokir IP lewat Windows Firewall. data.ip, data.mode = block | unblock.
. (Join-Path $PSScriptRoot "soc-common.ps1")
$d = Get-ArData
$ip = [string]$d.ip
$mode = if ($d.mode) { [string]$d.mode } else { "block" }

if (-not $ip) { Write-ArLog "ip kosong"; exit 0 }
if ($ip -notmatch '^(\d{1,3}\.){3}\d{1,3}(/\d{1,2})?$' -and $ip -notmatch '^[0-9a-fA-F:]+(/\d{1,3})?$') { Write-ArLog "ip $ip tidak sah"; exit 0 }
$never = @("127.0.0.1", "0.0.0.0", "::1")
if ($never -contains $ip) { Write-ArLog "ip $ip tidak boleh diblok"; exit 0 }

$name = "SOC-Block-$ip"
if ($mode -eq "unblock") {
    $out = netsh advfirewall firewall delete rule name="$name" 2>&1
    Write-ArLog "buka blokir $ip : $out"
    exit 0
}
$exists = netsh advfirewall firewall show rule name="$name" 2>&1
if ($exists -match "Rule Name") { Write-ArLog "rule $name sudah ada"; exit 0 }
$o1 = netsh advfirewall firewall add rule name="$name" dir=in action=block remoteip=$ip enable=yes profile=any 2>&1
$o2 = netsh advfirewall firewall add rule name="$name" dir=out action=block remoteip=$ip enable=yes profile=any 2>&1
Write-ArLog "blok $ip masuk: $o1 | keluar: $o2"
