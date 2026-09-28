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
| POST   | /auth/forgot-password   | -    | `{ email }` — สร้างรหัสยืนยัน 6 หลัก (ยังไม่ส่งอีเมล: รหัสแสดงใน log ของ backend) ตอบเหมือนกันเสมอไม่ว่ามีบัญชีหรือไม่ |
| POST   | /auth/reset-password    | -    | `{ email, code, newPassword }` — รหัสใช้ได้ 15 นาที เดาผิดได้รวม 5 ครั้งต่อช่วง |
| GET    | /auth/me                 | JWT  | -                                         |
| PATCH  | /auth/profile            | JWT  | `{ name? }` (เปลี่ยนรูปผ่าน /auth/avatar เท่านั้น) |
| POST   | /auth/avatar              | JWT  | multipart/form-data field `file` (JPG/PNG/WebP/GIF, ≤5MB) |
| POST   | /auth/change-password    | JWT  | `{ currentPassword, newPassword }`       |
| DELETE | /auth/account             | JWT  | -                                         |

### Recipes

| Method | Path              | Auth | Body/หมายเหตุ                                         |
|--------|-------------------|------|--------------------------------------------------------|
| GET    | /recipes           | -    | รายการทั้งหมด (16 สูตร seed ครั้งแรกที่บูต)              |
| GET    | /recipes/:id       | -    | -                                                        |
| POST   | /recipes           | JWT  | สร้างสูตรใหม่ (isOfficial=false, isRecommended=false, uploaderId=ผู้สร้าง) |
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
| POST   | /recipes/:recipeId/reviews    | JWT  | `{ rating, content, imageUrls? }` — ผู้ใช้ 1 คนมี 1 รีวิวต่อสูตร (ส่งซ้ำ = แก้รีวิวเดิม), อัปเดต recipe.rating/reviewCount อัตโนมัติ |
| POST   | /reviews/:id/like              | JWT  | toggle like (เก็บ `likedByUserIds`, client คำนวณ isLiked เอง) |
| POST   | /reviews/:id/report             | JWT  | -                                                              |
| POST   | /reviews/:id/replies            | JWT  | `{ content }`                                                  |

### Comments (nested)

| Method | Path                            | Auth | หมายเหตุ                                    |
|--------|----------------------------------|------|------------------------------------------------|
| GET    | /recipes/:recipeId/comments      | -    | คืนเป็น tree (nested `replies`) พร้อมใช้        |
| POST   | /recipes/:recipeId/comments      | JWT  | `{ content, parentId?, mentions?, imageUrl? }` — parentId ต้องเป็นคอมเมนต์ของสูตรเดียวกัน |
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

## Deploy (Docker บน VM)

แบบ **pull-based + webhook** — GitHub ทำได้แค่ขอให้ VM deploy ผ่าน webhook ที่มีลายเซ็น ไม่มีสิทธิ์รันคำสั่งบน VM (repo เป็น public จึงไม่ใช้ self-hosted runner):

1. push เข้า `main` → CI (`.github/workflows/backend.yml`) รัน build + test บน runner ของ GitHub
2. ผ่านแล้ว job `publish` build image, smoke test (`/recipes`, `/metrics`) แล้ว push ขึ้น `ghcr.io/ballggeasy/recipe-backend` (tag `latest` + `sha-<commit>`)
3. ขั้นสุดท้ายของ job `publish` ยิง `POST` ที่มีลายเซ็น HMAC-SHA256 ไปที่ webhook บน VM (ผ่าน Tailscale Funnel) → hook แตะไฟล์ `/opt/recipe-backend/.deploy-request` → `recipe-deploy.path` สั่ง `recipe-deploy.service` รัน `/usr/local/bin/recipe-deploy` ทันที:
   pull image → checkout commit เดียวกับ image (label `org.opencontainers.image.revision`) เพื่อใช้ compose/monitoring config ที่ตรงกัน → `docker compose up -d` → reload Prometheus → smoke test `GET /recipes`
   ถ้า smoke test ไม่ผ่านจะไม่บันทึกว่า deploy แล้ว และลองใหม่รอบถัดไป (ไม่มี auto-rollback — แก้โดย push commit ที่แก้แล้ว)
4. ถ้าเรียก webhook ไม่สำเร็จ (VM ปิด, tunnel ล่ม, ยังไม่ตั้ง secret) CI ไม่ fail — systemd timer `recipe-deploy.timer` บน VM เช็ก GHCR ทุก 1 ชั่วโมงเป็น fallback

ตั้งค่า VM ด้วย Ansible playbook ใน [`../ansible`](../ansible/README.md) (Docker, deploy user, env file ที่มี secret สุ่ม, timer).

**ครั้งแรกครั้งเดียว:** หลัง CI publish image แรก ให้ตั้ง package เป็น public — GitHub → Profile → Packages → `recipe-backend` → Package settings → Change visibility → Public (VM pull แบบไม่ login). ไม่มี secret ใน image; โค้ดเป็น public อยู่แล้ว.

ดูสถานะบน VM:

```bash
systemctl list-timers recipe-deploy.timer
systemctl status recipe-webhook.service recipe-deploy.path
journalctl -u recipe-deploy.service -n 50
cat /opt/recipe-backend/.deployed-revision
```

ตั้ง `HOST_PORT` / `GRAFANA_PORT` ใน `/opt/recipe-backend/.env` ถ้าต้องการ port อื่น (default 3000 / 3001).

ข้อมูลเก็บใน Docker volume `recipe-backend_data` (SQLite) และ `recipe-backend_uploads` (รูปที่อัปโหลด) — ไม่หายตอน redeploy.

Backup:

```bash
docker run --rm -v recipe-backend_data:/d -v "$PWD":/b alpine tar czf /b/data-backup.tgz -C /d .
```

รันแบบเดียวกันบนเครื่องตัวเอง: `docker compose up -d --build` (อ่าน `./.env` — ต้องมี `GRAFANA_ADMIN_PASSWORD` ด้วย ดู `.env.example`). `node-exporter` ใช้ได้เฉพาะ host Linux.

### Monitoring (Prometheus + Grafana)

compose เดียวกันรัน monitoring stack ด้วย:

| Service | เข้าถึง | หน้าที่ |
|---|---|---|
| backend `/metrics` | `http://<vm>:3000/metrics` | metrics ของ Node process + `http_requests_total`, `http_request_duration_seconds` (label: method, route pattern, status) |
| Grafana | `http://<vm>:3001` (user `admin`, รหัสจาก `GRAFANA_ADMIN_PASSWORD`) | dashboard **Recipe App → Recipe Backend** (provision อัตโนมัติ) |
| Prometheus | `127.0.0.1:9090` บน VM เท่านั้น — ใช้ `ssh -L 9090:localhost:9090 <user>@<vm>` | เก็บ metrics 15 วัน |
| node-exporter | ภายใน network ของ compose | CPU / RAM / disk ของ VM |

เปลี่ยน port Grafana ด้วย `GRAFANA_PORT` ในไฟล์ env. แก้ `monitoring/prometheus/prometheus.yml` หรือ dashboard JSON แล้ว push — VM จะ reload Prometheus ตอน deploy และ Grafana โหลด dashboard ใหม่เองภายใน 30 วินาที.
