import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 10 책장 꾸미기
class DecorateScreen extends StatefulWidget {
  const DecorateScreen({super.key});

  @override
  State<DecorateScreen> createState() => _DecorateScreenState();
}

class _DecorateScreenState extends State<DecorateScreen> {
  int _target = 0; // 0 책장, 1 캐릭터
  late ShelfDeco? _selected = context.read<ReadingState>().placedDecoration;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    return SunScaffold(
      bottom: PrimaryButton(
        label: '저장하기',
        onPressed: () {
          s.placeDecoration(_selected);
          goHome(context);
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TopBar(title: '책장 꾸미기'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21),
            child: CharacterShelf(books: s.shelf, decoration: _selected),
          ),
          const SizedBox(height: 12),
          SegmentedPill(
            items: const ['책장', '캐릭터'],
            selected: _target,
            onChanged: (i) => setState(() => _target = i),
          ),
          const SizedBox(height: 12),
          if (_target == 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('캐릭터 꾸미기는 곧 열려요!', style: AppText.bodySub)),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final d in ShelfDeco.values) ...[
                  if (d != ShelfDeco.values.first) const SizedBox(width: 10),
                  Expanded(child: _DecoTile(
                    deco: d,
                    owned: s.ownedDecorations.contains(d),
                    selected: _selected == d,
                    onTap: () => setState(() => _selected = _selected == d ? null : d),
                  )),
                ],
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DecoTile extends StatelessWidget {
  const _DecoTile({
    required this.deco,
    required this.owned,
    required this.selected,
    required this.onTap,
  });
  final ShelfDeco deco;
  final bool owned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = selected ? '놓는 중' : (owned ? '보유' : '잠김');
    return GestureDetector(
      onTap: owned ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Opacity(
          opacity: owned ? 1 : 0.5,
          child: Column(
            children: [
              SvgPicture.asset(deco.asset, width: 48, height: 48),
              const SizedBox(height: 4),
              Text(deco.label, style: AppText.label),
              const SizedBox(height: 4),
              Text(
                status,
                style: AppText.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.subText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
