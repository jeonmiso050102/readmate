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
  late final Set<DeskProp> _props = {...context.read<ReadingState>().placedDeskProps};

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    return SunScaffold(
      bottom: PrimaryButton(
        label: '저장하기',
        onPressed: () {
          s.placeDecoration(_selected);
          s.setDeskProps(_props);
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
          if (_target == 0) ...[
            const SizedBox(height: 20),
            Text('책상 소품', style: AppText.bodyBold),
            const SizedBox(height: 2),
            Text('책을 다 읽을수록 하나씩 열려요. 여러 개를 함께 놓을 수 있어요.', style: AppText.caption),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final p in DeskProp.values) ...[
                  if (p != DeskProp.values.first) const SizedBox(width: 10),
                  Expanded(
                    child: _PropTile(
                      prop: p,
                      unlocked: s.isDeskPropUnlocked(p),
                      remaining: (p.unlockBooks - s.shelf.length).clamp(0, 999).toInt(),
                      placed: _props.contains(p),
                      onTap: () => setState(() {
                        if (!_props.remove(p)) _props.add(p);
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ],
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

/// 책상 소품 칸: 잠김(완독 N권 남음) / 보유 / 놓는 중
class _PropTile extends StatelessWidget {
  const _PropTile({
    required this.prop,
    required this.unlocked,
    required this.remaining,
    required this.placed,
    required this.onTap,
  });
  final DeskProp prop;
  final bool unlocked;
  final int remaining;
  final bool placed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = !unlocked ? '완독 $remaining권 더 읽으면 열려요' : (placed ? '놓는 중' : '보유');
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: placed ? AppColors.primary : Colors.transparent, width: 2),
          boxShadow: AppColors.softShadow(0.7),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: unlocked ? 1 : 0.35,
                  child: SvgPicture.asset(prop.asset, height: 64),
                ),
                if (!unlocked) const Icon(Icons.lock_outline, color: AppColors.subText, size: 26),
              ],
            ),
            const SizedBox(height: 6),
            Text(prop.label, style: AppText.label),
            const SizedBox(height: 2),
            Text(
              status,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: placed ? AppColors.primary : AppColors.subText),
            ),
          ],
        ),
      ),
    );
  }
}
