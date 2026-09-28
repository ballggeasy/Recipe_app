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
    (SortOption.nameAsc, 'ชื่อ A-Z'),
    (SortOption.nameDesc, 'ชื่อ Z-A'),
    (SortOption.ratingDesc, 'คะแนนสูงสุด'),
    (SortOption.timeAsc, 'เวลาน้อยสุด'),
    (SortOption.timeDesc, 'เวลามากสุด'),
    (SortOption.newest, 'ล่าสุด'),
    (SortOption.popular, 'ยอดนิยม'),
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
