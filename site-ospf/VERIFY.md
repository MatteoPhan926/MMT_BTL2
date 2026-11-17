# Kiểm chứng Step 5 trên lab — chưa có kết quả thực tế

Nguồn địa chỉ là [IP plan origin](../../TVI_Step2_IP_Addressing_Plan%20(origin).md); [manifest](manifest.json) và [trạng thái](../evidence/site-ospf/status.json). Thu console output thô có hostname, thời gian, image/version, không tạo log giả. Tách evidence `before-ospf`, `baseline`, `failure`, `restored` và ghi chính xác các lệnh đã chạy.

## A. Trước khi bật OSPF

Trên cả hai đầu mỗi link: `show ip interface brief`, `show ipv6 interface brief`, `show interfaces <link>`, ping IPv4 có source IP interface và IPv6 có source interface. IPv6 link-local cần tồn tại. HQ: kiểm `show etherchannel summary`, `show interfaces trunk`, `show spanning-tree vlan 900`, `show interfaces vlan 900`; Po1 phải bundled, VLAN900 forwarding, SVI up/up. Nếu ping transit không đạt, dừng ở pha 01.

## B. Sau khi bật OSPFv3 hai AF

| Site | Thiết bị | FULL neighbors / AF |
|---|---|---:|
| HQ | HQ-EDGE01, HQ-DIST-01, HQ-CORE02 | 2 mỗi node; 3 cặp duy nhất |
| Hanoi | HN-EDGE01, HN-DIST01 | 1 mỗi node; 1 cặp |
| Da Nang | DN-EDGE01, DN-DIST01 | 1 mỗi node; 1 cặp |

`show ospfv3 neighbor`/`show ospfv3 interface` phải xác nhận đúng AF, area 0, point-to-point, cost 10 và passive đúng chỗ. Kiểm `show running-config` để không có OSPF trên ISP/WAN Gi0/0, tunnel, OOB. VLAN99 là in-band nên có thể passive, còn `192.168.250.0/24` và `2001:db8:ffff:250::/64` không tham gia.

Từng node phải học loopback *các node khác cùng site* bằng OSPF: IPv4 `/32`, IPv6 `/128`; loopback chính node là local/connected. Tất cả giá trị cụ thể đã nằm trong 7 file `verification/*.commands.txt`, không còn placeholder. EDGE phải học các SVI nội site đã thực sự up/up, đúng prefix từ origin: HQ 5 VLAN, Hanoi 5 VLAN, Da Nang 16 VLAN. VLAN50 Guest chỉ quảng bá nội site, không xuất qua WAN Step 6. Nếu SVI chưa được dựng ở Step 3–4, ghi NOT_VERIFIED cho prefix đó; không gán PASS vì nó có trong config.

Ping hai chiều với `source Loopback0`: HQ 6 hướng, Hanoi 2, Da Nang 2 = 10 hướng mỗi AF, 20 thử nghiệm tổng. Baseline sau hội tụ cần reply 20/20 trên mỗi hướng. Xem route chiều về và ACL nếu ping một chiều. Ping transit không thay ping loopback. Nếu CLI không nhận ping một dòng, dùng extended ping với source tương ứng và ghi transcript.

## C. Failover HQ

1. Baseline: từ HQ-EDGE01 route tới `10.254.0.12/32` đi trực tiếp `GigabitEthernet0/1`/`10.10.0.2`; IPv6 tới `2001:db8:fffe::c/128` cũng đi trực tiếp. HQ-DIST-01 ↔ HQ-CORE02 qua Vlan900 đang FULL hai AF. Không có static route ưu tiên hơn.
2. Chạy probe liên tục từ HQ-EDGE01 có `source Loopback0` tới hai loopback trên (hai console/luồng nếu có thể). Ghi timestamp của probe, không chỉ đếm dấu chấm ping.
3. Tại HQ-EDGE01: `show clock`, `configure terminal`, `interface GigabitEthernet0/1`, `shutdown`, `end`; ghi T0.
4. Kiểm route từ EDGE sang `10.254.0.12` đổi qua `10.10.0.6`/Gi0/2. Tại HQ-CORE02 route sang loopback HQ-DIST-01 qua `10.10.0.9`/Vlan900. IPv6 có thể hiển thị next-hop link-local; xác nhận theo egress interface và router ID. Capture neighbor và traceroute, nhưng không dùng traceroute làm bằng chứng duy nhất.
5. Ghi T1 lúc probe ổn định trở lại, số gói mất, chu kỳ probe và độ phân giải thời gian. T1−T0 là gián đoạn quan sát được; không suy uptime hay SPF thuần. Thực hiện riêng IPv4/IPv6 nếu không đo đồng thời được.
6. **Luôn khôi phục dù test thất bại:** trên EDGE `configure terminal`, `interface GigabitEthernet0/1`, `no shutdown`, `end`. Kiểm 3 cặp HQ trở lại FULL cả hai AF, route trực tiếp phục hồi, source ping đạt; chỉ khi đó mới lưu cấu hình.

Đây là test mất link, không chứng minh failover cả node, LACP member, WAN, dual ISP hoặc 99.99% uptime.

## D. Khắc phục và kết luận

Không up/up: đối chiếu port map/routed port/Po1/STP. Không neighbor: kiểm IPv6 link-local, AF, area, passive, ACL protocol 89, MTU, Hello/dead, router ID. FULL nhưng thiếu route: kiểm SVI up/up, enrollment cả hai AF và RIB có static/connected ưu tiên không. Failover không chuyển: kiểm Vlan900, cost, route tại CORE02 và route trả về. Không bỏ qua lỗi lệnh của image. Rollback dựa trên running-config backup, gỡ chỉ các dòng OSPF/cổng đã thêm và không xóa VLAN/HSRP do nhóm khác sở hữu.

Chỉ ghi PASS khi có raw output cho platform, ping transit trước OSPF, FULL đúng số lượng hai AF, route loopback/đủ SVI, 20 source-ping, failover HQ và restoration. Cập nhật [status.json](../evidence/site-ospf/status.json) kèm đường dẫn evidence thô; validator offline không thay các bằng chứng này.
