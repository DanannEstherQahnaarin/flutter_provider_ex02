# 개발 규칙 (Development Rules)

이 문서는 Flutter Riverpod 프로젝트의 개발 규칙과 코딩 표준을 정의합니다.

---

## 1. 코드 구조 및 아키텍처

### 1.1 UI 코드와 비즈니스 코드 분리

#### 원칙
- **UI 코드**: 화면 렌더링 및 사용자 인터랙션 처리만 담당
- **비즈니스 코드**: 데이터 처리, 상태 관리, 비즈니스 로직 처리

#### 디렉토리 구조
```
lib/
├── model/          # 데이터 모델 (비즈니스 로직)
├── provider/       # 상태 관리 및 비즈니스 로직 (Riverpod Provider)
├── screen/         # UI 화면 (위젯)
├── widget/         # 재사용 가능한 UI 컴포넌트
├── service/        # 비즈니스 서비스 로직
└── exception/      # 예외 처리 클래스
```

#### 규칙
1. **Screen 위젯 (`lib/screen/`)**
   - UI 렌더링만 담당
   - 비즈니스 로직 직접 구현 금지
   - Provider를 통해서만 데이터 접근
   - 사용자 입력 검증은 최소한의 UI 레벨 검증만 수행

2. **Provider (`lib/provider/`)**
   - 상태 관리 및 비즈니스 로직 처리
   - 데이터 변환 및 가공
   - 외부 서비스 호출 (향후 확장 시)
   - UI 코드에서 직접 호출하지 않음 (Provider를 통해서만 접근)

3. **Service (`lib/service/`)**
   - 복잡한 비즈니스 로직 처리
   - 데이터베이스 연동 (향후)
   - API 호출 (향후)
   - Provider에서 Service 호출

4. **Model (`lib/model/`)**
   - 순수 데이터 클래스
   - 비즈니스 로직 포함 금지
   - 데이터 변환 메서드만 포함 가능

#### 예시

**❌ 잘못된 예시 (UI에 비즈니스 로직 포함)**
```dart
// lib/screen/todo_list.dart
class TodoListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final todos = []; // 직접 데이터 관리
    // 비즈니스 로직이 UI에 포함됨
    final filteredTodos = todos.where((todo) => todo.isCompleted).toList();
    return ListView(...);
  }
}
```

**✅ 올바른 예시 (UI와 비즈니스 로직 분리)**
```dart
// lib/provider/todo_provider.dart
@riverpod
class TodoNotifier extends _$TodoNotifier {
  @override
  List<Todo> build() => [];
  
  /// 완료된 할일 목록을 필터링하여 반환
  List<Todo> getCompletedTodos() {
    return state.where((todo) => todo.isCompleted).toList();
  }
}

// lib/screen/todo_list.dart
class TodoListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoNotifierProvider);
    // UI는 데이터 표시만 담당
    return ListView(...);
  }
}
```

---

## 2. 예외 처리 (Exception Handling)

### 2.1 사용자 정의 예외 클래스 생성

#### 원칙
- 모든 예외는 사용자 정의 예외 클래스를 통해 공통 관리
- 표준 Exception 클래스 직접 사용 금지
- 예외 타입별로 명확한 클래스 분리

#### 디렉토리 구조
```
lib/
└── exception/
    ├── app_exception.dart      # 기본 예외 클래스
    ├── todo_exception.dart      # Todo 관련 예외
    └── validation_exception.dart # 검증 관련 예외
```

#### 예외 클래스 구조

**기본 예외 클래스 (`lib/exception/app_exception.dart`)**
```dart
/// 애플리케이션의 기본 예외 클래스
/// 
/// 모든 사용자 정의 예외는 이 클래스를 상속받아야 합니다.
abstract class AppException implements Exception {
  /// 예외 메시지
  final String message;
  
  /// 원본 예외 (있는 경우)
  final Object? originalException;
  
  /// 스택 트레이스
  final StackTrace? stackTrace;
  
  const AppException(
    this.message, {
    this.originalException,
    this.stackTrace,
  });
  
  @override
  String toString() => message;
}
```

**Todo 관련 예외 (`lib/exception/todo_exception.dart`)**
```dart
/// Todo 관련 예외 클래스
/// 
/// Todo 생성, 수정, 삭제 시 발생하는 예외를 처리합니다.
class TodoNotFoundException extends AppException {
  const TodoNotFoundException(String todoId)
      : super('Todo를 찾을 수 없습니다: $todoId');
}

class TodoValidationException extends AppException {
  const TodoValidationException(String message) : super(message);
}

class TodoDuplicateException extends AppException {
  const TodoDuplicateException(String title)
      : super('이미 존재하는 Todo입니다: $title');
}
```

#### 예외 처리 규칙

1. **Provider에서 예외 처리**
```dart
@riverpod
class TodoNotifier extends _$TodoNotifier {
  /// Todo를 추가합니다.
  /// 
  /// [todo] 추가할 Todo 객체
  /// 
  /// Throws [TodoValidationException] Todo 검증 실패 시
  /// Throws [TodoDuplicateException] 중복된 Todo인 경우
  Future<void> addTodo(Todo todo) async {
    try {
      // 검증 로직
      if (todo.title.isEmpty) {
        throw const TodoValidationException('제목은 필수입니다.');
      }
      
      // 비즈니스 로직
      // ...
    } on TodoValidationException {
      rethrow; // 명시적 예외는 재던지기
    } on Exception catch (e, stackTrace) {
      // 예상치 못한 예외는 AppException으로 래핑
      throw AppException(
        'Todo 추가 중 오류가 발생했습니다.',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }
}
```

2. **UI에서 예외 처리**
```dart
class TodoAddScreen extends ConsumerWidget {
  Future<void> _handleAdd(BuildContext context, WidgetRef ref, Todo todo) async {
    try {
      await ref.read(todoNotifierProvider.notifier).addTodo(todo);
      Navigator.of(context).pop();
    } on TodoValidationException catch (e) {
      // 사용자에게 검증 오류 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on AppException catch (e) {
      // 일반 오류 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }
}
```

3. **로깅과 함께 예외 처리**
```dart
Future<void> addTodo(Todo todo) async {
  try {
    // 비즈니스 로직
  } on AppException catch (e, stackTrace) {
    logger.error(
      'Todo 추가 실패',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

---

## 3. 컴포넌트 모듈화 및 재사용

### 3.1 재사용 가능한 컴포넌트 구조

#### 원칙
- 공통으로 사용되는 UI 컴포넌트는 `lib/widget/` 디렉토리에 모듈화
- 중복 코드 최소화
- Props 기반으로 동작하도록 설계

#### 디렉토리 구조
```
lib/
└── widget/
    ├── common/           # 공통 위젯
    │   ├── custom_button.dart
    │   ├── custom_text_field.dart
    │   └── loading_indicator.dart
    ├── todo/             # Todo 관련 위젯
    │   ├── todo_item.dart
    │   └── todo_form.dart
    └── dialog/           # 다이얼로그 컴포넌트
        ├── confirm_dialog.dart
        └── error_dialog.dart
```

#### 컴포넌트 작성 규칙

1. **단일 책임 원칙**
   - 각 위젯은 하나의 명확한 목적만 가져야 함
   - 복잡한 위젯은 작은 위젯으로 분리

2. **Props 기반 설계**
   - 위젯은 파라미터를 통해 동작하도록 설계
   - 내부 상태는 최소화

3. **문서화**
   - 모든 공통 위젯에 상세 주석 작성
   - 사용 예시 포함

#### 예시

**공통 버튼 컴포넌트 (`lib/widget/common/custom_button.dart`)**
```dart
/// 재사용 가능한 커스텀 버튼 위젯
/// 
/// 다양한 스타일과 크기의 버튼을 제공합니다.
/// 
/// 예시:
/// ```dart
/// CustomButton(
///   text: '저장',
///   onPressed: () => handleSave(),
///   style: ButtonStyle.primary,
/// )
/// ```
class CustomButton extends StatelessWidget {
  /// 버튼에 표시될 텍스트
  final String text;
  
  /// 버튼 클릭 시 실행될 콜백
  final VoidCallback? onPressed;
  
  /// 버튼 스타일
  final ButtonStyle style;
  
  /// 버튼 크기
  final ButtonSize size;
  
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = ButtonStyle.primary,
    this.size = ButtonSize.medium,
  });
  
  @override
  Widget build(BuildContext context) {
    // 구현
  }
}
```

**Todo 항목 컴포넌트 (`lib/widget/todo/todo_item.dart`)**
```dart
/// Todo 목록의 개별 항목을 표시하는 위젯
/// 
/// Todo 정보를 표시하고, 클릭 시 상세 정보를 보여줍니다.
/// 
/// 예시:
/// ```dart
/// TodoItem(
///   todo: todo,
///   onTap: () => navigateToDetail(todo.id),
///   onDelete: () => deleteTodo(todo.id),
/// )
/// ```
class TodoItem extends StatelessWidget {
  /// 표시할 Todo 객체
  final Todo todo;
  
  /// 항목 클릭 시 실행될 콜백
  final VoidCallback? onTap;
  
  /// 삭제 버튼 클릭 시 실행될 콜백
  final VoidCallback? onDelete;
  
  const TodoItem({
    super.key,
    required this.todo,
    this.onTap,
    this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    // 구현
  }
}
```

#### 재사용 체크리스트
- [ ] 동일한 UI 패턴이 2회 이상 사용되는가?
- [ ] 위젯이 단일 책임을 가지는가?
- [ ] Props를 통해 동작을 제어할 수 있는가?
- [ ] 문서화가 되어 있는가?
- [ ] 테스트 가능한 구조인가?

---

## 4. 외부 패키지 (Pub Package) 관리

### 4.1 패키지 추가 규칙

#### 원칙
- 필요한 패키지만 추가
- `pubspec.yaml`에 추가 시 반드시 주석으로 용도 명시
- 버전은 최신 안정 버전 사용
- 사용하지 않는 패키지는 제거

#### `pubspec.yaml` 주석 규칙

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 상태 관리 라이브러리
  # - Riverpod: 선언적 상태 관리
  # - flutter_riverpod: Flutter 위젯과 통합
  # - riverpod_annotation: 코드 생성 기반 Provider
  riverpod: ^3.1.0
  flutter_riverpod: ^3.1.0
  riverpod_annotation: ^4.0.0

  # 로깅 라이브러리
  # - logger: 구조화된 로깅 기능 제공
  # - 로그 레벨: Debug, Info, Warning, Error
  # - 콘솔 및 파일 출력 지원
  logger: ^2.0.0

  # 유틸리티
  # - intl: 날짜/시간 포맷팅 및 국제화
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # 코드 품질
  # - flutter_lints: Flutter 권장 린트 규칙
  flutter_lints: ^6.0.0

  # 코드 생성
  # - riverpod_generator: Riverpod Provider 코드 생성
  riverpod_generator: ^4.0.0+1

  # 빌드 러너
  # - build_runner: 코드 생성 실행 도구
  build_runner: ^2.4.0
```

#### 패키지 추가 프로세스

1. **필요성 검토**
   - 정말 필요한 패키지인가?
   - 직접 구현이 가능한가?
   - 프로젝트 규모에 적합한가?

2. **패키지 선택**
   - 공식 패키지 우선
   - 활발히 유지보수되는 패키지
   - 문서화가 잘 되어 있는 패키지

3. **추가 및 문서화**
   ```yaml
   # [패키지명]: [간단한 설명]
   # - [주요 기능 1]
   # - [주요 기능 2]
   # - [사용 목적]
   package_name: ^version
   ```

4. **사용 예시 문서화**
   - README 또는 별도 문서에 사용 예시 추가
   - 주요 API 사용법 정리

#### 패키지별 주석 예시

**로깅 패키지**
```yaml
# 로깅 라이브러리
# - logger: 구조화된 로깅 기능 제공
# - 로그 레벨: Debug, Info, Warning, Error, Fatal
# - 콘솔 출력 및 파일 저장 지원
# - 타임스탬프 및 스택 트레이스 자동 포함
# 사용 위치: lib/provider/, lib/service/
logger: ^2.0.0
```

**국제화 패키지**
```yaml
# 국제화 및 날짜/시간 포맷팅
# - intl: 날짜, 시간, 숫자 포맷팅
# - 다국어 지원 (향후 확장 시)
# - DateFormat, NumberFormat 클래스 제공
# 사용 위치: lib/model/, lib/widget/
intl: ^0.19.0
```

**유효성 검사 패키지**
```yaml
# 폼 유효성 검사 라이브러리
# - formz: 타입 안전한 폼 상태 관리
# - 입력값 검증 및 에러 처리
# 사용 위치: lib/screen/, lib/widget/
formz: ^0.6.0
```

---

## 5. Dart Lint 규칙 준수

### 5.1 Lint 규칙 준수 원칙

#### 원칙
- `analysis_options.yaml`에 정의된 모든 lint 규칙 준수
- Lint 경고는 반드시 해결
- 예외적인 경우에만 `// ignore:` 주석 사용 (주석으로 이유 명시)

### 5.2 주요 Lint 규칙

#### 필수 준수 규칙

1. **코드 스타일**
   - `prefer_single_quotes`: 문자열은 작은따옴표 사용
   - `prefer_const_constructors`: 가능한 경우 const 생성자 사용
   - `prefer_const_literals_to_create_immutables`: 불변 리스트/맵은 const 사용

2. **네이밍 규칙**
   - `non_constant_identifier_names`: 변수명은 camelCase
   - `constant_identifier_names`: 상수는 lowerCamelCase 또는 SCREAMING_CAPS
   - `library_names`: 라이브러리명은 snake_case

3. **코드 품질**
   - `avoid_print`: `print()` 대신 logger 사용
   - `avoid_empty_else`: 빈 else 블록 금지
   - `prefer_is_empty`: `length == 0` 대신 `isEmpty` 사용
   - `prefer_is_not_empty`: `length > 0` 대신 `isNotEmpty` 사용

4. **Null Safety**
   - `avoid_null_checks_in_equality_operators`: null 체크는 명시적으로
   - `prefer_null_aware_operators`: null-aware 연산자 사용 권장

5. **비동기 처리**
   - `avoid_void_async`: void async 함수 지양
   - `unawaited_futures`: Future는 await 또는 unawaited 처리

#### Lint 규칙 확인 방법

```bash
# 프로젝트 전체 lint 확인
flutter analyze

# 특정 파일만 확인
flutter analyze lib/main.dart

# 자동 수정 가능한 문제 자동 수정
dart fix --apply
```

### 5.3 Lint 예외 처리

#### 예외 허용 조건
- 기술적으로 불가능한 경우
- 프레임워크 제약으로 인한 경우
- 명확한 이유가 있는 경우

#### 예외 처리 형식
```dart
// ignore: lint_rule_name
// 이유: [명확한 이유 설명]
code_that_violates_lint_rule();

// 또는 인라인 주석
final result = someCode(); // ignore: lint_rule_name - [이유]
```

#### 예시

**❌ 잘못된 예외 처리**
```dart
// ignore: avoid_print
print('Debug message'); // 이유 없이 lint 무시
```

**✅ 올바른 예외 처리**
```dart
// ignore: avoid_print
// 이유: 초기화 단계에서 logger가 아직 초기화되지 않아 print 사용
print('Initializing application...');
```

### 5.4 Lint 규칙 커스터마이징

`analysis_options.yaml`에서 프로젝트에 맞게 규칙 조정 가능:

```yaml
linter:
  rules:
    # 특정 규칙 비활성화 (필요한 경우만)
    # avoid_print: false
    
    # 추가 규칙 활성화
    prefer_single_quotes: true
    prefer_const_constructors: true
    prefer_final_fields: true
    prefer_final_locals: true
```

---

## 6. 코드 리뷰 체크리스트

### 6.1 구조 및 아키텍처
- [ ] UI 코드와 비즈니스 코드가 분리되어 있는가?
- [ ] 적절한 디렉토리 구조를 따르고 있는가?
- [ ] 재사용 가능한 컴포넌트로 모듈화되어 있는가?

### 6.2 예외 처리
- [ ] 사용자 정의 예외 클래스를 사용하고 있는가?
- [ ] 예외가 적절히 처리되고 있는가?
- [ ] 예외 발생 시 로깅이 되고 있는가?

### 6.3 패키지 관리
- [ ] 추가된 패키지에 주석이 있는가?
- [ ] 패키지가 실제로 사용되고 있는가?
- [ ] 버전이 적절한가?

### 6.4 코드 품질
- [ ] 모든 lint 규칙을 준수하고 있는가?
- [ ] 클래스 및 함수에 주석이 있는가?
- [ ] 로깅이 적절히 구현되어 있는가?

### 6.5 테스트
- [ ] 주요 기능에 대한 테스트가 있는가?
- [ ] 예외 상황에 대한 테스트가 있는가?

---

## 7. 개발 워크플로우

### 7.1 코드 작성 전
1. PRD 및 RULES 문서 확인
2. 필요한 패키지 검토 및 추가 (주석 포함)
3. 디렉토리 구조 확인

### 7.2 코드 작성 중
1. UI와 비즈니스 로직 분리 유지
2. 사용자 정의 예외 사용
3. 재사용 가능한 컴포넌트 고려
4. 주석 및 로깅 추가

### 7.3 코드 작성 후
1. `flutter analyze` 실행하여 lint 확인
2. 자동 수정 가능한 문제 해결
3. 코드 리뷰 체크리스트 확인
4. 테스트 작성 (가능한 경우)

---

## 8. 참고 자료

- [Flutter Lints](https://pub.dev/packages/flutter_lints)
- [Dart Lint Rules](https://dart.dev/lints)
- [Riverpod Documentation](https://riverpod.dev/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

