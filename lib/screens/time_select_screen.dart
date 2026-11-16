import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 04 읽기 시간 선택
class TimeSelectScreen extends StatelessWidget {
  const TimeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    final book = s.current;
    final presets = <int>{5, 10, 15, s.goalMinutes}.toList()..sort();
    return SunScaffold(
      bottom: PrimaryButton(
        label: '타이머 시작',
        onPressed: () => Navigator.of(context).pushNamed(Routes.timer),
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
                Expanded(child: _TimeChip(minutes: presets[i], selected: presets[i] == s.goalMinutes)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('목표를 달성한 뒤에는', style: AppText.bodyBold),
                const SizedBox(height: 10),
                Text('지금 목표에서 10분씩 늘려 직접 정해요.', style: AppText.bodySub),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _RoundButton(label: '−', onTap: () => s.adjustNextGoal(-10)),
                    Expanded(
                      child: Center(child: Text('${s.nextGoalMinutes}분', style: AppText.title)),
                    ),
                    _RoundButton(label: '+', onTap: () => s.adjustNextGoal(10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SproutWithBubble(text: '짧게라도 매일 읽자!', sproutWidth: 96),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.minutes, required this.selected});
  final int minutes;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<ReadingState>().setGoal(minutes),
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
