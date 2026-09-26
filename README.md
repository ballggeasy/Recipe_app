# Recipe App

แอปสูตรอาหาร — Flutter frontend + NestJS backend อยู่ใน repo เดียวกัน แต่แยกโฟลเดอร์ชัดเจน

```
.
├── frontend/       # Flutter app
└── backend/        # NestJS API server
```

## เริ่มต้นใช้งาน

ต้องรัน **backend ก่อน** แล้วค่อยรัน frontend ต่อ (frontend เรียก API จาก backend โดยตรง ไม่มี mock data แล้ว)

### 1. Backend (NestJS)

ต้องมี [Node.js](https://nodejs.org/) (แนะนำ v18+)

```bash
cd backend
npm install
cp .env.example .env
npm run start:dev
```

Server จะรันที่ `http://localhost:3000` และสร้างไฟล์ฐานข้อมูล SQLite ที่ `backend/data/app.sqlite` อัตโนมัติ (seed สูตรอาหารตัวอย่าง 16 สูตรให้เองตอนบูตครั้งแรก)

รายละเอียด endpoint ทั้งหมดดูที่ [`backend/README.md`](backend/README.md)

### 2. Frontend (Flutter)

ต้องมี [Flutter SDK](https://docs.flutter.dev/get-started/install) ติดตั้งไว้แล้ว

```bash
cd frontend
flutter pub get
flutter run
```

เลือกอุปกรณ์ตามที่ต้องการ (Chrome, Windows, emulator ฯลฯ) เมื่อ `flutter run` ถาม หรือระบุ `-d <device>` เช่น `flutter run -d chrome`

**หมายเหตุเรื่องการเชื่อมต่อ backend:** แอปตั้งค่า base URL ให้อัตโนมัติตามแพลตฟอร์ม (`frontend/lib/services/api_client.dart`):
- Web / Windows / iOS simulator → `http://localhost:3000`
- Android emulator → `http://10.0.2.2:3000` (ตัว emulator เข้าถึง host เครื่องจริงผ่าน IP นี้เสมอ)
- ถ้ารันบนมือถือจริง (ไม่ใช่ emulator) ต้องแก้ `baseUrl` ให้ชี้ไป IP เครื่องที่รัน backend เอง

## ทดสอบ

```bash
cd frontend
flutter analyze --no-fatal-infos
flutter test
```

```bash
cd backend
npm run build
npm test          # unit test (test/*.spec.ts)
npm run test:e2e  # e2e test บน SQLite in-memory (test/*.e2e-spec.ts)
```

CI รันสองอย่างนี้บน GitHub Actions ทุก push/PR — ดู `.github/workflows/`.
