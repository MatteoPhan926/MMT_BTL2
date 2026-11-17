# TVI — Step 2 IP Addressing Plan

Phiên bản 1.0 — 15/11/2026

## Giả định thiết kế

HQ 2.200, Hanoi 1.700, Da Nang 600 người dùng. Voice dự trữ một IP/người. Guest 1.000/site. IoT tại Da Nang gồm 12 vùng, mỗi vùng 900 endpoint, tổng 10.800. Đây là giả định để nhóm duyệt. Baseline dùng cùng subnet với số host mô phỏng nhỏ hơn. Các địa chỉ minh họa trên XML được cập nhật theo bảng này.

## Khối địa chỉ

| Site | IPv4 | IPv6 | ASN |
|---|---|---|---|
| HQ | 10.10.0.0/16 | 2001:db8:10::/48 | 65001 |
| Hanoi | 10.20.0.0/16 | 2001:db8:20::/48 | 65002 |
| Da Nang | 10.30.0.0/16 | 2001:db8:30::/48 | 65003 |

IPv6 2001:db8::/32 dùng cho tài liệu và lab. Mỗi LAN /64. Subnet ID dùng chuỗi VLAN ID trong hệ hex, VLAN100 dùng :100::. Dải chưa cấp trong /16 dành cho tăng trưởng.

## VLAN, VLSM và DHCP

| Site | VLAN | Vai trò | Host dự kiến | IPv4 | Host khả dụng | Gateway | DHCP pool hoặc cấp tĩnh | IPv6 prefix |
|---|---|---|---:|---|---:|---|---|---|
| HQ | 10 | Corporate | 2200 | 10.10.16.0/20 | 4094 | 10.10.16.1 | 10.10.16.50 – 10.10.31.254 | 2001:db8:10:10::/64 |
| HQ | 40 | Voice | 2200 | 10.10.32.0/20 | 4094 | 10.10.32.1 | 10.10.32.50 – 10.10.47.254 | 2001:db8:10:40::/64 |
| HQ | 50 | Guest | 1000 | 10.10.48.0/21 | 2046 | 10.10.48.1 | 10.10.48.50 – 10.10.55.254 | 2001:db8:10:50::/64 |
| HQ | 99 | Management | 200 | 10.10.99.0/24 | 254 | 10.10.99.1 | Static inventory | 2001:db8:10:99::/64 |
| HQ | 100 | Services | 100 | 10.10.100.0/24 | 254 | 10.10.100.1 | Static inventory | 2001:db8:10:100::/64 |
| HN | 20 | Corporate | 1700 | 10.20.16.0/20 | 4094 | 10.20.16.1 | 10.20.16.50 – 10.20.31.254 | 2001:db8:20:20::/64 |
| HN | 40 | Voice | 1700 | 10.20.32.0/20 | 4094 | 10.20.32.1 | 10.20.32.50 – 10.20.47.254 | 2001:db8:20:40::/64 |
| HN | 50 | Guest | 1000 | 10.20.48.0/21 | 2046 | 10.20.48.1 | 10.20.48.50 – 10.20.55.254 | 2001:db8:20:50::/64 |
| HN | 99 | Management | 200 | 10.20.99.0/24 | 254 | 10.20.99.1 | Static inventory | 2001:db8:20:99::/64 |
| HN | 25 | Compute | 400 | 10.20.64.0/23 | 510 | 10.20.64.1 | Static inventory | 2001:db8:20:25::/64 |
| DN | 30 | Corporate | 600 | 10.30.16.0/20 | 4094 | 10.30.16.1 | 10.30.16.50 – 10.30.31.254 | 2001:db8:30:30::/64 |
| DN | 40 | Voice | 600 | 10.30.32.0/20 | 4094 | 10.30.32.1 | 10.30.32.50 – 10.30.47.254 | 2001:db8:30:40::/64 |
| DN | 50 | Guest | 1000 | 10.30.48.0/21 | 2046 | 10.30.48.1 | 10.30.48.50 – 10.30.55.254 | 2001:db8:30:50::/64 |
| DN | 99 | Management | 200 | 10.30.99.0/24 | 254 | 10.30.99.1 | Static inventory | 2001:db8:30:99::/64 |
| DN | 35 | IoT zone 1 | 900 | 10.30.128.0/22 | 1022 | 10.30.128.1 | 10.30.128.50 – 10.30.131.254 | 2001:db8:30:35::/64 |
| DN | 136 | IoT zone 2 | 900 | 10.30.132.0/22 | 1022 | 10.30.132.1 | 10.30.132.50 – 10.30.135.254 | 2001:db8:30:136::/64 |
| DN | 137 | IoT zone 3 | 900 | 10.30.136.0/22 | 1022 | 10.30.136.1 | 10.30.136.50 – 10.30.139.254 | 2001:db8:30:137::/64 |
| DN | 138 | IoT zone 4 | 900 | 10.30.140.0/22 | 1022 | 10.30.140.1 | 10.30.140.50 – 10.30.143.254 | 2001:db8:30:138::/64 |
| DN | 139 | IoT zone 5 | 900 | 10.30.144.0/22 | 1022 | 10.30.144.1 | 10.30.144.50 – 10.30.147.254 | 2001:db8:30:139::/64 |
| DN | 140 | IoT zone 6 | 900 | 10.30.148.0/22 | 1022 | 10.30.148.1 | 10.30.148.50 – 10.30.151.254 | 2001:db8:30:140::/64 |
| DN | 141 | IoT zone 7 | 900 | 10.30.152.0/22 | 1022 | 10.30.152.1 | 10.30.152.50 – 10.30.155.254 | 2001:db8:30:141::/64 |
| DN | 142 | IoT zone 8 | 900 | 10.30.156.0/22 | 1022 | 10.30.156.1 | 10.30.156.50 – 10.30.159.254 | 2001:db8:30:142::/64 |
| DN | 143 | IoT zone 9 | 900 | 10.30.160.0/22 | 1022 | 10.30.160.1 | 10.30.160.50 – 10.30.163.254 | 2001:db8:30:143::/64 |
| DN | 144 | IoT zone 10 | 900 | 10.30.164.0/22 | 1022 | 10.30.164.1 | 10.30.164.50 – 10.30.167.254 | 2001:db8:30:144::/64 |
| DN | 145 | IoT zone 11 | 900 | 10.30.168.0/22 | 1022 | 10.30.168.1 | 10.30.168.50 – 10.30.171.254 | 2001:db8:30:145::/64 |
| DN | 146 | IoT zone 12 | 900 | 10.30.172.0/22 | 1022 | 10.30.172.1 | 10.30.172.50 – 10.30.175.254 | 2001:db8:30:146::/64 |

Corporate VLANs dùng /20 để chứa quy mô và tăng trưởng. Guest /21 để có đủ 1.000 địa chỉ sau khi dành IP hạ tầng. IoT dùng VLAN35 và VLAN136–146. Cập nhật danh sách này trên topology Da Nang. Các VLAN IoT /22 nằm liên tiếp trong 10.30.128.0–10.30.175.255.

## Gateway và dịch vụ

N là network address. Target HA dùng virtual gateway N+1, thiết bị 01 dùng N+2, thiết bị 02 dùng N+3. Baseline HQ dùng HSRP, Hanoi/Da Nang dùng một SVI N+1. Dành N+1 đến N+49 cho hạ tầng và exclusions DHCP. Static inventory phải ghi từng IP đã cấp.

DHCP HQ dùng 10.10.100.10/24, DNS dùng 10.10.100.11/24, gateway 10.10.100.1. Có thể chạy hai địa chỉ trên một máy baseline. IPv6 dịch vụ là 2001:db8:10:100::10 và ::11. Relay trên SVI cần DHCP hướng tới 10.10.100.10. Scope cấp gateway theo bảng và DNS 10.10.100.11.

IPv6 gateway được công bố bằng RA. Dùng global ::1 cho gateway đơn/virtual, ::2 và ::3 cho hai SVI thật trong HA theo hỗ trợ nền tảng. Client dùng SLAAC, cung cấp DNS qua RDNSS hoặc DHCPv6 theo image/client. Không suy ra gateway IPv6 từ DHCPv6.

## Transit baseline

| Link | Cổng A | Cổng B | IPv4 A | IPv4 B | IPv6 subnet |
|---|---|---|---|---|---|
| HQ edge–core01 | EDGE Gi0/1 | CORE01 Gi0/0 | 10.10.0.1/30 | 10.10.0.2/30 | 2001:db8:10:f000::/64 |
| HQ edge–core02 | EDGE Gi0/2 | CORE02 Gi0/0 | 10.10.0.5/30 | 10.10.0.6/30 | 2001:db8:10:f001::/64 |
| HQ core transit | CORE01 Vlan900 | CORE02 Vlan900 | 10.10.0.9/30 | 10.10.0.10/30 | 2001:db8:10:f002::/64 |
| HN edge–dist | EDGE Gi0/1 | DIST Gi0/0 | 10.20.0.1/30 | 10.20.0.2/30 | 2001:db8:20:f003::/64 |
| DN edge–dist | EDGE Gi0/1 | DIST Gi0/0 | 10.30.0.1/30 | 10.30.0.2/30 | 2001:db8:30:f004::/64 |

IPv6 đầu A dùng ::1, đầu B dùng ::2. OSPFv3 chạy IPv4/IPv6 AF theo hỗ trợ image. VLAN900 đi trên Po1 giữa hai core. Cổng thành viên LACP không gán IP. User SVI đặt passive.

## WAN và overlay

| Link | Cổng A | Cổng B | IP A | IP B |
|---|---|---|---|---|
| ISP–HN | ISP Gi0/0 | HN EDGE Gi0/0 | 10.255.1.1/30 | 10.255.1.2/30 |
| ISP–HQ | ISP Gi0/1 | HQ EDGE Gi0/0 | 10.255.2.1/30 | 10.255.2.2/30 |
| ISP–DN | ISP Gi0/2 | DN EDGE Gi0/0 | 10.255.3.1/30 | 10.255.3.2/30 |
| HQ–HN | HQ Tunnel0 | HN Tunnel0 | 172.16.1.1/30 | 172.16.1.2/30 |
| HQ–DN | HQ Tunnel1 | DN Tunnel1 | 172.16.2.1/30 | 172.16.2.2/30 |

ISP baseline dùng AS65000. Endpoint IPsec dùng IP WAN của edge. Tunnel0 IPv6 dùng 2001:db8:ff00:1::/64, Tunnel1 dùng 2001:db8:ff00:2::/64. HQ ::1, chi nhánh ::2. Transport baseline dùng IPv4 và overlay mang IPv4/IPv6 theo image. eBGP overlay dùng ASN site tương ứng. Giữ route endpoint trên underlay. Chỉ quảng bá prefix nội bộ được phép, loại Guest và OOB khỏi allowlist. Không dùng aggregate /16 bao phủ Guest để thay allowlist.

## Loopbacks và OOB

| Device | Loopback /32 | OOB /24 |
|---|---|---|
| HQ-EDGE01 | 10.254.0.11 | 192.168.250.11 |
| HQ-DIST-01 | 10.254.0.12 | 192.168.250.12 |
| HQ-CORE02 | 10.254.0.13 | 192.168.250.13 |
| HQ-ACCESS01 | — | 192.168.250.14 |
| HN-EDGE01 | 10.254.0.15 | 192.168.250.15 |
| HN-DIST01 | 10.254.0.16 | 192.168.250.16 |
| HN-ACCESS01 | — | 192.168.250.17 |
| DN-EDGE01 | 10.254.0.18 | 192.168.250.18 |
| DN-DIST01 | 10.254.0.19 | 192.168.250.19 |
| DN-ACCESS01 | — | 192.168.250.20 |
| ISP01 | 10.254.0.21 | 192.168.250.21 |

Router ID dùng loopback IPv4. Loopback IPv6 dùng 2001:db8:fffe::X/128, X là chuỗi số cuối IPv4 dưới dạng hex. Quảng bá loopback trong OSPF site tương ứng. Controller OOB dùng 192.168.250.100/24. Gateway OOB nếu cần là .1. OOB IPv6 dùng 2001:db8:ffff:250::/64, host ID theo quy ước tương tự. Interface OOB dùng cổng rảnh riêng và ghi lại khi chọn image. VLAN99 in-band quản trị dùng N+11 cho switch đầu tiên, N+12 cho switch tiếp theo, WLC N+21, AP N+22.

## Dự trữ cho kiến trúc đích

- Dành 10.site.0.16–10.site.0.63 cho edge02, distribution02 và routed handoff, chia /30 theo thứ tự link trong inventory.
- Dành 10.10.1.0/24 cho spine–leaf /30 và 10.254.1.0/24 cho loopback fabric /32. IPv6 hạ tầng mở rộng dùng subnet ID f100–f1ff trong /48 site.
- ISP B AS65100 dùng 10.255.4.0/30 tới HQ, 10.255.5.0/30 tới HN, 10.255.6.0/30 tới DN. ISP nhận host đầu, edge nhận host thứ hai.
- Tunnel dự phòng HQ–HN dùng 172.16.3.0/30, HQ–DN dùng 172.16.4.0/30. HQ host đầu, chi nhánh host thứ hai. IPv6 dùng 2001:db8:ff00:3::/64 và :4::/64 theo quy ước tunnel baseline.
- Fabric dùng VLAN100/VNI10100, gateway anycast N+1 trên border leaf khi triển khai. Baseline gateway VLAN100 nằm trên core. Chốt quyền sở hữu gateway và routed handoff khi mở rộng fabric.

## Xác minh và bàn giao

Các subnet VLAN/transit baseline đã được kiểm tra không chồng lấn và đủ host sau khi dành 49 IP đầu cho hạ tầng. Các block dự trữ bao chứa subnet con có chủ đích. Gateway, DHCP, RA và routing phải kiểm thử trong lab. Bản kế hoạch chốt địa chỉ baseline, các cổng mở rộng và dự trữ được ánh xạ khi chốt node/image.

Bàn giao bảng này cho nhóm VLAN/HSRP/DHCP, Security, Routing và Automation. Cập nhật draw.io, inventory và DHCP scopes theo cùng phiên bản. Đối chiếu tên interface với image thực tế trước khi cấu hình.

Nguồn yêu cầu — Assignment 2, Step 2 và checklist IPv4/IPv6.