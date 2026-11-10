# BÁO CÁO SỬA LỖI — QUẢN LÝ DỊCH VỤ KHÁCH SẠN

**Ngày:** 09/11/2026  
**Phạm vi:** chỉ sửa lỗi và nâng cấp các chức năng **đã có**. Không thêm màn hình, không thêm module, không có chức năng đặt phòng.  
**Build:** thành công — 0 warning, 0 error.  
**Đã kiểm thử:** đăng nhập, sơ đồ phòng, check-out, hóa đơn, lịch sử giao dịch, báo cáo doanh thu, khởi động lại.

---

## 1. NHỮNG LỖI ĐÃ SỬA (TRONG CHỨC NĂNG SẴN CÓ)

### 1.1. Kết nối CSDL & khởi động

| Lỗi | Đã sửa |
|---|---|
| Fallback kết nối hard-code `Server=.\SQLEXPRESS01`, không có `appsettings.json` trong source | Đổi fallback sang `Server=.`; thêm cấu hình mẫu cho bản publish. Máy dùng instance khác chỉ sửa `appsettings.json`. |
| Mất kết nối SQL nhưng app vẫn báo khởi tạo thành công, tự thêm tài khoản admin/123 trong RAM | Bắt buộc `TestConnection()` trước khi nạp; lỗi hiển thị cho người dùng; bỏ fallback tài khoản trong code. |
| Mỗi lần mở app tự “quyết toán” mọi đơn quá khứ, tự đánh dấu đã thanh toán, tự gán đối tác giặt ủi, tự tạo phân công ca | Mặc định tắt; chỉ chạy khi đặt `QLKS_AUTO_SETTLE_DEMO=1` cho dữ liệu demo. |
| Reload dữ liệu còn giữ cache cũ khi DB rỗng | Đã `Clear()` trước khi nạp ở các danh mục chính. |
| Mỗi lần đăng nhập thành công, app tự ghi đè `MatKhauHash` sang định dạng khác dù mật khẩu không đổi (khiến tưởng đã đổi mật khẩu) | Bỏ đoạn tự ghi đè trong `AuthService.Login`; hash chỉ được cập nhật khi người dùng thực sự đổi mật khẩu trong chức năng quản lý tài khoản. Đã khôi phục hash seed `admin`/`letan` về giá trị ban đầu. |

### 1.2. Tính tiền phòng & hóa đơn

| Lỗi | Đã sửa |
|---|---|
| Bảng phòng không có giá; mọi phòng dùng mặc định 500.000đ | Bổ sung cột `GiaPhong`; phòng đơn 500.000đ, phòng đôi 800.000đ; đọc giá thật từ DB. |
| Check-out chỉ thu dịch vụ; khách không dùng dịch vụ thì không thu tiền phòng | Check-out luôn mở hóa đơn quyết toán gồm tiền phòng + dịch vụ. |
| Hóa đơn hiển thị/tính tổng chỉ có dịch vụ (`RoomCost = 0`) | Tính `RoomCost = Số đêm × Giá phòng`; cửa sổ hóa đơn thêm dòng “Tiền phòng” và tổng đúng. |
| Sau khi thanh toán dịch vụ, phòng vẫn “Đang ở”, phải bấm trả phòng lần 2 | Gộp luồng: thanh toán xong tự chuyển “Đang dọn”, xóa thông tin khách. |
| Hóa đơn/doanh thu tiền phòng chỉ nằm trong RAM, tắt app là mất; lại seed 2 hóa đơn mẫu giả | Bổ sung bảng nội bộ `HoaDon`/`ChiTietHoaDon`, lưu hóa đơn khi quyết toán và nạp lại khi mở app; bỏ 2 hóa đơn mẫu. Đây là sửa lỗi mất dữ liệu của chức năng hóa đơn sẵn có, không phải màn hình/chức năng mới. |
| Lịch sử giao dịch cộng trùng hóa đơn + từng dịch vụ | Giao dịch hóa đơn chỉ ghi phần tiền phòng; dịch vụ hiển thị riêng. |
| Tổng tiền lịch sử cộng cả đơn chưa thanh toán/đã hủy | Thêm cờ `IsPaid`; tổng chỉ cộng giao dịch đã thanh toán. |

**Kết quả test:** phòng 101 (2 đêm × 500.000đ) + 515.000đ dịch vụ = **1.515.000đ**; hóa đơn lưu DB, khởi động lại vẫn còn.

### 1.3. Công nợ phòng & thanh toán

| Lỗi | Đã sửa |
|---|---|
| View/SP công nợ tính cả đơn ăn uống **đã hủy** | Thêm điều kiện `TrangThai <> N'Đã hủy'`. |
| View/SP tính cả đơn sự kiện/thuê xe **chưa tới giờ sử dụng** | Chỉ tính đơn có `ThoiGianBatDau/NgayThue <= thời điểm quyết toán`. |
| Thanh toán tự đánh dấu món “Đã giao”, xe “Hoàn tất”, gán `NgayTraThucTe` dù chưa trả xe | Thanh toán chỉ cập nhật công nợ; không đổi vòng đời dịch vụ. |
| Ghi nợ phòng bị trừ “cọc ảo” (thu thiếu 30–100%) | Khi ChargeToRoom, `actualCollect = 0`; công nợ phòng là toàn bộ giá trị dịch vụ. |
| Xác nhận thanh toán fire-and-forget, lỗi bị bỏ qua | Dùng bản đồng bộ; SQL từ chối thì UI báo lỗi, không đánh dấu đã thanh toán trong RAM. |

### 1.4. Phòng — check-in/check-out

| Lỗi | Đã sửa |
|---|---|
| Cho check-in vào phòng **đang dọn** | Chặn ở `CanCheckIn` và `CheckInCommand`. |
| Cho chuyển phòng **đang có khách** sang “Đang dọn” | `CanSetCleaning` chỉ cho phòng trống/đang dọn; command chặn nếu đang có khách. |
| Sau check-out, `KhachHang.SoPhong` vẫn giữ phòng cũ | Cập nhật `SoPhong = NULL` khi trả phòng. |
| ComboBox phòng đang ở không cập nhật sau check-in/out | Gọi `RefreshAvailableRoomNumbers()` khi trạng thái phòng thay đổi. |

### 1.5. Sự kiện & thuê xe

| Lỗi | Đã sửa |
|---|---|
| Thêm/sửa khu vực sự kiện ghi `Trống/Đang sử dụng/Bảo trì/Đang dọn` — vi phạm CHECK constraint; lỗi bị nuốt | Map đúng `Hoạt động/Ngừng khai thác`; `await` + kiểm tra số dòng; bỏ ID giả. Khi load, “Ngừng khai thác” → `Maintenance` (không còn bị coi là sẵn sàng). |
| Sửa xe đang thuê ghi `Đang thuê` — vi phạm CHECK; thêm xe ghi `Đang cho thuê` | Map `Available → Sẵn sàng`, `Maintenance → Bảo trì`, `Rented → Hoạt động`; `await` + báo lỗi; bỏ ID giả. |
| Sửa xe tự đặt lại cọc 30%, ghi đè cọc thực tế | Giữ nguyên `TienCocQuyDinh` khi sửa. |
| Xe ô tô bị lưu loại “Xe côn tay” | Map đủ 4 loại, thêm `Car → Xe ô tô`. |
| Parse giá bằng `Replace(",", "").Replace(".", "")` làm “1,5” thành “15” | Dùng `decimal.TryParse` theo culture `vi-VN`. |

### 1.6. Món ăn & tồn kho

| Lỗi | Đã sửa |
|---|---|
| Bán món không kiểm tra tồn kho; bỏ qua kết quả `sp_DatMonAn`; hết hàng vẫn tạo đơn | Kiểm tra tồn trước; SP thất bại thì báo lỗi, không tạo đơn; chỉ trừ kho RAM sau khi SP thành công. |
| Insert header + chi tiết đơn hàng fire-and-forget | Chạy đồng bộ, kiểm tra số dòng ảnh hưởng, báo lỗi thay vì im lặng. |

### 1.7. Bãi giữ xe

| Lỗi | Đã sửa |
|---|---|
| `ActualOutTime` lấy lúc mở app, không phải lúc xe ra → tính phí thiếu | Khi chọn vé đặt giờ ra = hiện tại; khi quyết toán nếu giờ ra < giờ vào thì reset và tính lại. |

### 1.8. Nhân sự

| Lỗi | Đã sửa |
|---|---|
| Nhân viên nghỉ việc nhưng tài khoản vẫn đăng nhập được | Cập nhật thêm `TaiKhoan.TrangThai = 0` khi cho nghỉ việc; đồng bộ, không fire-and-forget. |

### 1.9. CSDL

- Bổ sung `PhongKhachSan.GiaPhong`, `HoaDon`, `ChiTietHoaDon`.
- Sửa `vw_DichVuChuaThanhToanTheoPhong`, `vw_DoanhThuTheoDichVu`, `sp_XacNhanThanhToanDichVuTheoPhong`.
- Thêm `Database/Migration_2026-11-09_HotelFixes.sql` để cập nhật DB cũ **không mất dữ liệu**.

---

## 2. LỖI CÒN LẠI TRONG CÁC CHỨC NĂNG SẴN CÓ

> Không đề xuất thêm module/màn hình. Các mục dưới đây là lỗi/logic của chức năng hiện có.

### 2.1. Nghiêm trọng

1. **Thanh toán và lưu hóa đơn chưa cùng một transaction.**
   - Hiện gọi SP xác nhận thanh toán, sau đó mới lưu `HoaDon`. Nếu lưu hóa đơn lỗi, tiền đã thu nhưng lịch sử thiếu.
   - **Sửa đúng:** gộp vào một stored procedure `sp_QuyetToanPhong` (cập nhật công nợ + insert hóa đơn + cập nhật phòng) trong một transaction.

2. **Mật khẩu chưa an toàn.**
   - `SecurityHelper` đang mã hóa AES hai chiều, khóa hard-code; admin xem được mật khẩu plaintext; tài khoản mẫu `admin/123`.
   - **Sửa đúng:** PBKDF2/BCrypt/Argon2 + salt riêng; bỏ giải mã/hiển thị mật khẩu; bắt buộc đổi mật khẩu; xóa tài khoản demo khỏi script production. Đây là sửa lỗi bảo mật của chức năng đăng nhập hiện có.

3. **Còn nhiều chỗ ghi CSDL fire-and-forget.**
   - Các command trong ViewModel/View dùng `_ = ExecuteNonQueryAsync(...)`; lỗi trigger/CHECK/FK bị nuốt, UI vẫn báo thành công.
   - **Sửa đúng:** `async Task` + `await`, kiểm tra kết quả, rollback trạng thái RAM nếu DB lỗi; dùng transaction cho các thao tác nhiều bảng.

4. **Script `Database/QuanLyDichVuKhachSan.sql` drop database.**
   - **Sửa đúng:** chỉ dùng cho dev/demo; cập nhật DB thật bằng migration có backup (đã thêm file migration).

### 2.2. Logic tính toán / chức năng hiện có

5. **Công nợ gom theo `SoPhong`** nên dịch vụ của khách cũ có thể bị tính cho khách mới khi cùng phòng. Không thêm bảng mới: có thể lọc theo `NgayNhanPhong/NgayTraPhong` của phòng và ngày phát sinh dịch vụ, đồng thời đối chiếu khách/CCCD trước khi quyết toán.
6. **Chưa có phụ thu trả muộn/trả sớm, thuế, giảm giá** trong hóa đơn hiện có. Nếu nghiệp vụ không yêu cầu thì giữ nguyên; nếu có, bổ sung cột/hạng mục trong hóa đơn hiện tại (không thêm màn hình).
7. **Kho chưa trừ theo lô/hạn sử dụng**, `sp_DatMonAn` chưa chặn số lượng âm. Sửa trong chức năng kho hiện có: `IF @SoLuong <= 0 RETURN 0`; trừ FIFO/cảnh báo lô hết hạn.
8. **Bãi xe chưa chống trùng biển số đang gửi**, chưa kiểm tra phòng đang có khách trước khi miễn phí. Sửa trong chức năng bãi xe hiện có.
9. **Báo cáo doanh thu** đang trộn doanh thu gộp và hoa hồng giặt ủi, lọc theo ngày phát sinh thay vì ngày thu. Sửa công thức/lọc trong báo cáo hiện có.
10. **Nhân viên ↔ tài khoản** chưa có khóa ngoại; khóa tài khoản hiện dò theo họ tên. Có thể bổ sung `NhanVienId` vào `TaiKhoan` (sửa liên kết hiện có, không thêm chức năng).
11. **Reload dữ liệu** còn giữ cache cũ khi DB rỗng; timer cảnh báo không dừng khi logout. Sửa trong chức năng hiện có.
12. **Dead code/lỗi tiềm ẩn:** `AddInventoryBatch`, `AddNewVehicleCommand`, các hàm quota gọi SP không tồn tại; `GetAllTransactions` hard-code tên nhân viên; lọc giao dịch case-sensitive; `TotalStockValue` dùng giá bán; `TrashedDate` không lưu DB. Nên dọn/sửa trong các chức năng hiện có.

### 2.3. UI/UX cần sửa (theo phản hồi của bạn)

Các lỗi hiển thị cần ảnh chụp cụ thể để sửa chính xác. Những điểm đã thấy trong quá trình test:

- **Sơ đồ phòng:** tên khách và số điện thoại bị cắt (“Vũ H…”, “09081122…”) do card phòng hẹp + `TextTrimming`. Hướng sửa trong layout hiện có: cho phép xuống dòng hoặc tăng nhẹ chiều rộng card/giảm font, thêm tooltip hiển thị đầy đủ.
- **Lịch sử giao dịch:** tổng bề rộng các cột (135 + 150 + 160 + 130 + 155 + 125 + 180 + 130 + 145 ≈ 1.310px) lớn hơn vùng hiển thị ~800px, nên cột “Số tiền thu”/“Hình thức” bị cắt và phải kéo ngang. Hướng sửa: dùng `Width="*"`/`MinWidth` cho các cột chính, giảm bớt cột phụ hoặc cho phép xuống dòng tiêu đề.
- **Một số nhãn bị lệch/mất chữ** do chiều cao cố định hoặc font tiếng Việt; cần ảnh từng màn hình để chỉnh đúng `MinWidth`, `TextWrapping`, `TextTrimming`, `Padding`.

> Gửi mình ảnh chụp các màn hình bị lỗi (hoặc tên màn hình + vị trí) để mình sửa đúng ô/chữ, không tự ý đổi layout.

---

## 3. HƯỚNG DẪN CẬP NHẬT & CHẠY

**Yêu cầu:** Windows 10/11, .NET 10 SDK/Runtime, SQL Server (Express/Developer/LocalDB).

**DB đang có dữ liệu — cập nhật không mất dữ liệu:**
```powershell
sqlcmd -S . -E -d QuanLyDichVuKhachSan -i Database\Migration_2026-11-09_HotelFixes.sql -f 65001 -b
```

**Cài mới/demo (script này drop database):**
```powershell
sqlcmd -S . -E -i Database\QuanLyDichVuKhachSan.sql -f 65001 -b
```

**Cấu hình** `appsettings.json` cạnh file chạy:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.;Database=QuanLyDichVuKhachSan;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```
Dùng `.\SQLEXPRESS` hoặc `(LocalDB)\MSSQLLocalDB` nếu máy cài instance khác. File này bị `.gitignore` — không commit.

**Build/chạy:**
```powershell
dotnet build QuanLyDichVuKhachSan.slnx
dotnet run
```
Bản publish đã cập nhật trong `publish/`.

**Tài khoản demo:** `admin/123`, `letan/123` — cần đổi trước khi dùng thật.

---

## 4. FILE ĐÃ SỬA

`Database/QuanLyDichVuKhachSan.sql`, `Database/Migration_2026-11-09_HotelFixes.sql`, `Models/RoomModels.cs`, `Models/ServiceModels.cs`, `Services/DataService.cs`, `Services/DatabaseService.cs`, `ViewModels/RoomMapViewModel.cs`, `ViewModels/EventViewModel.cs`, `ViewModels/VehicleViewModel.cs`, `ViewModels/ParkingViewModel.cs`, `ViewModels/StaffViewModel.cs`, `ViewModels/TransactionHistoryViewModel.cs`, `Views/AddEventSpaceDialogWindow.xaml.cs`, `Views/EditEventSpaceDialogWindow.xaml.cs`, `Views/AddVehicleDialogWindow.xaml.cs`, `Views/EditVehicleDialogWindow.xaml.cs`, `Views/InvoiceBillWindow.xaml.cs`.

---

*Báo cáo này chỉ mô tả lỗi/nâng cấp trong các chức năng đã có. Không có chức năng đặt phòng, không thêm màn hình mới. Các mục UI/UX cần ảnh chụp cụ thể để sửa chính xác.*
