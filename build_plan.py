"""Generate a reviewable candidate, not device configuration or simulation."""
from pathlib import Path
import ipaddress
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
sites = []
for index, (name, octet, users, iot, corp_prefix, iot_prefix) in enumerate([
    ('HCMC', 16, 5000, 3000, 19, 20), ('Hanoi', 32, 3750, 2000, 20, 20),
    ('DaNang', 48, 1250, 5000, 21, 19)]):
    v6 = ipaddress.ip_network(f'2001:db8:1000:{index*4096:x}::/52')
    zones = []
    for n, (zone, start, prefix, hosts) in enumerate([
        ('Corp', 0, corp_prefix, users), ('Voice', 32, corp_prefix, users),
        ('IoT', 64, iot_prefix, iot), ('Guest', 128, 22, 500),
        ('Management', 144, 24, 100), ('Services', 145, 24, 100),
        ('Transit', 146, 24, 0), ('Loopback', 147, 24, 0)]):
        zones.append({'name': zone, 'ipv4_pool': f'10.{octet}.{start}.0/{prefix}',
            'ipv6_pool': str(list(v6.subnets(new_prefix=56))[n]),
            'endpoint_assumption': hosts,
            'allocation': 'LAN /24 and /64' if hosts else 'transit /31,/127 or loopback /32,/128'})
    sites.append({'name': name, 'ipv4_summary': f'10.{octet}.0.0/16',
                  'ipv6_summary': str(v6), 'zones': zones})
plan = {'status': 'CANDIDATE - instructor and team review required',
        'ipv6_documentation_only': True, 'ipv6_aggregate': '2001:db8:1000::/48',
        'lan_ipv4_prefix': 24, 'reserved_gateway_addresses_per_lan': 3, 'sites': sites}
(ROOT/'plan.json').write_text(json.dumps(plan, indent=2), encoding='utf-8')

# Native editable Draw.io logical diagram. Deliberately no invented interface IDs.
mxfile = ET.Element('mxfile', host='app.diagrams.net')
diagram = ET.SubElement(mxfile, 'diagram', name='Candidate functional domains')
model = ET.SubElement(diagram, 'mxGraphModel', dx='1200', dy='850', grid='1', page='1', pageWidth='1200', pageHeight='850')
root = ET.SubElement(model, 'root')
ET.SubElement(root, 'mxCell', id='0')
ET.SubElement(root, 'mxCell', id='1', parent='0')
def box(key, label, x, y, w=300, h=90, color='#dae8fc'):
    c = ET.SubElement(root,'mxCell', id=key,value=label,vertex='1',parent='1',
        style=f'rounded=1;whiteSpace=wrap;html=0;fillColor={color};fontSize=16;')
    ET.SubElement(c,'mxGeometry',x=str(x),y=str(y),width=str(w),height=str(h),attrib={'as':'geometry'})
def edge(key, a, b, label):
    c = ET.SubElement(root,'mxCell',id=key,source=a,target=b,value=label,edge='1',parent='1',
        style='edgeStyle=orthogonalEdgeStyle;endArrow=none;fontSize=13;')
    ET.SubElement(c,'mxGeometry',relative='1',attrib={'as':'geometry'})
box('title','TVI candidate: functional domains only - NOT approved wiring or running lab',40,20,1100,55,'#fff2cc')
box('wan','WAN demarcation: ISP A + ISP B + MPLS\nBGP / IPsec or SD-WAN per approved scope',330,115,540,90,'#d5e8d4')
box('hq','HCMC campus: core/gateway pair\nCorp / Voice / IoT / Guest\n10.16.0.0/16',40,290)
box('hn','Hanoi campus: gateway pair\nCorp / R&D / Voice / IoT / Guest\n10.32.0.0/16',430,290)
box('dn','Da Nang: gateway pair\nCorp / warehouse IoT / Voice / Guest\n10.48.0.0/16',820,290)
box('dc','HQ DC: spine-leaf EVPN-VXLAN\nVTEP / VRF / service zones\nImage capability proof pending',40,485,330,105)
box('svc','HQ central services with HA\nDHCP / DNS / AAA / WLC\nBranch relay and service policy',430,485,330,105)
box('mgmt','Management / automation\nSSH / backups / telemetry\nSeparate trust zone',820,485,300,105)
box('note','Every site: security boundary, dual uplinks, explicit route policies.\nLAN /24 and IPv6 /64 are allocated inside zone pools.\nModels, interface IDs, WAN addressing and node count await capability/resource review.',90,690,1010,100,'#fff2cc')
for key, a, b, label in [('a','wan','hq','redundant edge paths'),('b','wan','hn','redundant edge paths'),
 ('c','wan','dn','redundant edge paths'),('d','hq','dc','L3 / policy'),('e','hq','svc','services'),
 ('f','hn','svc','relay over routed WAN'),('g','dn','mgmt','management policy')]:
    edge(key,a,b,label)
ET.ElementTree(mxfile).write(ROOT/'logical_options.drawio',encoding='utf-8',xml_declaration=True)
print('Generated plan.json and logical_options.drawio (candidate only)')
