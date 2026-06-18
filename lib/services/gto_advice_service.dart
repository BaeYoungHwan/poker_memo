import 'package:cloud_functions/cloud_functions.dart';

import '../domain/hand_memo.dart';

/// `gtoAdvice` Cloud Function 호출 서비스
///
/// Firebase Functions 콜러블을 감싸 화면(screens/)이 Cloud Function 세부사항을
/// 알 필요 없이 순수 Dart 인터페이스로 AI GTO 조언을 요청할 수 있도록 한다.
class GtoAdviceService {
  GtoAdviceService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// 핸드 상황·포지션·스택·블라인드를 전달해 AI GTO 조언 텍스트를 받아온다.
  ///
  /// 실패 시(인증 없음, 일일 한도 초과, 서버 오류 등) 서버가 한국어로 작성한
  /// 메시지를 그대로 노출하는 [Exception]을 던진다 (CLAUDE.md: 외부 호출 try-catch 필수).
  Future<String> requestAdvice({
    required String handMemoText,
    required PokerPosition position,
    required int stackSize,
    required String blindLevel,
  }) async {
    try {
      final callable = _functions.httpsCallable('gtoAdvice');
      final result = await callable.call({
        'handMemoText': handMemoText,
        'position': position.label,
        'stackSize': stackSize,
        'blindLevel': blindLevel,
      });

      // 플랫폼별 반환 타입 차이(Map<String, dynamic> vs LinkedHashMap<Object?, Object?>)를
      // 안전하게 흡수하기 위해 동적 캐스팅 후 키 조회
      final data = result.data as Map<dynamic, dynamic>;
      final advice = data['advice'] as String?;
      if (advice == null || advice.isEmpty) {
        throw Exception('AI 조언 응답이 비어 있습니다. 잠시 후 다시 시도해 주세요.');
      }
      return advice;
    } on FirebaseFunctionsException catch (e) {
      // 서버(HttpsError)가 던진 한국어 메시지를 그대로 사용자에게 전달
      throw Exception(e.message ?? 'GTO 조언 요청 중 오류가 발생했습니다.');
    }
  }
}
