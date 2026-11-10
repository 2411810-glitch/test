/* =================================================================================
   HỆ THỐNG QUẢN LÝ DỊCH VỤ KHÁCH SẠN (DALAT HOTEL) - SQL SERVER
   FILE 2: Views.sql - CÁC KHUNG NHÌN TỔNG HỢP & GIÁM SÁT THỜI GIAN THỰC (VIEWS)
   Thứ tự chạy: 1. Table.sql -> 2. Views.sql -> 3. Trigger.sql -> 4. Procedures.sql -> 5. Data.sql
   ================================================================================= */

USE QuanLyDichVuKhachSan;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 3.0 View tương thích ngược DonDatXeChoThue -> DonThueXe
IF OBJECT_ID('DonDatXeChoThue', 'V') IS NOT NULL DROP VIEW DonDatXeChoThue;
GO
CREATE VIEW DonDatXeChoThue AS
SELECT * FROM DonThueXe;
GO

-- 3.1 View dịch vụ chưa thanh toán theo phòng (Ghi nợ phòng cần thu lúc Check-out)
-- Đã bổ sung PhuThuRutNganDonDep (Sự kiện) và PhuThuRutNganBuffer (Thuê xe) vào công nợ phải thu
IF OBJECT_ID('vw_DichVuChuaThanhToanTheoPhong', 'V') IS NOT NULL DROP VIEW vw_DichVuChuaThanhToanTheoPhong;
GO
CREATE VIEW vw_DichVuChuaThanhToanTheoPhong AS
SELECT SoPhong, N'Ẩm thực' AS LoaiDichVu, MaDon, TongTien AS SoTien, NgayTao AS ThoiGian
FROM DonHangMonAn
WHERE DaThanhToan = 0 AND TrangThai <> N'Đã hủy' AND (HinhThucThanhToan = N'Ghi nợ vào phòng' OR HinhThucThanhToan = N'Tính chung tiền phòng')
UNION ALL
SELECT SoPhong, N'Sự kiện', MaDon, (TongTienDuKien + ChiPhiPhatSinh + ISNULL(PhuThuRutNganDonDep, 0) - TienCoc), NgayTao
FROM DonDatSuKien
WHERE DaThanhToan = 0 AND SoPhong IS NOT NULL
  AND TrangThaiDon NOT LIKE N'Đã hủy%'
  AND ThoiGianBatDau <= GETDATE()
UNION ALL
SELECT SoPhong, N'Thuê xe', MaDon, (TienThue + ChiPhiPhatSinh + ISNULL(PhuThuRutNganBuffer, 0) - TienCoc), NgayTao
FROM DonThueXe
WHERE DaThanhToan = 0 AND SoPhong IS NOT NULL
  AND TrangThaiDon NOT LIKE N'Đã hủy%'
  AND NgayThue <= GETDATE()
UNION ALL
SELECT SoPhong, N'Bãi đỗ xe', MaVe, PhiGui, ThoiGianVao
FROM BaiDoXe
WHERE DaThanhToan = 0 AND SoPhong IS NOT NULL AND PhiGui > 0
UNION ALL
SELECT SoPhong, N'Giặt ủi', MaDon, TongTienThuKhach, NgayNhan
FROM DonGiatUi
WHERE DaThanhToan = 0 AND SoPhong IS NOT NULL AND TrangThai <> N'Đã hủy';
GO

-- 3.2 View thống kê doanh thu theo dịch vụ
-- Đã chuẩn hóa: Cộng phụ thu rút ngắn thời gian dọn dẹp/kiểm tra xe, và ghi nhận đúng phần Tiền cọc giữ lại đối với đơn "Đã hủy - Không hoàn cọc"
IF OBJECT_ID('vw_DoanhThuTheoDichVu', 'V') IS NOT NULL DROP VIEW vw_DoanhThuTheoDichVu;
GO
CREATE VIEW vw_DoanhThuTheoDichVu AS
SELECT N'Ăn Uống' AS TenDichVu, COUNT(Id) AS SoGiaoDich, ISNULL(SUM(TongTien),0) AS DoanhThu, NgayTao AS Ngay
FROM DonHangMonAn
WHERE DaThanhToan = 1 AND TrangThai <> N'Đã hủy'
GROUP BY NgayTao
UNION ALL
SELECT N'Sảnh & Sự Kiện', COUNT(Id),
       ISNULL(SUM(CASE
           WHEN TrangThaiDon = N'Đã hủy - Không hoàn cọc' THEN TienCoc
           WHEN TrangThaiDon LIKE N'Đã hủy%' THEN 0
           ELSE (TongTienDuKien + ChiPhiPhatSinh + ISNULL(PhuThuRutNganDonDep, 0))
       END), 0),
       NgayTao
FROM DonDatSuKien
WHERE (DaThanhToan = 1 OR TrangThaiDon = N'Đã hủy - Không hoàn cọc')
  AND TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy')
GROUP BY NgayTao
UNION ALL
SELECT N'Cho Thuê Xe Máy', COUNT(Id),
       ISNULL(SUM(CASE
           WHEN TrangThaiDon = N'Đã hủy - Không hoàn cọc' THEN TienCoc
           WHEN TrangThaiDon LIKE N'Đã hủy%' THEN 0
           ELSE (TienThue + ChiPhiPhatSinh + ISNULL(PhuThuRutNganBuffer, 0))
       END), 0),
       NgayTao
FROM DonThueXe
WHERE (DaThanhToan = 1 OR TrangThaiDon = N'Đã hủy - Không hoàn cọc')
  AND TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy')
GROUP BY NgayTao
UNION ALL
SELECT N'Bãi & Hầm Đỗ Xe', COUNT(Id), ISNULL(SUM(PhiGui),0), ThoiGianVao
FROM BaiDoXe
WHERE DaThanhToan = 1 AND PhiGui > 0
GROUP BY ThoiGianVao
UNION ALL
SELECT N'Giặt Ủi' AS TenDichVu, COUNT(Id) AS SoGiaoDich, ISNULL(SUM(TongTienThuKhach),0) AS DoanhThu, NgayNhan AS Ngay
FROM DonGiatUi
WHERE DaThanhToan = 1 AND TrangThai <> N'Đã hủy'
GROUP BY NgayNhan;
GO

-- 3.3 Trạng thái Trống / Đang sử dụng / Đang dọn của từng Khu vực sự kiện tại thời điểm hiện tại (Tính động theo GETDATE())
IF OBJECT_ID('vw_TrangThaiKhuVucHienTai', 'V') IS NOT NULL DROP VIEW vw_TrangThaiKhuVucHienTai;
GO
CREATE VIEW vw_TrangThaiKhuVucHienTai AS
SELECT kv.Id AS KhuVucId, kv.TenKhuVuc, kv.TrangThai AS TrangThaiKhaiThac,
    CASE
        WHEN kv.TrangThai = N'Ngừng khai thác' THEN N'Ngừng khai thác'
        WHEN dangDung.Id IS NOT NULL THEN N'Đang sử dụng'
        WHEN dangDon.Id IS NOT NULL THEN N'Đang dọn'
        ELSE N'Trống'
    END AS TrangThaiHienTai
FROM KhuVucSuKien kv
OUTER APPLY (
    SELECT TOP 1 d.Id FROM DonDatSuKien d
    WHERE d.KhuVucId = kv.Id AND d.TrangThaiDon = N'Đang sử dụng'
      AND GETDATE() BETWEEN d.ThoiGianBatDau AND d.ThoiGianKetThuc
) dangDung
OUTER APPLY (
    SELECT TOP 1 d.Id FROM DonDatSuKien d
    WHERE d.KhuVucId = kv.Id
      AND d.TrangThaiDon IN (N'Đang sử dụng', N'Hoàn tất')
      AND GETDATE() >= d.ThoiGianKetThuc
      AND GETDATE() < DATEADD(MINUTE, ISNULL(d.ThoiGianDonDepPhut,
            ISNULL((SELECT CAST(GiaTri AS INT) FROM ThamSoHeThong WHERE MaThamSo='EVENT_CLEANING_BUFFER_MINUTES'), 60)),
            d.ThoiGianKetThuc)
) dangDon;
GO

-- 3.4 Cảnh báo các đơn sự kiện sắp hết giờ thuê (dùng tham số EVENT_ADVANCE_ALERT_MINUTES)
IF OBJECT_ID('vw_SuKienSapHetGio', 'V') IS NOT NULL DROP VIEW vw_SuKienSapHetGio;
GO
CREATE VIEW vw_SuKienSapHetGio AS
SELECT d.Id, d.MaDon, d.KhuVucId, kv.TenKhuVuc, d.TenKhach, d.ThoiGianKetThuc,
       DATEDIFF(MINUTE, GETDATE(), d.ThoiGianKetThuc) AS SoPhutConLai
FROM DonDatSuKien d
JOIN KhuVucSuKien kv ON kv.Id = d.KhuVucId
WHERE d.TrangThaiDon = N'Đang sử dụng'
  AND d.ThoiGianKetThuc BETWEEN GETDATE() AND DATEADD(MINUTE,
        ISNULL((SELECT CAST(GiaTri AS INT) FROM ThamSoHeThong WHERE MaThamSo='EVENT_ADVANCE_ALERT_MINUTES'), 15),
        GETDATE());
GO

-- 3.5 Trạng thái Sẵn sàng / Đang thuê / Đang vệ sinh kiểm tra của từng Xe tại thời điểm hiện tại (Tính động theo GETDATE())
IF OBJECT_ID('vw_TrangThaiXeHienTai', 'V') IS NOT NULL DROP VIEW vw_TrangThaiXeHienTai;
GO
CREATE VIEW vw_TrangThaiXeHienTai AS
SELECT x.Id AS XeId, x.BienSo, x.TenXe, x.LoaiXe, x.GiaThueNgay, x.TienCocQuyDinh,
       x.TrangThai AS TrangThaiKhaiThac,
       CASE
           WHEN x.TrangThai IN (N'Bảo trì', N'Ngừng khai thác') THEN x.TrangThai
           WHEN dangThue.Id IS NOT NULL THEN N'Đang thuê'
           WHEN dangKiemTra.Id IS NOT NULL THEN N'Đang vệ sinh / kiểm tra'
           ELSE N'Sẵn sàng'
       END AS TrangThaiHienTai
FROM XeChoThue x
OUTER APPLY (
    SELECT TOP 1 d.Id FROM DonThueXe d
    WHERE d.XeId = x.Id AND d.TrangThaiDon = N'Đang thuê'
      AND GETDATE() >= d.NgayThue AND (d.NgayTraThucTe IS NULL OR d.NgayTraThucTe > GETDATE())
) dangThue
OUTER APPLY (
    SELECT TOP 1 d.Id FROM DonThueXe d
    WHERE d.XeId = x.Id
      AND d.TrangThaiDon IN (N'Đang thuê', N'Hoàn tất')
      AND GETDATE() >= ISNULL(d.NgayTraThucTe, d.NgayTraDuKien)
      AND GETDATE() < DATEADD(MINUTE, ISNULL(d.ThoiGianKiemTraXePhut,
            ISNULL((SELECT CAST(GiaTri AS INT) FROM ThamSoHeThong WHERE MaThamSo='VEHICLE_CLEANING_BUFFER_MINUTES'), 30)),
            ISNULL(d.NgayTraThucTe, d.NgayTraDuKien))
) dangKiemTra;
GO

-- 3.6 Cảnh báo các đơn thuê xe sắp đến giờ trả xe (dùng tham số VEHICLE_ADVANCE_ALERT_MINUTES)
IF OBJECT_ID('vw_XeSapHetGioThue', 'V') IS NOT NULL DROP VIEW vw_XeSapHetGioThue;
GO
CREATE VIEW vw_XeSapHetGioThue AS
SELECT d.Id, d.MaDon, d.XeId, x.BienSo, x.TenXe, d.TenKhach, d.SoDienThoai, d.SoPhong, d.NgayTraDuKien,
       DATEDIFF(MINUTE, GETDATE(), d.NgayTraDuKien) AS SoPhutConLai
FROM DonThueXe d
JOIN XeChoThue x ON x.Id = d.XeId
WHERE d.TrangThaiDon = N'Đang thuê'
  AND d.NgayTraThucTe IS NULL
  AND d.NgayTraDuKien BETWEEN GETDATE() AND DATEADD(MINUTE,
        ISNULL((SELECT CAST(GiaTri AS INT) FROM ThamSoHeThong WHERE MaThamSo='VEHICLE_ADVANCE_ALERT_MINUTES'), 30),
        GETDATE());
GO

-- 3.7 Cảnh báo các đơn sự kiện quá giờ hẹn kết thúc từ 15 phút trở lên mà chưa hoàn tất
IF OBJECT_ID('vw_SuKienQuaHan', 'V') IS NOT NULL DROP VIEW vw_SuKienQuaHan;
GO
CREATE VIEW vw_SuKienQuaHan AS
SELECT d.Id, d.MaDon, d.KhuVucId, kv.TenKhuVuc, d.TenKhach, d.SoDienThoai, d.SoPhong, d.ThoiGianKetThuc,
       DATEDIFF(MINUTE, d.ThoiGianKetThuc, GETDATE()) AS SoPhutQuaHan
FROM DonDatSuKien d
JOIN KhuVucSuKien kv ON kv.Id = d.KhuVucId
WHERE d.TrangThaiDon = N'Đang sử dụng'
  AND GETDATE() >= DATEADD(MINUTE, 15, d.ThoiGianKetThuc);
GO

-- 3.8 Cảnh báo các đơn thuê xe quá giờ hẹn trả từ 30 phút trở lên mà chưa trả xe, quyết toán
IF OBJECT_ID('vw_XeThueQuaHan', 'V') IS NOT NULL DROP VIEW vw_XeThueQuaHan;
GO
CREATE VIEW vw_XeThueQuaHan AS
SELECT d.Id, d.MaDon, d.XeId, x.BienSo, x.TenXe, d.TenKhach, d.SoDienThoai, d.SoPhong, d.NgayTraDuKien,
       DATEDIFF(MINUTE, d.NgayTraDuKien, GETDATE()) AS SoPhutQuaHan
FROM DonThueXe d
JOIN XeChoThue x ON x.Id = d.XeId
WHERE d.TrangThaiDon = N'Đang thuê'
  AND d.NgayTraThucTe IS NULL
  AND GETDATE() >= DATEADD(MINUTE, 30, d.NgayTraDuKien);
GO
