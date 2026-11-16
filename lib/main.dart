import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/add_book_screen.dart';
import 'screens/decorate_screen.dart';
import 'screens/finished_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/manual_done_screen.dart';
import 'screens/manual_record_screen.dart';
import 'screens/recap_screen.dart';
import 'screens/record_screen.dart';
import 'screens/reward_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/time_select_screen.dart';
import 'screens/timer_screen.dart';
import 'services/auth_service.dart';
import 'state/reading_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ReadMateApp());
}

class Routes {
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home'; // 01 / 03 / 11 탭
  static const addBook = '/add-book'; // 02 (arguments: Book이면 수정 모드)
  static const timeSelect = '/time-select'; // 04
  static const timer = '/timer'; // 05
  static const record = '/record'; // 06
  static const reward = '/reward'; // 07
  static const recap = '/recap'; // 08
  static const finished = '/finished'; // 09 (arguments: Book, 없으면 지금 읽는 책)
  static const decorate = '/decorate'; // 10
  static const manualRecord = '/manual-record'; // 12
  static const manualDone = '/manual-done'; // 13 (arguments: ManualRecordResult)
}

class ReadMateApp extends StatelessWidget {
  const ReadMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<ReadingState>(create: (_) => ReadingState()),
      ],
      child: MaterialApp(
        title: '리드메이트',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // 날짜 선택 창 등을 한국어로
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AuthGate(),
        routes: {
          Routes.login: (_) => const LoginScreen(),
          Routes.signup: (_) => const SignupScreen(),
          Routes.home: (_) => const MainShell(),
          Routes.addBook: (ctx) => AddBookScreen(
                editing: ModalRoute.of(ctx)?.settings.arguments as Book?,
              ),
          Routes.timeSelect: (_) => const TimeSelectScreen(),
          Routes.timer: (_) => const TimerScreen(),
          Routes.record: (_) => const RecordScreen(),
          Routes.reward: (_) => const RewardScreen(),
          Routes.recap: (_) => const RecapScreen(),
          Routes.finished: (_) => const FinishedScreen(),
          Routes.decorate: (_) => const DecorateScreen(),
          Routes.manualRecord: (_) => const ManualRecordScreen(),
          Routes.manualDone: (_) => const ManualDoneScreen(),
        },
      ),
    );
  }
}

/// 로그인 상태에 따라 로그인 화면 또는 홈(책장)을 보여 줌
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: context.read<AuthService>().authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        return snap.data == null ? const LoginScreen() : const MainShell();
      },
    );
  }
}

/// 어디서든 홈(책장 탭)으로 돌아가기
void goHome(BuildContext context, {int tab = 0}) {
  shellTab.value = tab;
  Navigator.of(context).popUntil((r) => r.isFirst);
}
