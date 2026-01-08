import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/todo_provider.dart';
import '../widget/todo/todo_item.dart';
import '../screen/todo_add.dart';
import '../screen/todo_edit.dart';
import '../utils/logger.dart';

/// 할일 목록 화면
///
/// Todo 목록을 표시하는 메인 화면입니다.
/// NestedScrollView를 사용하여 스크롤 동작을 구현합니다.
///
/// 주요 기능:
/// - Todo 목록 표시
/// - Todo 추가 버튼 (FloatingActionButton)
/// - Todo 항목 클릭 시 수정 화면으로 이동
/// - Todo 삭제 기능
///
/// UI와 비즈니스 로직 분리:
/// - Provider를 통해서만 데이터 접근
/// - 비즈니스 로직은 Provider에서 처리
/// - UI는 데이터 표시 및 사용자 인터랙션만 담당
///
/// 예시:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const TodoListScreen()),
/// );
/// ```
class TodoListScreen extends ConsumerStatefulWidget {
  /// TodoListScreen 생성자
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  @override
  void initState() {
    super.initState();
    logger.i('TodoListScreen 진입');
  }

  @override
  void dispose() {
    logger.i('TodoListScreen 이탈');
    super.dispose();
  }

  /// Todo 추가 화면 열기
  ///
  /// FloatingActionButton 클릭 시 호출됩니다.
  /// 팝업 형태로 Todo 추가 화면을 표시합니다.
  Future<void> _openAddScreen() async {
    logger.i('Todo 추가 화면 열기');
    await showDialog(
      context: context,
      builder: (context) => const TodoAddScreen(),
    );
    logger.i('Todo 추가 화면 닫기');
  }

  /// Todo 수정 화면 열기
  ///
  /// Todo 항목 클릭 시 호출됩니다.
  /// 선택된 Todo의 ID를 전달하여 수정 화면을 표시합니다.
  ///
  /// [todoId] 수정할 Todo의 ID
  Future<void> _openEditScreen(String todoId) async {
    logger.i('Todo 수정 화면 열기: $todoId');
    await showDialog(
      context: context,
      builder: (context) => TodoEditScreen(todoId: todoId),
    );
    logger.i('Todo 수정 화면 닫기: $todoId');
  }

  /// Todo 삭제 처리
  ///
  /// 삭제 확인 다이얼로그를 표시하고, 확인 시 Todo를 삭제합니다.
  ///
  /// [todoId] 삭제할 Todo의 ID
  Future<void> _handleDelete(String todoId) async {
    logger.i('Todo 삭제 시도: $todoId');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(todoProvider.notifier).deleteTodo(todoId);
        logger.i('Todo 삭제 완료: $todoId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todo가 삭제되었습니다.')),
          );
        }
      } catch (e) {
        logger.e('Todo 삭제 실패: $todoId', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
          );
        }
      }
    } else {
      logger.d('Todo 삭제 취소: $todoId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('할일 목록'),
        elevation: 2.0,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('총 ${todos.length}개의 할일'),
              centerTitle: true,
            ),
          ),
        ],
        body: todos.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '할일이 없습니다',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '우측 하단 버튼을 눌러 할일을 추가하세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return TodoItem(
                    todo: todo,
                    onTap: () => _openEditScreen(todo.id),
                    onDelete: () => _handleDelete(todo.id),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        tooltip: '할일 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}
