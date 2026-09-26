# Recipe App Backend (NestJS)

Backend เต็มรูปแบบสำหรับแอป: Auth, สูตรอาหาร (CRUD), favorites/folders, reviews, comments (nested), meal planner — แทนที่ mock data/SharedPreferences ทั้งหมดฝั่ง Flutter.

## Run

```bash
npm install
cp .env.example .env
npm run build
npm start
```

Dev mode (auto-reload):

```bash
npm run start:dev
```

Server default: `http://localhost:3000`, DB: SQLite ไฟล์ที่ `./data/app.sqlite` (auto-create).

## Endpoints

| Method | Path                  | Auth | Body                                    |
|--------|-----------------------|------|------------------------------------------|
| POST   | /auth/register         | -    | `{ name, email, password }`              |
| POST   | /auth/login             | -    | `{ email, password }`                    |
| GET    | /auth/exists/:email     | -    | -                                         |
| POST   | /auth/reset-password    | -    | `{ email, newPassword }`                 |
| GET    | /auth/me                 | JWT  | -                                         |
| PATCH  | /auth/profile            | JWT  | `{ name?, profileImageUrl? }`            |
| POST   | /auth/avatar              | JWT  | multipart/form-data field `file` (JPG/PNG/WebP/GIF, ≤5MB) |
| POST   | /auth/change-password    | JWT  | `{ currentPassword, newPassword }`       |
| DELETE | /auth/account             | JWT  | -                                         |

### Recipes

| Method | Path              | Auth | Body/หมายเหตุ                                         |
|--------|-------------------|------|--------------------------------------------------------|
| GET    | /recipes           | -    | รายการทั้งหมด (16 สูตร seed ครั้งแรกที่บูต)              |
| GET    | /recipes/:id       | -    | -                                                        |
| POST   | /recipes           | JWT  | สร้างสูตรใหม่ (isOfficial=false, uploaderId=ผู้สร้าง)     |
| PATCH  | /recipes/:id       | JWT  | แก้ได้เฉพาะสูตรที่ตัวเองอัปโหลด (403 ถ้าไม่ใช่เจ้าของ)      |
| POST   | /recipes/:id/image | JWT  | multipart/form-data field `file` (JPG/PNG/WebP/GIF, ≤5MB) — ตั้งเป็นรูปเมนูแทนรูปเดิม, เฉพาะเจ้าของ, คืนสูตรที่อัปเดตแล้ว |
| DELETE | /recipes/:id       | JWT  | ลบได้เฉพาะสูตรที่ตัวเองอัปโหลด                            |

### Favorites & Folders

| Method | Path                                | Auth | หมายเหตุ                          |
|--------|-------------------------------------|------|-------------------------------------|
| GET    | /favorites                           | JWT  | คืน `string[]` ของ recipeId          |
| POST   | /favorites/:recipeId                 | JWT  | เพิ่ม favorite (idempotent)          |
| DELETE | /favorites/:recipeId                 | JWT  | เอาออกจาก favorite                   |
| GET    | /folders                             | JWT  | โฟลเดอร์ของผู้ใช้                     |
| POST   | /folders                             | JWT  | `{ name, emoji? }`                   |
| DELETE | /folders/:id                         | JWT  | ต้องเป็นเจ้าของโฟลเดอร์                |
| POST   | /folders/:id/recipes/:recipeId       | JWT  | เพิ่มสูตรเข้าโฟลเดอร์                  |
| DELETE | /folders/:id/recipes/:recipeId       | JWT  | เอาสูตรออกจากโฟลเดอร์                 |

### Reviews

| Method | Path                          | Auth | หมายเหตุ                                                  |
|--------|-------------------------------|------|--------------------------------------------------------------|
| GET    | /recipes/:recipeId/reviews    | -    | -                                                              |
| POST   | /recipes/:recipeId/reviews    | JWT  | `{ rating, content, imageUrls? }` — อัปเดต recipe.rating/reviewCount อัตโนมัติ |
| POST   | /reviews/:id/like              | JWT  | toggle like (เก็บ `likedByUserIds`, client คำนวณ isLiked เอง) |
| POST   | /reviews/:id/report             | JWT  | -                                                              |
| POST   | /reviews/:id/replies            | JWT  | `{ content }`                                                  |

### Comments (nested)

| Method | Path                            | Auth | หมายเหตุ                                    |
|--------|----------------------------------|------|------------------------------------------------|
| GET    | /recipes/:recipeId/comments      | -    | คืนเป็น tree (nested `replies`) พร้อมใช้        |
| POST   | /recipes/:recipeId/comments      | JWT  | `{ content, parentId?, mentions?, imageUrl? }`  |
| DELETE | /comments/:id                     | JWT  | เฉพาะเจ้าของ, ลบ reply ที่ซ้อนอยู่ข้างใต้ทั้งหมดด้วย (cascade) |

### Meal Planner

| Method | Path             | Auth | Body                                                          |
|--------|------------------|------|------------------------------------------------------------------|
| GET    | /meal-plan        | JWT  | รายการของผู้ใช้ทั้งหมด                                            |
| POST   | /meal-plan        | JWT  | `{ recipeId, date (ISO8601), mealType: breakfast/lunch/dinner/snack, servings? }` |
| DELETE | /meal-plan/:id    | JWT  | เฉพาะเจ้าของ                                                      |

`register`/`login` คืน `{ accessToken, user }` — ส่ง `Authorization: Bearer <accessToken>` สำหรับ endpoint ที่ต้อง JWT.

รหัสผ่าน hash ด้วย bcrypt (แทน SHA-256 ฝั่ง client เดิม).

รูปโปรไฟล์และรูปเมนูเก็บที่ `./uploads/avatars/` และ `./uploads/recipes/` (เปลี่ยนโฟลเดอร์ได้ด้วย env `UPLOADS_DIR`) เสิร์ฟผ่าน `/uploads/...` แบบ static. อัปโหลดใหม่จะลบไฟล์เก่าทิ้งอัตโนมัติ, ลบสูตรก็ลบรูปของสูตรนั้นด้วย. นามสกุลไฟล์ตั้งจาก MIME type ไม่ใช่ชื่อไฟล์ที่ client ส่งมา (ไม่รับ SVG) และจะไม่ลบไฟล์ที่อยู่นอกโฟลเดอร์ uploads เด็ดขาด. URL ที่คืนมาเป็น path relative (`/uploads/...`) — client ต่อ base URL เอง.

เมื่อ DB ว่าง (บูตครั้งแรก) จะ seed สูตรอาหาร 16 สูตรพร้อมรีวิว/คอมเมนต์ตัวอย่าง จาก `src/seed/seed-data.ts` อัตโนมัติ.
