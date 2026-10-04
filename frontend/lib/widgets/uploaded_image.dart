import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_radius.dart';
import '../theme/app_theme.dart';

/// รูปที่อัปโหลดไว้บน backend (path แบบ `/uploads/...`) หรือ URL เต็ม
class UploadedImage extends StatelessWidget {
  final String url;
  final double size;

  const UploadedImage({super.key, required this.url, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.network(
        ApiClient().resolveUrl(url),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: AppTheme.primLight(context),
          child: Icon(
            Icons.broken_image_outlined,
            color: AppTheme.prim(context),
          ),
        ),
      ),
    );
  }
}
