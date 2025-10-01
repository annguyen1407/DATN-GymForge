# GymForge Design System (Rút gọn v2)

> Bản rút gọn phục vụ đồ án: tập trung thành phần cốt lõi, đồng bộ với `lib/theme/design_tokens.dart`.

---
## 1. Triết lý & Mục tiêu
- Giao diện dark (bg/surface/surfaceAlt) + brand tím gradient → nhận diện rõ ràng, tránh bão hoà màu.
- Hạn chế "widget hoang dã": gom về bộ thành phần semantic (AppButton, AddActionButton, AppSnackBar, DestructiveConfirmSheet).
- Một kênh feedback thống nhất (AppSnackBar) + confirm phá huỷ chuẩn hoá.
- Khả năng mở rộng: mọi giá trị (màu, spacing, radius, typography, duration) tập trung ở `DesignTokens`.
- Tối ưu bảo trì: khi đổi theme → chỉnh token, không săn tìm literal rải rác.
- Tránh over‑engineering: chỉ mô tả những gì thực sự dùng trong app hiện tại.

---
## 2. Tokens (Nguồn sự thật)
File: `lib/theme/design_tokens.dart`

| Nhóm | Ví dụ | Ghi chú |
|------|-------|--------|
| Brand | `DesignTokens.brand`, `brandGradient` | Gradient cho hero / highlight duy nhất |
| Semantic | `danger`, `warning`, `success`, `info` | Dùng cho trạng thái / snackbar |
| Surfaces | `bg`, `surface`, `surfaceAlt`, `surfaceMuted`, `surfaceOutline` | Bố cục nền / khối nổi |
| Text | `textPrimary`, `textSecondary`, `textFaint` | Tương phản đảm bảo ≥ 4.5:1 với bg |
| Spacing | `spaceS`..`spaceXXL` | Thang 4‑based, ưu tiên thay vì số lẻ |
| Radius | `radiusS`..`radiusXXL` | AppButton / card / sheet thống nhất bo góc |
| Durations | `durationFast|Normal|Slow` | Animation vi mô |
| Typography | `fontSizeS|M|L|XL...` | Build TextStyle tại chỗ / theme |
| Opacity semantic | `disabledOpacity`, `pressedOpacity` | Trạng thái tương tác |

Nguyên tắc:
- Không hard‑code màu mới nếu token tương đương tồn tại.
- Xuất hiện ≥ 3 lần → cân nhắc thêm token (không thêm token cho giá trị dùng một lần trang trí nhỏ).
- Tách logic opacity dùng extension `withOpacityRatio()` / `mulAlpha()` (xem `core/extensions/color_extensions.dart`).

---
## 3. AppButton (Nút hợp nhất)
File: `widgets/app_button.dart`

### Variants
| Variant | Dùng khi | Visual |
|---------|----------|--------|
| primary | CTA chính | Nền tím đặc + subtle shadow |
| gradient | Hero / onboarding / điểm nhấn lớn | Gradient brand (mỗi màn ≤ 1) |
| secondary | Hành động phụ vẫn quan trọng | Surface nâng nhẹ |
| outline | Trung lập / reload | Viền mờ, nền trong suốt |
| text | Inline ít nhấn mạnh | Không nền, padding tối thiểu |
| danger | Xoá / phá huỷ | Nền đỏ |
| subtle | Hành động rất phụ | Gần như phẳng |

### Sizes
| Size | Chiều cao | Dùng |
|------|-----------|------|
| small | ~36 | Toolbars / list item actions |
| medium | ~44 | Mặc định forms / màn thường |
| large | ~52 | CTA bar / hero |

### State Mapping
| State | Điều kiện | Biểu hiện |
|-------|-----------|----------|
| Enabled | `onPressed != null && !loading` | Full opacity |
| Loading | `loading == true` | Spinner + vô hiệu hoá action |
| Disabled | `onPressed == null` | Opacity = `disabledOpacity` |
| Pressed | Gesture down | Opacity = `pressedOpacity` |

### API ví dụ
```dart
AppButton.primary(
  label: 'Lưu',
  onPressed: _save,
  loading: isSaving,
  leadingIcon: Icons.save,
  size: AppButtonSize.medium,
);
```
Quy tắc ngắn:
- Một `primary` hoặc `gradient` nổi bật trong 1 vùng logic.
- Không tạo custom styled ElevatedButton mới.
- Icon-only tạm dùng variant `text` với label rỗng (roadmap có thể thêm variant native).

---
## 4. AddActionButton (“+” chuẩn)
File: `widgets/add_action_button.dart`

| Constructor | Bối cảnh | Ghi chú |
|-------------|---------|--------|
| circle | Thay FAB nổi | 56x56 gradient |
| pill | Inline có nhãn | Có `label` tùy chọn |
| outlinePill | Nền tối dày đặc | Viền mờ |

Nguyên tắc:
- Chỉ cho hành động tạo / thêm / nhân bản.
- Không đổi icon khác để tránh mơ hồ chức năng.

---
## 5. AppSnackBar (Feedback thống nhất)
File: `widgets/app_snack_bar.dart`

Variants: `success`, `error`, `info`, `warning`

API:
```dart
AppSnackBar.showSuccess(context, 'Đã lưu');
AppSnackBar.showError(context, 'Thất bại');
```
Quy tắc:
- Mỗi hành động → tối đa 1 snackbar (class tự huỷ cái trước).
- Nội dung ≤ 2 dòng; dài hơn → dùng bottom sheet / dialog.
- Không gọi trực tiếp `ScaffoldMessenger.showSnackBar`.

---
## 6. DestructiveConfirmSheet
File: `widgets/destructive_confirm_sheet.dart`
- Xác nhận xoá / reset dữ liệu quan trọng.
- Primary destructive (đỏ) đặt ở bên phải (theo thói quen hành động khẳng định).

Mẫu:
```dart
final ok = await showModalBottomSheet<bool>(
  context: context,
  builder: (_) => DestructiveConfirmSheet(
    title: 'Xoá ngày tập',
    message: 'Bạn chắc chắn? Thao tác không thể hoàn tác.',
    confirmLabel: 'Xoá',
    onConfirm: () => Navigator.pop(context, true),
  ),
);
if (ok == true) deleteDay();
```

---
## 7. CTA Patterns
| Trường hợp | Thành phần | Ghi chú |
|-----------|------------|--------|
| Floating create | `AddActionButton.circle` | Không dùng FAB mặc định |
| Onboarding / hero | `AppButton.gradient` | Màn ≤ 1 gradient |
| Form submit | `AppButton.primary` (hoặc `danger` nếu destructive) | Dùng `loading` khi chờ API |
| Retry lỗi cục bộ | `AppButton.primary(size: small)` | Center, width hợp lý |
| Delete xác nhận | `AppButton.danger` + confirm sheet | Hai bước tránh xoá nhầm |

---
## 8. Anti‑patterns (Tránh)
| Anti‑pattern | Dùng thay |
|-------------|---------|
| ElevatedButton tím tuỳ biến | `AppButton.primary` |
| FloatingActionButton | `AddActionButton.circle` |
| IconButton gradient “+” | `AddActionButton.circle` |
| Snackbar thủ công | `AppSnackBar.showX` |
| Button tự giảm opacity thủ công | State nội bộ AppButton |
| Hard‑coded color trong widget | Token tương ứng |

---
## 9. Accessibility & Contrast
- Text chính ≥ 14sp, contrast đủ trên `bg` / `surface`.
- Không đặt text tím brand trên gradient tím (dễ mờ) → dùng trắng hoặc đổi nền.
- Kích thước hit target ≥ 40x40 (circle button / pill).
- Trạng thái disabled dùng opacity token (không đổi màu tuỳ hứng).

---
## 10. Quick Snippets
```dart
// Primary submit
AppButton.primary(label: 'Gửi', onPressed: _submit);
// Danger deletion
AppButton.danger(label: 'Xoá bài', onPressed: _delete, loading: isDeleting);
// Gradient hero
AppButton.gradient(label: 'Bắt đầu ngay', onPressed: startFlow);
// Outline neutral (không full width)
AppButton.outline(label: 'Tải lại', onPressed: _reload, fullWidth: false);
// Inline text
AppButton.text(label: 'Xem thêm', onPressed: _more, fullWidth: false);
// Add floating
AddActionButton.circle(onPressed: _addItem);
// Xác nhận xoá
final ok = await _confirmDelete(context); if (ok) _delete();
```

---
## 11. Thành phần bổ sung (Tóm tắt)
- DatePicker bottom sheet (AppDatePicker).
- Action menus: `DayActionsMenu`, `PlanActionsMenu`.
- DestructiveConfirmSheet (đã mô tả).

Không đi sâu optimistic/refetch trong phạm vi đồ án.

---
## 12. Nguyên tắc cốt lõi (Recap)
- Button = AppButton (mọi trường hợp) / “+” = AddActionButton.
- Mỗi màn ≤ 1 CTA nổi bật (primary / gradient).
- Feedback = AppSnackBar.
- Giá trị UI lấy từ `DesignTokens`.

---
## 13. FAQ Nhanh
| Hỏi | Trả lời |
|-----|---------|
| Nút mờ? | Disabled (`onPressed == null`) hoặc `loading` |
| Gradient dùng ở đâu? | Hero / onboarding / entry flows |
| Cần icon-only? | Tạm dùng `text` + icon, label rỗng |
| Thêm màu mới? | Kiểm tra `DesignTokens` trước, nếu thiếu → thêm token rồi dùng |

---
## 14. Kết luận
Tài liệu này là chuẩn tham chiếu để giữ UI nhất quán. Khi thêm thành phần nền tảng mới (ví dụ: Tag, Badge, Progress), mở rộng: bổ sung variant vào AppButton trước – tránh tạo hệ mới.

_Updated sync với tokens & quy ước hiện tại._

