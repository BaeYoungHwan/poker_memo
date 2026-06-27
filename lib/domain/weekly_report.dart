import 'package:cloud_firestore/cloud_firestore.dart';

/// AI 에이전트가 생성한 주간 Leak 분석 리포트
class WeeklyReport {
  const WeeklyReport({
    required this.id,
    required this.generatedAt,
    required this.weekStart,
    required this.handsAnalyzed,
    required this.topLeaks,
    required this.reportText,
    required this.status,
  });

  final String id;
  final DateTime generatedAt;
  final DateTime weekStart;

  /// 분석에 사용된 핸드 수
  final int handsAnalyzed;

  /// 상위 약점 목록 (최대 3개)
  final List<String> topLeaks;

  /// AI 생성 전체 리포트 텍스트
  final String reportText;

  /// 생성 상태 — "success" / "failed"
  final String status;

  factory WeeklyReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeeklyReport(
      id: doc.id,
      generatedAt:
          (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weekStart:
          (data['weekStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      handsAnalyzed: data['handsAnalyzed'] as int? ?? 0,
      topLeaks: List<String>.from(data['topLeaks'] as List? ?? []),
      reportText: data['reportText'] as String? ?? '',
      status: data['status'] as String? ?? 'success',
    );
  }
}
