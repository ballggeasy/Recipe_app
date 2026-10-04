import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/recipe.dart';
import 'recipe_text.dart';

Future<void> shareRecipe(BuildContext context, Recipe recipe) async {
  try {
    await Share.share(recipeDocument(recipe), subject: recipe.name);
  } catch (_) {
    if (context.mounted) {
      _show(context, 'แชร์สูตรไม่สำเร็จ');
    }
  }
}

/// ส่งสูตรเป็นไฟล์ข้อความผ่านแผงแชร์ เพื่อให้ผู้ใช้บันทึกลงเครื่อง
Future<void> downloadRecipe(BuildContext context, Recipe recipe) async {
  try {
    final safeName = recipe.name.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    await Share.shareXFiles(
      [
        XFile.fromData(
          utf8.encode(recipeDocument(recipe)),
          mimeType: 'text/plain',
          name: '$safeName.txt',
        ),
      ],
      subject: recipe.name,
      text: recipe.name,
    );
  } catch (_) {
    if (context.mounted) {
      _show(context, 'บันทึกสูตรไม่สำเร็จ');
    }
  }
}

Future<void> openRecipeVideo(BuildContext context, Recipe recipe) async {
  final uri = recipeVideoUri(recipe);
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _show(context, 'เปิดวิดีโอไม่สำเร็จ');
    }
  } catch (_) {
    if (context.mounted) {
      _show(context, 'เปิดวิดีโอไม่สำเร็จ');
    }
  }
}

void _show(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
