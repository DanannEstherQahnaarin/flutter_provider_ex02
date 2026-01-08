import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screen/todo_list.dart';
import 'utils/logger.dart';

/// 애플리케이션 진입점
///
/// Flutter 애플리케이션의 진입점입니다.
/// ProviderScope로 앱을 감싸서 Riverpod 상태 관리를 활성화합니다.
void main() {
  logger.i('애플리케이션 시작');
  runApp(const ProviderScope(child: MyApp()));
}

/// 메인 애플리케이션 위젯
///
/// MaterialApp을 구성하고 초기 라우트를 설정합니다.
/// ProviderScope로 감싸져 있어 모든 하위 위젯에서 Riverpod Provider를 사용할 수 있습니다.
///
/// 주요 구성:
/// - MaterialApp 설정
/// - 초기 라우트 설정 (TodoListScreen)
/// - 테마 설정
///
/// 예시:
/// ```dart
/// void main() {
///   runApp(const ProviderScope(child: MyApp()));
/// }
/// ```
class MyApp extends StatelessWidget {
  /// MyApp 생성자
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    logger.d('MyApp 빌드');
    return MaterialApp(
      title: 'Todo 앱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      home: const TodoListScreen(),
    );
  }
}
