import 'package:cloud_functions/cloud_functions.dart';

/// 포스터 스캔 결과 — Cloud Function `scanPoster` 응답을 담는 단순 DTO
/// (Firestore에 영속 저장되는 모델이 아니므로 domain/이 아닌 이 파일 내부에 둔다)
class PosterScanResult {
  const PosterScanResult({
    this.name,
    this.date,
    this.buyIn,
    this.warning,
  });

  /// AI가 인식한 토너먼트명 — 인식 실패 시 null
  final String? name;

  /// AI가 인식한 날짜 (ISO 형식 "YYYY-MM-DD" 문자열) — 인식 실패 시 null
  final String? date;

  /// AI가 인식한 바이인 금액 — 인식 실패 시 null
  final double? buyIn;

  /// 부분/전체 인식 실패 시 사용자에게 보여줄 안내 메시지 — 완전 인식 성공 시 null
  final String? warning;
}

/// `scanPoster` Cloud Function 호출 서비스
///
/// Firebase Functions 콜러블을 감싸 화면(screens/)이 Cloud Function 세부사항을
/// 알 필요 없이 순수 Dart 인터페이스로 포스터 이미지 AI 스캔을 요청할 수 있도록 한다.
class PosterScanService {
  PosterScanService({FirebaseFunctions? functions}) : _injectedFunctions = functions;

  final FirebaseFunctions? _injectedFunctions;

  /// 실제 호출 시점까지 평가를 지연한다 — 테스트에서 scanPoster를 오버라이드하는
  /// 서브클래스를 만들 때 FirebaseFunctions.instance(미초기화 시 예외)를 건드리지 않도록 함
  FirebaseFunctions get _functions => _injectedFunctions ?? FirebaseFunctions.instance;

  /// Base64로 인코딩된 이미지를 전달해 AI가 추출한 토너먼트 정보를 받아온다.
  ///
  /// [imageBase64]는 data URI 접두사 없는 순수 base64 문자열이어야 한다.
  /// [mimeType]은 "image/jpeg" | "image/png" | "image/webp" 중 하나.
  ///
  /// 실패 시(인증 없음, 일일 한도 초과, 이미지 형식/크기 오류, 서버 오류 등) 서버가
  /// 한국어로 작성한 메시지를 그대로 노출하는 [Exception]을 던진다
  /// (CLAUDE.md: 외부 호출 try-catch 필수).
  Future<PosterScanResult> scanPoster({
    required String imageBase64,
    required String mimeType,
  }) async {
    try {
      final callable = _functions.httpsCallable('scanPoster');
      final result = await callable.call({
        'imageBase64': imageBase64,
        'mimeType': mimeType,
      });

      // 플랫폼별 반환 타입 차이(Map<String, dynamic> vs LinkedHashMap<Object?, Object?>)를
      // 안전하게 흡수하기 위해 동적 캐스팅 후 키 조회
      final data = result.data as Map<dynamic, dynamic>;
      return PosterScanResult(
        name: data['name'] as String?,
        date: data['date'] as String?,
        buyIn: (data['buyIn'] as num?)?.toDouble(),
        warning: data['warning'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      // 서버(HttpsError)가 던진 한국어 메시지를 그대로 사용자에게 전달
      throw Exception(e.message ?? '포스터 분석 중 오류가 발생했습니다.');
    }
  }
}
