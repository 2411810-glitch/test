using System;
using System.Globalization;
using System.Windows;
using QuanLyDichVuKhachSan.Models;
using QuanLyDichVuKhachSan.Services;

namespace QuanLyDichVuKhachSan.Views
{
    public partial class AddLaundryServiceTypeDialogWindow : Window
    {
        public LaundryServiceTypeItem? CreatedServiceType { get; private set; }

        public AddLaundryServiceTypeDialogWindow()
        {
            InitializeComponent();
            TxtServiceName.Text = "";
            TxtRetailPrice.Text = "";
        }

        private void BtnCancel_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
            Close();
        }

        private async void BtnSave_Click(object sender, RoutedEventArgs e)
        {
            if (!AuthService.Instance.IsAdmin)
            {
                MessageBox.Show("Chỉ tài khoản Admin mới có quyền thêm loại hình dịch vụ giặt!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            string name = TxtServiceName.Text.Trim();
            if (string.IsNullOrWhiteSpace(name))
            {
                MessageBox.Show("Vui lòng nhập Tên loại hình dịch vụ giặt!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            string priceStr = TxtRetailPrice.Text.Replace(",", "").Replace(".", "").Trim();
            if (!decimal.TryParse(priceStr, NumberStyles.Any, CultureInfo.InvariantCulture, out var price) || price <= 0)
            {
                MessageBox.Show("Đơn giá niêm yết phải là số lớn hơn 0!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            var (created, error) = await DatabaseService.Instance.AddLaundryServiceTypeAsync(name, price);
            if (created == null)
            {
                MessageBox.Show(error ?? "Không thể thêm loại hình dịch vụ giặt mới!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            DataService.Instance.LaundryServiceTypes.Add(created);
            DataService.Instance.NotifyLaundryDataChanged();
            CreatedServiceType = created;

            MessageBox.Show($"Đã thêm loại hình dịch vụ giặt [{created.TenLoai}] với giá niêm yết {created.DonGiaBanKg:N0} đ/Kg!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
            DialogResult = true;
            Close();
        }
    }
}

