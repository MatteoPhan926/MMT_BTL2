# Yêu cầu - bằng chứng - điều kiện nghiệm thu

Mọi yêu cầu runtime dưới đây hiện **CHƯA KIỂM CHỨNG**, không bị loại vì máy thiếu tài nguyên. Preparation đã có phân tích, candidate IP và validator; chưa có mô phỏng.

| ID / nguồn PDF | Yêu cầu | Bằng chứng cần tạo |
|---|---|---|
| R01 p1-2 | HQ HCMC 2000+, Hanoi1500+, DaNang500+; 4000+ user,10000+ IoT, guest;10000+ user2030 | Capacity/IP hierarchy; đại diện từng trust zone trong lab; không giả10000 host được chạy |
| R02 p2 | HQ10/40Gbps,99.99% uptime | Tính năng/capacity thiết bị thiết kế, failure-domain analysis, RTO đo; không suy throughput/availability từ ping trong VM |
| R03 p2 | Spine-leaf EVPN-VXLAN DC | Underlay/overlay routes, VTEP/EVPN tables, encapsulation và host reachability; cần chốt độ sâu bắt buộc |
| R04 p2-3 | SD-WAN,dual ISP+MPLS,branch cloud breakout; BGP/IPsec | Route policy, isolation/crypto proof, tunnel counters, mấtISP không blackhole; IPsec không tự bằng đầy đủ SD-WAN |
| R05 p2-3,23 | Campus collapsed-core/3-tier, dynamicVLAN,802.1Q,STP,LACP | Logical/physical Draw.io; trunk allowedlists,STP root/backup,LACP memberfailure; dynamic assignment cần AAA/image capability |
| R06 p3,23 | FHRP gateway redundancy;HQ DHCP/DNS,branch relay | VIP ownership,lease renew từ branch,DNS query,core/gatewayfailover; loại SPOF dịch vụ |
| R07 p2-4 | IPv4 VLSM,IPv6 hierarchy,OSPFv3/OSPF,MP-BGP | Nooverlap/capacity; dualstack loopback/endpoint reachability; OSPF adjacency và BGP policy,default/summaries |
| R08 p2-4,23 | IoT/Guest/Corp isolation,NGFW/microseg,portsecurity,DHCPsnooping,DAI,zoneFW,ZTNA/SASE | Positive/negative matrix cảIPv4/IPv6,rogueDHCP/ARP lab cô lập,management denied; phân biệt concepts với implementation |
| R09 p3,4,23 | Voice priority tất cảWAN,video,data | DSCP EF/AF31, counters và concurrent saturated best-effort; latency/jitter/loss đo riêng; ping đơn lẻ không đủ |
| R10 p2-3 | WLC/CAPWAP,Wi-Fi6/7 scenario | Controller/APjoin,SSID-zone mapping,guestpolicy; RFcapacity là thiết kế, không claim VM chứng minh RF |
| R11 p4,9-15,24 | Automation cấu hìnhVLAN hoặcbackup thật,inventoryngoài,secretsan toàn,idempotency,errorhandling | Run trên devices,rerun không thay dư,dead node không dừng cảfleet,backups/log/time/hash,restore sample |
| R12 p3,16-18 | EVE/GNS3/CML;PacketTracer cần instructorpreapproval | Host/image/license/capability manifest; boot proof,projectexport. PT cài sẵn không phải approval |
| R13 p3-5 | 10steps,mỗi bước1điểm,6weeks;week1diagram/IPapproval | Milestone gates; chưa tự quy đổi thành điểm hoặc bỏ công nghệ ngoài bảng10steps |
| R14 p5-8,24 | PDF executive/design/IP/topology/security/tests,TOC/pages;configs/code;15-minute demo | Report/Configurations/Automation archive,checksum,cleanimport rehearsal,corefailover<3min vàautomationlive |

Rubric viết p6-8: cần business alignment, topology,IPv4/IPv6,protocol justification,security,automation,verification và professional writing. Nhóm phải đọc/biên tập bản cuối: p24 yêu cầu không để AI prose chưa chỉnh sửa. Không gọi tài liệu preparation này là report nộp đã được nhóm duyệt.

## Câu hỏi cần chốt trước thiết kế chi tiết

1. p2 yêu cầu EVPN-VXLAN/SD-WAN/NGFW/ZTNA, nhưng rubric step6 cho iBGP/EVPN **hoặc IPsec**. Công nghệ nào phải chạy, cái nào chỉ thiết kế/chứng minh concept? Giữ nguyên requirement cho tới khi có trả lời.
2. p3 nói OSPF, p4 cho OSPF/EIGRP; chọn OSPF dual-stack làm hướng nhất quán, không cần thêm EIGRP chỉ vì xuất hiện trong ví dụ.
3. p5 lặp nội dung client-server/file-transfer của A1 trong submission. Cần xác nhận copy-paste, ưu tiên mạng doanh nghiệp và configs theo p24; không tự bỏ hoặc trộn hai bài.
4. p18 starter có một HQedge/ISP gây SPOF, không thỏa p1-3. Lab tối giản nào được chấp nhận, redundancy nào phải chạy đồng thời?
5. Deadline ghi Sunday17/11/2026 nhưng ngày đó là thứBa; xác nhận LMS/ngày nộp, hình thức team và node budget. Không tự đặt deadline.
