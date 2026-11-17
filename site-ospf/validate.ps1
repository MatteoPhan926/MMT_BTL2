param(
    [string]$Root = $PSScriptRoot,
    [string]$Origin = ''
)
$ErrorActionPreference = 'Stop'
if (-not $Origin) { $Origin = Join-Path (Split-Path -Parent (Split-Path -Parent $Root)) 'TVI_Step2_IP_Addressing_Plan (origin).md' }
function Check([bool]$Ok, [string]$Message) { if (-not $Ok) { throw $Message } }
function Cells([string]$Line) { return @(($Line -split '\|') | ForEach-Object { $_.Trim() }) }
function V4([string]$Address) {
    $b = [Net.IPAddress]::Parse($Address).GetAddressBytes()
    Check ($b.Length -eq 4) "Invalid IPv4: $Address"
    return ([long]$b[0]*16777216 + [long]$b[1]*65536 + [long]$b[2]*256 + $b[3])
}
Check (Test-Path -LiteralPath $Origin) "Origin file missing: $Origin"
$source = Get-Content -LiteralPath $Origin -Encoding UTF8
$plan = Get-Content -LiteralPath (Join-Path $Root 'manifest.json') -Encoding UTF8 -Raw | ConvertFrom-Json
Check ($plan.nodes.Count -eq 7 -and $plan.links.Count -eq 5) 'Expected seven nodes and five links'
Check ($plan.access_devices.Count -eq 3) 'Expected three OOB-only ACCESS devices'
Check ($plan.svis.Count -eq 26) 'Expected 26 SVI allocations from origin'
Check ($plan.area -eq 0) 'Area must be 0'
$names = @{}
$addresses = @{}
$ports = @{}
foreach ($n in $plan.nodes) {
    Check (-not $names.ContainsKey($n.name)) "Duplicate node $($n.name)"
    $names[$n.name] = $n
    $row = @($source | Where-Object { $_ -match ('^\| ' + [regex]::Escape($n.name) + ' \|') })
    Check ($row.Count -eq 1) "Origin loopback row missing/ambiguous: $($n.name)"
    $c = Cells $row[0]
    Check ($n.loopback4 -eq $c[2] -and $n.oob4 -eq $c[3]) "Loopback/OOB mismatch for $($n.name)"
    $last = [int](($n.loopback4 -split '\.')[-1])
    $v6 = '2001:db8:fffe::{0:x}' -f $last
    Check ($n.loopback6 -eq $v6) "IPv6 loopback hex mismatch for $($n.name)"
    foreach ($a in @($n.loopback4,$n.loopback6,$n.oob4)) {
        Check (-not $addresses.ContainsKey($a)) "Duplicate address: $a"
        $addresses[$a] = $true
    }
    Check ($n.process -eq @{HQ=10;Hanoi=20;DaNang=30}[$n.site]) "Process/site mismatch: $($n.name)"
}
$accessRows = @($source | Where-Object { $_ -match '^\| (HQ|HN|DN)-ACCESS01 \|' })
Check ($accessRows.Count -eq 3) 'Origin ACCESS inventory changed: review source'
foreach ($row in $accessRows) {
    $c = Cells $row
    $device = @($plan.access_devices | Where-Object { $_.name -eq $c[1] })
    Check ($device.Count -eq 1) "ACCESS absent/duplicate in manifest: $($c[1])"
    $d = $device[0]
    $site = @{HQ='HQ';HN='Hanoi';DN='DaNang'}[($c[1] -split '-')[0]]
    Check ($d.site -eq $site -and $c[2] -eq [string][char]0x2014 -and $null -eq $d.loopback4 -and $d.oob4 -eq $c[3]) "ACCESS loopback/OOB mismatch: $($c[1])"
    Check (-not $names.ContainsKey($d.name)) "ACCESS incorrectly included in OSPF nodes: $($d.name)"
    Check (-not $addresses.ContainsKey($d.oob4)) "Duplicate OOB address: $($d.oob4)"
    $addresses[$d.oob4] = $true
}
$svRows = @($source | Where-Object { $_ -match '^\| (HQ|HN|DN) \| [0-9]+ \|' })
Check ($svRows.Count -eq 26) 'Origin SVI table changed: review source'
foreach ($row in $svRows) {
    $c = Cells $row
    $site = @{HQ='HQ';HN='Hanoi';DN='DaNang'}[$c[1]]
    $vlan = [int]$c[2]
    $item = @($plan.svis | Where-Object { $_.site -eq $site -and $_.vlan -eq $vlan })
    Check ($item.Count -eq 1) "SVI allocation absent/duplicate: $site VLAN$vlan"
    $s = $item[0]
    Check ($s.ipv4_prefix -eq $c[5] -and $s.gateway4 -eq $c[7] -and $s.ipv6_prefix -eq $c[9]) "SVI address mismatch: $site VLAN$vlan"
    foreach ($owner in $s.owners) {
        Check ($names.ContainsKey($owner)) "Unknown SVI owner: $owner"
        Check ($names[$owner].site -eq $site) "Cross-site SVI owner: $owner"
        Check (@($names[$owner].passive_svis | Where-Object { $_ -eq "Vlan$vlan" }).Count -eq 1) "SVI missing in owner manifest: $owner Vlan$vlan"
    }
}
$transitRows = @($source | Where-Object { $_ -match '^\| (HQ|HN|DN) (edge|core)' })
Check ($transitRows.Count -eq 5) 'Origin transit table changed: review source'
$networks = @{}
for ($i=0; $i -lt $plan.links.Count; $i++) {
    $l = $plan.links[$i]
    $c = Cells $transitRows[$i]
    Check ($l.ipv4_prefix_length -eq 30) "Transit not /30: $($l.id)"
    Check ($l.a.ipv4 -eq (($c[4] -split '/')[0]) -and $l.b.ipv4 -eq (($c[5] -split '/')[0])) "Transit IPv4 mismatch: $($l.id)"
    Check ($l.ipv6_prefix -eq $c[6]) "Transit IPv6 mismatch: $($l.id)"
    Check ($c[2].EndsWith(($l.a.interface -replace '^GigabitEthernet','Gi' -replace '^Vlan','Vlan')) -and $c[3].EndsWith(($l.b.interface -replace '^GigabitEthernet','Gi' -replace '^Vlan','Vlan'))) "Transit interface mismatch: $($l.id)"
    $a = V4 $l.a.ipv4; $b = V4 $l.b.ipv4
    Check (($a -band 4294967292L) -eq ($b -band 4294967292L) -and $a%4 -eq 1 -and $b%4 -eq 2) "Invalid /30 pair: $($l.id)"
    $net4 = [string]($a -band 4294967292L)
    Check (-not $networks.ContainsKey($net4)) "Repeated /30: $($l.id)"
    $networks[$net4] = $true
    $prefix = [Net.IPAddress]::Parse(($l.ipv6_prefix -split '/')[0]).GetAddressBytes()
    $net6 = [BitConverter]::ToString($prefix,0,8)
    Check (-not $networks.ContainsKey($net6)) "Repeated IPv6 /64: $($l.id)"
    $networks[$net6] = $true
    $endIndex = 0
    foreach ($e in @($l.a,$l.b)) {
        $endIndex++
        Check ($names.ContainsKey($e.node) -and $names[$e.node].site -eq $l.site) "Cross-site/unknown endpoint: $($e.node)"
        $portKey = "$($e.node)/$($e.interface)"
        Check (-not $ports.ContainsKey($portKey)) "Duplicate interface: $portKey"
        $ports[$portKey] = $true
        $ip6 = [Net.IPAddress]::Parse($e.ipv6).GetAddressBytes()
        Check ([BitConverter]::ToString($ip6,0,8) -eq $net6 -and @($ip6[8..14] | Where-Object { $_ -ne 0 }).Count -eq 0 -and $ip6[15] -eq $endIndex) "Wrong ::1/::2: $($e.ipv6)"
        foreach ($address in @($e.ipv4,$e.ipv6)) {
            Check (-not $addresses.ContainsKey($address)) "Duplicate address: $address"
            $addresses[$address] = $true
        }
        $phase1 = Get-Content -LiteralPath (Join-Path $Root "configs/$($e.node).01-transit.cfg") -Raw
        Check ($phase1.Contains("ip address $($e.ipv4) 255.255.255.252") -and $phase1.Contains("ipv6 address $($e.ipv6)/64")) "Phase 1 address mismatch: $($e.node)"
        Check ($phase1.Contains("interface $($e.interface)")) "Phase 1 interface missing: $portKey"
        Check ($phase1 -notmatch '(?m)^\s*(router ospf|ospfv3 |ipv6 ospf)') 'OSPF enabled before transit test'
    }
}
foreach ($n in $plan.nodes) {
    $cfg = Get-Content -LiteralPath (Join-Path $Root "configs/$($n.name).02-ospf.cfg") -Raw
    Check ($cfg -notmatch '\{\{' -and $cfg.Contains("router-id $($n.loopback4)")) "Unresolved/mismatched OSPF config: $($n.name)"
    Check ($cfg.Contains("ip address $($n.loopback4) 255.255.255.255") -and $cfg.Contains("ipv6 address $($n.loopback6)/128")) "Loopback config mismatch: $($n.name)"
    Check (@([regex]::Matches($cfg,'(?m)^\s*passive-interface default\s*$')).Count -eq 2) "Passive default missing: $($n.name)"
    $active = @([regex]::Matches($cfg,'(?m)^\s*no passive-interface (\S+)') | ForEach-Object { $_.Groups[1].Value })
    Check ($active.Count -eq 2*$n.active.Count) "Active interface count mismatch: $($n.name)"
    foreach ($iface in $n.active) {
        Check ($ports.ContainsKey("$($n.name)/$iface")) "Active interface is not transit: $($n.name)/$iface"
        Check (@($active | Where-Object { $_ -eq $iface }).Count -eq 2) "Not active in both AFs: $($n.name)/$iface"
    }
    foreach ($iface in @('Loopback0') + @($n.active) + @($n.passive_svis)) {
        $blocks = @([regex]::Matches($cfg,'(?ms)^interface ' + [regex]::Escape($iface) + '\r?\n(?<body>.*?)^exit\s*$'))
        Check ($blocks.Count -ge 1) "Missing interface: $($n.name)/$iface"
        $enrolledBlocks = @($blocks | Where-Object { $_.Groups['body'].Value.Contains("ospfv3 $($n.process) area 0 ipv4") -and $_.Groups['body'].Value.Contains("ospfv3 $($n.process) area 0 ipv6") })
        Check ($enrolledBlocks.Count -eq 1) "Missing/duplicate AF: $($n.name)/$iface"
    }
    $enrollment = @([regex]::Matches($cfg,'(?m)^\s*ospfv3 (\d+) area (\d+) (ipv[46])\s*$'))
    Check ($enrollment.Count -eq 2*(1+$n.active.Count+$n.passive_svis.Count)) "Enrollment count mismatch: $($n.name)"
    Check (@([regex]::Matches($cfg,'(?m)^\s*ospfv3 cost 10\s*$')).Count -eq $n.active.Count) "Transit cost mismatch: $($n.name)"
    Check ($cfg -notmatch '(?m)^\s*(redistribute|default-information|network |no passive-interface (Tunnel|Vlan(?!900)))' ) "Forbidden OSPF export/interface: $($n.name)"
    Check ($cfg -notmatch '192\.168\.250|2001:db8:ffff:250|10\.255\.|172\.16\.') "WAN/OOB appears in OSPF config: $($n.name)"
    $verificationPath = Join-Path $Root "verification/$($n.name).commands.txt"
    Check (Test-Path -LiteralPath $verificationPath) "Missing verification commands: $($n.name)"
    $verification = Get-Content -LiteralPath $verificationPath -Raw
    foreach ($peer in @($plan.nodes | Where-Object { $_.site -eq $n.site -and $_.name -ne $n.name })) {
        Check ($verification.Contains("ping $($peer.loopback4) source Loopback0") -and $verification.Contains("ping ipv6 $($peer.loopback6) source Loopback0")) "Source ping missing: $($n.name) -> $($peer.name)"
    }
    if ($n.name -match 'EDGE') {
        foreach ($s in @($plan.svis | Where-Object { $_.site -eq $n.site })) {
            $v4 = $s.ipv4_prefix -split '/'
            $bits = [int]$v4[1]
            $mask = @(0..3 | ForEach-Object { $v = [Math]::Max(0,[Math]::Min(8,$bits-8*$_)); if ($v -eq 0) { 0 } else { 256-[Math]::Pow(2,8-$v) } }) -join '.'
            Check ($verification.Contains("show ip route $($v4[0]) $mask") -and $verification.Contains("show ipv6 route $($s.ipv6_prefix)")) "SVI route check missing: $($n.name) Vlan$($s.vlan)"
        }
    }
}
foreach ($site in @('HQ','Hanoi','DaNang')) {
    Check (@($plan.links | Where-Object { $_.site -eq $site }).Count -eq $plan.expected_unique_adjacencies_per_af.$site) "Adjacency count mismatch: $site"
}
$visited = @{'HQ-EDGE01'=$true}
do {
    $oldCount = $visited.Count
    foreach ($l in @($plan.links | Where-Object { $_.site -eq 'HQ' -and $_.id -ne 'HQ-E-D' })) {
        if ($visited.ContainsKey($l.a.node)) { $visited[$l.b.node] = $true }
        if ($visited.ContainsKey($l.b.node)) { $visited[$l.a.node] = $true }
    }
} while ($visited.Count -gt $oldCount)
Check ($visited.ContainsKey('HQ-DIST-01')) 'No designed HQ backup path'
[pscustomobject]@{
    source = $Origin
    offline_alignment = 'PASS'
    scope = 'Origin tables, config values and design graph only; no simulator or CLI execution'
    nodes = $plan.nodes.Count
    access_devices = $plan.access_devices.Count
    links_per_AF = $plan.links.Count
    svi_allocations = $plan.svis.Count
    unresolved_address_placeholders = 0
    runtime = 'NOT_RUN'
} | ConvertTo-Json -Depth 4
