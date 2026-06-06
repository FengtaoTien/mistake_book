import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final reviewApiProvider = Provider<ReviewApi>((ref) {
  return ReviewApi(ref.read(dioProvider));
});

class ReviewApi {
  final Dio _dio;
  ReviewApi(this._dio);

  Future<List<Map<String, dynamic>>> getDue() async {
    final r = await _dio.get('/reviews/due');
    return List<Map<String, dynamic>>.from(r.data);
  }

  Future<Map<String, dynamic>> review(String mistakeId, int quality) async {
    final r = await _dio.post('/reviews/$mistakeId/review', data: {'quality': quality});
    return r.data;
  }
}
