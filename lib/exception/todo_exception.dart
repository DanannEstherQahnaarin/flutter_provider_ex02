import 'app_exception.dart';

/// Todo 관련 예외 클래스
/// 
/// Todo 생성, 수정, 삭제 시 발생하는 예외를 처리합니다.
/// 모든 Todo 관련 예외는 이 파일에 정의되어 있습니다.

/// Todo를 찾을 수 없을 때 발생하는 예외
/// 
/// 존재하지 않는 Todo ID로 접근하거나 조회할 때 발생합니다.
/// 
/// 예시:
/// ```dart
/// throw TodoNotFoundException('todo-123');
/// ```
class TodoNotFoundException extends AppException {
  /// TodoNotFoundException 생성자
  /// 
  /// [todoId] 찾을 수 없는 Todo의 ID
  const TodoNotFoundException(String todoId)
      : super('Todo를 찾을 수 없습니다: $todoId');
}

/// Todo 유효성 검증 실패 시 발생하는 예외
/// 
/// Todo 생성 또는 수정 시 필수 필드가 누락되거나
/// 유효하지 않은 값이 입력되었을 때 발생합니다.
/// 
/// 예시:
/// ```dart
/// throw const TodoValidationException('제목은 필수입니다.');
/// ```
class TodoValidationException extends AppException {
  /// TodoValidationException 생성자
  /// 
  /// [message] 검증 실패에 대한 상세 메시지
  const TodoValidationException(super.message);
}

/// 중복된 Todo가 존재할 때 발생하는 예외
/// 
/// 동일한 제목의 Todo가 이미 존재할 때 발생합니다.
/// 
/// 예시:
/// ```dart
/// throw TodoDuplicateException('중요한 할일');
/// ```
class TodoDuplicateException extends AppException {
  /// TodoDuplicateException 생성자
  /// 
  /// [title] 중복된 Todo의 제목
  const TodoDuplicateException(String title)
      : super('이미 존재하는 Todo입니다: $title');
}
