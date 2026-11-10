using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Input;
using QuanLyDichVuKhachSan.Helpers;
using QuanLyDichVuKhachSan.Services;
using QuanLyDichVuKhachSan.ViewModels;
using QuanLyDichVuKhachSan.Views;

namespace QuanLyDichVuKhachSan
{
    public partial class MainWindow : Window
    {
        public MainViewModel ViewModel { get; }
        public LoginViewModel LoginVM { get; }

        // Cache view theo tên tab: mỗi tab chỉ được tạo một lần,
        // các lần chuyển tab sau dùng lại instance cũ (giữ nguyên trạng thái).
        private readonly Dictionary<string, FrameworkElement> _viewCache = new();

        private bool _isFullScreen = false;
        private WindowStyle _savedWindowStyle = WindowStyle.SingleBorderWindow;
        private WindowState _savedWindowState = WindowState.Maximized;
        private ResizeMode _savedResizeMode = ResizeMode.CanResize;

        public MainWindow()
        {
            InitializeComponent();

            // MainViewModel lúc này rất nhẹ: chưa tạo ViewModel con, chưa nạp CSDL.
            ViewModel = new MainViewModel();
            LoginVM = new LoginViewModel();

            DataContext = ViewModel;
            LoginControl.DataContext = LoginVM;

            // Khởi tạo ở kích thước nhỏ gọn cho màn hình đăng nhập
            ApplyLoginWindowSize();

            // Nạp dữ liệu nền bất đồng bộ ngay khi mở ứng dụng (giúp mở app nhanh hơn).
            // Lúc này chưa có View/ViewModel con nào bind vào collection của DataService,
            // nên việc nạp trên background thread là an toàn.
            _ = DataService.Instance.InitializeAsync();

            LoginVM.LoginSucceeded += OnLoginSucceeded;
            ViewModel.RequestTabTransition += ShowTab;

            ViewModel.RequestLogout += () =>
            {
                if (_isFullScreen)
                {
                    ExitFullScreen();
                }
                ApplyLoginWindowSize();
            };
        }

        private async void OnLoginSucceeded()
        {
            ApplyWorkWindowSize();

            bool initialized;
            try
            {
                initialized = await DataService.Instance.InitializeAsync();
            }
            catch (Exception ex)
            {
                HandleInitializationFailure(ex.Message);
                return;
            }

            if (!initialized)
            {
                HandleInitializationFailure(DataService.Instance.InitializationError ?? "Không rõ nguyên nhân.");
                return;
            }

            // Chỉ sau khi dữ liệu sẵn sàng mới đăng ký sự kiện, bật timer cảnh báo
            // và cho phép workspace hiển thị.
            ViewModel.InitializeWorkspace();
            ViewModel.RefreshAuthState();

            // Tab đầu tiên cũng được tạo muộn, sau khi dữ liệu đã nạp xong.
            ShowTab("RoomMap", () => ViewModel.RefreshTabData("RoomMap"));
        }

        private void HandleInitializationFailure(string message)
        {
            DataService.Instance.ResetInitialization();

            // Đưa người dùng về màn hình đăng nhập để có thể thử lại,
            // tránh bị kẹt ở màn hình "Đang tải dữ liệu..." không có nút bấm.
            AuthService.Instance.Logout();
            ApplyLoginWindowSize();

            MessageBox.Show(
                $"Không thể tải dữ liệu từ CSDL.\n\nChi tiết: {message}\n\nVui lòng kiểm tra kết nối SQL Server rồi đăng nhập lại.",
                "Lỗi dữ liệu",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }

        /// <summary>
        /// Hiển thị tab theo cơ chế lazy + progressive render:
        /// - Lần đầu mở tab: tạo view và ViewModel tương ứng (chỉ tab đó).
        /// - Các lần sau: dùng lại view đã cache nên chuyển tab tức thì.
        /// - Luôn chạy 2 pha: hiện header/khung trước, nạp vùng dữ liệu nặng sau.
        /// </summary>
        private void ShowTab(string tabName, Action? deferredRefresh = null)
        {
            if (string.IsNullOrWhiteSpace(tabName)) return;

            if (!_viewCache.TryGetValue(tabName, out var view))
            {
                view = CreateView(tabName);
                _viewCache[tabName] = view;
            }

            // Đưa view vào host trước để mọi vùng dữ liệu nằm trong cây trực quan,
            // sau đó mới chuẩn bị Pha 1 (layout/render thực sự diễn ra sau khi hàm này kết thúc).
            TabContentHost.Content = view;

            // PHA 1 (0ms): ẩn tạm vùng dữ liệu nặng để khung tiêu đề hiện ngay.
            var regions = TabProgressiveRender.PrepareStage1(view);
            ViewModel.CurrentTab = tabName;

            // PHA 2: đổ dữ liệu + hiệu ứng sau khi header đã render xong.
            TabProgressiveRender.ScheduleStage2(view, regions, deferredRefresh);
        }

        private FrameworkElement CreateView(string tabName)
        {
            return tabName switch
            {
                "RoomMap" => new RoomMapView { DataContext = ViewModel.RoomMapVM },
                "Statistics" => new StatisticsView { DataContext = ViewModel.StatisticsVM },
                "Staff" => new StaffManagementView { DataContext = ViewModel.StaffVM },
                "Customers" => new CustomerListView { DataContext = ViewModel.CustomerVM },
                "Inventory" => new InventoryManagementView { DataContext = ViewModel.InventoryVM },
                "ServicesConfig" => new ServicesConfigView { DataContext = ViewModel.ServicesConfigVM },
                "Food" => new FoodServiceView { DataContext = ViewModel.FoodVM },
                "Event" => new EventServiceView { DataContext = ViewModel.EventVM },
                "Vehicle" => new VehicleServiceView { DataContext = ViewModel.VehicleVM },
                "Parking" => new ParkingServiceView { DataContext = ViewModel.ParkingVM },
                "Laundry" => new LaundryServiceView { DataContext = ViewModel.LaundryVM },
                "Transactions" => new TransactionHistoryView { DataContext = ViewModel.TransactionsVM },
                _ => throw new ArgumentOutOfRangeException(nameof(tabName), tabName, "Tab không hợp lệ.")
            };
        }

        private void MainWindow_PreviewKeyDown(object sender, KeyEventArgs e)
        {
            // Bắt tổ hợp phím Alt + Enter hoặc F11 để chuyển đổi toàn màn hình
            bool isAlt = (Keyboard.Modifiers & ModifierKeys.Alt) == ModifierKeys.Alt;
            bool isEnter = e.Key == Key.Return || e.Key == Key.Enter || e.SystemKey == Key.Return || e.SystemKey == Key.Enter;

            if ((isAlt && isEnter) || e.Key == Key.F11)
            {
                ToggleFullScreen();
                e.Handled = true;
                return;
            }

            // Nhấn ESC để thoát toàn màn hình về dạng cửa sổ
            if (e.Key == Key.Escape && _isFullScreen)
            {
                ExitFullScreen();
                e.Handled = true;
                return;
            }
        }

        private void BtnFullScreen_Click(object sender, RoutedEventArgs e)
        {
            ToggleFullScreen();
        }

        public void ToggleFullScreen()
        {
            if (ViewModel == null || !ViewModel.IsLoggedIn)
            {
                return;
            }

            if (!_isFullScreen)
            {
                EnterFullScreen();
            }
            else
            {
                ExitFullScreen();
            }
        }

        private void EnterFullScreen()
        {
            _savedWindowStyle = this.WindowStyle;
            _savedWindowState = this.WindowState;
            _savedResizeMode = this.ResizeMode;

            this.WindowState = WindowState.Normal;
            this.WindowStyle = WindowStyle.None;
            this.ResizeMode = ResizeMode.NoResize;
            this.WindowState = WindowState.Maximized;

            _isFullScreen = true;
            UpdateFullScreenButtonState();
        }

        private void ExitFullScreen()
        {
            this.WindowState = WindowState.Normal;
            this.WindowStyle = _savedWindowStyle;
            this.ResizeMode = _savedResizeMode;
            this.WindowState = _savedWindowState;

            _isFullScreen = false;
            UpdateFullScreenButtonState();
        }

        private void UpdateFullScreenButtonState()
        {
            if (BtnFullScreen != null)
            {
                BtnFullScreen.Content = _isFullScreen ? "🗗 Cửa Sổ" : "⛶ Toàn Màn Hình";
                BtnFullScreen.ToolTip = _isFullScreen
                    ? "Quay về chế độ cửa sổ có thanh tiêu đề (Alt + Enter hoặc F11)"
                    : "Chuyển sang chế độ toàn màn hình không có thanh tiêu đề (Alt + Enter hoặc F11)";
            }
        }

        private void ApplyLoginWindowSize()
        {
            this.WindowStyle = WindowStyle.SingleBorderWindow;
            this.WindowState = WindowState.Normal;
            this.ResizeMode = ResizeMode.CanMinimize;
            this.MinWidth = 460;
            this.MinHeight = 460;
            this.Width = 480;
            this.Height = 480;
            CenterWindowOnScreen();
        }

        private void ApplyWorkWindowSize()
        {
            this.MinWidth = 1100;
            this.MinHeight = 700;
            this.ResizeMode = ResizeMode.CanResize;
            this.WindowState = WindowState.Maximized;
            _isFullScreen = false;
            UpdateFullScreenButtonState();
        }

        private void CenterWindowOnScreen()
        {
            double screenWidth = SystemParameters.PrimaryScreenWidth;
            double screenHeight = SystemParameters.PrimaryScreenHeight;
            this.Left = (screenWidth - this.Width) / 2;
            this.Top = (screenHeight - this.Height) / 2;
        }
    }
}
