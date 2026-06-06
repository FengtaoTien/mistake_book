import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/mistake_api.dart';
import '../models/mistake.dart';

final mistakeListProvider = FutureProvider<List<Mistake>>((ref) {
  return ref.read(mistakeApiProvider).list();
});
