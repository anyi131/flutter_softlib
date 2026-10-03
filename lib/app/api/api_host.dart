/// 后端服务地址（统一入口，改域名只改这里）
class ApiHost {
  ApiHost._();
  static const String base = 'https://flrjk.52yfx.cn';

  /// 站点详情页（分享二维码指向此处，而非下载直链）
  static String appPage(int id) => '$base/app.html?id=$id';

  /// 管理后台
  static const String admin = '$base/admin/index.php';

  /// 自建蓝奏云解析服务
  static const String lzyProxy = 'https://www.52yfx.cn/lzy.php';
}
