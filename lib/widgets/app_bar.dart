import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Global Deep Navy app bar.
/// By default shows a hamburger icon on the left.
/// Pass [showBack] = true to show a back arrow instead (for secondary screens).
class ShiftSnapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final bool showBack;

  const ShiftSnapAppBar({
    super.key,
    this.onMenuTap,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.surface),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : IconButton(
              icon: const Icon(Icons.menu, color: AppColors.surface),
              onPressed: onMenuTap,
            ),
      centerTitle: true,
      title: const Text('ShiftSnap', style: AppTextStyles.header),
    );
  }
}