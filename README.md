# GymForge

GymForge là ứng dụng di động hỗ trợ người tập gym quản lý quá trình tập luyện, theo dõi tiến độ, ghi nhận dinh dưỡng và kết nối với huấn luyện viên cá nhân. Dự án được xây dựng trong khuôn khổ đồ án tốt nghiệp với mục tiêu tạo một hệ thống thực tế cho ba nhóm người dùng chính: Gymer, Coach và Admin.

Ứng dụng tập trung vào việc cá nhân hóa kế hoạch tập luyện, hỗ trợ người dùng ghi log từng buổi tập, tính toán tiến độ, quản lý lịch hẹn với huấn luyện viên và cung cấp nền tảng backend đủ rõ ràng để mở rộng thêm các nghiệp vụ phòng gym.

## Góc nhìn business

GymForge được thiết kế không chỉ như một ứng dụng ghi chép tập luyện, mà là một nền tảng kết nối giữa người tập gym và huấn luyện viên cá nhân. Bài toán kinh doanh chính của dự án nằm ở việc giảm rào cản khi người mới bắt đầu tập gym muốn tiếp cận kiến thức, giáo án và PT phù hợp, đồng thời tạo thêm kênh vận hành số cho huấn luyện viên.

### Vấn đề thị trường

- Người mới tập thường khó chọn bài tập, thiết bị và giáo án phù hợp với thể trạng.
- Việc theo dõi tiến độ thủ công dễ thiếu nhất quán, khó đánh giá hiệu quả dài hạn.
- Chi phí thuê PT trực tiếp tại phòng tập có thể cao, thiếu linh hoạt về lịch và địa điểm.
- Huấn luyện viên cá nhân khó quản lý nhiều học viên nếu chỉ dùng chat, giấy ghi chú hoặc bảng tính.
- Các ứng dụng tập luyện phổ biến thường mạnh về thư viện bài tập nhưng chưa tập trung đủ vào kết nối Gymer - Coach trong một quy trình hoàn chỉnh.

### Giá trị mang lại

- Với Gymer: có thể tìm plan, tập theo hướng dẫn, ghi log, theo dõi tiến độ, quản lý dinh dưỡng và kết nối với Coach khi cần hỗ trợ chuyên sâu.
- Với Coach: có kênh nhận học viên, quản lý yêu cầu huấn luyện, tạo plan riêng, đặt lịch và theo dõi tiến độ học viên.
- Với Admin hoặc đơn vị vận hành: có thể quản lý dữ liệu người dùng, bài tập, plan mẫu, gói premium và các nghiệp vụ nền tảng.

### Mô hình doanh thu tiềm năng

- Gói Premium cho người tập để mở khóa plan nâng cao, thống kê chuyên sâu hoặc tính năng cá nhân hóa.
- Phí kết nối hoặc hoa hồng từ các yêu cầu huấn luyện giữa Gymer và Coach.
- Gói tài khoản Coach với các công cụ quản lý học viên nâng cao.
- Bán hoặc phân phối workout plan mẫu theo mục tiêu: giảm mỡ, tăng cơ, sức mạnh, phục hồi, beginner.
- Hợp tác với phòng gym để triển khai nội bộ cho hội viên và huấn luyện viên.

### Lợi thế sản phẩm

- Kết hợp tập luyện, log dữ liệu, dinh dưỡng, lịch hẹn và coach marketplace trong cùng một ứng dụng.
- Dữ liệu tập luyện được cấu trúc hóa, giúp hệ thống có nền tảng để gợi ý plan và cá nhân hóa về sau.
- Backend phân quyền rõ theo vai trò, phù hợp để mở rộng thành hệ thống vận hành thực tế.
- Có thể phát triển tiếp các tính năng thương mại như subscription, thanh toán, coach ranking và báo cáo hiệu quả huấn luyện.

## Mục tiêu dự án

- Hỗ trợ người tập lập và thực hiện kế hoạch tập luyện theo mục tiêu cá nhân.
- Cung cấp thư viện bài tập, nhóm cơ, thiết bị và video/hướng dẫn luyện tập.
- Theo dõi tiến độ tập luyện qua log theo ngày, tuần, tháng và từng kế hoạch.
- Ghi nhận chỉ số cơ thể, lượng calo, dinh dưỡng và lịch sử tập luyện.
- Cho phép Gymer tìm kiếm huấn luyện viên, gửi yêu cầu huấn luyện, đặt lịch và đánh giá Coach.
- Cho phép Coach quản lý học viên, lịch hẹn và kế hoạch tập luyện cho học viên.
- Cho phép Admin quản lý người dùng, bài tập, nhóm cơ, thiết bị, plan mẫu và các cấu hình hệ thống.

## Tính năng chính

### Người dùng chung

- Đăng ký, đăng nhập, xác thực JWT và refresh token.
- Đăng nhập bằng Google OAuth.
- Quản lý hồ sơ cá nhân, ảnh đại diện, thông tin liên lạc và chỉ số cơ thể.
- Xem trang chủ với nhắc nhở tập luyện, chuỗi tập luyện và thống kê nhanh.
- Xem thư viện bài tập, tìm kiếm bài tập và xem thông tin chi tiết.

### Gymer

- Tạo, chỉnh sửa, xóa và sử dụng kế hoạch tập luyện cá nhân.
- Khám phá plan mẫu miễn phí hoặc premium.
- Bắt đầu buổi tập, log từng set, chỉnh reps/tạ/thời gian và lưu kết quả.
- Theo dõi tiến độ kế hoạch, lịch sử tập luyện và thống kê chuyên sâu.
- Ghi nhận dinh dưỡng theo ngày, lượng calo nạp vào và calo tiêu hao.
- Tìm kiếm huấn luyện viên, gửi yêu cầu huấn luyện và đặt lịch tập.
- Đánh giá huấn luyện viên sau quá trình tập luyện.

### Coach

- Quản lý hồ sơ huấn luyện viên và trạng thái nhận học viên.
- Xem danh sách học viên.
- Tạo kế hoạch tập luyện cho học viên.
- Xử lý yêu cầu huấn luyện: chấp nhận, từ chối hoặc hủy.
- Quản lý lịch hẹn với học viên.
- Theo dõi một phần dữ liệu tập luyện của học viên theo quyền được cấp.

### Admin

- Quản lý tài khoản người dùng và phân quyền.
- Quản lý coach, gymer, bài tập, nhóm cơ và thiết bị.
- Quản lý workout plan mẫu, gói subscription và cấu hình hệ thống.
- Duyệt hoặc cập nhật một số trạng thái nghiệp vụ như coach, salary/payment tùy module.

## Công thức và xử lý dữ liệu tập luyện

GymForge sử dụng các công thức trong đồ án để lượng hóa quá trình tập luyện:

- Tính năng lượng tiêu hao dựa trên MET, cân nặng, số rep, thời gian trung bình mỗi rep và cường độ bài tập.
- Điều chỉnh MET theo mức tạ thực tế, 1RM hoặc tỷ lệ tải trọng so với cân nặng.
- Tính phần trăm hoàn thành buổi tập bằng công thức hybrid, kết hợp:
  - phần trăm volume thực tế so với volume mục tiêu;
  - phần trăm số set đã hoàn thành.

Phần tính toán phía Flutter nằm tại:

```text
front-end-flutter/gym_app_v2/lib/utils/workout_completion.dart
front-end-flutter/gym_app_v2/lib/utils/calorie_formula.dart
```

## Kiến trúc tổng quan

```text
Flutter Mobile App
        |
        | REST API / JSON / JWT
        v
NestJS Backend
        |
        | Prisma ORM
        v
PostgreSQL Database

Redis: cache/session/token support
SMTP: email notification
Firebase Storage: media/image storage
```

Backend được thiết kế theo hướng stateless, dùng JWT cho xác thực và RolesGuard cho phân quyền. Flutter app giao tiếp với backend qua REST API, lưu token an toàn bằng `flutter_secure_storage` và dùng `.env` để cấu hình API base URL.

## Công nghệ sử dụng

### Frontend

- Flutter / Dart
- Material UI
- `http` cho REST API
- `flutter_secure_storage` và `shared_preferences`
- `flutter_dotenv`
- Firebase Core / Firebase Storage
- `image_picker`, `cached_network_image`, `youtube_player_flutter`
- `fl_chart`, `table_calendar`, `percent_indicator`

### Backend

- Node.js
- NestJS
- TypeScript
- Prisma ORM
- PostgreSQL
- Redis
- JWT, Passport, Google OAuth
- Nodemailer + Handlebars email template
- Swagger/OpenAPI
- Jest, Supertest

## Cấu trúc thư mục

```text
.
├── backend/                         # NestJS API server
│   ├── prisma/                      # Prisma schema, migrations, seed scripts
│   ├── src/                         # Source backend modules
│   ├── test/                        # E2E tests
│   ├── .env.example                 # Mẫu cấu hình backend
│   └── package.json
├── front-end-flutter/
│   └── gym_app_v2/                  # Flutter mobile app
│       ├── lib/                     # Source Flutter
│       ├── assets/                  # Images, icons, gifs, sounds
│       ├── .env.example             # Mẫu cấu hình frontend
│       └── pubspec.yaml
└── README.md                        # Tài liệu tổng quan dự án
```

## Yêu cầu môi trường

- Node.js 18 trở lên
- npm
- PostgreSQL
- Redis
- Flutter SDK tương thích Dart SDK `^3.8.1`
- Android Studio hoặc Xcode nếu chạy mobile emulator/simulator

## Cài đặt backend

```bash
cd backend
npm install
cp .env.example .env
```

Cập nhật các biến trong `backend/.env`, tối thiểu:

```env
DATABASE_URL="postgresql://username:password@localhost:5432/gymforge_db"
JWT_ACCESS_SECRET="replace-with-access-token-secret"
JWT_REFRESH_SECRET="replace-with-refresh-token-secret"
JWT_EXPIRES_IN="15m"
REDIS_HOST="localhost"
REDIS_PORT=6379
PORT=3000
CORS_ORIGIN="http://localhost:3000"
FRONTEND_URL="http://localhost:3000"
```

Khởi tạo Prisma và database:

```bash
npx prisma generate
npx prisma migrate dev
```

Chạy backend ở môi trường development:

```bash
npm run start:dev
```

Swagger API sau khi backend chạy:

```text
http://localhost:3000/api
```

## Cài đặt Flutter app

```bash
cd front-end-flutter/gym_app_v2
flutter pub get
cp .env.example .env
```

Cập nhật `front-end-flutter/gym_app_v2/.env`:

```env
API_BASE_URL=http://localhost:3000
REFRESH_INTERVAL_SECONDS=600
```

Nếu chạy Android Emulator, API backend trên máy host thường dùng:

```env
API_BASE_URL=http://10.0.2.2:3000
```

Chạy ứng dụng:

```bash
flutter run
```

## Kiểm thử

Backend:

```bash
cd backend
npm run test
npm run test:e2e
npm run test:cov
```

Flutter:

```bash
cd front-end-flutter/gym_app_v2
flutter test
flutter analyze
```

## Bảo mật và cấu hình

- Không commit file `.env`, database dump, keystore, private key hoặc file build binary.
- Dùng `.env.example` làm mẫu cấu hình cho môi trường local.
- JWT access token và refresh token cần dùng secret đủ mạnh khi triển khai thật.
- Khuyến nghị triển khai backend sau reverse proxy có TLS.
- Cần backup database định kỳ nếu vận hành thực tế.

## Trạng thái triển khai

Các phần chính đã có trong codebase:

- Flutter mobile app.
- Backend NestJS theo module.
- Xác thực JWT, Google OAuth và phân quyền role.
- Quản lý workout plan, exercise, muscle group, equipment.
- Training request, appointment, feedback, subscription.
- Exercise log, meal log và thống kê tập luyện.
- Email service qua SMTP.
- Prisma schema/migration và test backend.

Một số hướng mở rộng hoặc phần chưa hoàn chỉnh hoàn toàn:

- Chat realtime giữa Gymer và Coach.
- Push notification qua Firebase Cloud Messaging.
- CI/CD, health check và monitoring production.
- Performance/load test trên môi trường staging PostgreSQL.

## Tài liệu liên quan

- Backend: `backend/README.md`
- Flutter app: `front-end-flutter/gym_app_v2/README.md`
- Auth token flow: `front-end-flutter/gym_app_v2/AUTH_TOKEN_FLOW.md`
- Coding standards: `front-end-flutter/gym_app_v2/CODING_STANDARDS.md`
- Design system: `front-end-flutter/gym_app_v2/DESIGN_SYSTEM.md`

## Nhóm thực hiện

- Nguyễn Thành An - 1912532
- Khương Hoàng Nguyên - 2114218

Đồ án tốt nghiệp ngành Khoa học Máy tính, Khoa Khoa học và Kỹ thuật Máy tính, Trường Đại học Bách Khoa - ĐHQG TP.HCM.
