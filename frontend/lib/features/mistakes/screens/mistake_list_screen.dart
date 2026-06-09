import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_config.dart';
import '../../../core/api/mistake_api.dart';
import '../../../core/models/mistake.dart';
import '../../../core/providers/mistake_provider.dart';

final _subjects = ['全部', '语文', '数学', '英语', '物理', '化学', '历史', '生物'];
final _grades = ['全部', '三年级', '四年级', '五年级', '初一', '初二', '初三', '高一', '高二', '高三'];

class MistakeListScreen extends ConsumerStatefulWidget {
  const MistakeListScreen({super.key});

  @override
  ConsumerState<MistakeListScreen> createState() => _MistakeListScreenState();
}

class _MistakeListScreenState extends ConsumerState<MistakeListScreen> {
  String _filterSubject = '全部';
  String _filterGrade = '全部';

  Future<void> _delete(Mistake m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除: ${m.questionText.length > 20 ? '${m.questionText.substring(0, 20)}...' : m.questionText}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(mistakeApiProvider).delete(m.id);
      ref.invalidate(mistakeListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          _buildFilter(),
          Expanded(child: mistakes.when(
            data: (list) {
              final filtered = list.where((m) {
                if (_filterSubject != '全部' && m.subject != _filterSubject) return false;
                if (_filterGrade != '全部' && m.grade != _filterGrade) return false;
                return true;
              }).toList();
              if (filtered.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('没有找到匹配的错题', style: TextStyle(color: Colors.grey, fontSize: 18)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(mistakeListProvider.future),
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = filtered[i];
                    return Dismissible(
                      key: ValueKey(m.id),
                      direction: DismissDirection.endToStart,
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      confirmDismiss: (_) async {
                        await _delete(m);
                        return false;
                      },
                      child: ListTile(
                        onTap: () async {
                          await context.push('/add', extra: m);
                          ref.invalidate(mistakeListProvider);
                        },
                        leading: m.imageUrl != null && m.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '$apiBaseUrl${m.imageUrl}',
                                  width: 48, height: 48, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _subjectAvatar(m),
                                ),
                              )
                            : _subjectAvatar(m),
                        title: Text(m.questionText, maxLines: 3, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${m.grade.isNotEmpty ? "$m.grade · " : ""}${m.mistakeReason} · ${m.tags.join(", ")}',
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
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('加载失败', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(mistakeListProvider),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          )),
        ],
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

  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _filterDropdown(_filterSubject, _subjects, (v) {
            setState(() => _filterSubject = v!);
          }),
          const SizedBox(width: 8),
          _filterDropdown(_filterGrade, _grades, (v) {
            setState(() => _filterGrade = v!);
          }),
        ],
      ),
    );
  }

  Widget _filterDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isDense: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _subjectAvatar(Mistake m) {
    return CircleAvatar(
      backgroundColor: _subjectColor(m.subject),
      child: Text(m.subject.isNotEmpty ? m.subject[0] : '?',
          style: const TextStyle(color: Colors.white)),
    );
  }

  Color _subjectColor(String subject) {
    const colors = {
      '语文': Colors.red,
      '数学': Colors.blue,
      '英语': Colors.purple,
      '物理': Colors.green,
      '化学': Colors.orange,
      '历史': Colors.brown,
      '生物': Colors.teal,
    };
    return colors[subject] ?? Colors.grey;
  }
}
