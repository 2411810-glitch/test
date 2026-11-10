using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using System.Windows;
using System.Windows.Input;
using QuanLyDichVuKhachSan.Models;
using QuanLyDichVuKhachSan.Services;
using QuanLyDichVuKhachSan.Views;

namespace QuanLyDichVuKhachSan.ViewModels
{
    public class MainViewModel : BaseViewModel
    {
        public AuthService Auth => AuthService.Instance;
        public DataService Data => DataService.Instance;

        // ------------------------------------------------------------------
        // ViewModels con: khởi tạo muộn (lazy) — chỉ tạo khi tab được mở lần đầu.
        // Không dùng getter trong constructor hoặc trong các đoạn code chạy lúc khởi động.
        // ------------------------------------------------------------------
        private RoomMapViewModel? _roomMapVM;
        public RoomMapViewModel RoomMapVM => _roomMapVM ??= new RoomMapViewModel();

        private FoodViewModel? _foodVM;
        public FoodViewModel FoodVM => _foodVM ??= new FoodViewModel();

        private EventViewModel? _eventVM;
        public EventViewModel EventVM => _eventVM ??= new EventViewModel();

        private VehicleViewModel? _vehicleVM;
        public VehicleViewModel VehicleVM => _vehicleVM ??= new VehicleViewModel();

        private ParkingViewModel? _parkingVM;
        public ParkingViewModel ParkingVM => _parkingVM ??= new ParkingViewModel();

        private LaundryViewModel? _laundryVM;
        public LaundryViewModel LaundryVM => _laundryVM ??= new LaundryViewModel();

        private StaffViewModel? _staffVM;
        public StaffViewModel StaffVM => _staffVM ??= new StaffViewModel();

        private StatisticsViewModel? _statisticsVM;
        public StatisticsViewModel StatisticsVM => _statisticsVM ??= new StatisticsViewModel();

        private CustomerViewModel? _customerVM;
        public CustomerViewModel CustomerVM => _customerVM ??= new CustomerViewModel();

        private InventoryViewModel? _inventoryVM;
        public InventoryViewModel InventoryVM => _inventoryVM ??= new InventoryViewModel();

        private ServicesConfigViewModel? _servicesConfigVM;
        public ServicesConfigViewModel ServicesConfigVM => _servicesConfigVM ??= new ServicesConfigViewModel(RefreshServiceVisibilities);

        private TransactionHistoryViewModel? _transactionsVM;
        public TransactionHistoryViewModel TransactionsVM => _transactionsVM ??= new TransactionHistoryViewModel();

        private string _currentTab = "RoomMap";
        public string CurrentTab
        {
            get => _currentTab;
            set => SetProperty(ref _currentTab, value);
        }

        public bool IsLoggedIn => Auth.IsLoggedIn;
        public bool IsAdmin => Auth.IsAdmin;
        public bool IsReceptionist => Auth.IsReceptionist;

        // Header role display: Chỉ hiện Admin hoặc Lễ Tân, không hiện họ tên
        public string CurrentUserRoleDisplay => Auth.IsAdmin ? "Admin" : "Lễ Tân";
        public string RoleBadgeBackground => Auth.IsAdmin ? "#D97706" : "#0D9488";
        public string AdminBadgeTooltip => "Nhấp chuột phải để Đăng xuất";
        public string CurrentDutyStaffDisplay => Data.GetScheduledDutyStaffName();

        // ------------------------------------------------------------------
        // Trạng thái workspace: chỉ hiện giao diện làm việc sau khi dữ liệu sẵn sàng.
        // ------------------------------------------------------------------
        private bool _isDataReady;
        public bool IsDataReady
        {
            get => _isDataReady;
            private set
            {
                if (SetProperty(ref _isDataReady, value))
                {
                    OnPropertyChanged(nameof(IsWorkspaceVisible));
                    OnPropertyChanged(nameof(IsWorkspaceLoading));
                }
            }
        }

        public bool IsWorkspaceVisible => IsLoggedIn && IsDataReady;
        public bool IsWorkspaceLoading => IsLoggedIn && !IsDataReady;

        // Tự động ẩn/hiển thị tab dịch vụ khi Bật/Tắt Active trong Cấu hình dịch vụ (Áp dụng cả Admin và Lễ tân)
        // Khi dữ liệu chưa nạp xong, trả về true để tránh đọc collection đang được ghi ở thread nền.
        public bool IsFoodServiceVisible => !Data.IsInitialized || (Data.ServicesConfig.FirstOrDefault(x => x.Code == "AN_UONG")?.IsActive ?? true);
        public bool IsEventServiceVisible => !Data.IsInitialized || (Data.ServicesConfig.FirstOrDefault(x => x.Code == "SU_KIEN")?.IsActive ?? true);
        public bool IsVehicleServiceVisible => !Data.IsInitialized || (Data.ServicesConfig.FirstOrDefault(x => x.Code == "THUE_XE")?.IsActive ?? true);
        public bool IsParkingServiceVisible => !Data.IsInitialized || (Data.ServicesConfig.FirstOrDefault(x => x.Code == "DO_XE")?.IsActive ?? true);
        public bool IsLaundryServiceVisible => !Data.IsInitialized || (Data.ServicesConfig.FirstOrDefault(x => x.Code == "GIAT_UI")?.IsActive ?? true);

        // Notifications
        public NotificationService NotificationService => NotificationService.Instance;

        public System.Collections.Generic.IEnumerable<AppNotification> FilteredNotifications
        {
            get
            {
                var list = IsAdmin 
                    ? NotificationService.Notifications 
                    : NotificationService.Notifications.Where(x => x.TargetRole != "Admin");
                return list.OrderBy(x => x.IsRead ? 1 : 0).ThenByDescending(x => x.Timestamp).ToList();
            }
        }

        public int UnreadNotificationCount => FilteredNotifications.Count(x => !x.IsRead);
        public bool HasUnreadNotifications => UnreadNotificationCount > 0;

        private bool _isNotificationPopupOpen;
        public bool IsNotificationPopupOpen
        {
            get => _isNotificationPopupOpen;
            set => SetProperty(ref _isNotificationPopupOpen, value);
        }

        // Commands
        public ICommand SelectTabCommand { get; }
        public ICommand LogoutCommand { get; }
        public ICommand SyncDatabaseCommand { get; }
        public ICommand OpenAccountManagementCommand { get; }
        public ICommand ToggleNotificationPopupCommand { get; }
        public ICommand MarkNotificationReadCommand { get; }
        public ICommand OpenNotificationTargetCommand { get; }

        public event Action? RequestLogout;
        public event Action<string, Action?>? RequestTabTransition;

        private bool _workspaceInitialized;

        public MainViewModel()
        {
            // Constructor này phải THẬT NHẸ.
            // Tuyệt đối không tạo ViewModel con, không đụng tới DataService.InitializeAsync,
            // không đăng ký timer ở đây — vì MainWindow tạo MainViewModel trước khi login hiển thị.

            SelectTabCommand = new RelayCommand(SelectTab);
            LogoutCommand = new RelayCommand(Logout);
            SyncDatabaseCommand = new RelayCommand(async () => await SyncDatabaseAsync());
            OpenAccountManagementCommand = new RelayCommand(OpenAccountManagement);
            OpenNotificationTargetCommand = new RelayCommand(OpenNotificationTarget);

            ToggleNotificationPopupCommand = new RelayCommand(_ =>
            {
                IsNotificationPopupOpen = !IsNotificationPopupOpen;
                if (IsNotificationPopupOpen)
                {
                    // Mở popup = đã xem: tự động đánh dấu đã đọc và tắt badge đỏ
                    NotificationService.MarkAllAsRead(IsAdmin);
                    OnPropertyChanged(nameof(FilteredNotifications));
                    OnPropertyChanged(nameof(UnreadNotificationCount));
                    OnPropertyChanged(nameof(HasUnreadNotifications));
                }
            });

            MarkNotificationReadCommand = new RelayCommand(p =>
            {
                if (p is AppNotification notif)
                {
                    notif.IsRead = true;
                    OnPropertyChanged(nameof(FilteredNotifications));
                    OnPropertyChanged(nameof(UnreadNotificationCount));
                    OnPropertyChanged(nameof(HasUnreadNotifications));
                }
            });

            Auth.AuthStateChanged += OnAuthStateChanged;
        }

        /// <summary>
        /// Gọi MỘT LẦN sau khi DataService.InitializeAsync() hoàn tất và trước khi hiện workspace.
        /// Đăng ký các sự kiện cần dữ liệu thật, bật timer cảnh báo và đánh dấu dữ liệu sẵn sàng.
        /// </summary>
        public void InitializeWorkspace()
        {
            if (_workspaceInitialized) return;
            _workspaceInitialized = true;

            NotificationService.Notifications.CollectionChanged += OnNotificationsChanged;
            Data.ServicesConfig.CollectionChanged += OnServicesConfigChanged;
            HotelServiceConfig.OnActiveChanged += OnServiceConfigActiveChanged;

            RefreshServiceVisibilities();
            NotificationService.StartMonitoring();

            IsDataReady = true;

            OnPropertyChanged(nameof(CurrentDutyStaffDisplay));
            OnPropertyChanged(nameof(FilteredNotifications));
            OnPropertyChanged(nameof(UnreadNotificationCount));
            OnPropertyChanged(nameof(HasUnreadNotifications));
        }

        private void OnNotificationsChanged(object? sender, NotifyCollectionChangedEventArgs e)
        {
            // Đang mở popup thì thông báo mới cũng coi như đã xem, badge không nhảy số
            if (IsNotificationPopupOpen && e.NewItems != null)
            {
                foreach (AppNotification notif in e.NewItems)
                {
                    if (IsAdmin || notif.TargetRole != "Admin")
                    {
                        notif.IsRead = true;
                    }
                }
            }

            OnPropertyChanged(nameof(FilteredNotifications));
            OnPropertyChanged(nameof(UnreadNotificationCount));
            OnPropertyChanged(nameof(HasUnreadNotifications));
        }

        private void OnServicesConfigChanged(object? sender, NotifyCollectionChangedEventArgs e)
        {
            RefreshServiceVisibilities();
        }

        private void OnServiceConfigActiveChanged(HotelServiceConfig config)
        {
            RefreshServiceVisibilities();
        }

        public void OpenAccountManagement(object? parameter = null)
        {
            if (IsAdmin)
            {
                var win = new AccountManagementWindow();
                win.ShowDialog();
            }
            else
            {
                MessageBox.Show("Chức năng quản lý tài khoản chỉ dành riêng cho Quản trị viên (Admin)!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
        }

        public void RefreshServiceVisibilities()
        {
            OnPropertyChanged(nameof(IsFoodServiceVisible));
            OnPropertyChanged(nameof(IsEventServiceVisible));
            OnPropertyChanged(nameof(IsVehicleServiceVisible));
            OnPropertyChanged(nameof(IsParkingServiceVisible));
            OnPropertyChanged(nameof(IsLaundryServiceVisible));

            // Nếu tab hiện tại vừa bị tắt (inactive), tự động chuyển về Sơ đồ phòng
            if ((CurrentTab == "Food" && !IsFoodServiceVisible) ||
                (CurrentTab == "Event" && !IsEventServiceVisible) ||
                (CurrentTab == "Vehicle" && !IsVehicleServiceVisible) ||
                (CurrentTab == "Parking" && !IsParkingServiceVisible) ||
                (CurrentTab == "Laundry" && !IsLaundryServiceVisible))
            {
                CurrentTab = "RoomMap";
            }
        }

        private void SelectTab(object? parameter)
        {
            if (parameter is string tabName)
            {
                // Kiểm tra phân quyền: Lễ tân không được vào các tab Admin
                if (!IsAdmin && (tabName == "Statistics" || tabName == "Staff" || tabName == "Customers" || tabName == "Inventory" || tabName == "ServicesConfig"))
                {
                    MessageBox.Show("Mục này chỉ dành riêng cho quyền Quản trị viên (Admin)!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                    return;
                }

                if (_currentTab == tabName)
                {
                    // Bấm lại tab Kho Hàng: luôn quay về màn danh sách kho mặc định.
                    if (tabName == "Inventory")
                    {
                        InventoryVM.ShowDefaultView();
                        InventoryVM.RefreshAll();
                    }
                    return;
                }

                Action refreshAction = () => RefreshTabData(tabName);

                if (RequestTabTransition != null)
                {
                    RequestTabTransition.Invoke(tabName, refreshAction);
                }
                else
                {
                    CurrentTab = tabName;
                    refreshAction();
                }
            }
        }

        public void RefreshTabData(string tabName)
        {
            switch (tabName)
            {
                case "RoomMap":
                    RoomMapVM.ApplyFilter();
                    RoomMapVM.LoadServicesForSelectedRoom();
                    RoomMapVM.NotifyAllStateChanges();
                    break;
                case "Customers":
                    CustomerVM.ApplyFilter();
                    break;
                case "Inventory":
                    InventoryVM.RefreshAll();
                    InventoryVM.ShowDefaultView();
                    break;
                case "Food":
                    FoodVM.ApplyFoodFilter();
                    break;
                case "Statistics":
                    StatisticsVM.RefreshStatistics();
                    break;
                case "Vehicle":
                    VehicleVM.ApplyVehicleFilter();
                    break;
                case "Transactions":
                    TransactionsVM.Refresh();
                    break;
            }
        }

        private bool _isBusy;
        public bool IsBusy
        {
            get => _isBusy;
            set => SetProperty(ref _isBusy, value);
        }

        private async System.Threading.Tasks.Task SyncDatabaseAsync()
        {
            if (IsBusy) return;

            IsBusy = true;
            try
            {
                await Data.SyncDataToDatabaseAsync();

                // Chỉ refresh những tab đã được mở. Dùng backing field để không
                // vô tình khởi tạo ViewModel của các tab chưa ai mở.
                if (_roomMapVM != null)
                {
                    _roomMapVM.ApplyFilter();
                    _roomMapVM.LoadServicesForSelectedRoom();
                    _roomMapVM.NotifyAllStateChanges();
                }
                if (_foodVM != null) _foodVM.ApplyFoodFilter();
                if (_eventVM != null) _eventVM.BuildHourlySchedule();
                if (_vehicleVM != null) _vehicleVM.ApplyVehicleFilter();
                if (_customerVM != null) _customerVM.ApplyFilter();
                if (_inventoryVM != null) _inventoryVM.RefreshAll();
                if (_statisticsVM != null) _statisticsVM.RefreshStatistics();
                if (_transactionsVM != null) _transactionsVM.Refresh();

                RefreshServiceVisibilities();
            }
            finally
            {
                System.Windows.Input.Mouse.OverrideCursor = null;
                IsBusy = false;
            }
        }

        public void RefreshAuthState()
        {
            OnAuthStateChanged();
        }

        private void OnAuthStateChanged()
        {
            OnPropertyChanged(nameof(IsLoggedIn));
            OnPropertyChanged(nameof(IsAdmin));
            OnPropertyChanged(nameof(IsReceptionist));
            OnPropertyChanged(nameof(CurrentUserRoleDisplay));
            OnPropertyChanged(nameof(RoleBadgeBackground));
            OnPropertyChanged(nameof(AdminBadgeTooltip));
            OnPropertyChanged(nameof(CurrentDutyStaffDisplay));
            OnPropertyChanged(nameof(IsWorkspaceVisible));
            OnPropertyChanged(nameof(IsWorkspaceLoading));

            RefreshServiceVisibilities();
            SetDefaultTab();

            // Dùng backing field: nếu dùng getter StatisticsVM sẽ tạo VM thống kê
            // ngay lúc đăng nhập, làm mất tác dụng của lazy tab.
            if (_statisticsVM != null)
            {
                _statisticsVM.RefreshStatistics();
            }
        }

        private void SetDefaultTab()
        {
            CurrentTab = "RoomMap";
        }

        private void Logout(object? parameter)
        {
            Auth.Logout();
            RequestLogout?.Invoke();
        }

        /// <summary>
        /// Xử lý nhấp đúp vào thông báo: tự động đóng popup, đánh dấu đã đọc và chuyển thẳng tới dòng đơn trong bảng lịch sử của tab dịch vụ đó
        /// </summary>
        private void OpenNotificationTarget(object? param)
        {
            if (param is not AppNotification notif) return;

            // 1. Đánh dấu đã đọc và đóng popup thông báo
            notif.IsRead = true;
            IsNotificationPopupOpen = false;
            OnPropertyChanged(nameof(FilteredNotifications));
            OnPropertyChanged(nameof(UnreadNotificationCount));
            OnPropertyChanged(nameof(HasUnreadNotifications));

            // Nếu không phải thông báo liên quan đến quyết toán (ví dụ: đăng nhập, nhập kho, thông báo chung), chỉ đánh dấu đã đọc
            if (!notif.IsSettlementRelated)
            {
                return;
            }

            string? room = notif.GetResolvedRoomNumber();
            string? orderCode = notif.GetResolvedOrderCode();

            // 2. Chuyển thẳng sang TAB DỊCH VỤ tương ứng (danh sách lịch sử) để trỏ vào đơn cần xử lý
            switch (notif.Type)
            {
                case NotificationType.LaundryReturn:
                    SelectTab("Laundry");
                    LaundryVM.SelectOrderByCode(orderCode, room);
                    break;

                case NotificationType.VehicleReturn:
                    SelectTab("Vehicle");
                    VehicleVM.SelectRentalByCode(orderCode, room);
                    break;

                case NotificationType.EventEnding:
                    SelectTab("Event");
                    EventVM.SelectBookingByCode(orderCode, room);
                    break;

                case NotificationType.RoomCheckout:
                    SelectTab("RoomMap");
                    if (!string.IsNullOrWhiteSpace(room))
                    {
                        RoomMapVM.NavigateToRoomAndService(room, orderCode, "Tiền phòng");
                    }
                    break;

                case NotificationType.Transaction:
                    SelectTab("Transactions");
                    break;

                case NotificationType.Inventory:
                    if (IsAdmin) SelectTab("Inventory");
                    break;

                default:
                    // Phân loại thông minh theo mã đơn hoặc danh mục dịch vụ
                    if (!string.IsNullOrWhiteSpace(orderCode))
                    {
                        if (orderCode.StartsWith("DH-GU", StringComparison.OrdinalIgnoreCase))
                        {
                            SelectTab("Laundry");
                            LaundryVM.SelectOrderByCode(orderCode, room);
                        }
                        else if (orderCode.StartsWith("TX", StringComparison.OrdinalIgnoreCase))
                        {
                            SelectTab("Vehicle");
                            VehicleVM.SelectRentalByCode(orderCode, room);
                        }
                        else if (orderCode.StartsWith("SK", StringComparison.OrdinalIgnoreCase))
                        {
                            SelectTab("Event");
                            EventVM.SelectBookingByCode(orderCode, room);
                        }
                        else
                        {
                            SelectTab("RoomMap");
                            if (!string.IsNullOrWhiteSpace(room)) RoomMapVM.NavigateToRoomAndService(room, orderCode, notif.ServiceCategory);
                        }
                    }
                    else if (!string.IsNullOrWhiteSpace(notif.ServiceCategory))
                    {
                        if (notif.ServiceCategory.IndexOf("giặt", StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            SelectTab("Laundry");
                            LaundryVM.SelectOrderByCode(null, room);
                        }
                        else if (notif.ServiceCategory.IndexOf("xe", StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            SelectTab("Vehicle");
                            VehicleVM.SelectRentalByCode(null, room);
                        }
                        else if (notif.ServiceCategory.IndexOf("kiện", StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            SelectTab("Event");
                            EventVM.SelectBookingByCode(null, room);
                        }
                        else
                        {
                            SelectTab("RoomMap");
                            if (!string.IsNullOrWhiteSpace(room)) RoomMapVM.NavigateToRoomAndService(room, null, notif.ServiceCategory);
                        }
                    }
                    else if (!string.IsNullOrWhiteSpace(room))
                    {
                        SelectTab("RoomMap");
                        RoomMapVM.NavigateToRoomAndService(room, orderCode, notif.ServiceCategory);
                    }
                    break;
            }
        }
    }
}
