import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/api/api_config.dart';
import '../../../core/api/mistake_api.dart';
import '../../../core/api/ocr_api.dart';
import '../../../core/models/mistake.dart';

class MistakeAddScreen extends ConsumerStatefulWidget {
  const MistakeAddScreen({super.key});

  @override
  ConsumerState<MistakeAddScreen> createState() => _MistakeAddScreenState();
}

class _MistakeAddScreenState extends ConsumerState<MistakeAddScreen> {
  final _form = GlobalKey<FormState>();
  String _subject = '数学';
  String _grade = '初一';
  final _questionCtl = TextEditingController();
  final _answerCtl = TextEditingController();
  String _mistakeReason = '粗心';
  int _difficulty = 3;
  final _tagsCtl = TextEditingController();
  final _sourceCtl = TextEditingController();
  bool _loading = false;
  String? _imageUrl;
  bool _ocrLoading = false;
  Mistake? _editTarget;
  bool get _isEditing => _editTarget != null;

  static const _subjects = ['语文', '数学', '英语', '物理', '化学', '历史', '生物'];
  static const _grades = ['三年级', '四年级', '五年级', '初一', '初二', '初三', '高一', '高二', '高三'];
  static const _reasons = ['粗心', '概念不清', '思路错误', '计算错误', '审题错误', '其他'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Mistake) {
        final m = extra;
        setState(() {
          _editTarget = m;
          _subject = m.subject;
          _grade = m.grade;
          _questionCtl.text = m.questionText;
          _answerCtl.text = m.answerText;
          _mistakeReason = m.mistakeReason;
          _difficulty = m.difficulty;
          _tagsCtl.text = m.tags.join(", ");
          _sourceCtl.text = m.source;
          _imageUrl = m.imageUrl;
        });
      }
    });
  }

  @override
  void dispose() {
    _questionCtl.dispose();
    _answerCtl.dispose();
    _tagsCtl.dispose();
    _sourceCtl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera);
    if (x == null || !mounted) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: x.path,
      compressQuality: 80,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪题目区域',
          lockAspectRatio: false,
          showCropGrid: true,
        ),
        IOSUiSettings(title: '裁剪题目区域', aspectRatioLockEnabled: false, resetButtonHidden: false),
      ],
    );
    if (cropped == null || !mounted) return;
    setState(() => _ocrLoading = true);
    try {
      final result = await ref.read(ocrApiProvider).recognize(cropped.path);
      _questionCtl.text = result.text;
      _imageUrl = result.imageUrl;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('识别完成，共 ${result.text.length} 字')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR 识别失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final tags = _tagsCtl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final data = {
        'subject': _subject,
        'grade': _grade,
        'question_text': _questionCtl.text,
        'answer_text': _answerCtl.text,
        'mistake_reason': _mistakeReason,
        'difficulty': _difficulty,
        'tags': tags,
        'source': _sourceCtl.text,
        if (_imageUrl != null) 'image_url': _imageUrl,
      };
      if (_isEditing) {
        await ref.read(mistakeApiProvider).update(_editTarget!.id, data);
      } else {
        await ref.read(mistakeApiProvider).create(data);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑错题' : '添加错题')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEditing)
              OutlinedButton.icon(
                onPressed: _ocrLoading ? null : _pickImage,
                icon: _ocrLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.camera_alt),
                label: Text(_ocrLoading ? '识别中...' : '拍照录入'),
              ),
            if (_imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '$apiBaseUrl$_imageUrl',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _subjects.contains(_subject) ? _subject : null,
              decoration: const InputDecoration(labelText: '科目', border: OutlineInputBorder()),
              items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _subject = v!),
              validator: (v) => (v == null || v.isEmpty) ? '请选择科目' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _grades.contains(_grade) ? _grade : null,
              decoration: const InputDecoration(labelText: '年级', border: OutlineInputBorder()),
              items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _grade = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _questionCtl,
              decoration: const InputDecoration(labelText: '题目', border: OutlineInputBorder()),
              maxLines: 8,
              minLines: 4,
              validator: (v) => (v == null || v.isEmpty) ? '请输入题目' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _answerCtl,
              decoration: const InputDecoration(labelText: '正确答案', border: OutlineInputBorder()),
              maxLines: 5,
              minLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _mistakeReason,
              decoration: const InputDecoration(labelText: '错因', border: OutlineInputBorder()),
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _mistakeReason = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('难度: '),
                for (int i = 1; i <= 5; i++)
                  IconButton(
                    icon: Icon(i <= _difficulty ? Icons.star : Icons.star_border, color: Colors.amber),
                    onPressed: () => setState(() => _difficulty = i),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsCtl,
              decoration: const InputDecoration(labelText: '知识点标签（逗号分隔）', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceCtl,
              decoration: const InputDecoration(labelText: '来源（如：期中考试）', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? '更新' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}
