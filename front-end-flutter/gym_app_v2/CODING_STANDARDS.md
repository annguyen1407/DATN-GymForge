# GymForge Flutter Coding Standards (Rút gọn đồng bộ)

Cập nhật để đồng bộ với `DesignTokens`, Design System v2 và phạm vi đồ án (test chỉ ở mức roadmap, không bắt buộc hiện tại).

---
## 1. Analyzer & Lint Baseline
- Mục tiêu: **0 analyzer issues** (`flutter analyze`).
- Không re-introduce lỗi đã fix (`use_build_context_synchronously`, deprecated API, `avoid_print`).
- `// ignore_for_file:` chỉ dùng khi có lý do rõ ràng, ghi chú ngắn.

Checklist nhanh trước commit:
1. `flutter analyze` = 0 warning/error.
2. Không còn `print(` / `debugPrint(` (trừ trong `AppLogger`).
3. Không gọi trực tiếp `withOpacity()` → dùng extension (xem §2).
4. Sau mỗi `await` trong `State`: `if (!mounted) return;` trước `setState` / Navigator.
5. Thêm `const` tối đa vào widget tree.
6. Không duplicate model / widget.

---
## 2. Color & Opacity
Sử dụng tokens + extension để tránh scatter logic.
- Màu: lấy từ `DesignTokens` (không hard-code màu brand, surface...).
- Opacity: `color.withOpacityRatio(x)` hoặc `color.mulAlpha(f)` thay vì `withOpacity()` trực tiếp.
- Không tạo file tokens song song khác.

---
## 3. Logging Policy
Tất cả log qua `AppLogger` (`core/logging/app_logger.dart`).
```dart
AppLogger.debug('Loaded ${items.length} items', tag: 'ExerciseRepo');
AppLogger.error('Failed to fetch plan', tag: 'PlanRepo', error: e, stackTrace: st);
```
Cấm: `print`, `debugPrint` (trừ nội bộ logger), wrapper tuỳ ý.

---
## 4. Async Context Safety
- Cache `navigator = Navigator.of(context)` nếu dùng sau `await` nhiều lần.
- Sau `await` trong State: kiểm `if (!mounted) return;`.
- Không show dialog/sheet trong `build()`.
- Dùng `PopScope` thay cho `WillPopScope` ở code mới.

---
## 5. Naming & Files
- File snake_case, class PascalCase.
- Không dùng hậu tố tạm như `Temp`, `Copy` (nếu tạm → TODO deadline xóa).
- Widget public không khai báo State private mismatch.

---
## 6. Avoid Duplication
- Button → `AppButton`; FAB / plus → `AddActionButton`.
- Không tạo ElevatedButton style riêng trừ khi bắt buộc (khi đó cân nhắc mở rộng AppButton).
- Xoá file placeholder khi đã migrate.

---
## 7. Null Safety & Defensive Code
- Tránh lạm dụng `!`; ưu tiên early return.
- Sử dụng pattern matching / `if (x == null) return;` thay vì ép kiểu.
- Khi parse JSON: kiểm tra kiểu trước cast.

---
## 8. Styling & Readability
- Line length mục tiêu: ≤ 110 chars.
- Import order: SDK → packages → local (cách nhau dòng trống).
- Dùng trailing commas để formatter tối ưu.
- Expression-bodied function chỉ khi cực ngắn & rõ ràng.

---
## 9. UI Consistency
- Không hard-code màu/spacing nếu token có sẵn.
- Bóng / gradient / opacity theo token & variant (không tự tuỳ biến mỗi nơi một kiểu).
- Text tương phản: đảm bảo đọc được trên nền dark (tránh tím brand nhỏ trên gradient tím).

---
## 10. Error Handling
- Bắt lỗi tại boundary repository/service → log bằng `AppLogger.error`.
- Feedback user dùng `AppSnackBar.showError`.
- Không propagate exception raw lên UI (trừ debug có kiểm soát).

---
## 11. Performance Guidelines
- Không tính toán nặng trong `build()`.
- Dùng `const` constructors khi có thể.
- Danh sách dài → `ListView.builder`, tránh 1 `Column` chứa quá nhiều phần tử.
- Dự kiến debounce search (có thể thêm util sau – không bắt buộc).

---
## 12. State & Lifecycle
- Dispose controllers / animations.
- Không trigger network trong `build()`.
- Khởi tạo fetch trong `initState` hoặc hành động explicit.

---
## 13. API & Services
- Mọi HTTP request đi qua Repository/Service + `ApiClient`.
- Model parse qua `fromJson` (không xử lý JSON trong widget).
- Trả về model rõ ràng thay vì `dynamic`.

---
## 14. Testing (Roadmap – Không bắt buộc hiện tại)
- Ưu tiên (khi thêm sau này): logic tính toán `ExerciseLogsService`, `workout_completion.dart`.
- Golden test cho 1–2 widget chủ chốt (button / card) nếu mở rộng.

---
## 15. Git & Commit Hygiene
- Mỗi commit giữ analyzer xanh.
- Commit message: tiếng Anh ngắn gọn + prefix (`feat:`, `fix:`, `refactor:`, `chore:` ...).
- Xoá branch sau merge để tránh drift.

---
## 16. Dependencies
- Thêm package mới: cần lý do (thiếu tính năng trong stdlib? giảm thời gian?).
- Ưu tiên nhẹ, null-safe, maintained.
- Tránh thêm chỉ để tiết kiệm vài dòng code trivial.

---
## 17. Accessibility / UX
- Hit target ≥ 40x40 (circle / icon actions quan trọng).
- Disabled state dùng opacity token (không đổi text sang màu ngẫu nhiên).
- Tránh text nhỏ < 12sp (trừ label phụ / meta cực nhỏ – cân nhắc).

---
## 18. Dark Theme Fidelity
- Giữ hệ surface: `bg` → `surface` → `surfaceAlt` → `surfaceMuted` (tầng). Không xen màu xám lạ.
- Viền mờ dùng `surfaceOutline` hoặc opacity trắng thấp.

---
## 19. Deletion Policy
1. Migrate usages.
2. Tìm kiếm chắc không còn import.
3. Xoá cùng commit (không để mồ côi).

---
## 20. TODO & Comments
- Format: `// TODO(username - yyyy-mm-dd): mệnh đề cụ thể`.
- Xoá TODO khi hoàn thành (đừng để mốc đã quá hạn lâu).
- Comment mô tả mục đích / bẫy, không lặp lại hiển nhiên.

---
## 21. Future Enhancements (Khuyến nghị)
- Hợp nhất cơ chế refresh token (loại bỏ timer trùng lặp nếu còn).
- Introduce Result/Either type thay vì trả `null`.
- Debounce helper chung.
- Simple dependency injection container (registrar) khi số service tăng.
- Thêm lint rule custom (nếu cần) để cấm hard‑code brand color.

---
## 22. Violation Handling
- Vi phạm phải ghi chú lý do trong commit/PR.
- Lặp nhiều lần → tạo task cleanup.

---
## 23. Adoption Steps (Tuỳ chọn)
1. (Sau này) Pre-commit: `flutter format --set-exit-if-changed . && flutter analyze`.
2. (Sau này) CI workflow GitHub Actions: format + analyze.
3. Định kỳ rà soát doc khi thêm feature.

_Last updated: 2025-09-23_
