param([string]$Root = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
$m = Get-Content (Join-Path $Root 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$s5 = Get-Content (Join-Path $Root '../site-ospf/manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$origin = Get-Content (Join-Path $Root $m.source) -Raw -Encoding UTF8
$script:checks = 0
function Assert($condition, $message) {
    if (-not $condition) { throw "FAIL: $message" }
    $script:checks++
}
function Has([string]$text, [string]$value) { Assert ($text.Contains($value)) "Missing: $value" }
function Config($name, $phase) { Get-Content (Join-Path $Root "configs/$name.$phase") -Raw -Encoding UTF8 }
function Mask($prefix) { if ($prefix.EndsWith('/24')) { '255.255.255.0' } elseif ($prefix.EndsWith('/20')) { '255.255.240.0' } else { throw 'Unexpected LAN mask' } }
function ExactPermits($text, $list, $expected) {
    $pattern = '(?m)^(?:ip|ipv6) prefix-list ' + [regex]::Escape($list) + ' seq \d+ permit (.+)\r?$'
    $actual = @([regex]::Matches($text,$pattern) | ForEach-Object { $_.Groups[1].Value.Trim() })
    Assert (($actual.Count -eq @($expected).Count) -and -not @(Compare-Object @($actual | Sort-Object) @($expected | Sort-Object)).Count) "Allowlist mismatch: $list"
}
$isp = Config 'ISP01' '01-underlay.cfg'
Has $origin "AS$($m.isp.asn)"
Has $isp "router bgp $($m.isp.asn)"
Has $isp "bgp router-id $($m.isp.rid)"
ExactPermits $isp 'S6-TRANSPORT4' @($m.edges.net)
foreach ($e in $m.edges) {
    $node = @($s5.nodes | Where-Object name -eq $e.name)
    Assert ($node.Count -eq 1 -and $node[0].loopback4 -eq $e.rid) "Step5 router-id $($e.name)"
    $svi = @($s5.svis | Where-Object { $_.vlan -eq $e.vlan -and $_.ipv4_prefix -eq $e.p4 -and $_.ipv6_prefix -eq $e.p6 })
    Assert ($svi.Count -eq 1) "Step5 selected SVI $($e.name)"
    foreach ($v in @($e.p4,$e.p6,"$($e.wan)/30","$($e.isp)/30",[string]$e.asn)) { Has $origin $v }
    $c = Config $e.name '01-underlay.cfg'
    Has $c "ip address $($e.wan) 255.255.255.252"
    Has $c "router bgp $($e.asn)"
    Has $c "bgp router-id $($e.rid)"
    Has $c "neighbor $($e.isp) remote-as $($m.isp.asn)"
    Has $c "neighbor $($e.isp) activate"
    Has $c "neighbor $($e.isp) prefix-list S6-DENY4 out"
    Has $c 'ip prefix-list S6-DENY4 seq 10 deny 0.0.0.0/0 le 32'
    Has $c "neighbor $($e.isp) prefix-list S6-ISP-IN4 in"
    ExactPermits $c 'S6-ISP-IN4' @($m.edges | Where-Object name -ne $e.name | ForEach-Object net)
    Has $isp "interface $($e.ispIf)"
    Has $isp "ip address $($e.isp) 255.255.255.252"
    Has $isp "neighbor $($e.wan) remote-as $($e.asn)"
    Has $isp "neighbor $($e.wan) prefix-list S6-DENY4 in"
    Has $isp "neighbor $($e.wan) prefix-list S6-TRANSPORT4 out"
    Has $isp "network $($e.net.Split('/')[0]) mask 255.255.255.252"
    Has (Config $e.name '03-overlay-v4.cfg') "network $($e.p4.Split('/')[0]) mask $(Mask $e.p4)"
    Has (Config $e.name '06-overlay-v6.cfg') "network $($e.p6)"
}
foreach ($t in $m.tunnels) {
    foreach ($v in @("$($t.hub4)/30","$($t.branch4)/30",($t.hub6 -replace '::1$','::/64'))) { Has $origin $v }
    foreach ($name in @($t.hub,$t.branch)) {
        $hub = $name -eq $t.hub
        $e = $m.edges | Where-Object name -eq $name
        $remoteName = if ($hub) { $t.branch } else { $t.hub }
        $r = $m.edges | Where-Object name -eq $remoteName
        $local4 = if ($hub) { $t.hub4 } else { $t.branch4 }
        $peer4 = if ($hub) { $t.branch4 } else { $t.hub4 }
        $local6 = if ($hub) { $t.hub6 } else { $t.branch6 }
        $peer6 = if ($hub) { $t.branch6 } else { $t.hub6 }
        $c = Config $name '02-ipsec.cfg.template'
        foreach ($v in @("interface $($t.interface)","ip address $local4 255.255.255.252","tunnel destination $($r.wan)","identity local address $($e.wan)","match identity remote address $($r.wan) 255.255.255.255","pre-shared-key local $($t.secret)","pre-shared-key remote $($t.secret)",'tunnel mode ipsec ipv4',"tunnel protection ipsec profile S6-$($t.id)-IPSEC")) { Has $c $v }
        $dual = Config $name '05-dual-overlay.cfg'
        Has $dual 'tunnel mode ipsec dual-overlay'
        Has $dual "ipv6 address $local6/64"
        foreach ($af in @(4,6)) {
            $c = Config $name "$(if ($af -eq 4) {'03'} else {'06'})-overlay-v$af.cfg"
            $peer = if ($af -eq 4) { $peer4 } else { $peer6 }
            $ownPrefix = if ($af -eq 4) { $e.p4 } else { $e.p6 }
            $remotePrefix = if ($af -eq 4) { $r.p4 } else { $r.p6 }
            Has $c "neighbor $peer remote-as $($r.asn)"
            Has $c "neighbor $peer activate"
            foreach ($direction in @('IN','OUT')) {
                $list = "S6-$($t.id)-$direction$af"
                $expected = if ($direction -eq 'IN') { $remotePrefix } else { $ownPrefix }
                ExactPermits $c $list @($expected)
                Has $c "neighbor $peer prefix-list $list $($direction.ToLower())"
            }
        }
    }
}
foreach ($g in $m.gateways) {
    $link = @($s5.links | Where-Object { $_.a.node -eq $g.edge -and $_.b.node -eq $g.name })
    Assert ($link.Count -eq 1 -and $link[0].a.ipv4 -eq $g.next4 -and $link[0].a.ipv6 -eq $g.next6 -and $link[0].b.interface -eq $g.interface) "Gateway adjacency: $($g.name)"
    foreach ($name in $g.remote) {
        $r = $m.edges | Where-Object name -eq $name
        Has (Config $g.name '04-return-v4.cfg') "ip route $($r.p4.Split('/')[0]) $(Mask $r.p4) $($g.next4)"
        Has (Config $g.name '07-return-v6.cfg') "ipv6 route $($r.p6) $($g.interface) $($g.next6)"
    }
}
foreach ($f in Get-ChildItem (Join-Path $Root 'configs') -File) {
    $text = Get-Content $f.FullName -Raw -Encoding UTF8
    Assert ($text -notmatch '(?mi)^\s*(redistribute|aggregate-address|default-information|ospfv3|router ospf|ip route 0\.0\.0\.0|ipv6 route ::/0)\b') "Scope violation $($f.Name)"
    Assert ($text -notmatch '(?mi)^.*prefix-list .* permit .* (le|ge) ') "Broad allowlist $($f.Name)"
    Assert ($text -notmatch '(?mi)^.*prefix-list .* permit .*?/16\s*$') "Aggregate permit $($f.Name)"
}
# Negative tests exercise exact-policy validation without changing files.
$negative = 0
foreach ($bad in @('10.10.0.0/16','10.10.48.0/21','192.168.250.0/24','10.10.100.0/24 le 32')) {
    $caught = $false
    try { ExactPermits "ip prefix-list TEST seq 10 permit $bad" 'TEST' @('10.10.100.0/24') } catch { $caught = $true }
    Assert $caught "Negative policy test: $bad"
    $negative++
}
[pscustomobject]@{ offline='PASS'; checks=$script:checks; negative_tests=$negative; edges=3; tunnels=2; runtime='NOT_RUN'; limitation='Static consistency only; no IOS parser or live dataplane test' } | ConvertTo-Json
