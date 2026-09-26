import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recipe_app/services/api_client.dart';

typedef RouteHandler = http.Response Function(http.Request request);

/// ApiClient ที่ตอบจาก [routes] แทนการยิง network จริง
/// key ของ route คือ `'METHOD /path'` เช่น `'GET /recipes'` — route ที่ไม่ได้กำหนดจะตอบ 404
/// ถ้าส่ง [log] มา ทุก request จะถูกเก็บไว้ให้ test ตรวจสอบภายหลัง
ApiClient fakeApi(Map<String, RouteHandler> routes, {List<http.Request>? log}) {
  return ApiClient.forTesting(MockClient((request) async {
    log?.add(request);
    final handler = routes['${request.method} ${request.url.path}'];
    if (handler == null) return jsonResponse({'message': 'no route'}, 404);
    return handler(request);
  }));
}

/// response JSON แบบ UTF-8 (จำเป็นเพราะข้อความ error จาก backend เป็นภาษาไทย)
http.Response jsonResponse(Object? body, [int status = 200]) => http.Response(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// JSON ของสูตรอาหารตามรูปแบบที่ backend ส่งมา — override เฉพาะ field ที่ test สนใจ
Map<String, dynamic> recipeJson({
  String id = 'r1',
  String name = 'ผัดกะเพรา',
  String category = 'อาหารจานเดียว',
  String country = 'ไทย',
  int cookTimeMinutes = 15,
  int prepTimeMinutes = 10,
  String difficulty = 'ง่าย',
  num rating = 4.5,
  int reviewCount = 12,
  bool isOfficial = true,
  List<String> ingredients = const ['หมูสับ', 'ใบกะเพรา'],
  String createdAt = '2026-01-01T00:00:00.000Z',
  int viewCount = 0,
}) =>
    {
      'id': id,
      'name': name,
      'emoji': '🍛',
      'imageUrl': '',
      'category': category,
      'country': country,
      'cookTimeMinutes': cookTimeMinutes,
      'prepTimeMinutes': prepTimeMinutes,
      'difficulty': difficulty,
      'ingredients': ingredients,
      'steps': ['ผัด'],
      'isOfficial': isOfficial,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt,
      'viewCount': viewCount,
    };
