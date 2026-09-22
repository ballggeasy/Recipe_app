import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_button.dart';

/// โหมดทำอาหาร — แสดงขั้นตอนทีละสเต็ปด้วยตัวอักษรขนาดใหญ่ อ่านง่ายขณะทำอาหารจริง
class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookingModeScreen({super.key, required this.recipe});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.steps;
    final total = steps.length;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text(widget.recipe.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: total == 0
          ? Center(
              child: Text(
                'สูตรนี้ยังไม่มีขั้นตอนการทำ',
                style: AppTypography.body(color: AppTheme.txtSecondary(context)),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: Row(
                    children: List.generate(total, (i) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= _index ? AppTheme.prim(context) : AppTheme.div(context),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ขั้นตอน ${_index + 1} จาก $total',
                      style: AppTypography.caption(color: AppTheme.txtSecondary(context)),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: total,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.prim(context),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: AppTypography.h2(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              steps[i],
                              style: AppTypography.display(color: AppTheme.txtPrimary(context)).copyWith(fontSize: 24, height: 1.5),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: Row(
                      children: [
                        if (_index > 0)
                          Expanded(
                            child: AppButton.outline(
                              label: 'ก่อนหน้า',
                              onPressed: () => _controller.previousPage(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              ),
                            ),
                          ),
                        if (_index > 0) const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton.primary(
                            label: _index == total - 1 ? 'เสร็จสิ้น' : 'ขั้นตอนถัดไป',
                            icon: _index == total - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                            onPressed: () {
                              if (_index == total - 1) {
                                Navigator.pop(context);
                              } else {
                                _controller.nextPage(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
