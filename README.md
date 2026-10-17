
# GC-Tune

[![GitHub Release](https://img.shields.io/github/v/release/Bebrazui/GC-Tune?style=flat-square&color=2ea44f)](https://github.com/Bebrazui/GC-Tune/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%208.0%2B-brightgreen.svg?style=flat-square)](https://android.com)
[![OriginOS](https://img.shields.io/badge/OriginOS-Supported-informational.svg?style=flat-square)](https://www.vivo.com/origin-os)

Công cụ tinh chỉnh hệ thống nâng cao và triển khai kênh đặc quyền dành cho OriginOS và các thiết bị vivo. GC-Tune tận dụng môi trường thực thi của Game Cube (Chế độ Ultra Game Mode) để thực thi lệnh với quyền hệ thống nâng cao (`uid 1000` / `system`), cài đặt giao diện `.itz` tùy chỉnh và áp dụng màu sắc cho bộ biểu tượng trực tiếp trên trình khởi chạy OriginOS mà không cần root.

[Tải bản phát hành mới nhất](https://github.com/Bebrazui/GC-Tune/releases/latest) &bull; [Thiết lập nhanh](#thiết-lập-nhanh) &bull; [Tính năng](#tổng-quan) &bull; [Biên dịch](#biên-dịch-từ-mã-nguồn)

---

## Tổng quan

GC-Tune hoạt động dựa trên một kênh IPC được thiết lập thông qua hệ thống con Game Cube có đặc quyền. Kênh này cung cấp khả năng thực thi lệnh với quyền `system` (uid 1000), cho phép tinh chỉnh cài đặt thiết bị, chỉnh sửa giao diện hệ thống và đổi màu biểu tượng bằng Material You cùng các bảng màu tùy chỉnh.

### Các tính năng chính

- **Trình dòng lệnh hệ thống có đặc quyền (`uid 1000`)**  
  Thực thi trực tiếp các lệnh shell quản trị bằng thông tin xác thực của tài khoản hệ thống. Sử dụng cơ chế đánh thức an toàn khi ở trạng thái chờ, dựa trên tín hiệu từ `dumpsys SurfaceFlinger` và `logcat`, không cần thăm dò nền liên tục hay gây hao pin.

- **Công cụ chỉnh sửa giao diện OriginOS (`.itz`)**  
  Nhập các gói giao diện `.itz` tùy chỉnh và của bên thứ ba, loại bỏ siêu dữ liệu độc quyền của cửa hàng và chuẩn hóa các mã định danh danh mục (`id`, `id3`, `uid`) để có thể xem trước và áp dụng giao diện tùy chỉnh thông qua iTheme mà không bị chặn bởi cơ chế thu phí bản quyền.

- **Đổi màu biểu tượng hệ thống và biểu tượng thích ứng**  
  Áp dụng màu sắc và kiểu hiển thị đồng nhất trực tiếp lên trình khởi chạy OriginOS:
  - Tô màu bằng Material 3 và mã màu HEX tùy chỉnh.
  - Điều chỉnh độ bão hòa, độ sáng và cường độ màu.
  - Tùy chỉnh ô nền và bán kính bo góc dạng squircle.
  - Tương thích với các gói biểu tượng tiêu chuẩn của bên thứ ba.

- **Không cần quyền root**  
  Không yêu cầu quyền root hoặc mở khóa bootloader. Hoạt động thông qua tích hợp với framework hệ thống và các quyền tiêu chuẩn cơ bản (`WRITE_SECURE_SETTINGS` được cấp qua ADB).

---

## Thiết lập nhanh

### 1. Cài đặt

Tải APK đã ký từ trang [Releases](https://github.com/Bebrazui/GC-Tune/releases/latest) và cài đặt lên thiết bị:

```bash
adb install -r gctune-signed.apk
```

### 2. Cấp quyền

Sau khi cài đặt, cấp quyền `WRITE_SECURE_SETTINGS` một lần thông qua ADB:

```bash
adb shell pm grant com.poc.gctune android.permission.WRITE_SECURE_SETTINGS
```

### 3. Thêm vào Game Cube

1. Mở **Cài đặt** → **Ultra Game Mode** (Game Cube).
2. Vào **Trò chơi được hỗ trợ** (Thêm trò chơi).
3. Trong mục **Ứng dụng khác**, chọn **GC Tune** và thêm ứng dụng vào danh sách trò chơi.
4. Khởi chạy GC Tune. Màn hình hướng dẫn ban đầu sẽ xác nhận kết nối kênh đang hoạt động.

---

## Kiến trúc và kênh IPC

```text
 +-------------------------------------------------------+
 |                       GC Tune                         |
 |  com.poc.gctune (Activities / Foreground Service)      |
 +-------------------------------------------------------+
                             |
                   SurfaceControl / IPC
                             v
 +-------------------------------------------------------+
 |                 Game Cube Subsystem                   |
 |              SurfaceFlinger / uid 1000                |
 +-------------------------------------------------------+
                             |
         +-------------------+-------------------+
         |                   |                   |
         v                   v                   v
   Trình dòng lệnh      Bộ chỉnh sửa        Bộ xử lý
   hệ thống             giao diện           biểu tượng
 (thực thi uid 1000)   (sửa đổi .itz)    (đổi màu launcher)
```

Ứng dụng khởi chạy một dịch vụ nền trước gọn nhẹ (`ChannelService`), duy trì lớp hiển thị (layer) và bộ nhận ACK trong khi các lệnh được thực thi. Tiến trình theo dõi chạy hoàn toàn theo sự kiện thông qua `logcat`, bảo đảm không tiêu thụ CPU khi ở trạng thái chờ.

---

## Biên dịch từ mã nguồn

### Yêu cầu

- JDK 11 trở lên.
- Android SDK (Platform 35 / Build-Tools 34.0.0 trở lên).
- PowerShell (Windows / Linux / macOS).

### Các bước biên dịch

Sao chép kho mã nguồn và chạy script build:

```bash
git clone https://github.com/Bebrazui/GC-Tune.git
cd GC-Tune
.\build.ps1
```

Script sẽ biên dịch mã Java bằng `javac`, đóng gói các lớp thành tệp DEX thông qua `d8`, đóng gói APK bằng `aapt` và ký APK bằng `apksigner`.

---

## Tuyên bố miễn trừ trách nhiệm

Dự án này được phát triển nhằm phục vụ nghiên cứu, tùy chỉnh thiết bị và mục đích giáo dục. Hãy bảo đảm tuân thủ các chính sách của nhà sản xuất thiết bị trước khi thay đổi các thông số hệ thống.
