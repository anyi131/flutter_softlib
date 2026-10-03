/// 广场动态
class PostItem {
  final int id;
  final int userId;
  final String nickname;
  final String avatar;
  final String content;
  final List<String> images;
  final int catId;
  final String catTitle;
  final int likeCount;
  final int commentCount;
  final int views;
  final int createtime;
  final bool isAdmin;
  final bool isVip;
  final String title;

  PostItem({
    required this.id,
    this.userId = 0,
    required this.nickname,
    required this.avatar,
    required this.content,
    required this.images,
    required this.catId,
    required this.catTitle,
    required this.likeCount,
    required this.commentCount,
    required this.views,
    required this.createtime,
    this.isAdmin = false,
    this.isVip = false,
    this.title = '',
  });

  static int _i(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;
  static String _s(dynamic v) => (v ?? '').toString();

  factory PostItem.fromJson(Map j) => PostItem(
        id: _i(j['id']),
        userId: _i(j['user_id']),
        nickname: _s(j['nickname']),
        avatar: _s(j['avatar']),
        content: _s(j['content']),
        images: (j['images'] is List)
            ? (j['images'] as List).map((e) => e.toString()).toList()
            : _s(j['images'])
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
        catId: _i(j['cat_id']),
        catTitle: _s(j['cat_title']),
        likeCount: _i(j['like_count']),
        commentCount: _i(j['comment_count']),
        views: _i(j['views']),
        createtime: _i(j['createtime']),
        isAdmin: j['is_admin'] == 1 || j['is_admin'] == true,
        isVip: j['is_vip'] == 1 || j['is_vip'] == true,
        title: _s(j['title']),
      );

  static List<PostItem> listFrom(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => PostItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// 相对时间
  String get relTime {
    if (createtime <= 0) return '';
    final diff =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - createtime;
    if (diff < 60) return '刚刚';
    if (diff < 3600) return '${diff ~/ 60} 分钟前';
    if (diff < 86400) return '${diff ~/ 3600} 小时前';
    if (diff < 86400 * 30) return '${diff ~/ 86400} 天前';
    final d = DateTime.fromMillisecondsSinceEpoch(createtime * 1000);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

/// 广场分类
class PostCat {
  final int id;
  final String title;
  final int count;
  PostCat({required this.id, required this.title, required this.count});

  factory PostCat.fromJson(Map j) => PostCat(
        id: int.tryParse('${j['id']}') ?? 0,
        title: (j['title'] ?? '').toString(),
        count: int.tryParse('${j['count']}') ?? 0,
      );

  static List<PostCat> listFrom(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => PostCat.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}
