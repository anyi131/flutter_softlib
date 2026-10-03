import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户信息模型
class UserInfo {
  final int id;
  final String username;
  final String nickname;
  final String email;
  final String avatar;
  final String qq;
  final int gender;
  final String bio;
  final int score;
  final String money;
  final bool isVip;
  final String vipExpire;
  final String inviteCode;
  final String jointime;
  final bool isAdmin;

  UserInfo({
    required this.id,
    required this.username,
    required this.nickname,
    required this.email,
    required this.avatar,
    required this.qq,
    required this.gender,
    required this.bio,
    required this.score,
    required this.money,
    required this.isVip,
    required this.vipExpire,
    required this.inviteCode,
    required this.jointime,
    this.isAdmin = false,
  });

  factory UserInfo.fromJson(Map json) {
    String s(String k) => (json[k] ?? '').toString();
    return UserInfo(
      id: int.tryParse(s('id')) ?? 0,
      username: s('username'),
      nickname: s('nickname'),
      email: s('email'),
      avatar: s('avatar'),
      qq: s('qq'),
      gender: int.tryParse(s('gender')) ?? 0,
      bio: s('bio'),
      score: int.tryParse(s('score')) ?? 0,
      money: s('money'),
      isVip: json['is_vip'] == true || s('is_vip') == 'true',
      vipExpire: s('vip_expire'),
      inviteCode: s('invite_code'),
      jointime: s('jointime'),
      isAdmin: json['is_admin'] == true || s('is_admin') == 'true' || s('is_admin') == '1',
    );
  }

  /// 账号（展示用）
  String get account => id > 0 ? (262475940 + id).toString() : '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nickname': nickname,
        'email': email,
        'avatar': avatar,
        'qq': qq,
        'gender': gender,
        'bio': bio,
        'score': score,
        'money': money,
        'is_vip': isVip,
        'vip_expire': vipExpire,
        'invite_code': inviteCode,
        'jointime': jointime,
        'is_admin': isAdmin,
      };
}

/// 用户服务：注册 / 登录 / 找回 / 资料 / QQ头像
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  static const String baseUrl = 'https://flrjk.52yfx.cn';
  static const String _kToken = 'user_token';
  static const String _kUser = 'user_info';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  ));

  String _token = '';
  UserInfo? _user;

  String get token => _token;
  UserInfo? get user => _user;
  bool get isLoggedIn => _token.isNotEmpty && _user != null;

  /// 启动时恢复登录态
  Future<void> restore() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString(_kToken) ?? '';
    final raw = sp.getString(_kUser);
    if (raw != null && raw.isNotEmpty) {
      try {
        _user = UserInfo.fromJson(jsonDecode(raw) as Map);
      } catch (_) {}
    }
  }

  Future<void> _save(String token, UserInfo? info) async {
    _token = token;
    if (info != null) _user = info;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kToken, _token);
    if (_user != null) {
      await sp.setString(_kUser, jsonEncode(_user!.toJson()));
    }
  }

  Future<void> logout() async {
    final t = _token;
    _token = '';
    _user = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kToken);
    await sp.remove(_kUser);
    if (t.isNotEmpty) {
      try {
        await _dio.post('/api/softlib/user/logout', data: {'token': t});
      } catch (_) {}
    }
  }

  /// 统一解析后端 {code,msg,data}
  Map<String, dynamic> _unwrap(Response resp) {
    final d = resp.data;
    if (d is Map) return Map<String, dynamic>.from(d);
    throw Exception('返回格式异常');
  }

  /// 发送邮箱验证码
  Future<void> sendCode(String email, {String scene = 'register'}) async {
    final r = _unwrap(await _dio.post('/api/softlib/user/send_code',
        data: {'email': email, 'scene': scene}));
    if (r['code'] != 1) throw Exception(r['msg'] ?? '发送失败');
  }

  /// 注册
  Future<void> register({
    required String email,
    required String code,
    required String password,
    String nickname = '',
    String qq = '',
  }) async {
    final r = _unwrap(await _dio.post('/api/softlib/user/register', data: {
      'email': email,
      'code': code,
      'password': password,
      'nickname': nickname,
      'qq': qq,
    }));
    if (r['code'] != 1) throw Exception(r['msg'] ?? '注册失败');
    final data = Map<String, dynamic>.from(r['data'] ?? {});
    await _save(
      (data['token'] ?? '').toString(),
      data['userinfo'] is Map ? UserInfo.fromJson(data['userinfo']) : null,
    );
  }

  /// 登录
  Future<void> login(String account, String password) async {
    final r = _unwrap(await _dio.post('/api/softlib/user/login',
        data: {'account': account, 'password': password}));
    if (r['code'] != 1) throw Exception(r['msg'] ?? '登录失败');
    final data = Map<String, dynamic>.from(r['data'] ?? {});
    await _save(
      (data['token'] ?? '').toString(),
      data['userinfo'] is Map ? UserInfo.fromJson(data['userinfo']) : null,
    );
  }

  /// 重置密码
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final r = _unwrap(await _dio.post('/api/softlib/user/reset',
        data: {'email': email, 'code': code, 'password': password}));
    if (r['code'] != 1) throw Exception(r['msg'] ?? '重置失败');
  }

  /// 刷新资料
  Future<UserInfo?> refreshProfile() async {
    if (_token.isEmpty) return null;
    try {
      final r = _unwrap(await _dio.post('/api/softlib/user/profile',
          data: {'token': _token}));
      if (r['code'] == 1 && r['data'] is Map) {
        final info = UserInfo.fromJson(r['data']);
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_kUser, jsonEncode(info.toJson()));
        _user = info;
        return info;
      }
    } catch (_) {}
    return _user;
  }

  /// 更新资料（昵称/QQ/头像等）
  Future<UserInfo?> updateProfile(Map<String, dynamic> fields) async {
    if (_token.isEmpty) throw Exception('请先登录');
    final r = _unwrap(await _dio.post('/api/softlib/user/update',
        data: {...fields, 'token': _token}));
    if (r['code'] != 1) throw Exception(r['msg'] ?? '更新失败');
    if (r['data'] is Map) {
      final info = UserInfo.fromJson(r['data']);
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kUser, jsonEncode(info.toJson()));
      _user = info;
      return info;
    }
    return null;
  }

  /// 每日签到（+5 积分）
  Future<int> signIn() async {
    if (_token.isEmpty) throw Exception('请先登录');
    final r = _unwrap(await _dio.post('/api/softlib/user/sign', data: {'token': _token}));
    if (r['code'] != 1) throw Exception(r['msg'] ?? '签到失败');
    final score = int.tryParse('${r['data']?['score']}') ?? 0;
    await refreshProfile();
    return score;
  }

  /// 查询 QQ 头像（注册前预览用）
  Future<String?> fetchQqAvatar(String qq) async {
    try {
      final resp = await _dio.get('/api/softlib/user/qqavatar',
          queryParameters: {'qq': qq});
      final r = _unwrap(resp);
      if (r['code'] == 1 && r['data'] is Map) {
        return (r['data']['avatar'] ?? '').toString();
      }
    } catch (_) {}
    return null;
  }
}
