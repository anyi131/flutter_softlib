import 'dart:io';

import 'package:dio/dio.dart';

import 'api_host.dart';
import 'user_service.dart';

/// 内嵌管理系统服务（需管理员账号登录）
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiHost.base,
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 25),
  ));

  /// 统一 POST（自动带 token）
  Future<Map<String, dynamic>> _post(String action,
      [Map<String, dynamic> extra = const {}]) async {
    try {
      final r = await _dio.post('/api/softlib/admin/$action',
          data: {...extra, 'token': UserService.instance.token});
      if (r.data is Map) {
        final m = Map<String, dynamic>.from(r.data);
        if (m['code'] != 1) throw Exception(m['msg'] ?? '操作失败');
        return m;
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? '网络异常');
    }
    throw Exception('返回格式异常');
  }

  Future<Map<String, dynamic>> dashboard() async =>
      Map<String, dynamic>.from((await _post('dashboard'))['data'] ?? {});

  Future<List<Map<String, dynamic>>> apps({String keyword = ''}) async {
    final d = (await _post('apps', {'keyword': keyword}))['data'];
    return d is List ? d.map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  Future<void> saveApp(Map<String, dynamic> data) async => _post('app_save', data);

  /// 解析蓝奏云链接 / 本地文件 → 自动带出软件信息
  Future<Map<String, dynamic>> parse({required String type, String url = '', String filePath = ''}) async {
    final d = (await _post('parse', {
      'type': type,
      if (url.isNotEmpty) 'url': url,
      if (filePath.isNotEmpty) 'file_path': filePath,
    }))['data'];
    return d is Map ? Map<String, dynamic>.from(d) : {};
  }

  /// 上传本地安装包（multipart）
  Future<Map<String, dynamic>> uploadFile(File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path,
          filename: file.path.split('/').last),
      'token': UserService.instance.token,
    });
    final r = await _dio.post('/api/softlib/admin/upload',
        data: form,
        options: Options(receiveTimeout: const Duration(seconds: 120)));
    if (r.data is Map && r.data['code'] == 1) {
      return Map<String, dynamic>.from(r.data['data'] ?? {});
    }
    throw Exception(r.data is Map ? (r.data['msg'] ?? '上传失败') : '上传失败');
  }

  Future<void> deleteApp(int id) async => _post('app_del', {'id': id});

  Future<List<Map<String, dynamic>>> appCats() async {
    final d = (await _post('app_cats'))['data'];
    return d is List ? d.map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  Future<List<Map<String, dynamic>>> users({String keyword = ''}) async {
    final d = (await _post('users', {'keyword': keyword}))['data'];
    return d is List ? d.map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  Future<void> grantVip(int id, int days) async =>
      _post('user_vip', {'id': id, 'days': days});

  Future<void> setAdmin(int id, bool value) async =>
      _post('user_admin', {'id': id, 'value': value ? 1 : 0});

  Future<void> toggleUserStatus(int id) async =>
      _post('user_status', {'id': id});

  Future<void> deleteUser(int id) async => _post('user_del', {'id': id});

  Future<List<Map<String, dynamic>>> posts() async {
    final d = (await _post('posts'))['data'];
    return d is List ? d.map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  Future<void> deletePost(int id) async => _post('post_del', {'id': id});

  Future<List<Map<String, dynamic>>> reviews() async {
    final d = (await _post('reviews'))['data'];
    return d is List ? d.map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  Future<void> deleteReview(int id) async => _post('review_del', {'id': id});

  Future<Map<String, dynamic>> splash() async =>
      Map<String, dynamic>.from((await _post('splash'))['data'] ?? {});

  Future<void> saveSplash(Map<String, dynamic> data) async =>
      _post('splash_save', data);

  Future<Map<String, dynamic>> config() async =>
      Map<String, dynamic>.from((await _post('config'))['data'] ?? {});

  Future<void> saveConfig(Map<String, dynamic> data) async =>
      _post('config_save', data);
}
