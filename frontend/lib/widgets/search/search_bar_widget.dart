import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/recipe_provider.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

class SearchBarWidget extends StatelessWidget {
  final String hint;
  final bool showHistory;
  final VoidCallback? onSubmitted;

  const SearchBarWidget({
    super.key,
    this.hint = 'ค้นหาเมนู, วัตถุดิบ, หมวดหมู่...',
    this.showHistory = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surf(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.div(context)),
            boxShadow: AppShadows.softFor(context),
          ),
          child: Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              provider.updateSearchQuery(textEditingValue.text);
              return provider.getAutocompleteSuggestions(textEditingValue.text);
            },
            onSelected: (selection) {
              provider.updateSearchQuery(selection);
              provider.addToSearchHistory(selection);
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: provider.updateSearchQuery,
                onSubmitted: (value) {
                  provider.addToSearchHistory(value);
                  onSubmitted?.call();
                },
                style: AppTypography.body(color: AppTheme.txtPrimary(context)),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTypography.body(color: AppTheme.txtSecondary(context)),
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.txtSecondary(context), size: 22),
                  suffixIcon: provider.searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'ล้างคำค้นหา',
                          icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.txtSecondary(context)),
                          onPressed: () {
                            controller.clear();
                            provider.clearSearch();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              );
            },
          ),
        ),
        if (showHistory && provider.searchHistory.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ...provider.searchHistory.map(
                (h) => ActionChip(
                  label: Text(h, style: AppTypography.caption(color: AppTheme.txtPrimary(context))),
                  avatar: Icon(Icons.history_rounded, size: 16, color: AppTheme.txtSecondary(context)),
                  backgroundColor: AppTheme.surfMuted(context),
                  side: BorderSide.none,
                  onPressed: () => provider.updateSearchQuery(h),
                ),
              ),
              ActionChip(
                label: Text('ล้างประวัติ', style: AppTypography.caption(color: AppTheme.txtSecondary(context))),
                backgroundColor: AppTheme.surfMuted(context),
                side: BorderSide.none,
                onPressed: provider.clearSearchHistory,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
