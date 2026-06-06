import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'shared/theme/app_theme.dart';
import 'features/mistakes/screens/mistake_list_screen.dart';
import 'features/mistakes/screens/mistake_add_screen.dart';
import 'features/study_plan/screens/plan_screen.dart';
import 'features/tutor/screens/tutor_screen.dart';
import 'features/review/screens/review_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const MistakeListScreen()),
      GoRoute(path: '/add', builder: (_, _) => const MistakeAddScreen()),
      GoRoute(path: '/plan', builder: (_, _) => const PlanScreen()),
      GoRoute(path: '/tutor', builder: (_, _) => const TutorScreen()),
      GoRoute(path: '/review', builder: (_, _) => const ReviewScreen()),
    ],
  );
});

class MistakeBookApp extends ConsumerWidget {
  const MistakeBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'AI 错题本',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
