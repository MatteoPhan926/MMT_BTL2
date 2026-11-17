# Step 6 — WAN, eBGP và IPsec
Nguồn chuẩn: [IP plan origin](../../TVI_Step2_IP_Addressing_Plan%20(origin).md), [OSPF nội site](../site-ospf/README.md). Không sửa bản origin hoặc cấu hình OSPF hiện có.

## Phạm vi và trạng thái
Đã tạo cấu hình offline; **chưa triển khai lên thiết bị, chưa chứng minh Established hoặc mã hóa**. Chọn phương án IPsec, không triển khai iBGP/EVPN. Baseline có một ISP01 AS65000; ISP B và tunnel dự phòng vẫn là phần dự trữ, chưa đáp ứng yêu cầu hai ISP nếu rubric bắt buộc.
HQ-DIST-01 là vai trò CORE01 trong bảng transit. VLAN20 HN và VLAN30 DN được origin gọi Corporate; Engineering/Logistics là tên ca thử, không phải subnet mới.

## Trình tự áp dụng
Các file trong [configs](./configs) là delta cho baseline sạch, không phải migration tự động. Sao lưu running/startup config riêng, kiểm tra tên cổng và cấu hình BGP/crypto đang tồn tại. Không dán toàn bộ thư mục cùng lúc; dừng nếu CLI báo lỗi. Không tự lưu startup trước khi nghiệm thu.

1. Xác nhận Step 3–4 có VLAN/trunk/SVI, HSRP HQ, gateway và RA hoạt động. Step 5 phải FULL và edge học đúng prefix LAN: HQ 10.10.100.0/24; HN 10.20.16.0/20; DN 10.30.16.0/20, cùng các /64 tương ứng. Chỉ enrollment SVI vào OSPF chưa tạo IP/gateway cho SVI.
2. Áp dụng **01-underlay** trên ISP01 và ba edge. Kiểm tra WAN và phiên eBGP. ISP chỉ phát ba /30 transport; edge không phát gì về ISP. Không bỏ bộ lọc OUT khi thêm network overlay.
3. Sao chép **02-ipsec.cfg.template** vào thư mục local private, thay token PSK bằng khóa lab mạnh: HQ–HN dùng cùng một khóa ở hai đầu, HQ–DN dùng một khóa riêng. Không dán token nguyên văn; không commit hoặc đưa khóa vào bằng chứng. Áp dụng HQ–HN trước, kiểm thử, rồi HQ–DN.
4. Áp dụng **03-overlay-v4**, sau đó **04-return-v4** trên các gateway. Network BGP cần route có đúng mask trong RIB từ Step 5; không thêm Null0 để làm giả điều kiện này.
5. Kiểm tra từ host theo [VERIFY](./VERIFY.md), không chỉ ping giữa các edge.
6. Dual-stack: chỉ khi image xác nhận hỗ trợ, áp dụng **05-dual-overlay** ở cả hai đầu trong cửa sổ bảo trì, sau đó **06-overlay-v6** và **07-return-v6**. Nâng cấp mode ngắt tunnel tạm thời; kiểm tra lại cả IPv4 và IPv6.

## Điều kiện nền tảng và bảo mật
Cần image có IKEv2, VTI, BGP và OSPFv3 IPv4/IPv6 AF phù hợp. Lấy show version và kiểm tra license/CLI trước. Cho phép IKE UDP500, NAT-T UDP4500 khi sử dụng, ESP giữa đúng endpoint; baseline không cấu hình NAT. Rà ACL/NAT hiện có, không xóa chính sách khác.
MTU1400/MSS IPv4 1360, IPv6 1340 là baseline, cần kiểm tra PMTUD với gói lớn.

IPv6 dùng mode ipsec dual-overlay (lệnh được Cisco giới thiệu ở IOS XE 17.9.1a, còn phụ thuộc platform). Không giả định mode ipsec ipv4 mang được cả hai họ địa chỉ chỉ vì thêm IPv6 vào interface. Nếu không hỗ trợ, giữ IPv6 NOT_VERIFIED và chọn thiết kế tương thích sau khi xác nhận image.
Nguồn: [Cisco tunnel mode ipsec dual-overlay](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/security/s1/sec-s1-cr-book/sec-cr-t2.html).

## Giới hạn cố ý
- Overlay chỉ HQ Services ↔ HN VLAN20 và HQ Services ↔ DN VLAN30; không branch-to-branch, không Guest/OOB, không aggregate /16.
- Prefix-list lọc route, không thay ACL/firewall lọc nguồn và dịch vụ. Chưa chứng minh phân vùng bảo mật hoặc toàn bộ DHCP relay các VLAN.
- Route tĩnh chiều về có trên cả hai core HQ nhưng không có tracking/floating backup; không tuyên bố failover WAN hoặc mất link edge-core vẫn thông suốt.
- Không đưa WAN/tunnel vào OSPF, không redistribute BGP vào OSPF, không thay đổi loopback/transit Step 5.

## Rollback và kiểm tra offline
Rollback từng phase theo diff với backup: gỡ đúng neighbor overlay/prefix-list/route tĩnh mới; khi quay về IPv4, shutdown tunnel, gỡ protection, đổi mode ipsec ipv4, gắn lại protection và no shutdown ở cả hai đầu. Gỡ AF6/địa chỉ IPv6 nếu đã thêm. Không dùng no router bgp hoặc xóa crypto dùng chung để rollback một tunnel. Khôi phục giá trị cũ thay vì xóa nếu đối tượng đã tồn tại.

Chạy từ gốc dự án:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\site-ospf\validate.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\wan-ipsec-bgp\validate.ps1
```
Validator kiểm tra tĩnh, không mô phỏng IOS hoặc kiểm chứng data plane. [Trạng thái](../evidence/wan-ipsec-bgp/status.json) giữ riêng bằng chứng runtime.

