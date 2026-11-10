using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace QuanLyDichVuKhachSan.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public UserRole Role { get; set; }
        public string PhoneNumber { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public bool IsActive { get; set; } = true;

        public string RoleDisplayName => Role == UserRole.Admin ? "Admin" : "Lễ Tân";
        public bool CanBeLocked => Role != UserRole.Admin;
    }

    public class Customer
    {
        public int Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string IdentityCard { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string RoomNumber { get; set; } = string.Empty;
        public string Note { get; set; } = string.Empty;
    }

    public class Staff : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler? PropertyChanged;
        private void OnPropertyChanged([CallerMemberName] string? name = null) => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));

        private int _id;
        public int Id { get => _id; set { _id = value; OnPropertyChanged(); } }

        private string _code = string.Empty;
        public string Code { get => _code; set { _code = value; OnPropertyChanged(); } }

        private string _fullName = string.Empty;
        public string FullName { get => _fullName; set { _fullName = value; OnPropertyChanged(); } }

        private string _identityCard = string.Empty;
        public string IdentityCard { get => _identityCard; set { _identityCard = value; OnPropertyChanged(); } }

        private string _phoneNumber = string.Empty;
        public string PhoneNumber { get => _phoneNumber; set { _phoneNumber = value; OnPropertyChanged(); } }

        private string _email = string.Empty;
        public string Email { get => _email; set { _email = value; OnPropertyChanged(); } }

        private string _position = string.Empty;
        public string Position { get => _position; set { _position = value; OnPropertyChanged(); } }

        private decimal _baseSalary;
        public decimal BaseSalary { get => _baseSalary; set { _baseSalary = value; OnPropertyChanged(); } }

        private string _status = "Đang làm việc";
        public string Status { get => _status; set { _status = value; OnPropertyChanged(); } }
    }

    public class Shift
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public string Note { get; set; } = string.Empty;

        public string TimeDisplay => $"{StartTime:hh\\:mm} - {EndTime:hh\\:mm}";
    }

    public class ShiftAssignment
    {
        public int Id { get; set; }
        public int StaffId { get; set; }
        public string StaffName { get; set; } = string.Empty;
        public int ShiftId { get; set; }
        public string ShiftName { get; set; } = string.Empty;
        public DateTime ShiftDate { get; set; }
        public string Note { get; set; } = string.Empty;
    }

    public class HotelServiceConfig : System.ComponentModel.INotifyPropertyChanged
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string ServiceType { get; set; } = string.Empty; // Tự túc / Ngoài

        public string Icon => Code?.Trim().ToUpperInvariant() switch
        {
            "AN_UONG" => "🍲",
            "SU_KIEN" => "🏛️",
            "THUE_XE" => "🛵",
            "DO_XE" => "🅿️",
            "GIAT_UI" => "🧺",
            _ => "🛎️"
        };

        private bool _isActive = true;
        public bool IsActive
        {
            get => _isActive;
            set
            {
                if (_isActive != value)
                {
                    _isActive = value;
                    PropertyChanged?.Invoke(this, new System.ComponentModel.PropertyChangedEventArgs(nameof(IsActive)));
                    OnActiveChanged?.Invoke(this);
                }
            }
        }

        public string Description { get; set; } = string.Empty;

        public event System.ComponentModel.PropertyChangedEventHandler? PropertyChanged;
        public static event Action<HotelServiceConfig>? OnActiveChanged;
    }
}
