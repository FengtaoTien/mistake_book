import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/api/tutor_api.dart';

class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  String? _sessionId;
  final _messages = <Map<String, dynamic>>[];
  final _textCtl = TextEditingController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  bool _recording = false;
  bool _loading = false;

  @override
  void dispose() {
    _textCtl.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(tutorApiProvider).createSession();
      _sessionId = data['id'] as String;
      final msgs = data['messages'] as List<dynamic>? ?? [];
      setState(() => _messages.addAll(msgs.cast<Map<String, dynamic>>()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建会话失败: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _textCtl.text.trim();
    if (text.isEmpty || _sessionId == null) return;
    _textCtl.clear();
    setState(() {
      _messages.add({"role": "user", "content": text});
      _loading = true;
    });
    try {
      final data = await ref.read(tutorApiProvider).chat(_sessionId!, text: text);
      final msgs = data['messages'] as List<dynamic>;
      setState(() => _messages..clear()..addAll(msgs.cast<Map<String, dynamic>>()));
      _playAudio();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recordAndSend() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path == null || _sessionId == null) return;
      setState(() {
        _messages.add({"role": "user", "content": "🎤 语音消息..."});
        _loading = true;
      });
      try {
        final data = await ref.read(tutorApiProvider).chat(_sessionId!, audioPath: path);
        final msgs = data['messages'] as List<dynamic>;
        setState(() => _messages..clear()..addAll(msgs.cast<Map<String, dynamic>>()));
        _playAudio();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/tutor_audio.mp4';
        await _recorder.start(RecordConfig(), path: path);
        setState(() => _recording = true);
      }
    }
  }

  void _playAudio() {
    final last = _messages.isNotEmpty ? _messages.last : null;
    if (last != null && last['role'] == 'assistant' && last['audio_url'] != null) {
      _player.play(UrlSource('http://10.0.2.2:8000${last['audio_url']}'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 语音辅导')),
      body: _sessionId == null ? _buildStart() : _buildChat(),
    );
  }

  Widget _buildStart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.headphones, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('开始一次 AI 辅导对话'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _startSession,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: const Text('开始辅导'),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              final role = m['role'] as String? ?? '';
              final content = m['content'] as String? ?? '';
              final isUser = role == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(content),
                ),
              );
            },
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, -2)),
          ]),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_recording ? Icons.mic : Icons.mic_none, color: _recording ? Colors.red : null),
                onPressed: _recordAndSend,
              ),
              Expanded(
                child: TextField(
                  controller: _textCtl,
                  decoration: const InputDecoration(
                    hintText: '输入你的问题...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ),
      ],
    );
  }
}
