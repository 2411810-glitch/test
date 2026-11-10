/* =================================================================================
   HỆ THỐNG QUẢN LÝ DỊCH VỤ KHÁCH SẠN (DALAT HOTEL) - SQL SERVER
   FILE 1: Table.sql - KHỞI TẠO DATABASE, KIỂU DỮ LIỆU & CẤU TRÚC BẢNG (TABLES)
   Thứ tự chạy: 1. Table.sql -> 2. Views.sql -> 3. Trigger.sql -> 4. Procedures.sql -> 5. Data.sql
   ================================================================================= */

USE master;
GO
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'QuanLyDichVuKhachSan')
BEGIN
    ALTER DATABASE QuanLyDichVuKhachSan SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyDichVuKhachSan;
END
GO
CREATE DATABASE QuanLyDichVuKhachSan;
GO

USE QuanLyDichVuKhachSan;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =====================================================================================
-- PHẦN 1: ĐỊNH NGHĨA KIỂU DỮ LIỆU TỰ ĐỊNH NGHĨA (USER-DEFINED TABLE TYPES)
-- =====================================================================================

IF TYPE_ID(N'kieu_ChiTietNhapKho') IS NOT NULL DROP TYPE kieu_ChiTietNhapKho;
GO
CREATE TYPE kieu_ChiTietNhapKho AS TABLE (
    MonAnId     INT NOT NULL,
    DonViNhap   NVARCHAR(50) NOT NULL,
    HeSoQuyDoi  INT NOT NULL,
    SoLuongNhap INT NOT NULL,
    DonGiaNhap  DECIMAL(18,2) NOT NULL,
    SoLo        VARCHAR(50) NULL,
    HanSuDung   DATE NULL,
    GhiChu      NVARCHAR(255) NULL
);
GO


-- =====================================================================================
-- PHẦN 2: TẠO TẤT CẢ CÁC BẢNG (TABLES, CONSTRAINTS & INDEXES)
-- =====================================================================================

-- 2.1 Tài khoản đăng nhập (Admin / Lễ tân)
IF OBJECT_ID('TaiKhoan', 'U') IS NOT NULL DROP TABLE TaiKhoan;
CREATE TABLE TaiKhoan (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    TenDangNhap     NVARCHAR(50)  NOT NULL UNIQUE,
    MatKhauHash     NVARCHAR(255) NOT NULL,
    HoTen           NVARCHAR(100) NOT NULL,
    VaiTro          NVARCHAR(20)  NOT NULL CHECK (VaiTro IN (N'Admin', N'LeTan')),
    SoDienThoai     NVARCHAR(20)  NULL,
    Email           NVARCHAR(100) NULL,
    TrangThai       BIT NOT NULL DEFAULT 1,
    NgayTao         DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- 2.2 Nhân viên & Ca trực
IF OBJECT_ID('NhanVien', 'U') IS NOT NULL DROP TABLE NhanVien;
CREATE TABLE NhanVien (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    MaNV            NVARCHAR(20)  NOT NULL UNIQUE,
    HoTen           NVARCHAR(100) NOT NULL,
    CCCD            NVARCHAR(20)  NOT NULL UNIQUE,
    SoDienThoai     NVARCHAR(20)  NOT NULL,
    Email           NVARCHAR(100) NULL,
    ChucVu          NVARCHAR(50)  NOT NULL,
    LuongCoBan      DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (LuongCoBan >= 0),
    TrangThai       NVARCHAR(30)  NOT NULL DEFAULT N'Đang làm việc'
                        CHECK (TrangThai IN (N'Đang làm việc', N'Nghỉ phép', N'Đã nghỉ'))
);
GO

IF OBJECT_ID('CaTruc', 'U') IS NOT NULL DROP TABLE CaTruc;
CREATE TABLE CaTruc (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    TenCa       NVARCHAR(50) NOT NULL UNIQUE,
    GioBatDau   TIME NOT NULL,
    GioKetThuc  TIME NOT NULL,
    GhiChu      NVARCHAR(255) NULL
);
GO

IF OBJECT_ID('PhanCongCaTruc', 'U') IS NOT NULL DROP TABLE PhanCongCaTruc;
CREATE TABLE PhanCongCaTruc (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    NhanVienId  INT NOT NULL FOREIGN KEY REFERENCES NhanVien(Id) ON DELETE CASCADE,
    CaTrucId    INT NOT NULL FOREIGN KEY REFERENCES CaTruc(Id),
    NgayTruc    DATE NOT NULL,
    GhiChu      NVARCHAR(255) NULL,
    CONSTRAINT UQ_PhanCong UNIQUE (NhanVienId, CaTrucId, NgayTruc)
);
GO

-- 2.3 Danh mục dịch vụ hệ thống & Cấu hình tham số
IF OBJECT_ID('DichVuHeThong', 'U') IS NOT NULL DROP TABLE DichVuHeThong;
CREATE TABLE DichVuHeThong (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    MaDV            NVARCHAR(30)  NOT NULL UNIQUE,
    TenDV           NVARCHAR(100) NOT NULL,
    LoaiDichVu      NVARCHAR(30)  NOT NULL CHECK (LoaiDichVu IN (N'Tự túc', N'Dịch vụ ngoài')),
    DangHoatDong    BIT NOT NULL DEFAULT 1,
    MoTa            NVARCHAR(255) NULL
);
GO

IF OBJECT_ID('ThamSoHeThong', 'U') IS NOT NULL DROP TABLE ThamSoHeThong;
CREATE TABLE ThamSoHeThong (
    MaThamSo     VARCHAR(50) PRIMARY KEY,
    TenThamSo    NVARCHAR(100) NOT NULL,
    GiaTri       NVARCHAR(100) NOT NULL,
    MoTa         NVARCHAR(255) NULL
);
GO

-- 2.4 Sơ đồ phòng khách sạn (Bổ trợ liên kết khách lưu trú để ghi nợ dịch vụ vào phòng)
IF OBJECT_ID('PhongKhachSan', 'U') IS NOT NULL DROP TABLE PhongKhachSan;
CREATE TABLE PhongKhachSan (
    Id            INT IDENTITY(1,1) PRIMARY KEY,
    SoPhong       NVARCHAR(20) NOT NULL UNIQUE,
    Tang          INT NOT NULL,
    LoaiPhong     NVARCHAR(50) NOT NULL,
    GiaPhong      DECIMAL(18,2) NOT NULL DEFAULT 500000 CHECK (GiaPhong >= 0),
    TrangThai     NVARCHAR(30) NOT NULL DEFAULT N'Trống'
                      CHECK (TrangThai IN (N'Trống', N'Đang ở', N'Đang dọn', N'Bảo trì')),
    TenKhach      NVARCHAR(100) NULL,
    SoDienThoai   NVARCHAR(20)  NULL,
    CCCD          NVARCHAR(20)  NULL,
    GhiChu        NVARCHAR(255) NULL,
    NgayNhanPhong DATETIME NULL,
    NgayTraPhong  DATETIME NULL
);
GO

-- 2.5 Hồ sơ khách hàng
IF OBJECT_ID('KhachHang', 'U') IS NOT NULL DROP TABLE KhachHang;
CREATE TABLE KhachHang (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    HoTen           NVARCHAR(100) NOT NULL,
    CCCD            NVARCHAR(20)  NULL,
    SoDienThoai     NVARCHAR(20)  NOT NULL,
    SoPhong         NVARCHAR(20)  NULL,
    GhiChu          NVARCHAR(255) NULL,
    NgayTao         DATETIME NOT NULL DEFAULT GETDATE()
);
GO
CREATE INDEX IX_KhachHang_CCCD ON KhachHang(CCCD);
CREATE INDEX IX_KhachHang_SDT  ON KhachHang(SoDienThoai);
GO

-- 2.5b Hóa đơn quyết toán phòng & dịch vụ
IF OBJECT_ID('ChiTietHoaDon', 'U') IS NOT NULL DROP TABLE ChiTietHoaDon;
IF OBJECT_ID('HoaDon', 'U') IS NOT NULL DROP TABLE HoaDon;
GO
CREATE TABLE HoaDon (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    MaHoaDon        NVARCHAR(50)  NOT NULL UNIQUE,
    SoPhong         NVARCHAR(20)  NOT NULL,
    TenKhach        NVARCHAR(100) NULL,
    SoDienThoai     NVARCHAR(20)  NULL,
    CCCD            NVARCHAR(20)  NULL,
    NgayLap         DATETIME      NOT NULL DEFAULT GETDATE(),
    NgayNhan        DATETIME      NULL,
    NgayTra         DATETIME      NULL,
    SoDem           INT           NOT NULL DEFAULT 0,
    GiaPhong        DECIMAL(18,2) NOT NULL DEFAULT 0,
    TienPhong       DECIMAL(18,2) NOT NULL DEFAULT 0,
    TienDichVu      DECIMAL(18,2) NOT NULL DEFAULT 0,
    TongTien        DECIMAL(18,2) NOT NULL DEFAULT 0,
    NguoiLap        NVARCHAR(100) NULL,
    NguoiThu        NVARCHAR(100) NULL
);
GO
CREATE TABLE ChiTietHoaDon (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    HoaDonId        INT           NOT NULL FOREIGN KEY REFERENCES HoaDon(Id) ON DELETE CASCADE,
    LoaiDichVu      NVARCHAR(50)  NULL,
    TenDichVu       NVARCHAR(200) NULL,
    ThoiGian        DATETIME      NULL,
    SoTien          DECIMAL(18,2) NOT NULL DEFAULT 0
);
GO
CREATE INDEX IX_HoaDon_SoPhong_NgayLap ON HoaDon(SoPhong, NgayLap);
GO

-- 2.6 Dịch vụ 1: Nhà cung cấp, Món ăn minibar / hàng khô, Nhập kho
IF OBJECT_ID('NhaCungCap', 'U') IS NOT NULL DROP TABLE NhaCungCap;
CREATE TABLE NhaCungCap (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    TenNhaCungCap   NVARCHAR(100) NOT NULL UNIQUE,
    NguoiLienHe     NVARCHAR(100) NULL,
    SoDienThoai     NVARCHAR(20)  NOT NULL,
    DiaChi          NVARCHAR(255) NULL,
    Email           NVARCHAR(100) NULL,
    GhiChu          NVARCHAR(255) NULL,
    TrangThai       BIT NOT NULL DEFAULT 1
);
GO

IF OBJECT_ID('MonAn', 'U') IS NOT NULL DROP TABLE MonAn;
CREATE TABLE MonAn (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    TenMon              NVARCHAR(100) NOT NULL UNIQUE,
    DanhMuc             NVARCHAR(50)  NOT NULL,
    DonViTinh           NVARCHAR(20)  NOT NULL,
    GiaBan              DECIMAL(18,2) NOT NULL CHECK (GiaBan >= 0),
    GiaVonBinhQuan      DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (GiaVonBinhQuan >= 0),
    SoLuongTonKho       INT           NOT NULL DEFAULT 0 CHECK (SoLuongTonKho >= 0),
    MucTonToiThieu      INT           NOT NULL DEFAULT 10,
    HinhAnh             NVARCHAR(500) NULL,
    TrangThai           NVARCHAR(30)  NOT NULL DEFAULT N'Đang phục vụ'
                            CHECK (TrangThai IN (N'Đang phục vụ', N'Còn hàng', N'Hết hàng', N'Ngừng kinh doanh', N'Đã xóa')),
    NhaCungCapId        INT           NULL FOREIGN KEY REFERENCES NhaCungCap(Id),
    GhiChu              NVARCHAR(255) NULL,
    DonViNhapMacDinh    NVARCHAR(50)  NULL DEFAULT N'Thùng',
    HeSoQuyDoiMacDinh   INT           NULL DEFAULT 24
);
GO

IF OBJECT_ID('PhieuNhapKho', 'U') IS NOT NULL DROP TABLE PhieuNhapKho;
CREATE TABLE PhieuNhapKho (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    MaPhieuNhap     NVARCHAR(50)  NOT NULL UNIQUE,
    NhaCungCapId    INT           NOT NULL FOREIGN KEY REFERENCES NhaCungCap(Id),
    NguoiNhapId     INT           NOT NULL FOREIGN KEY REFERENCES NhanVien(Id),
    NgayNhap        DATETIME      NOT NULL DEFAULT GETDATE(),
    TongTien        DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (TongTien >= 0),
    GhiChu          NVARCHAR(255) NULL
);
GO

IF OBJECT_ID('ChiTietPhieuNhapKho', 'U') IS NOT NULL DROP TABLE ChiTietPhieuNhapKho;
CREATE TABLE ChiTietPhieuNhapKho (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    PhieuNhapId     INT NOT NULL FOREIGN KEY REFERENCES PhieuNhapKho(Id) ON DELETE CASCADE,
    MonAnId         INT NOT NULL FOREIGN KEY REFERENCES MonAn(Id),
    DonViNhap       NVARCHAR(50) NOT NULL,
    HeSoQuyDoi      INT NOT NULL DEFAULT 1 CHECK (HeSoQuyDoi >= 1),
    SoLuongNhap     INT NOT NULL CHECK (SoLuongNhap > 0),
    SoLuongCoSo     AS (SoLuongNhap * HeSoQuyDoi) PERSISTED,
    DonGiaNhap      DECIMAL(18,2) NOT NULL CHECK (DonGiaNhap >= 0),
    ThanhTien       AS (SoLuongNhap * DonGiaNhap) PERSISTED,
    GiaVonCoSo      AS (DonGiaNhap / HeSoQuyDoi) PERSISTED,
    SoLo            VARCHAR(50) NULL,
    HanSuDung       DATE NULL,
    GhiChu          NVARCHAR(255) NULL
);
GO

-- 2.7 Đơn hàng ẩm thực & minibar
-- Lưu ý thực tế khách sạn nhỏ: Bán đồ khô/nước đóng chai trực tiếp tại quầy lễ tân hoặc minibar nên mặc định TrangThai = N'Đã giao'.
-- Các trạng thái 'Chờ xử lý', 'Đang chuẩn bị' phục vụ trường hợp khách gọi mang lên phòng; 'Đã hủy' dùng để loại trừ doanh thu/công nợ và hoàn kho.
IF OBJECT_ID('DonHangMonAn', 'U') IS NOT NULL DROP TABLE DonHangMonAn;
CREATE TABLE DonHangMonAn (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    MaDon               NVARCHAR(30) NOT NULL UNIQUE,
    KhachHangId         INT NULL FOREIGN KEY REFERENCES KhachHang(Id),
    TenKhach            NVARCHAR(100) NOT NULL,
    SoPhong             NVARCHAR(20) NULL,
    HinhThucThanhToan   NVARCHAR(50) NOT NULL DEFAULT N'Ghi nợ vào phòng'
                            CHECK (HinhThucThanhToan IN (N'Thanh toán trực tiếp', N'Ghi nợ vào phòng', N'Hóa đơn riêng', N'Tính chung tiền phòng')),
    TongTien            DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (TongTien >= 0),
    DaThanhToan         BIT NOT NULL DEFAULT 0,
    GhiChu              NVARCHAR(255) NULL,
    NguoiTaoId          INT NOT NULL FOREIGN KEY REFERENCES NhanVien(Id),
    NguoiThanhToanId    INT NULL     FOREIGN KEY REFERENCES NhanVien(Id),
    ThoiGianThanhToan   DATETIME NULL,
    NgayTao             DATETIME NOT NULL DEFAULT GETDATE(),
    TrangThai           NVARCHAR(30) NOT NULL DEFAULT N'Đã giao'
                            CHECK (TrangThai IN (N'Chờ xử lý', N'Đang chuẩn bị', N'Đã giao', N'Đã hủy')),
    CONSTRAINT CK_DonHang_XacNhanTT CHECK (
        (DaThanhToan = 0 AND NguoiThanhToanId IS NULL AND ThoiGianThanhToan IS NULL) OR
        (DaThanhToan = 1 AND NguoiThanhToanId IS NOT NULL AND ThoiGianThanhToan IS NOT NULL)
    ),
    CONSTRAINT CK_DonHangMonAn_Huy CHECK (TrangThai <> N'Đã hủy' OR DaThanhToan = 0)
);
GO

IF OBJECT_ID('ChiTietDonHangMonAn', 'U') IS NOT NULL DROP TABLE ChiTietDonHangMonAn;
CREATE TABLE ChiTietDonHangMonAn (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    DonHangId   INT NOT NULL FOREIGN KEY REFERENCES DonHangMonAn(Id) ON DELETE CASCADE,
    MonAnId     INT NOT NULL FOREIGN KEY REFERENCES MonAn(Id),
    SoLuong     INT NOT NULL CHECK (SoLuong > 0),
    DonGia      DECIMAL(18,2) NOT NULL CHECK (DonGia >= 0),
    ThanhTien   AS (SoLuong * DonGia) PERSISTED,
    GiaVon      DECIMAL(18,2) NOT NULL DEFAULT 0,
    LoiNhuan    AS (SoLuong * DonGia - SoLuong * GiaVon) PERSISTED,
    GhiChu      NVARCHAR(255) NULL
);
GO

-- 2.8 Dịch vụ 2: Cho thuê sảnh & Hội nghị sự kiện
IF OBJECT_ID('KhuVucSuKien', 'U') IS NOT NULL DROP TABLE KhuVucSuKien;
CREATE TABLE KhuVucSuKien (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    TenKhuVuc       NVARCHAR(100) NOT NULL UNIQUE,
    LoaiKhuVuc      NVARCHAR(50)  NOT NULL,
    SucChua         INT           NOT NULL CHECK (SucChua > 0),
    GiaThueTheoGio  DECIMAL(18,2) NOT NULL CHECK (GiaThueTheoGio >= 0),
    TrangThietBi    NVARCHAR(500) NULL,
    -- TrangThai lưu trạng thái khai thác của khu vực ('Hoạt động' / 'Ngừng khai thác').
    -- Trạng thái thời gian thực (Trống / Đang sử dụng / Đang dọn) tính động qua vw_TrangThaiKhuVucHienTai.
    TrangThai       NVARCHAR(30)  NOT NULL DEFAULT N'Hoạt động'
                        CHECK (TrangThai IN (N'Hoạt động', N'Ngừng khai thác'))
);
GO

IF OBJECT_ID('DonDatSuKien', 'U') IS NOT NULL DROP TABLE DonDatSuKien;
CREATE TABLE DonDatSuKien (
    Id                      INT IDENTITY(1,1) PRIMARY KEY,
    MaDon                   NVARCHAR(30) NOT NULL UNIQUE,
    KhuVucId                INT NOT NULL FOREIGN KEY REFERENCES KhuVucSuKien(Id),
    KhachHangId             INT NULL FOREIGN KEY REFERENCES KhachHang(Id),
    TenKhach                NVARCHAR(100) NOT NULL,
    SoDienThoai             NVARCHAR(20) NOT NULL,
    SoPhong                 NVARCHAR(20) NULL,
    ThoiGianBatDau          DATETIME NOT NULL,
    ThoiGianKetThuc         DATETIME NOT NULL,
    ThoiGianDonDepPhut      INT NULL CHECK (ThoiGianDonDepPhut IS NULL OR ThoiGianDonDepPhut >= 0),
    PhuThuRutNganDonDep     DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (PhuThuRutNganDonDep >= 0),
    GhiChuRutNganDonDep     NVARCHAR(255) NULL,
    TienCoc                 DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (TienCoc >= 0),
    TongTienDuKien          DECIMAL(18,2) NOT NULL CHECK (TongTienDuKien >= 0),
    ChiPhiPhatSinh          DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (ChiPhiPhatSinh >= 0),
    DaThanhToan             BIT NOT NULL DEFAULT 0,
    GhiChuHuHai             NVARCHAR(500) NULL,
    HinhThucThanhToanBanDau NVARCHAR(20) NOT NULL DEFAULT N'Đặt cọc trước'
                                CHECK (HinhThucThanhToanBanDau IN (N'Đặt cọc trước', N'Thanh toán toàn bộ')),
    TrangThaiDon            NVARCHAR(30) NOT NULL DEFAULT N'Đã đặt'
                                CHECK (TrangThaiDon IN (
                                    N'Đã đặt', N'Đang sử dụng', N'Hoàn tất',
                                    N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')),
    ThoiGianHuy             DATETIME NULL,
    LyDoHuy                 NVARCHAR(255) NULL,
    NguoiHuyId              INT NULL FOREIGN KEY REFERENCES NhanVien(Id),
    SoTienHoanCoc           DECIMAL(18,2) NULL,
    NguoiTaoId              INT NOT NULL FOREIGN KEY REFERENCES NhanVien(Id),
    NguoiThanhToanId        INT NULL     FOREIGN KEY REFERENCES NhanVien(Id),
    ThoiGianThanhToan       DATETIME NULL,
    NgayTao                 DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_SuKien_ThoiGian CHECK (ThoiGianKetThuc > ThoiGianBatDau),
    CONSTRAINT CK_DonDatSuKien_TienCoc CHECK (TienCoc <= TongTienDuKien),
    CONSTRAINT CK_DonDatSuKien_XacNhanTT CHECK (
        (DaThanhToan = 0 AND NguoiThanhToanId IS NULL AND ThoiGianThanhToan IS NULL) OR
        (DaThanhToan = 1 AND NguoiThanhToanId IS NOT NULL AND ThoiGianThanhToan IS NOT NULL)
    ),
    CONSTRAINT CK_DonDatSuKien_Huy CHECK (
        (TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')
            AND ThoiGianHuy IS NULL AND NguoiHuyId IS NULL AND SoTienHoanCoc IS NULL) OR
        (TrangThaiDon IN (N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')
            AND ThoiGianHuy IS NOT NULL AND NguoiHuyId IS NOT NULL AND SoTienHoanCoc IS NOT NULL)
    ),
    CONSTRAINT CK_DonDatSuKien_HuyHoanCoc CHECK (TrangThaiDon NOT LIKE N'Đã hủy%' OR DaThanhToan = 0)
);
GO
CREATE INDEX IX_DonDatSuKien_KhuVuc_ThoiGian ON DonDatSuKien(KhuVucId, ThoiGianBatDau, ThoiGianKetThuc);
GO

-- 2.9 Dịch vụ 3: Cho thuê xe máy (XeChoThue và DonThueXe)
IF OBJECT_ID('DonDatXeChoThue', 'V') IS NOT NULL DROP VIEW DonDatXeChoThue;
IF OBJECT_ID('DonThueXe', 'U') IS NOT NULL DROP TABLE DonThueXe;
IF OBJECT_ID('XeChoThue', 'U') IS NOT NULL DROP TABLE XeChoThue;
CREATE TABLE XeChoThue (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    BienSo              NVARCHAR(20) NOT NULL UNIQUE,
    TenXe               NVARCHAR(100) NOT NULL,
    LoaiXe              NVARCHAR(30) NOT NULL,
    GiaThueNgay         DECIMAL(18,2) NOT NULL CHECK (GiaThueNgay >= 0),
    TienCocQuyDinh      DECIMAL(18,2) NOT NULL DEFAULT 500000 CHECK (TienCocQuyDinh >= 0),
    TrangThai           NVARCHAR(30) NOT NULL DEFAULT N'Hoạt động'
                            CHECK (TrangThai IN (N'Hoạt động', N'Sẵn sàng', N'Bảo trì', N'Ngừng khai thác')),
    GhiChuTinhTrang     NVARCHAR(255) NULL
);
GO

CREATE TABLE DonThueXe (
    Id                      INT IDENTITY(1,1) PRIMARY KEY,
    MaDon                   NVARCHAR(30) NOT NULL UNIQUE,
    XeId                    INT NOT NULL FOREIGN KEY REFERENCES XeChoThue(Id),
    KhachHangId             INT NULL FOREIGN KEY REFERENCES KhachHang(Id),
    TenKhach                NVARCHAR(100) NOT NULL,
    CCCD                    NVARCHAR(20) NOT NULL,
    SoDienThoai             NVARCHAR(20) NOT NULL,
    SoPhong                 NVARCHAR(20) NULL,
    NgayThue                DATETIME NOT NULL,
    NgayTraDuKien           DATETIME NOT NULL,
    NgayTraThucTe           DATETIME NULL,
    ThoiGianKiemTraXePhut   INT NULL CHECK (ThoiGianKiemTraXePhut IS NULL OR ThoiGianKiemTraXePhut >= 0),
    PhuThuRutNganBuffer     DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (PhuThuRutNganBuffer >= 0),
    GhiChuRutNganBuffer     NVARCHAR(255) NULL,
    TienCoc                 DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (TienCoc >= 0),
    TienThue                DECIMAL(18,2) NOT NULL CHECK (TienThue >= 0),
    ChiPhiPhatSinh          DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (ChiPhiPhatSinh >= 0),
    TongTienThanhToan       DECIMAL(18,2) NOT NULL DEFAULT 0,
    DaThanhToan             BIT NOT NULL DEFAULT 0,
    GhiChuKhiNhanXe         NVARCHAR(500) NULL,
    GhiChuHuHai             NVARCHAR(500) NULL,
    HinhThucThanhToanBanDau NVARCHAR(20) NOT NULL DEFAULT N'Đặt cọc trước'
                                CHECK (HinhThucThanhToanBanDau IN (N'Đặt cọc trước', N'Thanh toán toàn bộ')),
    TrangThaiDon            NVARCHAR(30) NOT NULL DEFAULT N'Đã đặt'
                                CHECK (TrangThaiDon IN (
                                    N'Đã đặt', N'Đang thuê', N'Hoàn tất',
                                    N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')),
    ThoiGianHuy             DATETIME NULL,
    LyDoHuy                 NVARCHAR(255) NULL,
    NguoiHuyId              INT NULL FOREIGN KEY REFERENCES NhanVien(Id),
    SoTienHoanCoc           DECIMAL(18,2) NULL,
    NguoiTaoId              INT NOT NULL FOREIGN KEY REFERENCES NhanVien(Id),
    NguoiThanhToanId        INT NULL     FOREIGN KEY REFERENCES NhanVien(Id),
    ThoiGianThanhToan       DATETIME NULL,
    NgayTao                 DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_ThueXe_NgayTra CHECK (NgayTraDuKien > NgayThue),
    CONSTRAINT CK_DonThueXe_TienCoc CHECK (TienCoc <= TienThue),
    CONSTRAINT CK_DonThueXe_XacNhanTT CHECK (
        (DaThanhToan = 0 AND NguoiThanhToanId IS NULL AND ThoiGianThanhToan IS NULL) OR
        (DaThanhToan = 1 AND NguoiThanhToanId IS NOT NULL AND ThoiGianThanhToan IS NOT NULL)
    ),
    CONSTRAINT CK_DonThueXe_Huy CHECK (
        (TrangThaiDon NOT IN (N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')
            AND ThoiGianHuy IS NULL AND NguoiHuyId IS NULL AND SoTienHoanCoc IS NULL) OR
        (TrangThaiDon IN (N'Đã hủy - Hoàn cọc', N'Đã hủy - Không hoàn cọc')
            AND ThoiGianHuy IS NOT NULL AND NguoiHuyId IS NOT NULL AND SoTienHoanCoc IS NOT NULL)
    ),
    CONSTRAINT CK_DonThueXe_HuyHoanCoc CHECK (TrangThaiDon NOT LIKE N'Đã hủy%' OR DaThanhToan = 0)
);
GO
CREATE INDEX IX_DonThueXe_Xe_ThoiGian ON DonThueXe(XeId, NgayThue, NgayTraDuKien);
GO

-- 2.10 Dịch vụ 4: Bãi & Hầm đỗ xe
IF OBJECT_ID('BaiDoXe', 'U') IS NOT NULL DROP TABLE BaiDoXe;
CREATE TABLE BaiDoXe (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    MaVe                NVARCHAR(30) NOT NULL UNIQUE,
    BienSoXe            NVARCHAR(20) NOT NULL,
    LoaiXe              NVARCHAR(30) NOT NULL CHECK (LoaiXe IN (N'Xe máy', N'Ô tô')),
    TenKhach            NVARCHAR(100) NULL,
    SoDienThoai         NVARCHAR(20) NULL,
    SoPhong             NVARCHAR(20) NULL,
    ThoiGianVao         DATETIME NOT NULL DEFAULT GETDATE(),
    ThoiGianRa          DATETIME NULL,
    HinhThucGui         NVARCHAR(30) NOT NULL DEFAULT N'Theo lượt'
                            CHECK (HinhThucGui IN (N'Theo lượt', N'Theo tiếng', N'Theo giờ', N'Theo ngày', N'Khách phòng (Miễn phí)')),
    PhiGui              DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (PhiGui >= 0),
    DaThanhToan         BIT NOT NULL DEFAULT 0,
    GhiChuSuaChua       NVARCHAR(255) NULL,
    NguoiTaoId          INT NOT NULL FOREIGN KEY REFERENCES NhanVien(Id),
    NguoiThanhToanId    INT NULL     FOREIGN KEY REFERENCES NhanVien(Id),
    ThoiGianThanhToan   DATETIME NULL,
    CONSTRAINT CK_BaiDoXe_ThoiGian CHECK (ThoiGianRa IS NULL OR ThoiGianRa >= ThoiGianVao),
    CONSTRAINT CK_BaiDoXe_XacNhanTT CHECK (
        (DaThanhToan = 0 AND NguoiThanhToanId IS NULL AND ThoiGianThanhToan IS NULL) OR
        (DaThanhToan = 1 AND NguoiThanhToanId IS NOT NULL AND ThoiGianThanhToan IS NOT NULL)
    )
);
GO

-- 2.11 Dịch vụ 5: Giặt ủi & Đối tác giặt ủi liên kết
IF OBJECT_ID('DonGiatUi', 'U') IS NOT NULL DROP TABLE DonGiatUi;
IF OBJECT_ID('BangGiaDoiTacGiatUi', 'U') IS NOT NULL DROP TABLE BangGiaDoiTacGiatUi;
IF OBJECT_ID('DoiTacGiatUi', 'U') IS NOT NULL DROP TABLE DoiTacGiatUi;
IF OBJECT_ID('LoaiDichVuGiatUi', 'U') IS NOT NULL DROP TABLE LoaiDichVuGiatUi;
GO

CREATE TABLE LoaiDichVuGiatUi (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    MaLoai              NVARCHAR(30)  NOT NULL UNIQUE,
    TenLoai             NVARCHAR(100) NOT NULL UNIQUE,
    DonGiaBanKg         DECIMAL(18,2) NOT NULL CHECK (DonGiaBanKg > 0),
    DonViTinh           NVARCHAR(20)  NOT NULL DEFAULT N'Kg',
    HeSoBoiThuongToiDa  INT           NOT NULL DEFAULT 10 CHECK (HeSoBoiThuongToiDa > 0),
    DangKinhDoanh       BIT           NOT NULL DEFAULT 1
);
GO

CREATE TABLE DoiTacGiatUi (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    TenDoiTac           NVARCHAR(100) NOT NULL UNIQUE,
    DiaChi              NVARCHAR(255) NULL,
    SoDienThoai         NVARCHAR(20)  NOT NULL,
    HanThanhToanCongNo  NVARCHAR(30)  NOT NULL DEFAULT N'Theo tháng'
                            CHECK (HanThanhToanCongNo IN (N'Theo tháng', N'Theo tuần', N'Theo đơn')),
    TyLeKhachSanHuong   DECIMAL(5,2)  NULL DEFAULT 30.00,
    TyLeDoiTacHuong     DECIMAL(5,2)  NULL DEFAULT 70.00,
    TrangThai           BIT           NOT NULL DEFAULT 1
);
GO

CREATE TABLE BangGiaDoiTacGiatUi (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    DoiTacId            INT NOT NULL FOREIGN KEY REFERENCES DoiTacGiatUi(Id) ON DELETE CASCADE,
    LoaiDichVuId        INT NOT NULL FOREIGN KEY REFERENCES LoaiDichVuGiatUi(Id) ON DELETE CASCADE,
    DonGiaVonKg         DECIMAL(18,2) NOT NULL CHECK (DonGiaVonKg >= 0),
    GhiChu              NVARCHAR(255) NULL,
    CONSTRAINT UQ_BangGiaDoiTac UNIQUE (DoiTacId, LoaiDichVuId)
);
GO

CREATE TABLE DonGiatUi (
    Id                      INT IDENTITY(1,1) PRIMARY KEY,
    MaDon                   NVARCHAR(30) NOT NULL UNIQUE,
    KhachHangId             INT NULL FOREIGN KEY REFERENCES KhachHang(Id),
    TenKhach                NVARCHAR(100) NOT NULL,
    SoDienThoai             NVARCHAR(20) NOT NULL,
    SoPhong                 NVARCHAR(20) NULL,
    LoaiDichVu              NVARCHAR(50) NOT NULL,
    KhoiLuongKg             DECIMAL(6,2) NOT NULL CHECK (KhoiLuongKg > 0),
    DonGiaKg                DECIMAL(18,2) NOT NULL CHECK (DonGiaKg >= 0),
    TongTienThuKhach        DECIMAL(18,2) NOT NULL DEFAULT 0,
    DoiTacId                INT NULL FOREIGN KEY REFERENCES DoiTacGiatUi(Id),
    DonGiaVonKg             DECIMAL(18,2) NULL,
    TienDoiTacNhan          DECIMAL(18,2) NOT NULL DEFAULT 0,
    TienKhachSanNhan        DECIMAL(18,2) NOT NULL DEFAULT 0,
    TinhTrangQuanAoLucNhan  NVARCHAR(255) NULL,
    NgayNhan                DATETIME NOT NULL DEFAULT GETDATE(),
    NgayGiaoDoiTac          DATETIME NULL,
    NgayHenTra              DATETIME NOT NULL,
    NgayTraThucTe           DATETIME NULL,
    ChiPhiPhatSinh          DECIMAL(18,2) NOT NULL DEFAULT 0,
    HinhThucThanhToan       NVARCHAR(50) NOT NULL DEFAULT N'Ghi nợ vào phòng',
    TrangThai               NVARCHAR(30) NOT NULL DEFAULT N'Chờ giao đối tác'
                                CHECK (TrangThai IN (N'Chờ giao đối tác', N'Đang giặt', N'Hoàn tất', N'Đã hủy')),
    DaThanhToan             BIT NOT NULL DEFAULT 0,
    NguoiTaoId              INT NOT NULL FOREIGN KEY REFERENCES NhanVien(Id),
    NguoiThanhToanId        INT NULL     FOREIGN KEY REFERENCES NhanVien(Id),
    ThoiGianThanhToan       DATETIME NULL,
    DaThanhToanChoDoiTac    BIT NOT NULL DEFAULT 0,
    NgayThanhToanChoDoiTac  DATETIME NULL,
    CoDenBu                 BIT NOT NULL DEFAULT 0,
    BenChiuTrachNhiem       NVARCHAR(50) NULL CHECK (BenChiuTrachNhiem IS NULL OR BenChiuTrachNhiem IN (N'KhachSan', N'DoiTac', N'KhongCo')),
    SoTienDenBu             DECIMAL(18,2) NOT NULL DEFAULT 0,
    LyDoDenBu               NVARCHAR(255) NULL,
    NgayGhiNhanDenBu        DATETIME NULL,
    NguoiGhiNhanDenBuId     INT NULL FOREIGN KEY REFERENCES NhanVien(Id),
    CONSTRAINT CK_DonGiatUi_ThoiGian CHECK (NgayHenTra >= NgayNhan),
    CONSTRAINT CK_DonGiatUi_DoiTac CHECK (
        (TrangThai IN (N'Chờ giao đối tác', N'Đã hủy')) OR (DoiTacId IS NOT NULL AND DoiTacId > 0)
    ),
    CONSTRAINT CK_DonGiatUi_Huy CHECK (TrangThai <> N'Đã hủy' OR DaThanhToan = 0),
    CONSTRAINT CK_GiatUi_XacNhanTT CHECK (
        (DaThanhToan = 0 AND NguoiThanhToanId IS NULL AND ThoiGianThanhToan IS NULL) OR
        (DaThanhToan = 1 AND NguoiThanhToanId IS NOT NULL AND ThoiGianThanhToan IS NOT NULL)
    )
);
GO
