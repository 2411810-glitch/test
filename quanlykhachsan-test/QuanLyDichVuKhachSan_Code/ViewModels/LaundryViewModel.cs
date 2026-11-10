using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;

namespace QuanLyDichVuKhachSan // Nếu file cũ của bạn là QuanLyDichVuKhachSan.Views thì giữ nguyên .Views
{
    public partial class LaundryServiceView : UserControl
    {
        private ObservableCollection<DonGiatUiHienThi> _dsGiatUi;
        private readonly string[] _cacBuocTienDo = 
        { 
            "Đã tiếp nhận", 
            "Đang giặt", 
            "Đang sấy", 
            "Đang ủi", 
            "Hoàn thành", 
            "Đã giao khách" 
        };

        public LaundryServiceView()
        {
            InitializeComponent();
            TaiDuLieuGiatUi();
        }

        private void TaiDuLieuGiatUi()
        {
            if (_dsGiatUi == null)
            {
                _dsGiatUi = new ObservableCollection<DonGiatUiHienThi>
                {
                    new DonGiatUiHienThi("DH001", "Nguyễn Hằng", "0234563 9806", "Giặt sấy nhanh", "Đang giặt", "50.000"),
                    new DonGiatUiHienThi("DH002", "Nguyễn Nganh", "0234563 9809", "Giặt ủi cao cấp", "Đang sấy", "85.000"),
                    new DonGiatUiHienThi("DH003", "Nguyễn Hằng", "0234559 9809", "Giặt khô Vest", "Đã tiếp nhận", "120.000"),
                    new DonGiatUiHienThi("DH004", "Nguyễn Hằng", "0234564 9808", "Giặt sấy thường", "Đã tiếp nhận", "45.000"),
                    new DonGiatUiHienThi("DH005", "Trần Minh Quân", "0234554 9809", "Giặt ủi theo bộ", "Đang giặt", "60.000"),
                    new DonGiatUiHienThi("DH006", "Lê Thu Thảo", "0334558 9809", "Giặt chăn ga", "Hoàn thành", "150.000"),
                    new DonGiatUiHienThi("DH007", "Phạm Hoàng Nam", "09749 272037", "Giặt sấy thường", "Đang ủi", "50.000"),
                    new DonGiatUiHienThi("DH008", "Võ Gia Huy", "09749 278038", "Giặt ủi cao cấp", "Đã giao khách", "95.000")
                };
            }
            CapNhatThongKeGiatUi(_dsGiatUi);
        }

        private void CapNhatThongKeGiatUi(IEnumerable<DonGiatUiHienThi> list)
        {
            if (dgDonGiatUi != null)
                dgDonGiatUi.ItemsSource = list.ToList();

            if (_dsGiatUi == null) return;

            if (txtTongDonGiatUi != null)
                txtTongDonGiatUi.Text = $"{_dsGiatUi.Count:00} đơn";

            if (txtDangXuLyGiatUi != null)
                txtDangXuLyGiatUi.Text = $"{_dsGiatUi.Count(x => x.TrangThai == "Đang giặt" || x.TrangThai == "Đang sấy" || x.TrangThai == "Đang ủi"):00} đơn";

            if (txtChoGiaoGiatUi != null)
                txtChoGiaoGiatUi.Text = $"{_dsGiatUi.Count(x => x.TrangThai == "Hoàn thành")} đơn";
        }

        private void BtnCapNhatTienDo_Click(object sender, RoutedEventArgs e)
        {
            if ((sender as FrameworkElement)?.DataContext is DonGiatUiHienThi don)
            {
                int idx = Array.IndexOf(_cacBuocTienDo, don.TrangThai);
                if (idx >= 0 && idx < _cacBuocTienDo.Length - 1)
                {
                    don.CapNhatTrangThai(_cacBuocTienDo[idx + 1]);
                    CapNhatThongKeGiatUi(_dsGiatUi);
                }
                else
                {
                    MessageBox.Show($"Đơn {don.MaDon} đã hoàn thành bàn giao cho khách!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
                }
            }
        }

        private void BtnLichSuGiatUi_Click(object sender, RoutedEventArgs e)
        {
            if ((sender as FrameworkElement)?.DataContext is DonGiatUiHienThi don)
            {
                MessageBox.Show(
                    $"Mã đơn: {don.MaDon}\nKhách hàng: {don.TenKhachHang}\nSĐT: {don.SoDienThoai}\nDịch vụ: {don.DichVu}\nTrạng thái hiện tại: {don.TrangThai} ({don.TienDo}%)",
                    "Lịch Sử Tiến Độ", MessageBoxButton.OK, MessageBoxImage.Information);
            }
        }

        private void DgDonGiatUi_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (dgDonGiatUi.SelectedItem is DonGiatUiHienThi don)
            {
                txtMaDonGui.Text = don.MaDon;
                txtTenKhachGui.Text = don.TenKhachHang;
                txtSdtGui.Text = don.SoDienThoai;
                txtDonGiaGui.Text = don.DonGia;
            }
        }

        private void BtnTiepNhanDon_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(txtTenKhachGui.Text))
            {
                MessageBox.Show("Vui lòng nhập tên khách hàng!", "Cảnh báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            string ma = string.IsNullOrWhiteSpace(txtMaDonGui.Text) ? $"DH{_dsGiatUi.Count + 1:000}" : txtMaDonGui.Text.Trim();
            string dv = (cboLoaiGiatUi.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? "Giặt sấy thường";
            string sdt = string.IsNullOrWhiteSpace(txtSdtGui.Text) ? "0900 000 000" : txtSdtGui.Text.Trim();

            _dsGiatUi.Insert(0, new DonGiatUiHienThi(ma, txtTenKhachGui.Text.Trim(), sdt, dv, "Đã tiếp nhận", txtDonGiaGui.Text.Trim()));
            CapNhatThongKeGiatUi(_dsGiatUi);
            BtnLamMoiFormGiatUi_Click(null, null);
        }

        private void BtnChiTietDon_Click(object sender, RoutedEventArgs e)
        {
            if (dgDonGiatUi.SelectedItem is DonGiatUiHienThi don)
            {
                MessageBox.Show(
                    $"CHI TIẾT ĐƠN GIẶT ỦI\n------------------------\nMã đơn: {don.MaDon}\nKhách hàng: {don.TenKhachHang}\nSĐT: {don.SoDienThoai}\nDịch vụ: {don.DichVu}\nĐơn giá: {don.DonGia} VNĐ\nTrạng thái: {don.TrangThai}",
                    "Chi Tiết Đơn Hàng", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            else
            {
                MessageBox.Show("Vui lòng chọn 1 đơn trong bảng danh sách!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
            }
        }

        private void BtnLamMoiFormGiatUi_Click(object sender, RoutedEventArgs e)
        {
            txtMaDonGui.Text = $"DH{_dsGiatUi.Count + 1:000}";
            txtTenKhachGui.Clear();
            txtSdtGui.Clear();
            cboLoaiGiatUi.SelectedIndex = 0;
            txtDonGiaGui.Text = "50.000";
            dgDonGiatUi.SelectedItem = null;
        }

        private void BtnLamMoiGiatUi_Click(object sender, RoutedEventArgs e)
        {
            txtTimKiemGiatUi.Clear();
            CapNhatThongKeGiatUi(_dsGiatUi);
        }

        private void TxtTimKiemGiatUi_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (_dsGiatUi == null) return;
            string kw = txtTimKiemGiatUi.Text.Trim().ToLower();
            if (string.IsNullOrEmpty(kw))
            {
                CapNhatThongKeGiatUi(_dsGiatUi);
            }
            else
            {
                dgDonGiatUi.ItemsSource = _dsGiatUi.Where(x =>
                    x.MaDon.ToLower().Contains(kw) ||
                    x.TenKhachHang.ToLower().Contains(kw) ||
                    x.SoDienThoai.ToLower().Contains(kw) ||
                    x.DichVu.ToLower().Contains(kw)).ToList();
            }
        }

        private void CardLocTatCa_Click(object sender, MouseButtonEventArgs e) => CapNhatThongKeGiatUi(_dsGiatUi);

        private void CardLocDangXuLy_Click(object sender, MouseButtonEventArgs e) =>
            dgDonGiatUi.ItemsSource = _dsGiatUi.Where(x => x.TrangThai == "Đang giặt" || x.TrangThai == "Đang sấy" || x.TrangThai == "Đang ủi").ToList();

        private void CardLocChoGiao_Click(object sender, MouseButtonEventArgs e) =>
            dgDonGiatUi.ItemsSource = _dsGiatUi.Where(x => x.TrangThai == "Hoàn thành").ToList();

        private void StepFilter_Click(object sender, MouseButtonEventArgs e)
        {
            if (sender is FrameworkElement el && el.Tag is string buoc)
            {
                dgDonGiatUi.ItemsSource = _dsGiatUi.Where(x => x.TrangThai == buoc).ToList();
            }
        }
    }

    public class DonGiatUiHienThi : INotifyPropertyChanged
    {
        public string MaDon { get; set; }
        public string TenKhachHang { get; set; }
        public string SoDienThoai { get; set; }
        public string DichVu { get; set; }
        public string DonGia { get; set; }

        private string _trangThai;
        public string TrangThai
        {
            get => _trangThai;
            set { _trangThai = value; OnPropertyChanged(nameof(TrangThai)); }
        }

        private int _tienDo;
        public int TienDo
        {
            get => _tienDo;
            set { _tienDo = value; OnPropertyChanged(nameof(TienDo)); }
        }

        private Brush _mauNen;
        public Brush MauNen
        {
            get => _mauNen;
            set { _mauNen = value; OnPropertyChanged(nameof(MauNen)); }
        }

        private Brush _mauChu;
        public Brush MauChu
        {
            get => _mauChu;
            set { _mauChu = value; OnPropertyChanged(nameof(MauChu)); }
        }

        public DonGiatUiHienThi(string ma, string ten, string sdt, string dv, string tt, string gia)
        {
            MaDon = ma;
            TenKhachHang = ten;
            SoDienThoai = sdt;
            DichVu = dv;
            DonGia = gia;
            CapNhatTrangThai(tt);
        }

        public void CapNhatTrangThai(string trangThaiMoi)
        {
            TrangThai = trangThaiMoi;
            var bc = new BrushConverter();
            switch (trangThaiMoi)
            {
                case "Đã tiếp nhận":
                    TienDo = 16;
                    MauNen = (Brush)bc.ConvertFrom("#DCFCE7");
                    MauChu = (Brush)bc.ConvertFrom("#15803D");
                    break;
                case "Đang giặt":
                    TienDo = 35;
                    MauNen = (Brush)bc.ConvertFrom("#DBEAFE");
                    MauChu = (Brush)bc.ConvertFrom("#1D4ED8");
                    break;
                case "Đang sấy":
                    TienDo = 55;
                    MauNen = (Brush)bc.ConvertFrom("#FEF9C3");
                    MauChu = (Brush)bc.ConvertFrom("#A16207");
                    break;
                case "Đang ủi":
                    TienDo = 75;
                    MauNen = (Brush)bc.ConvertFrom("#E0E7FF");
                    MauChu = (Brush)bc.ConvertFrom("#4338CA");
                    break;
                case "Hoàn thành":
                    TienDo = 90;
                    MauNen = (Brush)bc.ConvertFrom("#FEE2E2");
                    MauChu = (Brush)bc.ConvertFrom("#B91C1C");
                    break;
                case "Đã giao khách":
                    TienDo = 100;
                    MauNen = (Brush)bc.ConvertFrom("#E2E8F0");
                    MauChu = (Brush)bc.ConvertFrom("#334155");
                    break;
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged(string name) => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
}