import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 애플리케이션 전역 Logger 인스턴스
/// 
/// 이 Logger는 애플리케이션 전체에서 사용되는 로깅 기능을 제공합니다.
/// 개발 환경과 프로덕션 환경에 따라 다른 로그 레벨을 설정합니다.
/// 
/// 로그 레벨:
/// - Debug: 디버깅 정보 (개발 환경에서만)
/// - Info: 일반 정보 (상태 변경, 사용자 액션 등)
/// - Warning: 경고 메시지
/// - Error: 에러 메시지
/// - Fatal: 치명적 오류
/// 
/// 사용 예시:
/// ```dart
/// import 'package:flutter_riverpod_ex01/utils/logger.dart';
/// 
/// logger.d('디버그 메시지');
/// logger.i('정보 메시지');
/// logger.w('경고 메시지');
/// logger.e('에러 메시지', error: exception, stackTrace: stackTrace);
/// ```
final Logger logger = Logger(
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // 타임스탬프 출력
  ),
  level: kDebugMode ? Level.debug : Level.warning, // 개발 환경: Debug, 프로덕션: Warning 이상
);
