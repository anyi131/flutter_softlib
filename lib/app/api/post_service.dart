import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_host.dart';

import 'package:dio/dio.dart';

import '../models/post_item.dart';

/// 广场社区服务
class PostService {
  PostService._();
  static final PostService instance = PostService._();

  static const String baseUrl = ApiHost.base;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  ));

  /// 分类
  Future<List<PostCat>> fetchCats() async {
    try {
      final r = await _dio.get('/api/softlib/post/cats');
      if (r.data is Map && r.data['code'] == 1) {
        return PostCat.listFrom(r.data['data']);
      }
    } catch (e) {
      debugPrint('[Softlib] $e');
    }
    return [];
  }

  /// 动态列表
  Future<List<PostItem>> fetchPosts({int page = 1, int catId = 0}) async {
    final r = await _dio.get('/api/softlib/post/index', queryParameters: {
      'pages': page,
      if (catId > 0) 'cat_id': catId,
    });
    if (r.data is Map && r.data['code'] == 1) {
      return PostItem.listFrom(r.data['data']);
    }
    throw Exception('加载失败');
  }

  /// 动态详情
  Future<PostItem?> fetchDetail(int id) async {
    final r = await _dio.get('/api/softlib/post/detail',
        queryParameters: {'id': id});
    if (r.data is Map && r.data['code'] == 1 && r.data['data'] is Map) {
      return PostItem.fromJson(Map<String, dynamic>.from(r.data['data']));
    }
    return null;
  }

  /// 发布
  Future<void> create({
    required String nickname,
    required String content,
    List<String> images = const [],
    int catId = 0,
    String avatar = '',
  }) async {
    final r = await _dio.post('/api/softlib/post/create', data: {
      'nickname': nickname,
      'content': content,
      'images': images.join(','),
      'cat_id': catId,
      'avatar': avatar,
    });
    if (r.data is Map && r.data['code'] != 1) {
      throw Exception(r.data['msg'] ?? '发布失败');
    }
  }

  /// 点赞
  Future<int?> like(int id) async {
    try {
      final r = await _dio.post('/api/softlib/post/like', data: {'id': id});
      if (r.data is Map && r.data['code'] == 1) {
        return int.tryParse('${r.data['data']?['like_count']}');
      }
    } catch (e) {
      debugPrint('[Softlib] $e');
    }
    return null;
  }

  /// 评论列表
  Future<List<Map<String, dynamic>>> comments(int postId) async {
    try {
      final r = await _dio.get('/api/softlib/post/comment_list',
          queryParameters: {'post_id': postId});
      if (r.data is Map && r.data['code'] == 1 && r.data['data'] is List) {
        return List<Map<String, dynamic>>.from((r.data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (e) {
      debugPrint('[Softlib] $e');
    }
    return [];
  }

  /// 发评论
  Future<bool> comment({
    required int postId,
    required String nickname,
    required String content,
    String avatar = '',
  }) async {
    final r = await _dio.post('/api/softlib/post/comment', data: {
      'post_id': postId,
      'nickname': nickname,
      'content': content,
      'avatar': avatar,
    });
    return r.data is Map && r.data['code'] == 1;
  }

  /// 上传图片
  Future<String> uploadImage(File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path,
          filename: file.path.split('/').last),
    });
    final r = await _dio.post('/api/softlib/pic/index',
        data: form, options: Options(receiveTimeout: const Duration(seconds: 60)));
    if (r.data is Map && r.data['code'] == 1) {
      return (r.data['data']['url'] ?? '').toString();
    }
    throw Exception(r.data is Map ? (r.data['msg'] ?? '上传失败') : '上传失败');
  }
}
