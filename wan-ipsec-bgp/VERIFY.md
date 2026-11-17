# Nghiệm thu Step 6
Mọi kết quả dưới đây là **kỳ vọng**, không phải kết quả đã đo. Dùng các lệnh trong [verification](./verification) theo từng gate; điều chỉnh cú pháp show theo image, không bỏ qua lỗi.

## Gate 0 — Prerequisites
Ghi show version, interface mapping, thời gian chạy. Kiểm tra Step 5 FULL và exact route LAN IPv4/IPv6 trên edge. SVI phải up/up, gateway/HSRP/RA và host thực sự hoạt động. Lưu backup riêng có bảo vệ bí mật.

## Gate 1 — Underlay
Ping peer ISP rồi WAN chi nhánh từ địa chỉ WAN HQ và chiều ngược lại. ISP có 3 peer Established; mỗi edge có 1 peer ISP trước overlay. Sau overlay, route endpoint WAN vẫn qua ISP, tuyệt đối không qua tunnel.
Kiểm tra ISP chỉ có ba subnet transport trong advertised-routes; edge advertised-routes về ISP rỗng. Không có prefix doanh nghiệp/Guest/OOB học từ edge trên ISP.

## Gate 2 — IPsec
Chụp show crypto ipsec sa trước ping, ping hai chiều giữa IP tunnel, chụp lại sau ping. Cả encaps/encrypt và decaps/decrypt phải tăng ở đúng peer; ghi số trước/sau và lỗi. IKEv2 SA phải established/READY theo image. Tunnel up/up hoặc cấu hình hiện diện không đủ chứng minh mã hóa. Có thể capture ISP để xác nhận ESP/NAT-T, không thấy payload doanh nghiệp plaintext.

## Gate 3 — Overlay
Sau IPv4: HQ có 3 phiên (ISP + HN + DN), mỗi nhánh 2 (ISP + HQ), ISP 3.
Mỗi peer overlay nhận đúng 1 prefix: HQ nhận HN /20 và DN /20 từ đúng peer; mỗi nhánh chỉ nhận HQ /24. Next-hop LAN xa là IP tunnel. Không có default, Guest, OOB hoặc /16 trên overlay.
Sau IPv6: HQ có 2 peer IPv6, mỗi nhánh 1; mỗi peer nhận đúng 1 /64. Underlay vẫn IPv4. Kiểm tra route IPv6 next-hop tunnel và counters IPsec sau ping IPv6; kiểm thử lại IPv4 sau đổi mode.

## Gate 4 — Host end-to-end
HN dùng một PC VLAN20, ví dụ 10.20.16.50/20 gateway 10.20.16.1; DN dùng 10.30.16.50/20 gateway 10.30.16.1. Xác nhận DHCP/cấp phát không trùng IP trước khi dùng ví dụ.
Server HQ 10.10.100.10/24 gateway 10.10.100.1. Ping và traceroute/tracert từ CẢ HAI PC tới server, rồi kiểm tra chiều ngược lại. Lưu IP/mask/default route của host cùng kết quả.
IPv6: dùng địa chỉ thực nhận trên PC qua SLAAC/RA; ping 2001:db8:10:100::10 rồi chiều về tới địa chỉ PC. Không giả định gateway IPv6 do DHCPv6 cấp.
Đo thêm gói lớn/PMTUD; ping nhỏ không chứng minh mọi ứng dụng chạy. Nếu fail: kiểm tra host firewall, VLAN, gateway, exact route edge, static route gateway, ACL/NAT, SA counters hai chiều.
Không dùng ping nguồn WAN/loopback edge tới server để thay thế host test: những prefix đó không nằm trong allowlist overlay.

## Ghi bằng chứng
Lưu output đã che bí mật dưới evidence/wan-ipsec-bgp/raw/<thoi-gian>/<node>-<gate>.txt. Ghi lệnh, thời gian, image, source/destination, expected/actual, PASS/FAIL và trước/sau counters. Không lưu running config chứa PSK vào bằng chứng.
Chỉ cập nhật runtime PASS khi có output chứng minh; phase chưa chạy giữ NOT_RUN/NOT_VERIFIED. Kiểm tra lại Step 5 neighbor/loopback sau khi triển khai.

