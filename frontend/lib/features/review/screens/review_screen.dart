import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/review_api.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<Map<String, dynamic>> _dueList = [];
  int _index = 0;
  bool _showAnswer = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ref.read(reviewApiProvider).getDue();
      setState(() {
        _dueList = list;
        _index = 0;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitReview(int quality) async {
    final id = _dueList[_index]['id'] as String;
    await ref.read(reviewApiProvider).review(id, quality);
    if (_index < _dueList.length - 1) {
      setState(() {
        _index++;
        _showAnswer = false;
      });
    } else {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('复习')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dueList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('当前没有待复习的错题', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : _buildCard(),
    );
  }

  Widget _buildCard() {
    final m = _dueList[_index];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LinearProgressIndicator(value: (_index + 1) / _dueList.length),
          const SizedBox(height: 8),
          Text('${_index + 1} / ${_dueList.length}', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Chip(label: Text(m['subject'] as String? ?? '')),
                    const Spacer(),
                    Text('复习次数: ${m['repetitions'] ?? 0}', style: TextStyle(color: Colors.grey.shade600)),
                  ]),
                  const SizedBox(height: 16),
                  Text(m['question_text'] as String? ?? '', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  if (_showAnswer) ...[
                    const Divider(),
                    Text('答案:', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Text(m['answer_text'] as String? ?? '', style: const TextStyle(fontSize: 16, color: Colors.green)),
                  ],
                ],
              ),
            ),
          ),
          const Spacer(),
          if (!_showAnswer)
            FilledButton(onPressed: () => setState(() => _showAnswer = true), child: const Text('显示答案'))
          else ...[
            const Text('还记得吗？', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _qualityBtn(0, '完全忘了', Colors.red),
                _qualityBtn(3, '有点印象', Colors.orange),
                _qualityBtn(5, '完全掌握', Colors.green),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _qualityBtn(int q, String label, Color color) {
    return Column(
      children: [
        FilledButton.tonal(
          style: FilledButton.styleFrom(backgroundColor: color.withValues(alpha: 0.2)),
          onPressed: () => _submitReview(q),
          child: Text(label, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
