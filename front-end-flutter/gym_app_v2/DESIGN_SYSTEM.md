# GymForge Design System (Flutter)

> Trụ cột giao diện thống nhất cho ứng dụng GymForge. Mục tiêu: **nhanh hơn**, **nhất quán hơn**, **dễ bảo trì hơn**.

---
## 1. Triết lý
- Dark surface chủ đạo (#000 / #121212 / #1A1A1A) + accent tím gradient (primary brand).
- Giảm sự đa dạng ngẫu nhiên của ElevatedButton / TextButton / FAB bằng các thành phần ngữ nghĩa (AppButton, AddActionButton).
- Feedback người dùng: dùng một chuẩn duy nhất (AppSnackBar) + bottom sheet xác nhận phá huỷ.
- Ưu tiên code tái sử dụng: màu, padding, bo góc, elevation / shadow nằm trung tâm.

---
## 2. Màu sắc chính (Tokens gợi ý)
| Token | Mô tả | Giá trị gợi ý |
|-------|-------|---------------|
| `color.bg` | Nền chính | `#000000` |
| `color.surface` | Khối nổi | `#141414` / `#1C1C1E` |
| `color.surfaceAlt` | Khối phụ | `#222224` |
| `color.border` | Viền mờ | `rgba(255,255,255,0.12)` |
| `color.textPrimary` | Chữ chính | `#FFFFFF` |
| `color.textSecondary` | Chữ phụ | `#B5B5B5` |
| `color.textFaint` | Chú thích | `#6F6F6F` |
| `color.brand` | Accent cơ bản | `#8854FF` |
| `color.brandGradientStart` | Gradient start | `#8854FF` |
| `color.brandGradientEnd` | Gradient end | `#9966FF` / `#B06BFF` |
| `color.danger` | Hành động phá huỷ | `#FF4D4D` / `#FF5151` |
| `color.warning` | Cảnh báo | `#FFB020` |
| `color.success` | Thành công | `#2ECC71` |
| `color.info` | Thông tin | `#4098FF` |

(Hiện tại chưa tách file theme Dart – có thể bổ sung `theme/tokens.dart` sau.)

---
## 3. AppButton
`widgets/app_button.dart` cung cấp hệ thống nút hợp nhất thay thế ElevatedButton/TextButton/... với API semantic.

### Variants
| Variant | Dùng khi | Đặc điểm |
|---------|---------|----------|
| `primary` | CTA chính trong view | Nền tím đặc + shadow nhẹ |
| `secondary` | Hành động phụ quan trọng | Nền surface nâng nhẹ |
| `outline` | Hành động trung lập, tùy chọn | Viền mờ, nền trong suốt |
| `text` | Inline, ít nhấn mạnh | Không nền, padding tối thiểu |
| `danger` | Xoá / phá huỷ / reset | Nền đỏ, không gradient |
| `gradient` | Hero / hành trình chính / màn chào | Gradient thương hiệu |
| `subtle` | Hành động rất phụ | Hầu như phẳng, hoà vào nền |

### Sizes
| Size | Chiều cao / padding | Ngữ cảnh |
|------|---------------------|----------|
| `small` | Chip / toolbar | Inline hoặc nhóm dày đặc |
| `medium` | Mặc định | Form, thẻ chi tiết |
| `large` | CTA lớn / bar dưới | Onboarding, hành trình chính |

### API chính
```dart
AppButton.primary(
  label: 'Lưu',
  onPressed: _save,
  leadingIcon: Icons.save,
  loading: isSaving,
  size: AppButtonSize.large,
);
```
Thuộc tính đáng chú ý:
- `loading`: tự disable + hiển thị spinner.
- `fullWidth`: mặc định true (trừ text variant) – kiểm soát chiều rộng.
- `leadingIcon` / `trailingIcon`.
- Không cần wrap SizedBox trừ khi muốn giới hạn cục bộ.

### Quy tắc sử dụng
- Chỉ một `primary` hoặc `gradient` nổi bật trong một khối logic.
- Tránh lồng nhiều AppButton cùng cấp gây nhiễu thị giác.
- `text` dùng cho hành động phụ trong card/list item (ví dụ: “Xem thêm”).

---
## 4. AddActionButton
`widgets/add_action_button.dart` – nút dấu “+” chuẩn hoá.

### Variants
| Constructor | Dùng khi | Ghi chú |
|-------------|---------|---------|
| `AddActionButton.circle` | FAB thay thế (floating) | 56x56, gradient, elevation nhẹ |
| `AddActionButton.pill` | Inline tạo mới có nhãn | Có optional `label` |
| `AddActionButton.outlinePill` | Trên nền tối cần nhẹ hơn | Viền mờ, không gradient |

### Mẫu
```dart
AddActionButton.circle(onPressed: _createPlan);
AddActionButton.pill(label: 'Thêm bài', onPressed: _addExercise);
```

Quy tắc: Chỉ dùng cho hành động “thêm/tạo/lặp” – không tái dụng như CTA chung (dùng AppButton thay thế).

---
## 5. AppSnackBar
`widgets/app_snack_bar.dart` – kênh feedback thống nhất.

### Variants
`success`, `error`, `info`, `warning`

### API
```dart
AppSnackBar.showSuccess(context, 'Đã lưu');
AppSnackBar.showError(context, 'Thất bại');
```

### Nguyên tắc
- Mỗi hành động chỉ hiển thị 1 snackbar → AppSnackBar tự ẩn snackbar trước đó.
- Dùng tông màu và icon nhất quán (định nghĩa trong private theme mapping).
- Không dùng trực tiếp `ScaffoldMessenger.showSnackBar` nữa.

---
## 6. DestructiveConfirmSheet
`widgets/destructive_confirm_sheet.dart`
Bottom sheet xác nhận hành động phá huỷ (xoá plan, xoá exercise...).

API mẫu:
```dart
final confirmed = await showModalBottomSheet<bool>(
  context: context,
  builder: (_) => DestructiveConfirmSheet(
    title: 'Xoá ngày tập',
    message: 'Bạn chắc chắn? Thao tác không thể hoàn tác.',
    confirmLabel: 'Xoá',
    onConfirm: () => Navigator.pop(context, true),
  ),
);
if (confirmed == true) deleteDay();
```
Đã migrate nút sang `AppButton.outline` + `AppButton.danger`.

---
## 7. Pattern: Floating / Page CTAs
| Ngữ cảnh | Thành phần | Ghi chú |
|----------|------------|---------|
| FAB tạo mới | `AddActionButton.circle` | Tránh dùng FloatingActionButton mặc định |
| CTA màn onboarding / welcome | `AppButton.gradient` | Tối đa 1 gradient / màn |
| Form submission | `AppButton.primary` hoặc `danger` (nếu destructive) | Loading state nếu có call API |
| Retry trong lỗi cục bộ | `AppButton.primary` (small) | Center + width cố định hợp lý (140–200) |

---
## 8. Tránh lặp lại (Anti-patterns)
| Anti-pattern | Thay bằng |
|--------------|----------|
| ElevatedButton với style tím custom | `AppButton.primary` |
| TextButton retry / reload | `AppButton.primary(size: small)` |
| IconButton hình tròn gradient cho “+” | `AddActionButton.circle` |
| Snackbar thủ công | `AppSnackBar.showX` |
| FAB mặc định | `AddActionButton.circle` |

---
## 9. Checklist Migration (đã thực hiện)
- [x] Global: SnackBar → AppSnackBar
- [x] Plan tab / Exercise list / Exercise detail retry
- [x] Profile setup các bước → AppButton
- [x] Verify success → AppButton
- [x] Destructive bottom sheet → AppButton
- [x] Workout template & session màn → AppButton / AddActionButton
- [x] + buttons rải rác → AddActionButton
- [ ] log_exercise_detail_screen (pending)
- [ ] Cuối log_screen 2 nút legacy (pending)

---
## 10. Naming & File Quy ước
| Thành phần | File |
|------------|------|
| AppButton | `widgets/app_button.dart` |
| AddActionButton | `widgets/add_action_button.dart` |
| AppSnackBar | `widgets/app_snack_bar.dart` |
| DestructiveConfirmSheet | `widgets/destructive_confirm_sheet.dart` |

Giữ factory constructors thay vì subclass để dễ mở rộng.

---
## 11. Mở rộng tương lai (Roadmap nhẹ)
- Tách `ThemeData` custom: typography scale, colorScheme override.
- Thêm `IconOnlyButton` (kích thước 40x40 – state hover/pressed rõ ràng).
- Thêm animation subtle cho gradient hover (desktop/web).
- Trích xuất tokens sang lớp `DesignTokens` + test snapshot đơn giản.
- Hệ thống form field wrapper (label + validation + spacing) thống nhất.

---
## 12. Quick Usage Snippets
```dart
// Primary submit
AppButton.primary(label: 'Gửi', onPressed: _submit);

// Danger deletion
AppButton.danger(label: 'Xoá bài', onPressed: _delete, loading: isDeleting);

// Gradient hero
AppButton.gradient(label: 'Bắt đầu ngay', onPressed: startFlow);

// Outline neutral
AppButton.outline(label: 'Tải lại', onPressed: _reload, fullWidth: false);

// Text inline
AppButton.text(label: 'Xem thêm', onPressed: _more, fullWidth: false);

// Add floating
AddActionButton.circle(onPressed: _addItem);
```

---
## 13. Review Guidelines (PR Checklist)
- [ ] Không dùng ElevatedButton/TextButton trực tiếp trừ trường hợp đặc biệt được chấp thuận.
- [ ] Snackbar phải gọi qua AppSnackBar.
- [ ] CTA chính màn hình không quá 1 variant nổi bật (primary/gradient).
- [ ] Các nút “+” phải dùng AddActionButton.*
- [ ] Loading state có spinner khi gọi API > 400ms.
- [ ] Kiểm tra accessible tap target ≥ 44px.

---
## 14. FAQ Nhanh
- Vì sao nút bị mờ? -> `onPressed` null hoặc `loading = true`.
- Cần icon-only? → Tạm dùng `AppButton.text` với label rỗng + icon (roadmap sẽ thêm variant native).
- Dùng gradient ở đâu? → Chỉ cho hero/entry flows (welcome, start workout, onboarding).

---
## 15. Liên quan kỹ thuật
- Tránh lồng InkWell khác bên trong AppButton (đã có ripple riêng).
- AnimatedContainer dùng làm nền → tránh rebuild nặng trong list rất dài (có thể tối ưu tiếp bằng Stateless + theme caching nếu cần).
- Nếu cần disable tạm thời: set `onPressed: null` thay vì bool riêng.

---
**Kết luận:** File này là nguồn tham chiếu chính để đảm bảo UI thống nhất. Cập nhật khi thêm thành phần nền tảng mới.

---
## 16. Thành phần tái sử dụng mới (2025-09 cập nhật)

### 16.1 AppDatePicker (`widgets/date/app_date_picker.dart`)
Date picker tuỳ biến dạng bottom sheet / dialog (compact) với:
* Chỉ hiển thị ngày trong tháng hiện tại (ẩn ngày thừa tháng trước/sau)
* `disablePast` chặn chọn ngày đã qua (dùng trong workout day)
* Overlay chọn nhanh tháng/năm với grid "Tháng 1...12" + điều hướng năm
* Animation chuyển tháng (fade/slide subtle)
* Tùy chọn `hideTitle` khi nhúng vào flow (DOB, workout day edit)

API mẫu:
```dart
final picked = await AppDatePicker.show(
  context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2020),
  lastDate: DateTime(2030),
  hideTitle: true,
  disablePast: true,
  confirmLabel: 'Lưu',
  cancelLabel: 'Huỷ',
);
```

Quy tắc:
* Không tự parse chuỗi dd/MM/yyyy ngoài widget – luôn làm việc với `DateTime`.
* Dùng chung formatter trong `AppDateUtils` (xem 16.4) để nhất quán hiển thị.

### 16.2 DayActionsMenu (`widgets/day_actions_menu.dart`)
Menu 3 chấm cho hành động trên Workout Day (Sửa / Xoá). Sử dụng `enum DayAction { edit, delete }` để type-safe.

```dart
DayActionsMenu(onAction: (action) async {
  switch(action) {
    case DayAction.edit: _editDate(); break;
    case DayAction.delete: _confirmDeleteDay(); break;
  }
});
```

### 16.3 PlanActionsMenu (`widgets/plan_actions_menu.dart`)
Tương tự `DayActionsMenu` nhưng phạm vi kế hoạch tập luyện. Dùng `enum PlanAction { edit, delete }`.

```dart
PlanActionsMenu(onAction: (action) async {
  if (action == PlanAction.delete) _deletePlan();
});
```

### 16.4 AppDateUtils (`utils/date_utils.dart`)
Chuẩn hoá xử lý ngày:
| Hàm | Mục đích |
|-----|----------|
| `formatDdMMyyyy(DateTime)` | Trả chuỗi `dd/MM/yyyy` |
| `parseIsoOrDisplay(String?)` | Parse ISO hoặc chuỗi dd/MM/yyyy an toàn |
| `normalizeToLocalDate(DateTime)` | Bỏ phần time để so sánh/logic |

Nguyên tắc: Không parse từ UI text tuỳ tiện – luôn thông qua util này. Khi gửi API dùng ISO, khi hiển thị dùng `formatDdMMyyyy`.

### 16.5 DestructiveConfirmSheet tái sử dụng xoá Plan / Day
Đã thống nhất mọi confirm phá huỷ (xoá day, xoá kế hoạch) dùng bottom sheet này thay vì AlertDialog.

Mẫu xoá kế hoạch:
```dart
final confirmed = await showModalBottomSheet<bool>(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (_) => DestructiveConfirmSheet(
    title: 'Xoá kế hoạch',
    message: 'Bạn chắc chắn muốn xoá kế hoạch này? Hành động không thể hoàn tác.',
    confirmLabel: 'Xoá',
    onConfirm: () => Navigator.pop(context, true),
  ),
);
if (confirmed == true) {
  final deleted = await _repo.deletePlan(planId);
  if (deleted != null) {
    Navigator.pop(context, {
      'deleted': true,
      'id': deleted.id,
      'name': deleted.name,
    });
  }
}

  ### 16.5b Xoá & cập nhật Workout Day qua Repository
  Thay vì gọi trực tiếp `ApiService`, dùng abstraction trong `WorkoutPlansRepository` để đồng bộ logging và parse model.

  ```dart
  // Cập nhật ngày
  final updated = await _plansRepo.updateDay(
    dayId,
    workoutPlanId: planId,
    date: pickedDate,
  );
  if (updated != null) {
    // optimistic UI + navigator pop
  }

  // Xoá ngày
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => DestructiveConfirmSheet(
      title: 'Xoá ngày tập',
      message: 'Bạn chắc chắn muốn xoá ngày tập này?',
      confirmLabel: 'Xoá',
      onConfirm: () => Navigator.pop(context, true),
    ),
  );
  if (confirmed == true) {
    final deleted = await _plansRepo.deleteDay(dayId);
    if (deleted != null) {
      Navigator.pop(context, {'deleted': true, 'id': dayId});
    }
  }
  ```
```

### 16.6 Mẫu truyền kết quả qua Navigator
Chuẩn: Child màn chỉnh sửa/ngày tập trả Map có key rõ ràng:
| Key | Ý nghĩa |
|-----|---------|
| `updatedDate` | Chuỗi dd/MM/yyyy sau chỉnh sửa (cho hiển thị nhanh) |
| `updatedDateIso` | ISO chuẩn để parse chắc chắn |
| `deleted` | true nếu mục bị xoá |
| `id` | ID đối tượng để parent xác định & giữ selection |

Parent nhận: optimistic update (dựa `updatedDateIso` ưu tiên) rồi refetch để đồng bộ.

### 16.7 Pattern Optimistic + Refetch (Workout Day)
1. Child PATCH -> trả về `updatedDateIso`.
2. Parent cập nhật tạm `_days[idx] = copyWith(date: parsed)`.
3. Gọi `_refetchAndPreserve(preserveId: id)` để tránh nhảy selection.

### 16.8 Tên gọi & Tránh lệch ngữ nghĩa
| Tình huống | Dùng | Tránh |
|------------|------|-------|
| Menu hành động Day | `DayActionsMenu` | PopupMenuButton tuỳ biến lại |
| Menu hành động Plan | `PlanActionsMenu` | IconButton + showMenu thủ công |
| Xác nhận xoá | `DestructiveConfirmSheet` | AlertDialog default |
| Chọn ngày | `AppDatePicker.show()` | `showDatePicker` mặc định (không đồng bộ UI) |

### 16.9 Roadmap đề xuất tiếp theo
* Trích xuất `PlanEditScreen` dùng chung cho tạo / chỉnh sửa.
* Thêm `FormFieldWrapper` để chuẩn hoá label + error.
* Cơ chế theming động cho các button (compact density).
* Viết test đơn giản cho `AppDateUtils` (parse edge cases 29/02, invalid...).

---
## 17. Phụ lục nhanh (Cheat-Sheet)
```dart
// Menu kế hoạch
PlanActionsMenu(onAction: _handlePlanAction);

// Menu ngày tập
DayActionsMenu(onAction: _handleDayAction);

// Date picker
final d = await AppDatePicker.show(context, initialDate: DateTime.now(), hideTitle: true);

// Parse date trả về
final parsed = AppDateUtils.parseIsoOrDisplay(result['updatedDateIso'] ?? result['updatedDate']);
```

