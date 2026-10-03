/// 软件分类
class AppCat {
  final int id;
  final String title;
  final int count;

  AppCat({required this.id, required this.title, required this.count});

  factory AppCat.fromJson(Map j) => AppCat(
        id: int.tryParse('${j['id']}') ?? 0,
        title: (j['title'] ?? '').toString(),
        count: int.tryParse('${j['count']}') ?? 0,
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
