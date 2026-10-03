import 'dart:convert';

/// 软件数据模型（对接 /api/softlib/app/index）
///
/// 双来源设计：
/// - provider == 'lzy'   蓝奏云：客户端用 url 调 lzy_file_parse 解析后再下载
/// - provider == 'local' 服务器：客户端直接用 file 直链下载，无需解析
class AppItem {
  final int id;
  final String title;

  /// 'lzy' | 'local'
  final String provider;

  /// 蓝奏云分享地址（provider=lzy）
  final String url;

  /// 服务器直链（provider=local）
  final String file;

  final String icon;
  final String size;
  final String version;
  final String description;
  final int catId;
  final int weigh;
  final int views;
  final String uploadDate;
  final String ageRating;
  final List<String> screenshots;

  AppItem({
    required this.id,
    required this.title,
    required this.provider,
    required this.url,
    required this.file,
    required this.icon,
    required this.size,
    required this.version,
    required this.description,
    required this.catId,
    required this.weigh,
    this.views = 0,
    this.uploadDate = '',
    this.ageRating = '16+',
    this.screenshots = const [],
  });

  bool get isLocal => provider == 'local';

  /// 下载是否可直接进行（无需解析）
  bool get canDirectDownload => isLocal && file.isNotEmpty;

  factory AppItem.fromJson(Map<String, dynamic> json) {
    String s(String k) => (json[k] ?? '').toString();
    int i(String k) => int.tryParse((json[k] ?? '0').toString()) ?? 0;
    return AppItem(
      id: i('id'),
      title: s('title'),
      provider: s('provider').isEmpty ? 'lzy' : s('provider'),
      url: s('url'),
      file: s('file'),
      icon: s('icon'),
      size: s('size'),
      version: s('version'),
      description: s('description'),
      catId: i('cat_id'),
      weigh: i('weigh'),
      views: i('views'),
      uploadDate: s('upload_date'),
      ageRating: s('age_rating').isEmpty ? '16+' : s('age_rating'),
      screenshots: s('screenshots')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }

  static List<AppItem> listFrom(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => AppItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static List<AppItem> listFromRaw(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is Map && j['data'] != null) return listFrom(j['data']);
    } catch (_) {}
    return [];
  }
}
