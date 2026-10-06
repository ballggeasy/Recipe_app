/// ปุ่ม "ประเมินด้วย AI" ในหน้าสูตร และการโหลดรายการใหม่เพื่อรอผลประเมินจาก backend
///
/// ปิดไว้ก่อน: Cloudflare ของ ai.psu.blue บล็อกเซิร์ฟเวอร์ (Azure VM) จึงประเมินไม่สำเร็จ
/// เปิดตอน build ด้วย `--dart-define=AI_NUTRITION=true` เมื่อแก้ได้แล้ว
/// ไม่ใช่ const เพื่อให้ test เปิดได้ ค่าโภชนาการที่มีอยู่แล้ว (รวมค่าจาก AI) ยังแสดงตามปกติ
bool aiNutritionEnabled = const bool.fromEnvironment('AI_NUTRITION');
