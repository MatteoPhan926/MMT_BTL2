# Role 3 – WAN & Security (Cisco Packet Tracer)

## 1. Tổng quan

Phần Role 3 thuộc bài tập lớn 2 – **TechViet Innovations**, tập trung triển khai và kiểm thử các chức năng mạng diện rộng (WAN) và bảo mật mạng trên Cisco Packet Tracer.

Mục tiêu là xây dựng hệ thống kết nối giữa ba chi nhánh TP. Hồ Chí Minh (HQ), Hà Nội (HN) và Đà Nẵng (DN), đồng thời kiểm tra khả năng định tuyến, chuyển đổi địa chỉ, kiểm soát truy cập, ưu tiên lưu lượng và bảo vệ dữ liệu truyền qua WAN.

Phần triển khai được xây dựng dựa trên kế hoạch địa chỉ IP của Role 1, sử dụng môi trường mô phỏng riêng để kiểm thử và không thay thế cấu hình chính thức của các thành viên khác.

## 2. Các chức năng đã triển khai

### 2.1. Kết nối WAN và định tuyến BGP

- Thiết lập kết nối IPv4 giữa ISP01 và ba router biên HQ-EDGE01, HN-EDGE01, DN-EDGE01.
- Cấu hình eBGP Underlay giữa ISP01 (AS 65000) và ba chi nhánh (AS 65001, 65002, 65003).
- Kiểm tra trạng thái các phiên BGP và khả năng học các tuyến WAN.
- Xác nhận kết nối IP giữa ba chi nhánh thông qua ISP01.

### 2.2. NAT/PAT

- Cấu hình NAT Overload (PAT) trên HQ-EDGE01.
- Cho phép mạng Corporate và Guest tại HQ truy cập địa chỉ thử nghiệm bên ngoài.
- Kiểm tra bảng chuyển đổi địa chỉ bằng `show ip nat translations` và `show ip nat statistics`.
- Loại trừ các dải mạng nội bộ khỏi chính sách NAT dành cho Corporate.

### 2.3. Bảo mật bằng Extended ACL

- Thiết lập ACL trên Gateway của VLAN Guest tại HQ.
- Cho phép Guest truy cập Gateway của chính VLAN.
- Ngăn Guest truy cập mạng Corporate và các dải mạng nội bộ không được phép.
- Kiểm tra hoạt động của ACL bằng kết quả ping và bộ đếm `match(es)`.

### 2.4. Chất lượng dịch vụ (QoS)

- Cấu hình QoS trên router HQ-EDGE01.
- Phân loại lưu lượng Voice bằng DSCP EF (46).
- Phân loại lưu lượng Corporate bằng DSCP AF21 (18).
- Cấu hình mức ưu tiên Voice 20% và băng thông bảo đảm Corporate 30%.
- Kiểm thử quá trình đánh dấu DSCP và phân loại lưu lượng ở đầu ra WAN.

### 2.5. VPN Site-to-Site

- Triển khai GRE Tunnel0 giữa HQ và Hà Nội.
- Triển khai GRE Tunnel1 giữa HQ và Đà Nẵng.
- Cấu hình IKEv1/IPsec để bảo vệ lưu lượng GRE.
- Sử dụng Crypto Map với các sequence riêng cho hai VPN.
- Kiểm tra trạng thái IKE/IPsec SA và các bộ đếm mã hóa, giải mã.
- Xác nhận khả năng liên lạc từ mạng Corporate HQ đến các địa chỉ thử nghiệm tại Hà Nội và Đà Nẵng.

## 3. Kết quả kiểm thử

| Hạng mục | Kết quả |
|---|---|
| Kết nối WAN IPv4 giữa ba chi nhánh | Đạt |
| Ba phiên eBGP với ISP01 | Established |
| NAT/PAT Corporate và Guest | Đạt |
| ACL chặn Guest truy cập Corporate | Đạt |
| QoS đánh dấu DSCP EF và AF21 | Đạt |
| Phân loại QoS trên interface WAN | Đạt |
| VPN GRE over IPsec HQ–HN | ACTIVE |
| VPN GRE over IPsec HQ–DN | ACTIVE |
| Corporate HQ truy cập địa chỉ thử nghiệm tại Hà Nội | Đạt |
| Corporate HQ truy cập địa chỉ thử nghiệm tại Đà Nẵng | Đạt |

Các kết quả được kiểm chứng thông qua lệnh CLI và các bài kiểm tra kết nối trong Cisco Packet Tracer.

## 4. Giới hạn của môi trường mô phỏng

- Cisco Packet Tracer không hỗ trợ đầy đủ cấu hình IKEv2/IPsec VTI theo thiết kế của Role 1. Vì vậy, nhóm chức năng VPN được mô phỏng bằng GRE over IKEv1/IPsec.
- Các địa chỉ đích thuộc mạng Corporate Hà Nội và Đà Nẵng được mô phỏng bằng Loopback trên router, chưa phải hệ thống Campus thực tế.
- Trong quá trình kiểm thử, bộ đếm `receive errors` của VPN HQ–HN tăng khi tạo lưu lượng qua VPN HQ–DN. Nguyên nhân chưa được xác định; cả hai VPN vẫn thiết lập SA và truyền lưu lượng thành công trong các bài thử.
- Chưa triển khai và kiểm thử cơ chế chuyển đổi dự phòng ISP-B (ISP Failover).
- Chưa thực hiện tích hợp đầy đủ với mạng Campus chính thức của Role 1 và Role 2.
- Chưa kiểm thử hiệu quả ưu tiên và bảo đảm băng thông QoS trong điều kiện nghẽn mạng.
- Chưa kiểm chứng đầy đủ các chính sách lọc tuyến BGP nâng cao do giới hạn lệnh của Packet Tracer.

## 5. Bằng chứng kiểm thử (Evidence)

Các hình ảnh kiểm thử được lưu trong thư mục `evidence/`, bao gồm:

- Sơ đồ topology của môi trường mô phỏng Role 3.
- Trạng thái các phiên eBGP.
- Kết quả NAT/PAT.
- Kiểm thử Extended ACL cho mạng Guest.
- Kết quả QoS Marking và QoS WAN.
- Trạng thái IKEv1/IPsec của hai VPN.
- Kiểm thử kết nối từ Corporate HQ đến Hà Nội và Đà Nẵng.

## 6. Lưu ý khi tích hợp với dự án nhóm

- Tuân thủ kế hoạch địa chỉ IP chính thức trong thư mục `Topology/`.
- Không ghi đè hoặc tự ý thay đổi cấu hình của Role 1 và Role 2.
- File Packet Tracer của Role 3 là môi trường kiểm thử độc lập, không thay thế cấu hình IKEv2/IPsec VTI chính thức.
- Các Loopback và Static Route dùng để thử nghiệm cần được rà soát khi tích hợp mạng Campus thực tế.
- Việc triển khai ISP dự phòng và các chức năng chưa kiểm thử cần được nhóm thống nhất trước khi tích hợp.

## 7. Hướng dẫn mở và kiểm thử

1. Mở file `Role3_WAN_Security_Integration_Tested.pkt` bằng Cisco Packet Tracer.
2. Kiểm tra trạng thái các interface trên ISP01 và ba router biên.
3. Kiểm tra định tuyến BGP bằng `show ip bgp summary`.
4. Kiểm tra NAT/PAT bằng `show ip nat translations`.
5. Kiểm tra ACL bằng `show access-lists`.
6. Kiểm tra QoS bằng `show policy-map interface`.
7. Kiểm tra VPN bằng `show crypto isakmp sa` và `show crypto ipsec sa`.
8. Thực hiện ping từ HQ-TEST-PC đến các địa chỉ thử nghiệm tại Hà Nội và Đà Nẵng.

**Lưu ý:** Các khóa chia sẻ trước (Pre-Shared Key) trong file Packet Tracer chỉ được sử dụng cho mục đích mô phỏng và không được tái sử dụng trong hệ thống thực tế.