/* =================================================================================
   HỆ THỐNG QUẢN LÝ DỊCH VỤ KHÁCH SẠN (DALAT HOTEL) - SQL SERVER
   FILE 4: Procedures.sql - CÁC THỦ TỤC LƯU TRỮ XỬ LÝ NGHIỆP VỤ (STORED PROCEDURES)
   Thứ tự chạy: 1. Table.sql -> 2. Views.sql -> 3. Trigger.sql -> 4. Procedures.sql -> 5. Data.sql
   ================================================================================= */

USE QuanLyDichVuKhachSan;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 5.1 Tính tổng tiền dịch vụ CHƯA thanh toán của 1 phòng (dùng lúc Check-out)
IF OBJECT_ID('sp_TinhTongDichVuChuaThanhToanTheoPhong', 'P') IS NOT NULL
    DROP PROCEDURE sp_TinhTongDichVuChuaThanhToanTheoPhong;
GO
CREATE PROCEDURE sp_TinhTongDichVuChuaThanhToanTheoPhong
    @SoPhong NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM PhongKhachSan WHERE SoPhong = @SoPhong)
    BEGIN
        RAISERROR(N'Không tìm thấy phòng %s trong hệ thống.', 16, 1, @SoPhong);
        RETURN;
    END

    SELECT * FROM vw_DichVuChuaThanhToanTheoPhong
    WHERE SoPhong = @SoPhong
    ORDER BY ThoiGian;

    SELECT
        @SoPhong AS SoPhong,
        COUNT(*) AS SoDichVuChuaThanhToan,
        ISNULL(SUM(SoTien), 0) AS TongTienPhaiThu
    FROM vw_DichVuChuaThanhToanTheoPhong
    WHERE SoPhong = @SoPhong;
END;
GO

-- 5.2 Xác nhận đã thu tiền toàn bộ dịch vụ của 1 phòng (gọi khi Check-out)
IF OBJECT_ID('sp_XacNhanThanhToanDichVuTheoPhong', 'P') IS NOT NULL
    DROP PROCEDURE sp_XacNhanThanhToanDichVuTheoPhong;
GO
CREATE PROCEDURE sp_XacNhanThanhToanDichVuTheoPhong
    @SoPhong NVARCHAR(20),
    @NhanVienThanhToanId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM NhanVien WHERE Id = @NhanVienThanhToanId AND TrangThai = N'Đang làm việc')
    BEGIN
        RAISERROR(N'Nhân viên xác nhận thanh toán không hợp lệ hoặc đã nghỉ việc.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Now DATETIME = GETDATE();

        UPDATE DonHangMonAn SET DaThanhToan = 1, NguoiThanhToanId = @NhanVienThanhToanId, ThoiGianThanhToan = @Now
        WHERE SoPhong = @SoPhong AND DaThanhToan = 0 AND TrangThai <> N'Đã hủy'
          AND (HinhThucThanhToan = N'Ghi nợ vào phòng' OR HinhThucThanhToan = N'Tính chung tiền phòng');

        UPDATE DonDatSuKien SET DaThanhToan = 1, NguoiThanhToanId = @NhanVienThanhToanId, ThoiGianThanhToan = @Now
        WHERE SoPhong = @SoPhong AND DaThanhToan = 0
          AND TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')
          AND ThoiGianBatDau <= @Now;

        UPDATE DonThueXe SET DaThanhToan = 1, NguoiThanhToanId = @NhanVienThanhToanId, ThoiGianThanhToan = @Now
        WHERE SoPhong = @SoPhong AND DaThanhToan = 0
          AND TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')
          AND NgayThue <= @Now;

        UPDATE BaiDoXe SET DaThanhToan = 1, NguoiThanhToanId = @NhanVienThanhToanId, ThoiGianThanhToan = @Now
        WHERE SoPhong = @SoPhong AND DaThanhToan = 0;

        UPDATE DonGiatUi SET DaThanhToan = 1, NguoiThanhToanId = @NhanVienThanhToanId, ThoiGianThanhToan = @Now
        WHERE SoPhong = @SoPhong AND DaThanhToan = 0 AND TrangThai != N'Đã hủy';

        COMMIT TRANSACTION;

        SELECT N'Đã xác nhận thanh toán toàn bộ dịch vụ của phòng ' + @SoPhong
               + N' bởi nhân viên #' + CAST(@NhanVienThanhToanId AS NVARCHAR(10)) AS KetQua;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 5.3 Xác nhận thanh toán 1 đơn lẻ (Thanh toán trực tiếp tại quầy / Khách vãng lai)
-- Đã bổ sung kiểm tra loại trừ đơn đã hủy và tự động cập nhật ThoiGianRa cho vé gửi xe khi thanh toán xuất bãi
IF OBJECT_ID('sp_XacNhanThanhToanDonLe', 'P') IS NOT NULL DROP PROCEDURE sp_XacNhanThanhToanDonLe;
GO
CREATE PROCEDURE sp_XacNhanThanhToanDonLe
    @LoaiDichVu NVARCHAR(20),
    @MaDon NVARCHAR(30),
    @NhanVienThanhToanId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM NhanVien WHERE Id = @NhanVienThanhToanId AND TrangThai = N'Đang làm việc')
    BEGIN
        RAISERROR(N'Nhân viên xác nhận thanh toán không hợp lệ hoặc đã nghỉ việc.', 16, 1);
        RETURN;
    END

    DECLARE @Now DATETIME = GETDATE();

    IF @LoaiDichVu = 'AnUong'
        UPDATE DonHangMonAn SET DaThanhToan = 1, NguoiThanhToanId = @NhanVienThanhToanId, ThoiGianThanhToan = @Now
        WHERE MaDon = @MaDon AND DaThanhToan = 0 AND TrangThai <> N'Đã hủy';
    ELSE IF @LoaiDichVu = 'SuKien'
        UPDATE DonDatSuKien SET DaThanhToan = 1, NguoiThanhToanId = @NhanVienThanhToanId, ThoiGianThanhToan = @Now
        WHERE MaDon = @MaDon AND DaThanhToan = 0 AND TrangThaiDon NOT LIKE N'Đã hủy%';
    ELSE IF @LoaiDichVu = 'ThueXe'
        UPDATE DonThueXe SET DaThanhToan = 1, NguoiThanhToanId = @NhanVienThanhToanId, ThoiGianThanhToan = @Now
        WHERE MaDon = @MaDon AND DaThanhToan = 0 AND TrangThaiDon NOT LIKE N'Đã hủy%';
    ELSE IF @LoaiDichVu = 'DoXe'
        UPDATE BaiDoXe SET DaThanhToan = 1, ThoiGianRa = ISNULL(ThoiGianRa, @Now), NguoiThanhToanId = @NhanVienThanhToanId, ThoiGianThanhToan = @Now
        WHERE MaVe = @MaDon AND DaThanhToan = 0;
    ELSE IF @LoaiDichVu = 'GiatUi'
        UPDATE DonGiatUi SET DaThanhToan = 1, NguoiThanhToanId = @NhanVienThanhToanId, ThoiGianThanhToan = @Now
        WHERE MaDon = @MaDon AND DaThanhToan = 0 AND TrangThai != N'Đã hủy';
    ELSE
        RAISERROR(N'Loại dịch vụ không hợp lệ.', 16, 1);

    SELECT @@ROWCOUNT AS SoDongDaCapNhat;
END;
GO

-- 5.4 Trả phòng khách sạn
IF OBJECT_ID('sp_TraPhong', 'P') IS NOT NULL DROP PROCEDURE sp_TraPhong;
GO
CREATE PROCEDURE sp_TraPhong
    @SoPhong NVARCHAR(20),
    @KetQua INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ConNo INT;

    SELECT @ConNo = COUNT(*) FROM vw_DichVuChuaThanhToanTheoPhong WHERE SoPhong = @SoPhong;

    IF @ConNo > 0
    BEGIN
        SET @KetQua = 0;
        RETURN;
    END

    UPDATE PhongKhachSan
    SET TrangThai = N'Đang dọn', TenKhach = NULL, SoDienThoai = NULL, CCCD = NULL,
        GhiChu = NULL, NgayNhanPhong = NULL, NgayTraPhong = NULL
    WHERE SoPhong = @SoPhong;

    SET @KetQua = 1;
END;
GO

-- 5.5 Lập phiếu nhập kho
IF OBJECT_ID('sp_LapPhieuNhapKho', 'P') IS NOT NULL DROP PROCEDURE sp_LapPhieuNhapKho;
GO
CREATE PROCEDURE sp_LapPhieuNhapKho
    @MaPhieuNhap NVARCHAR(50),
    @NhaCungCapId INT,
    @NguoiNhapId INT,
    @GhiChu NVARCHAR(255) = NULL,
    @ChiTiet kieu_ChiTietNhapKho READONLY,
    @PhieuNhapId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM @ChiTiet)
        BEGIN
            RAISERROR(N'Phiếu nhập phải có ít nhất 1 dòng hàng.', 16, 1); RETURN;
        END

        BEGIN TRANSACTION;

        INSERT INTO PhieuNhapKho (MaPhieuNhap, NhaCungCapId, NguoiNhapId, GhiChu)
        VALUES (@MaPhieuNhap, @NhaCungCapId, @NguoiNhapId, @GhiChu);

        SET @PhieuNhapId = SCOPE_IDENTITY();

        INSERT INTO ChiTietPhieuNhapKho
            (PhieuNhapId, MonAnId, DonViNhap, HeSoQuyDoi, SoLuongNhap, DonGiaNhap, SoLo, HanSuDung, GhiChu)
        SELECT @PhieuNhapId, MonAnId, DonViNhap, HeSoQuyDoi, SoLuongNhap, DonGiaNhap, SoLo, HanSuDung, GhiChu
        FROM @ChiTiet;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 5.6 Bán hàng / mini-bar kiểm tra tồn kho
IF OBJECT_ID('sp_DatMonAn', 'P') IS NOT NULL DROP PROCEDURE sp_DatMonAn;
GO
CREATE PROCEDURE sp_DatMonAn
    @MonAnId INT,
    @SoLuong INT,
    @KetQua INT OUTPUT,
    @GiaVonTaiThoiDiemBan DECIMAL(18,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TonKho INT;

        SELECT @TonKho = SoLuongTonKho, @GiaVonTaiThoiDiemBan = GiaVonBinhQuan
        FROM MonAn WITH (UPDLOCK, ROWLOCK)
        WHERE Id = @MonAnId;

        IF @TonKho IS NULL OR @TonKho < @SoLuong
        BEGIN
            SET @KetQua = 0; ROLLBACK TRANSACTION; RETURN;
        END

        UPDATE MonAn
        SET SoLuongTonKho = SoLuongTonKho - @SoLuong,
            TrangThai = CASE WHEN SoLuongTonKho - @SoLuong <= 0 THEN N'Hết hàng' ELSE TrangThai END
        WHERE Id = @MonAnId;

        SET @KetQua = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 5.7 Báo cáo lợi nhuận hàng khô / mini-bar (Đã bổ sung lọc dh.TrangThai <> N'Đã hủy')
IF OBJECT_ID('sp_BaoCaoLoiNhuanKho', 'P') IS NOT NULL DROP PROCEDURE sp_BaoCaoLoiNhuanKho;
GO
CREATE PROCEDURE sp_BaoCaoLoiNhuanKho
    @TuNgay DATETIME,
    @DenNgay DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ma.Id AS MonAnId, ma.TenMon,
           SUM(ct.SoLuong)                 AS SoLuongDaBan,
           SUM(ct.ThanhTien)               AS DoanhThu,
           SUM(ct.SoLuong * ct.GiaVon)     AS TongGiaVon,
           SUM(ct.LoiNhuan)                AS LoiNhuanGop
    FROM ChiTietDonHangMonAn ct
    JOIN DonHangMonAn dh ON dh.Id = ct.DonHangId
    JOIN MonAn ma        ON ma.Id = ct.MonAnId
    WHERE dh.DaThanhToan = 1
      AND dh.TrangThai <> N'Đã hủy'
      AND dh.NgayTao BETWEEN @TuNgay AND @DenNgay
    GROUP BY ma.Id, ma.TenMon
    ORDER BY LoiNhuanGop DESC;
END;
GO

-- 5.8 Báo cáo doanh thu theo khoảng thời gian (Đã bổ sung lọc đơn hủy & cộng phụ thu rút ngắn thời gian dọn dẹp/kiểm tra xe)
IF OBJECT_ID('sp_BaoCaoDoanhThuTheoKhoangThoiGian', 'P') IS NOT NULL
    DROP PROCEDURE sp_BaoCaoDoanhThuTheoKhoangThoiGian;
GO
CREATE PROCEDURE sp_BaoCaoDoanhThuTheoKhoangThoiGian
    @TuNgay DATETIME,
    @DenNgay DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT N'Ăn Uống' AS NhomDichVu, COUNT(Id) AS SoGiaoDich, ISNULL(SUM(TongTien),0) AS DoanhThu
    FROM DonHangMonAn
    WHERE DaThanhToan = 1 AND TrangThai <> N'Đã hủy' AND NgayTao BETWEEN @TuNgay AND @DenNgay
    UNION ALL
    SELECT N'Sảnh & Sự Kiện', COUNT(Id),
           ISNULL(SUM(CASE
               WHEN TrangThaiDon = N'Đã hủy - Không hoàn cọc' THEN TienCoc
               WHEN TrangThaiDon LIKE N'Đã hủy%' THEN 0
               ELSE (TongTienDuKien + ChiPhiPhatSinh + ISNULL(PhuThuRutNganDonDep, 0))
           END), 0)
    FROM DonDatSuKien
    WHERE (DaThanhToan = 1 OR TrangThaiDon = N'Đã hủy - Không hoàn cọc')
      AND TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy')
      AND NgayTao BETWEEN @TuNgay AND @DenNgay
    UNION ALL
    SELECT N'Cho Thuê Xe Máy', COUNT(Id),
           ISNULL(SUM(CASE
               WHEN TrangThaiDon = N'Đã hủy - Không hoàn cọc' THEN TienCoc
               WHEN TrangThaiDon LIKE N'Đã hủy%' THEN 0
               ELSE (TienThue + ChiPhiPhatSinh + ISNULL(PhuThuRutNganBuffer, 0))
           END), 0)
    FROM DonThueXe
    WHERE (DaThanhToan = 1 OR TrangThaiDon = N'Đã hủy - Không hoàn cọc')
      AND TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy')
      AND NgayTao BETWEEN @TuNgay AND @DenNgay
    UNION ALL
    SELECT N'Bãi & Hầm Đỗ Xe', COUNT(Id), ISNULL(SUM(PhiGui),0)
    FROM BaiDoXe
    WHERE DaThanhToan = 1 AND PhiGui > 0 AND ThoiGianVao BETWEEN @TuNgay AND @DenNgay
    UNION ALL
    SELECT N'Giặt Ủi' AS NhomDichVu, COUNT(Id) AS SoGiaoDich, ISNULL(SUM(TongTienThuKhach),0) AS DoanhThu
    FROM DonGiatUi
    WHERE DaThanhToan = 1 AND TrangThai <> N'Đã hủy' AND NgayNhan BETWEEN @TuNgay AND @DenNgay;
END;
GO

-- 5.9 Nhận phòng (Check-in)
IF OBJECT_ID('sp_NhanPhong', 'P') IS NOT NULL DROP PROCEDURE sp_NhanPhong;
GO
CREATE PROCEDURE sp_NhanPhong
    @SoPhong NVARCHAR(20),
    @TenKhach NVARCHAR(100),
    @SoDienThoai NVARCHAR(20),
    @CCCD NVARCHAR(20),
    @NgayTraDuKien DATETIME = NULL,
    @GhiChu NVARCHAR(255) = NULL,
    @KetQua INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TrangThaiHienTai NVARCHAR(30);

    SELECT @TrangThaiHienTai = TrangThai FROM PhongKhachSan WITH (UPDLOCK, ROWLOCK) WHERE SoPhong = @SoPhong;

    IF @TrangThaiHienTai IS NULL
    BEGIN
        SET @KetQua = -1; RETURN;
    END

    IF @TrangThaiHienTai <> N'Trống'
    BEGIN
        SET @KetQua = 0; RETURN;
    END

    UPDATE PhongKhachSan
    SET TrangThai = N'Đang ở', TenKhach = @TenKhach, SoDienThoai = @SoDienThoai,
        CCCD = @CCCD, GhiChu = @GhiChu, NgayNhanPhong = GETDATE(), NgayTraPhong = @NgayTraDuKien
    WHERE SoPhong = @SoPhong;

    IF EXISTS (SELECT 1 FROM KhachHang WHERE (SoDienThoai = @SoDienThoai AND @SoDienThoai <> '') OR (CCCD = @CCCD AND @CCCD <> ''))
        UPDATE KhachHang SET HoTen = @TenKhach, SoPhong = @SoPhong, GhiChu = @GhiChu
        WHERE (SoDienThoai = @SoDienThoai AND @SoDienThoai <> '') OR (CCCD = @CCCD AND @CCCD <> '');
    ELSE
        INSERT INTO KhachHang (HoTen, CCCD, SoDienThoai, SoPhong, GhiChu)
        VALUES (@TenKhach, @CCCD, @SoDienThoai, @SoPhong, @GhiChu);

    SET @KetQua = 1;
END;
GO

-- 5.10 Hoàn tất dọn phòng
IF OBJECT_ID('sp_HoanTatDonPhong', 'P') IS NOT NULL DROP PROCEDURE sp_HoanTatDonPhong;
GO
CREATE PROCEDURE sp_HoanTatDonPhong
    @SoPhong NVARCHAR(20),
    @KetQua INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM PhongKhachSan WHERE SoPhong = @SoPhong AND TrangThai = N'Đang dọn')
    BEGIN
        SET @KetQua = 0; RETURN;
    END

    UPDATE PhongKhachSan SET TrangThai = N'Trống' WHERE SoPhong = @SoPhong;
    SET @KetQua = 1;
END;
GO

-- 5.11 Bàn giao đồ giặt cho đối tác
IF OBJECT_ID('sp_GiaoDoChoDoiTac', 'P') IS NOT NULL DROP PROCEDURE sp_GiaoDoChoDoiTac;
GO
CREATE PROCEDURE sp_GiaoDoChoDoiTac
    @MaDon NVARCHAR(30),
    @DoiTacId INT,
    @NhanVienGiaoId INT,
    @KetQua INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM DoiTacGiatUi WHERE Id = @DoiTacId AND TrangThai = 1)
    BEGIN
        RAISERROR(N'Đối tác giặt ủi không tồn tại hoặc đã ngừng hợp tác.', 16, 1);
        SET @KetQua = 0;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM DonGiatUi WHERE MaDon = @MaDon)
    BEGIN
        RAISERROR(N'Không tìm thấy mã đơn giặt ủi %s.', 16, 1, @MaDon);
        SET @KetQua = 0;
        RETURN;
    END

    UPDATE DonGiatUi
    SET 
        DoiTacId = @DoiTacId,
        NgayGiaoDoiTac = GETDATE(),
        TrangThai = N'Đang giặt'
    WHERE MaDon = @MaDon;

    SET @KetQua = 1;
END;
GO

-- 5.12 Ghi nhận đền bù thiệt hại giặt ủi (Xác định rõ bên chịu trách nhiệm, chặn vượt trần hợp đồng)
IF OBJECT_ID('sp_GhiNhanDenBuGiatUi', 'P') IS NOT NULL DROP PROCEDURE sp_GhiNhanDenBuGiatUi;
GO
CREATE PROCEDURE sp_GhiNhanDenBuGiatUi
    @MaDon NVARCHAR(30),
    @BenChiuTrachNhiem NVARCHAR(50),
    @SoTienDenBu DECIMAL(18,2),
    @LyDoDenBu NVARCHAR(255),
    @NhanVienGhiNhanId INT,
    @KetQua INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @BenChiuTrachNhiem NOT IN (N'KhachSan', N'DoiTac')
    BEGIN
        RAISERROR(N'Bên chịu trách nhiệm phải là KhachSan hoặc DoiTac.', 16, 1);
        SET @KetQua = 0;
        RETURN;
    END

    IF @SoTienDenBu <= 0
    BEGIN
        RAISERROR(N'Số tiền đền bù phải lớn hơn 0.', 16, 1);
        SET @KetQua = 0;
        RETURN;
    END

    DECLARE @TongTienThuKhach DECIMAL(18,2);
    DECLARE @LoaiDichVu NVARCHAR(50);
    DECLARE @HeSoTran INT;

    SELECT 
        @TongTienThuKhach = d.TongTienThuKhach,
        @LoaiDichVu = d.LoaiDichVu,
        @HeSoTran = ISNULL(ldv.HeSoBoiThuongToiDa, 10)
    FROM DonGiatUi d
    LEFT JOIN LoaiDichVuGiatUi ldv ON (ldv.TenLoai = d.LoaiDichVu OR ldv.MaLoai = d.LoaiDichVu)
    WHERE d.MaDon = @MaDon;

    IF @TongTienThuKhach IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy đơn giặt ủi %s.', 16, 1, @MaDon);
        SET @KetQua = 0;
        RETURN;
    END

    IF @BenChiuTrachNhiem = N'DoiTac'
    BEGIN
        DECLARE @MucTranBoiThuong DECIMAL(18,2) = @TongTienThuKhach * @HeSoTran;
        IF @SoTienDenBu > @MucTranBoiThuong
        BEGIN
            DECLARE @StrMucTran NVARCHAR(50) = CONVERT(NVARCHAR(50), @MucTranBoiThuong);
            RAISERROR(N'Số tiền đền bù vượt mức trần thỏa thuận trong hợp đồng (Tối đa %d lần giá dịch vụ = %s VNĐ).', 16, 1, @HeSoTran, @StrMucTran);
            SET @KetQua = 0;
            RETURN;
        END
    END

    UPDATE DonGiatUi
    SET 
        CoDenBu = 1,
        BenChiuTrachNhiem = @BenChiuTrachNhiem,
        SoTienDenBu = @SoTienDenBu,
        LyDoDenBu = @LyDoDenBu,
        NgayGhiNhanDenBu = GETDATE(),
        NguoiGhiNhanDenBuId = @NhanVienGhiNhanId
    WHERE MaDon = @MaDon;

    SET @KetQua = 1;
END;
GO

-- 5.13 Quyết toán công nợ theo kỳ cho đối tác giặt ủi
IF OBJECT_ID('sp_QuyetToanCongNoDoiTac', 'P') IS NOT NULL DROP PROCEDURE sp_QuyetToanCongNoDoiTac;
GO
CREATE PROCEDURE sp_QuyetToanCongNoDoiTac
    @DoiTacId INT,
    @DenNgay DATETIME = NULL,
    @NhanVienQuyetToanId INT,
    @SoDonQuyetToan INT OUTPUT,
    @TongTienQuyetToan DECIMAL(18,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @DenNgay IS NULL SET @DenNgay = GETDATE();

    SELECT 
        @SoDonQuyetToan = COUNT(Id),
        @TongTienQuyetToan = ISNULL(SUM(TienDoiTacNhan - CASE WHEN CoDenBu = 1 AND BenChiuTrachNhiem = N'DoiTac' THEN SoTienDenBu ELSE 0 END), 0)
    FROM DonGiatUi
    WHERE DoiTacId = @DoiTacId
      AND DaThanhToanChoDoiTac = 0
      AND TrangThai = N'Hoàn tất'
      AND NgayNhan <= @DenNgay;

    UPDATE DonGiatUi
    SET 
        DaThanhToanChoDoiTac = 1,
        NgayThanhToanChoDoiTac = GETDATE()
    WHERE DoiTacId = @DoiTacId
      AND DaThanhToanChoDoiTac = 0
      AND TrangThai = N'Hoàn tất'
      AND NgayNhan <= @DenNgay;

    SELECT 
        @DoiTacId AS DoiTacId,
        @SoDonQuyetToan AS SoDonDaQuyetToan,
        @TongTienQuyetToan AS TongTienThanhToanChoDoiTac,
        GETDATE() AS NgayQuyetToan;
END;
GO

-- 5.14 Thêm đối tác giặt ủi mới kèm thiết lập bảng giá vốn dịch vụ
IF OBJECT_ID('sp_ThemDoiTacGiatUi', 'P') IS NOT NULL DROP PROCEDURE sp_ThemDoiTacGiatUi;
GO
CREATE PROCEDURE sp_ThemDoiTacGiatUi
    @TenDoiTac           NVARCHAR(100),
    @DiaChi              NVARCHAR(255) = NULL,
    @SoDienThoai         NVARCHAR(20),
    @HanThanhToanCongNo  NVARCHAR(30) = N'Theo tháng',
    @TyLeKhachSanHuong   DECIMAL(5,2) = 30.00,
    @GiaVonGiatSay       DECIMAL(18,2) = NULL,
    @GiaVonGiatHap       DECIMAL(18,2) = NULL,
    @GiaVonUiPhang       DECIMAL(18,2) = NULL,
    @NewPartnerId        INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @TyLeDoiTacHuong DECIMAL(5,2) = 100.00 - @TyLeKhachSanHuong;

        INSERT INTO DoiTacGiatUi (TenDoiTac, DiaChi, SoDienThoai, HanThanhToanCongNo, TyLeKhachSanHuong, TyLeDoiTacHuong, TrangThai)
        VALUES (@TenDoiTac, @DiaChi, @SoDienThoai, @HanThanhToanCongNo, @TyLeKhachSanHuong, @TyLeDoiTacHuong, 1);

        SET @NewPartnerId = SCOPE_IDENTITY();

        DECLARE @GiaBanGiatSay DECIMAL(18,2), @GiaBanGiatHap DECIMAL(18,2), @GiaBanUiPhang DECIMAL(18,2);
        SELECT @GiaBanGiatSay = DonGiaBanKg FROM LoaiDichVuGiatUi WHERE MaLoai = 'GIAT_SAY';
        SELECT @GiaBanGiatHap = DonGiaBanKg FROM LoaiDichVuGiatUi WHERE MaLoai = 'GIAT_HAP';
        SELECT @GiaBanUiPhang = DonGiaBanKg FROM LoaiDichVuGiatUi WHERE MaLoai = 'UI_PHANG';

        IF @GiaVonGiatSay IS NULL OR @GiaVonGiatSay <= 0
            SET @GiaVonGiatSay = ROUND(@GiaBanGiatSay * (@TyLeDoiTacHuong / 100.0), 0);
        IF @GiaVonGiatHap IS NULL OR @GiaVonGiatHap <= 0
            SET @GiaVonGiatHap = ROUND(@GiaBanGiatHap * (@TyLeDoiTacHuong / 100.0), 0);
        IF @GiaVonUiPhang IS NULL OR @GiaVonUiPhang <= 0
            SET @GiaVonUiPhang = ROUND(@GiaBanUiPhang * (@TyLeDoiTacHuong / 100.0), 0);

        IF @GiaVonGiatSay >= @GiaBanGiatSay SET @GiaVonGiatSay = @GiaBanGiatSay - 1000;
        IF @GiaVonGiatHap >= @GiaBanGiatHap SET @GiaVonGiatHap = @GiaBanGiatHap - 1000;
        IF @GiaVonUiPhang >= @GiaBanUiPhang SET @GiaVonUiPhang = @GiaBanUiPhang - 1000;

        DECLARE @IdGiatSay INT, @IdGiatHap INT, @IdUiPhang INT;
        SELECT @IdGiatSay = Id FROM LoaiDichVuGiatUi WHERE MaLoai = 'GIAT_SAY';
        SELECT @IdGiatHap = Id FROM LoaiDichVuGiatUi WHERE MaLoai = 'GIAT_HAP';
        SELECT @IdUiPhang = Id FROM LoaiDichVuGiatUi WHERE MaLoai = 'UI_PHANG';

        INSERT INTO BangGiaDoiTacGiatUi (DoiTacId, LoaiDichVuId, DonGiaVonKg, GhiChu) VALUES
        (@NewPartnerId, @IdGiatSay, @GiaVonGiatSay, N'Giá vốn giặt sấy thỏa thuận'),
        (@NewPartnerId, @IdGiatHap, @GiaVonGiatHap, N'Giá vốn giặt hấp thỏa thuận'),
        (@NewPartnerId, @IdUiPhang, @GiaVonUiPhang, N'Giá vốn ủi phẳng thỏa thuận');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 5.15 Cập nhật bảng giá vốn của đối tác giặt ủi
IF OBJECT_ID('sp_CapNhatBangGiaDoiTac', 'P') IS NOT NULL DROP PROCEDURE sp_CapNhatBangGiaDoiTac;
GO
CREATE PROCEDURE sp_CapNhatBangGiaDoiTac
    @DoiTacId      INT,
    @LoaiDichVuId  INT,
    @DonGiaVonKg   DECIMAL(18,2),
    @KetQua        INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DonGiaBanKg DECIMAL(18,2);
    SELECT @DonGiaBanKg = DonGiaBanKg FROM LoaiDichVuGiatUi WHERE Id = @LoaiDichVuId;

    IF @DonGiaBanKg IS NULL
    BEGIN
        RAISERROR(N'Loại hình dịch vụ không tồn tại.', 16, 1);
        SET @KetQua = 0; RETURN;
    END

    IF @DonGiaVonKg >= @DonGiaBanKg
    BEGIN
        DECLARE @StrVon NVARCHAR(30) = CONVERT(NVARCHAR(30), @DonGiaVonKg);
        DECLARE @StrBan NVARCHAR(30) = CONVERT(NVARCHAR(30), @DonGiaBanKg);
        RAISERROR(N'Giá vốn (%s VNĐ) phải nhỏ hơn giá niêm yết bán cho khách (%s VNĐ)!', 16, 1, @StrVon, @StrBan);
        SET @KetQua = -1; RETURN;
    END

    IF EXISTS (SELECT 1 FROM BangGiaDoiTacGiatUi WHERE DoiTacId = @DoiTacId AND LoaiDichVuId = @LoaiDichVuId)
    BEGIN
        UPDATE BangGiaDoiTacGiatUi
        SET DonGiaVonKg = @DonGiaVonKg
        WHERE DoiTacId = @DoiTacId AND LoaiDichVuId = @LoaiDichVuId;
    END
    ELSE
    BEGIN
        INSERT INTO BangGiaDoiTacGiatUi (DoiTacId, LoaiDichVuId, DonGiaVonKg, GhiChu)
        VALUES (@DoiTacId, @LoaiDichVuId, @DonGiaVonKg, N'Cập nhật giá vốn mới');
    END

    SET @KetQua = 1;
END;
GO

-- 5.16 Tự động chuyển "Đã đặt" -> "Đang sử dụng" khi đến giờ sự kiện
IF OBJECT_ID('sp_KichHoatDangSuDungSuKien', 'P') IS NOT NULL DROP PROCEDURE sp_KichHoatDangSuDungSuKien;
GO
CREATE PROCEDURE sp_KichHoatDangSuDungSuKien
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE DonDatSuKien
    SET TrangThaiDon = N'Đang sử dụng'
    WHERE TrangThaiDon = N'Đã đặt'
      AND GETDATE() >= ThoiGianBatDau
      AND GETDATE() < ThoiGianKetThuc;

    SELECT @@ROWCOUNT AS SoDonDaKichHoat;
END;
GO

-- 5.17 Hoàn tất sự kiện (lễ tân bấm khi khách trả sảnh)
IF OBJECT_ID('sp_HoanTatSuKien', 'P') IS NOT NULL DROP PROCEDURE sp_HoanTatSuKien;
GO
CREATE PROCEDURE sp_HoanTatSuKien
    @DonId INT,
    @ChiPhiPhatSinh DECIMAL(18,2) = 0,
    @GhiChuHuHai NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM DonDatSuKien WHERE Id = @DonId AND TrangThaiDon = N'Đang sử dụng')
    BEGIN
        RAISERROR(N'Chỉ có thể hoàn tất đơn đang ở trạng thái Đang sử dụng.', 16, 1);
        RETURN;
    END

    UPDATE DonDatSuKien
    SET TrangThaiDon = N'Hoàn tất',
        ChiPhiPhatSinh = @ChiPhiPhatSinh,
        GhiChuHuHai = ISNULL(@GhiChuHuHai, GhiChuHuHai)
    WHERE Id = @DonId;
END;
GO

-- 5.18 Hủy đơn đặt sảnh (Chỉ hoàn cọc nếu báo hủy trước ngày diễn ra sự kiện ít nhất 1 ngày lịch)
IF OBJECT_ID('sp_HuySuKien', 'P') IS NOT NULL DROP PROCEDURE sp_HuySuKien;
GO
CREATE PROCEDURE sp_HuySuKien
    @DonId INT,
    @NguoiHuyId INT,
    @LyDoHuy NVARCHAR(255) = NULL,
    @KetQua NVARCHAR(30) OUTPUT,
    @SoTienHoan DECIMAL(18,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ThoiGianBatDauVal DATETIME, @TienCocVal DECIMAL(18,2), @TrangThaiHienTai NVARCHAR(30);

    SELECT @ThoiGianBatDauVal = ThoiGianBatDau, @TienCocVal = TienCoc, @TrangThaiHienTai = TrangThaiDon
    FROM DonDatSuKien WHERE Id = @DonId;

    IF @ThoiGianBatDauVal IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy đơn đặt sảnh.', 16, 1); RETURN;
    END

    IF @TrangThaiHienTai NOT IN (N'Đã đặt', N'Đang sử dụng')
    BEGIN
        RAISERROR(N'Đơn này không ở trạng thái có thể hủy (đã hoàn tất hoặc đã hủy trước đó).', 16, 1);
        RETURN;
    END

    IF CAST(GETDATE() AS DATE) <= DATEADD(DAY, -1, CAST(@ThoiGianBatDauVal AS DATE))
    BEGIN
        SET @KetQua = N'HoanCoc';
        SET @SoTienHoan = @TienCocVal;
        UPDATE DonDatSuKien
        SET TrangThaiDon = N'Đã hủy - Hoàn cọc', ThoiGianHuy = GETDATE(), LyDoHuy = @LyDoHuy,
            NguoiHuyId = @NguoiHuyId, SoTienHoanCoc = @TienCocVal,
            DaThanhToan = 1, NguoiThanhToanId = @NguoiHuyId, ThoiGianThanhToan = GETDATE()
        WHERE Id = @DonId;
    END
    ELSE
    BEGIN
        SET @KetQua = N'KhongHoanCoc';
        SET @SoTienHoan = 0;
        UPDATE DonDatSuKien
        SET TrangThaiDon = N'Đã hủy - Không hoàn cọc', ThoiGianHuy = GETDATE(), LyDoHuy = @LyDoHuy,
            NguoiHuyId = @NguoiHuyId, SoTienHoanCoc = 0,
            DaThanhToan = 1, NguoiThanhToanId = @NguoiHuyId, ThoiGianThanhToan = GETDATE()
        WHERE Id = @DonId;
    END
END;
GO

-- 5.19 Tự động chuyển "Đã đặt" -> "Đang thuê" khi đến giờ thuê xe
IF OBJECT_ID('sp_KichHoatDangThueXe', 'P') IS NOT NULL DROP PROCEDURE sp_KichHoatDangThueXe;
GO
CREATE PROCEDURE sp_KichHoatDangThueXe
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE DonThueXe
    SET TrangThaiDon = N'Đang thuê'
    WHERE TrangThaiDon = N'Đã đặt'
      AND GETDATE() >= NgayThue
      AND GETDATE() < NgayTraDuKien;

    SELECT @@ROWCOUNT AS SoDonDaKichHoat;
END;
GO

-- 5.20 Hoàn tất đơn thuê xe (Đã bổ sung cộng PhuThuRutNganBuffer vào TongTienThanhToan)
IF OBJECT_ID('sp_HoanTatThueXe', 'P') IS NOT NULL DROP PROCEDURE sp_HoanTatThueXe;
GO
CREATE PROCEDURE sp_HoanTatThueXe
    @DonId INT,
    @ChiPhiPhatSinh DECIMAL(18,2) = 0,
    @GhiChuHuHai NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM DonThueXe WHERE Id = @DonId AND TrangThaiDon = N'Đang thuê')
    BEGIN
        RAISERROR(N'Chỉ có thể hoàn tất đơn đang ở trạng thái Đang thuê.', 16, 1);
        RETURN;
    END

    UPDATE DonThueXe
    SET TrangThaiDon = N'Hoàn tất',
        NgayTraThucTe = GETDATE(),
        ChiPhiPhatSinh = @ChiPhiPhatSinh,
        TongTienThanhToan = TienThue + @ChiPhiPhatSinh + ISNULL(PhuThuRutNganBuffer, 0),
        GhiChuHuHai = ISNULL(@GhiChuHuHai, GhiChuHuHai)
    WHERE Id = @DonId;
END;
GO

-- 5.21 Hủy đơn thuê xe (Hủy trước ngày thuê ít nhất 1 ngày lịch được hoàn cọc)
IF OBJECT_ID('sp_HuyThueXe', 'P') IS NOT NULL DROP PROCEDURE sp_HuyThueXe;
GO
CREATE PROCEDURE sp_HuyThueXe
    @DonId INT,
    @NguoiHuyId INT,
    @LyDoHuy NVARCHAR(255) = NULL,
    @KetQua NVARCHAR(30) OUTPUT,
    @SoTienHoan DECIMAL(18,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NgayThueVal DATETIME, @TienCocVal DECIMAL(18,2), @TrangThaiHienTai NVARCHAR(30);

    SELECT @NgayThueVal = NgayThue, @TienCocVal = TienCoc, @TrangThaiHienTai = TrangThaiDon
    FROM DonThueXe WHERE Id = @DonId;

    IF @NgayThueVal IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy đơn thuê xe.', 16, 1); RETURN;
    END

    IF @TrangThaiHienTai NOT IN (N'Đã đặt', N'Đang thuê')
    BEGIN
        RAISERROR(N'Đơn này không ở trạng thái có thể hủy (đã hoàn tất hoặc đã hủy trước đó).', 16, 1);
        RETURN;
    END

    IF CAST(GETDATE() AS DATE) <= DATEADD(DAY, -1, CAST(@NgayThueVal AS DATE))
    BEGIN
        SET @KetQua = N'HoanCoc';
        SET @SoTienHoan = @TienCocVal;
        UPDATE DonThueXe
        SET TrangThaiDon = N'Đã hủy - Hoàn cọc', ThoiGianHuy = GETDATE(), LyDoHuy = @LyDoHuy,
            NguoiHuyId = @NguoiHuyId, SoTienHoanCoc = @TienCocVal,
            DaThanhToan = 1, NguoiThanhToanId = @NguoiHuyId, ThoiGianThanhToan = GETDATE()
        WHERE Id = @DonId;
    END
    ELSE
    BEGIN
        SET @KetQua = N'KhongHoanCoc';
        SET @SoTienHoan = 0;
        UPDATE DonThueXe
        SET TrangThaiDon = N'Đã hủy - Không hoàn cọc', ThoiGianHuy = GETDATE(), LyDoHuy = @LyDoHuy,
            NguoiHuyId = @NguoiHuyId, SoTienHoanCoc = 0,
            DaThanhToan = 1, NguoiThanhToanId = @NguoiHuyId, ThoiGianThanhToan = GETDATE()
        WHERE Id = @DonId;
    END
END;
GO

-- 5.22 Tự động quyết toán các dữ liệu mẫu đã qua (< CAST(GETDATE() AS DATE)) & tự động xếp lịch ca trực
IF OBJECT_ID('sp_TuDongQuyetToanDuLieuCu', 'P') IS NOT NULL DROP PROCEDURE sp_TuDongQuyetToanDuLieuCu;
GO
CREATE PROCEDURE sp_TuDongQuyetToanDuLieuCu
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Today DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);

    -- 1. Đơn hàng ăn uống trước hôm nay (trừ Đã hủy) -> Đã giao & Đã thanh toán
    UPDATE DonHangMonAn
    SET TrangThai = N'Đã giao',
        DaThanhToan = 1,
        NguoiThanhToanId = ISNULL(NguoiThanhToanId, ISNULL(NguoiTaoId, 1)),
        ThoiGianThanhToan = ISNULL(ThoiGianThanhToan, DATEADD(MINUTE, 20, NgayTao))
    WHERE NgayTao < @Today AND TrangThai <> N'Đã hủy' AND (DaThanhToan = 0 OR TrangThai IN (N'Chờ xử lý', N'Đang chuẩn bị'));

    -- 2. Đơn đặt sảnh & sự kiện đã qua trước hôm nay -> Hoàn tất & Đã thanh toán
    UPDATE DonDatSuKien
    SET TrangThaiDon = N'Hoàn tất',
        DaThanhToan = 1,
        NguoiThanhToanId = ISNULL(NguoiThanhToanId, ISNULL(NguoiTaoId, 1)),
        ThoiGianThanhToan = ISNULL(ThoiGianThanhToan, ThoiGianKetThuc)
    WHERE ThoiGianKetThuc < @Today AND TrangThaiDon NOT LIKE N'Đã hủy%' AND (DaThanhToan = 0 OR TrangThaiDon IN (N'Đã đặt', N'Đang sử dụng'));

    -- 3. Đơn thuê xe đã qua hạn trả trước hôm nay -> Hoàn tất & Đã thanh toán
    UPDATE DonThueXe
    SET TrangThaiDon = N'Hoàn tất',
        NgayTraThucTe = ISNULL(NgayTraThucTe, NgayTraDuKien),
        DaThanhToan = 1,
        NguoiThanhToanId = ISNULL(NguoiThanhToanId, ISNULL(NguoiTaoId, 1)),
        ThoiGianThanhToan = ISNULL(ThoiGianThanhToan, ISNULL(NgayTraThucTe, NgayTraDuKien))
    WHERE NgayTraDuKien < @Today AND TrangThaiDon NOT LIKE N'Đã hủy%' AND (DaThanhToan = 0 OR TrangThaiDon IN (N'Đã đặt', N'Đang thuê'));

    -- 4. Bãi đỗ xe vào trước hôm nay (trừ xe miễn phí của khách đang ở phòng) -> Đã ra & Đã thanh toán
    UPDATE BaiDoXe
    SET ThoiGianRa = ISNULL(ThoiGianRa, DATEADD(HOUR, 4, ThoiGianVao)),
        DaThanhToan = 1,
        NguoiThanhToanId = ISNULL(NguoiThanhToanId, ISNULL(NguoiTaoId, 1)),
        ThoiGianThanhToan = ISNULL(ThoiGianThanhToan, ISNULL(ThoiGianRa, DATEADD(HOUR, 4, ThoiGianVao)))
    WHERE ThoiGianVao < @Today AND (DaThanhToan = 0 OR (ThoiGianRa IS NULL AND HinhThucGui <> N'Khách phòng (Miễn phí)'));

    -- 5. Đơn giặt ủi hẹn trả trước hôm nay (trừ Đã hủy) -> Hoàn tất & Đã thanh toán
    UPDATE DonGiatUi
    SET DoiTacId = ISNULL(DoiTacId, 1),
        NgayGiaoDoiTac = ISNULL(NgayGiaoDoiTac, DATEADD(HOUR, 1, NgayNhan)),
        NgayTraThucTe = ISNULL(NgayTraThucTe, NgayHenTra),
        TrangThai = N'Hoàn tất',
        DaThanhToan = 1,
        NguoiThanhToanId = ISNULL(NguoiThanhToanId, ISNULL(NguoiTaoId, 1)),
        ThoiGianThanhToan = ISNULL(ThoiGianThanhToan, ISNULL(NgayTraThucTe, NgayHenTra))
    WHERE NgayHenTra < @Today AND TrangThai <> N'Đã hủy' AND (DaThanhToan = 0 OR TrangThai IN (N'Chờ giao đối tác', N'Đang giặt'));

    -- 6. Tự động đảm bảo xếp ca trực cho nhân viên từ hôm nay đến hết tháng hiện tại
    DECLARE @CurDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @EndMonth DATE = EOMONTH(@CurDate);
    WHILE @CurDate <= @EndMonth
    BEGIN
        DECLARE @DayNum INT = DAY(@CurDate);
        DECLARE @nvSang INT = ((@DayNum - 1) % 3) + 1;
        DECLARE @nvChieu INT = (@DayNum % 3) + 1;
        DECLARE @nvDem INT = ((@DayNum + 1) % 3) + 1;

        IF NOT EXISTS (SELECT 1 FROM PhanCongCaTruc WHERE NgayTruc = @CurDate AND CaTrucId = 1)
            INSERT INTO PhanCongCaTruc (NhanVienId, CaTrucId, NgayTruc, GhiChu)
            VALUES (@nvSang, 1, @CurDate, N'Phân ca sáng tự động trong tháng');

        IF NOT EXISTS (SELECT 1 FROM PhanCongCaTruc WHERE NgayTruc = @CurDate AND CaTrucId = 2)
            INSERT INTO PhanCongCaTruc (NhanVienId, CaTrucId, NgayTruc, GhiChu)
            VALUES (@nvChieu, 2, @CurDate, N'Phân ca chiều tự động trong tháng');

        IF NOT EXISTS (SELECT 1 FROM PhanCongCaTruc WHERE NgayTruc = @CurDate AND CaTrucId = 3)
            INSERT INTO PhanCongCaTruc (NhanVienId, CaTrucId, NgayTruc, GhiChu)
            VALUES (@nvDem, 3, @CurDate, N'Phân ca đêm tự động trong tháng');

        SET @CurDate = DATEADD(DAY, 1, @CurDate);
    END

    -- 7. Kích hoạt các đơn sự kiện / thuê xe đang trong khung giờ hôm nay
    EXEC sp_KichHoatDangSuDungSuKien;
    EXEC sp_KichHoatDangThueXe;
END;
GO
