/* =================================================================================
   HỆ THỐNG QUẢN LÝ DỊCH VỤ KHÁCH SẠN (DALAT HOTEL) - SQL SERVER
   FILE 5: Data.sql - DỮ LIỆU TĨNH HỆ THỐNG (MASTER DATA) & DỮ LIỆU MẪU (SAMPLE DATA)
   Thứ tự chạy: 1. Table.sql -> 2. Views.sql -> 3. Trigger.sql -> 4. Procedures.sql -> 5. Data.sql
   ================================================================================= */

USE QuanLyDichVuKhachSan;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =====================================================================================
-- PHẦN 6: DỮ LIỆU TĨNH & DANH MỤC HỆ THỐNG (SYSTEM & MASTER DATA)
-- =====================================================================================

-- 6.1 Tài khoản đăng nhập mặc định (Mật khẩu mặc định: 123)
INSERT INTO TaiKhoan (TenDangNhap, MatKhauHash, HoTen, VaiTro, SoDienThoai, Email) VALUES
('admin', 'ubJSwSb+V3dx+o3DsP1XwWiiBuvs6i40PTcsb1ziOsU=', N'Chủ Khách Sạn', N'Admin', '0948198812', 'dalathotel@gmail.com'),
('letan', 'ubJSwSb+V3dx+o3DsP1XwWiiBuvs6i40PTcsb1ziOsU=', N'Lễ Tân Trực Chính', N'LeTan', '0912345678', 'letan@dalathotel.vn');
GO

-- 6.2 Nhân viên
INSERT INTO NhanVien (MaNV, HoTen, CCCD, SoDienThoai, Email, ChucVu, LuongCoBan, TrangThai) VALUES
('NV001', N'Trần Thị Mai',  '001198000123', '0912345678', 'maitran@dalathotel.vn',   N'Lễ tân trưởng', 12000000, N'Đang làm việc'),
('NV002', N'Nguyễn Văn An',  '001199000456', '0987654321', 'annguyen@dalathotel.vn',  N'Nhân viên lễ tân',8500000, N'Đang làm việc'),
('NV003', N'Lê Hoàng Nam',   '001197000789', '0933112233', 'namle@dalathotel.vn',     N'Nhân viên lễ tân',8500000, N'Đang làm việc');
GO

-- 6.3 Ca trực
INSERT INTO CaTruc (TenCa, GioBatDau, GioKetThuc, GhiChu) VALUES
(N'Ca Sáng',  '06:00:00', '14:00:00', N'Tiếp nhận khách check-in sáng, kiểm tra mini-bar'),
(N'Ca Chiều', '14:00:00', '22:00:00', N'Đỉnh điểm check-in/out, bàn giao xe cho thuê'),
(N'Ca Đêm',   '22:00:00', '06:00:00', N'Trực đêm, bảo an bãi xe, chốt ca ngày');
GO

-- 6.4 Phân công ca trực trọn vẹn tháng 9/2026 (Từ 01/09 đến 30/09, mỗi ngày 3 ca cho 3 nhân viên luân phiên)
INSERT INTO PhanCongCaTruc (NhanVienId, CaTrucId, NgayTruc, GhiChu) VALUES
-- Ngày 01/09/2026
(1, 1, '2026-09-01', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-09-01', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-09-01', N'Lê Hoàng Nam ca đêm'),
-- Ngày 02/09/2026
(2, 1, '2026-09-02', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-09-02', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-09-02', N'Trần Thị Mai ca đêm'),
-- Ngày 03/09/2026
(3, 1, '2026-09-03', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-09-03', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-09-03', N'Nguyễn Văn An ca đêm'),
-- Ngày 04/09/2026
(1, 1, '2026-09-04', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-09-04', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-09-04', N'Lê Hoàng Nam ca đêm'),
-- Ngày 05/09/2026
(2, 1, '2026-09-05', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-09-05', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-09-05', N'Trần Thị Mai ca đêm'),
-- Ngày 06/09/2026
(3, 1, '2026-09-06', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-09-06', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-09-06', N'Nguyễn Văn An ca đêm'),
-- Ngày 07/09/2026
(1, 1, '2026-09-07', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-09-07', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-09-07', N'Lê Hoàng Nam ca đêm'),
-- Ngày 08/09/2026
(2, 1, '2026-09-08', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-09-08', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-09-08', N'Trần Thị Mai ca đêm'),
-- Ngày 09/09/2026
(3, 1, '2026-09-09', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-09-09', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-09-09', N'Nguyễn Văn An ca đêm'),
-- Ngày 10/09/2026
(1, 1, '2026-09-10', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-09-10', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-09-10', N'Lê Hoàng Nam ca đêm'),
-- Ngày 11/09/2026
(2, 1, '2026-09-11', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-09-11', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-09-11', N'Trần Thị Mai ca đêm'),
-- Ngày 12/09/2026
(3, 1, '2026-09-12', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-09-12', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-09-12', N'Nguyễn Văn An ca đêm'),
-- Ngày 13/09/2026
(1, 1, '2026-09-13', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-09-13', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-09-13', N'Lê Hoàng Nam ca đêm'),
-- Ngày 14/09/2026
(2, 1, '2026-09-14', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-09-14', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-09-14', N'Trần Thị Mai ca đêm'),
-- Ngày 15/09/2026
(3, 1, '2026-09-15', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-09-15', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-09-15', N'Nguyễn Văn An ca đêm'),
-- Ngày 16/09/2026
(1, 1, '2026-09-16', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-09-16', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-09-16', N'Lê Hoàng Nam ca đêm'),
-- Ngày 17/09/2026 - Hôm nay
(2, 1, '2026-09-17', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-09-17', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-09-17', N'Trần Thị Mai ca đêm'),
-- Ngày 18/09/2026
(3, 1, '2026-09-18', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-09-18', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-09-18', N'Nguyễn Văn An ca đêm'),
-- Ngày 19/09/2026
(1, 1, '2026-09-19', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-09-19', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-09-19', N'Lê Hoàng Nam ca đêm'),
-- Ngày 20/09/2026
(2, 1, '2026-09-20', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-09-20', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-09-20', N'Trần Thị Mai ca đêm'),
-- Ngày 21/09/2026
(3, 1, '2026-09-21', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-09-21', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-09-21', N'Nguyễn Văn An ca đêm'),
-- Ngày 22/09/2026
(1, 1, '2026-09-22', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-09-22', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-09-22', N'Lê Hoàng Nam ca đêm'),
-- Ngày 23/09/2026
(2, 1, '2026-09-23', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-09-23', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-09-23', N'Trần Thị Mai ca đêm'),
-- Ngày 24/09/2026
(3, 1, '2026-09-24', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-09-24', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-09-24', N'Nguyễn Văn An ca đêm'),
-- Ngày 25/09/2026
(1, 1, '2026-09-25', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-09-25', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-09-25', N'Lê Hoàng Nam ca đêm'),
-- Ngày 26/09/2026
(2, 1, '2026-09-26', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-09-26', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-09-26', N'Trần Thị Mai ca đêm'),
-- Ngày 27/09/2026
(3, 1, '2026-09-27', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-09-27', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-09-27', N'Nguyễn Văn An ca đêm'),
-- Ngày 28/09/2026
(1, 1, '2026-09-28', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-09-28', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-09-28', N'Lê Hoàng Nam ca đêm'),
-- Ngày 29/09/2026
(2, 1, '2026-09-29', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-09-29', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-09-29', N'Trần Thị Mai ca đêm'),
-- Ngày 30/09/2026
(3, 1, '2026-09-30', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-09-30', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-09-30', N'Nguyễn Văn An ca đêm');
GO

-- Phân công ca trực tháng 11/2026 (Xếp ca đầy đủ từ đầu tháng và từ hôm nay 09/11/2026 đến hết tháng 30/11/2026)
INSERT INTO PhanCongCaTruc (NhanVienId, CaTrucId, NgayTruc, GhiChu) VALUES
-- Ngày 01/11/2026
(1, 1, '2026-11-01', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-11-01', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-11-01', N'Lê Hoàng Nam ca đêm'),
-- Ngày 02/11/2026
(2, 1, '2026-11-02', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-11-02', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-11-02', N'Trần Thị Mai ca đêm'),
-- Ngày 03/11/2026
(3, 1, '2026-11-03', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-11-03', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-11-03', N'Nguyễn Văn An ca đêm'),
-- Ngày 04/11/2026
(1, 1, '2026-11-04', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-11-04', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-11-04', N'Lê Hoàng Nam ca đêm'),
-- Ngày 05/11/2026
(2, 1, '2026-11-05', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-11-05', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-11-05', N'Trần Thị Mai ca đêm'),
-- Ngày 06/11/2026
(3, 1, '2026-11-06', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-11-06', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-11-06', N'Nguyễn Văn An ca đêm'),
-- Ngày 07/11/2026
(1, 1, '2026-11-07', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-11-07', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-11-07', N'Lê Hoàng Nam ca đêm'),
-- Ngày 08/11/2026
(2, 1, '2026-11-08', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-11-08', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-11-08', N'Trần Thị Mai ca đêm'),
-- Ngày 09/11/2026 - Hôm nay
(3, 1, '2026-11-09', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-11-09', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-11-09', N'Nguyễn Văn An ca đêm'),
-- Ngày 10/11/2026
(1, 1, '2026-11-10', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-11-10', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-11-10', N'Lê Hoàng Nam ca đêm'),
-- Ngày 11/11/2026
(2, 1, '2026-11-11', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-11-11', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-11-11', N'Trần Thị Mai ca đêm'),
-- Ngày 12/11/2026
(3, 1, '2026-11-12', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-11-12', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-11-12', N'Nguyễn Văn An ca đêm'),
-- Ngày 13/11/2026
(1, 1, '2026-11-13', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-11-13', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-11-13', N'Lê Hoàng Nam ca đêm'),
-- Ngày 14/11/2026
(2, 1, '2026-11-14', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-11-14', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-11-14', N'Trần Thị Mai ca đêm'),
-- Ngày 15/11/2026
(3, 1, '2026-11-15', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-11-15', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-11-15', N'Nguyễn Văn An ca đêm'),
-- Ngày 16/11/2026
(1, 1, '2026-11-16', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-11-16', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-11-16', N'Lê Hoàng Nam ca đêm'),
-- Ngày 17/11/2026
(2, 1, '2026-11-17', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-11-17', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-11-17', N'Trần Thị Mai ca đêm'),
-- Ngày 18/11/2026
(3, 1, '2026-11-18', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-11-18', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-11-18', N'Nguyễn Văn An ca đêm'),
-- Ngày 19/11/2026
(1, 1, '2026-11-19', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-11-19', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-11-19', N'Lê Hoàng Nam ca đêm'),
-- Ngày 20/11/2026
(2, 1, '2026-11-20', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-11-20', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-11-20', N'Trần Thị Mai ca đêm'),
-- Ngày 21/11/2026
(3, 1, '2026-11-21', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-11-21', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-11-21', N'Nguyễn Văn An ca đêm'),
-- Ngày 22/11/2026
(1, 1, '2026-11-22', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-11-22', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-11-22', N'Lê Hoàng Nam ca đêm'),
-- Ngày 23/11/2026
(2, 1, '2026-11-23', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-11-23', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-11-23', N'Trần Thị Mai ca đêm'),
-- Ngày 24/11/2026
(3, 1, '2026-11-24', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-11-24', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-11-24', N'Nguyễn Văn An ca đêm'),
-- Ngày 25/11/2026
(1, 1, '2026-11-25', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-11-25', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-11-25', N'Lê Hoàng Nam ca đêm'),
-- Ngày 26/11/2026
(2, 1, '2026-11-26', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-11-26', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-11-26', N'Trần Thị Mai ca đêm'),
-- Ngày 27/11/2026
(3, 1, '2026-11-27', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-11-27', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-11-27', N'Nguyễn Văn An ca đêm'),
-- Ngày 28/11/2026
(1, 1, '2026-11-28', N'Trần Thị Mai ca sáng'),
(2, 2, '2026-11-28', N'Nguyễn Văn An ca chiều'),
(3, 3, '2026-11-28', N'Lê Hoàng Nam ca đêm'),
-- Ngày 29/11/2026
(2, 1, '2026-11-29', N'Nguyễn Văn An ca sáng'),
(3, 2, '2026-11-29', N'Lê Hoàng Nam ca chiều'),
(1, 3, '2026-11-29', N'Trần Thị Mai ca đêm'),
-- Ngày 30/11/2026
(3, 1, '2026-11-30', N'Lê Hoàng Nam ca sáng'),
(1, 2, '2026-11-30', N'Trần Thị Mai ca chiều'),
(2, 3, '2026-11-30', N'Nguyễn Văn An ca đêm');
GO

-- 6.5 Danh mục 5 dịch vụ hệ thống
INSERT INTO DichVuHeThong (MaDV, TenDV, LoaiDichVu, DangHoatDong, MoTa) VALUES
('AN_UONG', N'Ăn Uống',              N'Tự túc',        1, N'Bán lẻ hàng khô, nước giải khát, snack tại phòng & quầy lễ tân'),
('SU_KIEN', N'Sảnh & Sự Kiện',        N'Tự túc',        1, N'Cho thuê sảnh tiệc, phòng họp VIP, sân thượng Sky Lounge theo giờ/ngày'),
('THUE_XE', N'Cho Thuê Xe Máy',      N'Tự túc',        1, N'Cho thuê xe tay ga, xe số kèm mũ bảo hiểm'),
('DO_XE',   N'Bãi & Hầm Đỗ Xe',      N'Tự túc',        1, N'Quản lý trông giữ xe máy, ô tô có thu phí theo lượt/giờ/ngày'),
('GIAT_UI', N'Giặt Ủi',              N'Dịch vụ ngoài', 1, N'Liên kết đối tác giặt sấy, giặt hấp lấy hoa hồng 25-35%');
GO

-- 6.6 Cấu hình tham số hệ thống
INSERT INTO ThamSoHeThong (MaThamSo, TenThamSo, GiaTri, MoTa) VALUES
('CHECKIN_STANDARD_TIME',       '14:00',      N'14:00', N'Giờ nhận phòng tiêu chuẩn'),
('CHECKOUT_STANDARD_TIME',      '12:00',      N'12:00', N'Giờ trả phòng tiêu chuẩn'),
('EVENT_ADVANCE_ALERT_MINUTES', '15',         N'15',    N'Báo trước khi sự kiện sắp hết giờ (phút)'),
-- FIX (bổ sung theo yêu cầu): thời gian dọn dẹp mặc định giữa 2 đơn liên tiếp cùng khu vực
('EVENT_CLEANING_BUFFER_MINUTES','60',        N'60',    N'Thời gian dọn dẹp/kiểm tra tối thiểu giữa 2 đơn liên tiếp cùng 1 khu vực sự kiện (phút)'),
('VEHICLE_ADVANCE_ALERT_MINUTES','30',        N'30',    N'Báo trước khi xe sắp hết giờ thuê (phút)'),
('VEHICLE_CLEANING_BUFFER_MINUTES','30',      N'30',    N'Thời gian vệ sinh/kiểm tra xe tối thiểu giữa 2 lượt thuê liên tiếp cùng 1 xe (phút)');
GO

-- 6.7 Danh mục 20 phòng khách sạn (Tầng 1 đến Tầng 5)
-- 13 phòng đang ở (~2/3 tổng số phòng), thời gian lưu trú đầy đủ 2-3 ngày, 1-2 tuần từ hôm nay
INSERT INTO PhongKhachSan (SoPhong, Tang, LoaiPhong, TrangThai, TenKhach, SoDienThoai, CCCD, GhiChu, NgayNhanPhong, NgayTraPhong) VALUES
('101', 1, N'Phòng đơn', N'Đang ở',   N'Đoàn Minh Trí',     '0908112233', '079198001234', N'Khách ở 2 ngày từ hôm nay, thuê xe SH', GETDATE(), DATEADD(DAY,2,GETDATE())),
('102', 1, N'Phòng đơn', N'Đang ở',   N'Trịnh Hồng Quân',   '0909123456', '079192003344', N'Khách ở 3 ngày từ hôm nay, thuê xe Lead', GETDATE(), DATEADD(DAY,3,GETDATE())),
('103', 1, N'Phòng đôi', N'Đang ở',   N'Vũ Hoàng Nam',      '0912334455', '079193005566', N'Khách ở 2 tuần từ hôm nay, thuê xe Grande', GETDATE(), DATEADD(DAY,14,GETDATE())),
('104', 1, N'Phòng đôi', N'Đang dọn', NULL,                 NULL,         NULL,           N'Khách vừa trả phòng lúc sáng', NULL, NULL),
('201', 2, N'Phòng đơn', N'Đang ở',   N'Hoàng Mai Linh',    '0978112244', '079194007788', N'Khách ở 2 ngày từ hôm nay, thuê xe Future', GETDATE(), DATEADD(DAY,2,GETDATE())),
('202', 2, N'Phòng đôi', N'Đang ở',   N'Lê Tấn Phát',       '0969888999', '079201009876', N'Khách ở 1 tuần từ hôm nay, thuê xe AirBlade', GETDATE(), DATEADD(DAY,7,GETDATE())),
('203', 2, N'Phòng đôi', N'Đang ở',   N'Bùi Thanh Tùng',    '0938445566', '079196001122', N'Khách ở 2 tuần từ hôm nay, thuê xe Winner X', GETDATE(), DATEADD(DAY,14,GETDATE())),
('204', 2, N'Phòng đơn', N'Bảo trì',  NULL,                 NULL,         NULL,           N'Đang sửa vòi sen toilet', NULL, NULL),
('301', 3, N'Phòng đôi', N'Đang ở',   N'Nguyễn Anh Thư',    '0918777666', '079195003456', N'Khách ở 2 tuần từ hôm nay (honeymoon, thuê xe Vision)', GETDATE(), DATEADD(DAY,14,GETDATE())),
('302', 3, N'Phòng đơn', N'Đang ở',   N'Đặng Hải Yến',      '0982334411', '079197003355', N'Khách ở 3 ngày từ hôm nay, thuê xe Vespa', GETDATE(), DATEADD(DAY,3,GETDATE())),
('303', 3, N'Phòng đôi', N'Đang ở',   N'Phan Văn Đức',      '0945667788', '079199004466', N'Khách ở 2 tuần từ hôm nay, thuê xe NVX', GETDATE(), DATEADD(DAY,14,GETDATE())),
('304', 3, N'Phòng đơn', N'Trống',    NULL,                 NULL,         NULL,           NULL, NULL, NULL),
('401', 4, N'Phòng đôi', N'Đang ở',   N'Phạm Quốc Bảo',     '0933444555', '079188005678', N'Khách ở 2 tuần từ hôm nay, gửi xe ô tô 7 chỗ', GETDATE(), DATEADD(DAY,14,GETDATE())),
('402', 4, N'Phòng đơn', N'Đang ở',   N'Trần Thu Hà',       '0919223344', '079189006677', N'Khách ở 3 ngày từ hôm nay, thuê xe Liberty', GETDATE(), DATEADD(DAY,3,GETDATE())),
('403', 4, N'Phòng đôi', N'Đang ở',   N'Đỗ Minh Khang',     '0987556677', '079187008899', N'Khách ở 1 tuần từ hôm nay, thuê xe Exciter', GETDATE(), DATEADD(DAY,7,GETDATE())),
('404', 4, N'Phòng đơn', N'Trống',    NULL,                 NULL,         NULL,           NULL, NULL, NULL),
('501', 5, N'Phòng đôi', N'Đang ở',   N'Nguyễn Hoàng Long', '0903889900', '079186001234', N'Khách ở 2 tuần từ hôm nay, thuê xe PG-1', GETDATE(), DATEADD(DAY,14,GETDATE())),
('502', 5, N'Phòng đơn', N'Đang ở',   N'Lê Thị Ngọc Ánh',   '0979334455', '079185002345', N'Khách ở 1 tuần từ hôm nay, thuê xe Sirius', GETDATE(), DATEADD(DAY,7,GETDATE())),
('503', 5, N'Phòng đôi', N'Đang dọn', NULL,                 NULL,         NULL,           N'Đang thay ga trải giường', NULL, NULL),
('504', 5, N'Phòng đơn', N'Trống',    NULL,                 NULL,         NULL,           NULL, NULL, NULL);
GO
UPDATE PhongKhachSan
SET GiaPhong = CASE WHEN LoaiPhong = N'Phòng đôi' THEN 800000 ELSE 500000 END;
GO

-- 6.8 Nhà cung cấp
INSERT INTO NhaCungCap (TenNhaCungCap, NguoiLienHe, SoDienThoai, DiaChi, Email, GhiChu, TrangThai) VALUES
(N'Công ty CP Hàng tiêu dùng Masan', N'Nguyễn Văn Toàn', '02838221100', N'Tầng 12 Central Plaza, Q.1, TP.HCM', 'contact@masan.vn', N'Cung cấp nước khoáng, nước ngọt, mì ly ăn liền', 1),
(N'Công ty TNHH Nestlé Việt Nam',     N'Phạm Mai Lan',   '02839112233', N'KCN Biên Hòa 2, Đồng Nai',          'order@vn.nestle.com', N'Cung cấp cà phê G7, trà đóng chai, nước tăng lực', 1),
(N'Cơ sở Đặc sản Rượu Vang Đà Lạt',  N'Lê Hữu Thọ',     '02633822456', N'Phường 8, TP. Đà Lạt',             'sales@dalatwine.com', N'Cung cấp rượu vang, mứt dâu, trà Atiso cao cấp', 1);
GO

-- 6.9 Danh mục món ăn & mini-bar
INSERT INTO MonAn (TenMon, DanhMuc, DonViTinh, GiaBan, GiaVonBinhQuan, SoLuongTonKho, MucTonToiThieu, NhaCungCapId, GhiChu) VALUES
(N'Mì tôm ly Modern',               N'Đồ ăn nhẹ',       N'Ly',    20000, 11000, 150, 20, 1, N'Hạn dùng 8 tháng'),
(N'Nước khoáng Lavie 500ml',        N'Nước giải khát',  N'Chai',  15000,  6000, 240, 30, 1, N'Hạn dùng 12 tháng'),
(N'Coca Cola lon 330ml',            N'Nước giải khát',  N'Lon',   20000, 10000, 180, 25, 1, N'Hạn dùng 9 tháng'),
(N'Cà phê hòa tan G7 (hộp 20 gói)', N'Đồ uống pha',     N'Hộp',   45000, 22000,  80, 15, 2, N'Hạn dùng 18 tháng'),
(N'Trà Atiso túi lọc Đà Lạt',       N'Đồ uống pha',     N'Hộp',   60000, 30000,  60, 10, 3, N'Đặc sản Đà Lạt, HSD 12 tháng'),
(N'Snack khoai tây Lay''s',         N'Đồ ăn nhẹ',       N'Gói',   25000, 13000, 120, 20, 1, N'Hạn dùng 6 tháng'),
(N'Rượu vang đỏ Đà Lạt 750ml',      N'Rượu cao cấp',    N'Chai', 220000,120000,  40,  8, 3, N'Hạn dùng 36 tháng'),
(N'Hạt điều rang muối 200g',        N'Đồ ăn nhẹ',       N'Hũ',    85000, 45000,  50, 10, 3, N'Hạn dùng 12 tháng'),
(N'Nước tăng lực Red Bull lon',     N'Nước giải khát',  N'Lon',   25000, 12500,  90, 15, 2, N'Hạn dùng 12 tháng'),
(N'Socola thanh KitKat 4 finger',   N'Bánh kẹo',        N'Thanh', 22000, 11000,  70, 15, 2, N'Hạn dùng 10 tháng'),
(N'Trà xanh C2 hương chanh 455ml',  N'Nước giải khát',  N'Chai',  15000,  7000, 110, 20, 1, N'Hạn dùng 9 tháng'),
(N'Bia Heineken lon 330ml',         N'Đồ uống có cồn',  N'Lon',   35000, 18000, 100, 20, 1, N'Hạn dùng 12 tháng'),
(N'Mứt dâu tây Đà Lạt 250g',        N'Đặc sản',         N'Hũ',    55000, 28000,  45, 10, 3, N'Hạn dùng 6 tháng');
GO

-- 6.10 Sảnh & khu vực sự kiện (Chỉ cho thuê và tính tiền theo giờ)
INSERT INTO KhuVucSuKien (TenKhuVuc, LoaiKhuVuc, SucChua, GiaThueTheoGio, TrangThietBi, TrangThai) VALUES
(N'Sảnh Đại Tiệc A',        N'Sảnh lớn',             100, 1000000, N'Âm thanh Line Array, màn LED P3, ánh sáng Moving Head, 25 bàn tiệc tròn', N'Hoạt động'),
(N'Phòng Hội Nghị B',       N'Phòng họp kín',         50,  700000, N'Bàn hội nghị chữ U, 2 máy chiếu laser 4K, 8 mic không dây',              N'Hoạt động'),
(N'Sky Lounge Sân Thượng C', N'Sân thượng ngoài trời',  10,  500000, N'Quầy bar cocktail, loa Bose ngoài trời, đèn LED dây vintage',            N'Hoạt động'),
(N'Phòng Trà D',           N'Phòng nhỏ trong nhà',    10,  300000, N'Bàn trà gỗ, sân vườn nhỏ, phù hợp họp mặt gia đình',                     N'Hoạt động');
GO

-- 6.11 Danh mục 20 xe máy cho thuê (18 xe Hoạt động, 2 xe Bảo trì)
INSERT INTO XeChoThue (BienSo, TenXe, LoaiXe, GiaThueNgay, TienCocQuyDinh, TrangThai, GhiChuTinhTrang) VALUES
('49-B1 112.33', N'Airblade Đen (2022)',     N'Xe tay ga', 100000, 500000, N'Hoạt động', NULL),
('49-B1 223.44', N'Airblade Đỏ (2023)',      N'Xe tay ga', 100000, 500000, N'Hoạt động', NULL),
('49-B1 334.55', N'Airblade Xanh (2022)',    N'Xe tay ga', 100000, 500000, N'Hoạt động', NULL),
('49-B1 445.66', N'Airblade Xám (2024)',     N'Xe tay ga', 100000, 500000, N'Hoạt động', NULL),
('49-B1 556.77', N'Vision Trắng (2023)',     N'Xe tay ga', 100000, 500000, N'Hoạt động', NULL),
('49-B1 667.88', N'Vision Đỏ (2022)',       N'Xe tay ga', 100000, 500000, N'Hoạt động', NULL),
('49-B1 778.99', N'Vision Xanh (2024)',     N'Xe tay ga', 100000, 500000, N'Hoạt động', NULL),
('49-B1 889.11', N'Vision Đen (2023)',      N'Xe tay ga', 100000, 500000, N'Hoạt động', NULL),
('49-B1 123.01', N'Blade Đỏ (2021)',        N'Xe số',      80000, 300000, N'Hoạt động', NULL),
('49-B1 234.12', N'Blade Đen (2022)',       N'Xe số',      80000, 300000, N'Hoạt động', NULL),
('49-B1 345.23', N'Blade Xanh (2023)',      N'Xe số',      80000, 300000, N'Hoạt động', NULL),
('49-B1 456.34', N'Blade Trắng (2022)',     N'Xe số',      80000, 300000, N'Hoạt động', NULL),
('49-B1 567.45', N'Sirius Đen (2022)',      N'Xe số',      80000, 300000, N'Bảo trì',   NULL),
('49-B1 678.56', N'Sirius Đỏ (2021)',       N'Xe số',      80000, 300000, N'Hoạt động', NULL),
('49-B1 789.67', N'Sirius Xanh (2023)',     N'Xe số',      80000, 300000, N'Hoạt động', NULL),
('49-B1 890.78', N'Sirius Trắng (2022)',    N'Xe số',      80000, 300000, N'Hoạt động', NULL),
('49-B1 901.89', N'Yamaha Xanh (2022)',     N'Xe số',      80000, 300000, N'Hoạt động', NULL),
('49-B1 012.90', N'Yamaha Đỏ (2021)',       N'Xe số',      80000, 300000, N'Hoạt động', NULL),
('49-B1 135.79', N'Yamaha Đen (2023)',      N'Xe số',      80000, 300000, N'Bảo trì',   NULL),
('49-B1 246.80', N'Yamaha Xám (2022)',      N'Xe số',      80000, 300000, N'Hoạt động', NULL);
GO

-- 6.12 Bảng giá bán dịch vụ giặt ủi chung (Khóa giá bán thống nhất áp dụng cho mọi khách)
INSERT INTO LoaiDichVuGiatUi (MaLoai, TenLoai, DonGiaBanKg, DonViTinh, HeSoBoiThuongToiDa, DangKinhDoanh) VALUES
('GIAT_SAY', N'Giặt sấy thông thường', 30000, N'Kg', 10, 1),
('GIAT_HAP', N'Giặt hấp cao cấp',     80000, N'Kg', 10, 1),
('UI_PHANG', N'Ủi phẳng',              40000, N'Kg', 10, 1);
GO

-- 6.13 Đối tác giặt ủi ngoài
INSERT INTO DoiTacGiatUi (TenDoiTac, DiaChi, SoDienThoai, HanThanhToanCongNo, TyLeKhachSanHuong, TyLeDoiTacHuong, TrangThai) VALUES
(N'Tiệm Giặt Sấy Tốc Hành EcoClean',        N'Số 12 Đường Hoa Cúc, P.7, Đà Lạt',    '02633445566', N'Theo tháng', 30.00, 70.00, 1),
(N'Xưởng Giặt Hấp Cao Cấp Royal Laundry',   N'Số 88 Nguyễn Chí Thanh, Đà Lạt',      '02633112233', N'Theo tháng', 35.00, 65.00, 1),
(N'Tiệm Giặt Ủi Nhanh Sương Mai',           N'Số 45 Trần Hưng Đạo, Đà Lạt',         '02633998877', N'Theo tháng', 25.00, 75.00, 0);
GO

-- 6.14 Bảng giá vốn đối tác giặt ủi (Mỗi đối tác x mỗi loại dịch vụ = đơn giá vốn riêng, luôn NHỎ HƠN giá niêm yết)
INSERT INTO BangGiaDoiTacGiatUi (DoiTacId, LoaiDichVuId, DonGiaVonKg, GhiChu) VALUES
-- 1. Tiệm Giặt Sấy Tốc Hành EcoClean (Id = 1): Chuyên giặt sấy dân dụng & ủi phẳng (Không nhận giặt hấp)
(1, 1, 21000, N'Giá vốn giặt sấy 21k/kg (Giá bán 30k -> KS lời 9k/kg ~ 30%)'),
(1, 3, 28000, N'Giá vốn ủi phẳng 28k/kg (Giá bán 40k -> KS lời 12k/kg ~ 30%)'),

-- 2. Xưởng Giặt Hấp Cao Cấp Royal Laundry (Id = 2): Nhận đủ 3 dịch vụ kể cả vest, đầm lụa
(2, 1, 20000, N'Giá vốn giặt sấy 20k/kg (Giá bán 30k -> KS lời 10k/kg ~ 33.3%)'),
(2, 2, 52000, N'Giá vốn giặt hấp 52k/kg (Giá bán 80k -> KS lời 28k/kg ~ 35%)'),
(2, 3, 26000, N'Giá vốn ủi phẳng 26k/kg (Giá bán 40k -> KS lời 14k/kg ~ 35%)'),

-- 3. Tiệm Giặt Ủi Nhanh Sương Mai (Id = 3): Đã ngừng hợp tác (Chỉ nhận giặt sấy thông thường)
(3, 1, 22500, N'Giá vốn giặt sấy cũ lúc còn hợp tác (22.5k/kg)');
GO


-- =====================================================================================
-- PHẦN 7: DỮ LIỆU MẪU GIAO DỊCH PHÁT SINH (TRANSACTIONS & OPERATIONAL SAMPLE DATA)
-- =====================================================================================

-- 7.1 Khách hàng mẫu (14 khách lưu trú phòng + khách vãng lai)
INSERT INTO KhachHang (HoTen, CCCD, SoDienThoai, SoPhong, GhiChu, NgayTao) VALUES
(N'Đoàn Minh Trí',     '079198001234', '0908112233', '101', N'Khách lưu trú phòng 101 (2 ngày, thuê xe SH)', GETDATE()),
(N'Trịnh Hồng Quân',   '079192003344', '0909123456', '102', N'Khách lưu trú phòng 102 (3 ngày, thuê xe Lead)', GETDATE()),
(N'Vũ Hoàng Nam',      '079193005566', '0912334455', '103', N'Khách lưu trú phòng 103 (2 tuần, thuê xe Grande)', GETDATE()),
(N'Hoàng Mai Linh',    '079194007788', '0978112244', '201', N'Khách lưu trú phòng 201 (2 ngày, thuê xe Future)', GETDATE()),
(N'Lê Tấn Phát',       '079201009876', '0969888999', '202', N'Khách lưu trú phòng 202 (1 tuần, thuê xe AirBlade)', GETDATE()),
(N'Bùi Thanh Tùng',    '079196001122', '0938445566', '203', N'Khách lưu trú phòng 203 (2 tuần, thuê xe Winner X)', GETDATE()),
(N'Nguyễn Anh Thư',    '079195003456', '0918777666', '301', N'Khách lưu trú phòng 301 (2 tuần honeymoon, thuê xe Vision)', GETDATE()),
(N'Đặng Hải Yến',      '079197003355', '0982334411', '302', N'Khách lưu trú phòng 302 (3 ngày, thuê xe Vespa)', GETDATE()),
(N'Phan Văn Đức',      '079199004466', '0945667788', '303', N'Khách lưu trú phòng 303 (2 tuần, thuê xe NVX)', GETDATE()),
(N'Phạm Quốc Bảo',     '079188005678', '0933444555', '401', N'Khách lưu trú phòng 401 (2 tuần, gửi ô tô 7 chỗ)', GETDATE()),
(N'Trần Thu Hà',       '079189006677', '0919223344', '402', N'Khách lưu trú phòng 402 (3 ngày, thuê xe Liberty)', GETDATE()),
(N'Đỗ Minh Khang',     '079187008899', '0987556677', '403', N'Khách lưu trú phòng 403 (1 tuần, thuê xe Exciter)', GETDATE()),
(N'Nguyễn Hoàng Long', '079186001234', '0903889900', '501', N'Khách lưu trú phòng 501 (2 tuần, thuê xe PG-1)', GETDATE()),
(N'Lê Thị Ngọc Ánh',   '079185002345', '0979334455', '502', N'Khách lưu trú phòng 502 (1 tuần, thuê xe Sirius)', GETDATE()),
(N'Công ty TechCorp',  '0312999888',   '0903999888', NULL,  N'Khách vãng lai tổ chức sự kiện',   GETDATE()),
(N'Nguyễn Văn Khách',  '079190001111', '0988112233', NULL,  N'Khách vãng lai thuê xe',           GETDATE());
GO

-- 7.2 Phiếu nhập kho mẫu
INSERT INTO PhieuNhapKho (MaPhieuNhap, NhaCungCapId, NguoiNhapId, NgayNhap, GhiChu) VALUES
('PN-20260825-01', 1, 1, DATEADD(DAY,-6,GETDATE()), N'Nhập hàng định kỳ đầu tuần từ Masan'),
('PN-20260827-01', 1, 2, DATEADD(DAY,-4,GETDATE()), N'Nhập bổ sung nước khoáng và Coca Cola'),
('PN-20260829-01', 2, 1, DATEADD(DAY,-2,GETDATE()), N'Nhập cà phê G7 và socola từ Nestlé'),
('PN-20260830-01', 3, 3, DATEADD(DAY,-1,GETDATE()), N'Nhập rượu vang và đặc sản Đà Lạt');
GO

INSERT INTO ChiTietPhieuNhapKho (PhieuNhapId, MonAnId, DonViNhap, HeSoQuyDoi, SoLuongNhap, DonGiaNhap, SoLo, HanSuDung, GhiChu) VALUES
(1, 1, N'Thùng', 30, 5,  330000, N'MO-2608-A', DATEADD(MONTH,8,GETDATE()),  N'1 thùng = 30 gói'),
(1, 6, N'Thùng', 24, 3,  480000, N'LAY-2608-B', DATEADD(MONTH,6,GETDATE()), N'1 thùng = 24 gói'),
(2, 2, N'Thùng', 24, 10, 144000, N'LAV-2608-C', DATEADD(MONTH,12,GETDATE()),N'1 thùng = 24 chai 500ml'),
(2, 3, N'Thùng', 24, 8,  240000, N'COCA-2608-D',DATEADD(MONTH,9,GETDATE()), N'1 thùng = 24 lon'),
(3, 4, N'Hộp',   1,  20, 22000,  N'G7-2608-E',  DATEADD(MONTH,10,GETDATE()),N'Nhập lẻ theo hộp, không quy đổi'),
(4, 7, N'Thùng', 6,  5,  720000, N'VANG-2608-F',DATEADD(DAY,10,GETDATE()), N'CẢNH BÁO: còn 10 ngày là hết hạn, cần ưu tiên bán trước (FIFO)');
GO

-- 7.3 Đơn hàng ẩm thực & minibar mẫu (Các đơn quá khứ trước hôm nay đã Hoàn thành & Thanh toán hết; kèm đơn phát sinh mới Hôm nay & Ngày mai)
INSERT INTO DonHangMonAn (MaDon, KhachHangId, TenKhach, SoPhong, HinhThucThanhToan, TongTien, DaThanhToan, GhiChu, NguoiTaoId, NguoiThanhToanId, ThoiGianThanhToan, NgayTao, TrangThai) VALUES
-- Dữ liệu mẫu đã qua (Trước ngày hôm nay -> Đã giao & Đã thanh toán hết để thống kê)
('DH-AU-001', 1,  N'Đoàn Minh Trí',     '101', N'Ghi nợ vào phòng',    70000, 1, N'2 Coca + 2 Lavie',                     1, 1, DATEADD(DAY,-15,GETDATE()), DATEADD(DAY,-15,GETDATE()), N'Đã giao'),
('DH-AU-002', 1,  N'Đoàn Minh Trí',     '101', N'Thanh toán trực tiếp', 90000, 1, N'2 Cà phê G7',                         1, 1, DATEADD(DAY,-14,GETDATE()), DATEADD(DAY,-14,GETDATE()), N'Đã giao'),
('DH-AU-003', 2,  N'Trịnh Hồng Quân',   '102', N'Ghi nợ vào phòng',   120000, 1, N'4 Mì Modern + 2 Coca',                 2, 2, DATEADD(DAY,-14,GETDATE()), DATEADD(DAY,-14,GETDATE()), N'Đã giao'),
('DH-AU-004', 3,  N'Vũ Hoàng Nam',      '103', N'Ghi nợ vào phòng',   610000, 1, N'2 Rượu vang đỏ + 2 Hạt điều',          1, 1, DATEADD(DAY,-13,GETDATE()), DATEADD(DAY,-13,GETDATE()), N'Đã giao'),
('DH-AU-005', 4,  N'Hoàng Mai Linh',    '201', N'Thanh toán trực tiếp',280000, 1, N'2 Hạt điều + 2 Mứt dâu',              2, 2, DATEADD(DAY,-13,GETDATE()), DATEADD(DAY,-13,GETDATE()), N'Đã giao'),
('DH-AU-006', 5,  N'Lê Tấn Phát',       '202', N'Ghi nợ vào phòng',   220000, 1, N'6 Mì tôm ly + 4 Snack Lay''s',         2, 2, DATEADD(DAY,-12,GETDATE()), DATEADD(DAY,-12,GETDATE()), N'Đã giao'),
('DH-AU-007', 6,  N'Bùi Thanh Tùng',    '203', N'Ghi nợ vào phòng',   210000, 1, N'6 Bia Heineken lon',                   3, 3, DATEADD(DAY,-12,GETDATE()), DATEADD(DAY,-12,GETDATE()), N'Đã giao'),
('DH-AU-008', 7,  N'Nguyễn Anh Thư',    '301', N'Ghi nợ vào phòng',   635000, 1, N'2 Rượu vang + 2 Mứt dâu + 1 Hạt điều', 3, 3, DATEADD(DAY,-11,GETDATE()), DATEADD(DAY,-11,GETDATE()), N'Đã giao'),
('DH-AU-009', 8,  N'Đặng Hải Yến',      '302', N'Ghi nợ vào phòng',   180000, 1, N'4 Coca + 4 Snack Lay''s',              1, 1, DATEADD(DAY,-11,GETDATE()), DATEADD(DAY,-11,GETDATE()), N'Đã giao'),
('DH-AU-010', 9,  N'Phan Văn Đức',      '303', N'Ghi nợ vào phòng',   450000, 1, N'8 Bia Heineken + 2 Hạt điều',          2, 2, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-10,GETDATE()), N'Đã giao'),
('DH-AU-011', 10, N'Phạm Quốc Bảo',     '401', N'Ghi nợ vào phòng',   345000, 1, N'3 Trà Atiso + 3 Mứt dâu',              1, 1, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-10,GETDATE()), N'Đã giao'),
('DH-AU-012', 11, N'Trần Thu Hà',       '402', N'Ghi nợ vào phòng',    50000, 0, N'2 Nước tăng lực Red Bull (Khách hủy)', 2, NULL, NULL,                     DATEADD(DAY,-9,GETDATE()),  N'Đã hủy'),
('DH-AU-013', 12, N'Đỗ Minh Khang',     '403', N'Ghi nợ vào phòng',   240000, 1, N'4 Red Bull + 4 Mì + 4 Lavie',          2, 2, DATEADD(DAY,-9,GETDATE()),  DATEADD(DAY,-9,GETDATE()),  N'Đã giao'),
('DH-AU-014', 13, N'Nguyễn Hoàng Long', '501', N'Ghi nợ vào phòng',   830000, 1, N'3 Rượu vang đỏ + 2 Hạt điều',          1, 1, DATEADD(DAY,-8,GETDATE()),  DATEADD(DAY,-8,GETDATE()),  N'Đã giao'),
('DH-AU-015', 14, N'Lê Thị Ngọc Ánh',   '502', N'Ghi nợ vào phòng',   340000, 1, N'4 Hũ Mứt dâu + 2 Trà Atiso',           3, 3, DATEADD(DAY,-8,GETDATE()),  DATEADD(DAY,-8,GETDATE()),  N'Đã giao'),
('DH-AU-016', 1,  N'Đoàn Minh Trí',     '101', N'Ghi nợ vào phòng',   140000, 1, N'4 Mì Modern + 4 C2',                   1, 1, DATEADD(DAY,-7,GETDATE()),  DATEADD(DAY,-7,GETDATE()),  N'Đã giao'),
('DH-AU-017', 4,  N'Hoàng Mai Linh',    '201', N'Ghi nợ vào phòng',   154000, 1, N'2 Mứt dâu + 2 KitKat',                 2, 2, DATEADD(DAY,-7,GETDATE()),  DATEADD(DAY,-7,GETDATE()),  N'Đã giao'),
('DH-AU-018', 7,  N'Nguyễn Anh Thư',    '301', N'Thanh toán trực tiếp',380000, 1, N'6 Bia Heineken + 2 Hạt điều',          1, 1, DATEADD(DAY,-6,GETDATE()),  DATEADD(DAY,-6,GETDATE()),  N'Đã giao'),
('DH-AU-019', 9,  N'Phan Văn Đức',      '303', N'Ghi nợ vào phòng',   220000, 1, N'2 Trà Atiso + 4 Lay''s',               2, 2, DATEADD(DAY,-6,GETDATE()),  DATEADD(DAY,-6,GETDATE()),  N'Đã giao'),
('DH-AU-020', 10, N'Phạm Quốc Bảo',     '401', N'Ghi nợ vào phòng',   800000, 1, N'3 Rượu vang đỏ + 4 Bia Heineken',      1, 1, DATEADD(DAY,-5,GETDATE()),  DATEADD(DAY,-5,GETDATE()),  N'Đã giao'),
('DH-AU-021', 13, N'Nguyễn Hoàng Long', '501', N'Ghi nợ vào phòng',   520000, 1, N'4 Cà phê G7 + 4 Hạt điều',             3, 3, DATEADD(DAY,-5,GETDATE()),  DATEADD(DAY,-5,GETDATE()),  N'Đã giao'),
('DH-AU-022', 2,  N'Trịnh Hồng Quân',   '102', N'Ghi nợ vào phòng',   660000, 1, N'2 Rượu vang đỏ + 4 Mứt dâu',           1, 1, DATEADD(DAY,-4,GETDATE()),  DATEADD(DAY,-4,GETDATE()),  N'Đã giao'),
('DH-AU-023', 5,  N'Lê Tấn Phát',       '202', N'Ghi nợ vào phòng',   450000, 1, N'10 Bia Heineken + 4 Lay''s',           2, 2, DATEADD(DAY,-4,GETDATE()),  DATEADD(DAY,-4,GETDATE()),  N'Đã giao'),
('DH-AU-024', 3,  N'Vũ Hoàng Nam',      '103', N'Ghi nợ vào phòng',   660000, 1, N'3 Rượu vang đỏ Đà Lạt',                1, 1, DATEADD(DAY,-3,GETDATE()),  DATEADD(DAY,-3,GETDATE()),  N'Đã giao'),
('DH-AU-025', 6,  N'Bùi Thanh Tùng',    '203', N'Ghi nợ vào phòng',   560000, 1, N'4 Hạt điều + 4 Mứt dâu',               2, 2, DATEADD(DAY,-3,GETDATE()),  DATEADD(DAY,-3,GETDATE()),  N'Đã giao'),
('DH-AU-026', 8,  N'Đặng Hải Yến',      '302', N'Ghi nợ vào phòng',   650000, 1, N'2 Rượu vang + 6 Bia Heineken',         3, 3, DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,-2,GETDATE()),  N'Đã giao'),
('DH-AU-027', 11, N'Trần Thu Hà',       '402', N'Ghi nợ vào phòng',   460000, 1, N'4 Trà Atiso + 4 Mứt dâu',              1, 1, DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,-2,GETDATE()),  N'Đã giao'),
('DH-AU-028', 12, N'Đỗ Minh Khang',     '403', N'Ghi nợ vào phòng',   420000, 1, N'12 Bia Heineken lon',                  2, 2, DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  N'Đã giao'),
('DH-AU-029', 14, N'Lê Thị Ngọc Ánh',   '502', N'Ghi nợ vào phòng',   440000, 1, N'2 Rượu vang đỏ Đà Lạt',                1, 1, DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  N'Đã giao'),
('DH-AU-030', 1,  N'Đoàn Minh Trí',     '101', N'Ghi nợ vào phòng',   520000, 1, N'4 Hạt điều + 4 Cà phê G7',             2, 2, DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  N'Đã giao'),
-- Giao dịch phát sinh MỚI Hôm nay (GETDATE()) và Ngày mai (DATEADD(DAY,1,GETDATE()))
('DH-AU-031', 1,  N'Đoàn Minh Trí',     '101', N'Ghi nợ vào phòng',    55000, 0, N'1 Mì Modern + 1 Red Bull + 1 Lavie sáng nay', 1, NULL, NULL, DATEADD(HOUR,-2,GETDATE()), N'Đã giao'),
('DH-AU-032', 2,  N'Trịnh Hồng Quân',   '102', N'Thanh toán trực tiếp', 90000, 1, N'2 Cà phê G7 (Khách thanh toán tại quầy sáng nay)', 1, 1, DATEADD(HOUR,-2,GETDATE()), DATEADD(HOUR,-2,GETDATE()), N'Đã giao'),
('DH-AU-033', 3,  N'Vũ Hoàng Nam',      '103', N'Ghi nợ vào phòng',   290000, 0, N'1 Rượu vang đỏ Đà Lạt + 2 Bia Heineken hôm nay', 2, NULL, NULL, DATEADD(HOUR,-1,GETDATE()), N'Đã giao'),
('DH-AU-034', 5,  N'Lê Tấn Phát',       '202', N'Ghi nợ vào phòng',    85000, 0, N'1 Hạt điều rang muối 200g dùng tại phòng', 2, NULL, NULL, DATEADD(MINUTE,-40,GETDATE()), N'Đang chuẩn bị'),
('DH-AU-035', 7,  N'Nguyễn Anh Thư',    '301', N'Ghi nợ vào phòng',   115000, 0, N'1 Trà Atiso + 1 Mứt dâu tây Đà Lạt',    1, NULL, NULL, DATEADD(MINUTE,-25,GETDATE()), N'Đã giao'),
('DH-AU-036', 8,  N'Đặng Hải Yến',      '302', N'Thanh toán trực tiếp', 70000, 1, N'2 Snack Lay''s + 1 Coca Cola',           2, 2, DATEADD(MINUTE,-20,GETDATE()), DATEADD(MINUTE,-20,GETDATE()), N'Đã giao'),
('DH-AU-037', 10, N'Phạm Quốc Bảo',     '401', N'Ghi nợ vào phòng',   140000, 0, N'4 Bia Heineken ướp lạnh gọi lên phòng', 1, NULL, NULL, DATEADD(MINUTE,-10,GETDATE()), N'Chờ xử lý'),
('DH-AU-038', 12, N'Đỗ Minh Khang',     '403', N'Ghi nợ vào phòng',    65000, 0, N'2 Mì tôm ly + 1 Red Bull',              3, NULL, NULL, DATEADD(MINUTE,-5,GETDATE()),  N'Chờ xử lý'),
('DH-AU-039', 6,  N'Bùi Thanh Tùng',    '203', N'Ghi nợ vào phòng',   280000, 0, N'Đặt trước 1 Rượu vang + 1 Trà Atiso ngày mai', 1, NULL, NULL, DATEADD(DAY,1,GETDATE()), N'Chờ xử lý'),
('DH-AU-040', 13, N'Nguyễn Hoàng Long', '501', N'Thanh toán trực tiếp',130000, 1, N'Đặt combo Cà phê G7 + Hạt điều sáng mai', 2, 2, GETDATE(), DATEADD(DAY,1,GETDATE()), N'Đã giao');
GO

INSERT INTO ChiTietDonHangMonAn (DonHangId, MonAnId, SoLuong, DonGia, GiaVon, GhiChu) VALUES
(1, 3, 2, 20000, 10000, N'Coca Cola lon'),
(1, 2, 2, 15000, 6000, N'Nước khoáng Lavie'),
(2, 4, 2, 45000, 22000, N'Cà phê G7'),
(3, 1, 4, 20000, 11000, N'Mì Modern ly'),
(3, 3, 2, 20000, 10000, N'Coca Cola lon'),
(4, 7, 2, 220000, 120000, N'Rượu vang đỏ Đà Lạt'),
(4, 8, 2, 85000, 45000, N'Hạt điều rang muối'),
(5, 8, 2, 85000, 45000, N'Hạt điều rang muối'),
(5, 13, 2, 55000, 28000, N'Mứt dâu tây 250g'),
(6, 1, 6, 20000, 11000, N'Mì Modern ly'),
(6, 6, 4, 25000, 13000, N'Snack khoai tây Lay''s'),
(7, 12, 6, 35000, 18000, N'Bia Heineken lon'),
(8, 7, 2, 220000, 120000, N'Rượu vang đỏ Đà Lạt'),
(8, 13, 2, 55000, 28000, N'Mứt dâu tây 250g'),
(8, 8, 1, 85000, 45000, N'Hạt điều rang muối'),
(9, 3, 4, 20000, 10000, N'Coca Cola lon'),
(9, 6, 4, 25000, 13000, N'Snack khoai tây Lay''s'),
(10, 12, 8, 35000, 18000, N'Bia Heineken lon'),
(10, 8, 2, 85000, 45000, N'Hạt điều rang muối'),
(11, 5, 3, 60000, 30000, N'Trà Atiso túi lọc'),
(11, 13, 3, 55000, 28000, N'Mứt dâu tây 250g'),
(12, 9, 2, 25000, 12500, N'Nước tăng lực Red Bull'),
(13, 9, 4, 25000, 12500, N'Nước tăng lực Red Bull'),
(13, 1, 4, 20000, 11000, N'Mì Modern ly'),
(13, 2, 4, 15000, 6000, N'Nước khoáng Lavie'),
(14, 7, 3, 220000, 120000, N'Rượu vang đỏ Đà Lạt'),
(14, 8, 2, 85000, 45000, N'Hạt điều rang muối'),
(15, 13, 4, 55000, 28000, N'Mứt dâu tây 250g'),
(15, 5, 2, 60000, 30000, N'Trà Atiso túi lọc'),
(16, 1, 4, 20000, 11000, N'Mì Modern ly'),
(16, 11, 4, 15000, 7000, N'Trà xanh C2'),
(17, 13, 2, 55000, 28000, N'Mứt dâu tây 250g'),
(17, 10, 2, 22000, 11000, N'Socola KitKat'),
(18, 12, 6, 35000, 18000, N'Bia Heineken lon'),
(18, 8, 2, 85000, 45000, N'Hạt điều rang muối'),
(19, 5, 2, 60000, 30000, N'Trà Atiso túi lọc'),
(19, 6, 4, 25000, 13000, N'Snack khoai tây Lay''s'),
(20, 7, 3, 220000, 120000, N'Rượu vang đỏ Đà Lạt'),
(20, 12, 4, 35000, 18000, N'Bia Heineken lon'),
(21, 4, 4, 45000, 22000, N'Cà phê G7'),
(21, 8, 4, 85000, 45000, N'Hạt điều rang muối'),
(22, 7, 2, 220000, 120000, N'Rượu vang đỏ Đà Lạt'),
(22, 13, 4, 55000, 28000, N'Mứt dâu tây 250g'),
(23, 12, 10, 35000, 18000, N'Bia Heineken lon'),
(23, 6, 4, 25000, 13000, N'Snack khoai tây Lay''s'),
(24, 7, 3, 220000, 120000, N'Rượu vang đỏ Đà Lạt'),
(25, 8, 4, 85000, 45000, N'Hạt điều rang muối'),
(25, 13, 4, 55000, 28000, N'Mứt dâu tây 250g'),
(26, 7, 2, 220000, 120000, N'Rượu vang đỏ Đà Lạt'),
(26, 12, 6, 35000, 18000, N'Bia Heineken lon'),
(27, 5, 4, 60000, 30000, N'Trà Atiso túi lọc'),
(27, 13, 4, 55000, 28000, N'Mứt dâu tây 250g'),
(28, 12, 12, 35000, 18000, N'Bia Heineken lon'),
(29, 7, 2, 220000, 120000, N'Rượu vang đỏ Đà Lạt'),
(30, 8, 4, 85000, 45000, N'Hạt điều rang muối'),
(30, 4, 4, 45000, 22000, N'Cà phê G7'),
(31, 1, 1, 20000, 11000, N'Mì Modern ly'),
(31, 9, 1, 25000, 12500, N'Nước tăng lực Red Bull'),
(31, 2, 1, 10000, 6000, N'Nước khoáng Lavie'),
(32, 4, 2, 45000, 22000, N'Cà phê G7'),
(33, 7, 1, 220000, 120000, N'Rượu vang đỏ Đà Lạt'),
(33, 12, 2, 35000, 18000, N'Bia Heineken lon'),
(34, 8, 1, 85000, 45000, N'Hạt điều rang muối'),
(35, 5, 1, 60000, 30000, N'Trà Atiso túi lọc'),
(35, 13, 1, 55000, 28000, N'Mứt dâu tây 250g'),
(36, 6, 2, 25000, 13000, N'Snack khoai tây Lay''s'),
(36, 3, 1, 20000, 10000, N'Coca Cola lon'),
(37, 12, 4, 35000, 18000, N'Bia Heineken lon'),
(38, 1, 2, 20000, 11000, N'Mì Modern ly'),
(38, 9, 1, 25000, 12500, N'Nước tăng lực Red Bull'),
(39, 7, 1, 220000, 120000, N'Rượu vang đỏ Đà Lạt'),
(39, 5, 1, 60000, 30000, N'Trà Atiso túi lọc'),
(40, 4, 1, 45000, 22000, N'Cà phê G7'),
(40, 8, 1, 85000, 45000, N'Hạt điều rang muối');
GO

-- 7.4 Đơn đặt sảnh & sự kiện mẫu (Sảnh Đại Tiệc A: 1tr/h, Phòng Hội Nghị B: 700k/h, Sky Lounge C: 500k/h, Phòng Trà D: 300k/h)
-- 16 đơn quá khứ đã Hoàn tất & Quyết toán (Tổng doanh thu = 57.350.000 đ ~ 60% tổng doanh thu khách sạn dịch vụ)
INSERT INTO DonDatSuKien (
    MaDon, KhuVucId, KhachHangId, TenKhach, SoDienThoai, SoPhong,
    ThoiGianBatDau, ThoiGianKetThuc, ThoiGianDonDepPhut, PhuThuRutNganDonDep, GhiChuRutNganDonDep,
    TienCoc, TongTienDuKien, ChiPhiPhatSinh, DaThanhToan, GhiChuHuHai,
    HinhThucThanhToanBanDau, TrangThaiDon,
    ThoiGianHuy, LyDoHuy, NguoiHuyId, SoTienHoanCoc,
    NguoiTaoId, NguoiThanhToanId, ThoiGianThanhToan, NgayTao
) VALUES
-- Dữ liệu sự kiện quá khứ (Hoàn tất & đã thanh toán)
('SK-2026-001', 1, 7,  N'Nguyễn Anh Thư',    '0918777666', '301', DATEADD(HOUR,8,DATEADD(DAY,-30,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,13,DATEADD(DAY,-30,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 1500000, 5000000, 0, 1, N'Tiệc gia đình kỷ niệm 5 bàn tròn', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,13,DATEADD(DAY,-30,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-33,GETDATE())),
('SK-2026-002', 2, 15, N'Công ty TechCorp',   '0903999888', NULL,  DATEADD(HOUR,13,DATEADD(DAY,-28,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,17,DATEADD(DAY,-28,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 1000000, 2800000, 0, 1, N'Họp chiến lược công nghệ 40 khách', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,17,DATEADD(DAY,-28,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-31,GETDATE())),
('SK-2026-003', 3, 1,  N'Đoàn Minh Trí',     '0908112233', '101', DATEADD(HOUR,17,DATEADD(DAY,-26,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,21,DATEADD(DAY,-26,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 1000000, 2000000, 0, 1, N'Tiệc sinh nhật Acoustic hoàng hôn', N'Thanh toán toàn bộ', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(HOUR,21,DATEADD(DAY,-26,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-29,GETDATE())),
('SK-2026-004', 4, 8,  N'Đặng Hải Yến',      '0982334411', '302', DATEADD(HOUR,8,DATEADD(DAY,-25,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,11,DATEADD(DAY,-25,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 300000, 900000, 0, 1, N'Thưởng trà sáng giao lưu', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,11,DATEADD(DAY,-25,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-27,GETDATE())),
('SK-2026-005', 1, 15, N'Tập đoàn Vingroup',  '0909555666', NULL,  DATEADD(HOUR,9,DATEADD(DAY,-22,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,15,DATEADD(DAY,-22,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 2000000, 6000000, 0, 1, N'Hội thảo khách hàng chi nhánh', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,15,DATEADD(DAY,-22,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-25,GETDATE())),
('SK-2026-006', 2, 6,  N'Bùi Thanh Tùng',    '0938445566', '203', DATEADD(HOUR,8,DATEADD(DAY,-20,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,13,DATEADD(DAY,-20,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), 30, 250000, N'Dọn dẹp cấp tốc 30 phút', 1000000, 3500000, 0, 1, N'Hội thảo khoa học công nghệ', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(HOUR,13,DATEADD(DAY,-20,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-23,GETDATE())),
('SK-2026-007', 3, 15, N'CLB Doanh Nhân Trẻ', '0902334455', NULL,  DATEADD(HOUR,17,DATEADD(DAY,-18,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,22,DATEADD(DAY,-18,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 1000000, 2500000, 0, 1, N'Cocktail Networking Night ngoài trời', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,22,DATEADD(DAY,-18,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-20,GETDATE())),
('SK-2026-008', 4, 2,  N'Trịnh Hồng Quân',   '0909123456', '102', DATEADD(HOUR,14,DATEADD(DAY,-17,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,17,DATEADD(DAY,-17,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 300000, 900000, 0, 1, N'Họp mặt trà đạo nghệ nhân', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,17,DATEADD(DAY,-17,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-19,GETDATE())),
('SK-2026-009', 1, 15, N'Tiệc cưới Hoàng Gia', '0988777111', NULL,  DATEADD(HOUR,11,DATEADD(DAY,-15,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,17,DATEADD(DAY,-15,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 2000000, 6000000, 500000, 1, N'Khách vỡ ly pha lê, bồi thường 500k', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,17,DATEADD(DAY,-15,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-18,GETDATE())),
('SK-2026-010', 2, 5,  N'Lê Tấn Phát',       '0969888999', '202', DATEADD(HOUR,8,DATEADD(DAY,-13,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,12,DATEADD(DAY,-13,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 1000000, 2800000, 0, 1, N'Họp chiến lược kinh doanh', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(HOUR,12,DATEADD(DAY,-13,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-15,GETDATE())),
('SK-2026-011', 3, 15, N'Live Chill Rooftop', '0916334455', NULL,  DATEADD(HOUR,17,DATEADD(DAY,-11,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,22,DATEADD(DAY,-11,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 1000000, 2500000, 0, 1, N'Live Chill Rooftop chào đón thu', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,22,DATEADD(DAY,-11,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-13,GETDATE())),
('SK-2026-012', 1, 15, N'FPT Software Đà Lạt','0908112345', NULL,  DATEADD(HOUR,9,DATEADD(DAY,-9,CAST(CAST(GETDATE() AS DATE) AS DATETIME))),  DATEADD(HOUR,16,DATEADD(DAY,-9,CAST(CAST(GETDATE() AS DATE) AS DATETIME))),  NULL, 0, NULL, 2000000, 7000000, 0, 1, N'Tech Summit nội bộ chi nhánh', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,16,DATEADD(DAY,-9,CAST(CAST(GETDATE() AS DATE) AS DATETIME))),  DATEADD(DAY,-12,GETDATE())),
('SK-2026-013', 2, 12, N'Đỗ Minh Khang',     '0987556677', '403', DATEADD(HOUR,13,DATEADD(DAY,-7,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,18,DATEADD(DAY,-7,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 1000000, 3500000, 0, 1, N'Ký kết hợp đồng dự án phần mềm', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,18,DATEADD(DAY,-7,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-10,GETDATE())),
('SK-2026-014', 1, 15, N'Ngân hàng Vietcombank','0912888999',NULL,  DATEADD(HOUR,10,DATEADD(DAY,-5,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,18,DATEADD(DAY,-5,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 2500000, 8000000, 0, 1, N'Tiệc tri ân khách hàng thân thiết', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,18,DATEADD(DAY,-5,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-8,GETDATE())),
('SK-2026-015', 3, 13, N'Nguyễn Hoàng Long', '0903889900', '501', DATEADD(HOUR,17,DATEADD(DAY,-3,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,21,DATEADD(DAY,-3,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 1000000, 2000000, 0, 1, N'Tiệc mừng thọ gia đình trên sân thượng', N'Thanh toán toàn bộ', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,21,DATEADD(DAY,-3,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-5,GETDATE())),
('SK-2026-016', 4, 10, N'Phạm Quốc Bảo',     '0933444555', '401', DATEADD(HOUR,14,DATEADD(DAY,-2,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,18,DATEADD(DAY,-2,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 400000, 1200000, 0, 1, N'Giao lưu trà đạo nghệ thuật', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(HOUR,18,DATEADD(DAY,-2,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY,-4,GETDATE())),
-- Đơn hủy (1 hoàn cọc, 1 không hoàn cọc)
('SK-2026-017', 1, 15, N'Gala Tri Ân Dược Phẩm','0913998877',NULL, DATEADD(HOUR,16,DATEADD(DAY,-12,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,21,DATEADD(DAY,-12,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 2000000, 5000000, 0, 0, N'Khách hoãn địa điểm sang Hà Nội', N'Đặt cọc trước', N'Đã hủy - Hoàn cọc', DATEADD(DAY,-14,GETDATE()), N'Khách báo hủy trước 2 ngày, hoàn cọc 100%', 1, 2000000, 1, NULL, NULL, DATEADD(DAY,-16,GETDATE())),
('SK-2026-018', 4, 15, N'CLB Thư Pháp Trà Đạo','0914223355',NULL, DATEADD(HOUR,14,DATEADD(DAY,-8,CAST(CAST(GETDATE() AS DATE) AS DATETIME))),  DATEADD(HOUR,18,DATEADD(DAY,-8,CAST(CAST(GETDATE() AS DATE) AS DATETIME))),  NULL, 0, NULL, 300000,  1200000, 0, 0, N'Khách báo hủy đột xuất trước giờ', N'Đặt cọc trước', N'Đã hủy - Không hoàn cọc', DATEADD(HOUR,11,DATEADD(DAY,-8,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), N'Báo hủy sát giờ, mất cọc theo quy định', 2, 0, 2, NULL, NULL, DATEADD(DAY,-10,GETDATE())),
-- Đơn hôm nay (Đang sử dụng)
('SK-2026-019', 2, 15, N'Hội thảo Pháp lý Doanh nghiệp','0914889900',NULL, DATEADD(HOUR,8,CAST(CAST(GETDATE() AS DATE) AS DATETIME)), DATEADD(HOUR,15,CAST(CAST(GETDATE() AS DATE) AS DATETIME)), NULL, 0, NULL, 1000000, 4900000, 0, 0, N'Hội thảo đang diễn ra tại Phòng Hội Nghị B', N'Đặt cọc trước', N'Đang sử dụng', NULL, NULL, NULL, NULL, 1, NULL, NULL, DATEADD(DAY,-1,GETDATE())),
('SK-2026-020', 4, 10, N'Phạm Quốc Bảo',     '0933444555', '401', DATEADD(HOUR,8,CAST(CAST(GETDATE() AS DATE) AS DATETIME)), DATEADD(HOUR,14,CAST(CAST(GETDATE() AS DATE) AS DATETIME)), NULL, 0, NULL, 500000, 1800000, 0, 0, N'Giao lưu trà đạo hôm nay tại Phòng Trà D', N'Đặt cọc trước', N'Đang sử dụng', NULL, NULL, NULL, NULL, 1, NULL, NULL, DATEADD(DAY,-1,GETDATE())),
-- Đơn ngày mai (Đã đặt)
('SK-2026-021', 1, 15, N'Viettel Telecom Hội nghị', '0986112233', NULL, DATEADD(HOUR,8,DATEADD(DAY,1,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,16,DATEADD(DAY,1,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 2000000, 8000000, 0, 0, N'Hội nghị triển khai kế hoạch ngày mai', N'Đặt cọc trước', N'Đã đặt', NULL, NULL, NULL, NULL, 1, NULL, NULL, GETDATE()),
('SK-2026-022', 3, 7,  N'Nguyễn Anh Thư',    '0918777666', '301', DATEADD(HOUR,17,DATEADD(DAY,1,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(HOUR,22,DATEADD(DAY,1,CAST(CAST(GETDATE() AS DATE) AS DATETIME))), NULL, 0, NULL, 1000000, 2500000, 0, 0, N'Tiệc Acoustic tối ngày mai trên Sky Lounge', N'Đặt cọc trước', N'Đã đặt', NULL, NULL, NULL, NULL, 1, NULL, NULL, GETDATE());
GO

-- 7.5 Đơn thuê xe mẫu (20 xe máy: Airblade 1-4, Vision 5-8, Blade 9-12, Sirius 13-16, Yamaha 17-20)
-- 30 đơn hoàn tất quá khứ (Tổng doanh thu = 16.500.000 đ)
INSERT INTO DonThueXe (
    MaDon, XeId, KhachHangId, TenKhach, CCCD, SoDienThoai, SoPhong,
    NgayThue, NgayTraDuKien, NgayTraThucTe,
    ThoiGianKiemTraXePhut, PhuThuRutNganBuffer, GhiChuRutNganBuffer,
    TienCoc, TienThue, ChiPhiPhatSinh, TongTienThanhToan, DaThanhToan,
    GhiChuKhiNhanXe, GhiChuHuHai,
    HinhThucThanhToanBanDau, TrangThaiDon,
    ThoiGianHuy, LyDoHuy, NguoiHuyId, SoTienHoanCoc,
    NguoiTaoId, NguoiThanhToanId, ThoiGianThanhToan, NgayTao
) VALUES
-- Dữ liệu mẫu đã qua (Trước ngày hôm nay -> Đã hoàn tất & thanh toán hết)
('TX-2026-001', 9,  16, N'Nguyễn Văn Khách', '079190001111', '0988112233', NULL,  DATEADD(DAY,-30,GETDATE()), DATEADD(DAY,-27,GETDATE()), DATEADD(DAY,-27,GETDATE()), NULL, 0, NULL, 100000, 240000, 0, 240000, 1, N'Khách thuê Blade Đỏ 3 ngày', N'Xe sạch đẹp, trả đúng hạn', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-27,GETDATE()), DATEADD(DAY,-30,GETDATE())),
('TX-2026-002', 17, 16, N'Lê Hoàng Long',   '079191002222', '0912445566', NULL,  DATEADD(DAY,-27,GETDATE()), DATEADD(DAY,-24,GETDATE()), DATEADD(DAY,-24,GETDATE()), NULL, 0, NULL, 100000, 240000, 0, 240000, 1, N'Khách thuê Yamaha Xanh 3 ngày', N'Xe hoạt động tốt', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(DAY,-24,GETDATE()), DATEADD(DAY,-27,GETDATE())),
('TX-2026-003', 5,  16, N'Phạm Thu Thảo',   '079192003333', '0938119900', NULL,  DATEADD(DAY,-25,GETDATE()), DATEADD(DAY,-22,GETDATE()), DATEADD(DAY,-22,GETDATE()), NULL, 0, NULL, 150000, 300000, 0, 300000, 1, N'Khách thuê Vision Trắng 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-22,GETDATE()), DATEADD(DAY,-25,GETDATE())),
('TX-2026-004', 1,  1,  N'Đoàn Minh Trí',   '079198001234', '0908112233', '101', DATEADD(DAY,-24,GETDATE()), DATEADD(DAY,-21,GETDATE()), DATEADD(DAY,-21,GETDATE()), NULL, 0, NULL, 150000, 300000, 0, 300000, 1, N'Khách thuê Airblade Đen 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-21,GETDATE()), DATEADD(DAY,-24,GETDATE())),
('TX-2026-005', 10, 4,  N'Hoàng Mai Linh',  '079194007788', '0978112244', '201', DATEADD(DAY,-23,GETDATE()), DATEADD(DAY,-20,GETDATE()), DATEADD(DAY,-20,GETDATE()), NULL, 0, NULL, 100000, 240000, 0, 240000, 1, N'Khách thuê Blade Đen 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(DAY,-20,GETDATE()), DATEADD(DAY,-23,GETDATE())),
('TX-2026-006', 2,  5,  N'Lê Tấn Phát',     '079201009876', '0969888999', '202', DATEADD(DAY,-22,GETDATE()), DATEADD(DAY,-19,GETDATE()), DATEADD(DAY,-19,GETDATE()), NULL, 0, NULL, 150000, 300000, 0, 300000, 1, N'Khách thuê Airblade Đỏ 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-19,GETDATE()), DATEADD(DAY,-22,GETDATE())),
('TX-2026-007', 6,  2,  N'Trịnh Hồng Quân', '079192003344', '0909123456', '102', DATEADD(DAY,-21,GETDATE()), DATEADD(DAY,-18,GETDATE()), DATEADD(DAY,-18,GETDATE()), NULL, 0, NULL, 150000, 300000, 0, 300000, 1, N'Khách thuê Vision Đỏ 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(DAY,-18,GETDATE()), DATEADD(DAY,-21,GETDATE())),
('TX-2026-008', 14, 8,  N'Đặng Hải Yến',    '079197003355', '0982334411', '302', DATEADD(DAY,-20,GETDATE()), DATEADD(DAY,-17,GETDATE()), DATEADD(DAY,-17,GETDATE()), NULL, 0, NULL, 100000, 240000, 0, 240000, 1, N'Khách thuê Sirius Đỏ 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-17,GETDATE()), DATEADD(DAY,-20,GETDATE())),
('TX-2026-009', 18, 11, N'Trần Thu Hà',     '079189006677', '0919223344', '402', DATEADD(DAY,-19,GETDATE()), DATEADD(DAY,-16,GETDATE()), DATEADD(DAY,-16,GETDATE()), NULL, 0, NULL, 100000, 240000, 0, 240000, 1, N'Khách thuê Yamaha Đỏ 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(DAY,-16,GETDATE()), DATEADD(DAY,-19,GETDATE())),
('TX-2026-010', 3,  12, N'Đỗ Minh Khang',   '079187008899', '0987556677', '403', DATEADD(DAY,-18,GETDATE()), DATEADD(DAY,-15,GETDATE()), DATEADD(DAY,-15,GETDATE()), NULL, 0, NULL, 150000, 300000, 0, 300000, 1, N'Khách thuê Airblade Xanh 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(DAY,-15,GETDATE()), DATEADD(DAY,-18,GETDATE())),
('TX-2026-011', 15, 14, N'Lê Thị Ngọc Ánh', '079185002345', '0979334455', '502', DATEADD(DAY,-17,GETDATE()), DATEADD(DAY,-14,GETDATE()), DATEADD(DAY,-14,GETDATE()), NULL, 0, NULL, 100000, 240000, 0, 240000, 1, N'Khách thuê Sirius Xanh 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(DAY,-14,GETDATE()), DATEADD(DAY,-17,GETDATE())),
('TX-2026-012', 11, 16, N'Ngô Gia Huy',     '079193004444', '0945223344', NULL,  DATEADD(DAY,-16,GETDATE()), DATEADD(DAY,-13,GETDATE()), DATEADD(DAY,-13,GETDATE()), NULL, 0, NULL, 100000, 240000, 0, 240000, 1, N'Khách thuê Blade Xanh 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-13,GETDATE()), DATEADD(DAY,-16,GETDATE())),
('TX-2026-013', 4,  16, N'Đặng Quốc Tuấn',  '079194005555', '0979887766', NULL,  DATEADD(DAY,-15,GETDATE()), DATEADD(DAY,-12,GETDATE()), DATEADD(DAY,-12,GETDATE()), NULL, 0, NULL, 150000, 300000, 0, 300000, 1, N'Khách thuê Airblade Xám 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-12,GETDATE()), DATEADD(DAY,-15,GETDATE())),
('TX-2026-014', 7,  16, N'Trần Minh Trí',   '079195006666', '0908776655', NULL,  DATEADD(DAY,-14,GETDATE()), DATEADD(DAY,-11,GETDATE()), DATEADD(DAY,-11,GETDATE()), NULL, 0, NULL, 150000, 300000, 0, 300000, 1, N'Khách thuê Vision Xanh 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(DAY,-11,GETDATE()), DATEADD(DAY,-14,GETDATE())),
('TX-2026-015', 16, 16, N'Phan Thanh Bình', '079196008888', '0969888111', NULL,  DATEADD(DAY,-13,GETDATE()), DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-10,GETDATE()), NULL, 0, NULL, 100000, 240000, 0, 240000, 1, N'Khách thuê Sirius Trắng 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-13,GETDATE())),
('TX-2026-016', 20, 16, N'Võ Hoàng Khang',  '079196007777', '0918332211', NULL,  DATEADD(DAY,-12,GETDATE()), DATEADD(DAY,-9,GETDATE()),  DATEADD(DAY,-9,GETDATE()),  NULL, 0, NULL, 100000, 240000, 0, 240000, 1, N'Khách thuê Yamaha Xám 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(DAY,-9,GETDATE()),  DATEADD(DAY,-12,GETDATE())),
('TX-2026-017', 8,  7,  N'Nguyễn Anh Thư',  '079195003456', '0918777666', '301', DATEADD(DAY,-12,GETDATE()), DATEADD(DAY,-8,GETDATE()),  DATEADD(DAY,-8,GETDATE()),  NULL, 0, NULL, 150000, 400000, 0, 400000, 1, N'Khách thuê Vision Đen 4 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-8,GETDATE()),  DATEADD(DAY,-12,GETDATE())),
('TX-2026-018', 12, 3,  N'Vũ Hoàng Nam',    '079193005566', '0912334455', '103', DATEADD(DAY,-11,GETDATE()), DATEADD(DAY,-7,GETDATE()),  DATEADD(DAY,-7,GETDATE()),  NULL, 0, NULL, 100000, 320000, 0, 320000, 1, N'Khách thuê Blade Trắng 4 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-7,GETDATE()),  DATEADD(DAY,-11,GETDATE())),
('TX-2026-019', 1,  13, N'Nguyễn Hoàng Long','079186001234', '0903889900', '501', DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-6,GETDATE()),  DATEADD(DAY,-6,GETDATE()),  NULL, 0, NULL, 150000, 400000, 0, 400000, 1, N'Khách thuê Airblade Đen 4 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-6,GETDATE()),  DATEADD(DAY,-10,GETDATE())),
('TX-2026-020', 5,  6,  N'Bùi Thanh Tùng',  '079196001122', '0938445566', '203', DATEADD(DAY,-9,GETDATE()),  DATEADD(DAY,-5,GETDATE()),  DATEADD(DAY,-5,GETDATE()),  NULL, 0, NULL, 150000, 400000, 0, 400000, 1, N'Khách thuê Vision Trắng 4 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-5,GETDATE()),  DATEADD(DAY,-9,GETDATE())),
('TX-2026-021', 9,  9,  N'Phan Văn Đức',    '079199004466', '0945667788', '303', DATEADD(DAY,-8,GETDATE()),  DATEADD(DAY,-4,GETDATE()),  DATEADD(DAY,-4,GETDATE()),  NULL, 0, NULL, 100000, 320000, 0, 320000, 1, N'Khách thuê Blade Đỏ 4 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-4,GETDATE()),  DATEADD(DAY,-8,GETDATE())),
('TX-2026-022', 17, 16, N'Trần Văn Bình',   '079197008888', '0903112233', NULL,  DATEADD(DAY,-8,GETDATE()),  DATEADD(DAY,-4,GETDATE()),  DATEADD(DAY,-4,GETDATE()),  NULL, 0, NULL, 100000, 320000, 0, 320000, 1, N'Khách thuê Yamaha Xanh 4 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-4,GETDATE()),  DATEADD(DAY,-8,GETDATE())),
('TX-2026-023', 2,  16, N'Đặng Quốc Huy',   '079199003322', '0908332211', NULL,  DATEADD(DAY,-7,GETDATE()),  DATEADD(DAY,-3,GETDATE()),  DATEADD(DAY,-3,GETDATE()),  NULL, 0, NULL, 150000, 400000, 0, 400000, 1, N'Khách thuê Airblade Đỏ 4 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-3,GETDATE()),  DATEADD(DAY,-7,GETDATE())),
('TX-2026-024', 6,  16, N'Vũ Thị Hạnh',     '079192005544', '0937221144', NULL,  DATEADD(DAY,-6,GETDATE()),  DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,-2,GETDATE()),  NULL, 0, NULL, 150000, 400000, 0, 400000, 1, N'Khách thuê Vision Đỏ 4 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,-6,GETDATE())),
('TX-2026-025', 10, 16, N'Ngô Thanh Tùng',  '079193006677', '0914889922', NULL,  DATEADD(DAY,-6,GETDATE()),  DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,-2,GETDATE()),  NULL, 0, NULL, 100000, 320000, 0, 320000, 1, N'Khách thuê Blade Đen 4 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,-6,GETDATE())),
('TX-2026-026', 14, 16, N'Trịnh Văn Nam',   '079194008899', '0903554433', NULL,  DATEADD(DAY,-5,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  NULL, 0, NULL, 100000, 320000, 0, 320000, 1, N'Khách thuê Sirius Đỏ 4 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-5,GETDATE())),
('TX-2026-027', 18, 16, N'Lý Quốc Bảo',     '079195007788', '0918443322', NULL,  DATEADD(DAY,-5,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  NULL, 0, NULL, 100000, 320000, 0, 320000, 1, N'Khách thuê Yamaha Đỏ 4 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-5,GETDATE())),
('TX-2026-028', 3,  16, N'Hồ Minh Tuấn',    '079196009900', '0909665544', NULL,  DATEADD(DAY,-4,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  NULL, 0, NULL, 300000, 300000, 0, 300000, 1, N'Khách thuê Airblade Xanh 3 ngày', N'Xe sạch đẹp', N'Thanh toán toàn bộ', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-4,GETDATE())),
('TX-2026-029', 7,  16, N'Bùi Văn Hùng',    '079198002233', '0908114455', NULL,  DATEADD(DAY,-4,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  NULL, 0, NULL, 150000, 300000, 0, 300000, 1, N'Khách thuê Vision Xanh 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-4,GETDATE())),
('TX-2026-030', 11, 16, N'Phan Văn Hưng',   '079198004455', '0915667788', NULL,  DATEADD(DAY,-4,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  NULL, 0, NULL, 100000, 240000, 0, 240000, 1, N'Khách thuê Blade Xanh 3 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Hoàn tất', NULL, NULL, NULL, NULL, 1, 1, DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,-4,GETDATE())),
-- Đơn hủy (1 hoàn cọc, 1 không hoàn cọc)
('TX-2026-031', 4,  16, N'Võ Thị Thu Thảo', '079197001122', '0916332211', NULL,  DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-7,GETDATE()),  NULL,                       NULL, 0, NULL, 200000, 200000, 0, 0, 0, N'Khách hủy trước 2 ngày', N'Xe sạch đẹp', N'Đặt cọc trước', N'Đã hủy - Hoàn cọc', DATEADD(DAY,-12,GETDATE()), N'Khách hủy trước 2 ngày, hoàn cọc 100%', 1, 150000, 1, NULL, NULL, DATEADD(DAY,-12,GETDATE())),
('TX-2026-032', 15, 16, N'Đặng Văn Long',   '079199009988', '0907119988', NULL,  DATEADD(DAY,-7,GETDATE()),  DATEADD(DAY,-4,GETDATE()),  NULL,                       NULL, 0, NULL, 240000, 240000, 0, 0, 0, N'Khách hủy sát giờ nhận', N'Xe sạch đẹp', N'Đặt cọc trước', N'Đã hủy - Không hoàn cọc', DATEADD(DAY,-7,GETDATE()), N'Hủy sát giờ, mất cọc theo quy định', 1, 0, 1, NULL, NULL, DATEADD(DAY,-8,GETDATE())),
-- Giao dịch thuê xe MỚI Hôm nay (GETDATE()) và Ngày mai (DATEADD(DAY,1,GETDATE()))
('TX-2026-033', 1,  1,  N'Đoàn Minh Trí',   '079198001234', '0908112233', '101', DATEADD(HOUR,-3,GETDATE()), DATEADD(DAY,1,GETDATE()),  NULL,                       NULL, 0, NULL, 100000, 100000, 0, 100000, 0, N'Khách phòng 101 thuê Airblade Đen hôm nay', N'Đang thuê', N'Đặt cọc trước', N'Đang thuê', NULL, NULL, NULL, NULL, 1, NULL, NULL, DATEADD(HOUR,-3,GETDATE())),
('TX-2026-034', 6,  2,  N'Trịnh Hồng Quân', '079192003344', '0909123456', '102', DATEADD(HOUR,-2,GETDATE()), DATEADD(DAY,2,GETDATE()),  NULL,                       NULL, 0, NULL, 150000, 200000, 0, 200000, 0, N'Khách phòng 102 thuê Vision Đỏ hôm nay', N'Đang thuê', N'Đặt cọc trước', N'Đang thuê', NULL, NULL, NULL, NULL, 2, NULL, NULL, DATEADD(HOUR,-2,GETDATE())),
('TX-2026-035', 7,  3,  N'Vũ Hoàng Nam',    '079193005566', '0912334455', '103', DATEADD(HOUR,-4,GETDATE()), DATEADD(DAY,3,GETDATE()),  NULL,                       NULL, 0, NULL, 150000, 300000, 0, 300000, 0, N'Khách phòng 103 thuê Vision Xanh hôm nay', N'Đang thuê', N'Đặt cọc trước', N'Đang thuê', NULL, NULL, NULL, NULL, 1, NULL, NULL, DATEADD(HOUR,-4,GETDATE())),
('TX-2026-036', 10, 8,  N'Đặng Hải Yến',    '079197003355', '0982334411', '302', DATEADD(HOUR,-3,GETDATE()), DATEADD(DAY,2,GETDATE()),  NULL,                       NULL, 0, NULL, 100000, 160000, 0, 160000, 0, N'Khách phòng 302 thuê Blade Đen hôm nay', N'Đang thuê', N'Đặt cọc trước', N'Đang thuê', NULL, NULL, NULL, NULL, 2, NULL, NULL, DATEADD(HOUR,-3,GETDATE())),
('TX-2026-037', 2,  5,  N'Lê Tấn Phát',     '079201009876', '0969888999', '202', DATEADD(HOUR,-1,GETDATE()), DATEADD(DAY,2,GETDATE()),  NULL,                       NULL, 0, NULL, 150000, 200000, 0, 200000, 0, N'Khách phòng 202 thuê Airblade Đỏ hôm nay', N'Đang thuê', N'Đặt cọc trước', N'Đang thuê', NULL, NULL, NULL, NULL, 1, NULL, NULL, DATEADD(HOUR,-1,GETDATE())),
('TX-2026-038', 15, 14, N'Lê Thị Ngọc Ánh', '079185002345', '0979334455', '502', DATEADD(HOUR,-5,GETDATE()), DATEADD(HOUR,-1,GETDATE()), DATEADD(HOUR,-1,GETDATE()), NULL, 0, NULL, 80000, 80000, 0, 80000, 1, N'Khách phòng 502 thuê Sirius Xanh', N'Đã trả xe sáng nay', N'Thanh toán toàn bộ', N'Hoàn tất', NULL, NULL, NULL, NULL, 2, 2, DATEADD(HOUR,-1,GETDATE()), DATEADD(HOUR,-5,GETDATE())),
('TX-2026-039', 8,  4,  N'Hoàng Mai Linh',  '079194007788', '0978112244', '201', DATEADD(DAY,1,GETDATE()),   DATEADD(DAY,3,GETDATE()),  NULL,                       NULL, 0, NULL, 150000, 200000, 0, 200000, 0, N'Khách phòng 201 đặt thuê Vision Đen ngày mai', N'Xe sạch đẹp', N'Đặt cọc trước', N'Đã đặt', NULL, NULL, NULL, NULL, 1, NULL, NULL, GETDATE()),
('TX-2026-040', 9,  6,  N'Bùi Thanh Tùng',  '079196001122', '0938445566', '203', DATEADD(DAY,1,GETDATE()),   DATEADD(DAY,4,GETDATE()),  NULL,                       NULL, 0, NULL, 100000, 240000, 0, 240000, 0, N'Khách phòng 203 đặt thuê Blade Đỏ ngày mai', N'Xe sạch đẹp', N'Đặt cọc trước', N'Đã đặt', NULL, NULL, NULL, NULL, 1, NULL, NULL, GETDATE()),
('TX-2026-041', 5,  7,  N'Nguyễn Anh Thư',  '079195003456', '0918777666', '301', DATEADD(DAY,1,GETDATE()),   DATEADD(DAY,3,GETDATE()),  NULL,                       NULL, 0, NULL, 200000, 200000, 0, 200000, 1, N'Khách phòng 301 đặt thuê Vision Trắng ngày mai', N'Xe sạch đẹp', N'Thanh toán toàn bộ', N'Đã đặt', NULL, NULL, NULL, NULL, 1, 1, GETDATE(), GETDATE()),
('TX-2026-042', 17, 11, N'Trần Thu Hà',     '079189006677', '0919223344', '402', DATEADD(DAY,1,GETDATE()),   DATEADD(DAY,3,GETDATE()),  NULL,                       NULL, 0, NULL, 100000, 160000, 0, 160000, 0, N'Khách phòng 402 đặt thuê Yamaha Xanh ngày mai', N'Xe sạch đẹp', N'Đặt cọc trước', N'Đã đặt', NULL, NULL, NULL, NULL, 2, NULL, NULL, GETDATE());
GO

-- 7.6 Bãi đỗ xe mẫu (24 lượt gửi quá khứ đã thanh toán, tổng doanh thu = 5.200.000 đ; kèm các xe đang gửi hôm nay)
INSERT INTO BaiDoXe (MaVe, BienSoXe, LoaiXe, TenKhach, SoDienThoai, SoPhong, ThoiGianVao, ThoiGianRa, HinhThucGui, PhiGui, DaThanhToan, GhiChuSuaChua, NguoiTaoId, NguoiThanhToanId, ThoiGianThanhToan) VALUES
-- Dữ liệu mẫu đã qua (Trước ngày hôm nay -> Đã rời bãi & thanh toán hết)
('VE-DX-001', '49A-123.45', N'Ô tô',  N'Trần Văn An',        '0912345678', NULL,  DATEADD(DAY,-15,GETDATE()),DATEADD(DAY,-12,GETDATE()),N'Theo ngày',  300000, 1, NULL, 1, 1, DATEADD(DAY,-12,GETDATE())),
('VE-DX-002', '59-X1 888.88', N'Xe máy',N'Lê Thị Bình',        '0987654321', NULL,  DATEADD(DAY,-14,GETDATE()),DATEADD(DAY,-12,GETDATE()),N'Theo ngày',  30000,  1, NULL, 2, 2, DATEADD(DAY,-12,GETDATE())),
('VE-DX-003', '60B-456.78', N'Ô tô',  N'Nguyễn Văn Cường',   '0933112233', NULL,  DATEADD(DAY,-13,GETDATE()),DATEADD(DAY,-10,GETDATE()),N'Theo ngày',  300000, 1, NULL, 1, 1, DATEADD(DAY,-10,GETDATE())),
('VE-DX-004', '49B-999.11', N'Xe máy',N'Phạm Minh Đức',      '0908223344', NULL,  DATEADD(DAY,-12,GETDATE()),DATEADD(DAY,-10,GETDATE()),N'Theo ngày',  30000,  1, NULL, 3, 3, DATEADD(DAY,-10,GETDATE())),
('VE-DX-005', '51F-777.99', N'Ô tô',  N'Vũ Hoàng Khang',     '0919334455', NULL,  DATEADD(DAY,-11,GETDATE()),DATEADD(DAY,-9,GETDATE()), N'Theo ngày',  200000, 1, NULL, 1, 1, DATEADD(DAY,-9,GETDATE())),
('VE-DX-006', '59-Z2 333.22', N'Xe máy',N'Khách vãng lai A',   '0900112233', NULL,  DATEADD(DAY,-10,GETDATE()),DATEADD(DAY,-9,GETDATE()), N'Theo lượt',  15000,  1, NULL, 2, 2, DATEADD(DAY,-9,GETDATE())),
('VE-DX-007', '51G-111.22', N'Ô tô',  N'Nguyễn Thành Đạt',   '0933444111', NULL,  DATEADD(DAY,-9,GETDATE()), DATEADD(DAY,-7,GETDATE()), N'Theo ngày',  200000, 1, NULL, 2, 2, DATEADD(DAY,-7,GETDATE())),
('VE-DX-008', '49A-222.33', N'Ô tô',  N'Lê Quang Vinh',      '0912334111', NULL,  DATEADD(DAY,-8,GETDATE()), DATEADD(DAY,-6,GETDATE()), N'Theo ngày',  200000, 1, NULL, 1, 1, DATEADD(DAY,-6,GETDATE())),
('VE-DX-009', '29B-333.44', N'Ô tô',  N'Hoàng Gia Bảo',      '0903889111', NULL,  DATEADD(DAY,-8,GETDATE()), DATEADD(DAY,-5,GETDATE()), N'Theo ngày',  300000, 1, NULL, 3, 3, DATEADD(DAY,-5,GETDATE())),
('VE-DX-010', '59-S3 444.11', N'Xe máy',N'Phan Thanh Bình',    '0969888111', NULL,  DATEADD(DAY,-7,GETDATE()), DATEADD(DAY,-6,GETDATE()), N'Theo lượt',  15000,  1, NULL, 1, 1, DATEADD(DAY,-6,GETDATE())),
('VE-DX-011', '60A-998.22', N'Ô tô',  N'Hoàng Trọng Khôi',   '0908771122', NULL,  DATEADD(DAY,-6,GETDATE()), DATEADD(DAY,-4,GETDATE()), N'Theo ngày',  200000, 1, NULL, 2, 2, DATEADD(DAY,-4,GETDATE())),
('VE-DX-012', '49-M1 555.66', N'Xe máy',N'Nguyễn Văn Khách',   '0988112233', NULL,  DATEADD(DAY,-6,GETDATE()), DATEADD(DAY,-5,GETDATE()), N'Theo lượt',  10000,  1, NULL, 1, 1, DATEADD(DAY,-5,GETDATE())),
('VE-DX-013', '59-A1 999.88', N'Xe máy',N'Khách vãng lai B',   '0900111222', NULL,  DATEADD(DAY,-5,GETDATE()), DATEADD(DAY,-4,GETDATE()), N'Theo lượt',  10000,  1, NULL, 2, 2, DATEADD(DAY,-4,GETDATE())),
('VE-DX-014', '51H-234.56', N'Ô tô',  N'Trần Văn Nam',       '0938112299', NULL,  DATEADD(DAY,-5,GETDATE()), DATEADD(DAY,-2,GETDATE()), N'Theo ngày',  300000, 1, NULL, 1, 1, DATEADD(DAY,-2,GETDATE())),
('VE-DX-015', '49A-333.88', N'Ô tô',  N'Đặng Quốc Huy',      '0908332211', NULL,  DATEADD(DAY,-4,GETDATE()), DATEADD(DAY,-2,GETDATE()), N'Theo ngày',  200000, 1, NULL, 1, 1, DATEADD(DAY,-2,GETDATE())),
('VE-DX-016', '51G-444.99', N'Ô tô',  N'Ngô Thanh Tùng',     '0914889922', NULL,  DATEADD(DAY,-4,GETDATE()), DATEADD(DAY,-1,GETDATE()), N'Theo ngày',  300000, 1, NULL, 2, 2, DATEADD(DAY,-1,GETDATE())),
('VE-DX-017', '60A-555.11', N'Ô tô',  N'Vũ Thị Hạnh',        '0937221144', NULL,  DATEADD(DAY,-3,GETDATE()), DATEADD(DAY,-1,GETDATE()), N'Theo ngày',  200000, 1, NULL, 1, 1, DATEADD(DAY,-1,GETDATE())),
('VE-DX-018', '29B-666.22', N'Ô tô',  N'Trịnh Văn Nam',      '0903554433', NULL,  DATEADD(DAY,-3,GETDATE()), DATEADD(HOUR,-6,GETDATE()),N'Theo ngày',  300000, 1, NULL, 2, 2, DATEADD(HOUR,-6,GETDATE())),
('VE-DX-019', '51F-888.33', N'Ô tô',  N'Hồ Minh Tuấn',       '0909665544', NULL,  DATEADD(DAY,-2,GETDATE()), DATEADD(HOUR,-4,GETDATE()),N'Theo ngày',  200000, 1, NULL, 1, 1, DATEADD(HOUR,-4,GETDATE())),
('VE-DX-020', '49A-999.44', N'Ô tô',  N'Bùi Văn Hùng',       '0908114455', NULL,  DATEADD(DAY,-2,GETDATE()), DATEADD(HOUR,-3,GETDATE()),N'Theo ngày',  200000, 1, NULL, 3, 3, DATEADD(HOUR,-3,GETDATE())),
('VE-DX-021', '60B-111.55', N'Ô tô',  N'Phan Văn Hưng',      '0915667788', NULL,  DATEADD(DAY,-1,GETDATE()), DATEADD(HOUR,-2,GETDATE()),N'Theo tiếng', 150000, 1, NULL, 1, 1, DATEADD(HOUR,-2,GETDATE())),
('VE-DX-022', '51K-222.66', N'Ô tô',  N'Lý Quốc Bảo',        '0918443322', NULL,  DATEADD(DAY,-1,GETDATE()), DATEADD(HOUR,-1,GETDATE()),N'Theo tiếng', 150000, 1, NULL, 2, 2, DATEADD(HOUR,-1,GETDATE())),
('VE-DX-023', '29B-777.88', N'Ô tô',  N'Đinh Văn Toàn',      '0908667788', NULL,  DATEADD(DAY,-1,GETDATE()), DATEADD(MINUTE,-30,GETDATE()),N'Theo ngày',200000, 1, NULL, 1, 1, DATEADD(MINUTE,-30,GETDATE())),
('VE-DX-024', '49-B1 777.99', N'Xe máy',N'Lâm Chấn Huy',      '0988223344', NULL,  DATEADD(DAY,-1,GETDATE()), DATEADD(MINUTE,-15,GETDATE()),N'Theo ngày',20000,  1, NULL, 1, 1, DATEADD(MINUTE,-15,GETDATE())),
-- Giao dịch bãi đỗ xe MỚI Hôm nay (GETDATE())
-- Xe miễn phí của khách đang ở phòng (ThoiGianRa IS NULL)
('VE-DX-025', '51G-123.45', N'Ô tô',  N'Phạm Quốc Bảo',      '0933444555', '401', DATEADD(HOUR,-5,GETDATE()), NULL,                      N'Khách phòng (Miễn phí)', 0,     1, NULL, 2, 2, DATEADD(HOUR,-5,GETDATE())),
('VE-DX-026', '49A-567.89', N'Ô tô',  N'Vũ Hoàng Nam',       '0912334455', '103', DATEADD(HOUR,-6,GETDATE()), NULL,                      N'Khách phòng (Miễn phí)', 0,     1, NULL, 1, 1, DATEADD(HOUR,-6,GETDATE())),
('VE-DX-027', '29B-888.99', N'Ô tô',  N'Nguyễn Hoàng Long',  '0903889900', '501', DATEADD(HOUR,-4,GETDATE()), NULL,                      N'Khách phòng (Miễn phí)', 0,     1, NULL, 3, 3, DATEADD(HOUR,-4,GETDATE())),
('VE-DX-028', '59-S3 888.11', N'Xe máy',N'Lê Tấn Phát',        '0969888999', '202', DATEADD(HOUR,-3,GETDATE()), NULL,                      N'Khách phòng (Miễn phí)', 0,     1, NULL, 1, 1, DATEADD(HOUR,-3,GETDATE())),
-- Xe khách vãng lai đang gửi trong bãi (ThoiGianRa IS NULL)
('VE-DX-029', '60A-686.86', N'Ô tô',  N'Đinh Văn Toàn',      '0908667788', NULL,  DATEADD(HOUR,-2,GETDATE()), NULL,                      N'Theo tiếng',             100000,0, NULL, 2, NULL, NULL),
('VE-DX-030', '49-B1 666.88', N'Xe máy',N'Lâm Chấn Huy',       '0988223344', NULL,  DATEADD(MINUTE,-75,GETDATE()),NULL,                    N'Theo lượt',              5000,  0, NULL, 1, NULL, NULL),
-- Xe vãng lai đã thanh toán xuất bến sáng nay
('VE-DX-031', '51K-999.68', N'Ô tô',  N'Trương Minh Phú',    '0918223399', NULL,  DATEADD(HOUR,-4,GETDATE()), DATEADD(HOUR,-1,GETDATE()),N'Theo tiếng',             150000,1, N'Khách dự hội thảo sáng nay', 1, 1, DATEADD(HOUR,-1,GETDATE()));
GO

-- 7.7 Đơn giặt ủi mẫu (24 đơn hoàn tất quá khứ, tổng doanh thu = 7.300.000 đ; kèm các đơn mới hôm nay & ngày mai)
-- Đảm bảo: Tất cả các đơn Đang giặt / Hoàn tất ĐỀU CÓ DoiTacId và NgayGiaoDoiTac!
INSERT INTO DonGiatUi (MaDon, KhachHangId, TenKhach, SoDienThoai, SoPhong, DoiTacId, LoaiDichVu, KhoiLuongKg, DonGiaKg, TongTienThuKhach, TienKhachSanNhan, TienDoiTacNhan, TinhTrangQuanAoLucNhan, NgayNhan, NgayGiaoDoiTac, NgayHenTra, NgayTraThucTe, HinhThucThanhToan, TrangThai, DaThanhToan, NguoiTaoId, NguoiThanhToanId, ThoiGianThanhToan, CoDenBu, BenChiuTrachNhiem, SoTienDenBu, LyDoDenBu, NgayGhiNhanDenBu, NguoiGhiNhanDenBuId) VALUES
-- Dữ liệu mẫu đã qua (Trước ngày hôm nay -> Đã hoàn tất & thanh toán hết)
('DH-GU-001', 1,  N'Đoàn Minh Trí',     '0908112233', '101', 1,    N'Giặt sấy thông thường', 6.0, 30000, 180000, 54000,  126000, N'Đồ du lịch gia đình',         DATEADD(DAY,-25,GETDATE()),DATEADD(DAY,-25,GETDATE()),DATEADD(DAY,-24,GETDATE()),DATEADD(DAY,-24,GETDATE()),N'Thanh toán trực tiếp', N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-24,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-002', 3,  N'Vũ Hoàng Nam',      '0912334455', '103', 2,    N'Giặt hấp cao cấp',     4.0, 80000, 320000, 112000, 208000, N'Áo măng tô dạ hội',        DATEADD(DAY,-23,GETDATE()),DATEADD(DAY,-23,GETDATE()),DATEADD(DAY,-22,GETDATE()),DATEADD(DAY,-22,GETDATE()),N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 2, 2, DATEADD(DAY,-22,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-003', 7,  N'Nguyễn Anh Thư',    '0918777666', '301', 1,    N'Ủi phẳng',              5.0, 40000, 200000, 60000,  140000, N'10 váy lụa nhẹ',            DATEADD(DAY,-22,GETDATE()),DATEADD(DAY,-22,GETDATE()),DATEADD(DAY,-21,GETDATE()),DATEADD(DAY,-21,GETDATE()),N'Thanh toán trực tiếp', N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-21,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-004', 5,  N'Lê Tấn Phát',       '0969888999', '202', 1,    N'Giặt sấy thông thường', 8.0, 30000, 240000, 72000,  168000, N'Quần áo thể thao',          DATEADD(DAY,-20,GETDATE()),DATEADD(DAY,-20,GETDATE()),DATEADD(DAY,-19,GETDATE()),DATEADD(DAY,-19,GETDATE()),N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 3, 3, DATEADD(DAY,-19,GETDATE()), 1, N'DoiTac', 100000, N'Tiệm giặt làm phai cúc áo, đã bồi thường 100k', DATEADD(DAY,-19,GETDATE()), 1),
('DH-GU-005', 4,  N'Hoàng Mai Linh',    '0978112244', '201', NULL, N'Giặt sấy thông thường', 2.0, 30000,  60000,  60000,  0,      N'Khách đổi ý nhận lại tự giặt',DATEADD(DAY,-19,GETDATE()),NULL,                      DATEADD(DAY,-18,GETDATE()),NULL,                      N'Thanh toán trực tiếp', N'Đã hủy',   0, 1, NULL, NULL,                     0, NULL, 0, NULL, NULL, NULL),
('DH-GU-006', 9,  N'Phan Văn Đức',      '0945667788', '303', 2,    N'Giặt hấp cao cấp',     5.0, 80000, 400000, 140000, 260000, N'3 bộ vest dự hội thảo',     DATEADD(DAY,-18,GETDATE()),DATEADD(DAY,-18,GETDATE()),DATEADD(DAY,-17,GETDATE()),DATEADD(DAY,-17,GETDATE()),N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 2, 2, DATEADD(DAY,-17,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-007', 6,  N'Bùi Thanh Tùng',    '0938445566', '203', 1,    N'Giặt sấy thông thường', 7.0, 30000, 210000, 63000,  147000, N'Đồ cotton gia đình đoàn',   DATEADD(DAY,-17,GETDATE()),DATEADD(DAY,-17,GETDATE()),DATEADD(DAY,-16,GETDATE()),DATEADD(DAY,-16,GETDATE()),N'Thanh toán trực tiếp', N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-16,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-008', 8,  N'Đặng Hải Yến',      '0982334411', '302', 2,    N'Giặt hấp cao cấp',     3.5, 80000, 280000, 98000,  182000, N'Đầm lụa dạ hội',            DATEADD(DAY,-16,GETDATE()),DATEADD(DAY,-16,GETDATE()),DATEADD(DAY,-15,GETDATE()),DATEADD(DAY,-15,GETDATE()),N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 2, 2, DATEADD(DAY,-15,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-009', 11, N'Trần Thu Hà',       '0919223344', '402', 1,    N'Ủi phẳng',              6.0, 40000, 240000, 72000,  168000, N'12 áo sơ mi công sở',       DATEADD(DAY,-15,GETDATE()),DATEADD(DAY,-15,GETDATE()),DATEADD(DAY,-14,GETDATE()),DATEADD(DAY,-14,GETDATE()),N'Thanh toán trực tiếp', N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-14,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-010', 12, N'Đỗ Minh Khang',     '0987556677', '403', 1,    N'Giặt sấy thông thường', 6.0, 30000, 180000, 54000,  126000, N'Đồ phượt xe máy',          DATEADD(DAY,-14,GETDATE()),DATEADD(DAY,-14,GETDATE()),DATEADD(DAY,-13,GETDATE()),DATEADD(DAY,-13,GETDATE()),N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 2, 2, DATEADD(DAY,-13,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-011', 1,  N'Đoàn Minh Trí',     '0908112233', '101', 2,    N'Giặt hấp cao cấp',     4.0, 80000, 320000, 112000, 208000, N'Áo sơ mi lụa + 2 vest',     DATEADD(DAY,-13,GETDATE()),DATEADD(DAY,-13,GETDATE()),DATEADD(DAY,-12,GETDATE()),DATEADD(DAY,-12,GETDATE()),N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-12,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-012', 5,  N'Lê Tấn Phát',       '0969888999', '202', 1,    N'Giặt sấy thông thường', 7.0, 30000, 210000, 63000,  147000, N'Đồ thể thao đi phượt',     DATEADD(DAY,-12,GETDATE()),DATEADD(DAY,-12,GETDATE()),DATEADD(DAY,-11,GETDATE()),DATEADD(DAY,-11,GETDATE()),N'Thanh toán trực tiếp', N'Hoàn tất', 1, 2, 2, DATEADD(DAY,-11,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-013', 3,  N'Vũ Hoàng Nam',      '0912334455', '103', 2,    N'Giặt hấp cao cấp',     4.5, 80000, 360000, 126000, 234000, N'2 áo măng tô dạ dày',       DATEADD(DAY,-11,GETDATE()),DATEADD(DAY,-11,GETDATE()),DATEADD(DAY,-10,GETDATE()),DATEADD(DAY,-10,GETDATE()),N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 3, 3, DATEADD(DAY,-10,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-014', 4,  N'Hoàng Mai Linh',    '0978112244', '201', 1,    N'Giặt sấy thông thường', 5.0, 30000, 150000, 45000,  105000, N'Váy hoa mùa hè',           DATEADD(DAY,-10,GETDATE()),DATEADD(DAY,-10,GETDATE()),DATEADD(DAY,-9,GETDATE()), DATEADD(DAY,-9,GETDATE()), N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-9,GETDATE()),  0, NULL, 0, NULL, NULL, NULL),
('DH-GU-015', 6,  N'Bùi Thanh Tùng',    '0938445566', '203', 1,    N'Giặt sấy thông thường', 8.0, 30000, 240000, 72000,  168000, N'Quần áo ngủ + áo khoác',   DATEADD(DAY,-9,GETDATE()), DATEADD(DAY,-9,GETDATE()), DATEADD(DAY,-8,GETDATE()), DATEADD(DAY,-8,GETDATE()), N'Thanh toán trực tiếp', N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-8,GETDATE()),  0, NULL, 0, NULL, NULL, NULL),
('DH-GU-016', 8,  N'Đặng Hải Yến',      '0982334411', '302', 2,    N'Giặt hấp cao cấp',     3.5, 80000, 280000, 98000,  182000, N'Đầm lụa tơ tằm',           DATEADD(DAY,-8,GETDATE()), DATEADD(DAY,-8,GETDATE()), DATEADD(DAY,-7,GETDATE()), DATEADD(DAY,-7,GETDATE()), N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 2, 2, DATEADD(DAY,-7,GETDATE()),  0, NULL, 0, NULL, NULL, NULL),
('DH-GU-017', 9,  N'Phan Văn Đức',      '0945667788', '303', 1,    N'Giặt sấy thông thường', 7.0, 30000, 210000, 63000,  147000, N'Đồ gia đình du lịch',      DATEADD(DAY,-7,GETDATE()), DATEADD(DAY,-7,GETDATE()), DATEADD(DAY,-6,GETDATE()), DATEADD(DAY,-6,GETDATE()), N'Thanh toán trực tiếp', N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-6,GETDATE()),  0, NULL, 0, NULL, NULL, NULL),
('DH-GU-018', 13, N'Nguyễn Hoàng Long', '0903889900', '501', 1,    N'Ủi phẳng',              5.0, 40000, 200000, 60000,  140000, N'Áo sơ mi đoàn công tác',   DATEADD(DAY,-6,GETDATE()), DATEADD(DAY,-6,GETDATE()), DATEADD(DAY,-5,GETDATE()), DATEADD(DAY,-5,GETDATE()), N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 2, 2, DATEADD(DAY,-5,GETDATE()),  0, NULL, 0, NULL, NULL, NULL),
('DH-GU-019', 2,  N'Trịnh Hồng Quân',   '0909123456', '102', 1,    N'Ủi phẳng',              6.0, 40000, 240000, 72000,  168000, N'12 áo sơ mi công sở',       DATEADD(DAY,-5,GETDATE()), DATEADD(DAY,-5,GETDATE()), DATEADD(DAY,-4,GETDATE()), DATEADD(DAY,-4,GETDATE()), N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-4,GETDATE()),  0, NULL, 0, NULL, NULL, NULL),
('DH-GU-020', 7,  N'Nguyễn Anh Thư',    '0918777666', '301', 2,    N'Giặt hấp cao cấp',     5.0, 80000, 400000, 140000, 260000, N'Váy dạ hội trắng honeymoon',DATEADD(DAY,-4,GETDATE()), DATEADD(DAY,-4,GETDATE()), DATEADD(DAY,-3,GETDATE()), DATEADD(DAY,-3,GETDATE()), N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 2, 2, DATEADD(DAY,-3,GETDATE()),  0, NULL, 0, NULL, NULL, NULL),
('DH-GU-021', 10, N'Phạm Quốc Bảo',     '0933444555', '401', 2,    N'Giặt hấp cao cấp',     6.0, 80000, 480000, 168000, 312000, N'2 bộ vest cao cấp họp VIP', DATEADD(DAY,-4,GETDATE()), DATEADD(DAY,-4,GETDATE()), DATEADD(DAY,-3,GETDATE()), DATEADD(DAY,-3,GETDATE()), N'Thanh toán trực tiếp', N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-3,GETDATE()),  0, NULL, 0, NULL, NULL, NULL),
('DH-GU-022', 14, N'Lê Thị Ngọc Ánh',   '0979334455', '502', 1,    N'Giặt sấy thông thường', 6.0, 30000, 180000, 54000,  126000, N'Đồ len mỏng + khăn quàng',  DATEADD(DAY,-3,GETDATE()), DATEADD(DAY,-3,GETDATE()), DATEADD(DAY,-2,GETDATE()), DATEADD(DAY,-2,GETDATE()), N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 2, 2, DATEADD(DAY,-2,GETDATE()),  0, NULL, 0, NULL, NULL, NULL),
('DH-GU-023', 11, N'Trần Thu Hà',       '0919223344', '402', 1,    N'Giặt sấy thông thường', 5.0, 30000, 150000, 45000,  105000, N'Quần áo ngủ + áo khoác gió',DATEADD(DAY,-2,GETDATE()), DATEADD(DAY,-2,GETDATE()), DATEADD(DAY,-1,GETDATE()), DATEADD(DAY,-1,GETDATE()), N'Thanh toán trực tiếp', N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-1,GETDATE()),  0, NULL, 0, NULL, NULL, NULL),
('DH-GU-024', 12, N'Đỗ Minh Khang',     '0987556677', '403', 1,    N'Giặt sấy thông thường', 6.0, 30000, 180000, 54000,  126000, N'Đồ phượt xe máy',          DATEADD(DAY,-2,GETDATE()), DATEADD(DAY,-2,GETDATE()), DATEADD(DAY,-1,GETDATE()), DATEADD(DAY,-1,GETDATE()), N'Ghi nợ vào phòng',   N'Hoàn tất', 1, 1, 1, DATEADD(DAY,-1,GETDATE()),  0, NULL, 0, NULL, NULL, NULL),
-- Giao dịch giặt ủi MỚI Hôm nay (GETDATE()) và Ngày mai (DATEADD(DAY,1,GETDATE()))
('DH-GU-025', 1,  N'Đoàn Minh Trí',     '0908112233', '101', NULL, N'Giặt hấp cao cấp',     2.0, 80000, 160000, 160000, 0,      N'Áo sơ mi lụa + quần tây (Mới nhận)',          DATEADD(HOUR,-2,GETDATE()), NULL,                      DATEADD(DAY,1,GETDATE()),   NULL,                      N'Ghi nợ vào phòng',   N'Chờ giao đối tác', 0, 1, NULL, NULL, 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-026', 5,  N'Lê Tấn Phát',       '0969888999', '202', NULL, N'Giặt sấy thông thường', 3.5, 30000, 105000, 105000, 0,      N'Đồ thể thao đi phượt (Chờ gom tiệm)',         DATEADD(HOUR,-1,GETDATE()), NULL,                      DATEADD(DAY,1,GETDATE()),   NULL,                      N'Thanh toán trực tiếp', N'Chờ giao đối tác', 1, 2, 2, DATEADD(HOUR,-1,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-027', 3,  N'Vũ Hoàng Nam',      '0912334455', '103', 2,    N'Giặt hấp cao cấp',     2.5, 80000, 200000, 70000,  130000, N'Áo măng tô dạ (Hẹn trả ngày mai)',            DATEADD(HOUR,-4,GETDATE()), DATEADD(HOUR,-3,GETDATE()), DATEADD(DAY,1,GETDATE()),   NULL,                      N'Ghi nợ vào phòng',   N'Đang giặt',        0, 3, NULL, NULL, 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-028', 4,  N'Hoàng Mai Linh',    '0978112244', '201', 1,    N'Giặt sấy thông thường', 3.0, 30000,  90000, 27000,  63000,  N'Váy hoa mùa hè (Đang giặt)',                  DATEADD(HOUR,-3,GETDATE()), DATEADD(HOUR,-2,GETDATE()), DATEADD(HOUR,5,GETDATE()),  NULL,                      N'Ghi nợ vào phòng',   N'Đang giặt',        0, 1, NULL, NULL, 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-029', 6,  N'Bùi Thanh Tùng',    '0938445566', '203', 1,    N'Giặt sấy thông thường', 4.0, 30000, 120000, 36000,  84000,  N'Quần áo ngủ + áo khoác gió (Đang giặt)',       DATEADD(HOUR,-5,GETDATE()), DATEADD(HOUR,-4,GETDATE()), DATEADD(HOUR,2,GETDATE()),  NULL,                      N'Thanh toán trực tiếp', N'Đang giặt',        1, 1, 1, DATEADD(HOUR,-5,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-030', 8,  N'Đặng Hải Yến',      '0982334411', '302', 2,    N'Giặt hấp cao cấp',     1.5, 80000, 120000, 42000,  78000,  N'Đầm lụa tơ tằm (Đang giặt)',                  DATEADD(HOUR,-4,GETDATE()), DATEADD(HOUR,-3,GETDATE()), DATEADD(HOUR,2,GETDATE()),  NULL,                      N'Ghi nợ vào phòng',   N'Đang giặt',        0, 2, NULL, NULL, 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-031', 9,  N'Phan Văn Đức',      '0945667788', '303', 1,    N'Giặt sấy thông thường', 3.0, 30000,  90000, 27000,  63000,  N'Quần áo du lịch gia đình (Hoàn tất hôm nay)',  DATEADD(HOUR,-6,GETDATE()), DATEADD(HOUR,-5,GETDATE()), DATEADD(HOUR,-1,GETDATE()), DATEADD(HOUR,-1,GETDATE()), N'Thanh toán trực tiếp', N'Hoàn tất',         1, 1, 1, DATEADD(HOUR,-1,GETDATE()), 0, NULL, 0, NULL, NULL, NULL),
('DH-GU-032', 13, N'Nguyễn Hoàng Long', '0903889900', '501', NULL, N'Ủi phẳng',              2.5, 40000, 100000, 35000,  65000,  N'Bộ vest hội nghị ngày mai',                    DATEADD(DAY,1,GETDATE()),   NULL,                       DATEADD(DAY,2,GETDATE()),   NULL,                      N'Ghi nợ vào phòng',   N'Chờ giao đối tác', 0, 1, NULL, NULL, 0, NULL, 0, NULL, NULL, NULL);
GO

-- Tự động chạy thủ tục quyết toán dữ liệu quá khứ và đồng bộ ca trực
EXEC sp_TuDongQuyetToanDuLieuCu;
GO
