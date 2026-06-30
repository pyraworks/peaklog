import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_icons.dart';
import '../l10n/app_localizations.dart';

class SwipeableRow extends StatefulWidget {
  final String id;
  final Widget child;
  final VoidCallback? onEdit;      // tap on row
  final VoidCallback? onSwipeEdit; // swipe action: edit button
  final VoidCallback? onShare;     // swipe action: share button
  final VoidCallback? onDelete;    // swipe action: delete button

  const SwipeableRow({
    required this.id,
    required this.child,
    this.onEdit,
    this.onSwipeEdit,
    this.onShare,
    this.onDelete,
    super.key,
  });

  @override
  State<SwipeableRow> createState() => _SwipeableRowState();
}

class _SwipeableRowState extends State<SwipeableRow> {
  static const _hintKey = 'swipe_hint_shown';

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) _maybeShowHint();
  }

  Future<void> _maybeShowHint() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_hintKey) == true) return;
    await prefs.setBool(_hintKey, true);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.swipeHint),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  double get _actionExtent {
    final count = (widget.onSwipeEdit != null ? 1 : 0) +
        (widget.onShare != null ? 1 : 0) +
        (widget.onDelete != null ? 1 : 0);
    return count * 0.19;
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: _actionExtent,
        children: [
          if (widget.onSwipeEdit != null)
            SlidableAction(
              onPressed: (_) => widget.onSwipeEdit!(),
              backgroundColor: AppColors.shareBlueBg,
              foregroundColor: AppColors.primary,
              icon: AppIcons.edit,
            ),
          if (widget.onShare != null)
            SlidableAction(
              onPressed: (_) => widget.onShare!(),
              backgroundColor: AppColors.shareBlueBg,
              foregroundColor: AppColors.shareBlue,
              icon: AppIcons.share,
            ),
          if (widget.onDelete != null)
            SlidableAction(
              onPressed: (_) => widget.onDelete!(),
              backgroundColor: AppColors.destructiveBg,
              foregroundColor: const Color(0xFFB91C1C),
              icon: AppIcons.delete,
            ),
        ],
      ),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: widget.child,
      ),
    );
  }
}
