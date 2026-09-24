/// ค่าคงที่ที่ใช้ทั่วแอป
class AppConstants {
  static const difficulties = ['ง่าย', 'ปานกลาง', 'ยาก'];

  static const dietTags = [
    'สุขภาพ',
    'คลีน',
    'คีโต',
    'วีแกน',
    'มังสวิรัติ',
    'ฮาลาล',
    'เด็ก',
    'ผู้สูงอายุ',
    'เบาหวาน',
    'ลดน้ำหนัก',
  ];

  static const seasons = ['ตลอดปี', 'ฤดูร้อน', 'ฤดูหนาว', 'ฤดูฝน'];

  static const sortOptions = [
    ('name_asc', 'ชื่อ A-Z'),
    ('name_desc', 'ชื่อ Z-A'),
    ('rating_desc', 'คะแนนสูงสุด'),
    ('time_asc', 'เวลาน้อยสุด'),
    ('time_desc', 'เวลามากสุด'),
    ('newest', 'ล่าสุด'),
    ('popular', 'ยอดนิยม'),
  ];

  static const homeSections = [
    ('latest', 'ล่าสุด', '🆕'),
    ('popular', 'ยอดนิยม', '🔥'),
    ('recommended', 'แนะนำ', '⭐'),
    ('random', 'สุ่ม', '🎲'),
    ('seasonal', 'ตามฤดูกาล', '🍂'),
  ];

  static const maxSearchHistory = 10;
}

enum RecipeListMode {
  all,
  latest,
  popular,
  recommended,
  random,
  seasonal,
  diet,
}

enum SortOption {
  nameAsc,
  nameDesc,
  ratingDesc,
  timeAsc,
  timeDesc,
  newest,
  popular,
}

enum SourceFilter { all, official, user }

enum SearchMode { all, name, ingredient, category, country, time, difficulty }
