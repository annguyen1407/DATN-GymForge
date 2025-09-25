# GymForge Flutter App – Kiến trúc (Phiên bản rút gọn v2)

_Mục tiêu đồ án tốt nghiệp – tập trung phần cốt lõi, lược bỏ chi tiết thừa (kiểm thử sâu, state management nâng cao, CI)._  
Tài liệu đồng bộ với: `DESIGN_SYSTEM.md` (UI & tokens), `CODING_STANDARDS.md` (quy ước code), `BACKEND_SCHEMA_REFERENCE.md` (mô hình dữ liệu backend tổng quan cho FE).

---
## 1. High-Level Overview

| Layer | Thư mục | Nhiệm vụ chính |
|-------|---------|----------------|
| Entry / Routing | `main.dart` | Khởi động app, xác định màn hình ban đầu |
| Core Infra | `lib/core` | API client, token manager, logging, extensions |
| Domain Models | `lib/models` | Model thuần (parse JSON -> object) |
| Data Access (Repositories) | `lib/repositories` | Gọi API, map JSON -> model, log |
| Services / Use-cases | `lib/services` | Logic nhiều bước / build payload / kết hợp repo |
| UI Screens | `lib/screens` | Màn hình theo feature |
| Reusable Widgets | `lib/widgets` | Thành phần UI tái sử dụng |
| Theming / Tokens | `lib/theme` | `DesignTokens` (màu, spacing, radius, typography) |
| Utils | `lib/utils` | Helper thuần (date, workout completion) |

Luồng: UI → Service (nếu cần logic hợp nhất) / Repository → ApiClient → Backend → Kết quả trả về model → UI.  
Chi tiết cấu trúc dữ liệu backend: xem `BACKEND_SCHEMA_REFERENCE.md`.

---
## 2. Boot Sequence & Navigation
1. `main()` → `MyApp`.
2. `_initApp()` trong `MyAppState`:
   - Kiểm tra `seenOnboarding` (SharedPreferences).
   - Lấy access token (nếu có) + profile (legacy `ApiService.getProfile`).
   - Chạy refresh token nếu sắp hết hạn.
   - Chọn screen đầu (`Onboarding` / `Welcome` / `WelcomeProfileSetupScreen` / `MainScreen`).
3. `MainScreen` fetch profile (hiện có cơ chế refresh định kỳ sẽ hợp nhất sau).
4. Navigation: dùng `MaterialApp.routes` + `Navigator.push...` (routing thủ công).  

> Ghi chú: Chưa áp dụng router phức tạp (GoRouter…) do phạm vi đồ án.

---
## 3. Authentication & Token Lifecycle
| Thành phần | Vai trò |
|------------|--------|
| SharedPreferences | Lưu `access_token` |
| SecureStorage | Lưu `refresh_token` |
| `TokenManager` | Decode exp JWT, single-flight refresh, `getValidAccessToken()` |
| `ApiClient` | Thêm `Authorization`, retry 401 một lần |
| `ApiService` | Legacy endpoints (login/signup/verify/password reset) |

Tình trạng hiện tại: Hai cơ chế refresh (timer cũ + TokenManager).  
Hướng cải tiến: Loại bỏ timer, chỉ để TokenManager chủ động refresh khi sắp hết hạn.

### 3.1 Luồng Refresh Chuẩn (Sequence)
1. UI chuẩn bị gọi API → `TokenManager.getValidAccessToken()`.
2. Nếu access token sắp hết hạn (< threshold) → POST `/auth/refresh`.
3. Thành công → cập nhật token, thực thi lại request gốc một lần.
4. Thất bại (refresh lỗi/expired) → xoá cả access + refresh, điều hướng về màn đăng nhập.

### 3.2 Bản đồ Endpoint Auth
| Hành động FE | Endpoint | Ghi chú |
|--------------|----------|--------|
| Đăng ký | POST /auth/register | Trả OTP qua email |
| Xác thực email | POST /auth/verify-email | Cần email + mã OTP |
| Đăng nhập | POST /auth/login | Nhận access + refresh |
| Refresh | POST /auth/refresh | Gửi refresh token (header/body tuỳ implement) |
| Quên mật khẩu | POST /auth/forgot-password | OTP reset riêng |
| Đặt lại mật khẩu | POST /auth/reset-password | OTP + mật khẩu mới |
| Resend verify | POST /auth/resend-verification | Giới hạn tần suất (future) |
| Google OAuth | GET /auth/google | Flow web / CustomTab | 

---
## 4. API Layer & Error Handling
`ApiClient.requestJson()` trả về `ApiResponse` có:
- `status`, `raw`, `error`, `message`.
Helper chuyển đổi: `asModel(T.fromJson)`, `asModelList`.

Quy tắc thêm endpoint:
1. Thêm phương thức trong Repository.
2. Gọi `ApiClient.requestJson`.
3. Parse qua `Model.fromJson`.
4. Lỗi → trả `null` / danh sách rỗng + log (UI quyết định hiển thị).

---
## 5. Repositories vs Services
| Loại | Khi nào |
|------|--------|
| Repository | Gần CRUD / REST thuần, ánh xạ dữ liệu |
| Service | Nhiều bước, build payload, tính toán, kết hợp nhiều repo |

Ví dụ: `WorkoutPlansRepository.getPlans()` vs `ExerciseLogsService.buildPayloads()`.

---
## 6. Models
- Mỗi model: `factory ...fromJson(Map<String,dynamic>)`.
- Giữ thuần dữ liệu (không gọi network / service bên trong).
- Không nhúng logic tính toán phức tạp (đặt ở service / util).

Ví dụ: `ExerciseModel`, `MuscleGroupModel`, `WorkoutPlanModel`.

UI-only model tạm thời (ví dụ `ExerciseItem`) nếu dùng rộng nên tách `models/ui/` (cải tiến tiềm năng).

---
## 7. Logging
- Dùng `AppLogger.debug/info/warn/error`.
- Chuẩn format: `[timestamp][LEVEL][TAG] message`.
- Loại bỏ dần `debugPrint` còn sót trong repo.

---
## 8. Theming & Design System
- `DesignTokens` quản lý màu, spacing, radius, durations, typography, opacity.
- Design System chi tiết: xem `DESIGN_SYSTEM.md`.
- Không hard-code màu mới → dùng token gần nhất hoặc thêm token (nếu xuất hiện ≥ 3 lần).
- Extension opacity: `withOpacityRatio`, `mulAlpha` (tránh deprecated pattern).

---
## 9. Workout Completion Logic
File: `utils/workout_completion.dart`
- Tính `volumePercent`, `setsPercent`, `hybridPercent`.
- `hybridPercent = alpha * volume + (1 - alpha) * sets` (alpha mặc định 0.8).
- Tham số linh hoạt: `repValue`, `allowOver100`, `maxIntensityMultiplier`.

### 9.1 Liên kết Backend
Backend hiện không trả trực tiếp Hybrid Percent → FE tự tính. Nếu backend sau này thêm field tương đương cần đồng bộ để không double-calc.

---
## 10. Exercise Logs Flow
`ExerciseLogsService`:
- Chuẩn hóa payload gửi `/exercise-logs`.
- Bỏ set rỗng (reps = 0 & time = 0).
- Tính `progressPercent` (format 1 chữ số thập phân).

Khi backend thêm field:
1. Bổ sung vào payload models.
2. Thêm trong `toBackendMinimalJson()`.
3. Giữ backward compatibility.

### 10.1 Chuỗi Thao Tác (Sequence)
| Bước | FE | Backend | Kết quả |
|------|----|---------|---------|
| 1 | Người dùng nhập sets | – | – |
| 2 | Service lọc sets rỗng | – | Payload sạch |
| 3 | POST /exercise-logs | Persist + tính metric phụ | Trả log + progress |
| 4 | UI cập nhật list/dash | – | Hiển thị mới |
| 5 | Gọi stats (daily/weekly) | Aggregate | Dashboard số liệu |

### 10.2 Mapping Trường Chính
| FE Field | Backend Field | Ghi chú |
|----------|---------------|--------|
| exerciseId | exerciseId | Bắt buộc |
| weight | weight | Có thể null |
| reps/time | reps/time | Loại 0/0 trước gửi |
| intensity | intensity | Dùng tính calories quick |


---
## 11. Screen & Widget Patterns
- Screen: Scaffold + SafeArea (nếu cần) + nội dung cuộn.
- Fetch data trong `initState` hoặc action (không trong `build`).
- Widget tái sử dụng: đưa vào `widgets/` (button, card, action menu...).

---
## 12. Xử lý lỗi (Đơn giản)
- Unauthorized (401) → có thể logout (demo đủ dùng).
- Hiển thị lỗi: snackbar qua AppSnackBar.

---
## 13. Bỏ kiểm thử tự động (Trong phạm vi đồ án)
- Không yêu cầu test. Có thể mô tả logic bằng văn bản nếu cần trong báo cáo.

---
## 14. Cải tiến tiềm năng (Tuỳ chọn)
| Hạng mục | Giá trị |
|---------|--------|
| Gộp refresh token | Giảm trùng lặp & bug cạnh tranh |
| Tách UI-only models | Rõ ràng ranh giới domain vs presentation |
| Result/Either thay null | Giảm if-null phân tán |
| Router có khai báo (GoRouter) | Dễ bảo trì khi màn nhiều lên |
| Central constants (storage keys) | Tránh gõ lại string key |

### 14.1 Bản đồ FE ↔ BE (Các Tính Năng Khác)
| Tính năng | FE Layer | Backend Endpoint | Payload chính |
|-----------|----------|------------------|---------------|
| Danh sách kế hoạch | Plans Repository | GET /workout-plans | Array kế hoạch |
| Clone template | Plans Repository | POST /workout-plans/clone | Kế hoạch mới (days+exercises) |
| Thêm exercise vào day | Plans Repository | POST /workout-plans/:id/days/:dayId/exercises | Day cập nhật |
| Quick log | ExerciseLogsService | POST /exercise-logs/quick | Log + calories estimate |
| Coach rating list | Coaches Repo | GET /coaches | averageRating + counts |
| Gửi feedback | Feedback Repo | POST /feedbacks | Feedback + rating update |
| Training request | Training Requests Repo | POST /training-requests | Trạng thái pending |
| Meals summary | Meals Repo | GET /meals/my/:date/summary | Breakdown calories |

### 14.2 Vai Trò (UI Enable Matrix)
| Vai trò | Quyền UI chính | Ẩn/Giới hạn |
|---------|----------------|-------------|
| Admin | Quản lý user/profile | Một số màn có thể giản lược |
| Coach | Quản lý kế hoạch, xem gymers, nhận request | Không gửi request làm gymer |
| Gymer | Gửi request, log bài tập, feedback | Không duyệt request |

---
## 15. Coding Conventions (Tóm tắt)
- Tên: PascalCase (class), camelCase (biến), snake_case (file).  
- `mounted` check sau await trong State.  
- Không đặt logic mạng trong model.  
- `Future<void>` cho async không trả giá trị.  
- Parse JSON kiểm kiểu trước cast.

Chi tiết thêm: xem `CODING_STANDARDS.md`.

---
## 16. Checklist thêm tính năng (Rút gọn)
1. Model + Repository (nếu mới).
2. Endpoint gọi qua `ApiClient`.
3. Service nếu cần build logic nhiều bước.
4. UI fetch trong `initState` / action.
5. Log bằng `AppLogger`.
6. UI dùng widget / token chuẩn (Design System).

---
## 17. Hạn chế hiện tại
| Vấn đề | Ghi chú |
|--------|--------|
| Hai cơ chế refresh token | Sẽ hợp nhất qua `TokenManager` |
| Chưa có state management nâng cao | SetState đủ cho phạm vi hiện tại |
| Một số thư mục placeholder | Không ảnh hưởng logic |

---
## 18. Glossary
| Thuật ngữ | Giải thích |
|-----------|-----------|
| Hybrid Percent | Chỉ số kết hợp volume & sets (trọng số alpha=0.8) |
| Volume Load | reps * weight * intensity (clamped) |
| Template Plan | Khuôn mẫu plan để clone user |

(Tham chiếu thêm các thực thể & enum backend: `BACKEND_SCHEMA_REFERENCE.md`).

---
## 19. Ghi chú mở rộng tương lai
- Có thể thêm analytics, i18n khi mở quy mô.
- Golden test 1–2 widget quan trọng nếu cần minh hoạ chất lượng.

---
## 20. Tóm tắt nhanh
- `ApiClient` + `TokenManager` điều phối request & auth.
- Repository: truy cập dữ liệu. Service: logic hợp nhất / tính toán.
- UI dùng Design Tokens + component chuẩn (Design System).
- Khi phân vân: xem mẫu code tương tự + áp dụng token.

_Kết thúc bản rút gọn v2._
