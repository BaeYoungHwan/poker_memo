import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'package:poker_memo_ai/core/theme/app_theme.dart';
import 'package:poker_memo_ai/domain/tournament.dart';
import 'package:poker_memo_ai/providers/tournament_list_provider.dart';
import 'package:poker_memo_ai/screens/add_tournament_screen.dart';
import 'package:poker_memo_ai/services/poster_scan_service.dart';

// Firebase 없이 테스트하기 위한 가짜 Notifier — addTournament 호출 인자를 그대로 기록
class _RecordingTournamentNotifier extends TournamentListNotifier {
  String? lastName;
  DateTime? lastDate;
  double? lastBuyIn;

  @override
  Stream<List<Tournament>> build() => Stream.value(const []);

  @override
  Future<void> addTournament(String name, DateTime date, double buyIn) async {
    lastName = name;
    lastDate = date;
    lastBuyIn = buyIn;
  }
}

// image_picker 플랫폼 채널을 가로채 더미 이미지를 즉시 반환하는 가짜 플랫폼
// (실제 카메라/갤러리 접근 없이 위젯 테스트에서 이미지 선택 흐름을 검증하기 위함)
class _FakeImagePickerPlatform extends ImagePickerPlatform {
  Uint8List? bytesToReturn;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    final bytes = bytesToReturn;
    if (bytes == null) return null;
    return XFile.fromData(bytes, mimeType: 'image/jpeg', name: 'poster.jpg');
  }
}

// scanPoster Cloud Function 호출을 가로채 미리 정해둔 결과/에러를 그대로 반환하는 가짜 서비스
class _FakePosterScanService extends PosterScanService {
  PosterScanResult? resultToReturn;
  Object? errorToThrow;

  @override
  Future<PosterScanResult> scanPoster({
    required String imageBase64,
    required String mimeType,
  }) async {
    final error = errorToThrow;
    if (error != null) throw error;
    return resultToReturn ?? const PosterScanResult();
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('이름이 비어있으면 저장 버튼이 비활성화된다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tournamentListProvider.overrideWith(_RecordingTournamentNotifier.new)],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.darkTheme,
          home: const AddTournamentScreen(),
        ),
      ),
    );
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('이름 입력 후 저장 버튼이 활성화되고, 탭하면 입력값 그대로 addTournament가 호출된다',
      (tester) async {
    final notifier = _RecordingTournamentNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tournamentListProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.darkTheme,
          home: const AddTournamentScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'WSOP Main Event');
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);

    await tester.enterText(find.byType(TextField).last, '500');
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(notifier.lastName, 'WSOP Main Event');
    expect(notifier.lastBuyIn, 500.0);
  });

  testWidgets('포스터 스캔 성공 시 이름/바이인/날짜 필드가 자동으로 채워진다', (tester) async {
    final fakePlatform = _FakeImagePickerPlatform()
      ..bytesToReturn = Uint8List.fromList([1, 2, 3]);
    ImagePickerPlatform.instance = fakePlatform;

    final fakeService = _FakePosterScanService()
      ..resultToReturn = const PosterScanResult(
        name: 'WSOP Main Event',
        date: '2026-07-15',
        buyIn: 500.0,
        warning: null,
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentListProvider.overrideWith(_RecordingTournamentNotifier.new),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.darkTheme,
          home: AddTournamentScreen(posterScanService: fakeService),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('갤러리에서 선택'));
    await tester.pumpAndSettle();

    expect(find.text('WSOP Main Event'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
  });

  testWidgets('포스터 일부 인식 시 warning 안내 메시지가 SnackBar로 노출된다', (tester) async {
    final fakePlatform = _FakeImagePickerPlatform()
      ..bytesToReturn = Uint8List.fromList([1, 2, 3]);
    ImagePickerPlatform.instance = fakePlatform;

    final fakeService = _FakePosterScanService()
      ..resultToReturn = const PosterScanResult(
        name: 'WSOP Main Event',
        date: null,
        buyIn: null,
        warning: '일부 정보만 인식되었습니다. 나머지는 직접 입력해 주세요.',
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentListProvider.overrideWith(_RecordingTournamentNotifier.new),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.darkTheme,
          home: AddTournamentScreen(posterScanService: fakeService),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('카메라로 촬영'));
    await tester.pumpAndSettle();

    expect(find.text('일부 정보만 인식되었습니다. 나머지는 직접 입력해 주세요.'), findsOneWidget);
  });

  testWidgets('포스터 스캔 실패 시 에러 메시지가 SnackBar로 노출된다', (tester) async {
    final fakePlatform = _FakeImagePickerPlatform()
      ..bytesToReturn = Uint8List.fromList([1, 2, 3]);
    ImagePickerPlatform.instance = fakePlatform;

    final fakeService = _FakePosterScanService()
      ..errorToThrow = Exception('일일 포스터 스캔 한도(5회)에 도달했습니다.');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentListProvider.overrideWith(_RecordingTournamentNotifier.new),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.darkTheme,
          home: AddTournamentScreen(posterScanService: fakeService),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('갤러리에서 선택'));
    await tester.pumpAndSettle();

    expect(
      find.text('포스터 분석 실패: Exception: 일일 포스터 스캔 한도(5회)에 도달했습니다.'),
      findsOneWidget,
    );
  });
}
