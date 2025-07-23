
# Gym App v2 (Flutter)

Ứng dụng quản lý phòng gym, tập luyện, huấn luyện viên, lịch sử, cá nhân hóa, xây dựng bằng Flutter.

## 1. Cài đặt & Chạy ứng dụng

### Yêu cầu
- Flutter SDK >= 3.8.1
- Dart >= 3.0
- Thiết bị iOS hoặc trình giả lập simulator
- Đã cài backend API (xem thư mục backend)

### Cài đặt
```bash
cd front-end-flutter/gym_app_v2
flutter pub get
```


### Chạy app
```bash
flutter run
```

### Cấu hình địa chỉ backend (baseUrl)

Để thay đổi địa chỉ backend (khi deploy lên server thật), sửa giá trị trong file:

```
lib/services/api_constants.dart
```

Ví dụ:
```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:3000'; // đổi thành domain backend thật khi deploy
}
```

## 2. Cấu trúc thư mục chính

```
lib/
  main.dart                // Entry point, điều hướng, kiểm tra onboarding/token/profile
  models/                  // Định nghĩa model dữ liệu (UserModel...)
  services/                // Giao tiếp API, xử lý logic lấy dữ liệu
  screens/                 // Các màn hình chính (Home, Workout, Exercise, Log, User...)
  widgets/                 // Widget tái sử dụng (BottomNav, Card, Tab, ...)
  utils/, constants/       // Tiện ích, hằng số
```

## 3. Luồng dữ liệu & giải thích code

- **main.dart**: 
  - Khởi động app, kiểm tra đã xem onboarding chưa, có token chưa, nếu có thì gọi API lấy profile user.
  - Điều hướng đến màn hình phù hợp: Onboarding, Welcome, MainScreen...

- **services/api_service.dart**: 
  - Chỉ xử lý logic gọi API (login, signup, getProfile), không liên quan UI.
  - Sử dụng http, trả về Map hoặc null.

- **services/user_service.dart**:
  - Lấy access_token từ SharedPreferences, gọi API lấy profile, trả về UserModel.

- **models/user_model.dart**:
  - Định nghĩa UserModel, có fromJson để parse từ API.

- **screens/main_screen.dart**:
  - Quản lý 5 tab chính (Home, Workout, Exercise, Log, User), truyền user cho các tab cần thiết.
  - Sử dụng CustomBottomNavBar để chuyển tab.

- **widgets/**:
  - Chứa các widget tái sử dụng: CustomBottomNavBar, CategoryIcon, ExerciseGroupCard, SectionHeader, ...

- **Luồng đăng nhập/đăng ký**:
  - Người dùng nhập thông tin, gọi ApiService.login/signup, lưu token vào SharedPreferences, chuyển sang MainScreen.

- **Luồng lấy profile**:
  - Khi vào app, lấy token, gọi ApiService.getProfile, parse về UserModel, truyền cho các màn hình.

## 4. Hướng dẫn maintain & mở rộng

- **Thêm màn hình mới**: Tạo file trong screens/, thêm route vào main.dart nếu cần.
- **Thêm API mới**: Thêm hàm vào api_service.dart, nếu cần model thì tạo ở models/.
- **Tái sử dụng widget**: Đặt widget vào widgets/, import vào các màn hình cần dùng.
- **Quản lý state**: Hiện tại dùng StatefulWidget và SharedPreferences, có thể tích hợp Provider/BLoC nếu app lớn hơn.
- **Comment**: Tất cả code đã có comment chi tiết, chỉ cần đọc là hiểu logic.

## 5. Một số lưu ý
- Đảm bảo backend chạy đúng port, sửa baseUrl trong api_service.dart nếu cần.
- Ảnh, asset để trong assets/, nhớ khai báo trong pubspec.yaml.
- Nếu gặp lỗi API, kiểm tra token, backend, hoặc log debug.

## 6. Liên hệ & đóng góp
- Nếu có bug hoặc muốn đóng góp, hãy tạo pull request hoặc liên hệ chủ repo.

---

> File này dành cho dev mới, giải thích chi tiết luồng code, cấu trúc, và hướng dẫn maintain/mở rộng. Đọc kỹ comment trong từng file để hiểu sâu hơn.
