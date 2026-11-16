import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../state/reading_state.dart';

/// AI가 추천하고 Google Books로 확인을 마친 책
class RecommendedBook {
  const RecommendedBook({
    required this.title,
    required this.author,
    required this.reason,
    this.pageCount,
    this.coverUrl,
  });

  final String title;
  final String author;
  final String reason;
  final int? pageCount; // Google Books에 쪽수가 없으면 null
  final String? coverUrl;

  Map<String, dynamic> toMap() => {
        'title': title,
        'author': author,
        'reason': reason,
        'pageCount': pageCount,
        'coverUrl': coverUrl,
      };

  factory RecommendedBook.fromMap(Map m) => RecommendedBook(
        title: (m['title'] ?? '').toString(),
        author: (m['author'] ?? '').toString(),
        reason: (m['reason'] ?? '').toString(),
        pageCount: (m['pageCount'] as num?)?.toInt(),
        coverUrl: m['coverUrl'] as String?,
      );
}

/// 저장해 둔 추천 (레벨별)
class SavedRecommendation {
  const SavedRecommendation(this.books, this.createdAt);
  final List<RecommendedBook> books;
  final DateTime createdAt;

  /// 하루가 지나면 새로 추천
  bool get isStale => DateTime.now().difference(createdAt) > const Duration(hours: 24);
}

class RecommendFailure implements Exception {
  RecommendFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 1) Gemini(Firebase AI Logic)가 독서 기록을 보고 후보 책을 고르고
/// 2) Google Books API로 실제 있는 책인지 확인해 쪽수·표지를 채움
class RecommendService {
  RecommendService({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static const levelNames = ['초보자', '중급자', '고급자'];

  static final _config = GenerationConfig(
    temperature: 0.9,
    responseMimeType: 'application/json',
    responseSchema: Schema.object(properties: {
      'books': Schema.array(
        items: Schema.object(properties: {
          'title': Schema.string(description: '한국어판 정식 제목 (부제 제외)'),
          'author': Schema.string(description: '저자 이름 (한국어 표기)'),
          'reason': Schema.string(description: '이 사용자에게 맞는 이유, 30자 이내'),
        }),
      ),
    }),
  );

  GenerativeModel _modelOf(String name) =>
      FirebaseAI.googleAI().generativeModel(model: name, generationConfig: _config);

  /// 빠른 가벼운 모델(flash-lite)을 먼저 쓰고, 바쁘거나 늦으면 기본 모델로 다시 시도
  Future<GenerateContentResponse> _generate(String prompt) async {
    final attempts = [kGeminiFallbackModel, kGeminiModel, kGeminiFallbackModel];
    Object? lastError;
    for (var i = 0; i < attempts.length; i++) {
      try {
        return await _modelOf(attempts[i])
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 20));
      } catch (e) {
        lastError = e;
        final low = e.toString().toLowerCase();
        final retryable = e is TimeoutException ||
            low.contains('503') ||
            low.contains('unavailable') ||
            low.contains('deadline') ||
            low.contains('overloaded') ||
            low.contains('500');
        debugPrint('Gemini ${attempts[i]} 실패 (${i + 1}번째 시도): $e');
        if (!retryable) rethrow;
        await Future<void>.delayed(Duration(seconds: 1 + i * 2));
      }
    }
    throw lastError!;
  }

  /// [count]권을 추천. 후보를 넉넉히 받아 확인에 실패한 책은 버림
  Future<List<RecommendedBook>> recommend(ReadingState s, {int count = 3}) async {
    final candidates = await _askAi(s, candidates: count + 3);

    // 이미 책장/더미에 있는 책은 제외
    final owned = {...s.shelf, ...s.toRead}.map((b) => _norm(b.title)).toSet();
    final fresh = candidates.where((c) => !owned.contains(_norm(c.title))).toList();

    // Google Books로 동시에 확인
    final checked = await Future.wait(fresh.map(_verify));
    final verified = checked.whereType<RecommendedBook>().toList()
      // 쪽수까지 확인된 책을 앞으로
      ..sort((a, b) => (a.pageCount == null ? 1 : 0).compareTo(b.pageCount == null ? 1 : 0));

    if (verified.isEmpty) {
      throw RecommendFailure('추천할 책을 확인하지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
    return verified.take(count).toList();
  }

  // ------------------------------------------------------- 저장 (Firestore)

  DocumentReference<Map<String, dynamic>>? get _savedDoc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('meta').doc('recommendations');
  }

  /// 지난번에 받은 추천 불러오기 (바로 보여 주기용)
  Future<SavedRecommendation?> loadSaved(int level) async {
    try {
      final snap = await _savedDoc?.get();
      final m = snap?.data()?['level$level'];
      if (m is! Map) return null;
      final books = [for (final b in (m['books'] as List? ?? const [])) RecommendedBook.fromMap(b as Map)];
      if (books.isEmpty) return null;
      return SavedRecommendation(
        books,
        DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num?)?.toInt() ?? 0),
      );
    } catch (e) {
      debugPrint('저장된 추천을 불러오지 못했어요: $e');
      return null;
    }
  }

  Future<void> save(int level, List<RecommendedBook> books) async {
    try {
      await _savedDoc?.set({
        'level$level': {
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'books': books.map((b) => b.toMap()).toList(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('추천을 저장하지 못했어요: $e');
    }
  }

  // ------------------------------------------------------------------ Gemini

  Future<List<({String title, String author, String reason})>> _askAi(
    ReadingState s, {
    required int candidates,
  }) async {
    String list(Iterable<Book> books) => books.isEmpty
        ? '없음'
        : books.map((b) => '- ${b.title} (${b.totalPages}쪽, ${b.percent}% 읽음)').join('\n');

    final prompt = '''
너는 한국 독서 습관 앱 "리드메이트"의 책 추천 도우미야.
아래 사용자의 독서 기록을 보고, 이 사람이 **끝까지 읽기 좋은** 책을 $candidates권 추천해 줘.

[사용자 정보]
- 독서 레벨: ${levelNames[s.readerLevel]}
- 한 번에 읽는 목표 시간: ${s.goalMinutes}분
- 다 읽은 책:
${list(s.shelf)}
- 읽고 있거나 읽으려고 쌓아 둔 책:
${list(s.toRead)}

[규칙]
- 반드시 한국에서 실제로 출간된 책만 추천해. 지어내지 마.
- title에는 한국어판 정식 제목만, author에는 저자 이름만 적어.
- 위 목록에 이미 있는 책은 추천하지 마.
- 레벨 기준: 초보자는 300쪽 이하에 문장이 쉽고 장이 짧은 책, 중급자는 200~400쪽, 고급자는 분량과 깊이가 있는 책.
- 다 읽은 책의 분야와 분위기를 참고하되, 서로 다른 책을 섞어서 골라.
- reason은 "이 사용자에게" 왜 맞는지 25자 이내로, 친근한 존댓말로 써.
- 설명 없이 JSON만 답해.
''';

    try {
      final res = await _generate(prompt);
      final text = res.text;
      if (text == null || text.isEmpty) throw RecommendFailure('AI가 빈 답을 보냈어요.');
      final data = jsonDecode(text) as Map<String, dynamic>;
      return [
        for (final b in (data['books'] as List? ?? const []))
          if (b is Map && (b['title'] ?? '').toString().trim().isNotEmpty)
            (
              title: b['title'].toString().trim(),
              author: (b['author'] ?? '').toString().trim(),
              reason: (b['reason'] ?? '').toString().trim(),
            ),
      ];
    } on RecommendFailure {
      rethrow;
    } catch (e) {
      debugPrint('Gemini 호출 실패: $e');
      throw RecommendFailure(_aiErrorMessage(e));
    }
  }

  /// 자주 나는 오류를 알아보기 쉬운 안내로 바꿈 (개발 중에는 원래 오류도 함께 표시)
  static String _aiErrorMessage(Object e) {
    final raw = e.toString();
    final low = raw.toLowerCase();
    String msg;
    if (low.contains('app check')) {
      msg = 'App Check 때문에 막혔어요.\nFirebase 콘솔 → App Check → API 탭에서 Firebase AI Logic을 '
          '「적용 해제」했는지 확인해 주세요. 바꾼 뒤 반영까지 최대 15분 걸릴 수 있어요.';
    } else if (low.contains('not found') || low.contains('404') || low.contains('is not supported')) {
      msg = 'AI 모델($kGeminiModel)을 찾지 못했어요.\nlib/config/api_keys.dart의 kGeminiModel을 확인해 주세요.';
    } else if (low.contains('503') || low.contains('unavailable') || low.contains('deadline')) {
      msg = 'AI 서버가 지금 바빠서 답이 늦었어요. 잠시 후 「다시 시도」를 눌러 주세요.';
    } else if (low.contains('quota') || low.contains('429') || low.contains('resource_exhausted')) {
      msg = 'AI 사용량이 잠시 초과됐어요. 1~2분 뒤 다시 시도해 주세요.';
    } else if (low.contains('api has not been used') || low.contains('disabled') ||
        low.contains('permission')) {
      msg = 'Firebase AI Logic이 아직 켜지지 않았어요.\nFirebase 콘솔 → AI Logic에서 '
          'Gemini Developer API 설정을 끝까지 진행해 주세요.';
    } else {
      msg = 'AI 추천을 불러오지 못했어요.';
    }
    if (kDebugMode) msg += '\n\n(개발용 오류 내용: ${raw.length > 300 ? raw.substring(0, 300) : raw})';
    return msg;
  }

  // ------------------------------------------------------------ Google Books

  Future<RecommendedBook?> _verify(({String title, String author, String reason}) c) async {
    final q = StringBuffer('intitle:${c.title}');
    if (c.author.isNotEmpty) q.write(' inauthor:${c.author}');
    final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', {
      'q': q.toString(),
      'maxResults': '5',
      'printType': 'books',
      if (kGoogleBooksApiKey.isNotEmpty) 'key': kGoogleBooksApiKey,
    });
    try {
      final res = await _http.get(uri);
      if (res.statusCode != 200) {
        debugPrint('Google Books ${res.statusCode}: ${res.body}');
        if (res.statusCode == 429) {
          throw RecommendFailure(kGoogleBooksApiKey.isEmpty
              ? 'Google Books 사용량이 초과됐어요.\nlib/config/api_keys.dart에 API 키를 넣고 앱을 다시 시작(R)해 주세요.'
              : 'Google Books 사용량이 잠시 초과됐어요. 1분 뒤 다시 시도해 주세요.');
        }
        if (res.statusCode == 403 || res.statusCode == 400) {
          throw RecommendFailure(
            'Google Books API 키를 쓸 수 없어요.\nGoogle Cloud 콘솔에서 Books API를 「사용」으로 켰는지, '
            '키의 제한사항에 Books API와 localhost가 들어 있는지 확인해 주세요.'
            '${kDebugMode ? '\n\n(개발용 오류 내용: ${res.body.length > 300 ? res.body.substring(0, 300) : res.body})' : ''}',
          );
        }
        return null;
      }
      final items = (jsonDecode(res.body)['items'] as List?) ?? const [];
      Map<String, dynamic>? best;
      for (final it in items) {
        final v = (it as Map)['volumeInfo'] as Map<String, dynamic>? ?? const {};
        if (!_sameTitle(v['title']?.toString() ?? '', c.title)) continue;
        // 쪽수가 있는 판을 우선 (Google Books는 쪽수를 모르면 0을 주기도 함)
        final has = ((v['pageCount'] as num?) ?? 0) > 0;
        final bestHas = ((best?['pageCount'] as num?) ?? 0) > 0;
        if (best == null || (!bestHas && has)) best = v;
      }
      if (best == null) return null; // 실제 책을 찾지 못함 → 버림

      final authors = (best['authors'] as List?)?.join(', ');
      final thumb = (best['imageLinks'] as Map?)?['thumbnail']?.toString();
      return RecommendedBook(
        title: c.title,
        author: (authors == null || authors.isEmpty) ? c.author : authors,
        reason: c.reason,
        pageCount: ((best['pageCount'] as num?) ?? 0) > 0 ? (best['pageCount'] as num).toInt() : null,
        coverUrl: thumb?.replaceFirst('http://', 'https://'),
      );
    } on RecommendFailure {
      rethrow;
    } catch (e) {
      debugPrint('Google Books 확인 실패 (${c.title}): $e');
      return null;
    }
  }

  static String _norm(String s) =>
      s.replaceAll(RegExp(r'[\s\p{P}\p{S}]', unicode: true), '').toLowerCase();

  /// 부제/판차 표기가 붙어도 같은 책으로 봄
  static bool _sameTitle(String found, String wanted) {
    final a = _norm(found);
    final b = _norm(wanted);
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.startsWith(b) || b.startsWith(a);
  }
}
