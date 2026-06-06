import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final planApiProvider = Provider<PlanApi>((ref) {
  return PlanApi(ref.read(dioProvider));
});

class PlanData {
  final String id;
  final String weekStart;
  final Map<String, dynamic> planJson;
  final int progress;
  final bool completed;

  PlanData({required this.id, required this.weekStart, required this.planJson, required this.progress, required this.completed});

  factory PlanData.fromJson(Map<String, dynamic> json) => PlanData(
    id: json['id'] as String,
    weekStart: json['week_start'] as String,
    planJson: json['plan_json'] as Map<String, dynamic>,
    progress: json['progress'] as int? ?? 0,
    completed: json['completed'] as bool? ?? false,
  );
}

class PlanApi {
  final Dio _dio;
  PlanApi(this._dio);

  Future<PlanData?> getCurrent() async {
    final r = await _dio.get('/plans/');
    if (r.data == null) return null;
    return PlanData.fromJson(r.data);
  }

  Future<PlanData> generate() async {
    final r = await _dio.post('/plans/generate');
    return PlanData.fromJson(r.data);
  }
}
