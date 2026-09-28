# Ansible — เตรียม VM สำหรับ deploy backend

Playbook นี้ตั้งค่า VM (Ubuntu/Debian) ให้รัน backend + monitoring และอัปเดตตัวเองจาก GHCR ด้วยคำสั่งเดียว รันซ้ำได้ (idempotent)

| Role | ทำอะไร |
|---|---|
| `docker` | ติดตั้ง Docker Engine + Compose plugin จาก apt repo ทางการของ Docker |
| `app_env` | สร้าง user `recipe-deploy` (group `docker`) และ `/opt/recipe-backend/.env` (mode `0600`) พร้อม `JWT_SECRET` และ `GRAFANA_ADMIN_PASSWORD` แบบสุ่ม — **ไม่ทับค่าเดิม** ถ้ามีอยู่แล้ว |
| `deploy_agent` | clone repo ไป `/opt/recipe-backend/repo`, ติดตั้ง `/usr/local/bin/recipe-deploy` และ systemd timer `recipe-deploy.timer` (fallback ทุก 1 ชั่วโมง) ที่ pull image จาก GHCR แล้ว `docker compose up` |
| `deploy_webhook` | webhook (`127.0.0.1:9000`) ที่ CI เรียกหลัง publish image เสร็จ → แตะไฟล์ `.deploy-request` → `recipe-deploy.path` สั่ง deploy ทันที; เปิดออกเน็ตผ่าน Tailscale Funnel (VM อยู่ใน network private) — ปิดด้วย `-e manage_deploy_webhook=false` |
| `firewall` | (ปิดไว้ default) เปิด ufw: SSH, 3000, 3001 — เปิดด้วย `-e manage_ufw=true` |

ทำไมไม่ใช้ self-hosted runner: repo เป็น public — PR จาก fork สามารถแก้ workflow ให้ไปรันบน runner ของเราได้ แบบ pull-based นี้ VM แค่ดึง image ที่ CI build จาก `main` (หลัง test ผ่าน) ไม่มีช่องทางให้ GitHub สั่งรันโค้ดบน VM — webhook แค่ "ขอให้ deploy" (request ต้องมีลายเซ็น HMAC-SHA256 จาก secret ที่ VM สุ่มสร้าง) ตัว VM ยังดึง `:latest` จาก GHCR เองเหมือนเดิม

## ต้องมี

- เครื่องที่รัน Ansible: Linux, macOS หรือ WSL (Windows ธรรมดารัน Ansible ไม่ได้) ติดตั้ง `pip install ansible-core`
- SSH เข้า VM ได้ด้วย key และ user นั้นมีสิทธิ์ `sudo`
- VM ออกอินเทอร์เน็ตไป `github.com`, `ghcr.io`, `download.docker.com`, `pkgs.tailscale.com` และ Docker Hub ได้
- Ubuntu 22.04+ หรือ Debian 12+ (แพ็กเกจ `webhook` ≥ 2.8)
- บัญชี Tailscale: เปิด HTTPS certificates (admin console → DNS) และอนุญาต Funnel ใน tailnet policy (`nodeAttrs` → `funnel`) แล้วสร้าง auth key (Settings → Keys)

## ใช้งาน

```bash
cd ansible
cp inventory.ini.example inventory.ini        # แก้ ansible_user
ansible-galaxy collection install -r requirements.yml
ssh <user>@172.30.58.15 exit                  # ครั้งแรก: ยอมรับ host key
ansible-playbook playbook.yml -K -e tailscale_authkey=tskey-auth-...   # ครั้งแรก; -K ถามรหัส sudo
ansible-playbook playbook.yml -K              # ครั้งต่อไป (VM ล็อกอิน Tailscale แล้ว)
```

ตอนจบ playbook จะแสดง URL ของ webhook (`https://recipe-vm.<tailnet>.ts.net/hooks/recipe-deploy`) — ตั้งเป็น GitHub secret สองตัว (repo → Settings → Secrets and variables → Actions):

| Secret | ค่า |
|---|---|
| `DEPLOY_WEBHOOK_URL` | URL ที่ playbook แสดง |
| `DEPLOY_WEBHOOK_SECRET` | ค่าหลัง `DEPLOY_WEBHOOK_SECRET=` ใน `sudo cat /opt/recipe-backend/webhook.env` บน VM |

ถ้ายังไม่ตั้ง secret, CI จะข้ามขั้นเรียก webhook และ VM จะ deploy ตาม timer fallback แทน

ดูค่า secret ที่ถูกสร้าง (บน VM): `sudo cat /opt/recipe-backend/.env`

ดูสถานะ deploy (บน VM):

```bash
systemctl list-timers recipe-deploy.timer
systemctl status recipe-webhook.service recipe-deploy.path
journalctl -u recipe-deploy.service -n 50
```

## ตรวจ

```bash
ansible-playbook -i inventory.ini.example playbook.yml --syntax-check
ansible-lint playbook.yml
```

CI รันสองคำสั่งนี้ทุกครั้งที่แก้ไฟล์ใน `ansible/` (`.github/workflows/ansible.yml`)
