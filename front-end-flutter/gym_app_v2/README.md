# 🏋️ GymForge - Ứng dụng quản lý tập luyện thể hình

GymForge là một ứng dụng mobile được phát triển bằng Flutter, giúp người dùng theo dõi và quản lý quá trình tập luyện thể hình một cách hiệu quả và chuyên nghiệp.

## 📱 Tính năng chính

### 🏠 Dashboard (Home)
- Tổng quan tiến độ tập luyện
- Thống kê nhanh và động lực hàng ngày
- Hiển thị thông tin người dùng

### 💪 Quản lý bài tập (Workout)
- Danh sách các routine tập luyện
- Tạo và chỉnh sửa bài tập tùy chỉnh
- Khởi động session tập luyện trực tiếp

### 🎯 Session tập luyện thông minh (Workout Session)
- **Timer đa chế độ**: 
  - Đếm xuôi khi tập luyện (màu đỏ)
  - Đếm ngược khi nghỉ ngơi trong chế độ auto (màu cam)
- **Quản lý hiệp chi tiết**:
  - Theo dõi từng hiệp với thông tin đầy đủ
  - Hiển thị số hiệp hiện tại/tổng số hiệp
- **Chỉnh sửa linh hoạt**:
  - Thay đổi số reps trong quá trình tập (khi pause)
  - Điều chỉnh thời gian với nút ±10s
- **Chế độ tập luyện**:
  - **Auto mode**: Tự động chuyển hiệp sau thời gian nghỉ
  - **Manual mode**: Người dùng điều khiển hoàn toàn
- **Lưu trữ dữ liệu**: Ghi lại chi tiết mỗi hiệp:
  - Thời gian tập luyện
  - Số reps thực tế
  - Trọng lượng sử dụng
  - Timestamp

### 📚 Thư viện bài tập (Exercise)
- Danh sách bài tập phong phú với hướng dẫn
- Phân loại theo nhóm cơ
- Tìm kiếm và lọc bài tập

### 📊 Nhật ký tập luyện (Log)
- Lịch sử tập luyện chi tiết
- Thống kê tiến độ theo thời gian
- Phân tích hiệu suất

### 👤 Hồ sơ cá nhân (Profile)
- Quản lý thông tin người dùng
- Cài đặt ứng dụng
- Thống kê tổng quan

## 🚀 Cài đặt và chạy dự án

### Yêu cầu hệ thống
- Flutter SDK >= 3.8.1
- Dart SDK >= 3.0.0
- Android Studio hoặc VS Code với Flutter extension
- iOS Simulator (cho iOS) hoặc Android Emulator
- Backend API đang chạy (xem thư mục backend)

### Cài đặt
1. **Clone repository:**
```bash
git clone https://github.com/annguyen1407/DATN-GymForge.git
cd DATN-GymForge/front-end-flutter/gym_app_v2
```

2. **Cài đặt dependencies:**
```bash
flutter pub get
```

3. **Cấu hình API endpoint:**
   
   Chỉnh sửa file `lib/services/api_constants.dart`:
   ```dart
   class ApiConstants {
     // iOS Simulator - kết nối localhost
     static const String baseUrl = 'http://localhost:3000';
     
     // Android Emulator - sử dụng IP đặc biệt
     // static const String baseUrl = 'http://10.0.2.2:3000';
     
     // Production - domain thật khi deploy
     // static const String baseUrl = 'https://your-api-domain.com';
   }
   ```

4. **Chạy ứng dụng:**
```bash
flutter run
```

## 🏗️ Cấu trúc dự án

```
lib/
├── main.dart                    # Entry point, routing, authentication flow
├── screens/                     # Các màn hình chính
│   ├── auth/                   # Đăng nhập, đăng ký, onboarding
│   ├── main_screen.dart        # Container chính với bottom navigation
│   ├── home/                   # Dashboard và trang chủ
│   ├── workout/                # Quản lý bài tập và workout session
│   │   ├── workout_screen.dart
│   │   └── workout_session_screen.dart
│   ├── exercise/               # Thư viện bài tập
│   ├── log/                    # Nhật ký và lịch sử tập luyện
│   └── user/                   # Hồ sơ và cài đặt người dùng
├── widgets/                    # Components tái sử dụng
│   ├── custom_bottom_nav_bar.dart
│   ├── exercise_card.dart
│   └── ...
├── services/                   # API và business logic
│   ├── api_service.dart        # HTTP requests
│   ├── api_constants.dart      # API endpoints
│   └── user_service.dart       # User management
├── models/                     # Data models
│   └── user_model.dart
└── utils/                      # Utilities và constants
```

## 🎮 Hướng dẫn sử dụng Workout Session

### Quy trình tập luyện:

1. **Khởi động session:**
   - Chọn bài tập từ danh sách Workout
   - Bấm "Khởi động bài tập"
   - Giao diện hiển thị timer `0:00` và trạng thái "Sẵn sàng"

2. **Bắt đầu tập luyện:**
   - Bấm nút ▶️ để bắt đầu hiệp đầu tiên
   - Timer chuyển màu đỏ và bắt đầu đếm xuôi
   - Trạng thái hiển thị "Hiệp 1/X"

3. **Trong quá trình tập:**
   - **Timer màu đỏ**: Đang tập luyện (đếm xuôi thời gian)
   - **Pause ⏸️**: Tạm dừng để nghỉ hoặc chỉnh sửa
   - **Chỉnh sửa reps**: Khi pause, tap vào "Số rép" để thay đổi

4. **Hoàn thành hiệp:**
   - Bấm "Log set X" để lưu hiệp và chuyển sang hiệp tiếp theo
   - Hệ thống tự động chuyển sang thời gian nghỉ

5. **Thời gian nghỉ:**
   - **Manual mode**: Hiển thị "Nghỉ ngơi - Bấm Play để tiếp tục"
   - **Auto mode**: Timer màu cam đếm ngược, tự động chuyển hiệp

### Điều khiển nâng cao:

- **⏪ Replay (-10s)**: Giảm 10 giây thời gian đã tập
- **⏮️ Previous**: Chuyển về bài tập trước
- **⏸️/▶️ Play/Pause**: Tạm dừng/Tiếp tục
- **⏭️ Next**: Chuyển sang bài tập tiếp theo
- **🔄 Auto**: Toggle chế độ tự động (background xanh khi bật)

### Hoàn thành session:
- Sau khi tập xong tất cả bài tập, popup hiển thị thống kê chi tiết
- Bấm "Lưu và hoàn thành" để lưu dữ liệu và quay về màn hình chính

## 🛠️ Công nghệ và Architecture

### Frontend Stack:
- **Framework**: Flutter 3.x
- **Language**: Dart 3.0+
- **UI**: Material Design 3
- **State Management**: StatefulWidget + setState
- **Local Storage**: SharedPreferences
- **HTTP Client**: dart:http

### Backend Integration:
- **API**: RESTful API với Node.js/Express
- **Authentication**: JWT Token
- **Data Format**: JSON

### Key Features Implementation:
- **Smart Timer System**: Sử dụng `Timer.periodic` cho độ chính xác cao
- **Real-time Data**: Lưu trữ chi tiết từng hiệp trong `Map<int, List<Map>>`
- **Flexible UI**: Dynamic state management cho workout session
- **Persistent Storage**: Auto-save workout data với timestamp

## 📊 Luồng dữ liệu chính

### Authentication Flow:
```
App Start → Check Token → Valid? → Get Profile → Main Screen
                      ↓ Invalid
                   Welcome Screen → Login/Register → Main Screen
```

### Workout Session Flow:
```
Select Workout → Start Session → For each Exercise:
  └─ For each Set:
      └─ Start Timer → Pause (optional) → Log Set → Rest
  └─ Next Exercise or Complete → Save Data → Return Home
```

### Data Structure Example:
```dart
// Workout session data
Map<int, List<Map<String, dynamic>>> workoutData = {
  0: [ // First exercise
    {
      'set': 1,
      'reps': 12,
      'time': 45, // seconds
      'weight': 20, // kg
      'timestamp': DateTime.now(),
    },
    // ... more sets
  ],
  // ... more exercises
};
```

## 🔧 Hướng dẫn maintain và mở rộng

### Thêm tính năng mới:
1. **Màn hình mới**: Tạo file trong `screens/`, cập nhật routing nếu cần
2. **API endpoint**: Thêm method trong `api_service.dart`
3. **Data model**: Tạo model trong `models/` với `fromJson/toJson`
4. **Reusable widget**: Đặt trong `widgets/` để tái sử dụng

### Code Standards:
- Tất cả widget class bắt đầu bằng chữ hoa
- Method private bắt đầu với `_`
- Comment đầy đủ cho business logic phức tạp
- Sử dụng const constructor khi có thể

### Performance Tips:
- Sử dụng `const` widgets để tránh rebuild không cần thiết
- Dispose controllers và timers trong `dispose()`
- Kiểm tra `mounted` trước khi `setState()`

## 🐛 Debug và Troubleshooting

### Lỗi thường gặp:

1. **API Connection Error:**
   - Kiểm tra backend có đang chạy không
   - Verify baseUrl trong `api_constants.dart`
   - Check network connectivity

2. **Timer Issues:**
   - Ensure timer is cancelled in `dispose()`
   - Check `mounted` before `setState()`

3. **Authentication Problems:**
   - Clear SharedPreferences: `flutter clean`
   - Check token expiration
   - Verify API endpoints

### Debug Commands:
```bash
# Clean build
flutter clean && flutter pub get

# Run with debug info
flutter run --debug --verbose

# Check dependencies
flutter doctor
```

## 📋 Roadmap và tính năng sắp tới

- [ ] **Advanced Analytics**: Biểu đồ tiến độ chi tiết
- [ ] **Social Features**: Chia sẻ workout với bạn bè
- [ ] **Custom Exercises**: Tạo bài tập tùy chỉnh với hình ảnh
- [ ] **Workout Templates**: Thư viện template có sẵn
- [ ] **Push Notifications**: Nhắc nhở tập luyện
- [ ] **Offline Mode**: Hoạt động không cần internet


## 🤝 Đóng góp

Chúng tôi hoan nghênh mọi đóng góp! Để contribute:

1. Fork repository
2. Tạo feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Tạo Pull Request

### Guidelines:
- Follow existing code style
- Add comments for complex logic
- Test trên cả iOS và Android
- Update documentation nếu cần

## 📄 License

Dự án này được phát triển cho mục đích học tập và nghiên cứu trong khuôn khổ đồ án tốt nghiệp.

## 📞 Liên hệ và hỗ trợ

- **Developer**: Nguyễn Thành An
- **Email**: annguyen1407@gmail.com
- **GitHub**: [@annguyen1407](https://github.com/annguyen1407)
- **Project Repository**: [DATN-GymForge](https://github.com/annguyen1407/DATN-GymForge)

---

> 💡 **Tip**: Đọc kỹ comments trong code để hiểu sâu hơn về logic và implementation details. Mọi component đều được document chi tiết!

🏋️‍♂️ **Happy Coding & Happy Training!** 💪