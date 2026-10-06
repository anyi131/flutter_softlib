import 'package:get/get.dart';

import '../../api/api_host.dart';

import 'drama_page.dart';
import 'movie_page.dart';
import 'quote_music_page.dart';
import 'tools_v2.dart';

/// 工具路由 v2 —— 全部指向重构后的页面
/// route 名与后台 jzs_tool.route 对应；api_url 经 Get.arguments 传入
Function? toolRoute(String title, {String target = '', String route = ''}) {
  switch (route) {
    case 'hotsearch':
      return () => Get.to(
        () => V2ListPage(
          title: title,
          fallbackUrl: 'https://60s-api.viki.moe/v2/weibo',
        ),
      );
    case 'news':
      return () => Get.to(() => const V2DailyNewsPage());
    case 'translate':
      return () => Get.to(() => const V2TranslatePage());
    case 'exchange':
      return () => Get.to(() => const V2ExchangePage());
    case 'earthquake':
      return () => Get.to(
        () => V2ListPage(
          title: title,
          fallbackUrl: '${ApiHost.base}/api/softlib/media/earthquake',
        ),
      );
    case 'ipquery':
      return () => Get.to(() => const V2IpPage());
    case 'qrcode':
      return () => Get.to(() => const V2QrcodePage());
    case 'stopwatch':
      return () => Get.to(() => const V2StopwatchPage());
    case 'countdown':
      return () => Get.to(() => const V2CountdownPage());
    case 'movie':
    case 'moviesearch':
      return () => Get.to(() => const MoviePage());
    case 'music':
      return () => Get.to(() => const MusicPage());
    case 'shortvideo':
      return () => Get.to(() => const DramaPage());
  }
  // 名称兜底
  final t = title.toLowerCase();
  if (t.contains('热搜') || t.contains('热榜')) {
    return () => Get.to(
      () => V2ListPage(
        title: title,
        fallbackUrl: 'https://60s-api.viki.moe/v2/weibo',
      ),
    );
  }
  if (t.contains('60秒') || t.contains('日报')) {
    return () => Get.to(() => const V2DailyNewsPage());
  }
  if (t.contains('翻译')) return () => Get.to(() => const V2TranslatePage());
  if (t.contains('汇率')) return () => Get.to(() => const V2ExchangePage());
  if (t.contains('地震')) {
    return () => Get.to(
      () => V2ListPage(
        title: title,
        fallbackUrl: '${ApiHost.base}/api/softlib/media/earthquake',
      ),
    );
  }
  if (t.contains('二维码')) return () => Get.to(() => const V2QrcodePage());
  if (t.contains('秒表')) return () => Get.to(() => const V2StopwatchPage());
  if (t.contains('倒计时') || t.contains('计时器')) {
    return () => Get.to(() => const V2CountdownPage());
  }
  if (t.contains('影视') || t.contains('视频') || t.contains('星球')) {
    return () => Get.to(() => const MoviePage());
  }
  if (t.contains('短剧') || t.contains('爽剧')) {
    return () => Get.to(() => const DramaPage());
  }
  if (t.contains('音乐')) return () => Get.to(() => const MusicPage());
  return null;
}
