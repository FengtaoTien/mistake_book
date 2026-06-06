import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/plan_api.dart';

final currentPlanProvider = FutureProvider<PlanData?>((ref) {
  return ref.read(planApiProvider).getCurrent();
});
