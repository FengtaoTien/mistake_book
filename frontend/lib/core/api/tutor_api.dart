import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final tutorApiProvider = Provider<TutorApi>((ref) {
  return TutorApi(ref.read(dioProvider));
});

class TutorApi {
  final Dio _dio;
  TutorApi(this._dio);

  Future<Map<String, dynamic>> createSession({String? mistakeId}) async {
    final r = await _dio.post('/tutor/sessions', data: {'mistake_id': mistakeId});
    return r.data;
  }

  Future<Map<String, dynamic>> chat(String sessionId, {String text = '', String? audioPath}) async {
    final form = FormData.fromMap({'text': text});
    if (audioPath != null) {
      form.files.add(MapEntry('audio', await MultipartFile.fromFile(audioPath)));
    }
    final r = await _dio.post('/tutor/sessions/$sessionId/chat', data: form);
    return r.data;
  }
}
