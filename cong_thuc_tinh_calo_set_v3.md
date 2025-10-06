# 📘 Công thức tính calo tiêu thụ cho 1 set bài tập (phiên bản hoàn chỉnh v3)

## 🧮 1. Công thức tổng quát

```math
E_set = M_adj × 3.5 × (W / 200) × (R × T_rep / 60)
```

---

## 🧩 2. MET điều chỉnh theo cường độ

```math
M_adj =
{
  M_base, nếu loadUsed = 0
  M_base × F_int, nếu loadUsed > 0 và oneRm > 0
  M_base × F_default, nếu loadUsed > 0 và oneRm bị thiếu hoặc = 0
}
```

---

## ⚙️ 3. Công thức hệ số điều chỉnh

### Trường hợp có đủ 1RM

```math
F_int = Clamp(1 + k × ((loadUsed / oneRm × 100 - P_ref) / 100), F_min, F_max)
```

### Trường hợp không có 1RM (ước lượng theo trọng lượng cơ thể)

```math
F_default = Clamp(1 + k_r × ((L_ratio - L_ref) / L_ref), F_min, F_max)
```
với  
`L_ratio = loadUsed / W`

---

## 🧩 4. Giải thích biến số

| Ký hiệu | Ý nghĩa | Đơn vị | Ghi chú |
|----------|----------|---------|----------|
| `E_set` | Năng lượng tiêu thụ trong 1 set | kcal | Kết quả cuối cùng |
| `M_base` | MET cơ bản của bài tập | – | Lưu trong DB (giá trị trung bình) |
| `M_adj` | MET đã điều chỉnh theo cường độ | – | Dựa trên `loadUsed`, `oneRm` hoặc `W` |
| `loadUsed` | Mức tạ dùng trong set | kg | Nếu 0 → bài không dùng tạ |
| `oneRm` | 1 Repetition Maximum | kg | Mức tạ tối đa nâng được 1 lần |
| `W` | Cân nặng cơ thể người tập | kg | Dùng trong quy đổi năng lượng |
| `R` | Số rep trong set | lần | Tổng số rep thực hiện |
| `T_rep` | Thời gian trung bình 1 rep | giây | Thường khoảng 4–6s |
| `P_ref` | %1RM tham chiếu | % | Mặc định 50 |
| `k`, `k_r` | Hệ số nhạy điều chỉnh | – | 0.3–0.7 (0.5 khuyến nghị) |
| `L_ref` | Tỷ lệ tải trọng tham chiếu | – | Mặc định 0.5 (tức 50% trọng lượng cơ thể) |
| `F_min`, `F_max` | Giới hạn hệ số điều chỉnh | – | Ngăn sai số cực trị |

---

## 📊 5. Các tình huống xử lý

| Loại bài tập | `loadUsed` | `oneRm` | Cách xử lý | Ghi chú |
|---------------|-------------|----------|-------------|----------|
| Bodyweight (hít đất, plank, squat tự do...) | 0 | – | `M_adj = M_base` | MET phản ánh cường độ trung bình |
| Weighted có 1RM | >0 | >0 | `M_adj = M_base × F_int` | Điều chỉnh chính xác theo %1RM |
| Weighted nhưng không có 1RM | >0 | 0 hoặc thiếu | `M_adj = M_base × F_default` | Ước lượng theo tỉ lệ tạ/cân nặng |

✅ Công thức tự động hoạt động đúng cho cả 3 loại — không cần thêm flag `isBodyweight`.

---

## 📘 6. Ví dụ minh họa

### 🏋️‍♂️ Bài có tạ (đủ 1RM): Bench Press
| Thông số | Giá trị |
|-----------|----------|
| `M_base` | 4.0 |
| `loadUsed` | 96 kg |
| `oneRm` | 120 kg |
| `W` | 75 kg |
| `R` | 6 |
| `T_rep` | 5 s |
| `P_ref` | 50 |
| `k` | 0.5 |
| `F_min` / `F_max` | 0.6 / 1.5 |

**Tính:**
```math
P = 96 / 120 × 100 = 80
F_int = 1 + 0.5 × (80 - 50)/100 = 1.15
M_adj = 4.0 × 1.15 = 4.6
E_set = 4.6 × 3.5 × 75 / 200 × (6×5/60) = 3.0 kcal
```

✅ **Kết quả:** ≈ 3 kcal/set

---

### 💪 Bài không tạ: Push-up
| Thông số | Giá trị |
|-----------|----------|
| `M_base` | 8.0 |
| `loadUsed` | 0 |
| `W` | 70 kg |
| `R` | 15 |
| `T_rep` | 4 s |

**Vì `loadUsed = 0` → `M_adj = M_base`**

```math
E_set = 8.0 × 3.5 × 70 / 200 × (15×4/60) = 9.8 kcal
```

✅ **Kết quả:** ≈ 10 kcal/set

---

### 🏋️‍♀️ Bài có tạ nhưng chưa có 1RM
| Thông số | Giá trị |
|-----------|----------|
| `M_base` | 4.0 |
| `loadUsed` | 60 kg |
| `oneRm` | *thiếu* |
| `W` | 70 kg |
| `R` | 10 |
| `T_rep` | 5 s |
| `k_r` | 0.5 |
| `L_ref` | 0.5 |
| `F_min` / `F_max` | 0.6 / 1.5 |

**Tính:**
```math
L_ratio = 60 / 70 = 0.86
F_default = 1 + 0.5 × (0.86 - 0.5)/0.5 = 1.36
M_adj = 4.0 × 1.36 = 5.44
E_set = 5.44 × 3.5 × 70 / 200 × (10×5/60) ≈ 11.1 kcal
```

✅ **Kết quả:** ≈ 11 kcal/set

---

## 🧠 7. Quy tắc thực thi tổng quát (backend-ready)

```text
Nếu loadUsed == 0:
    M_adj = M_base
Ngược lại nếu oneRm > 0:
    percent1Rm = loadUsed / oneRm × 100
    F_int = Clamp(1 + k × (percent1Rm - P_ref)/100, F_min, F_max)
    M_adj = M_base × F_int
Ngược lại (oneRm == null hoặc 0):
    L_ratio = loadUsed / W
    F_default = Clamp(1 + k_r × (L_ratio - L_ref)/L_ref, F_min, F_max)
    M_adj = M_base × F_default

E_set = M_adj × 3.5 × (W / 200) × (R × T_rep / 60)
```

---

## 🔧 8. Gợi ý cấu hình mặc định

| Tham số | Giá trị khuyến nghị |
|----------|----------------------|
| `P_ref` | 50 |
| `k`, `k_r` | 0.5 |
| `L_ref` | 0.5 |
| `F_min` | 0.6 |
| `F_max` | 1.5 |
| `T_rep` | 5 |

---

## ✅ 9. Tổng kết

| Tình huống | Cách tính | Ghi chú |
|-------------|-------------|----------|
| Bài không tạ (`loadUsed=0`) | `M_adj = M_base` | MET gốc |
| Có 1RM | `M_adj = M_base × F_int` | Điều chỉnh chính xác |
| Không có 1RM | `M_adj = M_base × F_default` | Ước lượng theo tạ/cân nặng |
| Tất cả trường hợp | `E_set = M_adj × 3.5 × (W / 200) × (R × T_rep / 60)` | Công thức thống nhất |

---

**➡️ Phiên bản này (v3)** là công thức chính thức khuyến nghị dùng trong app gym:  
- Xử lý tự động cho mọi loại bài tập (có tạ, không tạ, không có 1RM).  
- Không cần thêm flag mới trong DB.  
- Cho kết quả ổn định, hợp lý và dễ mở rộng.
