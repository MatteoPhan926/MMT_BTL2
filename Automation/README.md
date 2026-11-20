# Step 9 · Automation trên Cisco IOS

Chạy từ thư mục `Automation/` trên controller Linux có đường tới mạng OOB của lab. Inventory dùng tên và địa chỉ dự kiến trong bảng Step 2, gồm 7 switch và 4 router. Đối chiếu hostname, cổng SSH và IP quản trị thực tế trước khi chạy. Việc alias node giữa hai bộ cấu hình campus/routing cần được nhóm thống nhất trước khi bật provisioning.

## Chuẩn bị controller

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install ansible-core paramiko
ansible-galaxy collection install -r requirements.yml
ansible-inventory --graph
ansible-playbook deploy_baseline.yml --syntax-check
read -r -p 'Tài khoản SSH lab: ' TVI_SSH_USER
read -r -s -p 'Mật khẩu SSH lab: ' TVI_SSH_PASSWORD
echo
export TVI_SSH_USER TVI_SSH_PASSWORD
```

Dùng tài khoản lab có quyền đọc toàn bộ running-config và quyền cấu hình khi thử provisioning. Xác thực fingerprint từng node qua console và lưu host key trên controller trước khi chạy. Playbook dùng SSH tới IOS. Với file .pkt chạy độc lập, dùng CLI trong Packet Tracer để thu các phép đo được nền tảng hỗ trợ.

## Backup và cấu hình

1. Chạy `ansible-playbook deploy_baseline.yml --limit HN-DIST01` để thử backup. Bỏ `--limit` để chụp toàn bộ inventory. Mỗi lượt tạo thư mục riêng trong `backups/` với thời gian UTC, mỗi host online có bốn file gồm running-config và interface summary ở hai thời điểm. Phiên bản ảnh IOS cần hỗ trợ `show running-config` và `show ip interface brief`.
2. Để triển khai baseline, tạo `lab-vars.yml` cục bộ với hai khóa YAML `lab_ntp` và `lab_syslog` là địa chỉ máy NTP và syslog đang chạy trong lab. Dải Corporate là VLAN 10/20/30 theo site, cùng VLAN 99 quản trị. Tên VLAN nằm trong `campus_vlans` của inventory, chỉnh theo tên nhóm đã thống nhất trước khi áp.
3. Trên bản sao lab, kiểm tra local admin qua console trước khi bật AAA. Chạy `ansible-playbook deploy_baseline.yml --limit HN-DIST01 -e @lab-vars.yml -e provision=true`. Playbook merge VLAN, cấu hình NTP, syslog, banner và tạo danh sách AAA local tên TVI-LAB. Danh sách này chỉ được dùng cho line khi nhóm đã ánh xạ nó trong chính sách đăng nhập. Kiểm tra đăng nhập lại, VLAN và dịch vụ sau khi chạy. Các thay đổi nằm trong running-config.
4. Chạy lại cùng lệnh. Trong log, các task cấu hình VLAN/IOS/banner phải có trạng thái ok ở lần hai. Các task tạo thư mục và ghi snapshot sẽ có changed mỗi lượt. Khi một lệnh cấu hình lỗi giữa chừng, kiểm tra capture after của host còn truy cập được, so với before, rồi sửa hoặc phục hồi bằng checkpoint của simulator. Với node offline, play recap phải chỉ ra node lỗi và node còn lại vẫn chạy hết.
5. Xem `logs/automation.log` và kiểm exit code ngay sau lệnh bằng `echo $?`. Tính hash hoặc so diff theo cặp before/after. Backup đầy đủ có thể chứa khóa và thông tin xác thực. Dùng excerpt đã che thông tin đó làm evidence, giữ bản gốc trong thư mục riêng của controller. Kết thúc bằng `unset TVI_SSH_PASSWORD TVI_SSH_USER`.

## Đã kiểm tra

Ansible Core 2.21.6 và cisco.ios 11.7.1 đọc được inventory 11 node và playbook qua syntax-check. Một lần chạy backup qua SSH cục bộ với dữ liệu CLI mẫu cho thấy node online sinh đủ hai config và hai interface summary, node offline báo lỗi riêng và lượt chạy trả mã khác 0. Đây là kiểm tra đường chạy của automation trên controller. Thử provisioning, idempotency của IOS, SSH OOB và trạng thái của thiết bị nhóm nằm ở bài T01.
