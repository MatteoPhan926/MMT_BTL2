# Assignment 2 - Gói chuẩn bị độc lập

Ngày khảo sát: 05/11/2026. **Sẵn sàng phân tích/thiết kế; chưa sẵn sàng chạy lab đầy đủ hoặc tuyên bố hoàn thành Assignment 2.** Đây là preparation package, không phải cấu hình thiết bị đã kiểm chứng.

Nguồn chuẩn: PDF chính thức 24 trang, hash và bản trích xuất trong `evidence/source.json`, `evidence/assignment2_text.txt`. Đọc cả rubric, guide và checklist; ví dụ trang18 không được dùng thay yêu cầu redundancy/dual ISP ở trang1-3. Các hình trang trong evidence phục vụ đối chiếu.

Đọc theo thứ tự: `REQUIREMENTS.md` → `ARCHITECTURE.md` → `FEASIBILITY.md` → `IMPLEMENTATION_VERIFICATION.md`. `plan.json` là phương án địa chỉ có giả định rõ; `logical_options.drawio` là sơ đồ miền chức năng để thảo luận, chưa phải wiring được duyệt. `validate_plan.py` thực sự kiểm tính nhất quán của phương án; kết quả không chứng minh router chạy được.

```powershell
python build_plan.py
python validate_plan.py
```

Không tái sử dụng giao thức/client/server của Assignment 1 làm hạ tầng Assignment 2. Có thể dùng quy trình Git, checklist, SHA-256 artifact và phương pháp fault-injection. A1 chỉ là workload thử tùy chọn sau khi mạng hoạt động; không phải dependency để khởi động A2. Tạo repository riêng khi bắt đầu triển khai, không trộn config thiết bị với source A1.

Việc tiếp theo: xác nhận phạm vi rubric với giảng viên; có host hoặc remote lab đủ tài nguyên và image hợp lệ; boot proof hai node; chọn platform/vendor dựa capability đã thử; duyệt topology/IP; sau đó triển khai theo sáu tuần. Không có file `.pkt`, `.unl`, `.gns3` hoặc startup-config giả trong gói này.
