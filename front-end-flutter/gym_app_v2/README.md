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

3. **Cấu hình môi trường (.env):**
  Tạo file `.env` (copy từ `.env.example` nếu có) trong thư mục `gym_app_v2/`:
   
  ```bash
  cp .env.example .env
  ```
  Bên trong khai báo:
  ```properties
  API_BASE_URL=http://localhost:3000
  # Android Emulator có thể dùng: http://10.0.2.2:3000
  # Production ví dụ: https://api.your-domain.com
   
  # Thời gian giữa các lần tự refresh token (giây)
  REFRESH_INTERVAL_SECONDS=600
  ```
  Ứng dụng sẽ tự load `.env` ở `main.dart` và dùng `API_BASE_URL` thông qua `ApiConstants.baseUrl`.
  - Nếu thiếu hoặc không load được `.env` sẽ fallback `http://localhost:3000`.
  - Có thể đổi nhanh interval khi test (ví dụ 30s) bằng cách sửa `REFRESH_INTERVAL_SECONDS`.
   
  File cũ `api_constants.dart` giờ chỉ còn getter động, KHÔNG sửa tay trực tiếp để tránh lệch môi trường giữa dev / staging / prod.

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

## 🧮 Công thức tính % hoàn thành buổi tập

Hệ thống tính ra ba chỉ số chính để phản ánh mức độ hoàn thành buổi tập: `volumePercent`, `setsPercent` và `hybridPercent`.

### 1. Định nghĩa
- `targetLoad (T)`: Tổng tải mục tiêu của toàn bộ buổi tập.
  - Với mỗi bài tập: `perSetTarget = targetReps * (targetWeight > 0 ? targetWeight : repValue)`
  - `exerciseTargetLoad = perSetTarget * setsPlanned`
  - `T = Σ exerciseTargetLoad`
- `achievedLoad (Σ L_i)`: Tổng tải đạt được thực tế từ các set đã log.
  - Với mỗi set log:
    - `intensity = clamp( usedWeight / targetWeight, 0, maxIntensityMultiplier )` (nếu có targetWeight > 0, ngược lại = 1)
    - `load = doneReps * (usedWeight > 0 ? usedWeight : repValue) * intensity`
    - Cộng dồn vào `achievedLoad`.
- `totalSetsPlanned`: Tổng số set dự kiến (Σ sets của từng bài).
- `totalSetsDone`: Số set đã log thực tế.
- `setsPercent = (totalSetsDone / totalSetsPlanned) * 100` (0 nếu không có set kế hoạch).
- `volumePercent = (achievedLoad / targetLoad) * 100` (nếu `allowOver100 = false` thì clamp tối đa 100).
- `hybridPercent = hybridAlpha * volumePercent + (1 - hybridAlpha) * setsPercent`.

### 2. Tham số cấu hình (`WorkoutCompletionCalculatorParams`)
| Tham số | Ý nghĩa | Giá trị mặc định |
|--------|---------|------------------|
| `repValue` | Giá trị thay thế khi bài tập không có `targetWeight` (ví dụ bodyweight) | `1.0` |
| `allowOver100` | Cho phép `volumePercent` vượt 100% nếu tập nhiều hơn mục tiêu | `false` |
| `maxIntensityMultiplier` | Giới hạn hệ số cường độ khi nâng nặng hơn target | `1.2` |
| `hybridAlpha` | Trọng số pha trộn giữa volume và sets trong `hybridPercent` | `0.8` |

### 3. Pseudo code tóm tắt
```dart
for each exercise in plannedExercises:
  perSetTarget = targetReps * (targetWeight > 0 ? targetWeight : repValue)
  exerciseTargetLoad = perSetTarget * setsPlanned
  totalTargetLoad += exerciseTargetLoad
  totalSetsPlanned += setsPlanned

  for each loggedSet:
    totalSetsDone++
    intensity = targetWeight > 0 ? usedWeight / targetWeight : 1
    intensity = intensity.clamp(0, maxIntensityMultiplier)
    load = doneReps * (usedWeight > 0 ? usedWeight : repValue) * intensity
    totalAchievedLoad += load

volumePercent = (totalAchievedLoad / totalTargetLoad) * 100
if !allowOver100: volumePercent = min(volumePercent, 100)
setsPercent = (totalSetsDone / totalSetsPlanned) * 100
hybridPercent = hybridAlpha * volumePercent + (1 - hybridAlpha) * setsPercent
```

### 4. Ví dụ minh họa
Giả sử buổi tập có 1 bài:
| Chỉ số | Giá trị |
|--------|---------|
| targetWeight | 50 kg |
| targetReps | 10 |
| setsPlanned | 3 |
| perSetTarget | 10 * 50 = 500 |
| targetLoad | 500 * 3 = 1500 |

Log thực tế 3 set: (10 reps @50), (10 reps @52), (8 reps @55)
- Set 1: intensity = 50/50 = 1 → load = 10 * 50 * 1 = 500
- Set 2: intensity = 52/50 = 1.04 → load ≈ 10 * 52 * 1.04 = 540.8
- Set 3: intensity = 55/50 = 1.1 → load = 8 * 55 * 1.1 = 484
→ AchievedLoad ≈ 1524.8

`volumePercent = 1524.8 / 1500 * 100 ≈ 101.65%` → clamp thành `100%` (nếu `allowOver100=false`).
`setsPercent = 3/3 * 100 = 100%`.
Với `hybridAlpha=0.8`:
`hybridPercent = 0.8 * 100 + 0.2 * 100 = 100%`.

### 5. Ghi chú mở rộng
- Có thể bật `allowOver100` để phản ánh nỗ lực vượt mục tiêu.
- `repValue` có thể map theo bodyweight hoặc ước lượng caloric load trong tương lai.
- Khi thêm bài tập bodyweight (không có trọng lượng), hệ thống dùng `repValue` thay thế.
- `hybridAlpha` cao → ưu tiên khối lượng nâng (volume), thấp → cân bằng đều với số set hoàn thành.

Phần tính toán nằm ở file `lib/utils/workout_completion.dart`.

## 🛠️ Công nghệ và Architecture

### Frontend Stack:
- **Framework**: Flutter 3.x
- **Language**: Dart 3.0+
- **UI**: Material Design 3
- **Local Storage**: SharedPreferences
- **HTTP Client**: dart:http

### Backend Integration:
- **API**: RESTful API với Node.js/Express
- **Authentication**: JWT Token
- **Data Format**: JSON


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
### Code Standards:
- Tất cả widget class bắt đầu bằng chữ hoa
- Method private bắt đầu với `_`
- Comment đầy đủ cho business logic phức tạp
- Sử dụng const constructor khi có thể

### Performance Tips:
- Sử dụng `const` widgets để tránh rebuild không cần thiết

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
- **Email**: annguyen140701@gmail.com
- **GitHub**: [@annguyen1407](https://github.com/annguyen1407)
- **Project Repository**: [DATN-GymForge](https://github.com/annguyen1407/DATN-GymForge)

---

> 💡 **Tip**: Đọc kỹ comments trong code để hiểu sâu hơn về logic và implementation details. Mọi component đều được document chi tiết!

🏋️‍♂️ **Happy Coding & Happy Training!** 💪
