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

  AppCat({
    required this.id,
    required this.title,
    required this.count,
    this.type = 'local',
    this.url = '',
    this.pwd = '',
  });

  bool get isFolder => type == 'lzy' && url.isNotEmpty;

  factory AppCat.fromJson(Map j) => AppCat(
        id: int.tryParse('${j['id']}') ?? 0,
        title: (j['title'] ?? '').toString(),
        count: int.tryParse('${j['count']}') ?? 0,
        type: (j['type'] ?? 'local').toString(),
        url: (j['url'] ?? '').toString(),
        pwd: (j['pwd'] ?? '').toString(),
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
