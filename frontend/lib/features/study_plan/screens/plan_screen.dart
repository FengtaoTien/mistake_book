import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/plan_api.dart';
import '../../../core/providers/plan_provider.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(currentPlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI 学习计划')),
      body: plan.when(
        data: (data) {
          if (data == null) {
            return const Center(child: Text('还没有学习计划'));
          }
          final tasks = data.planJson['plan'] as List<dynamic>? ?? [];
          final summary = data.planJson['summary'] as String? ?? '';
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentPlanProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text('本周计划 (${data.weekStart})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (summary.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(summary, style: TextStyle(color: Colors.grey.shade600)),
                        ],
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: data.progress / 100,
                          backgroundColor: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 4),
                        Text('${data.progress}%', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (tasks.isEmpty)
                  const Center(child: Text('暂无任务'))
                else
                  ...tasks.map((day) {
                    final dayName = day['day'] as String? ?? '';
                    final dayTasks = day['tasks'] as List<dynamic>? ?? [];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const Divider(),
                            ...dayTasks.map((t) {
                              final subject = t['subject'] as String? ?? '';
                              final content = t['content'] as String? ?? '';
                              final mins = t['estimated_minutes'] as int? ?? 30;
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 14,
                                  child: Text(subject.isNotEmpty ? subject[0] : '?',
                                      style: const TextStyle(fontSize: 12)),
                                ),
                                title: Text(content, style: const TextStyle(fontSize: 14)),
                                trailing: Text('$mins min', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await ref.read(planApiProvider).generate();
                    ref.invalidate(currentPlanProvider);
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AI 重新生成'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}
