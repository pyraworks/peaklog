import 'package:flutter/material.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_icons.dart';
import '../core/design/app_typography.dart';

class ScreenHeader extends StatelessWidget {
  final String backLabel;
  final String? title;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final Widget? trailing;

  const ScreenHeader({
    required this.backLabel,
    this.title,
    this.titleWidget,
    this.onBack,
    this.trailing,
    super.key,
  }) : assert(title != null || titleWidget != null,
            'Either title or titleWidget must be provided');

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onBack ?? () => Navigator.of(context).pop(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.back,
                              size: 18,
                              color: AppColors.label1,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              backLabel,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w400,
                                color: AppColors.label1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: titleWidget ??
                        Text(
                          title!,
                          style: AppTypography.pageTitle.copyWith(
                            color: AppColors.label1,
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.separator),
        ],
      ),
    );
  }
}
