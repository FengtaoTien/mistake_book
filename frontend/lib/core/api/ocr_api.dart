import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final ocrApiProvider = Provider<OcrApi>((ref) {
  return OcrApi(ref.read(dioProvider));
});

class OcrResult {
  final String text;
  final String imageUrl;
  OcrResult({required this.text, required this.imageUrl});
}

class OcrApi {
  final Dio _dio;
  OcrApi(this._dio);

  Future<OcrResult> recognize(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final r = await _dio.post('/ocr/recognize', data: form);
    return OcrResult(
      text: r.data['text'] as String,
      imageUrl: r.data['image_url'] as String,
    );
  }
}
