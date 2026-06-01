import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/services/health_sync_service.dart';
import '../../core/theme/app_theme.dart';

class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  bool _syncing = false;
  SyncResult? _lastResult;
  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('건강 앱 연동')),
      body: Column(
        children: [
          const Divider(
              height: 0.5, thickness: 0.5, color: AppTheme.separator),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _InfoCard(),
                  const SizedBox(height: 20),
                  if (_errorMsg != null) ...[
                    _ErrorCard(message: _errorMsg!),
                    const SizedBox(height: 16),
                  ],
                  if (_lastResult != null) ...[
                    _ResultCard(result: _lastResult!),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _syncing ? null : _startSync,
                      child: _syncing
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                ),
                                SizedBox(width: 10),
                                Text('가져오는 중...'),
                              ],
                            )
                          : const Text('러닝 데이터 가져오기'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '최근 90일 이내의 러닝 기록을 자동으로 가져옵니다.\n'
                    '1km / 5km / 10km / 하프 / 풀 마라톤 기록이 자동 생성됩니다.\n'
                    '중복 기록은 자동으로 제외됩니다.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSync() async {
    setState(() {
      _syncing = true;
      _errorMsg = null;
      _lastResult = null;
    });
    try {
      await healthSyncService.configure();

      // 권한 요청: 기능 진입 시 (앱 시작 직후 금지)
      final granted = await healthSyncService.requestPermission();
      if (!granted) {
        setState(() => _errorMsg =
            '건강 앱 접근 권한이 필요합니다.\n설정 앱 → 개인정보 보호 → 건강에서 PBPR 접근을 허용해주세요.');
        return;
      }

      final result = await healthSyncService.syncRunningWorkouts();
      setState(() => _lastResult = result);
    } catch (e) {
      setState(() => _errorMsg = '오류: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(CupertinoIcons.heart_fill,
                color: AppTheme.accent, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apple Health 연동',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('러닝 기록을 자동으로 가져옵니다',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SyncResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.checkmark_circle_fill,
                  color: Color(0xFF34C759), size: 18),
              SizedBox(width: 8),
              Text('가져오기 완료',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _StatRow(label: '새로 가져온 기록', value: '${result.imported}개'),
          if (result.skipped > 0)
            _StatRow(label: '중복 제외', value: '${result.skipped}개'),
          if (result.newPbs.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('🎉 새로운 PR',
                style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            ...result.newPbs.map((pb) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('• $pb',
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13)),
                )),
          ],
          if (result.imported == 0 && result.newPbs.isEmpty)
            const Text('새로 가져올 기록이 없습니다.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFFF3B30).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle,
              color: Color(0xFFFF3B30), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFFFF3B30), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
