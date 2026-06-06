import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/mistake_provider.dart';

class MistakeListScreen extends ConsumerWidget {
  const MistakeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakes = ref.watch(mistakeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('错题本'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/review'),
            icon: const Icon(Icons.replay),
            label: const Text('复习'),
          ),
          TextButton.icon(
            onPressed: () => context.push('/plan'),
            icon: const Icon(Icons.calendar_month),
            label: const Text('计划'),
          ),
          TextButton.icon(
            onPressed: () => context.push('/tutor'),
            icon: const Icon(Icons.headphones),
            label: const Text('辅导'),
          ),
        ],
      ),
      body: mistakes.when(
        data: (list) => list.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('还没有错题', style: TextStyle(color: Colors.grey, fontSize: 18)),
                    Text('点击右下角 + 添加你的第一道错题', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(mistakeListProvider.future),
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = list[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _subjectColor(m.subject),
                        child: Text(m.subject.isNotEmpty ? m.subject[0] : '?',
                            style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(m.questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${m.mistakeReason} · ${m.tags.join(", ")}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(5, (j) => Icon(
                            Icons.star,
                            size: 14,
                            color: j < m.difficulty ? Colors.amber : Colors.grey.shade300,
                          )),
                        ],
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text('加载失败', style: TextStyle(color: Colors.grey.shade600)),
              Text('$e', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(mistakeListProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/add');
          ref.invalidate(mistakeListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _subjectColor(String subject) {
    const colors = {
      '数学': Colors.blue,
      '物理': Colors.green,
      '化学': Colors.orange,
      '英语': Colors.purple,
      '语文': Colors.red,
      '生物': Colors.teal,
    };
    return colors[subject] ?? Colors.grey;
  }
}
