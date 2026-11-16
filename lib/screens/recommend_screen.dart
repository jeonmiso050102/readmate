import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../services/recommend_service.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

const _levels = RecommendService.levelNames;

/// 11 AI 맞춤 추천
///
/// Gemini(Firebase AI Logic)가 독서 기록을 보고 책을 고르고,
/// Google Books API로 실제 있는 책인지 확인해 쪽수·표지를 채워요.
class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final _service = RecommendService();

  // 레벨별로 받아 둔 추천 (같은 레벨을 다시 누를 때 AI를 또 부르지 않게)
  final Map<int, List<RecommendedBook>> _cache = {};
  final Set<String> _added = {};
  bool _loading = false;
  String? _error;
  int? _loadingLevel;

  @override
  void initState() {
    super.initState();
    // AI 추천 탭을 열었을 때만 자동으로 추천 (다른 탭에 있을 땐 AI를 부르지 않음)
    shellTab.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    shellTab.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (shellTab.value == 2) _maybeLoad();
  }

  final Set<int> _checkedSaved = {}; // 저장된 추천을 이미 확인한 레벨
  bool _restoring = false;

  Future<void> _maybeLoad() async {
    if (!mounted || shellTab.value != 2) return;
    final s = context.read<ReadingState>();
    if (!s.aiEnabled || s.loading) return;
    final level = s.readerLevel;
    if (_cache.containsKey(level) || _loading || _restoring) return;

    // 1) 지난번 추천이 저장돼 있으면 바로 보여 주기
    if (_checkedSaved.add(level)) {
      _restoring = true;
      final saved = await _service.loadSaved(level);
      _restoring = false;
      if (!mounted) return;
      if (saved != null) {
        setState(() => _cache[level] = saved.books);
        // 하루가 지났으면 뒤에서 조용히 새로 받기 (그동안 지난 추천은 그대로 보임)
        if (saved.isStale) _load();
        return;
      }
    }
    // 2) 저장된 게 없으면 새로 받기
    _load();
  }

  Future<void> _load() async {
    final s = context.read<ReadingState>();
    final level = s.readerLevel;
    setState(() {
      _loading = true;
      _loadingLevel = level;
      _error = null;
    });
    try {
      final books = await _service.recommend(s);
      if (!mounted) return;
      setState(() => _cache[level] = books);
      _service.save(level, books);
    } on RecommendFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingLevel = null;
        });
        // 기다리는 동안 레벨을 바꿨다면 바뀐 레벨로 다시
        if (context.read<ReadingState>().readerLevel != level) _maybeLoad();
      }
    }
  }

  void _add(RecommendedBook r) {
    final color = AppColors.bookColors[r.title.hashCode.abs() % AppColors.bookColors.length];
    if (r.pageCount == null) {
      // 쪽수를 못 찾은 책은 제목만 채워서 직접 입력하게
      Navigator.of(context).pushNamed(
        Routes.addBook,
        arguments: Book(title: r.title, totalPages: 0, color: color),
      );
      return;
    }
    context.read<ReadingState>().addBook(title: r.title, totalPages: r.pageCount!, color: color);
    setState(() => _added.add(r.title));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${r.title}」을(를) 읽을 책 더미에 쌓았어요'),
        action: SnackBarAction(label: '보러 가기', onPressed: () => shellTab.value = 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    final list = _cache[s.readerLevel];
    final busy = _loading && _loadingLevel == s.readerLevel;
    // 이미 책 더미/책장에 있는 책은 숨김 (방금 「+」로 쌓은 책은 체크 표시로 남김)
    final owned = {...s.shelf, ...s.toRead}.map((b) => b.title).toSet();
    final visible = (list ?? const <RecommendedBook>[])
        .where((r) => _added.contains(r.title) || !owned.contains(r.title))
        .toList();
    // 탭이 보이는데 아직 추천이 없으면 (데이터 로딩이 끝난 직후 등) 한 번 불러오기
    if (shellTab.value == 2 && s.aiEnabled && !s.loading && list == null && !_loading && _error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoad());
    }

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
                  onChanged: (v) {
                    s.setAiEnabled(v);
                    if (v) WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoad());
                  },
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
            SegmentedPill(
              items: _levels,
              selected: s.readerLevel,
              onChanged: (i) {
                s.setReaderLevel(i);
                WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoad());
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text('${_levels[s.readerLevel]}에게 맞는 책', style: AppText.bodyBold),
                ),
                TextButton.icon(
                  onPressed: busy ? null : () => _load(),
                  icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                  label: Text('다시 추천받기',
                      style: AppText.label.copyWith(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (busy && visible.isEmpty)
              const _LoadingBox()
            else if (_error != null && visible.isEmpty)
              _ErrorBox(message: _error!, onRetry: () => _load())
            else ...[
              if (busy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                      ),
                      const SizedBox(width: 8),
                      Text('새싹이가 새 책을 고르는 중이에요…', style: AppText.caption),
                    ],
                  ),
                ),
              if (_error != null && !busy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_error!.split('\n').first,
                      style: AppText.caption.copyWith(color: Colors.redAccent)),
                ),
              for (final r in visible) ...[
                _RecoTile(reco: r, added: _added.contains(r.title), onAdd: () => _add(r)),
                const SizedBox(height: 10),
              ],
            ],
            const SizedBox(height: 4),
            Text(
              'AI가 내 독서 기록을 보고 고른 뒤, Google Books에서 실제로 있는 책인지 확인했어요.',
              style: AppText.caption,
            ),
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
              child: Text('로그아웃',
                  style: AppText.caption.copyWith(decoration: TextDecoration.underline)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Sprout(mood: SproutMood.basic, width: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('새싹이가 책을 고르는 중이에요', style: AppText.bodyBold),
                const SizedBox(height: 2),
                Text('실제로 있는 책인지도 확인하고 있어요', style: AppText.caption),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: AppColors.beige,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppText.body),
          const SizedBox(height: 8),
          OutlineButtonX(label: '다시 시도', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _RecoTile extends StatelessWidget {
  const _RecoTile({required this.reco, required this.added, required this.onAdd});
  final RecommendedBook reco;
  final bool added;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final fallbackColor =
        AppColors.bookColors[reco.title.hashCode.abs() % AppColors.bookColors.length];
    final cover = Container(
      width: 30,
      height: 44,
      decoration: BoxDecoration(color: fallbackColor, borderRadius: BorderRadius.circular(4)),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: reco.coverUrl == null
                ? cover
                : Image.network(
                    reco.coverUrl!,
                    width: 30,
                    height: 44,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    errorBuilder: (_, __, ___) => cover,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reco.title, style: AppText.label),
                const SizedBox(height: 1),
                Text(
                  [
                    if (reco.author.isNotEmpty) reco.author,
                    reco.pageCount != null ? '${reco.pageCount}쪽' : '쪽수 확인 필요',
                  ].join(' · '),
                  style: AppText.caption,
                ),
                if (reco.reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(reco.reason, style: AppText.caption.copyWith(color: AppColors.text)),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: added ? '쌓았어요' : '읽을 책에 추가',
            onPressed: added ? null : onAdd,
            icon: added
                ? const Icon(Icons.check, color: AppColors.green)
                : SvgPicture.asset('assets/svg/ic_plus.svg', width: 24, height: 24),
          ),
        ],
      ),
    );
  }
}
