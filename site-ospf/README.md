# Step 5 — OSPF nội site, đối chiếu IP plan origin

Nguồn địa chỉ duy nhất cho bộ này là [IP plan origin](TVI_Step2_IP_Addressing_Plan%20(origin).md) phiên bản 1.0. Không dùng `plan.json` hoặc các startup-config cũ ở thư mục gốc: chúng thuộc phương án địa chỉ `10.16/10.32/10.48` khác. Đã chuẩn bị cấu hình và lệnh kiểm tra, **chưa triển khai trên lab, chưa có bằng chứng OSPF FULL hoặc failover**.

## Phạm vi đã đồng bộ

- 7 thiết bị mang tên như bảng loopback origin: `HQ-EDGE01`, `HQ-DIST-01`, `HQ-CORE02`, `HN-EDGE01`, `HN-DIST01`, `DN-EDGE01`, `DN-DIST01`. Trong bảng transit, `CORE01` chính là vai trò của `HQ-DIST-01` theo sơ đồ interface baseline; không tự đổi hostname thành `HQ-CORE01`.
- Ba switch `HQ-ACCESS01`, `HN-ACCESS01`, `DN-ACCESS01` nằm trong `access_devices` của [manifest.json](manifest.json), với IP OOB lần lượt `192.168.250.14`, `.17`, `.20`. Theo IP plan origin, chúng không có loopback và không tham gia OSPF Step 5; các step sau có thể dùng danh sách này làm inventory OOB.
- 5 link transit IPv4 `/30` và IPv6 `/64` đúng bảng origin, đầu A `::1`, đầu B `::2`. HQ `Vlan900` chạy qua trunk LACP `Port-channel1`; không đặt IP trên Po1/member.
- Loopback IPv4 `/32` `.11/.12/.13/.15/.16/.18/.19`, router ID trùng loopback IPv4; IPv6 `/128` `2001:db8:fffe::b/::c/::d/::f/::10/::12/::13` (host cuối IPv4 biểu diễn hex).
- Ba site dùng OSPFv3 IPv4/IPv6 address families, area 0, process ID cục bộ 10/20/30. `passive-interface default`; chỉ link transit nội site được bỏ passive. Không enroll WAN/ISP, IPsec, tunnel hay OOB `192.168.250.0/24`.
- 26 SVI/prefix trong bảng VLAN origin được liệt kê trong [manifest.json](manifest.json) và enroll passive ở file OSPF của switch sở hữu: HQ hai switch theo baseline HSRP; Hanoi một DIST; Da Nang một DIST. VLAN 99 là quản trị *in-band*, không phải OOB. Guest VLAN50 được quảng bá **nội site** để EDGE có route trả về; Step 6 phải lọc Guest khỏi quảng bá liên site theo IP plan. Không thêm toàn bộ `/16` vào OSPF hoặc BGP.

## Thứ tự triển khai

1. Xác nhận đúng model/image Cisco IOS/IOS XE hỗ trợ `router ospfv3`, hai AF, lệnh interface `ospfv3 <process> area 0 ipv4/ipv6`, cost và passive. Cổng Gi0/0/Gi0/1/Gi0/2 và Po1 phải khớp thiết bị thật. Lưu `show version` và running-config trước thay đổi. Nếu image không hỗ trợ, dừng để tạo profile hợp lệ; không bỏ âm thầm AF IPv4.
2. Hanoi trước, Da Nang sau, HQ cuối. Áp `configs/<node>.01-transit.cfg` ở hai đầu; xác nhận up/up và ping IPv4/IPv6 hai chiều trước OSPF. `no switchport` trên đúng cổng routed L3, **không** trên Po1. Nếu một cổng đang mang traffic khác, cần phối hợp owner Step 3–4 trước thay đổi.
3. HQ cần Po1 đã được Step 3–4 cấu hình LACP/member (sơ đồ baseline ghi Gi0/1–2 giữa hai switch), VLAN900 allowed và forwarding. Pha 01 chỉ tạo VLAN/SVI và thêm VLAN900 vào allowed list trên Po1; không tự cấu hình member. Xác nhận `show etherchannel summary`, `show interfaces trunk`, STP và `Vlan900 up/up` trước OSPF.
4. Áp `configs/<node>.02-ospf.cfg` sau khi phase 1 đạt. Các file này có IP loopback đầy đủ, không còn placeholder. SVI user chỉ quảng bá prefix khi Step 3–4 đã tạo đúng địa chỉ/mask, IPv6 và SVI up/up. File Step 5 chỉ enroll OSPF, không gán gateway, không tạo HSRP/RA/DHCP. Không paste cả file nếu SVI tương ứng chưa được cấu hình và duyệt; tách các stanza SVI chưa sẵn sàng ra khỏi lượt áp dụng.
5. Chạy lệnh trong `verification/<node>.commands.txt` và [VERIFY.md](VERIFY.md). Chỉ lưu startup-config sau review và test đạt. Một lệnh ping hoặc show có thể khác cú pháp giữa các image; dùng `?`/extended ping và ghi lệnh thực tế, không sửa output thành công giả.

## Tệp chính

- [manifest.json](manifest.json): 7 node OSPF trong `nodes`, 3 switch ACCESS trong `access_devices`, địa chỉ OOB, 26 VLAN/SVI và owners theo baseline.
- [configs/](configs/): 14 file pha 01/02 cho 7 node; không chứa secret.
- [verification/](verification/): 7 bộ lệnh kiểm tra source ping, neighbor, route, SVI.
- [SVI.cfg.template](SVI.cfg.template): mẫu dùng nếu SVI được bàn giao sau; các SVI từ origin đã được enroll sẵn trong file pha 02.
- [validate.ps1](validate.ps1): đối chiếu offline trực tiếp origin với manifest/config; không thay kiểm chứng CLI/lab.
- [status.json](../evidence/site-ospf/status.json): trạng thái kiểm chứng thực tế.

Chạy validator từ root: `powershell -NoProfile -ExecutionPolicy Bypass -File .\site-ospf\validate.ps1`. `ExecutionPolicy Bypass` chỉ áp cho tiến trình lệnh này. Không chỉnh sửa file origin hoặc các cấu hình Step 3–4.
