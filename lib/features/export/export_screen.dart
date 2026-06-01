import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/unit_settings_provider.dart';
import 'clean_frame.dart';
import 'rough_frame.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final Exercise exercise;
  final double newValue;
  final DateTime date;

  const ExportScreen({
    required this.exercise,
    required this.newValue,
    required this.date,
    super.key,
  });

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  int _selectedStyle = 0;
  bool _exporting = false;
  final _cleanKey = GlobalKey();
  final _roughKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    final weightUnit = settings?.weightUnit ?? 'kg';
    final distanceUnit = settings?.distanceUnit ?? 'km';
    final date = widget.date;

    final frames = [
      RepaintBoundary(
        key: _cleanKey,
        child: CleanFrame(
          exercise: widget.exercise,
          valueInMetric: widget.newValue,
          weightUnit: weightUnit,
          distanceUnit: distanceUnit,
          date: date,
        ),
      ),
      RepaintBoundary(
        key: _roughKey,
        child: RoughFrame(
          exercise: widget.exercise,
          valueInMetric: widget.newValue,
          weightUnit: weightUnit,
          distanceUnit: distanceUnit,
          date: date,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('공유하기')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: frames[_selectedStyle],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _StyleButton(
                  label: 'CLEAN',
                  selected: _selectedStyle == 0,
                  onTap: () => setState(() => _selectedStyle = 0),
                ),
                const SizedBox(width: 12),
                _StyleButton(
                  label: 'ROUGH',
                  selected: _selectedStyle == 1,
                  onTap: () => setState(() => _selectedStyle = 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: ElevatedButton.icon(
              onPressed: _exporting ? null : _share,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.share),
              label: const Text('공유 / 저장'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share() async {
    setState(() => _exporting = true);
    try {
      final key = _selectedStyle == 0 ? _cleanKey : _roughKey;
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/pbpr_share.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'PBPR - ${widget.exercise.displayName} 신기록!',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _StyleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StyleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accent : AppTheme.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
