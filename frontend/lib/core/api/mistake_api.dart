import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mistake.dart';
import 'api_client.dart';

final mistakeApiProvider = Provider<MistakeApi>((ref) {
  return MistakeApi(ref.read(dioProvider));
});

class MistakeApi {
  final Dio _dio;
  MistakeApi(this._dio);

  Future<List<Mistake>> list() async {
    final r = await _dio.get('/mistakes/');
    return (r.data as List).map((e) => Mistake.fromJson(e)).toList();
  }

  Future<Mistake> get(String id) async {
    final r = await _dio.get('/mistakes/$id');
    return Mistake.fromJson(r.data);
  }

  Future<Mistake> create(Map<String, dynamic> data) async {
    final r = await _dio.post('/mistakes/', data: data);
    return Mistake.fromJson(r.data);
  }

  Future<Mistake> update(String id, Map<String, dynamic> data) async {
    final r = await _dio.put('/mistakes/$id', data: data);
    return Mistake.fromJson(r.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/mistakes/$id');
  }
}
