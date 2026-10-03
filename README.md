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

ต้องมี [Node.js](https://nodejs.org/) (v20.17 ขึ้นไป แนะนำ v22)

```bash
cd backend
npm install
cp .env.example .env
npm run start:dev
```

Server จะรันที่ `http://localhost:3000` และสร้างไฟล์ฐานข้อมูล SQLite ที่ `backend/data/app.sqlite` อัตโนมัติ (seed สูตรอาหารตัวอย่าง 16 สูตรให้เองตอนบูตครั้งแรก)

**ต้องตั้ง `JWT_SECRET` ใน `backend/.env` ก่อน** (server ไม่ยอม start ถ้าว่าง) — วิธีสร้างค่าสุ่มและตัวแปรอื่น ๆ ดูที่ [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md#configuration)

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
- ถ้ารันบนมือถือจริง (ไม่ใช่ emulator) หรืออยากชี้ไป backend ที่ deploy แล้ว ไม่ต้องแก้โค้ด ระบุตอนรัน/build: `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000`

## ทดสอบ

```bash
cd frontend
dart format --output=none --set-exit-if-changed lib test   # ตรวจฟอร์แมต (แก้ให้: dart format lib test)
flutter analyze --no-fatal-infos
flutter test
```

```bash
cd backend
npm run lint
npm run format:check   # แก้ให้: npm run format
npm run build
npm test          # unit test (test/*.spec.ts)
npm run test:e2e  # e2e test บน SQLite in-memory (test/*.e2e-spec.ts)
```

CI รันทั้งหมดนี้บน GitHub Actions ทุก push/PR (รวม `npm audit`, build Docker image และ build APK) — ดู `.github/workflows/`.

> หมายเหตุ Windows: ถ้า path ของโปรเจกต์มีตัวอักษรที่ไม่ใช่ ASCII (เช่นภาษาไทย) `flutter analyze` และ `flutter build web` จะพัง — copy `frontend/` ไป path ภาษาอังกฤษก่อนรันสองคำสั่งนี้ (CI ไม่ได้รับผลกระทบ)

## เอกสารเพิ่มเติม

| ไฟล์ | เนื้อหา |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | โครงสร้าง backend/frontend และข้อตกลงในโค้ด |
| [`docs/DATABASE.md`](docs/DATABASE.md) | migration, วิธีแก้ schema, backup/restore |
| [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) | pipeline, ตัวแปร environment, health check, **rollback** |
| [`docs/SECURITY.md`](docs/SECURITY.md) | มาตรการที่มี และความเสี่ยงที่ยังเปิดอยู่ |
| [`docs/ENGINEERING_REPORT.md`](docs/ENGINEERING_REPORT.md) | สรุปการปรับปรุง ก่อน/หลัง และหนี้ทางเทคนิคที่เหลือ |
| [`ansible/README.md`](ansible/README.md) | เตรียม VM สำหรับ deploy |
