import 'package:dio/dio.dart';

import 'api_host.dart';
import 'user_service.dart';

/// 消息通知
class MessageService {
  MessageService._();
  static final MessageService instance = MessageService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiHost.base,
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  ));

  Future<Map<String, dynamic>> list({int page = 1}) async {
    final r = await _dio.get('/api/softlib/message/index', queryParameters: {
      'token': UserService.instance.token,
      'pages': page,
    });
    if (r.data is Map && r.data['code'] == 1 && r.data['data'] is Map) {
      return Map<String, dynamic>.from(r.data['data']);
    }
    return {'list': [], 'unread': 0};
  }

  Future<int> unread() async {
    if (!UserService.instance.isLoggedIn) return 0;
    try {
      final r = await _dio.get('/api/softlib/message/unread',
          queryParameters: {'token': UserService.instance.token});
      if (r.data is Map && r.data['code'] == 1) {
        return int.tryParse('${r.data['data']?['unread']}') ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> markRead({int id = 0}) async {
    await _dio.post('/api/softlib/message/read', data: {
      'token': UserService.instance.token,
      'id': id,
    });
  }

  Future<void> remove(int id) async {
    await _dio.post('/api/softlib/message/delete', data: {
      'token': UserService.instance.token,
      'id': id,
    });
  }
}
