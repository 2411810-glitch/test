/* =================================================================================
   HỆ THỐNG QUẢN LÝ DỊCH VỤ KHÁCH SẠN (DALAT HOTEL) - SQL SERVER
   FILE 3: Trigger.sql - CÁC TRÌNH KÍCH HOẠT TỰ ĐỘNG HÓA NGHIỆP VỤ (TRIGGERS)
   Thứ tự chạy: 1. Table.sql -> 2. Views.sql -> 3. Trigger.sql -> 4. Procedures.sql -> 5. Data.sql
   ================================================================================= */

USE QuanLyDichVuKhachSan;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 4.1 Trigger tự động cộng tồn kho và cập nhật giá vốn bình quân khi nhập kho
IF OBJECT_ID('trg_ChiTietPhieuNhapKho_CongTonKho', 'TR') IS NOT NULL
    DROP TRIGGER trg_ChiTietPhieuNhapKho_CongTonKho;
GO
CREATE TRIGGER trg_ChiTietPhieuNhapKho_CongTonKho
ON ChiTietPhieuNhapKho
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ma
    SET
        ma.GiaVonBinhQuan = CASE
            WHEN (ma.SoLuongTonKho + ins.TongSoLuongNhapMoi) > 0 THEN
                ((ma.SoLuongTonKho * ma.GiaVonBinhQuan) + ins.TongGiaTriNhapMoi)
                / (ma.SoLuongTonKho + ins.TongSoLuongNhapMoi)
            ELSE ma.GiaVonBinhQuan
        END,
        ma.SoLuongTonKho = ma.SoLuongTonKho + ins.TongSoLuongNhapMoi,
        ma.TrangThai     = CASE
            WHEN ma.TrangThai = N'Ngừng kinh doanh' THEN N'Ngừng kinh doanh'
            ELSE N'Còn hàng'
        END
    FROM MonAn ma
    JOIN (
        SELECT MonAnId,
               SUM(SoLuongNhap * HeSoQuyDoi) AS TongSoLuongNhapMoi,
               SUM(SoLuongNhap * DonGiaNhap) AS TongGiaTriNhapMoi
        FROM inserted
        GROUP BY MonAnId
    ) ins ON ma.Id = ins.MonAnId;

    UPDATE pnk
    SET TongTien = (
        SELECT ISNULL(SUM(ThanhTien), 0)
        FROM ChiTietPhieuNhapKho
        WHERE PhieuNhapId = pnk.Id
    )
    FROM PhieuNhapKho pnk
    WHERE pnk.Id IN (SELECT DISTINCT PhieuNhapId FROM inserted);
END;
GO

-- 4.2 Trigger tự động hoàn trả tồn kho khi Đơn hàng ăn uống chuyển sang trạng thái 'Đã hủy'
IF OBJECT_ID('trg_DonHangMonAn_HoanTonKhoKhiHuy', 'TR') IS NOT NULL
    DROP TRIGGER trg_DonHangMonAn_HoanTonKhoKhiHuy;
GO
CREATE TRIGGER trg_DonHangMonAn_HoanTonKhoKhiHuy
ON DonHangMonAn
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(TrangThai)
    BEGIN
        ;WITH DonMoiHuy AS (
            SELECT i.Id AS DonHangId
            FROM inserted i
            JOIN deleted d ON i.Id = d.Id
            WHERE i.TrangThai = N'Đã hủy' AND d.TrangThai <> N'Đã hủy'
        ),
        SoLuongHoan AS (
            SELECT ct.MonAnId, SUM(ct.SoLuong) AS TongHoan
            FROM ChiTietDonHangMonAn ct
            JOIN DonMoiHuy dh ON ct.DonHangId = dh.DonHangId
            GROUP BY ct.MonAnId
        )
        UPDATE ma
        SET ma.SoLuongTonKho = ma.SoLuongTonKho + h.TongHoan,
            ma.TrangThai = CASE
                WHEN ma.TrangThai = N'Hết hàng' AND (ma.SoLuongTonKho + h.TongHoan) > 0 THEN N'Còn hàng'
                ELSE ma.TrangThai
            END
        FROM MonAn ma
        JOIN SoLuongHoan h ON ma.Id = h.MonAnId;
    END
END;
GO

-- 4.3 Trigger tự động tính tiền giặt ủi: khóa giá bán lúc nhận (kèm ChiPhiPhatSinh), khóa giá vốn khi gán đối tác
IF OBJECT_ID('trg_DonGiatUi_TinhTien', 'TR') IS NOT NULL DROP TRIGGER trg_DonGiatUi_TinhTien;
GO
CREATE TRIGGER trg_DonGiatUi_TinhTien
ON DonGiatUi
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    IF UPDATE(KhoiLuongKg) OR UPDATE(DonGiaKg) OR UPDATE(DoiTacId) OR UPDATE(DonGiaVonKg) OR UPDATE(ChiPhiPhatSinh)
    BEGIN
        UPDATE d
        SET 
            TongTienThuKhach = (i.KhoiLuongKg * i.DonGiaKg) + ISNULL(i.ChiPhiPhatSinh, 0),
            DonGiaVonKg = CASE 
                WHEN i.DoiTacId IS NULL THEN NULL
                WHEN i.DonGiaVonKg IS NOT NULL THEN i.DonGiaVonKg
                ELSE ISNULL(bg.DonGiaVonKg, i.DonGiaKg * (ISNULL(dt.TyLeDoiTacHuong, 70.0) / 100.0))
            END,
            TienDoiTacNhan = CASE 
                WHEN i.DoiTacId IS NULL THEN 0
                ELSE i.KhoiLuongKg * CASE 
                    WHEN i.DonGiaVonKg IS NOT NULL THEN i.DonGiaVonKg
                    ELSE ISNULL(bg.DonGiaVonKg, i.DonGiaKg * (ISNULL(dt.TyLeDoiTacHuong, 70.0) / 100.0))
                END
            END,
            TienKhachSanNhan = ((i.KhoiLuongKg * i.DonGiaKg) + ISNULL(i.ChiPhiPhatSinh, 0)) - CASE 
                WHEN i.DoiTacId IS NULL THEN 0
                ELSE i.KhoiLuongKg * CASE 
                    WHEN i.DonGiaVonKg IS NOT NULL THEN i.DonGiaVonKg
                    ELSE ISNULL(bg.DonGiaVonKg, i.DonGiaKg * (ISNULL(dt.TyLeDoiTacHuong, 70.0) / 100.0))
                END
            END
        FROM DonGiatUi d
        JOIN inserted i ON d.Id = i.Id
        LEFT JOIN DoiTacGiatUi dt ON dt.Id = i.DoiTacId
        LEFT JOIN LoaiDichVuGiatUi ldv ON (ldv.TenLoai = i.LoaiDichVu OR ldv.MaLoai = i.LoaiDichVu)
        LEFT JOIN BangGiaDoiTacGiatUi bg ON (bg.DoiTacId = i.DoiTacId AND bg.LoaiDichVuId = ldv.Id);
    END
END;
GO

-- 4.4 Trigger kiểm tra giá vốn đối tác báo phải nhỏ hơn giá niêm yết của khách sạn (đảm bảo luôn có lợi nhuận)
IF OBJECT_ID('trg_BangGiaDoiTac_KiemTraGiaVon', 'TR') IS NOT NULL DROP TRIGGER trg_BangGiaDoiTac_KiemTraGiaVon;
GO
CREATE TRIGGER trg_BangGiaDoiTac_KiemTraGiaVon
ON BangGiaDoiTacGiatUi
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN LoaiDichVuGiatUi ldv ON ldv.Id = i.LoaiDichVuId
        WHERE i.DonGiaVonKg >= ldv.DonGiaBanKg
    )
    BEGIN
        RAISERROR(N'Giá vốn của đối tác báo (DonGiaVonKg) phải nhỏ hơn giá niêm yết bán cho khách (DonGiaBanKg) để khách sạn có lợi nhuận!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- 4.5 Trigger chống 2 đơn đặt sảnh chồng/sát giờ nhau cùng 1 khu vực (bao gồm khoảng đệm dọn dẹp)
IF OBJECT_ID('trg_DonDatSuKien_ChongTrungLich', 'TR') IS NOT NULL DROP TRIGGER trg_DonDatSuKien_ChongTrungLich;
GO
CREATE TRIGGER trg_DonDatSuKien_ChongTrungLich
ON DonDatSuKien
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT (UPDATE(KhuVucId) OR UPDATE(ThoiGianBatDau) OR UPDATE(ThoiGianKetThuc)
            OR UPDATE(TrangThaiDon) OR UPDATE(ThoiGianDonDepPhut))
        RETURN;

    DECLARE @BufferMacDinh INT = ISNULL(
        (SELECT CAST(GiaTri AS INT) FROM ThamSoHeThong WHERE MaThamSo = 'EVENT_CLEANING_BUFFER_MINUTES'), 60);

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN DonDatSuKien d
            ON d.KhuVucId = i.KhuVucId
           AND d.Id <> i.Id
           AND d.TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')
        WHERE i.TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')
          AND i.ThoiGianBatDau < DATEADD(MINUTE, ISNULL(d.ThoiGianDonDepPhut, @BufferMacDinh), d.ThoiGianKetThuc)
          AND d.ThoiGianBatDau < DATEADD(MINUTE, ISNULL(i.ThoiGianDonDepPhut, @BufferMacDinh), i.ThoiGianKetThuc)
    )
    BEGIN
        RAISERROR(N'Khung giờ bị trùng hoặc chưa đủ thời gian dọn dẹp với 1 đơn khác đã đặt cho cùng khu vực này.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 4.6 Trigger chống 2 đơn thuê cùng 1 xe bị chồng/sát giờ nhau (xét theo thời điểm trả thực tế ISNULL(NgayTraThucTe, NgayTraDuKien) + thời gian kiểm tra kỹ thuật)
IF OBJECT_ID('trg_DonThueXe_ChongTrungLich', 'TR') IS NOT NULL DROP TRIGGER trg_DonThueXe_ChongTrungLich;
GO
CREATE TRIGGER trg_DonThueXe_ChongTrungLich
ON DonThueXe
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT (UPDATE(XeId) OR UPDATE(NgayThue) OR UPDATE(NgayTraDuKien) OR UPDATE(NgayTraThucTe)
            OR UPDATE(TrangThaiDon) OR UPDATE(ThoiGianKiemTraXePhut))
        RETURN;

    DECLARE @BufferMacDinh INT = ISNULL(
        (SELECT CAST(GiaTri AS INT) FROM ThamSoHeThong WHERE MaThamSo = 'VEHICLE_CLEANING_BUFFER_MINUTES'), 30);

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN DonThueXe d
            ON d.XeId = i.XeId
           AND d.Id <> i.Id
           AND d.TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')
        WHERE i.TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')
          AND i.NgayThue < DATEADD(MINUTE, ISNULL(d.ThoiGianKiemTraXePhut, @BufferMacDinh), ISNULL(d.NgayTraThucTe, d.NgayTraDuKien))
          AND d.NgayThue < DATEADD(MINUTE, ISNULL(i.ThoiGianKiemTraXePhut, @BufferMacDinh), ISNULL(i.NgayTraThucTe, i.NgayTraDuKien))
    )
    BEGIN
        RAISERROR(N'Khung thời gian thuê bị trùng hoặc chưa đủ thời gian kiểm tra/vệ sinh với 1 đơn khác đã đặt cho cùng xe này.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 4.7 Các Trigger đảm bảo tính toàn vẹn: Đơn đã hủy không được ghi nhận DaThanhToan = 1 (trừ Không hoàn cọc)
IF OBJECT_ID('trg_DonDatSuKien_KiemTraHuy', 'TR') IS NOT NULL DROP TRIGGER trg_DonDatSuKien_KiemTraHuy;
GO
CREATE TRIGGER trg_DonDatSuKien_KiemTraHuy
ON DonDatSuKien
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE d
    SET DaThanhToan = 0
    FROM DonDatSuKien d
    JOIN inserted i ON d.Id = i.Id
    WHERE i.TrangThaiDon LIKE N'Đã hủy%' AND d.DaThanhToan = 1;
END;
GO

IF OBJECT_ID('trg_DonThueXe_KiemTraHuy', 'TR') IS NOT NULL DROP TRIGGER trg_DonThueXe_KiemTraHuy;
GO
CREATE TRIGGER trg_DonThueXe_KiemTraHuy
ON DonThueXe
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE d
    SET DaThanhToan = 0
    FROM DonThueXe d
    JOIN inserted i ON d.Id = i.Id
    WHERE i.TrangThaiDon LIKE N'Đã hủy%' AND d.DaThanhToan = 1;
END;
GO

IF OBJECT_ID('trg_DonHangMonAn_KiemTraHuy', 'TR') IS NOT NULL DROP TRIGGER trg_DonHangMonAn_KiemTraHuy;
GO
CREATE TRIGGER trg_DonHangMonAn_KiemTraHuy
ON DonHangMonAn
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE d
    SET DaThanhToan = 0
    FROM DonHangMonAn d
    JOIN inserted i ON d.Id = i.Id
    WHERE i.TrangThai = N'Đã hủy' AND d.DaThanhToan = 1;
END;
GO

IF OBJECT_ID('trg_DonGiatUi_KiemTraHuy', 'TR') IS NOT NULL DROP TRIGGER trg_DonGiatUi_KiemTraHuy;
GO
CREATE TRIGGER trg_DonGiatUi_KiemTraHuy
ON DonGiatUi
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE d
    SET DaThanhToan = 0
    FROM DonGiatUi d
    JOIN inserted i ON d.Id = i.Id
    WHERE i.TrangThai = N'Đã hủy' AND d.DaThanhToan = 1;
END;
GO
