import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/todo.dart';
import '../provider/todo_provider.dart';
import '../widget/todo/todo_form.dart';
import '../widget/dialog/error_dialog.dart';
import '../exception/todo_exception.dart';
import '../exception/app_exception.dart';
import '../utils/logger.dart';

/// 할일 추가 화면
///
/// 새로운 Todo를 추가하는 팝업 화면입니다.
/// TodoForm 위젯을 사용하여 입력을 받습니다.
///
/// 주요 기능:
/// - Todo 제목 및 설명 입력
/// - 유효성 검증
/// - 예외 처리 및 에러 다이얼로그 표시
/// - 성공 시 팝업 닫기
///
/// UI와 비즈니스 로직 분리:
/// - 폼 입력은 UI에서 처리
/// - 데이터 저장은 Provider를 통해 처리
/// - 예외 처리는 UI에서 사용자에게 표시
///
/// 예시:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => const TodoAddScreen(),
/// );
/// ```
class TodoAddScreen extends ConsumerStatefulWidget {
  /// TodoAddScreen 생성자
  const TodoAddScreen({super.key});

  @override
  ConsumerState<TodoAddScreen> createState() => _TodoAddScreenState();
}

class _TodoAddScreenState extends ConsumerState<TodoAddScreen> {
  @override
  void initState() {
    super.initState();
    logger.i('TodoAddScreen 열기');
  }

  @override
  void dispose() {
    logger.i('TodoAddScreen 닫기');
    super.dispose();
  }

  /// 폼 제출 처리
  ///
  /// TodoForm에서 제출 버튼을 클릭하면 호출됩니다.
  /// 입력된 데이터로 Todo를 생성하고 Provider를 통해 추가합니다.
  ///
  /// [title] Todo 제목
  /// [description] Todo 설명 (선택사항)
  Future<void> _handleSubmit(String title, String? description) async {
    logger.i('Todo 추가 시도: $title');

    try {
      // Todo 생성
      final todo = Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        isCompleted: false,
      );

      // Provider를 통해 Todo 추가
      await ref.read(todoProvider.notifier).addTodo(todo);

      logger.i('Todo 추가 완료: ${todo.id}');

      // 성공 시 팝업 닫기
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('할일이 추가되었습니다.')));
      }
    } on TodoValidationException catch (e) {
      logger.w('Todo 추가 실패 - 검증 오류: ${e.message}');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(exception: e, title: '입력 오류'),
        );
      }
    } on TodoDuplicateException catch (e) {
      logger.w('Todo 추가 실패 - 중복 오류: ${e.message}');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(exception: e, title: '중복 오류'),
        );
      }
    } catch (e, stackTrace) {
      logger.e('Todo 추가 실패 - 예상치 못한 오류', error: e, stackTrace: stackTrace);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            exception: e is AppException
                ? e
                : TodoValidationException('할일 추가 중 오류가 발생했습니다.'),
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
    logger.d('Todo 추가 취소');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '할일 추가',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TodoForm(onSubmit: _handleSubmit, onCancel: _handleCancel),
        ],
      ),
    ),
  );
}
