/// 软件分类
class AppCat {
  final int id;
  final String title;
  final int count;

  /// local=本站上架 / lzy=蓝奏云文件夹
  final String type;

  /// 蓝奏云文件夹地址（type=lzy 时有值）
  final String url;
  final String pwd;

  /// 数据源统一介绍/截图（后台「数据源」配置，v52i #2）
  final String defaultDesc;
  final String defaultShots;
  final String defaultIcon;

  AppCat({
    required this.id,
    required this.title,
    required this.count,
    this.type = 'local',
    this.url = '',
    this.pwd = '',
    this.defaultDesc = '',
    this.defaultShots = '',
    this.defaultIcon = '',
  });

  bool get isFolder => type == 'lzy' && url.isNotEmpty;

  factory AppCat.fromJson(Map j) => AppCat(
    id: int.tryParse('${j['id']}') ?? 0,
    title: (j['title'] ?? '').toString(),
    count: int.tryParse('${j['count']}') ?? 0,
    type: (j['type'] ?? 'local').toString(),
    url: (j['url'] ?? '').toString(),
    pwd: (j['pwd'] ?? '').toString(),
    defaultDesc: (j['default_desc'] ?? '').toString(),
    defaultShots: (j['default_shots'] ?? '').toString(),
    defaultIcon: (j['default_icon'] ?? '').toString(),
  );

  static List<AppCat> listFrom(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => AppCat.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}
