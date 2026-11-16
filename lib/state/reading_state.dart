import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Book {
  Book({
    this.id = '',
    required this.title,
    required this.totalPages,
    required this.color,
    this.currentPage = 0,
    this.memo = '',
    this.summary = '',
    this.isDone = false,
    this.createdAt = 0,
    this.finishedAt = 0,
  });

  final String id; // Firestore 문서 ID (users/{uid}/books/{id})
  String title;
  int totalPages;
  Color color;
  int currentPage;
  String memo;
  String summary;
  bool isDone; // 책장에 꽂힌(완독) 책인지
  int createdAt;
  int finishedAt;

  double get progress => totalPages == 0 ? 0 : (currentPage / totalPages).clamp(0.0, 1.0);
  int get percent => (progress * 100).round();
  bool get isStarted => currentPage > 0;
  bool get isFinished => currentPage >= totalPages;

  factory Book.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Book(
      id: doc.id,
      title: d['title'] as String? ?? '',
      totalPages: (d['totalPages'] as num?)?.toInt() ?? 0,
      color: Color((d['color'] as num?)?.toInt() ?? AppColors.bookColors[0].toARGB32()),
      currentPage: (d['currentPage'] as num?)?.toInt() ?? 0,
      memo: d['memo'] as String? ?? '',
      summary: d['summary'] as String? ?? '',
      isDone: d['status'] == 'done',
      createdAt: (d['createdAt'] as num?)?.toInt() ?? 0,
      finishedAt: (d['finishedAt'] as num?)?.toInt() ?? 0,
    );
  }
}

enum ShelfDeco { pot, frame, lamp }

extension ShelfDecoInfo on ShelfDeco {
  String get label => switch (this) {
        ShelfDeco.pot => '작은 화분',
        ShelfDeco.frame => '액자',
        ShelfDeco.lamp => '조명',
      };
  String get asset => switch (this) {
        ShelfDeco.pot => 'assets/svg/deco_pot.svg',
        ShelfDeco.frame => 'assets/svg/deco_frame.svg',
        ShelfDeco.lamp => 'assets/svg/deco_lamp.svg',
      };
}

/// 로그인한 사용자의 독서 데이터를 Firestore와 동기화
///
/// - 책: `users/{uid}/books/{bookId}`
/// - 설정(목표 시간, 장식, 현재 책 등): `users/{uid}` 문서의 `settings` 필드
///
/// 새 사용자는 책장·읽을 책 더미가 모두 빈 상태로 시작합니다.
class ReadingState extends ChangeNotifier {
  ReadingState({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance {
    _authSub = _auth.authStateChanges().listen(_onUserChanged);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _booksSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  String? _uid;

  bool loading = true;
  List<Book> _books = [];

  // ---- 설정 (Firestore에 저장) ----
  String? _currentId;
  int goalMinutes = 15;
  int nextGoalMinutes = 25;
  Set<ShelfDeco> ownedDecorations = {};
  ShelfDeco? placedDecoration;
  bool aiEnabled = true;
  int readerLevel = 0; // 0 초보자, 1 중급자, 2 고급자

  // ---- 이번 세션 (저장 안 함) ----
  int lastSessionMinutes = 0;
  bool lastSessionCompleted = false;
  ShelfDeco? lastReward;

  /// 읽을 책 더미 (추가한 순서, index 0 = 맨 위)
  List<Book> get toRead => _books.where((b) => !b.isDone).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// 책장 (완독한 순서)
  List<Book> get shelf => _books.where((b) => b.isDone).toList()
    ..sort((a, b) => a.finishedAt.compareTo(b.finishedAt));

  /// 지금 읽는 책: 직접 고른 책, 없으면 더미 맨 위 책
  Book? get current {
    final list = toRead;
    for (final b in list) {
      if (b.id == _currentId) return b;
    }
    return list.isEmpty ? null : list.first;
  }

  bool isCurrent(Book b) => current?.id == b.id;

  // ---------------------------------------------------------------- 동기화

  DocumentReference<Map<String, dynamic>> get _userDoc => _db.collection('users').doc(_uid);
  CollectionReference<Map<String, dynamic>> get _booksCol => _userDoc.collection('books');
  CollectionReference<Map<String, dynamic>> get _sessionsCol => _userDoc.collection('sessions');

  void _onUserChanged(User? user) {
    _booksSub?.cancel();
    _userSub?.cancel();
    _resetLocal();
    _uid = user?.uid;
    if (user == null) {
      loading = false;
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();

    _booksSub = _booksCol.snapshots().listen((snap) {
      _books = snap.docs.map(Book.fromDoc).toList();
      loading = false;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('책 목록을 불러오지 못했어요: $e');
      loading = false;
      notifyListeners();
    });

    _userSub = _userDoc.snapshots().listen((snap) {
      final s = (snap.data()?['settings'] as Map<String, dynamic>?) ?? const {};
      _currentId = s['currentBookId'] as String?;
      goalMinutes = (s['goalMinutes'] as num?)?.toInt() ?? 15;
      nextGoalMinutes = (s['nextGoalMinutes'] as num?)?.toInt() ?? goalMinutes + 10;
      ownedDecorations = ((s['ownedDecorations'] as List?) ?? const [])
          .map((n) => ShelfDeco.values.where((d) => d.name == n).firstOrNull)
          .whereType<ShelfDeco>()
          .toSet();
      final placed = s['placedDecoration'] as String?;
      placedDecoration = ShelfDeco.values.where((d) => d.name == placed).firstOrNull;
      aiEnabled = s['aiEnabled'] as bool? ?? true;
      readerLevel = (s['readerLevel'] as num?)?.toInt() ?? 0;
      notifyListeners();
    }, onError: (Object e) => debugPrint('설정을 불러오지 못했어요: $e'));
  }

  void _resetLocal() {
    _books = [];
    _currentId = null;
    goalMinutes = 15;
    nextGoalMinutes = 25;
    ownedDecorations = {};
    placedDecoration = null;
    aiEnabled = true;
    readerLevel = 0;
    lastSessionMinutes = 0;
    lastSessionCompleted = false;
    lastReward = null;
  }

  Future<void> _saveSettings() async {
    if (_uid == null) return;
    await _userDoc.set({
      'settings': {
        'currentBookId': _currentId,
        'goalMinutes': goalMinutes,
        'nextGoalMinutes': nextGoalMinutes,
        'ownedDecorations': ownedDecorations.map((d) => d.name).toList(),
        'placedDecoration': placedDecoration?.name,
        'aiEnabled': aiEnabled,
        'readerLevel': readerLevel,
      },
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _booksSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- 책

  Future<void> addBook({required String title, required int totalPages, required Color color}) async {
    if (_uid == null) return;
    await _booksCol.add({
      'title': title,
      'totalPages': totalPages,
      'color': color.toARGB32(),
      'currentPage': 0,
      'memo': '',
      'summary': '',
      'status': 'toRead',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'finishedAt': 0,
    });
  }

  /// 책 정보 수정 (제목, 총 쪽수, 표지 색, 읽은 쪽수, 메모)
  Future<void> updateBook(
    Book book, {
    String? title,
    int? totalPages,
    Color? color,
    int? currentPage,
    String? memo,
  }) async {
    if (_uid == null || book.id.isEmpty) return;
    await _booksCol.doc(book.id).update({
      if (title != null) 'title': title,
      if (totalPages != null) 'totalPages': totalPages,
      if (color != null) 'color': color.toARGB32(),
      if (currentPage != null) 'currentPage': currentPage,
      if (memo != null) 'memo': memo,
    });
  }

  Future<void> deleteBook(Book book) async {
    if (_uid == null || book.id.isEmpty) return;
    if (_currentId == book.id) {
      _currentId = null;
      await _saveSettings();
    }
    await _booksCol.doc(book.id).delete();
  }

  void selectBook(Book book) {
    _currentId = book.id;
    notifyListeners();
    _saveSettings();
  }

  // ---------------------------------------------------------------- 독서 흐름

  void setGoal(int minutes) {
    goalMinutes = minutes;
    notifyListeners();
    _saveSettings();
  }

  void adjustNextGoal(int delta) {
    nextGoalMinutes = (nextGoalMinutes + delta).clamp(5, 180);
    notifyListeners();
    _saveSettings();
  }

  /// 타이머 종료(완료 또는 포기)
  void finishSession({required int minutes, required bool completed}) {
    lastSessionMinutes = minutes;
    lastSessionCompleted = completed;
    notifyListeners();
  }

  /// 독서 기록 한 건 저장 (`users/{uid}/sessions`) — 타이머 기록과 수동 기록 모두
  Future<void> logSession({
    required Book book,
    required DateTime date,
    required int minutes,
    required int fromPage,
    required int toPage,
    required bool manual,
  }) async {
    if (_uid == null || book.id.isEmpty) return;
    await _sessionsCol.add({
      'bookId': book.id,
      'bookTitle': book.title,
      'date': DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
      'minutes': minutes,
      'fromPage': fromPage,
      'toPage': toPage,
      'manual': manual,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 12 수동으로 기록하기: 진도 반영 + 기록 저장 (책장 장식 보상은 없음)
  Future<void> recordManual({
    required Book book,
    required DateTime date,
    required int minutes,
    required int toPage,
  }) async {
    final from = book.currentPage;
    final to = toPage.clamp(0, book.totalPages);
    logSession(book: book, date: date, minutes: minutes, fromPage: from, toPage: to, manual: true);
    await updateBook(book, currentPage: to);
  }

  /// 06 독서 기록 저장
  Future<void> recordProgress({required int page, required String memo}) async {
    final book = current;
    if (book == null) return;
    logSession(
      book: book,
      date: DateTime.now(),
      minutes: lastSessionMinutes,
      fromPage: book.currentPage,
      toPage: page.clamp(0, book.totalPages),
      manual: false,
    );
    if (lastSessionCompleted) {
      lastReward = ShelfDeco.pot;
      ownedDecorations.add(ShelfDeco.pot);
      _saveSettings();
    }
    await updateBook(
      book,
      currentPage: page.clamp(0, book.totalPages),
      memo: memo.trim().isEmpty ? null : memo.trim(),
    );
  }

  /// 07 보상 후 다음 목표 적용
  void applyNextGoal() {
    goalMinutes = nextGoalMinutes;
    nextGoalMinutes = goalMinutes + 10;
    notifyListeners();
    _saveSettings();
  }

  /// 09 완독 → 책장에 꽂기
  Future<void> shelveCurrent() async {
    final book = current;
    if (book != null) await shelveBook(book);
  }

  Future<void> shelveBook(Book book) async {
    if (_uid == null || book.id.isEmpty) return;
    final next = toRead.where((b) => b.id != book.id).firstOrNull;
    _currentId = next?.id;
    _saveSettings();
    await _booksCol.doc(book.id).update({
      'status': 'done',
      'currentPage': book.totalPages,
      'finishedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void placeDecoration(ShelfDeco? d) {
    placedDecoration = d;
    notifyListeners();
    _saveSettings();
  }

  void setAiEnabled(bool v) {
    aiEnabled = v;
    notifyListeners();
    _saveSettings();
  }

  void setReaderLevel(int v) {
    readerLevel = v;
    notifyListeners();
    _saveSettings();
  }
}
