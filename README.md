# 리드메이트 (ReadMate) — Flutter 앱

Figma 시안 「리드메이트 완독 습관 앱 화면 시안」의 13개 화면(로그인·회원가입 포함)을 Flutter로 구현한 프로젝트입니다.
인증은 **Firebase 이메일/비밀번호**를 사용합니다.

## 1. 실행 방법

```bash
cd readmate
flutter create . --org com.readmate --platforms android,ios,web   # 플랫폼 폴더 생성 (lib/는 그대로 유지됨)
flutter pub get

# Firebase 연결
dart pub global activate flutterfire_cli
flutterfire configure            # lib/firebase_options.dart 자동 생성(자리표시자 덮어쓰기)

flutter run
```

Firebase 콘솔에서 할 일:
1. **Authentication → 로그인 방법 → 이메일/비밀번호** 사용 설정
2. **Firestore Database** 생성 후 아래 규칙 적용
   - `users/{uid}`: 닉네임, 설정(목표 시간·장식·현재 책)
   - `users/{uid}/books/{bookId}`: 책 제목, 총 쪽수, 표지 색, 읽은 쪽수, 메모, 상태(toRead/done)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 내 프로필·설정(users/{uid})과 내 책(users/{uid}/books/...)만 읽고 쓸 수 있음
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

> 개발 모드에서는 타이머 화면의 `07:42` 숫자를 **길게 누르면** 바로 완료되어 06 독서 기록 → 07 보상 흐름을 빠르게 확인할 수 있어요.

## 2. 화면 구성 (Figma 프레임 ↔ 파일)

| Figma | 파일 | 이동 |
|---|---|---|
| 00 로그인 | `screens/login_screen.dart` | 로그인 → 01 / 회원가입 링크 → 00 회원가입 |
| 00 회원가입 | `screens/signup_screen.dart` | 가입하기 → 01 / 로그인 링크 → 00 로그인 |
| 01 홈 · 캐릭터 책장 | `screens/home_screen.dart` | 꾸미기 → 10 / 이어서 읽기 → 08 |
| 02 책 쌓아 두기 | `screens/add_book_screen.dart` | 쌓기 → 03 |
| 03 읽을 책 더미 | `screens/to_read_screen.dart` | 책 추가하기 → 02 / 읽기 시작 → 04(처음) 또는 08(이어 읽기) |
| 04 읽기 시간 선택 | `screens/time_select_screen.dart` | 타이머 시작 → 05 |
| 05 타이머 | `screens/timer_screen.dart` | 시간 종료 → 06 / 포기하기 → 01 |
| 06 독서 기록 | `screens/record_screen.dart` | 마지막 쪽 → 09 / 목표 달성 → 07 |
| 07 목표 달성 보상 | `screens/reward_screen.dart` | 책장에 놓기 → 10 / 나중에 → 01 |
| 08 이어 읽기 전 회고 | `screens/recap_screen.dart` | 이어서 읽기 → 04 |
| 09 완독 | `screens/finished_screen.dart` | 책장에 꽂기 → 01 / 다음 책 고르기 → 03 |
| 10 책장 꾸미기 | `screens/decorate_screen.dart` | 저장하기 → 01 |
| 11 AI 맞춤 추천 | `screens/recommend_screen.dart` | + → 03 (로그아웃 버튼도 이 화면 하단에 있음) |

공통 요소는 `widgets/common.dart`(버튼, 입력 필드, 상단 바, 새싹이, 말풍선, 세그먼트)와
`widgets/book_widgets.dart`(진행 책, 쌓인 책, 캐릭터 책장, 하단 탭바)에 있습니다.
새싹이 캐릭터·장식·아이콘은 Figma에서 SVG로 내보내 `assets/svg/`에 넣었습니다.

## 3. 디자인 토큰 (FlutterFlow Theme에 그대로 입력 가능)

| 이름 | 값 | 용도 |
|---|---|---|
| Primary | `#8C5A36` | 주요 버튼, 선택 테두리 |
| Background | `#FCF6D7` | 화면 배경 |
| Sun | `#EFC49F` | 상단 햇살 그라데이션(75% → 0%), 선택된 시간 칩 |
| Text | `#4A3A28` | 기본 텍스트 |
| SubText | `#786A52` | 보조 텍스트 |
| Card | `#FFFBEF` | 카드, 입력칸 |
| Border | `#EFD8B4` | 입력칸 테두리(1.5) |
| Beige | `#F5E3BD` | 진행 막대 배경, 세그먼트 배경 |
| Green | `#7FA24A` | 진행 막대, 스위치 |
| Link | `#2F6BC4` | 파란 링크 |

글꼴: **Noto Sans KR**(26 Bold 제목 / 20 Bold / 16 Bold / 14 Medium·Regular / 12 Regular), 말풍선은 **Gaegu Bold 19**.
모서리: 버튼 16, 입력칸 14, 카드 16, 쌓인 책 6.

## 4. FlutterFlow로 옮기기

FlutterFlow는 일반 Flutter 프로젝트를 통째로 가져오는(import) 기능이 없어서, 아래처럼 옮기면 가장 빠릅니다.

1. **새 프로젝트 → Settings → Firebase**에서 같은 Firebase 프로젝트를 연결하고, **Authentication**에서 Email 로그인을 켭니다.
   Entry Page = `Login`, Logged-In Page = `Home`으로 지정합니다.
2. **Theme Settings**에 위 3번 색상·글꼴을 입력합니다.
3. **Media Assets**에 `assets/svg/*.svg`를 업로드합니다.
4. 각 화면을 위 2번 표의 이름으로 만들고, 같은 위젯 트리(Column → 카드/입력칸/버튼)를 배치합니다.
   - 로그인 버튼 Action: **Auth → Log In (Email)**
   - 가입하기 버튼 Action: **Auth → Create Account (Email)** → **Backend → Create Document (users)**
5. 구현이 복잡한 컴포넌트(`CharacterShelf`, `ProgressBook`, `StackedBook`)는
   **Custom Code → Custom Widgets**에 해당 클래스 코드를 붙여 넣어 재사용할 수 있어요
   (의존성 `flutter_svg`, `google_fonts`를 Custom Code 설정에 추가).
6. 독서 데이터는 Firestore `users/{uid}/books`(title, totalPages, color, currentPage, memo, status, createdAt, finishedAt)에 저장돼요.
   FlutterFlow에서도 같은 컬렉션 구조로 만들면 데이터를 그대로 이어서 쓸 수 있어요.

## 5. 책 관리

- 새 계정은 책장과 읽을 책 더미가 **빈 상태**로 시작해요. 홈의 「첫 책 추가하기」나 읽을 책 탭의 「책 추가하기」로 추가해요.
- **책 정보 수정:** 읽을 책 더미에서 책을 눌러 고른 뒤 **한 번 더 누르거나 길게 누르면** 수정 화면이 열려요. 홈의 「지금 읽는 책」 카드에 있는 **수정**으로도 열 수 있어요.
  제목, 총 쪽수, 지금까지 읽은 쪽, 표지 색을 바꿀 수 있고, 같은 화면에서 책을 삭제할 수도 있어요.
