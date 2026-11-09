# Hướng kiến trúc và phương án địa chỉ

Đây là phương án để review, chưa chọn vendor/model/simulator. `logical_options.drawio` thể hiện miền chức năng và ranh giới kết nối; chưa có interface map, không phải topology hoàn chỉnh.

Campus: cặp collapsed core phù hợp lab nhỏ và FHRP; mô hình3-tier cho thêm failure domain nhưng tăng số node. Chọn theo capacity, oversubscription và RAM thực. Không dùng một gateway chỉ vì starter vẽ vậy. LACP phải nối cùng logical switch; không ghép port channel qua hai chassis độc lập khi chưa có MLAG/stacking được hỗ trợ. Căn chỉnh STP primary/secondary với FHRP active để tránh đường vòng.

DC: hướng thiết kế hai spine và ít nhất hai leaf để thể hiện ECMP/EVPN-VXLAN, endpoint đa đường. Không kéo mọi VLAN campus qua WAN. Kiểm image hỗ trợ EVPN, route recursion và MTU; control plane UP chưa chứng minh data plane. Nếu được phép triển khai WAN IPsec trước, vẫn ghi rõ phần DC chưa đạt; IPsec không thay EVPN.

WAN: mỗi site cần đường qua hai ISP thuộc failure domain độc lập; MPLS là underlay riêng nếu bắt buộc. Edge pair, route filter, local breakout và firewall/NAT state failover cần được thiết kế. Hai ISP trên một edge vẫn còn SPOF. Controllers SD-WAN tăng RAM/license, chỉ cam kết sau capability proof. OSPF/OSPFv3 trong site, BGP ở edge với policy rõ; tránh redistribute toàn bộ hoặc default route vòng. IPsec phải kiểm MTU/MSS; MPLS không tự cung cấp confidentiality.

Security: tách Corp, Finance, R&D, IoT, Guest, Voice, Management và Services. Default deny giữa zone, mở flow đã được business owner duyệt. Guest chỉ Internet cùng DHCP/DNS chỉ định, chặn mạng nội bộ cả IPv4/IPv6. IoT chỉ telemetry/update cho phép; user không SSH management. Tính established return, ND/RA, DHCPv6 và ICMPv6 thiết yếu. DHCP snooping chỉ trust đúng uplink; DAI xử lý static binding; port security không khóa nhầm uplink.

Services: DHCP/DNS tập trung HQ nhưng cần pair/replication hoặc HA rõ. Phân tích lease còn hiệu lực và DNS cache khi branch mất WAN. WLC/CAPWAP/AP/AAA là phân hệ riêng; dựng SSID chưa chứng minh RF capacity hoặc dynamic VLAN qua802.1X. Management tách data, SSH kiểm host key, secrets ngoài Git, backup/rollback và telemetry có timestamp.

## Địa chỉ dự kiến

`plan.json` dùng10.16.0.0/16 cho HCMC,10.32.0.0/16 cho Hanoi,10.48.0.0/16 cho DaNang. Đây là private candidate, phải kiểm overlap VPN/home/lab trước triển khai. IPv6 dùng2001:db8:1000::/48 **chỉ cho tài liệu/lab**, chia /52 theo site, /56 theo zone, /64 cho LAN; production phải dùng prefix được cấp.

Giả định tương lai: user5000/3750/1250, tổng10000; IoT3000/2000/5000, tổng10000; guest peak500/site. Đây không phải khảo sát đã xác nhận. Corp pool lần lượt /19,/20,/21; IoT /20,/20,/19; Voice theo user; Guest /22/site. Management và Services mỗi loại /24; Transit và Loopback có pool riêng.

Pool là summary/reservation, **không gán cả /19 lên một SVI**. Chia thành VLAN /24; mỗi /24 tính251 endpoint sau trừ network, broadcast, hai SVI và VIP. Finance/R&D cần VLAN/subzone cụ thể; pool Corp chưa tự tạo microsegmentation. Transit chia /31 và IPv6 /127 nếu image hỗ trợ; loopback /32 và /128.

`validate_plan.py` kiểm containment, overlap, IPv6 hierarchy, capacity, tổng scale và năm negative fixtures. Chưa kiểm routing/ACL/device configs. Quyết định còn mở: nền tảng/image/license;2-tier hay3-tier; node budget cho redundancy; độ sâu EVPN/SD-WAN/WLC; ISP/IPv6 policy; flow matrix; giới hạn performance claim.
