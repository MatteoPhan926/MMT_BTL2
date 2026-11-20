"""Compare the three corporate VLANs in Step 2 with the submitted IOS text."""
import csv
import ipaddress
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SITES = {
    "HQ": ("HQ_Startup_Configs", 10),
    "HN": ("Hanoi_Startup_Configs", 20),
    "DN": ("DaNang_Startup_Configs", 30),
}
PLAN = ROOT / "Topology/TVI_Step2_IP_Addressing_Plan (origin).md"


def sections(path, header):
    """Read top-level IOS blocks, skipping comments."""
    active = None
    for number, raw in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("!"):
            continue
        if not raw[0].isspace():
            match = re.fullmatch(header, line, re.I)
            if active is not None:
                yield active
            active = (match[1], f"{path.relative_to(ROOT)}:{number}", []) if match else None
        elif active is not None:
            active[2].append(line)
    if active is not None:
        yield active


def values(lines, prefix):
    return [line[len(prefix):] for line in lines if line.startswith(prefix)]


def networks(entries):
    return [str(ipaddress.IPv4Interface("/".join(item.split())).network) for item in entries]


def run():
    writer = csv.writer(sys.stdout, lineterminator="\n")
    writer.writerow(["site", "check", "status", "expected", "observed", "source"])
    results = []

    def check(site, title, ok, expected, actual, source):
        results.append(ok)
        writer.writerow([site, title, "PASS" if ok else "FAIL", expected, actual or "(absent)", source])

    plan = PLAN.read_text(encoding="utf-8")
    rows = list(csv.reader(plan.splitlines(), delimiter="|", skipinitialspace=True))
    dhcp = re.search(r"DHCP HQ dùng ([\d.]+)/\d+, DNS dùng ([\d.]+)/", plan)
    if not dhcp:
        raise ValueError("Không đọc được địa chỉ DHCP/DNS trong IP plan")
    dhcp_ip, dns_ip = dhcp.groups()
    configs = ROOT / "Configurations"
    pools = [pool for path in sorted((configs / SITES["HQ"][0]).glob("*.cfg"))
             for pool in sections(path, r"ip dhcp pool (\S+)")]
    for site, (folder, vlan) in SITES.items():
        matching = [row for row in rows if len(row) == 11 and row[1].strip() == site
                    and row[2].strip() == str(vlan) and row[3].strip() == "Corporate"]
        if len(matching) != 1:
            raise ValueError(f"Thiếu hoặc trùng dòng Corporate trong IP plan: {site}")
        row = [cell.strip() for cell in matching[0]]
        prefix, gateway, ipv6 = row[5], row[7], row[9]
        svis = [svi for path in sorted((configs / folder).glob("*.cfg"))
                for svi in sections(path, rf"interface Vlan\s*({vlan})")]
        if not svis:
            check(site, "Corporate SVI", False, str(vlan), "", folder)
        for _, source, lines in svis:
            nets = networks(values(lines, "ip address "))
            check(site, "SVI IPv4", prefix in nets, prefix, " ".join(nets), source)
            v6 = [str(ipaddress.IPv6Interface(i.split()[0]).network)
                  for i in values(lines, "ipv6 address ") if "/" in i]
            check(site, "SVI IPv6", ipv6 in v6, ipv6, " ".join(v6), source)
            helpers = values(lines, "ip helper-address ")
            check(site, "DHCP relay", dhcp_ip in helpers, dhcp_ip, " ".join(helpers), source)

        declared = [(net, pool) for pool in pools for net in networks(values(pool[2], "network "))]
        eligible = [pool for net, pool in declared if net == prefix]
        check(site, "Corporate DHCP scope", bool(eligible), prefix,
              ", ".join(net for net, _ in declared), str(configs.relative_to(ROOT) / SITES["HQ"][0]))
        for _, source, lines in eligible:
            routers = " ".join(values(lines, "default-router")).split()
            dns = " ".join(values(lines, "dns-server")).split()
            check(site, "DHCP gateway", gateway in routers, gateway, " ".join(routers), source)
            check(site, "DHCP DNS", dns_ip in dns, dns_ip, " ".join(dns), source)

        if site != "HQ":
            path = ROOT / f"wan-ipsec-bgp/configs/{site}-EDGE01.03-overlay-v4.cfg"
            net = ipaddress.IPv4Network(prefix)
            statement = f"network {net.network_address} mask {net.netmask}"
            advertised = [line.strip() for line in path.read_text().splitlines()
                          if line.strip().startswith("network ")]
            check(site, "BGP network statement", statement in advertised, statement,
                  " / ".join(advertised), str(path.relative_to(ROOT)))
    return 0 if all(results) else 1


if __name__ == "__main__":
    try:
        sys.exit(run())
    except (OSError, ValueError) as exc:
        sys.exit(f"Input error: {exc}")
