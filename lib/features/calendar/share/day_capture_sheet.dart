import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_radius.dart';
import '../../../l10n/app_localizations.dart';

/// Capture-confirmation bottom sheet: shows the already-generated PNG and
/// lets the user explicitly Save it, or dismiss without saving. This is
/// intentionally the only place that writes the image to Photos — nothing
/// saves automatically when the sheet is shown.
class DayCaptureSheet extends StatefulWidget {
  final Uint8List imageBytes;
  final String fileNamePrefix;
  const DayCaptureSheet({
    required this.imageBytes,
    required this.fileNamePrefix,
    super.key,
  });

  /// Shows the sheet over the current screen. Never saves on its own.
  /// [fileNamePrefix] names the saved file — "peaklog_day_share_" or
  /// "peaklog_month_share_" depending on which capture produced [imageBytes].
  static Future<void> show(
    BuildContext context,
    Uint8List imageBytes, {
    required String fileNamePrefix,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          DayCaptureSheet(imageBytes: imageBytes, fileNamePrefix: fileNamePrefix),
    );
  }

  @override
  State<DayCaptureSheet> createState() => _DayCaptureSheetState();
}

class _DayCaptureSheetState extends State<DayCaptureSheet> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/${widget.fileNamePrefix}${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(widget.imageBytes);
      await Gal.putImage(path, album: 'PeakLog');
      // The in-sheet "Saved" button state is the single source of
      // save-success feedback — no snackbar here. (A Scaffold-anchored
      // SnackBar queued while this sheet is open can end up hidden behind
      // it and only appear once the sheet is dismissed, which reads as a
      // second, redundant confirmation.)
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) _showSnack(l10n.saveFailed(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 12, 0),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(AppIcons.close, color: AppColors.label2),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _SheetButton(
                        label: l10n.cancel,
                        secondary: true,
                        onTap: _saving ? null : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SheetButton(
                        label: _saved ? l10n.savedToPhotos : l10n.save,
                        icon: _saved ? AppIcons.check : null,
                        loading: _saving,
                        success: _saved,
                        onTap: _saving || _saved ? null : _save,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool secondary;
  final bool loading;
  final IconData? icon;
  /// Completed/positive state (e.g. after a successful save) — styled as
  /// clearly affirmative, not as a grayed-out disabled button, even though
  /// [onTap] is null while in this state.
  final bool success;

  const _SheetButton({
    required this.label,
    required this.onTap,
    this.secondary = false,
    this.loading = false,
    this.icon,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    // Save-completion uses PeakLog's existing dark primary treatment, not
    // a separate success color — same tokens as the button's own normal
    // enabled (primary) state.
    final bg = success
        ? AppColors.actionDark
        : secondary
            ? AppColors.card
            : AppColors.actionDark;
    final border = success
        ? AppColors.actionDarkBorder
        : secondary
            ? AppColors.separator
            : AppColors.actionDarkBorder;
    final fg = success
        ? Colors.white
        : secondary
            ? (enabled ? AppColors.label1 : AppColors.label2)
            : (enabled ? Colors.white : AppColors.label2);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: border),
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
