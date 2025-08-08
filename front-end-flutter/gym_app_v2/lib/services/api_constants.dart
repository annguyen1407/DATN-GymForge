/// Định nghĩa các hằng số liên quan đến API, ví dụ baseUrl
class ApiConstants {
  /// Đổi giá trị này khi deploy backend lên server thật
  ///
  // Khi chạy trên IOS Simulator, sử dụng địa chỉ này để kết nối với backend trên máy tính
  static const String baseUrl = 'http://localhost:3000';

  // Khi chạy trên Android Emulator, sử dụng địa chỉ này để kết nối với backend trên máy tính
  //static const String baseUrl = 'http://10.0.2.2:3000';
}
