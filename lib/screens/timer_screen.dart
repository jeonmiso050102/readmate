import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 05 타이머
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late final int _total = context.read<ReadingState>().goalMinutes * 60;
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

  Future<void> _giveUp() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('정말 포기할까요?', style: AppText.bodyBold),
        content: Text('지금까지 읽은 ${_elapsedMinutes}분만 기록돼요.', style: AppText.bodySub),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('계속 읽기', style: AppText.label.copyWith(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('포기하기', style: AppText.label.copyWith(color: AppColors.subText)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _ticker?.cancel();
    context.read<ReadingState>().finishSession(minutes: _elapsedMinutes, completed: false);
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
      onPopInvoked: (didPop) {
        if (!didPop) _giveUp();
      },
      child: SunScaffold(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlineButtonX(label: '포기하기', onPressed: _giveUp),
            const SizedBox(height: 8),
            Text('포기하면 타이머가 멈추고 읽은 시간만 기록돼요', style: AppText.caption),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Text(book?.title ?? '', style: AppText.bodyBold),
            const SizedBox(height: 8),
            Text('${s.goalMinutes}분 목표', style: AppText.subLabel),
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
