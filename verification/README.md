# Role 4 · Nghiệm thu mạng TechViet

Rà soát ngày 20/11/2026 trên `main` tại `2289d9a`. Nhánh `feature/role3-wan-security` tại `b07eff4` đã được merge. Đánh giá dựa vào các file đã bàn giao. Lab độc lập của từng thành viên có thể chứa thay đổi mới hơn.

## Quyết định nghiệm thu

| Phần | Đã bàn giao trên GitHub | Còn thiếu để ký nghiệm thu |
|---|---|---|
| 1 · Architecture & Routing | Sơ đồ XML, bảng VLSM/IPv6, cấu hình OSPFv3 hai address-family, eBGP underlay và overlay IPsec. Có lệnh kiểm tra cho từng node. | Cả hai file `evidence/{site-ospf,wan-ipsec-bgp}/status.json` ghi runtime `NOT_RUN`. Cần neighbor FULL, route đúng nguồn, trace hai chiều tới host Services, rồi lặp lại sau sự cố. Step 6 hiện giới hạn prefix theo site. |
| 2 · Campus & Services | Sáu startup config có VLAN, Rapid-PVST, trunk, LACP/HSRP tại HQ và HN, DHCP pool/relay, snooping và port security. | Prefix, relay, DHCP scope lệch bảng Step 2. Chưa thấy địa chỉ IPv6 trên năm SVI Corporate đã kiểm, cấu hình DAI trong sáu file, hoặc bản ghi DNS và kết quả truy vấn DNS nội bộ. DN chỉ có một gateway trong bộ file này. |
| 3 · WAN & Security | Có file .pkt và 11 ảnh. Ảnh 02 có ba phiên eBGP với ISP01. Ảnh 07 có hai IKE SA ACTIVE. Có ảnh NAT, ACL, QoS và ping hai chi nhánh. | Lab riêng dùng GRE/IKEv1 và đích /32 trên EDGE. ISP-B chưa triển khai. Chưa đo QoS khi nghẽn hoặc chứng minh chính sách cho campus IPv6. README role 3 ghi nhận receive errors ở tunnel HN khi tạo traffic DN. |
| 4 · Automation & Verification | Playbook, inventory, kiểm tra chéo cấu hình, ma trận và biểu mẫu evidence trong gói này. | Cần bản lab tích hợp hoặc console của nhóm để đo failover, thu backup trên thiết bị và điền kết quả thực nghiệm. |

Nguồn đối chiếu là `Topology/TVI_Step2_IP_Addressing_Plan (origin).md` v1.0, cũng là nguồn mà hai thư mục routing và README role 3 tham chiếu. `plan.json` ở gốc dùng dải khác. Kết quả PASS của `validate_plan.py` chỉ kiểm tra phương án bên trong file đó. Nếu nhóm chọn đổi plan, cần phát hành lại cùng phiên bản cho SVI, pool, routing, ACL, inventory và bảng test.

## Các lỗi có thể nhận diện trước khi bật lab

| Site/VLAN | Step 2 | Subnet trên SVI của role 2 | Hệ quả cần kiểm tra |
|---|---|---|---|
| HQ / 10 | 10.10.16.0/20 | 10.16.10.0/24 | ACL và NAT của lab role 3 so khớp nguồn thuộc 10.10.16.0/20. |
| HN / 20 | 10.20.16.0/20 | 10.32.20.0/24 | BGP network statement và outbound allowlist của HN chọn 10.20.16.0/20. |
| DN / 30 | 10.30.16.0/20 | 10.48.30.0/24 | Tương tự HN. Pool /24 cũng không đủ cho giả định 600 máy Corporate của Step 2. |

Năm SVI Corporate chuyển DHCP tới `10.16.99.1`. Step 2 đặt DHCP tại `10.10.100.10`, DNS tại `10.10.100.11`. Core HQ có cấu hình DHCP server, còn dòng `dns-server` chỉ báo địa chỉ DNS cho client. Dùng truy vấn bản ghi nội bộ để kiểm tra dịch vụ.

Tại HQ, hai file DIST chỉ cho VLAN 10,20,30,99 qua Po1. Step 5 cần VLAN 900 qua Po1 giữa hai gateway. Tên node và sơ đồ cổng hai phần cũng khác. Nhóm cần lập bảng ánh xạ node/cổng khi ghép topology. Trên core của role 2, route trả về VLAN 10 đi qua `10.16.99.2` và VLAN 20 qua `10.16.99.3`. Vì vậy cần đo cả luồng từ xa khi gateway chính mất, kể cả khi VIP vẫn ping được.

Trong .pkt, `10.20.16.60` và `10.30.16.60` là Loopback20/30. HQ có static route /32 tới từng địa chỉ. Bài demo liên site nên dùng client nhận lease khác hai IP này và một máy Services có ứng dụng đang chạy. Kiểm tra FIB cả hai đầu để tránh nhầm route /32 thử nghiệm với prefix học qua BGP.

## Chạy lại kiểm tra tĩnh

Từ gốc repo, chạy `python verification/audit.py`. Script dùng thư viện chuẩn và xuất CSV ra stdout. Exit 0 khi các điều kiện đều khớp và exit 1 khi phát hiện chênh lệch. Lỗi đọc input in thông báo riêng ra stderr. Kết quả của bản đã rà soát nằm ở `evidence/static.csv` với 18 dòng FAIL và 2 dòng PASS. Hai dòng PASS xác nhận network statement IPv4 tại HN và DN khớp bảng Step 2. Phạm vi gồm SVI Corporate đã khai báo, relay, pool trên thiết bị HQ và hai statement BGP. Pool khớp prefix mới được kiểm tiếp gateway và DNS. Dịch vụ DHCP ngoài switch cần có bản export scope riêng để so.

## Chạy kiểm thử tích hợp

Dùng `test-matrix.md` để chọn bài và ghi vào `evidence/runs.csv`. Hướng dẫn Step 9 nằm tại `../Automation/README.md`. Theo đề, nhóm dùng Packet Tracer cho phần nộp cần có giảng viên chấp thuận. Chưa có thông tin xác nhận trong gói đã xem. Bài cần SSH từ controller, OSPFv3 hai AF hoặc đo QoS phải ghi rõ image, feature và giới hạn của môi trường dùng để chạy.

Gợi ý demo 15 phút: phút 0–2 giới thiệu bảng IP đã thống nhất, 2–5 renew ở HN rồi truy cập dịch vụ HQ bằng IPv4/IPv6, 5–7 đối chiếu Guest và Corporate, 7–10 đo failover và khôi phục, 10–13 chạy automation, 13–15 đọc kết quả và các giới hạn đã đo. Chỉ trình bày PASS khi có bản ghi của đúng bài trên đúng topology.
