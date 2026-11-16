import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 05 타이머
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key, this.minutes});

  /// 04에서 고른 읽기 시간(분). 없으면 저장된 목표 시간
  final int? minutes;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late final int _total = (widget.minutes ?? context.read<ReadingState>().goalMinutes) * 60;
  late int _remaining = _total;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _complete();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int get _elapsedMinutes => ((_total - _remaining) / 60).floor();

  void _complete() {
    _ticker?.cancel();
    context.read<ReadingState>().finishSession(
          minutes: _total ~/ 60,
          completed: true,
        );
    Navigator.of(context).pushReplacementNamed(Routes.record);
  }

  /// 05 '다음에 읽기': 타이머를 멈추고 지금까지 읽은 시간만 기록
  Future<void> _giveUp() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('다음에 이어 읽을까요?', style: AppText.bodyBold),
        content: Text('타이머가 멈추고 지금까지 읽은 $_elapsedMinutes분만 기록돼요.',
            style: AppText.bodySub),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('계속 읽기', style: AppText.label.copyWith(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('다음에 읽기', style: AppText.label.copyWith(color: AppColors.subText)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _ticker?.cancel();
    final s = context.read<ReadingState>();
    s.finishSession(minutes: _elapsedMinutes, completed: false);
    final book = s.current;
    if (book != null && _elapsedMinutes > 0) {
      s.logSession(
        book: book,
        date: DateTime.now(),
        minutes: _elapsedMinutes,
        fromPage: book.currentPage,
        toPage: book.currentPage,
        manual: false,
      );
    }
    goHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    final book = s.current;
    final mm = (_remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_remaining % 60).toString().padLeft(2, '0');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _giveUp();
      },
      child: SunScaffold(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlineButtonX(label: '다음에 읽기', onPressed: _giveUp),
            const SizedBox(height: 8),
            Text('누르면 타이머가 멈추고 지금까지 읽은 시간만 기록돼요', style: AppText.caption),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Text(book?.title ?? '', style: AppText.bodyBold),
            const SizedBox(height: 8),
            Text('${_total ~/ 60}분 목표', style: AppText.subLabel),
            const SizedBox(height: 8),
            // 개발 중에는 시간을 길게 눌러 바로 완료할 수 있어요.
            GestureDetector(
              onLongPress: kDebugMode ? _complete : null,
              child: Text('$mm:$ss', style: AppText.timer),
            ),
            const SizedBox(height: 8),
            Text('남은 시간', style: AppText.subLabel),
            const SizedBox(height: 80),
            if (book != null)
              SizedBox(
                height: 192,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(left: 0, right: 0, top: 72, child: ProgressBook(book: book)),
                    const Positioned(
                      left: 0,
                      top: 40,
                      child: Sprout(mood: SproutMood.sleep, width: 74),
                    ),
                    const Positioned(
                      left: 62,
                      top: 0,
                      child: SpeechBubble(text: '조금 느려도 괜찮아'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
