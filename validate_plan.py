"""Offline assertions only; does not claim simulation or device automation."""
from pathlib import Path
import copy
import ipaddress as ip
import json
import time

ROOT = Path(__file__).resolve().parent
def check(plan):
    aggregate = ip.ip_network(plan['ipv6_aggregate'])
    summaries = {4: [], 6: []}
    totals = {'Corp': 0, 'IoT': 0}
    for site in plan['sites']:
        pools = {4: [], 6: []}
        for version in (4, 6):
            parent = ip.ip_network(site[f'ipv{version}_summary'])
            assert parent.version == version
            if version == 6:
                assert parent.subnet_of(aggregate)
            assert all(not parent.overlaps(n) for n in summaries[version]), 'site overlap'
            summaries[version].append(parent)
            for zone in site['zones']:
                net = ip.ip_network(zone[f'ipv{version}_pool'])
                assert net.subnet_of(parent), 'zone outside site'
                assert all(not net.overlaps(n) for n in pools[version]), 'zone overlap'
                pools[version].append(net)
                if version == 4 and zone['endpoint_assumption']:
                    assert net.prefixlen <= plan['lan_ipv4_prefix']
                    lan_count = 2**(plan['lan_ipv4_prefix']-net.prefixlen)
                    usable = 2**(32-plan['lan_ipv4_prefix'])-2-plan['reserved_gateway_addresses_per_lan']
                    assert lan_count*usable >= zone['endpoint_assumption'], 'insufficient capacity'
                if version == 6:
                    assert net.prefixlen <= 64
        for zone in site['zones']:
            if zone['name'] in totals:
                totals[zone['name']] += zone['endpoint_assumption']
    assert totals['Corp'] >= 10000 and totals['IoT'] >= 10000, 'scale not covered'
    return totals

def main():
    start = time.monotonic()
    plan = json.loads((ROOT/'plan.json').read_text())
    totals = check(plan)
    negatives = []
    for name in ('overlap', 'capacity', 'outside', 'ipv6_overlap', 'scale'):
        altered = copy.deepcopy(plan)
        zones = altered['sites'][0]['zones']
        if name == 'overlap': zones[1]['ipv4_pool'] = zones[0]['ipv4_pool']
        if name == 'capacity': zones[0]['endpoint_assumption'] = 100000
        if name == 'outside': zones[0]['ipv4_pool'] = '10.99.0.0/19'
        if name == 'ipv6_overlap': zones[1]['ipv6_pool'] = zones[0]['ipv6_pool']
        if name == 'scale': zones[0]['endpoint_assumption'] = 1
        try:
            check(altered)
        except AssertionError as error:
            negatives.append({'fixture': name, 'rejected': True, 'reason': str(error)})
        else:
            raise AssertionError(f'Invalid fixture accepted: {name}')
    result = {'status': 'PASS', 'scope': 'offline candidate only - no devices or simulator',
        'sites': len(plan['sites']), 'zones': sum(len(s['zones']) for s in plan['sites']),
        'future_endpoint_assumptions': totals, 'negative_fixtures': negatives,
        'seconds': round(time.monotonic()-start,4)}
    (ROOT/'evidence/plan_validation.json').write_text(json.dumps(result, indent=2),encoding='utf-8')
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
