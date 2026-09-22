import '../services/api_client.dart';

/// ข้อมูลผู้ใช้ที่ได้จาก backend API — รหัสผ่านไม่ถูกเก็บฝั่ง client อีกต่อไป
class AppUser {
  final String id;
  final String email;
  final String name;
  final String? profileImagePath;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.profileImagePath,
  });

  AppUser copyWith({
    String? name,
    String? profileImagePath,
  }) {
    return AppUser(
      id: id,
      email: email,
      name: name ?? this.name,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  /// map จาก response ของ backend (field ชื่อ profileImageUrl)
  /// path ที่ backend ส่งมาเป็น relative (เช่น /uploads/avatars/xxx.jpg) ต้องต่อ baseUrl ก่อนใช้แสดงผล
  factory AppUser.fromApi(Map<String, dynamic> json) {
    final rawPath = json['profileImageUrl'] as String?;
    final resolvedPath = (rawPath != null && rawPath.startsWith('/'))
        ? '${ApiClient().baseUrl}$rawPath'
        : rawPath;

    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      profileImagePath: resolvedPath,
    );
  }
}
