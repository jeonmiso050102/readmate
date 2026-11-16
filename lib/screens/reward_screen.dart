import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 07 목표 달성 보상
class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    final reward = s.lastReward ?? ShelfDeco.pot;
    final next = s.nextGoalMinutes;
    final diff = next - s.goalMinutes;
    return SunScaffold(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: '책장에 놓기',
            onPressed: () {
              s.applyNextGoal();
              s.placeDecoration(reward);
              Navigator.of(context).pushReplacementNamed(Routes.decorate);
            },
          ),
          const SizedBox(height: 12),
          GhostButton(
            label: '나중에 놓기',
            onPressed: () {
              s.applyNextGoal();
              goHome(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Sprout(mood: SproutMood.happy, width: 192),
          const SizedBox(height: 12),
          Text('목표 달성!', style: AppText.title),
          const SizedBox(height: 12),
          Text(
            '${s.lastSessionMinutes}분을 끝까지 읽어서 책장 장식을 얻었어요',
            style: AppText.bodySub,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              children: [
                SvgPicture.asset(reward.asset, width: 62, height: 62),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.label, style: AppText.bodyBold),
                    const SizedBox(height: 2),
                    Text('책장에 놓을 수 있어요', style: AppText.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.beige,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: Text('다음 목표', style: AppText.label)),
                Text(
                  '$next분 (${diff >= 0 ? '+' : ''}$diff분)',
                  style: AppText.bodyBold.copyWith(color: AppColors.primary),
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
