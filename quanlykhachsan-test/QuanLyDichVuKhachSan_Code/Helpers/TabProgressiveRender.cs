using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Threading;

namespace QuanLyDichVuKhachSan.Helpers
{
    /// <summary>
    /// Cơ chế hiển thị 2 pha (Two-Stage Progressive Rendering) cho các Tab & Sub-Tab:
    /// - Pha 1 (0ms tức thì khi nhấn Tab): Hiển thị ngay lập tức Tiêu đề, Header, Thẻ KPI, Thanh công cụ lọc và Khung đề mục (Card Frames).
    ///   Các vùng dữ liệu nặng (IsDataRegion="True") được ẩn tạm thời để không chặn luồng vẽ khung giao diện đầu tiên.
    /// - Pha 2 (Ngay sau khi khung tiêu đề đã xuất hiện trên màn hình - DispatcherPriority.Background):
    ///   Đổ dữ liệu lên giao diện kèm hiệu ứng trượt & hiện mượt mà (130ms CubicEase Out).
    /// </summary>
    public static class TabProgressiveRender
    {
        private static readonly List<WeakReference<FrameworkElement>> _registeredRegions = new();
        private static int _currentTransitionId = 0;

        public static readonly DependencyProperty IsDataRegionProperty =
            DependencyProperty.RegisterAttached(
                "IsDataRegion",
                typeof(bool),
                typeof(TabProgressiveRender),
                new PropertyMetadata(false, OnIsDataRegionChanged));

        public static bool GetIsDataRegion(DependencyObject obj) => (bool)obj.GetValue(IsDataRegionProperty);
        public static void SetIsDataRegion(DependencyObject obj, bool value) => obj.SetValue(IsDataRegionProperty, value);

        private static readonly DependencyProperty IsWarmProperty =
            DependencyProperty.RegisterAttached(
                "IsWarm",
                typeof(bool),
                typeof(TabProgressiveRender),
                new PropertyMetadata(false));

        public static bool GetIsWarm(DependencyObject obj) => (bool)obj.GetValue(IsWarmProperty);
        public static void SetIsWarm(DependencyObject obj, bool value) => obj.SetValue(IsWarmProperty, value);

        private static void OnIsDataRegionChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if (d is FrameworkElement el && e.NewValue is true)
            {
                lock (_registeredRegions)
                {
                    _registeredRegions.Add(new WeakReference<FrameworkElement>(el));
                }

                // Khởi tạo RenderTransform sẵn để phục vụ animation bằng GPU
                if (el.RenderTransform is not TranslateTransform)
                {
                    el.RenderTransform = new TranslateTransform(0, 0);
                }

                // Mặc định ẩn vùng dữ liệu nặng lúc khởi tạo (Cold State) để phần Khung Tiêu Đề & Đề Mục
                // của toàn bộ các Tab được đo đạc trước siêu nhẹ (< 2ms), sẵn sàng hiển thị tức thì (0ms) khi nhấn Tab!
                if (!System.ComponentModel.DesignerProperties.GetIsInDesignMode(el))
                {
                    el.Visibility = Visibility.Collapsed;
                    el.Opacity = 0;
                }
            }
        }

        private static List<FrameworkElement> GetRegionsForContainer(DependencyObject container)
        {
            var result = new List<FrameworkElement>();
            lock (_registeredRegions)
            {
                for (int i = _registeredRegions.Count - 1; i >= 0; i--)
                {
                    if (!_registeredRegions[i].TryGetTarget(out var el))
                    {
                        _registeredRegions.RemoveAt(i);
                        continue;
                    }

                    if (IsDescendantOf(el, container))
                    {
                        result.Add(el);
                    }
                }
            }
            return result;
        }

        private static bool IsDescendantOf(DependencyObject child, DependencyObject ancestor)
        {
            DependencyObject? current = child;
            while (current != null)
            {
                if (ReferenceEquals(current, ancestor))
                    return true;

                DependencyObject? next = null;
                if (current is FrameworkElement fe && fe.Parent != null)
                {
                    next = fe.Parent;
                }
                else
                {
                    next = LogicalTreeHelper.GetParent(current);
                    if (next == null && current is Visual)
                    {
                        next = VisualTreeHelper.GetParent(current);
                    }
                }
                current = next;
            }
            return false;
        }

        /// <summary>
        /// PHA 1 (0ms): Ẩn tạm vùng dữ liệu nặng để WPF vẽ ngay lập tức Tiêu đề, Header và các Đề mục lên màn hình.
        /// </summary>
        public static List<FrameworkElement> PrepareStage1(FrameworkElement targetView)
        {
            var regions = GetRegionsForContainer(targetView);
            foreach (var region in regions)
            {
                region.BeginAnimation(UIElement.OpacityProperty, null);
                region.Opacity = 0;

                // Nếu vùng dữ liệu chưa từng được nạp (Cold Start), đặt Collapsed trong Pha 1
                // để WPF bỏ qua hoàn toàn việc tính toán hàng trăm dòng dữ liệu ở khung hình đầu tiên -> Hiện tiêu đề trong < 1ms!
                if (!GetIsWarm(region))
                {
                    region.Visibility = Visibility.Collapsed;
                }
            }
            return regions;
        }

        /// <summary>
        /// PHA 2 (Chạy ngay sau khi Tiêu đề & Đề mục đã hiển thị trên màn hình):
        /// Nạp/làm mới dữ liệu và kích hoạt hiệu ứng đổ dữ liệu mượt mà lên giao diện.
        /// </summary>
        public static void ScheduleStage2(FrameworkElement targetView, List<FrameworkElement> regions, Action? dataRefreshAction)
        {
            int transitionId = ++_currentTransitionId;

            // DispatcherPriority.Background (mức 4) luôn chạy NGAY SAU DispatcherPriority.Render (mức 7)
            // Đảm bảo màn hình đã hiển thị xong phần Tiêu đề & Đề mục trước khi đổ dữ liệu!
            targetView.Dispatcher.BeginInvoke(DispatcherPriority.Background, new Action(() =>
            {
                if (transitionId != _currentTransitionId)
                    return; // Người dùng đã bấm nhanh sang tab khác -> hủy ngay lập tức để không gây trễ

                // 1. Bật hiển thị vùng dữ liệu nếu là lần đầu mở tab
                foreach (var region in regions)
                {
                    if (region.Visibility != Visibility.Visible)
                    {
                        region.Visibility = Visibility.Visible;
                    }
                    SetIsWarm(region, true);
                }

                // 2. Cập nhật dữ liệu thông minh (chỉ cập nhật khi có sự thay đổi)
                dataRefreshAction?.Invoke();

                // 3. Chạy hiệu ứng đổ dữ liệu mượt mà (Fade-in + Slide-up nhẹ 130ms)
                var ease = new CubicEase { EasingMode = EasingMode.EaseOut };
                var duration = new Duration(TimeSpan.FromMilliseconds(130));

                var opacityAnim = new DoubleAnimation(0.0, 1.0, duration) { EasingFunction = ease };
                var slideAnim = new DoubleAnimation(7.0, 0.0, duration) { EasingFunction = ease };
                opacityAnim.Freeze();
                slideAnim.Freeze();

                foreach (var region in regions)
                {
                    if (region.RenderTransform is not TranslateTransform trans || trans.IsFrozen)
                    {
                        trans = new TranslateTransform(0, 7);
                        region.RenderTransform = trans;
                    }

                    region.BeginAnimation(UIElement.OpacityProperty, opacityAnim);
                    trans.BeginAnimation(TranslateTransform.YProperty, slideAnim);
                }
            }));
        }
    }
}
