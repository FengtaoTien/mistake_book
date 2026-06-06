import 'package:flutter_dotenv/flutter_dotenv.dart';

String get apiBaseUrl => dotenv.get('API_BASE_URL', fallback: 'http://localhost:8000');
