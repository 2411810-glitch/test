using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Data.SqlClient;
using QuanLyDichVuKhachSan.Models;

namespace QuanLyDichVuKhachSan.Services
{
    /// <summary>
    /// =========================================================================================================
    /// LỚP TRUY XUẤT CƠ SỞ DỮ LIỆU SQL SERVER (DATABASE ACCESS LAYER - DAL)
    /// ĐỒNG BỘ 100% VỚI SCHEMA CHÍNH THỨC TRONG FILE Database/QuanLyDichVuKhachSan.sql
    /// =========================================================================================================
    /// </summary>
    public class DatabaseService
    {
        private static DatabaseService? _instance;
        public static DatabaseService Instance => _instance ??= new DatabaseService();

        public string? LastError { get; set; }

        private string _connectionString = "";
        public string ConnectionString
        {
            get
            {
                if (string.IsNullOrWhiteSpace(_connectionString))
                {
                    _connectionString = LoadConnectionStringFromConfig();
                }
                return _connectionString;
            }
            set => _connectionString = value;
        }

        public static string LoadConnectionStringFromConfig()
        {
            try
            {
                string jsonPath = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "appsettings.json");
                if (System.IO.File.Exists(jsonPath))
                {
                    string jsonContent = System.IO.File.ReadAllText(jsonPath);
                    using var doc = System.Text.Json.JsonDocument.Parse(jsonContent);
                    if (doc.RootElement.TryGetProperty("ConnectionStrings", out var connSection) &&
                        connSection.TryGetProperty("DefaultConnection", out var connElement))
                    {
                        string? connStr = connElement.GetString();
                        if (!string.IsNullOrWhiteSpace(connStr)) return connStr;
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[Config Warning] Không thể đọc appsettings.json: {ex.Message}");
            }

            return @"Server=.;Database=QuanLyDichVuKhachSan;Trusted_Connection=True;TrustServerCertificate=True;Pooling=true;Min Pool Size=5;Max Pool Size=100;Connect Timeout=5;MultipleActiveResultSets=True;Packet Size=8192;Application Name=QuanLyDichVuKhachSan;";
        }

        #region Helper Safe Methods for Column Mapping
        public static string SafeGetString(SqlDataReader reader, params string[] columnNames)
        {
            foreach (var col in columnNames)
            {
                try
                {
                    int ordinal = reader.GetOrdinal(col);
                    if (!reader.IsDBNull(ordinal))
                    {
                        return reader.GetValue(ordinal)?.ToString() ?? "";
                    }
                }
                catch { }
            }
            return "";
        }

        public static int SafeGetInt(SqlDataReader reader, params string[] columnNames)
        {
            foreach (var col in columnNames)
            {
                try
                {
                    int ordinal = reader.GetOrdinal(col);
                    if (!reader.IsDBNull(ordinal))
                    {
                        return Convert.ToInt32(reader.GetValue(ordinal));
                    }
                }
                catch { }
            }
            return 0;
        }

        public static int? SafeGetNullableInt(SqlDataReader reader, params string[] columnNames)
        {
            foreach (var col in columnNames)
            {
                try
                {
                    int ordinal = reader.GetOrdinal(col);
                    if (!reader.IsDBNull(ordinal))
                    {
                        return Convert.ToInt32(reader.GetValue(ordinal));
                    }
                }
                catch { }
            }
            return null;
        }

        public static bool SafeGetBool(SqlDataReader reader, params string[] columnNames)
        {
            foreach (var col in columnNames)
            {
                try
                {
                    int ordinal = reader.GetOrdinal(col);
                    if (!reader.IsDBNull(ordinal))
                    {
                        var val = reader.GetValue(ordinal);
                        if (val is bool b) return b;
                        if (val is int i) return i == 1;
                        if (val is byte by) return by == 1;
                        string s = val.ToString() ?? "";
                        return s.Equals("True", StringComparison.OrdinalIgnoreCase) || s.Equals("1");
                    }
                }
                catch { }
            }
            return false;
        }

        public static decimal SafeGetDecimal(SqlDataReader reader, params string[] columnNames)
        {
            foreach (var col in columnNames)
            {
                try
                {
                    int ordinal = reader.GetOrdinal(col);
                    if (!reader.IsDBNull(ordinal))
                    {
                        return Convert.ToDecimal(reader.GetValue(ordinal));
                    }
                }
                catch { }
            }
            return 0;
        }

        public static decimal? SafeGetNullableDecimal(SqlDataReader reader, params string[] columnNames)
        {
            foreach (var col in columnNames)
            {
                try
                {
                    int ordinal = reader.GetOrdinal(col);
                    if (!reader.IsDBNull(ordinal))
                    {
                        return Convert.ToDecimal(reader.GetValue(ordinal));
                    }
                }
                catch { }
            }
            return null;
        }

        public static TimeSpan SafeGetTimeSpan(SqlDataReader reader, params string[] columnNames)
        {
            foreach (var col in columnNames)
            {
                try
                {
                    int ordinal = reader.GetOrdinal(col);
                    if (!reader.IsDBNull(ordinal))
                    {
                        var val = reader.GetValue(ordinal);
                        if (val is TimeSpan ts) return ts;
                        if (TimeSpan.TryParse(val.ToString(), out var parsed)) return parsed;
                    }
                }
                catch { }
            }
            return TimeSpan.Zero;
        }

        private static readonly string[] SupportedDateFormats = new[]
        {
            "dd/MM/yyyy",
            "dd/MM/yyyy HH:mm",
            "dd/MM/yyyy HH:mm:ss",
            "yyyy-MM-dd",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-ddTHH:mm:ss",
            "yyyy-MM-ddTHH:mm:ss.fff",
            "MM/dd/yyyy",
            "MM/dd/yyyy HH:mm:ss"
        };

        public static bool TryParseFlexibleDateTime(object? val, out DateTime result)
        {
            result = DateTime.Today;
            if (val == null || val is DBNull) return false;
            if (val is DateTime dt) { result = dt; return true; }

            string str = val.ToString()?.Trim() ?? "";
            if (string.IsNullOrEmpty(str)) return false;

            if (DateTime.TryParseExact(str, SupportedDateFormats, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out result))
                return true;

            if (DateTime.TryParse(str, System.Globalization.CultureInfo.GetCultureInfo("vi-VN"), System.Globalization.DateTimeStyles.None, out result))
                return true;

            if (DateTime.TryParse(str, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out result))
                return true;

            return false;
        }

        public static DateTime SafeGetDateTime(SqlDataReader reader, params string[] columnNames)
        {
            foreach (var col in columnNames)
            {
                try
                {
                    int ordinal = reader.GetOrdinal(col);
                    if (!reader.IsDBNull(ordinal))
                    {
                        var val = reader.GetValue(ordinal);
                        if (TryParseFlexibleDateTime(val, out var parsed)) return parsed;
                    }
                }
                catch { }
            }
            return DateTime.Today;
        }

        public static DateTime? SafeGetNullableDateTime(SqlDataReader reader, params string[] columnNames)
        {
            foreach (var col in columnNames)
            {
                try
                {
                    int ordinal = reader.GetOrdinal(col);
                    if (!reader.IsDBNull(ordinal))
                    {
                        var val = reader.GetValue(ordinal);
                        if (TryParseFlexibleDateTime(val, out var parsed)) return parsed;
                    }
                }
                catch { }
            }
            return null;
        }
        #endregion

        public bool TestConnection()
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                return conn.State == ConnectionState.Open;
            }
            catch
            {
                return false;
            }
        }

        #region Master Data Readers

        /// <summary>
        /// Đọc toàn bộ danh sách phòng từ CSDL SQL Server (Table PhongKhachSan)
        /// </summary>
        public List<HotelRoom> LoadRoomsFromDb()
        {
            var dict = new Dictionary<string, HotelRoom>(StringComparer.OrdinalIgnoreCase);
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                EnsureRoomPriceColumn(conn);
                string query = "SELECT * FROM PhongKhachSan ORDER BY Tang, SoPhong";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                int id = 1;
                while (reader.Read())
                {
                    string roomNum = SafeGetString(reader, "SoPhong", "RoomNumber");
                    if (string.IsNullOrWhiteSpace(roomNum)) continue;

                    string roomType = SafeGetString(reader, "LoaiPhong", "RoomType");
                    decimal roomPrice = SafeGetDecimal(reader, "GiaPhong", "PricePerNight");
                    if (roomPrice <= 0)
                        roomPrice = roomType.Contains("đôi", StringComparison.OrdinalIgnoreCase) ? 800000m : 500000m;

                    string statusStr = SafeGetString(reader, "TrangThai", "Status");
                    RoomStatus status = RoomStatus.Available;
                    if (statusStr.Equals("Occupied", StringComparison.OrdinalIgnoreCase) || statusStr.Contains("ở") || statusStr.Contains("khách"))
                        status = RoomStatus.Occupied;
                    else if (statusStr.Equals("Cleaning", StringComparison.OrdinalIgnoreCase) || statusStr.Contains("dọn"))
                        status = RoomStatus.Cleaning;
                    else if (statusStr.Equals("Maintenance", StringComparison.OrdinalIgnoreCase) || statusStr.Contains("sửa") || statusStr.Contains("Bảo trì"))
                        status = RoomStatus.Maintenance;

                    dict[roomNum] = new HotelRoom
                    {
                        Id = SafeGetInt(reader, "Id") != 0 ? SafeGetInt(reader, "Id") : id++,
                        RoomNumber = roomNum,
                        Floor = SafeGetInt(reader, "Tang", "Floor"),
                        RoomType = SafeGetString(reader, "LoaiPhong", "RoomType"),
                        PricePerNight = roomPrice,
                        Status = status,
                        CustomerName = SafeGetString(reader, "TenKhach", "CustomerName"),
                        PhoneNumber = SafeGetString(reader, "SoDienThoai", "PhoneNumber", "Phone"),
                        IdentityCard = SafeGetString(reader, "CCCD", "CMND", "IdentityCard"),
                        CheckInDate = SafeGetNullableDateTime(reader, "NgayNhanPhong", "CheckInDate"),
                        ExpectedCheckOutDate = SafeGetNullableDateTime(reader, "NgayTraPhong", "ExpectedCheckOutDate", "NgayDuKienTraPhong"),
                        Note = SafeGetString(reader, "GhiChu", "Note")
                    };
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadRoomsFromDb: {ex.Message}");
            }
            return dict.Values.ToList();
        }

        private static bool _invoiceTablesChecked = false;

        private static void EnsureInvoiceTables(SqlConnection conn)
        {
            if (_invoiceTablesChecked) return;
            try
            {
                string ddl = @"
                    IF OBJECT_ID('HoaDon', 'U') IS NULL
                    BEGIN
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
                        CREATE INDEX IX_HoaDon_SoPhong_NgayLap ON HoaDon(SoPhong, NgayLap);
                    END;
                    IF OBJECT_ID('ChiTietHoaDon', 'U') IS NULL
                    BEGIN
                        CREATE TABLE ChiTietHoaDon (
                            Id              INT IDENTITY(1,1) PRIMARY KEY,
                            HoaDonId        INT           NOT NULL FOREIGN KEY REFERENCES HoaDon(Id) ON DELETE CASCADE,
                            LoaiDichVu      NVARCHAR(50)  NULL,
                            TenDichVu       NVARCHAR(200) NULL,
                            ThoiGian        DATETIME      NULL,
                            SoTien          DECIMAL(18,2) NOT NULL DEFAULT 0
                        );
                    END";
                using var cmd = new SqlCommand(ddl, conn);
                cmd.ExecuteNonQuery();
                _invoiceTablesChecked = true;
            }
            catch { }
        }

        /// <summary>
        /// Lưu hóa đơn quyết toán phòng (tiền phòng + dịch vụ) xuống CSDL.
        /// </summary>
        public bool SaveInvoice(RoomInvoice invoice)
        {
            if (invoice == null) return false;
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                EnsureInvoiceTables(conn);
                using var transaction = conn.BeginTransaction();

                string roomNumber = invoice.RoomNumber;
                int bracketIndex = roomNumber.IndexOf(" (", StringComparison.Ordinal);
                if (bracketIndex > 0) roomNumber = roomNumber.Substring(0, bracketIndex).Trim();

                int invoiceId;
                using (var cmd = new SqlCommand(@"
                    INSERT INTO HoaDon (MaHoaDon, SoPhong, TenKhach, SoDienThoai, CCCD, NgayLap, NgayNhan, NgayTra, SoDem, GiaPhong, TienPhong, TienDichVu, TongTien, NguoiLap, NguoiThu)
                    OUTPUT INSERTED.Id
                    VALUES (@Ma, @Phong, @Ten, @SDT, @CCCD, @NgayLap, @NgayNhan, @NgayTra, @SoDem, @Gia, @TienPhong, @TienDV, @Tong, @NguoiLap, @NguoiThu)", conn, transaction))
                {
                    cmd.Parameters.AddWithValue("@Ma", invoice.InvoiceCode);
                    cmd.Parameters.AddWithValue("@Phong", roomNumber);
                    cmd.Parameters.AddWithValue("@Ten", (object?)invoice.CustomerName ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@SDT", (object?)invoice.PhoneNumber ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@CCCD", (object?)invoice.IdentityCard ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@NgayLap", invoice.InvoiceDate);
                    cmd.Parameters.AddWithValue("@NgayNhan", (object?)invoice.CheckInDate ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@NgayTra", (object?)invoice.CheckOutDate ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@SoDem", invoice.StayNights);
                    cmd.Parameters.AddWithValue("@Gia", invoice.PricePerNight);
                    cmd.Parameters.AddWithValue("@TienPhong", invoice.RoomCost);
                    cmd.Parameters.AddWithValue("@TienDV", invoice.ServicesCost);
                    cmd.Parameters.AddWithValue("@Tong", invoice.TotalAmount);
                    cmd.Parameters.AddWithValue("@NguoiLap", (object?)invoice.IssuedBy ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@NguoiThu", (object?)invoice.PaidBy ?? DBNull.Value);
                    invoiceId = Convert.ToInt32(cmd.ExecuteScalar());
                }

                if (invoice.PaidItems != null)
                {
                    foreach (var item in invoice.PaidItems)
                    {
                        using var cmd = new SqlCommand(@"
                            INSERT INTO ChiTietHoaDon (HoaDonId, LoaiDichVu, TenDichVu, ThoiGian, SoTien)
                            VALUES (@HoaDonId, @Loai, @Ten, @ThoiGian, @SoTien)", conn, transaction);
                        cmd.Parameters.AddWithValue("@HoaDonId", invoiceId);
                        cmd.Parameters.AddWithValue("@Loai", (object?)item.ServiceCategory ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@Ten", (object?)item.ServiceName ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@ThoiGian", (object?)item.UsedTime ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@SoTien", item.Amount);
                        cmd.ExecuteNonQuery();
                    }
                }

                transaction.Commit();
                invoice.Id = invoiceId;
                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] SaveInvoice: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Nạp lại lịch sử hóa đơn quyết toán phòng từ CSDL.
        /// </summary>
        public List<RoomInvoice> LoadInvoicesFromDb()
        {
            var list = new List<RoomInvoice>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                EnsureInvoiceTables(conn);

                var map = new Dictionary<int, RoomInvoice>();
                using (var cmd = new SqlCommand("SELECT * FROM HoaDon ORDER BY NgayLap DESC, Id DESC", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        int id = SafeGetInt(reader, "Id");
                        var invoice = new RoomInvoice
                        {
                            Id = id,
                            InvoiceCode = SafeGetString(reader, "MaHoaDon"),
                            RoomNumber = SafeGetString(reader, "SoPhong"),
                            CustomerName = SafeGetString(reader, "TenKhach"),
                            PhoneNumber = SafeGetString(reader, "SoDienThoai"),
                            IdentityCard = SafeGetString(reader, "CCCD"),
                            InvoiceDate = SafeGetNullableDateTime(reader, "NgayLap") ?? DateTime.Now,
                            CheckInDate = SafeGetNullableDateTime(reader, "NgayNhan"),
                            CheckOutDate = SafeGetNullableDateTime(reader, "NgayTra"),
                            StayNights = SafeGetInt(reader, "SoDem"),
                            PricePerNight = SafeGetDecimal(reader, "GiaPhong"),
                            RoomCost = SafeGetDecimal(reader, "TienPhong"),
                            ServicesCost = SafeGetDecimal(reader, "TienDichVu"),
                            TotalAmount = SafeGetDecimal(reader, "TongTien"),
                            IssuedBy = SafeGetString(reader, "NguoiLap"),
                            PaidBy = SafeGetString(reader, "NguoiThu"),
                            PaidItems = new List<RoomServiceUsageItem>()
                        };
                        map[id] = invoice;
                        list.Add(invoice);
                    }
                }

                using (var cmd = new SqlCommand("SELECT * FROM ChiTietHoaDon ORDER BY Id", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        int invoiceId = SafeGetInt(reader, "HoaDonId");
                        if (!map.TryGetValue(invoiceId, out var invoice)) continue;

                        invoice.PaidItems.Add(new RoomServiceUsageItem
                        {
                            ServiceCategory = SafeGetString(reader, "LoaiDichVu"),
                            ServiceName = SafeGetString(reader, "TenDichVu"),
                            UsedTime = SafeGetNullableDateTime(reader, "ThoiGian") ?? invoice.InvoiceDate,
                            Amount = SafeGetDecimal(reader, "SoTien"),
                            IsPaid = true
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadInvoicesFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// <summary>
        /// Cập nhật trực tiếp thông tin khách hàng, ngày nhận/trả phòng xuống bảng PhongKhachSan (Bất đồng bộ - Không chặn UI)
        /// </summary>
        public async Task<bool> UpdateRoomGuestInfoAsync(HotelRoom room)
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                await conn.OpenAsync();
                string statusStr = room.Status switch
                {
                    RoomStatus.Occupied => "Đang ở",
                    RoomStatus.Cleaning => "Đang dọn",
                    RoomStatus.Maintenance => "Bảo trì",
                    _ => "Trống"
                };

                string query = @"
                    UPDATE PhongKhachSan 
                    SET TrangThai = @TrangThai,
                        TenKhach = @TenKhach,
                        SoDienThoai = @SoDienThoai,
                        CCCD = @CCCD,
                        GhiChu = @GhiChu,
                        NgayNhanPhong = @NgayNhanPhong,
                        NgayTraPhong = @NgayTraPhong
                    WHERE SoPhong = @SoPhong";

                using var cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@TrangThai", statusStr);
                cmd.Parameters.AddWithValue("@TenKhach", (object?)room.CustomerName ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@SoDienThoai", (object?)room.PhoneNumber ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@CCCD", (object?)room.IdentityCard ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@GhiChu", (object?)room.Note ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@NgayNhanPhong", (object?)room.CheckInDate ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@NgayTraPhong", (object?)room.ExpectedCheckOutDate ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@SoPhong", room.RoomNumber);

                return await cmd.ExecuteNonQueryAsync() > 0;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] UpdateRoomGuestInfoAsync: {ex.Message}");
                return false;
            }
        }

        public bool UpdateRoomGuestInfo(HotelRoom room)
        {
            return Task.Run(() => UpdateRoomGuestInfoAsync(room)).GetAwaiter().GetResult();
        }

        private static bool _monAnColumnsChecked = false;
        private static void EnsureMonAnColumnsExist(SqlConnection conn)
        {
            if (_monAnColumnsChecked) return;
            try
            {
                string ddl = @"
                    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MonAn' AND COLUMN_NAME = 'DonViNhapMacDinh')
                        ALTER TABLE MonAn ADD DonViNhapMacDinh NVARCHAR(50) NULL DEFAULT N'Thùng';
                    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MonAn' AND COLUMN_NAME = 'HeSoQuyDoiMacDinh')
                        ALTER TABLE MonAn ADD HeSoQuyDoiMacDinh INT NULL DEFAULT 24;";
                using var cmd = new SqlCommand(ddl, conn);
                cmd.ExecuteNonQuery();
                _monAnColumnsChecked = true;
            }
            catch { }
        }

        private static bool _roomPriceChecked = false;
        private static void EnsureRoomPriceColumn(SqlConnection conn)
        {
            if (_roomPriceChecked) return;
            try
            {
                bool exists;
                using (var check = new SqlCommand(
                    "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'PhongKhachSan' AND COLUMN_NAME = 'GiaPhong'", conn))
                {
                    exists = Convert.ToInt32(check.ExecuteScalar()) > 0;
                }

                if (!exists)
                {
                    using (var alter = new SqlCommand(
                        "ALTER TABLE PhongKhachSan ADD GiaPhong DECIMAL(18,2) NOT NULL CONSTRAINT DF_PhongKhachSan_GiaPhong DEFAULT 500000", conn))
                    {
                        alter.ExecuteNonQuery();
                    }

                    using (var update = new SqlCommand(
                        "UPDATE PhongKhachSan SET GiaPhong = CASE WHEN LoaiPhong = N'Phòng đôi' THEN 800000 ELSE 500000 END", conn))
                    {
                        update.ExecuteNonQuery();
                    }
                }

                _roomPriceChecked = true;
            }
            catch { }
        }

        /// <summary>
        /// Đọc toàn bộ danh sách Hàng hóa mini-bar từ CSDL SQL Server (Table MonAn)
        /// </summary>
        public List<FoodItem> LoadFoodItemsFromDb()
        {
            var list = new List<FoodItem>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                EnsureMonAnColumnsExist(conn);
                string query = "SELECT * FROM MonAn ORDER BY Id";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string foodName = SafeGetString(reader, "TenMon", "Name");
                    string rawImg = SafeGetString(reader, "HinhAnh", "ImageUrl");
                    string resolvedImg = FoodItem.GetDefaultIcon(foodName);
                    if (!string.IsNullOrWhiteSpace(rawImg) && !rawImg.EndsWith(".jpg", StringComparison.OrdinalIgnoreCase) && !rawImg.EndsWith(".png", StringComparison.OrdinalIgnoreCase) && rawImg.Length <= 4)
                    {
                        resolvedImg = rawImg;
                    }

                    int defaultConversion = SafeGetInt(reader, "HeSoQuyDoiMacDinh");
                    if (defaultConversion <= 0) defaultConversion = 24;

                    string defaultUnit = SafeGetString(reader, "DonViNhapMacDinh");
                    if (string.IsNullOrWhiteSpace(defaultUnit)) defaultUnit = "Thùng";

                    string retailUnit = SafeGetString(reader, "DonViTinh", "DonViBanLe");
                    if (string.IsNullOrWhiteSpace(retailUnit)) retailUnit = "Cái";

                    int lowStock = SafeGetInt(reader, "MucTonToiThieu", "NguongCanhBaoTon");
                    if (lowStock <= 0) lowStock = 10;

                    string category = SafeGetString(reader, "DanhMuc", "LoaiMon", "Category");
                    if (string.IsNullOrWhiteSpace(category))
                    {
                        category = (foodName.ToLower().Contains("lavie") || foodName.ToLower().Contains("coca") || foodName.ToLower().Contains("pepsi") || foodName.ToLower().Contains("nước") || foodName.ToLower().Contains("cà phê") || foodName.ToLower().Contains("trà") || foodName.ToLower().Contains("rượu")) ? "Thức uống" : "Đồ ăn";
                    }

                    string status = SafeGetString(reader, "TrangThai", "Status");
                    if (string.IsNullOrWhiteSpace(status) || status == "Còn hàng") status = "Đang phục vụ";

                    bool isDeleted = status == "Đã xóa";
                    DateTime? trashedDate = isDeleted ? DateTime.Now : null;

                    list.Add(new FoodItem
                    {
                        Id = SafeGetInt(reader, "Id"),
                        Name = foodName,
                        Category = category,
                        Price = SafeGetDecimal(reader, "GiaBan", "DonGia", "Price"),
                        RetailUnit = retailUnit,
                        DefaultImportUnit = defaultUnit,
                        DefaultConversionRate = defaultConversion,
                        AverageCostPrice = SafeGetDecimal(reader, "GiaVonBinhQuan"),
                        StockQuantity = SafeGetInt(reader, "SoLuongTonKho"),
                        LowStockThreshold = lowStock,
                        ImageUrl = resolvedImg,
                        Status = isDeleted ? "Ngừng kinh doanh" : status,
                        TrashedDate = trashedDate
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadFoodItemsFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Lập phiếu nhập kho nhiều dòng hàng thông qua Stored Procedure: sp_LapPhieuNhapKho (TVP kieu_ChiTietNhapKho)
        /// </summary>
        public async Task<int> LapPhieuNhapKhoAsync(string receiptCode, int supplierId, int staffId, string note, List<WarehouseReceiptDraftItem> items)
        {
            return await Task.Run(() =>
            {
                try
                {
                    using var conn = new SqlConnection(ConnectionString);
                    conn.Open();

                    // 1. Kiểm tra và đảm bảo MaPhieuNhap là DUY NHẤT
                    string finalCode = receiptCode;
                    int duplicateCount = 0;
                    while (true)
                    {
                        using var checkCmd = new SqlCommand("SELECT COUNT(1) FROM PhieuNhapKho WHERE MaPhieuNhap = @Code", conn);
                        checkCmd.Parameters.AddWithValue("@Code", finalCode);
                        int count = (int)(checkCmd.ExecuteScalar() ?? 0);
                        if (count == 0) break;

                        duplicateCount++;
                        finalCode = $"{receiptCode}-{duplicateCount:D2}";
                    }

                    // 2. Đảm bảo NguoiNhapId & NhaCungCapId hợp lệ
                    int validStaffId = staffId;
                    using (var checkStaff = new SqlCommand("SELECT TOP 1 Id FROM NhanVien WHERE Id = @Id", conn))
                    {
                        checkStaff.Parameters.AddWithValue("@Id", staffId);
                        var sObj = checkStaff.ExecuteScalar();
                        if (sObj == null)
                        {
                            using var getFirstStaff = new SqlCommand("SELECT TOP 1 Id FROM NhanVien ORDER BY Id", conn);
                            validStaffId = Convert.ToInt32(getFirstStaff.ExecuteScalar() ?? 1);
                        }
                    }

                    int validSupplierId = supplierId;
                    using (var checkSup = new SqlCommand("SELECT TOP 1 Id FROM NhaCungCap WHERE Id = @Id", conn))
                    {
                        checkSup.Parameters.AddWithValue("@Id", supplierId);
                        var supObj = checkSup.ExecuteScalar();
                        if (supObj == null)
                        {
                            using var getFirstSup = new SqlCommand("SELECT TOP 1 Id FROM NhaCungCap ORDER BY Id", conn);
                            validSupplierId = Convert.ToInt32(getFirstSup.ExecuteScalar() ?? 1);
                        }
                    }

                    // 3. Thử gọi Stored Procedure: sp_LapPhieuNhapKho
                    try
                    {
                        using var cmd = new SqlCommand("sp_LapPhieuNhapKho", conn)
                        {
                            CommandType = CommandType.StoredProcedure
                        };

                        cmd.Parameters.AddWithValue("@MaPhieuNhap", finalCode);
                        cmd.Parameters.AddWithValue("@NhaCungCapId", validSupplierId);
                        cmd.Parameters.AddWithValue("@NguoiNhapId", validStaffId);
                        cmd.Parameters.AddWithValue("@GhiChu", string.IsNullOrWhiteSpace(note) ? (object)DBNull.Value : note);

                        var tvpTable = new System.Data.DataTable();
                        tvpTable.Columns.Add("MonAnId", typeof(int));
                        tvpTable.Columns.Add("DonViNhap", typeof(string));
                        tvpTable.Columns.Add("HeSoQuyDoi", typeof(int));
                        tvpTable.Columns.Add("SoLuongNhap", typeof(int));
                        tvpTable.Columns.Add("DonGiaNhap", typeof(decimal));
                        tvpTable.Columns.Add("SoLo", typeof(string));
                        tvpTable.Columns.Add("HanSuDung", typeof(DateTime));
                        tvpTable.Columns.Add("GhiChu", typeof(string));

                        foreach (var item in items)
                        {
                            tvpTable.Rows.Add(
                                item.FoodItemId,
                                item.ImportUnit,
                                item.ConversionRate > 0 ? item.ConversionRate : 1,
                                item.Quantity > 0 ? item.Quantity : 1,
                                item.ImportPrice,
                                string.IsNullOrWhiteSpace(item.BatchNumber) ? DBNull.Value : item.BatchNumber,
                                item.ExpiryDate.HasValue ? (object)item.ExpiryDate.Value.Date : DBNull.Value,
                                string.IsNullOrWhiteSpace(item.Note) ? DBNull.Value : item.Note
                            );
                        }

                        var tvpParam = cmd.Parameters.AddWithValue("@ChiTiet", tvpTable);
                        tvpParam.SqlDbType = SqlDbType.Structured;
                        tvpParam.TypeName = "kieu_ChiTietNhapKho";

                        var outParam = new SqlParameter("@PhieuNhapId", SqlDbType.Int)
                        {
                            Direction = ParameterDirection.Output
                        };
                        cmd.Parameters.Add(outParam);

                        cmd.ExecuteNonQuery();
                        if (outParam.Value is int id && id > 0) return id;
                    }
                    catch (Exception spEx)
                    {
                        System.Diagnostics.Debug.WriteLine($"[sp_LapPhieuNhapKho fallback to Direct SQL]: {spEx.Message}");
                    }

                    // 4. Fallback: Thực thi trực tiếp Transaction T-SQL nếu Stored Procedure chưa tạo hoặc gặp lỗi
                    using var tran = conn.BeginTransaction();
                    try
                    {
                        string insertHeader = @"
                            INSERT INTO PhieuNhapKho (MaPhieuNhap, NhaCungCapId, NguoiNhapId, GhiChu)
                            VALUES (@MaPhieuNhap, @NhaCungCapId, @NguoiNhapId, @GhiChu);
                            SELECT CAST(SCOPE_IDENTITY() AS INT);";

                        using var cmdHeader = new SqlCommand(insertHeader, conn, tran);
                        cmdHeader.Parameters.AddWithValue("@MaPhieuNhap", finalCode);
                        cmdHeader.Parameters.AddWithValue("@NhaCungCapId", validSupplierId);
                        cmdHeader.Parameters.AddWithValue("@NguoiNhapId", validStaffId);
                        cmdHeader.Parameters.AddWithValue("@GhiChu", string.IsNullOrWhiteSpace(note) ? (object)DBNull.Value : note);

                        int newReceiptId = Convert.ToInt32(cmdHeader.ExecuteScalar() ?? 1);

                        foreach (var item in items)
                        {
                            string insertDetail = @"
                                INSERT INTO ChiTietPhieuNhapKho (PhieuNhapId, MonAnId, DonViNhap, HeSoQuyDoi, SoLuongNhap, DonGiaNhap, SoLo, HanSuDung, GhiChu)
                                VALUES (@PhieuNhapId, @MonAnId, @DonViNhap, @HeSoQuyDoi, @SoLuongNhap, @DonGiaNhap, @SoLo, @HanSuDung, @GhiChu);";

                            using var cmdDetail = new SqlCommand(insertDetail, conn, tran);
                            cmdDetail.Parameters.AddWithValue("@PhieuNhapId", newReceiptId);
                            cmdDetail.Parameters.AddWithValue("@MonAnId", item.FoodItemId);
                            cmdDetail.Parameters.AddWithValue("@DonViNhap", item.ImportUnit);
                            cmdDetail.Parameters.AddWithValue("@HeSoQuyDoi", item.ConversionRate > 0 ? item.ConversionRate : 1);
                            cmdDetail.Parameters.AddWithValue("@SoLuongNhap", item.Quantity > 0 ? item.Quantity : 1);
                            cmdDetail.Parameters.AddWithValue("@DonGiaNhap", item.ImportPrice);
                            cmdDetail.Parameters.AddWithValue("@SoLo", string.IsNullOrWhiteSpace(item.BatchNumber) ? (object)DBNull.Value : item.BatchNumber);
                            cmdDetail.Parameters.AddWithValue("@HanSuDung", item.ExpiryDate.HasValue ? (object)item.ExpiryDate.Value.Date : DBNull.Value);
                            cmdDetail.Parameters.AddWithValue("@GhiChu", string.IsNullOrWhiteSpace(item.Note) ? (object)DBNull.Value : item.Note);

                            cmdDetail.ExecuteNonQuery();

                            // Chỉ cập nhật tồn kho & giá vốn thủ công nếu Trigger trg_ChiTietPhieuNhapKho_CongTonKho không tồn tại
                            string updateFood = @"
                                IF OBJECT_ID('trg_ChiTietPhieuNhapKho_CongTonKho', 'TR') IS NULL
                                BEGIN
                                    UPDATE MonAn
                                    SET GiaVonBinhQuan = CASE WHEN (SoLuongTonKho + (@SoLuongNhap * @HeSoQuyDoi)) > 0 
                                                              THEN ((SoLuongTonKho * GiaVonBinhQuan) + (@SoLuongNhap * @DonGiaNhap)) / (SoLuongTonKho + (@SoLuongNhap * @HeSoQuyDoi))
                                                              ELSE (@DonGiaNhap / @HeSoQuyDoi) END,
                                        SoLuongTonKho = SoLuongTonKho + (@SoLuongNhap * @HeSoQuyDoi)
                                    WHERE Id = @MonAnId;
                                END";
                            using var cmdFood = new SqlCommand(updateFood, conn, tran);
                            cmdFood.Parameters.AddWithValue("@SoLuongNhap", item.Quantity > 0 ? item.Quantity : 1);
                            cmdFood.Parameters.AddWithValue("@HeSoQuyDoi", item.ConversionRate > 0 ? item.ConversionRate : 1);
                            cmdFood.Parameters.AddWithValue("@DonGiaNhap", item.ImportPrice);
                            cmdFood.Parameters.AddWithValue("@MonAnId", item.FoodItemId);
                            cmdFood.ExecuteNonQuery();
                        }

                        tran.Commit();
                        return newReceiptId;
                    }
                    catch (Exception tranEx)
                    {
                        tran.Rollback();
                        System.Diagnostics.Debug.WriteLine($"[Direct SQL Error]: {tranEx.Message}");
                        return -1;
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[LapPhieuNhapKhoAsync Fatal Error]: {ex.Message}");
                    return -1;
                }
            });
        }

        /// <summary>
        /// Gọi Stored Procedure: sp_BaoCaoLoiNhuanKho
        /// </summary>
        public async Task<List<InventoryProfitReportItem>> GetInventoryProfitReportAsync(DateTime fromDate, DateTime toDate)
        {
            return await Task.Run(() =>
            {
                var list = new List<InventoryProfitReportItem>();
                try
                {
                    using var conn = new SqlConnection(ConnectionString);
                    conn.Open();
                    using var cmd = new SqlCommand("sp_BaoCaoLoiNhuanKho", conn)
                    {
                        CommandType = CommandType.StoredProcedure
                    };
                    cmd.Parameters.AddWithValue("@TuNgay", fromDate.Date);
                    cmd.Parameters.AddWithValue("@DenNgay", toDate.Date.AddDays(1).AddTicks(-1));

                    using var reader = cmd.ExecuteReader();
                    while (reader.Read())
                    {
                        list.Add(new InventoryProfitReportItem
                        {
                            FoodItemId = SafeGetInt(reader, "MonAnId"),
                            FoodItemName = SafeGetString(reader, "TenMon"),
                            QuantitySold = SafeGetInt(reader, "SoLuongDaBan"),
                            Revenue = SafeGetDecimal(reader, "DoanhThu"),
                            TotalCost = SafeGetDecimal(reader, "TongGiaVon"),
                            GrossProfit = SafeGetDecimal(reader, "LoiNhuanGop")
                        });
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[sp_BaoCaoLoiNhuanKho Error] {ex.Message}");
                }
                return list;
            });
        }

        /// <summary>
        /// Gọi Stored Procedure: sp_DatMonAn để trừ tồn kho và lấy giá vốn tại thời điểm bán
        /// </summary>
        public (bool Success, decimal CostPrice) DatMonAn(int foodId, int quantity)
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("sp_DatMonAn", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@MonAnId", foodId);
                cmd.Parameters.AddWithValue("@SoLuong", quantity);

                var pResult = new SqlParameter("@KetQua", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var pCost = new SqlParameter("@GiaVonTaiThoiDiemBan", SqlDbType.Decimal) { Direction = ParameterDirection.Output, Precision = 18, Scale = 2 };
                cmd.Parameters.Add(pResult);
                cmd.Parameters.Add(pCost);

                cmd.ExecuteNonQuery();
                int res = pResult.Value is int r ? r : 0;
                decimal cost = pCost.Value is decimal c ? c : 0;
                return (res == 1, cost);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[sp_DatMonAn Error] {ex.Message}");
                return (false, 0);
            }
        }

        /// <summary>
        /// Đọc toàn bộ danh sách Nhà Cung Cấp từ CSDL SQL Server (Table NhaCungCap)
        /// </summary>
        public List<Supplier> LoadSuppliersFromDb()
        {
            var list = new List<Supplier>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = "SELECT * FROM NhaCungCap ORDER BY Id";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    list.Add(new Supplier
                    {
                        Id = SafeGetInt(reader, "Id"),
                        Name = SafeGetString(reader, "TenNhaCungCap", "Name"),
                        Address = SafeGetString(reader, "DiaChi", "Address"),
                        PhoneNumber = SafeGetString(reader, "SoDienThoai", "PhoneNumber"),
                        ContactPerson = SafeGetString(reader, "NguoiLienHe", "ContactPerson"),
                        Note = SafeGetString(reader, "GhiChu", "Note"),
                        IsActive = SafeGetBool(reader, "TrangThai")
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadSuppliersFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Đọc toàn bộ Lịch sử Nhập kho từ CSDL SQL Server (Table ChiTietPhieuNhapKho & PhieuNhapKho)
        /// </summary>
        public List<InventoryBatch> LoadInventoryBatchesFromDb(List<FoodItem>? foodList = null)
        {
            var list = new List<InventoryBatch>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = @"
                    SELECT 
                        ct.Id AS ChiTietId,
                        pn.Id AS PhieuNhapId,
                        pn.MaPhieuNhap,
                        ct.MonAnId,
                        m.TenMon,
                        ct.DonViNhap,
                        ct.HeSoQuyDoi,
                        ct.SoLuongNhap,
                        ct.DonGiaNhap,
                        ct.SoLo,
                        ct.HanSuDung,
                        pn.NgayNhap,
                        nv.HoTen AS TenNguoiNhap,
                        ncc.TenNhaCungCap,
                        ct.GhiChu
                    FROM ChiTietPhieuNhapKho ct
                    JOIN PhieuNhapKho pn ON pn.Id = ct.PhieuNhapId
                    JOIN NhaCungCap ncc ON ncc.Id = pn.NhaCungCapId
                    LEFT JOIN NhanVien nv ON nv.Id = pn.NguoiNhapId
                    LEFT JOIN MonAn m ON m.Id = ct.MonAnId
                    ORDER BY pn.NgayNhap DESC, ct.Id DESC";

                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    int foodId = SafeGetInt(reader, "MonAnId");
                    string foodName = SafeGetString(reader, "TenMon");
                    if (string.IsNullOrWhiteSpace(foodName) && foodList != null)
                    {
                        var f = foodList.FirstOrDefault(x => x.Id == foodId);
                        if (f != null) foodName = f.Name;
                    }

                    int heSo = SafeGetInt(reader, "HeSoQuyDoi");
                    if (heSo <= 0) heSo = 1;

                    list.Add(new InventoryBatch
                    {
                        Id = SafeGetInt(reader, "ChiTietId"),
                        ReceiptId = SafeGetInt(reader, "PhieuNhapId"),
                        ReceiptCode = SafeGetString(reader, "MaPhieuNhap"),
                        FoodItemId = foodId,
                        FoodItemName = foodName,
                        ImportUnit = SafeGetString(reader, "DonViNhap") != "" ? SafeGetString(reader, "DonViNhap") : "Thùng",
                        ConversionRate = heSo,
                        Quantity = SafeGetInt(reader, "SoLuongNhap"),
                        ImportPrice = SafeGetDecimal(reader, "DonGiaNhap"),
                        BatchNumber = SafeGetString(reader, "SoLo"),
                        ExpiryDate = SafeGetNullableDateTime(reader, "HanSuDung"),
                        ImportDate = SafeGetDateTime(reader, "NgayNhap"),
                        ImportedBy = SafeGetString(reader, "TenNguoiNhap"),
                        Supplier = SafeGetString(reader, "TenNhaCungCap"),
                        Note = SafeGetString(reader, "GhiChu")
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadInventoryBatchesFromDb: {ex.Message}");
            }
            return list;
        }

        public bool UpdateFoodDefaultQuota(int foodId, int defaultQuota, bool applyToday = false)
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("sp_CapNhatQuotaMacDinhMonAn", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@MonAnId", foodId);
                cmd.Parameters.AddWithValue("@SoLuongMacDinhMoi", defaultQuota);
                cmd.Parameters.AddWithValue("@ApDungNgayHomNay", applyToday);
                cmd.ExecuteNonQuery();
                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] UpdateFoodDefaultQuota: {ex.Message}");
                _ = ExecuteNonQueryAsync(
                    "IF COL_LENGTH('MonAn', 'GioiHanMacDinh') IS NOT NULL " +
                    "EXEC sp_executesql N'UPDATE MonAn SET GioiHanMacDinh = @Quota, GioiHanNgay = CASE WHEN @Apply = 1 THEN @Quota ELSE GioiHanNgay END WHERE Id = @Id', N'@Quota INT, @Apply INT, @Id INT', @Quota=@Quota, @Apply=@Apply, @Id=@Id",
                    new SqlParameter("@Quota", defaultQuota),
                    new SqlParameter("@Apply", applyToday ? 1 : 0),
                    new SqlParameter("@Id", foodId));
                return true;
            }
        }

        public bool SetCustomQuotaForToday(int foodId, int customQuota)
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("sp_DatQuotaRiengChoLanResetKeTiep", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@MonAnId", foodId);
                cmd.Parameters.AddWithValue("@SoLuongRieng", customQuota);
                cmd.ExecuteNonQuery();
                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] SetCustomQuotaForToday: {ex.Message}");
                _ = ExecuteNonQueryAsync(
                    "IF COL_LENGTH('MonAn', 'GioiHanTuyChinhHomNay') IS NOT NULL " +
                    "EXEC sp_executesql N'UPDATE MonAn SET GioiHanTuyChinhHomNay = @Quota, GioiHanNgay = @Quota WHERE Id = @Id', N'@Quota INT, @Id INT', @Quota=@Quota, @Id=@Id",
                    new SqlParameter("@Quota", customQuota),
                    new SqlParameter("@Id", foodId));
                return true;
            }
        }

        /// <summary>
        /// Đọc toàn bộ Sảnh / Khu vực Sự kiện từ CSDL SQL Server (Table KhuVucSuKien)
        /// </summary>
        public List<EventSpace> LoadEventSpacesFromDb()
        {
            var list = new List<EventSpace>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = "SELECT * FROM KhuVucSuKien ORDER BY Id";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string statusStr = SafeGetString(reader, "TrangThai", "Status");
                    SpaceStatus status = SpaceStatus.Available;
                    if (statusStr.Contains("ngừng") || statusStr.Equals("Inactive", StringComparison.OrdinalIgnoreCase))
                        status = SpaceStatus.Maintenance;
                    else if (statusStr.Contains("cho thuê") || statusStr.Equals("Rented", StringComparison.OrdinalIgnoreCase))
                        status = SpaceStatus.Rented;
                    else if (statusStr.Contains("sửa") || statusStr.Contains("bảo trì") || statusStr.Equals("Maintenance", StringComparison.OrdinalIgnoreCase))
                        status = SpaceStatus.Maintenance;
                    else if (statusStr.Contains("dọn") || statusStr.Equals("Cleaning", StringComparison.OrdinalIgnoreCase))
                        status = SpaceStatus.Cleaning;

                    list.Add(new EventSpace
                    {
                        Id = SafeGetInt(reader, "Id"),
                        Name = SafeGetString(reader, "TenKhuVuc", "Name"),
                        SpaceType = SafeGetString(reader, "LoaiKhuVuc", "SpaceType"),
                        Capacity = SafeGetInt(reader, "SucChua", "Capacity"),
                        HourlyRate = SafeGetDecimal(reader, "GiaThueTheoGio", "HourlyRate"),
                        Equipments = SafeGetString(reader, "TrangThietBi", "Equipments"),
                        Status = status,
                        ImageUrl = SafeGetString(reader, "HinhAnh", "ImageUrl")
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadEventSpacesFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Tự động quyết toán các giao dịch mẫu đã qua trước ngày hôm nay (< CAST(GETDATE() AS DATE))
        /// chuyển sang trạng thái hoàn tất / đã thanh toán để phục vụ thống kê, đồng thời đảm bảo
        /// lịch phân công ca trực từ hôm nay đến hết tháng hiện tại.
        /// </summary>
        public void AutoSettlePastTransactions()
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string sql = @"
                    IF OBJECT_ID('sp_TuDongQuyetToanDuLieuCu', 'P') IS NOT NULL
                    BEGIN
                        EXEC sp_TuDongQuyetToanDuLieuCu;
                    END
                    ELSE
                    BEGIN
                        DECLARE @Today DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);

                        -- 1. Đơn hàng món ăn trước hôm nay (trừ đơn Đã hủy) -> Đã giao & Đã thanh toán
                        UPDATE DonHangMonAn
                        SET TrangThai = CASE WHEN TrangThai = N'Đã hủy' THEN N'Đã hủy' ELSE N'Đã giao' END,
                            DaThanhToan = CASE WHEN TrangThai = N'Đã hủy' THEN DaThanhToan ELSE 1 END,
                            NguoiThanhToanId = CASE WHEN TrangThai = N'Đã hủy' THEN NguoiThanhToanId ELSE ISNULL(NguoiThanhToanId, ISNULL(NguoiTaoId, 1)) END,
                            ThoiGianThanhToan = CASE WHEN TrangThai = N'Đã hủy' THEN ThoiGianThanhToan ELSE ISNULL(ThoiGianThanhToan, DATEADD(MINUTE, 20, NgayTao)) END
                        WHERE NgayTao < @Today AND (DaThanhToan = 0 OR TrangThai IN (N'Chờ xử lý', N'Đang chuẩn bị'));

                        -- 2. Đơn đặt sự kiện đã kết thúc trước hôm nay -> Hoàn tất & Đã thanh toán
                        UPDATE DonDatSuKien
                        SET TrangThaiDon = CASE WHEN TrangThaiDon LIKE N'Đã hủy%' THEN TrangThaiDon ELSE N'Hoàn tất' END,
                            DaThanhToan = 1,
                            NguoiThanhToanId = ISNULL(NguoiThanhToanId, ISNULL(NguoiHuyId, ISNULL(NguoiTaoId, 1))),
                            ThoiGianThanhToan = ISNULL(ThoiGianThanhToan, ISNULL(ThoiGianHuy, ThoiGianKetThuc))
                        WHERE ThoiGianKetThuc < @Today AND (DaThanhToan = 0 OR TrangThaiDon IN (N'Đã đặt', N'Đang sử dụng'));

                        -- 3. Đơn thuê xe có hạn trả trước hôm nay -> Hoàn tất & Đã thanh toán
                        UPDATE DonThueXe
                        SET TrangThaiDon = CASE WHEN TrangThaiDon LIKE N'Đã hủy%' THEN TrangThaiDon ELSE N'Hoàn tất' END,
                            NgayTraThucTe = CASE WHEN TrangThaiDon LIKE N'Đã hủy%' THEN NgayTraThucTe ELSE ISNULL(NgayTraThucTe, NgayTraDuKien) END,
                            DaThanhToan = 1,
                            NguoiThanhToanId = ISNULL(NguoiThanhToanId, ISNULL(NguoiHuyId, ISNULL(NguoiTaoId, 1))),
                            ThoiGianThanhToan = ISNULL(ThoiGianThanhToan, ISNULL(ThoiGianHuy, ISNULL(NgayTraThucTe, NgayTraDuKien)))
                        WHERE NgayTraDuKien < @Today AND (DaThanhToan = 0 OR TrangThaiDon IN (N'Đã đặt', N'Đang thuê'));

                        -- 4. Bãi đỗ xe vào trước hôm nay (trừ xe miễn phí của khách đang ở phòng) -> Đã ra bãi & Đã thanh toán
                        UPDATE BaiDoXe
                        SET ThoiGianRa = ISNULL(ThoiGianRa, DATEADD(HOUR, 4, ThoiGianVao)),
                            DaThanhToan = 1,
                            NguoiThanhToanId = ISNULL(NguoiThanhToanId, ISNULL(NguoiTaoId, 1)),
                            ThoiGianThanhToan = ISNULL(ThoiGianThanhToan, ISNULL(ThoiGianRa, DATEADD(HOUR, 4, ThoiGianVao)))
                        WHERE ThoiGianVao < @Today AND (DaThanhToan = 0 OR (ThoiGianRa IS NULL AND HinhThucGui <> N'Khách phòng (Miễn phí)'));

                        -- 5. Đơn giặt ủi hẹn trả trước hôm nay (trừ đơn Đã hủy) -> Hoàn tất & Đã thanh toán
                        UPDATE DonGiatUi
                        SET DoiTacId = CASE WHEN TrangThai = N'Đã hủy' THEN DoiTacId ELSE ISNULL(DoiTacId, 1) END,
                            NgayGiaoDoiTac = CASE WHEN TrangThai = N'Đã hủy' THEN NgayGiaoDoiTac ELSE ISNULL(NgayGiaoDoiTac, DATEADD(HOUR, 1, NgayNhan)) END,
                            NgayTraThucTe = CASE WHEN TrangThai = N'Đã hủy' THEN NgayTraThucTe ELSE ISNULL(NgayTraThucTe, NgayHenTra) END,
                            TrangThai = CASE WHEN TrangThai = N'Đã hủy' THEN N'Đã hủy' ELSE N'Hoàn tất' END,
                            DaThanhToan = CASE WHEN TrangThai = N'Đã hủy' THEN DaThanhToan ELSE 1 END,
                            NguoiThanhToanId = CASE WHEN TrangThai = N'Đã hủy' THEN NguoiThanhToanId ELSE ISNULL(NguoiThanhToanId, ISNULL(NguoiTaoId, 1)) END,
                            ThoiGianThanhToan = CASE WHEN TrangThai = N'Đã hủy' THEN ThoiGianThanhToan ELSE ISNULL(ThoiGianThanhToan, ISNULL(NgayTraThucTe, NgayHenTra)) END
                        WHERE NgayHenTra < @Today AND TrangThai <> N'Đã hủy' AND (DaThanhToan = 0 OR TrangThai IN (N'Chờ giao đối tác', N'Đang giặt'));
                    END";
                using var cmd = new SqlCommand(sql, conn);
                cmd.ExecuteNonQuery();

                // Tạo tự động các chỉ mục (Indexes) tối ưu hóa tốc độ truy vấn đa luồng
                EnsurePerformanceIndexes(conn);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] AutoSettlePastTransactions: {ex.Message}");
            }
        }

        private static bool _indexesEnsured = false;
        private static void EnsurePerformanceIndexes(SqlConnection conn)
        {
            if (_indexesEnsured) return;
            try
            {
                string sql = @"
                    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DonHangMonAn_SoPhong_DaTT' AND object_id = OBJECT_ID('DonHangMonAn'))
                        CREATE NONCLUSTERED INDEX IX_DonHangMonAn_SoPhong_DaTT ON DonHangMonAn(SoPhong, DaThanhToan) INCLUDE (TongTien, NgayTao);

                    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DonDatSuKien_SoPhong_DaTT' AND object_id = OBJECT_ID('DonDatSuKien'))
                        CREATE NONCLUSTERED INDEX IX_DonDatSuKien_SoPhong_DaTT ON DonDatSuKien(SoPhong, DaThanhToan) INCLUDE (KhuVucId, ThoiGianBatDau, ThoiGianKetThuc, TongTienDuKien, ChiPhiPhatSinh, TienCoc);

                    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DonThueXe_SoPhong_DaTT' AND object_id = OBJECT_ID('DonThueXe'))
                        CREATE NONCLUSTERED INDEX IX_DonThueXe_SoPhong_DaTT ON DonThueXe(SoPhong, DaThanhToan) INCLUDE (XeId, NgayThue, NgayTraDuKien, TienThue, ChiPhiPhatSinh, TienCoc);

                    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DonGiatUi_SoPhong_DaTT' AND object_id = OBJECT_ID('DonGiatUi'))
                        CREATE NONCLUSTERED INDEX IX_DonGiatUi_SoPhong_DaTT ON DonGiatUi(SoPhong, DaThanhToan) INCLUDE (TongTienThuKhach, NgayNhan, TrangThai);

                    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_BaiDoXe_SoPhong_DaTT' AND object_id = OBJECT_ID('BaiDoXe'))
                        CREATE NONCLUSTERED INDEX IX_BaiDoXe_SoPhong_DaTT ON BaiDoXe(SoPhong, DaThanhToan) INCLUDE (PhiGui, ThoiGianVao);

                    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PhanCongCaTruc_NhanVien_Ngay' AND object_id = OBJECT_ID('PhanCongCaTruc'))
                        CREATE NONCLUSTERED INDEX IX_PhanCongCaTruc_NhanVien_Ngay ON PhanCongCaTruc(NhanVienId, NgayTruc);";
                using var cmd = new SqlCommand(sql, conn);
                cmd.ExecuteNonQuery();
                _indexesEnsured = true;
            }
            catch { }
        }

        /// <summary>
        /// Đọc toàn bộ Danh mục Xe từ CSDL SQL Server (Table XeChoThue)
        /// </summary>
        public List<Vehicle> LoadVehiclesFromDb()
        {
            var list = new List<Vehicle>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = @"
                    SELECT x.*,
                           ISNULL(v.TrangThaiHienTai, x.TrangThai) AS TrangThaiHienTai
                    FROM XeChoThue x
                    LEFT JOIN vw_TrangThaiXeHienTai v ON v.XeId = x.Id
                    ORDER BY x.Id";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string loaiXe = SafeGetString(reader, "LoaiXe", "Type");
                    VehicleType type = VehicleType.Scooter;
                    if (loaiXe.Contains("số") || loaiXe.Equals("Manual", StringComparison.OrdinalIgnoreCase)) type = VehicleType.Manual;
                    else if (loaiXe.Contains("côn") || loaiXe.Equals("Clutch", StringComparison.OrdinalIgnoreCase)) type = VehicleType.Clutch;
                    else if (loaiXe.Contains("tô") || loaiXe.Equals("Car", StringComparison.OrdinalIgnoreCase)) type = VehicleType.Car;

                    string statusStr = SafeGetString(reader, "TrangThaiHienTai", "TrangThai");
                    VehicleStatus status = VehicleStatus.Available;
                    if (statusStr.Contains("thuê") || statusStr.Equals("Rented", StringComparison.OrdinalIgnoreCase)) status = VehicleStatus.Rented;
                    else if (statusStr.Contains("bảo trì") || statusStr.Contains("hỏng") || statusStr.Contains("Ngừng khai thác") || statusStr.Equals("Maintenance", StringComparison.OrdinalIgnoreCase) || statusStr.Equals("Damaged", StringComparison.OrdinalIgnoreCase)) status = VehicleStatus.Maintenance;

                    list.Add(new Vehicle
                    {
                        Id = SafeGetInt(reader, "Id"),
                        LicensePlate = SafeGetString(reader, "BienSo", "LicensePlate"),
                        Name = SafeGetString(reader, "TenXe", "Name"),
                        Type = type,
                        DailyRate = SafeGetDecimal(reader, "GiaThueNgay", "DailyRate"),
                        RequiredDeposit = SafeGetDecimal(reader, "TienCocQuyDinh", "RequiredDeposit"),
                        Status = status,
                        ConditionNote = SafeGetString(reader, "GhiChuTinhTrang", "ConditionNote"),
                        ImageUrl = SafeGetString(reader, "HinhAnh", "ImageUrl")
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadVehiclesFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Đọc danh sách Loại hình dịch vụ giặt ủi từ CSDL (Table LoaiDichVuGiatUi)
        /// </summary>
        public List<LaundryServiceTypeItem> LoadLaundryServiceTypesFromDb()
        {
            var list = new List<LaundryServiceTypeItem>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = @"SELECT Id, MaLoai, TenLoai, DonGiaBanKg, DonViTinh, HeSoBoiThuongToiDa, DangKinhDoanh
                                 FROM LoaiDichVuGiatUi
                                 WHERE DangKinhDoanh = 1
                                 ORDER BY Id";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    list.Add(new LaundryServiceTypeItem
                    {
                        Id = SafeGetInt(reader, "Id"),
                        MaLoai = SafeGetString(reader, "MaLoai"),
                        TenLoai = SafeGetString(reader, "TenLoai"),
                        DonGiaBanKg = SafeGetDecimal(reader, "DonGiaBanKg"),
                        DonViTinh = SafeGetString(reader, "DonViTinh"),
                        HeSoBoiThuongToiDa = SafeGetInt(reader, "HeSoBoiThuongToiDa"),
                        DangKinhDoanh = SafeGetBool(reader, "DangKinhDoanh")
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadLaundryServiceTypesFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Thêm mới Loại hình dịch vụ giặt ủi vào CSDL (Chỉ Admin)
        /// </summary>
        public async Task<(LaundryServiceTypeItem? Item, string? ErrorMessage)> AddLaundryServiceTypeAsync(string tenLoai, decimal donGiaBanKg)
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                await conn.OpenAsync();

                // Kiểm tra trùng tên
                using (var checkCmd = new SqlCommand("SELECT COUNT(1) FROM LoaiDichVuGiatUi WHERE LOWER(TenLoai) = LOWER(@Ten)", conn))
                {
                    checkCmd.Parameters.AddWithValue("@Ten", tenLoai.Trim());
                    int exists = Convert.ToInt32(await checkCmd.ExecuteScalarAsync());
                    if (exists > 0)
                    {
                        return (null, $"Loại hình dịch vụ [{tenLoai}] đã tồn tại trong danh sách!");
                    }
                }

                // Sinh MaLoai tự động đảm bảo duy nhất
                int nextIdx = 1;
                using (var maxCmd = new SqlCommand("SELECT ISNULL(MAX(Id), 0) + 1 FROM LoaiDichVuGiatUi", conn))
                {
                    nextIdx = Convert.ToInt32(await maxCmd.ExecuteScalarAsync());
                }
                string maLoai = $"DV_GU_{nextIdx:D2}";
                while (true)
                {
                    using var codeCheck = new SqlCommand("SELECT COUNT(1) FROM LoaiDichVuGiatUi WHERE MaLoai = @Ma", conn);
                    codeCheck.Parameters.AddWithValue("@Ma", maLoai);
                    if (Convert.ToInt32(await codeCheck.ExecuteScalarAsync()) == 0) break;
                    nextIdx++;
                    maLoai = $"DV_GU_{nextIdx:D2}";
                }

                string insertSql = @"INSERT INTO LoaiDichVuGiatUi (MaLoai, TenLoai, DonGiaBanKg, DonViTinh, HeSoBoiThuongToiDa, DangKinhDoanh)
                                     OUTPUT INSERTED.Id
                                     VALUES (@MaLoai, @TenLoai, @DonGia, N'Kg', 10, 1)";
                using var cmd = new SqlCommand(insertSql, conn);
                cmd.Parameters.AddWithValue("@MaLoai", maLoai);
                cmd.Parameters.AddWithValue("@TenLoai", tenLoai.Trim());
                cmd.Parameters.AddWithValue("@DonGia", donGiaBanKg);

                int newId = Convert.ToInt32(await cmd.ExecuteScalarAsync());
                var created = new LaundryServiceTypeItem
                {
                    Id = newId,
                    MaLoai = maLoai,
                    TenLoai = tenLoai.Trim(),
                    DonGiaBanKg = donGiaBanKg,
                    DonViTinh = "Kg",
                    HeSoBoiThuongToiDa = 10,
                    DangKinhDoanh = true
                };
                return (created, null);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] AddLaundryServiceTypeAsync: {ex.Message}");
                return (null, $"Lỗi CSDL khi thêm loại hình dịch vụ: {ex.Message}");
            }
        }

        /// <summary>
        /// Cập nhật Đơn giá/Kg niêm yết của 1 Loại hình dịch vụ giặt ủi (Chỉ Admin)
        /// </summary>
        public async Task<(bool Success, string? ErrorMessage)> UpdateLaundryServiceTypePriceAsync(int serviceTypeId, decimal newPrice)
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                await conn.OpenAsync();

                // Kiểm tra xem có đối tác nào đang có giá vốn >= giá niêm yết mới hay không
                string checkSql = @"
                    SELECT TOP 1 dt.TenDoiTac, bg.DonGiaVonKg
                    FROM BangGiaDoiTacGiatUi bg
                    JOIN DoiTacGiatUi dt ON dt.Id = bg.DoiTacId
                    WHERE bg.LoaiDichVuId = @Id AND bg.DonGiaVonKg >= @NewPrice";
                using (var checkCmd = new SqlCommand(checkSql, conn))
                {
                    checkCmd.Parameters.AddWithValue("@Id", serviceTypeId);
                    checkCmd.Parameters.AddWithValue("@NewPrice", newPrice);
                    using var r = await checkCmd.ExecuteReaderAsync();
                    if (await r.ReadAsync())
                    {
                        string partnerName = SafeGetString(r, "TenDoiTac");
                        decimal cost = SafeGetDecimal(r, "DonGiaVonKg");
                        return (false, $"Không thể đặt giá niêm yết ({newPrice:N0} đ/Kg) thấp hơn hoặc bằng giá vốn của đối tác [{partnerName}] ({cost:N0} đ/Kg)!");
                    }
                }

                using var cmd = new SqlCommand("UPDATE LoaiDichVuGiatUi SET DonGiaBanKg = @NewPrice WHERE Id = @Id", conn);
                cmd.Parameters.AddWithValue("@NewPrice", newPrice);
                cmd.Parameters.AddWithValue("@Id", serviceTypeId);
                await cmd.ExecuteNonQueryAsync();
                return (true, null);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] UpdateLaundryServiceTypePriceAsync: {ex.Message}");
                return (false, $"Lỗi CSDL khi cập nhật giá niêm yết: {ex.Message}");
            }
        }

        /// <summary>
        /// Đọc toàn bộ Đối tác Giặt ủi kèm Bảng giá vốn dịch vụ (Table DoiTacGiatUi JOIN BangGiaDoiTacGiatUi)
        /// </summary>
        public List<LaundryPartner> LoadLaundryPartnersFromDb()
        {
            var list = new List<LaundryPartner>();
            var partnerMap = new Dictionary<int, LaundryPartner>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();

                using (var cmd = new SqlCommand("SELECT * FROM DoiTacGiatUi ORDER BY Id", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        decimal rate = SafeGetDecimal(reader, "TyLeKhachSanHuong", "HotelCommissionRate");
                        var partner = new LaundryPartner
                        {
                            Id = SafeGetInt(reader, "Id"),
                            Name = SafeGetString(reader, "TenDoiTac", "Name"),
                            Address = SafeGetString(reader, "DiaChi", "Address"),
                            PhoneNumber = SafeGetString(reader, "SoDienThoai", "PhoneNumber"),
                            HotelCommissionRate = rate,
                            IsActive = SafeGetBool(reader, "TrangThai")
                        };
                        list.Add(partner);
                        partnerMap[partner.Id] = partner;
                    }
                }

                string priceQuery = @"
                    SELECT bg.DoiTacId, bg.LoaiDichVuId, bg.DonGiaVonKg,
                           ldv.MaLoai, ldv.TenLoai, ldv.DonGiaBanKg
                    FROM BangGiaDoiTacGiatUi bg
                    JOIN LoaiDichVuGiatUi ldv ON ldv.Id = bg.LoaiDichVuId
                    ORDER BY bg.DoiTacId, bg.LoaiDichVuId";
                using (var cmdPrice = new SqlCommand(priceQuery, conn))
                using (var readerPrice = cmdPrice.ExecuteReader())
                {
                    while (readerPrice.Read())
                    {
                        int partnerId = SafeGetInt(readerPrice, "DoiTacId");
                        if (!partnerMap.TryGetValue(partnerId, out var partner)) continue;

                        var item = new PartnerServicePriceItem
                        {
                            LoaiDichVuId = SafeGetInt(readerPrice, "LoaiDichVuId"),
                            MaLoai = SafeGetString(readerPrice, "MaLoai"),
                            TenLoai = SafeGetString(readerPrice, "TenLoai"),
                            DonGiaBanKg = SafeGetDecimal(readerPrice, "DonGiaBanKg"),
                            DonGiaVonKg = SafeGetDecimal(readerPrice, "DonGiaVonKg")
                        };
                        partner.ServicePrices.Add(item);

                        if (item.MaLoai == "GIAT_SAY" || item.TenLoai.Contains("sấy", StringComparison.OrdinalIgnoreCase))
                            partner.GiaVonGiatSay = item.DonGiaVonKg;
                        else if (item.MaLoai == "GIAT_HAP" || item.TenLoai.Contains("hấp", StringComparison.OrdinalIgnoreCase))
                            partner.GiaVonGiatHap = item.DonGiaVonKg;
                        else if (item.MaLoai == "UI_PHANG" || item.TenLoai.Contains("ủi", StringComparison.OrdinalIgnoreCase))
                            partner.GiaVonUiPhang = item.DonGiaVonKg;
                    }
                }

                foreach (var p in list) p.NotifyPriceSummaryChanged();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadLaundryPartnersFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Đồng bộ danh sách dịch vụ & giá vốn mà đối tác cung cấp xuống BangGiaDoiTacGiatUi
        /// </summary>
        public async Task<(bool Success, string? ErrorMessage)> SavePartnerServicePricesAsync(int partnerId, IEnumerable<PartnerServicePriceItem> servicePrices)
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                await conn.OpenAsync();
                using var tx = conn.BeginTransaction();
                try
                {
                    var items = servicePrices?.ToList() ?? new List<PartnerServicePriceItem>();

                    // Xóa những dịch vụ không còn trong danh sách báo giá của đối tác
                    using (var delCmd = new SqlCommand("DELETE FROM BangGiaDoiTacGiatUi WHERE DoiTacId = @DoiTacId", conn, tx))
                    {
                        delCmd.Parameters.AddWithValue("@DoiTacId", partnerId);
                        await delCmd.ExecuteNonQueryAsync();
                    }

                    // Thêm lại từng dịch vụ mà đối tác có nhận làm kèm giá vốn
                    foreach (var item in items)
                    {
                        using var insCmd = new SqlCommand(
                            "INSERT INTO BangGiaDoiTacGiatUi (DoiTacId, LoaiDichVuId, DonGiaVonKg, GhiChu) VALUES (@DoiTacId, @LoaiId, @DonGiaVon, @GhiChu)",
                            conn, tx);
                        insCmd.Parameters.AddWithValue("@DoiTacId", partnerId);
                        insCmd.Parameters.AddWithValue("@LoaiId", item.LoaiDichVuId);
                        insCmd.Parameters.AddWithValue("@DonGiaVon", item.DonGiaVonKg);
                        insCmd.Parameters.AddWithValue("@GhiChu", $"Giá vốn {item.TenLoai}");
                        await insCmd.ExecuteNonQueryAsync();
                    }

                    tx.Commit();
                    return (true, null);
                }
                catch
                {
                    tx.Rollback();
                    throw;
                }
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] SavePartnerServicePricesAsync: {ex.Message}");
                return (false, ex.Message);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[Error] SavePartnerServicePricesAsync: {ex.Message}");
                return (false, ex.Message);
            }
        }

        /// <summary>
        /// Lưu hoặc cập nhật bảng giá vốn của đối tác xuống BangGiaDoiTacGiatUi (tương thích ngược)
        /// </summary>
        public async System.Threading.Tasks.Task SavePartnerCostPricesAsync(int partnerId, decimal say, decimal hap, decimal ui)
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                await conn.OpenAsync();
                string sql = @"
                    DECLARE @IdSay INT = (SELECT TOP 1 Id FROM LoaiDichVuGiatUi WHERE MaLoai = 'GIAT_SAY');
                    DECLARE @IdHap INT = (SELECT TOP 1 Id FROM LoaiDichVuGiatUi WHERE MaLoai = 'GIAT_HAP');
                    DECLARE @IdUi  INT = (SELECT TOP 1 Id FROM LoaiDichVuGiatUi WHERE MaLoai = 'UI_PHANG');

                    IF @IdSay IS NOT NULL
                    BEGIN
                        IF EXISTS (SELECT 1 FROM BangGiaDoiTacGiatUi WHERE DoiTacId = @DoiTacId AND LoaiDichVuId = @IdSay)
                            UPDATE BangGiaDoiTacGiatUi SET DonGiaVonKg = @Say WHERE DoiTacId = @DoiTacId AND LoaiDichVuId = @IdSay;
                        ELSE
                            INSERT INTO BangGiaDoiTacGiatUi (DoiTacId, LoaiDichVuId, DonGiaVonKg, GhiChu) VALUES (@DoiTacId, @IdSay, @Say, N'Giá vốn giặt sấy');
                    END

                    IF @IdHap IS NOT NULL
                    BEGIN
                        IF EXISTS (SELECT 1 FROM BangGiaDoiTacGiatUi WHERE DoiTacId = @DoiTacId AND LoaiDichVuId = @IdHap)
                            UPDATE BangGiaDoiTacGiatUi SET DonGiaVonKg = @Hap WHERE DoiTacId = @DoiTacId AND LoaiDichVuId = @IdHap;
                        ELSE
                            INSERT INTO BangGiaDoiTacGiatUi (DoiTacId, LoaiDichVuId, DonGiaVonKg, GhiChu) VALUES (@DoiTacId, @IdHap, @Hap, N'Giá vốn giặt hấp');
                    END

                    IF @IdUi IS NOT NULL
                    BEGIN
                        IF EXISTS (SELECT 1 FROM BangGiaDoiTacGiatUi WHERE DoiTacId = @DoiTacId AND LoaiDichVuId = @IdUi)
                            UPDATE BangGiaDoiTacGiatUi SET DonGiaVonKg = @Ui WHERE DoiTacId = @DoiTacId AND LoaiDichVuId = @IdUi;
                        ELSE
                            INSERT INTO BangGiaDoiTacGiatUi (DoiTacId, LoaiDichVuId, DonGiaVonKg, GhiChu) VALUES (@DoiTacId, @IdUi, @Ui, N'Giá vốn ủi phẳng');
                    END";
                using var cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@DoiTacId", partnerId);
                cmd.Parameters.AddWithValue("@Say", say);
                cmd.Parameters.AddWithValue("@Hap", hap);
                cmd.Parameters.AddWithValue("@Ui", ui);
                await cmd.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] SavePartnerCostPricesAsync: {ex.Message}");
            }
        }

        /// <summary>
        /// Đọc toàn bộ danh sách Nhân viên từ CSDL SQL Server (Table NhanVien)
        /// </summary>
        public List<Staff> LoadStaffFromDb()
        {
            var list = new List<Staff>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = "SELECT * FROM NhanVien ORDER BY Id";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                int fallbackId = 1;
                while (reader.Read())
                {
                    int id = SafeGetInt(reader, "Id", "NhanVienID", "MaNhanVien");
                    if (id == 0) id = fallbackId;
                    fallbackId = Math.Max(fallbackId, id) + 1;

                    string code = SafeGetString(reader, "MaNV", "MaNhanVien", "Code");
                    if (string.IsNullOrWhiteSpace(code)) code = $"NV{id:D3}";

                    string fullName = SafeGetString(reader, "HoTen", "TenNhanVien", "FullName");
                    if (string.IsNullOrWhiteSpace(fullName)) continue;

                    string cccd = SafeGetString(reader, "CCCD", "SoCCCD", "CMND");
                    string phone = SafeGetString(reader, "SoDienThoai", "SDT", "Phone");
                    string email = SafeGetString(reader, "Email");
                    string position = SafeGetString(reader, "ChucVu", "VaiTro", "Position");
                    if (string.IsNullOrWhiteSpace(position)) position = "Nhân viên";

                    decimal salary = SafeGetDecimal(reader, "LuongCoBan", "Salary");
                    string status = SafeGetString(reader, "TrangThai", "Status");
                    if (string.IsNullOrWhiteSpace(status)) status = "Đang làm việc";

                    list.Add(new Staff
                    {
                        Id = id,
                        Code = code,
                        FullName = fullName,
                        IdentityCard = cccd,
                        PhoneNumber = phone,
                        Email = email,
                        Position = position,
                        BaseSalary = salary,
                        Status = status
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadStaffFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Đọc toàn bộ danh sách Ca trực từ CSDL SQL Server (Table CaTruc)
        /// </summary>
        public List<Shift> LoadShiftsFromDb()
        {
            var list = new List<Shift>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = "SELECT * FROM CaTruc ORDER BY Id";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                int fallbackId = 1;
                while (reader.Read())
                {
                    int id = SafeGetInt(reader, "Id", "CaTrucId", "MaCa");
                    if (id == 0) id = fallbackId;
                    fallbackId = Math.Max(fallbackId, id) + 1;

                    string name = SafeGetString(reader, "TenCa", "Name");
                    if (string.IsNullOrWhiteSpace(name)) continue;

                    TimeSpan start = SafeGetTimeSpan(reader, "GioBatDau", "StartTime");
                    TimeSpan end = SafeGetTimeSpan(reader, "GioKetThuc", "EndTime");
                    string note = SafeGetString(reader, "GhiChu", "Note");

                    list.Add(new Shift
                    {
                        Id = id,
                        Name = name,
                        StartTime = start,
                        EndTime = end,
                        Note = note
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadShiftsFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Đọc toàn bộ Lịch phân công ca trực từ CSDL SQL Server (Table PhanCongCaTruc JOIN NhanVien, CaTruc)
        /// </summary>
        public List<ShiftAssignment> LoadShiftAssignmentsFromDb(List<Staff>? staffList = null, List<Shift>? shiftList = null)
        {
            var list = new List<ShiftAssignment>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = @"
                    SELECT p.*, 
                           nv.HoTen AS TenNhanVien,
                           c.TenCa
                    FROM PhanCongCaTruc p
                    LEFT JOIN NhanVien nv ON p.NhanVienId = nv.Id
                    LEFT JOIN CaTruc c ON p.CaTrucId = c.Id
                    ORDER BY p.NgayTruc DESC, p.Id DESC";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                int fallbackId = 1;
                while (reader.Read())
                {
                    int id = SafeGetInt(reader, "Id", "PhanCongId");
                    if (id == 0) id = fallbackId;
                    fallbackId = Math.Max(fallbackId, id) + 1;

                    int staffId = SafeGetInt(reader, "NhanVienId", "StaffId");
                    int shiftId = SafeGetInt(reader, "CaTrucId", "ShiftId");
                    string staffName = SafeGetString(reader, "TenNhanVien", "HoTen", "StaffName");
                    string shiftName = SafeGetString(reader, "TenCa", "ShiftName");
                    DateTime shiftDate = SafeGetDateTime(reader, "NgayTruc", "ShiftDate");
                    string note = SafeGetString(reader, "GhiChu", "Note");

                    if (string.IsNullOrWhiteSpace(staffName) && staffList != null)
                    {
                        var st = staffList.FirstOrDefault(x => x.Id == staffId);
                        if (st != null) staffName = st.FullName;
                    }
                    if (string.IsNullOrWhiteSpace(shiftName) && shiftList != null)
                    {
                        var sh = shiftList.FirstOrDefault(x => x.Id == shiftId);
                        if (sh != null) shiftName = sh.Name;
                    }

                    list.Add(new ShiftAssignment
                    {
                        Id = id,
                        StaffId = staffId,
                        StaffName = string.IsNullOrWhiteSpace(staffName) ? $"Nhân viên #{staffId}" : staffName,
                        ShiftId = shiftId,
                        ShiftName = string.IsNullOrWhiteSpace(shiftName) ? $"Ca #{shiftId}" : shiftName,
                        ShiftDate = shiftDate,
                        Note = note
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadShiftAssignmentsFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Đọc toàn bộ danh sách Khách hàng từ CSDL SQL Server (Table KhachHang)
        /// </summary>
        public List<Customer> LoadCustomersFromDb()
        {
            var list = new List<Customer>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = "SELECT * FROM KhachHang ORDER BY Id DESC";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                int fallbackId = 1;
                while (reader.Read())
                {
                    int id = SafeGetInt(reader, "Id", "KhachHangID", "MaKhachHang");
                    if (id == 0) id = fallbackId;
                    fallbackId = Math.Max(fallbackId, id) + 1;

                    string fullName = SafeGetString(reader, "HoTen", "TenKhachHang", "CustomerName");
                    if (string.IsNullOrWhiteSpace(fullName)) continue;

                    list.Add(new Customer
                    {
                        Id = id,
                        FullName = fullName,
                        IdentityCard = SafeGetString(reader, "CCCD", "CMND", "IdentityCard"),
                        PhoneNumber = SafeGetString(reader, "SoDienThoai", "SDT", "PhoneNumber"),
                        RoomNumber = SafeGetString(reader, "SoPhong", "RoomNumber"),
                        Note = SafeGetString(reader, "GhiChu", "Note")
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadCustomersFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Chuẩn hóa tên dịch vụ đồng bộ tuyệt đối với tab hiển thị trên thanh điều hướng sidebar
        /// </summary>
        public static string NormalizeServiceName(string code, string fallback = "")
        {
            return code?.Trim().ToUpperInvariant() switch
            {
                "AN_UONG" => "Ăn Uống",
                "SU_KIEN" => "Sảnh & Sự Kiện",
                "THUE_XE" => "Cho Thuê Xe Máy",
                "DO_XE" => "Bãi & Hầm Đỗ Xe",
                "GIAT_UI" => "Giặt Ủi",
                _ => string.IsNullOrWhiteSpace(fallback) ? code ?? "" : fallback
            };
        }

        /// <summary>
        /// Đọc cấu hình dịch vụ từ CSDL SQL Server (Table DichVuHeThong)
        /// </summary>
        public List<HotelServiceConfig> LoadServicesConfigFromDb()
        {
            var list = new List<HotelServiceConfig>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();

                // Đồng bộ cập nhật tên chuẩn vào CSDL nếu còn lưu tên cũ
                try
                {
                    string updateSql = @"
                        UPDATE DichVuHeThong SET TenDV = N'Ăn Uống' WHERE MaDV = 'AN_UONG' AND TenDV <> N'Ăn Uống';
                        UPDATE DichVuHeThong SET TenDV = N'Sảnh & Sự Kiện' WHERE MaDV = 'SU_KIEN' AND TenDV <> N'Sảnh & Sự Kiện';
                        UPDATE DichVuHeThong SET TenDV = N'Cho Thuê Xe Máy' WHERE MaDV = 'THUE_XE' AND TenDV <> N'Cho Thuê Xe Máy';
                        UPDATE DichVuHeThong SET TenDV = N'Bãi & Hầm Đỗ Xe' WHERE MaDV = 'DO_XE' AND TenDV <> N'Bãi & Hầm Đỗ Xe';
                        UPDATE DichVuHeThong SET TenDV = N'Giặt Ủi' WHERE MaDV = 'GIAT_UI' AND TenDV <> N'Giặt Ủi';
                    ";
                    using var updateCmd = new SqlCommand(updateSql, conn);
                    updateCmd.ExecuteNonQuery();
                }
                catch { }

                string query = "SELECT * FROM DichVuHeThong ORDER BY Id";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string code = SafeGetString(reader, "MaDV", "MaDichVu", "Code");
                    string rawName = SafeGetString(reader, "TenDV", "TenDichVu", "Name");
                    string name = NormalizeServiceName(code, rawName);
                    string type = SafeGetString(reader, "LoaiDichVu", "ServiceType");
                    string desc = SafeGetString(reader, "MoTa", "Description");
                    bool active = SafeGetBool(reader, "DangHoatDong", "IsActive");

                    list.Add(new HotelServiceConfig
                    {
                        Code = code,
                        Name = name,
                        ServiceType = type,
                        IsActive = active,
                        Description = desc
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadServicesConfigFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Đọc toàn bộ danh sách Tài khoản Người dùng từ CSDL SQL Server (Table TaiKhoan)
        /// </summary>
        public List<User> LoadUsersFromDb()
        {
            var list = new List<User>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = "SELECT * FROM TaiKhoan ORDER BY Id";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string roleStr = SafeGetString(reader, "VaiTro", "Role");
                    UserRole role = (roleStr.Equals("Admin", StringComparison.OrdinalIgnoreCase)) 
                        ? UserRole.Admin 
                        : UserRole.Receptionist;

                    string username = SafeGetString(reader, "TenDangNhap", "Username");
                    string passwordHash = SafeGetString(reader, "MatKhauHash", "MatKhau", "Password");
                    string plainPassword = Helpers.SecurityHelper.DecodePasswordFromDb(passwordHash);
                    string fullName = SafeGetString(reader, "HoTen", "FullName");
                    bool isActive = SafeGetBool(reader, "TrangThai");

                    list.Add(new User
                    {
                        Id = SafeGetInt(reader, "Id", "NguoiDungID", "TaiKhoanID"),
                        Username = username,
                        Password = plainPassword,
                        FullName = string.IsNullOrWhiteSpace(fullName) ? (role == UserRole.Admin ? "Chủ Khách Sạn" : "Lễ tân") : fullName,
                        Role = role,
                        PhoneNumber = SafeGetString(reader, "SoDienThoai", "PhoneNumber", "SDT"),
                        Email = SafeGetString(reader, "Email"),
                        IsActive = isActive
                    });
                }
            }
            catch (Exception ex)
            {
                LastError = ex.Message;
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadUsersFromDb: {ex.Message}");
            }
            return list;
        }

        #endregion

        #region Transaction Readers

        /// <summary>
        /// Đọc các đơn hàng ăn uống từ CSDL (Table DonHangMonAn JOIN ChiTietDonHangMonAn)
        /// </summary>
        public List<FoodOrder> LoadFoodOrdersFromDb(List<FoodItem>? foodList = null, List<Staff>? staffList = null)
        {
            var list = new List<FoodOrder>();
            try
            {
                using (var conn = new SqlConnection(ConnectionString))
                {
                    conn.Open();
                    string query = @"
                        SELECT dh.*, nv.HoTen AS TenNguoiTao, nvTT.HoTen AS TenNguoiThanhToan 
                        FROM DonHangMonAn dh 
                        LEFT JOIN NhanVien nv ON dh.NguoiTaoId = nv.Id 
                        LEFT JOIN NhanVien nvTT ON dh.NguoiThanhToanId = nvTT.Id 
                        ORDER BY dh.NgayTao DESC";
                    using var cmd = new SqlCommand(query, conn);
                    using var reader = cmd.ExecuteReader();
                    while (reader.Read())
                    {
                        int orderId = SafeGetInt(reader, "Id");
                        string code = SafeGetString(reader, "MaDon");
                        string custName = SafeGetString(reader, "TenKhach");
                        string roomNum = SafeGetString(reader, "SoPhong");
                        string payTypeStr = SafeGetString(reader, "HinhThucThanhToan");
                        FoodPaymentType payType = payTypeStr.Contains("phòng") ? FoodPaymentType.RoomBill : FoodPaymentType.SeparateBill;
                        decimal total = SafeGetDecimal(reader, "TongTien");
                        bool daTT = SafeGetBool(reader, "DaThanhToan");
                        string note = SafeGetString(reader, "GhiChu");
                        int creatorId = SafeGetInt(reader, "NguoiTaoId");
                        int? payerId = SafeGetNullableInt(reader, "NguoiThanhToanId");
                        DateTime? payerTime = SafeGetNullableDateTime(reader, "ThoiGianThanhToan");
                        string staff = SafeGetString(reader, "TenNguoiTao");
                        if (string.IsNullOrWhiteSpace(staff) && creatorId == 0) staff = "Chủ khách sạn";
                        string payerStaff = SafeGetString(reader, "TenNguoiThanhToan");
                        if (string.IsNullOrWhiteSpace(payerStaff) && payerId == 0) payerStaff = "Chủ khách sạn";
                        if (string.IsNullOrWhiteSpace(payerStaff) && daTT && !string.IsNullOrWhiteSpace(staff)) payerStaff = staff;

                        DateTime created = SafeGetDateTime(reader, "NgayTao");
                        string status = SafeGetString(reader, "TrangThai");

                        list.Add(new FoodOrder
                        {
                            Id = orderId,
                            OrderCode = code,
                            KhachHangId = SafeGetNullableInt(reader, "KhachHangId"),
                            CustomerName = custName,
                            RoomNumber = roomNum,
                            PaymentType = payType,
                            TotalAmount = total,
                            DaThanhToan = daTT,
                            Note = note,
                            NguoiTaoId = creatorId != 0 ? creatorId : 1,
                            NguoiThanhToanId = payerId,
                            ThoiGianThanhToan = payerTime,
                            RecordedBy = staff,
                            PaidByStaffName = payerStaff,
                            CreatedAt = created,
                            Status = status
                        });
                    }
                }

                // Nạp chi tiết từng món ăn cho các đơn hàng
                if (list.Count > 0)
                {
                    using var conn2 = new SqlConnection(ConnectionString);
                    conn2.Open();
                    string detailQuery = @"
                        SELECT ct.DonHangId, ct.MonAnId, ct.SoLuong, ct.DonGia, ct.GiaVon, ma.TenMon, ma.DonViTinh 
                        FROM ChiTietDonHangMonAn ct 
                        JOIN MonAn ma ON ct.MonAnId = ma.Id";
                    using var detailCmd = new SqlCommand(detailQuery, conn2);
                    using var detailReader = detailCmd.ExecuteReader();
                    var orderMap = list.ToDictionary(x => x.Id);
                    while (detailReader.Read())
                    {
                        int orderId = SafeGetInt(detailReader, "DonHangId");
                        if (orderMap.TryGetValue(orderId, out var ord))
                        {
                            ord.Items.Add(new FoodOrderItem
                            {
                                FoodItemId = SafeGetInt(detailReader, "MonAnId"),
                                FoodItemName = SafeGetString(detailReader, "TenMon"),
                                RetailUnit = SafeGetString(detailReader, "DonViTinh", "DonViBanLe"),
                                Quantity = SafeGetInt(detailReader, "SoLuong"),
                                Price = SafeGetDecimal(detailReader, "DonGia"),
                                CostPrice = SafeGetDecimal(detailReader, "GiaVon")
                            });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadFoodOrdersFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Đọc đơn đặt sự kiện từ CSDL (Table DonDatSuKien JOIN KhuVucSuKien)
        /// </summary>
        public List<EventBooking> LoadEventBookingsFromDb(List<EventSpace>? spaceList = null, List<Staff>? staffList = null)
        {
            var list = new List<EventBooking>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = @"
                    SELECT sk.*, kv.TenKhuVuc, nv.HoTen AS TenNguoiTao, nvTT.HoTen AS TenNguoiThanhToan 
                    FROM DonDatSuKien sk 
                    LEFT JOIN KhuVucSuKien kv ON sk.KhuVucId = kv.Id 
                    LEFT JOIN NhanVien nv ON sk.NguoiTaoId = nv.Id 
                    LEFT JOIN NhanVien nvTT ON sk.NguoiThanhToanId = nvTT.Id 
                    ORDER BY sk.NgayTao DESC";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    int spaceId = SafeGetInt(reader, "KhuVucId");
                    string spaceName = SafeGetString(reader, "TenKhuVuc");
                    if (string.IsNullOrWhiteSpace(spaceName) && spaceList != null)
                    {
                        var s = spaceList.FirstOrDefault(x => x.Id == spaceId);
                        if (s != null) spaceName = s.Name;
                    }

                    int creatorId = SafeGetInt(reader, "NguoiTaoId");
                    int? payerId = SafeGetNullableInt(reader, "NguoiThanhToanId");
                    string staff = SafeGetString(reader, "TenNguoiTao");
                    if (string.IsNullOrWhiteSpace(staff) && creatorId == 0) staff = "Chủ khách sạn";
                    string payerStaff = SafeGetString(reader, "TenNguoiThanhToan");
                    if (string.IsNullOrWhiteSpace(payerStaff) && payerId == 0) payerStaff = "Chủ khách sạn";
                    bool daTT = SafeGetBool(reader, "DaThanhToan");
                    if (string.IsNullOrWhiteSpace(payerStaff) && daTT && !string.IsNullOrWhiteSpace(staff)) payerStaff = staff;

                    string initialPay = SafeGetString(reader, "HinhThucThanhToanBanDau");
                    string orderStatus = SafeGetString(reader, "TrangThaiDon");
                    string payStatus = SafeGetString(reader, "TrangThaiThanhToan");

                    if (string.IsNullOrWhiteSpace(orderStatus))
                    {
                        orderStatus = !string.IsNullOrWhiteSpace(payStatus) ? payStatus : "Đã đặt";
                    }

                    if (string.IsNullOrWhiteSpace(initialPay))
                    {
                        initialPay = (payStatus == "Đã thanh toán full" || daTT) ? "Thanh toán toàn bộ" : "Đặt cọc trước";
                    }

                    string dmgNote = SafeGetString(reader, "GhiChuHuHai");
                    if (string.IsNullOrWhiteSpace(payStatus))
                    {
                        if (orderStatus == "Đang sử dụng") payStatus = "Đang sử dụng";
                        else if (orderStatus == "Hoàn tất")
                        {
                            if (!daTT || (dmgNote != null && dmgNote.Contains("Ghi nợ vào phòng")))
                            {
                                payStatus = "Ghi nợ vào phòng";
                            }
                            else
                            {
                                payStatus = "Hoàn tất";
                            }
                        }
                        else if (orderStatus.StartsWith("Đã hủy")) payStatus = "Đã hủy";
                        else if (initialPay == "Thanh toán toàn bộ") payStatus = "Đã thanh toán full";
                        else payStatus = "Đã cọc";
                    }
                    else if (orderStatus == "Hoàn tất" && (!daTT || (dmgNote != null && dmgNote.Contains("Ghi nợ vào phòng"))))
                    {
                        payStatus = "Ghi nợ vào phòng";
                    }

                    list.Add(new EventBooking
                    {
                        Id = SafeGetInt(reader, "Id"),
                        BookingCode = SafeGetString(reader, "MaDon"),
                        SpaceId = spaceId,
                        SpaceName = spaceName,
                        KhachHangId = SafeGetNullableInt(reader, "KhachHangId"),
                        CustomerName = SafeGetString(reader, "TenKhach"),
                        PhoneNumber = SafeGetString(reader, "SoDienThoai"),
                        RoomNumber = SafeGetString(reader, "SoPhong"),
                        StartTime = SafeGetDateTime(reader, "ThoiGianBatDau"),
                        EndTime = SafeGetDateTime(reader, "ThoiGianKetThuc"),
                        DepositAmount = SafeGetDecimal(reader, "TienCoc"),
                        TotalEstimatedAmount = SafeGetDecimal(reader, "TongTienDuKien"),
                        AdditionalCost = SafeGetDecimal(reader, "ChiPhiPhatSinh"),
                        DamageNote = dmgNote ?? string.Empty,
                        DaThanhToan = daTT,
                        PaymentStatus = payStatus,
                        InitialPaymentType = initialPay,
                        OrderStatus = orderStatus,
                        NguoiTaoId = creatorId != 0 ? creatorId : 1,
                        NguoiThanhToanId = payerId,
                        ThoiGianThanhToan = SafeGetNullableDateTime(reader, "ThoiGianThanhToan"),
                        RecordedBy = staff,
                        PaidByStaffName = payerStaff,
                        CreatedAt = SafeGetDateTime(reader, "NgayTao")
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadEventBookingsFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Đọc đơn thuê xe từ CSDL (Table DonThueXe JOIN XeChoThue)
        /// </summary>
        public List<VehicleRental> LoadVehicleRentalsFromDb(List<Vehicle>? vehicleList = null, List<Staff>? staffList = null)
        {
            var list = new List<VehicleRental>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = @"
                    SELECT tx.*, x.TenXe, x.BienSo AS BienSoXe, nv.HoTen AS TenNguoiTao, nvTT.HoTen AS TenNguoiThanhToan 
                    FROM DonThueXe tx 
                    LEFT JOIN XeChoThue x ON tx.XeId = x.Id 
                    LEFT JOIN NhanVien nv ON tx.NguoiTaoId = nv.Id 
                    LEFT JOIN NhanVien nvTT ON tx.NguoiThanhToanId = nvTT.Id 
                    ORDER BY tx.NgayTao DESC";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    int vehicleId = SafeGetInt(reader, "XeId");
                    string vehicleName = SafeGetString(reader, "TenXe");
                    string plate = SafeGetString(reader, "BienSoXe");
                    if (vehicleList != null)
                    {
                        var v = vehicleList.FirstOrDefault(x => x.Id == vehicleId);
                        if (v != null)
                        {
                            if (string.IsNullOrWhiteSpace(vehicleName)) vehicleName = v.Name;
                            if (string.IsNullOrWhiteSpace(plate)) plate = v.LicensePlate;
                        }
                    }

                    int creatorId = SafeGetInt(reader, "NguoiTaoId");
                    int? payerId = SafeGetNullableInt(reader, "NguoiThanhToanId");
                    string staff = SafeGetString(reader, "TenNguoiTao");
                    if (string.IsNullOrWhiteSpace(staff) && creatorId == 0) staff = "Chủ khách sạn";
                    string payerStaff = SafeGetString(reader, "TenNguoiThanhToan");
                    if (string.IsNullOrWhiteSpace(payerStaff) && payerId == 0) payerStaff = "Chủ khách sạn";
                    bool daTT = SafeGetBool(reader, "DaThanhToan");
                    if (string.IsNullOrWhiteSpace(payerStaff) && daTT && !string.IsNullOrWhiteSpace(staff)) payerStaff = staff;

                    string initialPay = SafeGetString(reader, "HinhThucThanhToanBanDau");
                    string orderStatus = SafeGetString(reader, "TrangThaiDon", "TrangThai");
                    if (string.IsNullOrWhiteSpace(orderStatus)) orderStatus = "Đang thuê";
                    if (orderStatus == "Đã hoàn tất") orderStatus = "Hoàn tất";

                    if (string.IsNullOrWhiteSpace(initialPay))
                    {
                        initialPay = (daTT || SafeGetDecimal(reader, "TienCoc") >= SafeGetDecimal(reader, "TienThue")) ? "Thanh toán toàn bộ" : "Đặt cọc trước";
                    }

                    string dmgNoteVeh = SafeGetString(reader, "GhiChuHuHai");
                    string displayStatus = orderStatus;
                    string vehiclePayStatus = daTT ? "Đã thanh toán" : "Chưa thanh toán";
                    if (displayStatus.StartsWith("Đã hủy"))
                    {
                        displayStatus = "Đã hủy";
                        vehiclePayStatus = "Đã hủy";
                    }
                    else if (orderStatus == "Hoàn tất")
                    {
                        if (!daTT || (dmgNoteVeh != null && dmgNoteVeh.Contains("Ghi nợ vào phòng")))
                        {
                            displayStatus = "Ghi nợ vào phòng";
                            vehiclePayStatus = "Ghi nợ vào phòng";
                        }
                        else
                        {
                            displayStatus = "Hoàn tất";
                            vehiclePayStatus = "Hoàn tất";
                        }
                    }

                    list.Add(new VehicleRental
                    {
                        Id = SafeGetInt(reader, "Id"),
                        RentalCode = SafeGetString(reader, "MaDon"),
                        VehicleId = vehicleId,
                        VehicleName = vehicleName,
                        LicensePlate = plate,
                        KhachHangId = SafeGetNullableInt(reader, "KhachHangId"),
                        CustomerName = SafeGetString(reader, "TenKhach"),
                        IdentityCard = SafeGetString(reader, "CCCD"),
                        PhoneNumber = SafeGetString(reader, "SoDienThoai"),
                        RoomNumber = SafeGetString(reader, "SoPhong"),
                        RentalDate = SafeGetDateTime(reader, "NgayThue"),
                        ExpectedReturnDate = SafeGetDateTime(reader, "NgayTraDuKien"),
                        ActualReturnDate = SafeGetNullableDateTime(reader, "NgayTraThucTe"),
                        DepositAmount = SafeGetDecimal(reader, "TienCoc"),
                        RentalFee = SafeGetDecimal(reader, "TienThue"),
                        AdditionalCost = SafeGetDecimal(reader, "ChiPhiPhatSinh"),
                        TotalPayment = SafeGetDecimal(reader, "TongTienThanhToan"),
                        DaThanhToan = daTT,
                        ReceptionNote = SafeGetString(reader, "GhiChuKhiNhanXe"),
                        DamageNote = dmgNoteVeh ?? string.Empty,
                        Status = displayStatus,
                        PaymentStatus = vehiclePayStatus,
                        InitialPaymentType = initialPay,
                        OrderStatus = orderStatus,
                        NguoiTaoId = creatorId != 0 ? creatorId : 1,
                        NguoiThanhToanId = payerId,
                        ThoiGianThanhToan = SafeGetNullableDateTime(reader, "ThoiGianThanhToan"),
                        RecordedBy = staff,
                        PaidByStaffName = payerStaff,
                        CreatedAt = SafeGetDateTime(reader, "NgayTao")
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadVehicleRentalsFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Đọc các lượt đỗ xe từ CSDL (Table BaiDoXe)
        /// </summary>
        public List<ParkingRecord> LoadParkingRecordsFromDb(List<Staff>? staffList = null)
        {
            var list = new List<ParkingRecord>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = @"
                    SELECT bx.*, nv.HoTen AS TenNguoiTao, nvTT.HoTen AS TenNguoiThanhToan 
                    FROM BaiDoXe bx 
                    LEFT JOIN NhanVien nv ON bx.NguoiTaoId = nv.Id 
                    LEFT JOIN NhanVien nvTT ON bx.NguoiThanhToanId = nvTT.Id 
                    ORDER BY bx.ThoiGianVao DESC";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string vType = SafeGetString(reader, "LoaiXe");
                    vType = vType.Contains("Ô tô") ? "Ô tô" : "Xe máy";

                    string room = SafeGetString(reader, "SoPhong");
                    string chargeStr = SafeGetString(reader, "HinhThucGui");
                    ParkingChargeType charge;
                    if (!string.IsNullOrWhiteSpace(room) || chargeStr.Contains("miễn phí") || chargeStr.Contains("Khách phòng"))
                    {
                        charge = ParkingChargeType.ResidentFree;
                    }
                    else if (vType == "Xe máy")
                    {
                        charge = ParkingChargeType.ByTurn;
                    }
                    else
                    {
                        charge = ParkingChargeType.ByHour;
                    }

                    int creatorId = SafeGetInt(reader, "NguoiTaoId");
                    int? payerId = SafeGetNullableInt(reader, "NguoiThanhToanId");
                    string staff = SafeGetString(reader, "TenNguoiTao");
                    if (string.IsNullOrWhiteSpace(staff) && creatorId == 0) staff = "Chủ khách sạn";
                    string payerStaff = SafeGetString(reader, "TenNguoiThanhToan");
                    if (string.IsNullOrWhiteSpace(payerStaff) && payerId == 0) payerStaff = "Chủ khách sạn";
                    bool daTT = SafeGetBool(reader, "DaThanhToan");
                    if (string.IsNullOrWhiteSpace(payerStaff) && daTT && !string.IsNullOrWhiteSpace(staff)) payerStaff = staff;

                    list.Add(new ParkingRecord
                    {
                        Id = SafeGetInt(reader, "Id"),
                        TicketCode = SafeGetString(reader, "MaVe"),
                        LicensePlate = SafeGetString(reader, "BienSoXe", "BienSo"),
                        VehicleType = vType,
                        CustomerName = SafeGetString(reader, "TenKhach"),
                        PhoneNumber = SafeGetString(reader, "SoDienThoai"),
                        RoomNumber = room,
                        CheckInTime = SafeGetDateTime(reader, "ThoiGianVao"),
                        CheckOutTime = SafeGetNullableDateTime(reader, "ThoiGianRa"),
                        ChargeType = charge,
                        ParkingFee = SafeGetDecimal(reader, "PhiGui"),
                        DaThanhToan = daTT,
                        RepairNote = SafeGetString(reader, "GhiChuSuaChua"),
                        NguoiTaoId = creatorId != 0 ? creatorId : 1,
                        NguoiThanhToanId = payerId,
                        ThoiGianThanhToan = SafeGetNullableDateTime(reader, "ThoiGianThanhToan"),
                        RecordedBy = staff,
                        PaidByStaffName = payerStaff
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadParkingRecordsFromDb: {ex.Message}");
            }
            return list;
        }

        /// <summary>
        /// Đọc đơn giặt ủi từ CSDL (Table DonGiatUi JOIN DoiTacGiatUi)
        /// </summary>
        public List<LaundryOrder> LoadLaundryOrdersFromDb(List<LaundryPartner>? partnerList = null, List<Staff>? staffList = null)
        {
            var list = new List<LaundryOrder>();
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                string query = @"
                    SELECT gu.*, dt.TenDoiTac, ldv.Id AS ServiceTypeId,
                           nv.HoTen AS TenNguoiTao, nvTT.HoTen AS TenNguoiThanhToan 
                    FROM DonGiatUi gu 
                    LEFT JOIN DoiTacGiatUi dt ON gu.DoiTacId = dt.Id 
                    LEFT JOIN LoaiDichVuGiatUi ldv ON (ldv.TenLoai = gu.LoaiDichVu OR ldv.MaLoai = gu.LoaiDichVu)
                    LEFT JOIN NhanVien nv ON gu.NguoiTaoId = nv.Id 
                    LEFT JOIN NhanVien nvTT ON gu.NguoiThanhToanId = nvTT.Id 
                    ORDER BY gu.NgayNhan DESC";
                using var cmd = new SqlCommand(query, conn);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    int partnerId = SafeGetInt(reader, "DoiTacId");
                    string partnerName = SafeGetString(reader, "TenDoiTac");
                    if (string.IsNullOrWhiteSpace(partnerName) && partnerList != null)
                    {
                        var p = partnerList.FirstOrDefault(x => x.Id == partnerId);
                        if (p != null) partnerName = p.Name;
                    }

                    int serviceTypeId = SafeGetInt(reader, "ServiceTypeId");
                    string serviceStr = SafeGetString(reader, "LoaiDichVu");
                    LaundryServiceType serviceType = LaundryServiceType.WashAndDry;
                    if (serviceStr.Contains("hấp", StringComparison.OrdinalIgnoreCase)) serviceType = LaundryServiceType.DryCleaning;
                    else if (serviceStr.Contains("ủi", StringComparison.OrdinalIgnoreCase)) serviceType = LaundryServiceType.Ironing;

                    string statusStr = SafeGetString(reader, "TrangThai");
                    LaundryStatus status = LaundryStatus.PendingDispatch;
                    if (statusStr.Contains("hủy") || statusStr.Contains("Hủy")) status = LaundryStatus.Cancelled;
                    else if (statusStr.Contains("Hoàn tất") || statusStr.Contains("hoàn tất")) status = LaundryStatus.Completed;
                    else if (statusStr.Contains("giặt") || statusStr.Contains("Giặt") || (partnerId > 0 && !statusStr.Contains("Chờ"))) status = LaundryStatus.Washing;
                    else status = LaundryStatus.PendingDispatch;

                    int creatorId = SafeGetInt(reader, "NguoiTaoId");
                    int? payerId = SafeGetNullableInt(reader, "NguoiThanhToanId");
                    string staff = SafeGetString(reader, "TenNguoiTao");
                    if (string.IsNullOrWhiteSpace(staff) && creatorId == 0) staff = "Chủ khách sạn";
                    string payerStaff = SafeGetString(reader, "TenNguoiThanhToan");
                    if (string.IsNullOrWhiteSpace(payerStaff) && payerId == 0) payerStaff = "Chủ khách sạn";
                    bool daTT = SafeGetBool(reader, "DaThanhToan");
                    if (string.IsNullOrWhiteSpace(payerStaff) && daTT && !string.IsNullOrWhiteSpace(staff)) payerStaff = staff;

                    string paymentMethod = SafeGetString(reader, "HinhThucThanhToan");
                    if (string.IsNullOrWhiteSpace(paymentMethod)) paymentMethod = daTT ? "Thanh toán trực tiếp" : "Ghi nợ vào phòng";

                    list.Add(new LaundryOrder
                    {
                        Id = SafeGetInt(reader, "Id"),
                        OrderCode = SafeGetString(reader, "MaDon"),
                        KhachHangId = SafeGetNullableInt(reader, "KhachHangId"),
                        CustomerName = SafeGetString(reader, "TenKhach"),
                        PhoneNumber = SafeGetString(reader, "SoDienThoai"),
                        RoomNumber = SafeGetString(reader, "SoPhong"),
                        PartnerId = partnerId,
                        PartnerName = partnerName,
                        ServiceTypeId = serviceTypeId,
                        ServiceTypeName = serviceStr,
                        ServiceType = serviceType,
                        WeightKg = SafeGetDecimal(reader, "KhoiLuongKg"),
                        UnitPricePerKg = SafeGetDecimal(reader, "DonGiaKg"),
                        DonGiaVonKg = SafeGetNullableDecimal(reader, "DonGiaVonKg"),
                        HotelEarnings = SafeGetDecimal(reader, "TienKhachSanNhan", "TienKS"),
                        PartnerEarnings = SafeGetDecimal(reader, "TienDoiTacNhan", "TienTraDoiTac", "TienDoiTac"),
                        ClothesConditionNote = SafeGetString(reader, "TinhTrangQuanAoLucNhan"),
                        ReceivedDate = SafeGetDateTime(reader, "NgayNhan"),
                        NgayGiaoDoiTac = SafeGetNullableDateTime(reader, "NgayGiaoDoiTac"),
                        AppointmentDate = SafeGetDateTime(reader, "NgayHenTra"),
                        ActualReturnDate = SafeGetNullableDateTime(reader, "NgayTraThucTe"),
                        ChiPhiPhatSinh = SafeGetDecimal(reader, "ChiPhiPhatSinh"),
                        Status = status,
                        PaymentMethod = paymentMethod,
                        DaThanhToan = daTT,
                        NguoiTaoId = creatorId != 0 ? creatorId : 1,
                        NguoiThanhToanId = payerId,
                        ThoiGianThanhToan = SafeGetNullableDateTime(reader, "ThoiGianThanhToan"),
                        RecordedBy = staff,
                        PaidByStaffName = payerStaff,
                        DaThanhToanChoDoiTac = SafeGetBool(reader, "DaThanhToanChoDoiTac"),
                        NgayThanhToanChoDoiTac = SafeGetNullableDateTime(reader, "NgayThanhToanChoDoiTac"),
                        CoDenBu = SafeGetBool(reader, "CoDenBu"),
                        BenChiuTrachNhiem = SafeGetString(reader, "BenChiuTrachNhiem"),
                        SoTienDenBu = SafeGetDecimal(reader, "SoTienDenBu"),
                        LyDoDenBu = SafeGetString(reader, "LyDoDenBu"),
                        NgayGhiNhanDenBu = SafeGetNullableDateTime(reader, "NgayGhiNhanDenBu"),
                        NguoiGhiNhanDenBuId = SafeGetNullableInt(reader, "NguoiGhiNhanDenBuId")
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Error] LoadLaundryOrdersFromDb: {ex.Message}");
            }
            return list;
        }

        public async Task<bool> CompleteLaundryOrderReturnAsync(int orderId, string orderCode, decimal extraCost, bool coDenBu, string? benChiuTrachNhiem, decimal soTienDenBu, string? lyDoDenBu, int staffId)
        {
            string sql = @"
                UPDATE DonGiatUi
                SET 
                    TrangThai = N'Hoàn tất',
                    NgayTraThucTe = GETDATE(),
                    ChiPhiPhatSinh = @ChiPhiPhatSinh,
                    TongTienThuKhach = (KhoiLuongKg * DonGiaKg) + @ChiPhiPhatSinh,
                    CoDenBu = @CoDenBu,
                    BenChiuTrachNhiem = @BenChiuTrachNhiem,
                    SoTienDenBu = @SoTienDenBu,
                    LyDoDenBu = @LyDoDenBu,
                    NgayGhiNhanDenBu = CASE WHEN @CoDenBu = 1 THEN GETDATE() ELSE NULL END,
                    NguoiGhiNhanDenBuId = CASE WHEN @CoDenBu = 1 THEN @StaffId ELSE NULL END
                WHERE Id = @Id OR MaDon = @MaDon";

            var parameters = new[]
            {
                new SqlParameter("@Id", orderId),
                new SqlParameter("@MaDon", orderCode),
                new SqlParameter("@ChiPhiPhatSinh", extraCost),
                new SqlParameter("@CoDenBu", coDenBu ? 1 : 0),
                new SqlParameter("@BenChiuTrachNhiem", coDenBu && !string.IsNullOrWhiteSpace(benChiuTrachNhiem) ? (object)benChiuTrachNhiem : DBNull.Value),
                new SqlParameter("@SoTienDenBu", soTienDenBu),
                new SqlParameter("@LyDoDenBu", coDenBu && !string.IsNullOrWhiteSpace(lyDoDenBu) ? (object)lyDoDenBu : DBNull.Value),
                new SqlParameter("@StaffId", staffId)
            };

            int affected = await ExecuteNonQueryAsync(sql, parameters);
            return affected > 0;
        }

        #endregion

        #region Stored Procedures Calls

        /// <summary>
        /// Gọi Stored Procedure: sp_XacNhanThanhToanDichVuTheoPhong
        /// </summary>
        public async Task<bool> ConfirmRoomPaymentAsync(string roomNumber, int staffId)
        {
            return await Task.Run(() =>
            {
                try
                {
                    using var conn = new SqlConnection(ConnectionString);
                    conn.Open();
                    using var cmd = new SqlCommand("sp_XacNhanThanhToanDichVuTheoPhong", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@SoPhong", roomNumber);
                    cmd.Parameters.AddWithValue("@NhanVienThanhToanId", staffId);
                    cmd.ExecuteNonQuery();
                    return true;
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[sp_XacNhanThanhToanDichVuTheoPhong Error] {ex.Message}");
                    return false;
                }
            });
        }

        public bool ConfirmRoomPayment(string roomNumber, int staffId)
        {
            try
            {
                using var conn = new SqlConnection(ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("sp_XacNhanThanhToanDichVuTheoPhong", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@SoPhong", roomNumber);
                cmd.Parameters.AddWithValue("@NhanVienThanhToanId", staffId);
                cmd.ExecuteNonQuery();
                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[sp_XacNhanThanhToanDichVuTheoPhong Error] {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Gọi Stored Procedure: sp_XacNhanThanhToanDonLe
        /// </summary>
        public async Task<bool> ConfirmSinglePaymentAsync(string serviceType, string orderCode, int staffId)
        {
            return await Task.Run(() =>
            {
                try
                {
                    using var conn = new SqlConnection(ConnectionString);
                    conn.Open();
                    using var cmd = new SqlCommand("sp_XacNhanThanhToanDonLe", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@LoaiDichVu", serviceType);
                    cmd.Parameters.AddWithValue("@MaDon", orderCode);
                    cmd.Parameters.AddWithValue("@NhanVienThanhToanId", staffId);
                    cmd.ExecuteNonQuery();
                    return true;
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[sp_XacNhanThanhToanDonLe Error] {ex.Message}");
                    return false;
                }
            });
        }

        /// <summary>
        /// Thêm mặt hàng mới vào danh mục MonAn (Tồn kho khởi tạo = 0, Giá vốn = 0)
        /// </summary>
        public async Task<int> AddNewFoodItemAsync(FoodItem item)
        {
            return await Task.Run(() =>
            {
                try
                {
                    using var conn = new SqlConnection(ConnectionString);
                    conn.Open();
                    string sql = @"
                        INSERT INTO MonAn (TenMon, DanhMuc, GiaBan, DonViTinh, GiaVonBinhQuan, SoLuongTonKho, MucTonToiThieu, TrangThai, DonViNhapMacDinh, HeSoQuyDoiMacDinh)
                        VALUES (@TenMon, @DanhMuc, @GiaBan, @DonViTinh, 0, 0, @MucTonToiThieu, @TrangThai, @DonViNhap, @HeSoQuyDoi);
                        SELECT SCOPE_IDENTITY();";
                    using var cmd = new SqlCommand(sql, conn);
                    cmd.Parameters.AddWithValue("@TenMon", item.Name);
                    cmd.Parameters.AddWithValue("@DanhMuc", string.IsNullOrWhiteSpace(item.Category) ? "Đồ ăn" : item.Category);
                    cmd.Parameters.AddWithValue("@GiaBan", item.Price);
                    cmd.Parameters.AddWithValue("@DonViTinh", string.IsNullOrWhiteSpace(item.RetailUnit) ? "Cái" : item.RetailUnit);
                    cmd.Parameters.AddWithValue("@MucTonToiThieu", item.LowStockThreshold >= 0 ? item.LowStockThreshold : 10);
                    cmd.Parameters.AddWithValue("@TrangThai", "Còn hàng");
                    cmd.Parameters.AddWithValue("@DonViNhap", string.IsNullOrWhiteSpace(item.DefaultImportUnit) ? "Thùng" : item.DefaultImportUnit);
                    cmd.Parameters.AddWithValue("@HeSoQuyDoi", item.DefaultConversionRate > 0 ? item.DefaultConversionRate : 24);

                    var res = cmd.ExecuteScalar();
                    return res != null && res != DBNull.Value ? Convert.ToInt32(res) : -1;
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[AddNewFoodItemAsync Error] {ex.Message}");
                    return -1;
                }
            });
        }

        #endregion

        /// <summary>
        /// Thực thi câu lệnh SQL bất đồng bộ xuống CSDL ở tầng nền
        /// </summary>
        public Task<int> ExecuteNonQueryAsync(string sqlCommandText, params SqlParameter[] parameters)
        {
            return Task.Run(() =>
            {
                try
                {
                    using var conn = new SqlConnection(ConnectionString);
                    conn.Open();
                    using var cmd = new SqlCommand(sqlCommandText, conn);
                    if (parameters != null && parameters.Length > 0)
                    {
                        cmd.Parameters.AddRange(parameters);
                    }
                    return cmd.ExecuteNonQuery();
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[SQL Background Sync Warning]: {ex.Message}\nQuery: {sqlCommandText}");
                    return -1;
                }
            });
        }

        /// <summary>
        /// Thực thi câu lệnh SQL trả về giá trị đơn lẻ (Scalar)
        /// </summary>
        public Task<object?> ExecuteScalarAsync(string sqlCommandText, params SqlParameter[] parameters)
        {
            return Task.Run(() =>
            {
                try
                {
                    using var conn = new SqlConnection(ConnectionString);
                    conn.Open();
                    using var cmd = new SqlCommand(sqlCommandText, conn);
                    if (parameters != null && parameters.Length > 0)
                    {
                        cmd.Parameters.AddRange(parameters);
                    }
                    return cmd.ExecuteScalar();
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[SQL ExecuteScalarAsync Warning]: {ex.Message}\nQuery: {sqlCommandText}");
                    return null;
                }
            });
        }
    }
}
