using System;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using Microsoft.Data.SqlClient;
using QuanLyDichVuKhachSan.Models;
using QuanLyDichVuKhachSan.Services;

namespace QuanLyDichVuKhachSan.Views
{
    public partial class AddVehicleDialogWindow : Window
    {
        public AddVehicleDialogWindow()
        {
            InitializeComponent();
            ResetForm();
        }

        private void ResetForm()
        {
            int nextIndex = DataService.Instance.Vehicles.Count + 1;
            string autoCode = $"XE{nextIndex:D3}";
            while (DataService.Instance.Vehicles.Any(x => x.Id == nextIndex))
            {
                nextIndex++;
                autoCode = $"XE{nextIndex:D3}";
            }

            TxtCode.Text = autoCode;
            TxtLicensePlate.Text = "";
            TxtName.Text = "";
            CboType.SelectedIndex = 0;
            TxtDailyRate.Text = "";
            TxtRequiredDeposit.Text = "";
            CboStatus.SelectedIndex = 0;
            TxtConditionNote.Text = "";
        }

        private void TxtDailyRate_TextChanged(object sender, TextChangedEventArgs e)
        {
            // Giữ ô Tiền Cọc trống để người dùng chủ động nhập nếu cần
        }

        private void BtnCancel_Click(object sender, RoutedEventArgs e)
        {
            ResetForm();
        }

        private async void BtnSave_Click(object sender, RoutedEventArgs e)
        {
            string plate = TxtLicensePlate.Text.Trim();
            string name = TxtName.Text.Trim();

            if (string.IsNullOrWhiteSpace(plate) || string.IsNullOrWhiteSpace(name))
            {
                MessageBox.Show("Vui lòng nhập đầy đủ Biển số xe và Tên xe!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (DataService.Instance.Vehicles.Any(x => string.Equals(x.LicensePlate, plate, StringComparison.OrdinalIgnoreCase)))
            {
                MessageBox.Show($"Biển số xe [{plate}] đã tồn tại trong hệ thống! Vui lòng chọn biển số khác.", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            string rateStr = TxtDailyRate.Text.Replace(",", "").Replace(".", "").Trim();
            if (!decimal.TryParse(rateStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var rate) || rate <= 0)
            {
                MessageBox.Show("Giá thuê theo ngày phải lớn hơn 0!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            decimal deposit = 0m;
            string depositStr = TxtRequiredDeposit.Text.Replace(",", "").Replace(".", "").Trim();
            if (!string.IsNullOrWhiteSpace(depositStr))
            {
                if (!decimal.TryParse(depositStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out deposit) || deposit < 0)
                {
                    MessageBox.Show("Tiền cọc quy định không hợp lệ!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                    return;
                }
            }

            VehicleType vType = VehicleType.Scooter;
            if (CboType.SelectedItem is ComboBoxItem typeItem && typeItem.Tag is VehicleType vt)
            {
                vType = vt;
            }

            VehicleStatus vStatus = VehicleStatus.Available;
            if (CboStatus.SelectedItem is ComboBoxItem stItem && stItem.Tag is VehicleStatus vs)
            {
                vStatus = vs;
            }

            string note = TxtConditionNote.Text.Trim();

            int newId = 0;
            try
            {
                string sql = "INSERT INTO XeChoThue (BienSo, TenXe, LoaiXe, GiaThueNgay, TienCocQuyDinh, TrangThai, GhiChuTinhTrang) " +
                             "OUTPUT INSERTED.Id " +
                             "VALUES (@BienSo, @Ten, @Loai, @Gia, @Coc, @Status, @Note);";

                using var conn = new SqlConnection(DatabaseService.Instance.ConnectionString);
                await conn.OpenAsync();
                using var cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@BienSo", plate);
                cmd.Parameters.AddWithValue("@Ten", name);
                string dbType = vType switch
                {
                    VehicleType.Scooter => "Xe tay ga",
                    VehicleType.Manual => "Xe số",
                    VehicleType.Clutch => "Xe côn tay",
                    _ => "Xe ô tô"
                };
                string dbStatus = vStatus switch
                {
                    VehicleStatus.Available => "Sẵn sàng",
                    VehicleStatus.Maintenance => "Bảo trì",
                    _ => "Hoạt động"
                };

                cmd.Parameters.AddWithValue("@Loai", dbType);
                cmd.Parameters.AddWithValue("@Gia", rate);
                cmd.Parameters.AddWithValue("@Coc", deposit);
                cmd.Parameters.AddWithValue("@Status", dbStatus);
                cmd.Parameters.AddWithValue("@Note", note);

                var res = await cmd.ExecuteScalarAsync();
                if (res != null && int.TryParse(res.ToString(), out var id))
                {
                    newId = id;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Insert Vehicle Error] {ex.Message}");
            }

            if (newId <= 0)
            {
                MessageBox.Show("Không thể lưu xe vào CSDL. Vui lòng kiểm tra kết nối và thử lại!", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            var newVehicle = new Vehicle
            {
                Id = newId,
                LicensePlate = plate,
                Name = name,
                Type = vType,
                DailyRate = rate,
                RequiredDeposit = deposit,
                Status = vStatus,
                ConditionNote = note
            };

            DataService.Instance.AddVehicleToCache(newVehicle);

            MessageBox.Show($"Đã thêm mới xe [{newVehicle.Name} - {newVehicle.LicensePlate}] (Mã: {TxtCode.Text}) thành công!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
            DialogResult = true;
            Close();
        }
    }
}
