## GymForge Monorepo

Thư mục chính chứa:

- `backend/` (NestJS + Prisma + Redis) – API server
- `front-end-flutter/gym_app_v2/` – Ứng dụng mobile Flutter
- `dump.rdb` – Redis snapshot (dev)

### Cấu hình môi trường (Flutter app)
Vào thư mục `front-end-flutter/gym_app_v2/` và tạo file `.env` từ mẫu (nếu chưa có):
```
cp .env.example .env
```
Các biến chính:
```
API_BASE_URL=http://localhost:3000
REFRESH_INTERVAL_SECONDS=600
```
Chi tiết hơn xem `front-end-flutter/gym_app_v2/README.md` và `AUTH_TOKEN_FLOW.md`.

### Backend
Xem hướng dẫn riêng trong `backend/README.md` (migration Prisma, seed, chạy server).

---
Mọi thay đổi đối với luồng auth/refresh: xem `front-end-flutter/gym_app_v2/AUTH_TOKEN_FLOW.md`.


