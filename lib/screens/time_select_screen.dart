import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 04 읽기 시간 선택
class TimeSelectScreen extends StatefulWidget {
  const TimeSelectScreen({super.key});

  @override
  State<TimeSelectScreen> createState() => _TimeSelectScreenState();
}

class _TimeSelectScreenState extends State<TimeSelectScreen> {
  // 누르는 즉시 화면에 반영되도록 이 화면에서 직접 들고 있음
  late int _minutes = context.read<ReadingState>().goalMinutes;

  void _pick(int m) {
    setState(() => _minutes = m);
    context.read<ReadingState>().setGoal(m);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    final book = s.current;
    final presets = <int>{5, 10, 15, _minutes}.toList()..sort();
    return SunScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: '타이머 시작',
            onPressed: () => Navigator.of(context).pushNamed(Routes.timer, arguments: _minutes),
          ),
          const SizedBox(height: 16),
          GhostButton(
            label: '타이머를 못 켰나요? 수동으로 기록하기',
            onPressed: () => Navigator.of(context).pushNamed(Routes.manualRecord),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopBar(
            title: book == null ? '읽기 시간' : '${book.title} · ${book.currentPage + 1}쪽부터',
          ),
          const SizedBox(height: 16),
          Text('오늘은 몇 분 읽을까요?', style: AppText.title),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < presets.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _TimeChip(
                    minutes: presets[i],
                    selected: presets[i] == _minutes,
                    onTap: () => _pick(presets[i]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // 지금 읽을 시간 (바로 타이머에 들어가는 시간)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.sun.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('지금 읽을 시간', style: AppText.subLabel),
                      const SizedBox(height: 2),
                      Text(
                        '타이머가 ${_minutes.toString().padLeft(2, '0')}:00부터 시작해요',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                Text('$_minutes분', style: AppText.title.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SproutWithBubble(text: '짧게라도 매일 읽자!', sproutWidth: 96),
          const SizedBox(height: 28),
          // 다음 목표 (이번 목표를 달성한 뒤에 적용)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('다음 목표', style: AppText.bodyBold),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.beige,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('이번 목표를 달성한 뒤에 적용', style: AppText.caption),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('지금 목표에서 10분씩 늘려 직접 정해요.', style: AppText.bodySub),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _RoundButton(label: '−', onTap: () => s.adjustNextGoal(-10)),
                    Expanded(
                      child: Center(child: Text('${s.nextGoalMinutes}분', style: AppText.heading)),
                    ),
                    _RoundButton(label: '+', onTap: () => s.adjustNextGoal(10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.minutes, required this.selected, required this.onTap});
  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.sun : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Text('$minutes', style: AppText.title),
            const SizedBox(height: 2),
            Text('분', style: AppText.subLabel),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.beige,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: Text(label, style: AppText.heading)),
        ),
      ),
    );
  }
}
