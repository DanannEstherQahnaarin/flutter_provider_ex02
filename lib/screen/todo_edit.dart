import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/todo.dart';
import '../provider/todo_provider.dart';
import '../widget/todo/todo_form.dart';
import '../widget/dialog/error_dialog.dart';
import '../exception/todo_exception.dart';
import '../exception/app_exception.dart';
import '../utils/logger.dart';

/// 할일 수정 화면
///
/// 기존 Todo를 수정하는 팝업 화면입니다.
/// TodoForm 위젯을 사용하여 입력을 받습니다.
///
/// 주요 기능:
/// - 기존 Todo 데이터 로드
/// - Todo 제목 및 설명 수정
/// - 유효성 검증
/// - 예외 처리 및 에러 다이얼로그 표시
/// - 성공 시 팝업 닫기
///
/// UI와 비즈니스 로직 분리:
/// - 폼 입력은 UI에서 처리
/// - 데이터 수정은 Provider를 통해 처리
/// - 예외 처리는 UI에서 사용자에게 표시
///
/// 예시:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => TodoEditScreen(todoId: 'todo-123'),
/// );
/// ```
class TodoEditScreen extends ConsumerStatefulWidget {
  /// 수정할 Todo의 ID
  ///
  /// 필수 파라미터입니다.
  final String todoId;

  /// TodoEditScreen 생성자
  ///
  /// [todoId] 수정할 Todo의 ID (필수)
  const TodoEditScreen({
    super.key,
    required this.todoId,
  });

  @override
  ConsumerState<TodoEditScreen> createState() => _TodoEditScreenState();
}

class _TodoEditScreenState extends ConsumerState<TodoEditScreen> {
  Todo? _todo;

  @override
  void initState() {
    super.initState();
    logger.i('TodoEditScreen 열기: ${widget.todoId}');
    _loadTodo();
  }

  @override
  void dispose() {
    logger.i('TodoEditScreen 닫기: ${widget.todoId}');
    super.dispose();
  }

  /// Todo 데이터 로드
  ///
  /// Provider에서 Todo를 조회하여 화면에 표시할 데이터를 로드합니다.
  /// Todo를 찾을 수 없는 경우 에러 다이얼로그를 표시합니다.
  void _loadTodo() {
    try {
      final todos = ref.read(todoProvider);
      _todo = todos.firstWhere(
        (todo) => todo.id == widget.todoId,
        orElse: () => throw TodoNotFoundException(widget.todoId),
      );
      logger.d('Todo 로드 완료: ${_todo!.id}');
      setState(() {});
    } on TodoNotFoundException catch (e) {
      logger.w('Todo 로드 실패: ${e.message}');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            exception: e,
            title: '오류',
          ),
        ).then((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  /// 폼 제출 처리
  ///
  /// TodoForm에서 제출 버튼을 클릭하면 호출됩니다.
  /// 입력된 데이터로 Todo를 수정하고 Provider를 통해 업데이트합니다.
  ///
  /// [title] 수정된 Todo 제목
  /// [description] 수정된 Todo 설명 (선택사항)
  Future<void> _handleSubmit(String title, String? description) async {
    if (_todo == null) {
      return;
    }

    logger.i('Todo 수정 시도: ${_todo!.id}');

    try {
      // 수정된 Todo 생성
      final updatedTodo = _todo!.copyWith(
        title: title,
        description: description,
      );

      // Provider를 통해 Todo 수정
      await ref.read(todoProvider.notifier).updateTodo(
            widget.todoId,
            updatedTodo,
          );

      logger.i('Todo 수정 완료: ${_todo!.id}');

      // 성공 시 팝업 닫기
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('할일이 수정되었습니다.')),
        );
      }
    } on TodoNotFoundException catch (e) {
      logger.w('Todo 수정 실패 - Todo를 찾을 수 없음: ${e.message}');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            exception: e,
            title: '오류',
          ),
        );
      }
    } on TodoValidationException catch (e) {
      logger.w('Todo 수정 실패 - 검증 오류: ${e.message}');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            exception: e,
            title: '입력 오류',
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.e('Todo 수정 실패 - 예상치 못한 오류', error: e, stackTrace: stackTrace);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            exception: e is AppException
                ? e
                : TodoValidationException('할일 수정 중 오류가 발생했습니다.'),
            title: '오류',
          ),
        );
      }
    }
  }

  /// 취소 처리
  ///
  /// TodoForm에서 취소 버튼을 클릭하면 호출됩니다.
  /// 팝업을 닫습니다.
  void _handleCancel() {
    logger.d('Todo 수정 취소: ${widget.todoId}');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_todo == null) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '할일 수정',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TodoForm(
              initialTodo: _todo,
              onSubmit: _handleSubmit,
              onCancel: _handleCancel,
            ),
          ],
        ),
      ),
    );
  }
}
