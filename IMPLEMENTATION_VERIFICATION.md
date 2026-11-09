# Kế hoạch triển khai và kiểm chứng

## Sáu tuần với điều kiện chuyển bước

| Tuần | Deliverable | Gate |
|---|---|---|
|1|Chốt yêu cầu, host/image proof, Draw.io logical/physical, IP/VLAN/flow plan|Giảng viên duyệt; đủ tài nguyên; hai node boot thành công|
|2|VLAN/trunk/LACP/STP, FHRP, DHCP/DNS relay|Branch nhận lease, resolve DNS; link/gateway failover đạt|
|3|OSPF dual-stack, loopbacks, passive interfaces, summaries|Routes và ping/trace cả IPv4/IPv6; không redistribution ngoài ý muốn|
|4|BGP hai ISP, overlay theo scope, ACL/NAT/firewall/L2 security|Allowed/denied flow matrix; ISP failure; overlay capture|
|5|QoS, automation; WLC/AAA nếu thuộc scope|Congestion counters, dead-node handling, idempotency, backup/restore|
|6|Integration soak, reload test, PDF/config export, demo15phút|Fresh import tái lập được; nhóm duyệt report và mọi giới hạn|

Phân owner theo năng lực, không tự chuyển nguyên vai A1 sang A2. Gợi ý workstreams: architecture/IP/routing; campus/services; WAN/security; QA/automation/docs. Mỗi config cần peer review và test evidence.

## Hợp đồng automation - chưa chạy trên thiết bị

Inventory ngoài gồm hostname, management IP, SSH port, platform, site và roles. Secrets lấy từ getpass/env/Vault. Bắt đầu backup read-only để chứng minh kết nối/quyền, sau đó thử VLAN change trên một test device. Kiểm SSH host key, đặt timeout, cô lập lỗi từng node, không ghi credential vào log.

Backup running/startup với ISO timestamp và SHA-256. Kiểm CLI error/output trước save; rerun không tạo diff thừa; rollback phải thử. Không copy Cisco commands sang vendor khác hoặc tự `write memory` trước review. Offline IP validator không thay automation chức năng ở step9.

## Ma trận kiểm chứng sau khi có lab

| Test | Acceptance | Evidence |
|---|---|---|
|V01 clean boot|Save/reload và services/routes phục hồi|Versions, config SHA, boot log|
|V02 L2|STP root/trunk đúng; mất một LACP member còn path|STP/port-channel output, continuous ping|
|V03 DHCP/DNS|Branch lease/renew đúng scope/gateway/DNS; IPv6 theo design|Lease, relay capture, DNS query|
|V04 FHRP/core|Shutdown active core link, takeover và restore không flap|Timestamp, packet loss, RTO; rubric<180s, engineering target chốt trước đo|
|V05 routing|Loopbacks/endpoints across-site cả IPv4/IPv6|OSPF/BGP/routes, trace, negative prefix filter|
|V06 WAN|Mất ISP1 còn ISP2; restore không blackhole|Continuous flows, counters, route change|
|V07 security|Guest deny Corp/Mgmt; IoT chỉ flow cho phép|TCP positive/negative và IPv6, ACL hits; không chỉ ping|
|V08 L2 attack lab|Rogue DHCP/ARP bị chặn; DHCP hợp lệ vẫn chạy|Capture, snooping/DAI counters trong lab cô lập|
|V09 overlay|EVPN/VNI/VTEP hoặc IPsec SA; counters tăng với flow|Encapsulation/crypto capture, MTU boundary|
|V10 QoS|Best-effort bão hòa cùng voice/video; EF/AF31 và queues đúng|Offered load, latency/jitter/loss, counters; không claim ASIC throughput|
|V11 automation|Một node offline không chặn node khác; rerun idempotent|Exit code, redacted log, config diff/hash, restore|
|V12 wireless|AP join WLC, SSID đúng zone, dynamic auth nếu yêu cầu|Join/auth records và flows; RF capacity riêng|
|V13 soak|Data/services/failover đồng thời, tài nguyên ổn định|CPU/RAM/disk series, error/leak counts|
|V14 submission|ZIP fresh import, configs load, demo15phút|Manifest, rehearsal, known limitations|

Demo dự kiến:0-2phút business/topology;2-5 dual-stack DHCP/DNS và cross-site;5-7 guest deny/corp allow;7-10 shutdown core và đo RTO;10-12 automation backup/VLAN rerun;12-14 QoS/WAN evidence;14-15 giới hạn. Cần rehearsal có timer; chưa có kết quả demo thiết bị trong gói này.

## Handoff và exit criteria

Việc cần ngay: chủ sở hữu cấp host/storage; người phụ trách image/license xác nhận quyền; giảng viên chốt breadth/depth và ngoại lệ PacketTracer. Ngày bắt đầu sáu tuần chưa xác nhận. Khi chưa có lab, chỉ design/offline checks có thể đạt; data plane, failover, QoS và automation thiết bị giữ UNVERIFIED.

Gói cuối theo trang24: `Report/`, `Configurations/{HQ,Hanoi,DaNang}/`, `Automation/{inventory,script,backups,logs}`. Không pack secrets/images. Yêu cầu10/40Gbps cần capacity model/spec;99.99% tương đương khoảng52.56phút downtime/năm365ngày, không suy từ demo. Claim uptime cần availability model và dữ liệu vận hành/failure.
