import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

class _Reco {
  const _Reco(this.title, this.pages, this.reason, this.color);
  final String title;
  final int pages;
  final String reason;
  final Color color;
}

/// 레벨별 추천 목록 (AI 연동 전 샘플 데이터)
const _recos = <List<_Reco>>[
  [
    _Reco('작은 정원 일기', 152, '짧은 장으로 나뉘어 있어요', Color(0xFFC5CF9E)),
    _Reco('골목의 고양이들', 176, '쉬운 문장으로 읽혀요', Color(0xFFF9BDA6)),
    _Reco('아침의 편지', 128, '하루 한 편씩 읽기 좋아요', Color(0xFFA1B5DB)),
  ],
  [
    _Reco('여름 도서관', 312, '이야기가 빠르게 전개돼요', Color(0xFFD0ABC5)),
    _Reco('바다로 가는 기차', 268, '여행하듯 읽히는 장편이에요', Color(0xFFF7E4AF)),
    _Reco('오래된 레시피', 224, '에피소드마다 끝이 나요', Color(0xFFE1A2A5)),
  ],
  [
    _Reco('천 개의 지도', 486, '여러 인물의 시점이 교차해요', Color(0xFFA1B5DB)),
    _Reco('긴 겨울의 기록', 412, '깊이 있는 묘사가 많아요', Color(0xFFC5CF9E)),
    _Reco('시간의 서재', 538, '생각할 거리가 많은 책이에요', Color(0xFFD0ABC5)),
  ],
];

const _levels = ['초보자', '중급자', '고급자'];

/// 11 AI 맞춤 추천
class RecommendScreen extends StatelessWidget {
  const RecommendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    final list = _recos[s.readerLevel];
    return SunScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI 추천', style: AppText.title),
          const SizedBox(height: 14),
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI 추천 사용', style: AppText.bodyBold),
                      const SizedBox(height: 2),
                      Text('원하는 사람만 켜는 기능이에요', style: AppText.caption),
                    ],
                  ),
                ),
                Switch(
                  value: s.aiEnabled,
                  onChanged: s.setAiEnabled,
                  thumbColor: WidgetStateProperty.all(AppColors.card),
                  trackColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? AppColors.green
                        : AppColors.beige,
                  ),
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                ),
              ],
            ),
          ),
          if (s.aiEnabled) ...[
            const SizedBox(height: 14),
            Text('내 독서 레벨', style: AppText.bodyBold),
            const SizedBox(height: 14),
            SegmentedPill(items: _levels, selected: s.readerLevel, onChanged: s.setReaderLevel),
            const SizedBox(height: 14),
            Text('${_levels[s.readerLevel]}에게 맞는 책', style: AppText.bodyBold),
            const SizedBox(height: 14),
            for (final r in list) ...[
              _RecoTile(reco: r),
              const SizedBox(height: 10),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('AI 추천을 켜면 레벨에 맞는 책을 골라 드려요', style: AppText.bodySub),
              ),
            ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => context.read<AuthService>().signOut(),
              child: Text('로그아웃', style: AppText.caption.copyWith(decoration: TextDecoration.underline)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RecoTile extends StatelessWidget {
  const _RecoTile({required this.reco});
  final _Reco reco;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 44,
            decoration: BoxDecoration(color: reco.color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reco.title, style: AppText.label),
                const SizedBox(height: 1),
                Text('${reco.pages}쪽 · ${reco.reason}', style: AppText.caption),
              ],
            ),
          ),
          IconButton(
            tooltip: '읽을 책에 추가',
            onPressed: () {
              context.read<ReadingState>().addBook(
                    title: reco.title,
                    totalPages: reco.pages,
                    color: reco.color,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('「${reco.title}」을(를) 읽을 책 더미에 쌓았어요')),
              );
              shellTab.value = 1;
            },
            icon: SvgPicture.asset('assets/svg/ic_plus.svg', width: 24, height: 24),
          ),
        ],
      ),
    );
  }
}
