/// 애플리케이션의 기본 예외 클래스
/// 
/// 모든 사용자 정의 예외는 이 클래스를 상속받아야 합니다.
/// 이 클래스는 예외의 공통 속성(메시지, 원본 예외, 스택 트레이스)을 제공합니다.
/// 
/// 예시:
/// ```dart
/// class CustomException extends AppException {
///   const CustomException(String message) : super(message);
/// }
/// 
/// throw const CustomException('오류가 발생했습니다.');
/// ```
abstract class AppException implements Exception {
  /// 예외 메시지
  /// 
  /// 사용자에게 표시될 예외에 대한 설명 메시지입니다.
  final String message;

  /// 원본 예외 (있는 경우)
  /// 
  /// 이 예외를 발생시킨 원본 예외 객체입니다.
  /// 예외를 래핑할 때 사용됩니다.
  final Object? originalException;

  /// 스택 트레이스
  /// 
  /// 예외가 발생한 위치의 스택 트레이스 정보입니다.
  /// 디버깅 및 로깅에 사용됩니다.
  final StackTrace? stackTrace;

  /// AppException 생성자
  /// 
  /// [message] 예외 메시지 (필수)
  /// [originalException] 원본 예외 (선택사항)
  /// [stackTrace] 스택 트레이스 (선택사항)
  const AppException(
    this.message, {
    this.originalException,
    this.stackTrace,
  });

  /// 예외를 문자열로 변환
  /// 
  /// Returns 예외 메시지를 반환합니다.
  @override
  String toString() => message;
}
