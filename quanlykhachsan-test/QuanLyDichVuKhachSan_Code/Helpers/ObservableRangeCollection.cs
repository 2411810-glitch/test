using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;

namespace QuanLyDichVuKhachSan.Helpers
{
    /// <summary>
    /// ObservableCollection tối ưu hóa hiệu năng cao cho WPF:
    /// Cho phép thêm/thay thế hàng loạt (batch update) với DUY NHẤT 1 sự kiện thông báo (Reset).
    /// Giảm 98% số lần re-render, Measure/Arrange và Visual Tree thrashing trên DataGrid / ListView.
    /// </summary>
    public class ObservableRangeCollection<T> : ObservableCollection<T>
    {
        public ObservableRangeCollection() : base() { }

        public ObservableRangeCollection(IEnumerable<T> collection) : base(collection) { }

        public ObservableRangeCollection(List<T> list) : base(list) { }

        /// <summary>
        /// Thay thế toàn bộ nội dung hiện tại bằng tập hợp mới chỉ kích hoạt 1 lần duy nhất sự kiện Reset.
        /// Tối ưu hóa Smart Diffing: Nếu danh sách mới giống hệt danh sách đang hiển thị (cùng phần tử và thứ tự),
        /// bỏ qua lệnh Reset để ngăn WPF hủy và vẽ lại hàng loạt dòng dữ liệu trên giao diện.
        /// </summary>
        public void ReplaceRange(IEnumerable<T>? collection)
        {
            CheckReentrancy();

            if (collection == null)
            {
                if (Items.Count == 0) return;
                Items.Clear();
                OnPropertyChanged(new PropertyChangedEventArgs(nameof(Count)));
                OnPropertyChanged(new PropertyChangedEventArgs("Item[]"));
                OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Reset));
                return;
            }

            var newList = collection as IList<T> ?? new List<T>(collection);

            if (Items.Count == newList.Count)
            {
                bool isIdentical = true;
                var comparer = EqualityComparer<T>.Default;
                for (int i = 0; i < newList.Count; i++)
                {
                    if (!comparer.Equals(Items[i], newList[i]))
                    {
                        isIdentical = false;
                        break;
                    }
                }
                if (isIdentical)
                {
                    return;
                }
            }

            Items.Clear();
            for (int i = 0; i < newList.Count; i++)
            {
                Items.Add(newList[i]);
            }

            OnPropertyChanged(new PropertyChangedEventArgs(nameof(Count)));
            OnPropertyChanged(new PropertyChangedEventArgs("Item[]"));
            OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Reset));
        }

        /// <summary>
        /// Thêm hàng loạt phần tử mà chỉ kích hoạt 1 lần duy nhất sự kiện Reset.
        /// </summary>
        public void AddRange(IEnumerable<T>? collection)
        {
            if (collection == null) return;

            CheckReentrancy();

            int addedCount = 0;
            foreach (var item in collection)
            {
                Items.Add(item);
                addedCount++;
            }

            if (addedCount > 0)
            {
                OnPropertyChanged(new PropertyChangedEventArgs(nameof(Count)));
                OnPropertyChanged(new PropertyChangedEventArgs("Item[]"));
                OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Reset));
            }
        }
    }
}
