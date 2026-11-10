using System;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using Microsoft.Data.SqlClient;
using QuanLyDichVuKhachSan.Models;
using QuanLyDichVuKhachSan.Services;

namespace QuanLyDichVuKhachSan.Views
{
    public partial class AddLaundryPartnerDialogWindow : Window
    {
        private readonly ObservableCollection<PartnerServicePriceItem> _partnerPrices = new();
        private bool _isSyncingSelection;
        private bool _isCostPriceModified;

        public AddLaundryPartnerDialogWindow()
        {
            InitializeComponent();
            CboServiceType.ItemsSource = DataService.Instance.LaundryServiceTypes;
            DgPartnerPrices.ItemsSource = _partnerPrices;
            ResetForm();
        }

        private void ResetForm()
        {
            int nextIndex = DataService.Instance.LaundryPartners.Count + 1;
            string autoCode = $"DT{nextIndex:D2}";
            while (DataService.Instance.LaundryPartners.Any(x => x.Name.Contains(autoCode) || x.Id == nextIndex))
            {
                nextIndex++;
                autoCode = $"DT{nextIndex:D2}";
            }

            TxtCode.Text = autoCode;
            TxtName.Text = "";
            TxtAddress.Text = "";
            TxtPhoneNumber.Text = "";
            _partnerPrices.Clear();
            CboStatus.SelectedIndex = 0;

            _isSyncingSelection = true;
            try
            {
                if (CboServiceType.Items.Count > 0) CboServiceType.SelectedIndex = 0;
                TxtCostPrice.Text = "";
                _isCostPriceModified = false;
            }
            finally
            {
                _isSyncingSelection = false;
            }
        }

        private void CboServiceType_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (_isSyncingSelection) return;
            _isSyncingSelection = true;
            try
            {
                if (CboServiceType.SelectedItem is LaundryServiceTypeItem selectedSvc)
                {
                    var match = _partnerPrices.FirstOrDefault(p =>
                        p.LoaiDichVuId == selectedSvc.Id ||
                        string.Equals(p.TenLoai, selectedSvc.TenLoai, StringComparison.OrdinalIgnoreCase));

                    TxtCostPrice.Text = match != null ? match.DonGiaVonKg.ToString("0", CultureInfo.InvariantCulture) : "";
                    DgPartnerPrices.SelectedItem = match;
                }
                else
                {
                    TxtCostPrice.Text = "";
                }
                _isCostPriceModified = false;
            }
            finally
            {
                _isSyncingSelection = false;
            }
        }

        private void DgPartnerPrices_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (_isSyncingSelection) return;
            if (DgPartnerPrices.SelectedItem is not PartnerServicePriceItem selectedItem) return;

            _isSyncingSelection = true;
            try
            {
                var svcMatch = DataService.Instance.LaundryServiceTypes.FirstOrDefault(s =>
                    s.Id == selectedItem.LoaiDichVuId ||
                    string.Equals(s.TenLoai, selectedItem.TenLoai, StringComparison.OrdinalIgnoreCase));

                if (svcMatch != null)
                {
                    CboServiceType.SelectedItem = svcMatch;
                }
                TxtCostPrice.Text = selectedItem.DonGiaVonKg.ToString("0", CultureInfo.InvariantCulture);
                _isCostPriceModified = false;
            }
            finally
            {
                _isSyncingSelection = false;
            }
        }

        private void DgPartnerPricesRow_PreviewMouseRightButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (sender is DataGridRow row)
            {
                row.IsSelected = true;
                row.Focus();
            }
        }

        private void MenuItem_DeleteServicePrice_Click(object sender, RoutedEventArgs e)
        {
            if (DgPartnerPrices.SelectedItem is not PartnerServicePriceItem item) return;

            _partnerPrices.Remove(item);
            if (CboServiceType.SelectedItem is LaundryServiceTypeItem svc &&
                (svc.Id == item.LoaiDichVuId || string.Equals(svc.TenLoai, item.TenLoai, StringComparison.OrdinalIgnoreCase)))
            {
                _isSyncingSelection = true;
                TxtCostPrice.Text = "";
                _isCostPriceModified = false;
                _isSyncingSelection = false;
            }
        }

        private void TxtCostPrice_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (!_isSyncingSelection)
            {
                _isCostPriceModified = true;
            }
        }

        private void TxtCostPrice_PreviewKeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
            {
                e.Handled = true;
                if (TryApplyCurrentServicePrice(showWarningIfEmpty: true, showWarningIfInvalid: true))
                {
                    _isCostPriceModified = false;
                    Keyboard.ClearFocus();
                }
            }
        }

        private void TxtCostPrice_LostFocus(object sender, RoutedEventArgs e)
        {
            if (!_isCostPriceModified || !IsActive) return;
            if (BtnCancel.IsMouseOver || BtnConfirm.IsMouseOver) return;

            if (!TryApplyCurrentServicePrice(showWarningIfEmpty: false, showWarningIfInvalid: true))
            {
                // Khôi phục lại giá hợp lệ trước đó trong lưới (nếu có) để tránh kẹt
                if (CboServiceType.SelectedItem is LaundryServiceTypeItem svc)
                {
                    var match = _partnerPrices.FirstOrDefault(p =>
                        p.LoaiDichVuId == svc.Id ||
                        string.Equals(p.TenLoai, svc.TenLoai, StringComparison.OrdinalIgnoreCase));
                    _isSyncingSelection = true;
                    TxtCostPrice.Text = match != null ? match.DonGiaVonKg.ToString("0", CultureInfo.InvariantCulture) : "";
                    _isSyncingSelection = false;
                }
            }
            _isCostPriceModified = false;
        }

        private bool TryApplyCurrentServicePrice(bool showWarningIfEmpty, bool showWarningIfInvalid)
        {
            if (CboServiceType.SelectedItem is not LaundryServiceTypeItem selectedSvc)
            {
                if (showWarningIfInvalid)
                    MessageBox.Show("Vui lòng chọn loại hình dịch vụ giặt!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return false;
            }

            var existing = _partnerPrices.FirstOrDefault(p =>
                p.LoaiDichVuId == selectedSvc.Id ||
                string.Equals(p.TenLoai, selectedSvc.TenLoai, StringComparison.OrdinalIgnoreCase));

            string costStr = TxtCostPrice.Text.Replace(",", "").Replace(".", "").Trim();
            if (string.IsNullOrWhiteSpace(costStr))
            {
                // Giá rỗng => xóa dịch vụ này khỏi danh sách đối tác nếu đang tồn tại
                if (existing != null)
                {
                    _partnerPrices.Remove(existing);
                    return true;
                }
                if (showWarningIfEmpty)
                    MessageBox.Show("Vui lòng nhập giá vốn đối tác báo cho loại hình dịch vụ này!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return !showWarningIfEmpty;
            }

            if (!decimal.TryParse(costStr, NumberStyles.Any, CultureInfo.InvariantCulture, out var cost) || cost <= 0 || cost >= selectedSvc.DonGiaBanKg)
            {
                if (showWarningIfInvalid)
                    MessageBox.Show($"Giá vốn [{selectedSvc.TenLoai}] phải lớn hơn 0 và nhỏ hơn giá niêm yết ({selectedSvc.DonGiaBanKg:N0} đ/Kg)!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return false;
            }

            if (existing != null)
            {
                existing.DonGiaBanKg = selectedSvc.DonGiaBanKg;
                existing.DonGiaVonKg = cost;
            }
            else
            {
                var added = new PartnerServicePriceItem
                {
                    LoaiDichVuId = selectedSvc.Id,
                    MaLoai = selectedSvc.MaLoai,
                    TenLoai = selectedSvc.TenLoai,
                    DonGiaBanKg = selectedSvc.DonGiaBanKg,
                    DonGiaVonKg = cost
                };
                _partnerPrices.Add(added);
                _isSyncingSelection = true;
                DgPartnerPrices.SelectedItem = added;
                _isSyncingSelection = false;
            }

            return true;
        }

        private void BtnAddServicePrice_Click(object sender, RoutedEventArgs e)
        {
            if (TryApplyCurrentServicePrice(showWarningIfEmpty: true, showWarningIfInvalid: true))
            {
                _isCostPriceModified = false;
            }
        }

        private void BtnCancel_Click(object sender, RoutedEventArgs e)
        {
            ResetForm();
        }

        private async void BtnSave_Click(object sender, RoutedEventArgs e)
        {
            string name = TxtName.Text.Trim();
            string address = TxtAddress.Text.Trim();
            string phone = TxtPhoneNumber.Text.Trim();

            if (string.IsNullOrWhiteSpace(name) || string.IsNullOrWhiteSpace(phone))
            {
                MessageBox.Show("Vui lòng nhập Tên đối tác và Số điện thoại liên hệ!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            // Nếu người dùng vừa sửa giá vốn rồi bấm thẳng Xác nhận -> ghi nhận luôn thay đổi vào bảng giá trước khi lưu DB
            if (_isCostPriceModified)
            {
                if (!TryApplyCurrentServicePrice(showWarningIfEmpty: false, showWarningIfInvalid: true)) return;
                _isCostPriceModified = false;
            }

            if (_partnerPrices.Count == 0)
            {
                MessageBox.Show("Vui lòng chọn ít nhất 1 loại hình dịch vụ giặt, nhập giá vốn đối tác báo và bấm '➕ Lưu giá'!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            var ratios = _partnerPrices
                .Where(p => p.DonGiaBanKg > 0)
                .Select(p => (p.DonGiaBanKg - p.DonGiaVonKg) / p.DonGiaBanKg * 100m)
                .ToList();
            decimal commission = ratios.Count > 0 ? Math.Round(ratios.Average(), 2) : 30m;
            bool isActive = CboStatus.SelectedIndex == 0;

            int newId = 0;
            try
            {
                string sql = "INSERT INTO DoiTacGiatUi (TenDoiTac, DiaChi, SoDienThoai, TyLeKhachSanHuong, TyLeDoiTacHuong, TrangThai) " +
                             "OUTPUT INSERTED.Id " +
                             "VALUES (@Ten, @DiaChi, @Phone, @Commission, @PartnerRate, @Status);";

                using var conn = new SqlConnection(DatabaseService.Instance.ConnectionString);
                await conn.OpenAsync();
                using var cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@Ten", name);
                cmd.Parameters.AddWithValue("@DiaChi", string.IsNullOrWhiteSpace(address) ? DBNull.Value : (object)address);
                cmd.Parameters.AddWithValue("@Phone", phone);
                cmd.Parameters.AddWithValue("@Commission", commission);
                cmd.Parameters.AddWithValue("@PartnerRate", Math.Max(0, 100m - commission));
                cmd.Parameters.AddWithValue("@Status", isActive ? 1 : 0);

                var res = await cmd.ExecuteScalarAsync();
                if (res != null && int.TryParse(res.ToString(), out var id))
                {
                    newId = id;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SQL Insert Partner Error] {ex.Message}");
                MessageBox.Show($"Không thể lưu đối tác vào CSDL: {ex.Message}", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            if (newId <= 0)
            {
                MessageBox.Show("Không thể thêm đối tác mới vào CSDL!", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            var (savedPricesOk, priceError) = await DatabaseService.Instance.SavePartnerServicePricesAsync(newId, _partnerPrices);
            if (!savedPricesOk)
            {
                MessageBox.Show($"Đã tạo đối tác nhưng gặp lỗi khi lưu bảng giá vốn: {priceError}", "Cảnh báo", MessageBoxButton.OK, MessageBoxImage.Warning);
            }

            var newPartner = new LaundryPartner
            {
                Id = newId,
                Name = name,
                Address = address,
                PhoneNumber = phone,
                HotelCommissionRate = commission,
                IsActive = isActive
            };
            foreach (var p in _partnerPrices)
            {
                newPartner.ServicePrices.Add(p);
                if (p.MaLoai == "GIAT_SAY" || p.TenLoai.Contains("sấy", StringComparison.OrdinalIgnoreCase))
                    newPartner.GiaVonGiatSay = p.DonGiaVonKg;
                else if (p.MaLoai == "GIAT_HAP" || p.TenLoai.Contains("hấp", StringComparison.OrdinalIgnoreCase))
                    newPartner.GiaVonGiatHap = p.DonGiaVonKg;
                else if (p.MaLoai == "UI_PHANG" || p.TenLoai.Contains("ủi", StringComparison.OrdinalIgnoreCase))
                    newPartner.GiaVonUiPhang = p.DonGiaVonKg;
            }
            newPartner.NotifyPriceSummaryChanged();

            DataService.Instance.AddLaundryPartnerToCache(newPartner);
            DataService.Instance.NotifyLaundryDataChanged();

            MessageBox.Show($"Đã thêm mới đối tác [{newPartner.Name}] (Mã: {TxtCode.Text}) với {_partnerPrices.Count} dịch vụ thành công!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
            DialogResult = true;
            Close();
        }
    }
}
