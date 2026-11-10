using System;
using System.Linq;
using System.Windows;
using System.Windows.Input;
using Microsoft.Data.SqlClient;
using QuanLyDichVuKhachSan.Models;
using QuanLyDichVuKhachSan.Services;
using QuanLyDichVuKhachSan.Views;

namespace QuanLyDichVuKhachSan.ViewModels
{
    public class ServicesConfigViewModel : BaseViewModel
    {
        public DataService Data => DataService.Instance;
        public AuthService Auth => AuthService.Instance;

        private readonly Action? _onServicesConfigApplied;

        public bool IsAdmin => Auth.IsAdmin;

        private string _newCode = "";
        public string NewCode { get => _newCode; set => SetProperty(ref _newCode, value); }

        private string _newName = "";
        public string NewName { get => _newName; set => SetProperty(ref _newName, value); }

        private string _newType = "Tự túc";
        public string NewType { get => _newType; set => SetProperty(ref _newType, value); }

        private string _newDesc = "";
        public string NewDesc { get => _newDesc; set => SetProperty(ref _newDesc, value); }

        public ICommand AddServiceCommand { get; }
        public ICommand DeleteServiceCommand { get; }
        public ICommand ToggleActiveCommand { get; }
        public ICommand OpenAccountManagementCommand { get; }

        public ServicesConfigViewModel(Action? onServicesConfigApplied = null)
        {
            _onServicesConfigApplied = onServicesConfigApplied;
            AddServiceCommand = new RelayCommand(AddService);
            DeleteServiceCommand = new RelayCommand(DeleteService);
            ToggleActiveCommand = new RelayCommand(async parameter => await ToggleActiveAsync(parameter));
            OpenAccountManagementCommand = new RelayCommand(OpenAccountManagement);
        }

        private void OpenAccountManagement(object? parameter)
        {
            var win = new AccountManagementWindow();
            win.ShowDialog();
        }

        private async System.Threading.Tasks.Task ToggleActiveAsync(object? parameter)
        {
            if (parameter is not HotelServiceConfig service) return;

            // CheckBox đã cập nhật IsActive trước khi Command được gọi.
            bool desiredState = service.IsActive;

            int affected = await DatabaseService.Instance.ExecuteNonQueryAsync(
                "UPDATE DichVuHeThong SET DangHoatDong = @Active WHERE MaDV = @Code",
                new SqlParameter("@Active", desiredState ? 1 : 0),
                new SqlParameter("@Code", service.Code));

            if (affected <= 0)
            {
                // Không lưu được thì trả checkbox về trạng thái cũ để giao diện và CSDL luôn khớp nhau.
                service.IsActive = !desiredState;
                MessageBox.Show(
                    "Không thể cập nhật trạng thái dịch vụ vào CSDL. Vui lòng kiểm tra kết nối SQL Server rồi thử lại!",
                    "Lỗi cập nhật",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
                return;
            }

            // Làm mới thanh điều hướng ngay sau khi tick/bỏ tick thành công.
            _onServicesConfigApplied?.Invoke();
        }

        private void AddService(object? parameter)
        {
            if (string.IsNullOrWhiteSpace(NewCode) || string.IsNullOrWhiteSpace(NewName))
            {
                MessageBox.Show("Vui lòng nhập Mã dịch vụ và Tên dịch vụ!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (Data.ServicesConfig.Any(s => s.Code.Equals(NewCode.Trim(), StringComparison.OrdinalIgnoreCase)))
            {
                MessageBox.Show($"Mã dịch vụ [{NewCode}] đã tồn tại trong hệ thống!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            var service = new HotelServiceConfig
            {
                Code = NewCode.Trim().ToUpperInvariant(),
                Name = NewName.Trim(),
                ServiceType = NewType,
                Description = NewDesc?.Trim() ?? "",
                IsActive = true
            };

            Data.ServicesConfig.Add(service);

            // Đồng bộ xuống CSDL SQL Server (Table DichVuHeThong)
            _ = DatabaseService.Instance.ExecuteNonQueryAsync(
                "IF NOT EXISTS (SELECT 1 FROM DichVuHeThong WHERE MaDV = @Code) " +
                "INSERT INTO DichVuHeThong (MaDV, TenDV, LoaiDichVu, DangHoatDong, MoTa) VALUES (@Code, @Ten, @Loai, 1, @MoTa)",
                new SqlParameter("@Code", service.Code),
                new SqlParameter("@Ten", service.Name),
                new SqlParameter("@Loai", service.ServiceType),
                new SqlParameter("@MoTa", service.Description)
            );

            NewCode = "";
            NewName = "";
            NewDesc = "";

            MessageBox.Show($"Đã thêm dịch vụ [{service.Name}] thành công!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        private void DeleteService(object? parameter)
        {
            if (parameter is HotelServiceConfig service)
            {
                var res = MessageBox.Show($"Bạn có chắc chắn muốn xóa dịch vụ [{service.Name}] khỏi hệ thống?", "Thông báo", MessageBoxButton.YesNo, MessageBoxImage.Question);
                if (res == MessageBoxResult.Yes)
                {
                    Data.ServicesConfig.Remove(service);

                    _ = DatabaseService.Instance.ExecuteNonQueryAsync(
                        "DELETE FROM DichVuHeThong WHERE MaDV = @Code",
                        new SqlParameter("@Code", service.Code)
                    );
                }
            }
        }
    }
}
