# Khả thi và lựa chọn nền tảng

**Chưa thể chạy lab đầy đủ trên máy ở hiện trạng khảo sát.** Evidence ghi CPU AMD7840H có8core/16logical, RAM usable15.31GiB, VMware17.6.4 và PacketTracer9.0.1. WSL2 có distro nhưng stopped. Không phát hiện EVE/GNS3/CML trong inventory; chưa có bằng chứng boot thiết bị hoặc quyền sử dụng image.

Khi khảo sát, C còn219193344byte và E còn88780800byte. Guide trang16 yêu cầu100GB trống tối thiểu và16GB RAM cho VM. Host còn phải phục vụ Windows; không thể cấp toàn bộ16GiB cho VM và giữ headroom. Không tự xóa dữ liệu hoặc tải simulator nặng để vượt chặn.

HypervisorPresent=true, firmware virtualization=true nhưng SLAT field=false. Đây không phải kết luận CPU không hỗ trợ hoặc nested virtualization đã hoạt động. Cần boot guest, kiểm `lscpu`, `/dev/kvm`, `test -r /dev/kvm`, rồi boot hai thiết bị. Không tự tắt Hyper-V/VBS hoặc sửa BIOS.

| Lựa chọn | Lợi ích cần cân nhắc | Điều kiện quyết định |
|---|---|---|
| EVE-NG trên host/remote đủ tài nguyên | Lab nhiều thiết bị, giao diện trình duyệt | Nested virtualization, license và feature của image, edition, RAM/disk được đo |
| GNS3 + VM hoặc remote server | Packet capture và host tạo traffic | GUI/VM tương thích, KVM và image hợp lệ; minimum của GUI không phải budget toàn topology |
| CML | Reference images nếu nhóm có license | Giới hạn node và feature theo image; số đo VM không chứng minh ASIC10/40Gbps |
| PacketTracer đã cài | Giảm phạm vi khi thiếu phần cứng | Giảng viên phê duyệt trước; kiểm feature thực, không suy EVPN/SD-WAN từ icon |

Chưa chốt vendor/platform. Hướng khả thi là host phòng lab/đồng đội hoặc remote được cấp quyền có32-64GB RAM và100GB+ trống, sau đó kiểm capability. Không đề nghị mua dịch vụ hoặc phát sinh phí. Budget cộng footprint từng image, controllers, services, hypervisor và khoảng30% headroom; đo CPU/RAM sau boot trước chốt số node. Chạy từng phân hệ không thay demo tích hợp đồng thời.

## Gate trước triển khai

1. Có host/storage do người sở hữu bố trí, ghi tài nguyên khả dụng.
2. Có quyền dùng đúng image/version trên đúng simulator; ghi hash, không đưa image bản quyền vào Git.
3. Boot hypervisor/KVM và hai node; kiểm SSH, capture, save/reload và footprint.
4. Thử FHRP, LACP, OSPFv3, BGP, IPsec, EVPN và QoS theo phạm vi duyệt. Command được chấp nhận chưa đủ: phải có tác động lên data plane.
5. Topology nằm trong budget; giảng viên duyệt topology/IP và ngoại lệ.

## Primary sources đối chiếu ngày05/11/2026

- [EVE supported systems](https://www.eve-ng.net/index.php/supported-hardware-and-software-systems/): cần hardware/nested virtualization; inventory Windows không thay kiểm chứng guest.
- [GNS3 Windows requirements](https://docs.gns3.com/docs/getting-started/installation/windows): minimum dành cho lab nhỏ; nhiều thiết bị cần thêm tài nguyên.
- [Cisco CML images](https://developer.cisco.com/docs/modeling-labs/vm-images-for-cml-labs/): reference images chỉ licensed trong CML nếu không có license riêng; tính năng ASIC và throughput/timing không tương đương thiết bị thật.

Guide trang17 đổi tên VMDK thành qcow2 không tự chuyển định dạng. Khi triển khai cần kiểm `qemu-img info`, hướng dẫn đúng image/version và conversion nếu cần. Không dùng password mẫu `Cisco123!` làm credential của nhóm.
