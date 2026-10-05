import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'comic_page.dart';
import 'hero_gallery_page.dart';
import 'drama_page.dart';
import 'movie_page.dart';
import 'quote_music_page.dart';
import 'tools_common.dart';
import 'tools_ext.dart';
import 'tools_live.dart';
import 'tools_local.dart';
import 'tools_missing.dart';
import 'tools_sample.dart';
import 'tools_text.dart';

/// 工具调度中心（v45 —— 对齐样本「简助手」）
///
/// ★ 每个工具都是 App 内的真实页面（不跳浏览器）。
///
/// 匹配优先级：
///   ① route 字段（后端下发，最精确）
///   ② 工具名称（做兼容，防止后端改文案）
///   ③ 返回 null → 调用方回退到外链
VoidCallback? toolRoute(String title, {String target = '', String route = ''}) {
  // ① 优先按后端下发的 route 精确路由
  final rf = _byRoute(route);
  if (rf != null) return rf;

  // ② 退化到名称匹配
  return _byName(title.replaceAll(RegExp(r'\s+'), ''));
}

/// ─────────── route 精确匹配（后端 jzs_tool.route）───────────
VoidCallback? _byRoute(String r) {
  switch (r) {
    // 常用
    case 'calculator': return () => Get.to(() => const CalculatorTool());
    case 'qrcode': return () => Get.to(() => const QrTool());
    case 'compass': return () => Get.to(() => const CompassTool());
    case 'level': return () => Get.to(() => const LevelTool());
    case 'stopwatch': return () => Get.to(() => const StopwatchTool());
    case 'countdown': return () => Get.to(() => const CountdownTool());
    case 'decibel': return () => Get.to(() => const DecibelTool());
    case 'protractor': return () => Get.to(() => const ProtractorTool());
    // 解析
    case 'sniff': return () => Get.to(() => const NoWatermarkTool(mode: 'sniff'));
    case 'nowatermark': return () => Get.to(() => const NoWatermarkTool(mode: 'video'));
    case 'nowatermark_img': return () => Get.to(() => const NoWatermarkTool(mode: 'image'));
    case 'douyin': return () => Get.to(() => const NoWatermarkTool(mode: 'douyin'));
    case 'videoparse': return () => Get.to(() => const NoWatermarkTool(mode: 'vip'));
    case 'musicparse': return () => Get.to(() => const MusicPage());
    case 'lanzou': return () => Get.to(() => const LanzouTool());
    // 美图
    case 'wallpaper': return () => Get.to(() => const WallpaperTool());
    case 'avatar': return () => Get.to(() => const AvatarTool());
    case 'meme': return () => Get.to(() => const MemeTool());
    case 'beauty': return () => Get.to(() => const BeautyTool());
    case 'herogallery': return () => Get.to(() => const HeroGalleryPage());
    case 'picsum': return () => Get.to(() => const PicsumTool());
    // 影视音乐
    case 'movie': return () => Get.to(() => const MoviePage());
    case 'moviesearch': return () => Get.to(() => const MoviePage());
    case 'music': return () => Get.to(() => const MusicPage());
    case 'cctv': return () => Get.to(() => const CctvTool());
    case 'shortvideo': return () => Get.to(() => const DramaPage());
    // 小说漫画
    case 'comic': return () => Get.to(() => const ComicPage());
    case 'novel': return () => Get.to(() => const NovelTool());
    case 'noveldl': return () => Get.to(() => const NovelDlTool());
    // 图片处理
    case 'compress': return () => Get.to(() => const ImageCompressTool());
    case 'jiugongge': return () => Get.to(() => const JiuGongGeTool());
    case 'colorpick': return () => Get.to(() => const ColorPickerTool());
    case 'imagestitch': return () => Get.to(() => const ImageStitchTool());
    case 'sketch': return () => Get.to(() => const SketchTool());
    case 'blur': return () => Get.to(() => const BlurTool());
    case 'roundpic': return () => Get.to(() => const RoundPicTool());
    case 'watermark': return () => Get.to(() => const WatermarkTool());
    // 文本
    case 'pinyin': return () => Get.to(() => const PinyinTool());
    case 'base64': return () => Get.to(() => const Base64Tool());
    case 'morse': return () => Get.to(() => const MorseTool());
    case 'rc4': return () => Get.to(() => const Rc4Tool());
    case 'fancytext': return () => Get.to(() => const FancyTextTool());
    case 'numtocn': return () => Get.to(() => const NumToCnTool());
    case 'translate': return () => Get.to(() => const TranslateTool());
    case 'pinyinabbr': return () => Get.to(() => const PinyinAbbrTool());
    case 'textimage': return () => Get.to(() => const TextImageTool());
    // 计算
    case 'bmi': return () => Get.to(() => const BmiTool());
    case 'relative': return () => Get.to(() => const RelativeTool());
    case 'fuel': return () => Get.to(() => const FuelTool());
    case 'bloodtype': return () => Get.to(() => const BloodTypeTool());
    case 'unit': return () => Get.to(() => const UnitTool());
    case 'exchange': return () => Get.to(() => const ExchangeTool());
    case 'loan': return () => Get.to(() => const LoanTool());
    // 娱乐
    case 'wheel': return () => Get.to(() => const WheelTool());
    case 'game2048': return () => Get.to(() => const Game2048Tool());
    case 'minesweeper': return () => Get.to(() => const MinesweeperTool());
    case 'snake': return () => Get.to(() => const SnakeTool());
    case 'danmaku': return () => Get.to(() => const DanmakuTool());
    case 'piano': return () => Get.to(() => const PianoTool());
    case 'drawboard': return () => Get.to(() => const DrawBoardTool());
    case 'joke': return () => Get.to(() => const JokeTool());
    case 'tiangou': return () => Get.to(() => const CopywritingTool(title: '舔狗日记', samples: kTiangou));
    case 'kfc': return () => Get.to(() => const CopywritingTool(title: '疯狂星期四文案', samples: kKfc));
    // 查询
    case 'weather': return () => Get.to(() => const WeatherTool());
    case 'oilprice': return () => Get.to(() => const OilPriceTool());
    case 'express': return () => Get.to(() => const ExpressTool());
    case 'hotsearch': return () => Get.to(() => const HotSearchTool());
    case 'todayhistory': return () => Get.to(() => const TodayHistoryTool());
    case 'news': return () => Get.to(() => const NewsTool());
    case 'forex': return () => Get.to(() => const ForexTool());
    case 'hitokoto': return () => Get.to(() => const QuotePage());
    // 系统
    case 'deviceinfo': return () => Get.to(() => const DeviceInfoTool());
    case 'deadpixel': return () => Get.to(() => const DeadPixelTool());
    case 'argb': return () => Get.to(() => const ArgBTool());
    case 'mdcolor': return () => Get.to(() => const MdColorTool());
    case 'appmanager': return () => Get.to(() => const AppManagerTool());
    case 'battery': return () => Get.to(() => const BatteryTool());
    // ── v46 样本工具补齐 ──
    case 'ruler': return () => Get.to(() => const RulerTool());
    case 'scoreboard': return () => Get.to(() => const ScoreboardTool());
    case 'calendar': return () => Get.to(() => const CalendarTool());
    case 'motioncue': return () => Get.to(() => const MotionCueTool());
    case 'call': return () => Get.to(() => const CallTool());
    case 'camera': return () => Get.to(() => const CameraTool());
    case 'jianshen': return () => Get.to(() => const JianshenTool());
    case 'recipe': return () => Get.to(() => const RecipeTool());
    case 'dayenglish': return () => Get.to(() => const DayEnglishTool());
    case 'weatherrank': return () => Get.to(() => const WeatherRankTool());
    case 'temperature': return () => Get.to(() => const TemperatureTool());
    case 'earthquake': return () => Get.to(() => const EarthquakeTool());
    case 'devicerank': return () => Get.to(() => const DeviceRankTool());
    case 'exifedit': return () => Get.to(() => const ExifEditTool());
    case 'imageurl': return () => Get.to(() => const ImageUrlTool());
    case 'imagerotate': return () => Get.to(() => const ImageRotateTool());
    case 'solidcolor': return () => Get.to(() => const SolidColorTool());
    case 'gradientcolor': return () => Get.to(() => const GradientColorTool());
    case 'apkscanner': return () => Get.to(() => const ApkScannerTool());
    case 'appstore': return () => Get.to(() => const AppStoreTool());
    case 'apkinstaller': return () => Get.to(() => const ApkInstallerTool());
    case 'fontsize': return () => Get.to(() => const FontSizeTool());
    case 'loudspeaker': return () => Get.to(() => const LoudspeakerTool());
    case 'videowall': return () => Get.to(() => const VideoWallTool());
    case 'fileclean': return () => Get.to(() => const FileCleanTool());
    case 'extractaudio': return () => Get.to(() => const ExtractAudioTool());
    case 'stepcounter': return () => Get.to(() => const StepCounterTool());
    default: return null;
  }
}

/// ─────────── 名称匹配（兼容旧数据/后台自定义名称）───────────
VoidCallback? _byName(String t) {
  // 影视音频
  if (_m(t, ['影视大全', '影视库', '电影大全'])) return () => Get.to(() => const MoviePage());
  if (_m(t, ['影视搜索'])) return () => Get.to(() => const MoviePage());
  if (_m(t, ['河马短剧', '七猫短剧', '红果短剧', '短剧', '爽剧', '追剧']))
    return () => Get.to(() => const DramaPage());
  if (_m(t, ['大米星球', '555影视', '永乐视频']))
    return () => Get.to(() => const MoviePage());
  if (_m(t, ['音乐播放器', '音乐搜索', '听歌', '酷狗音乐', '网易云音乐', 'QQ音乐'])) return () => Get.to(() => const MusicPage());
  if (_m(t, ['漫画书城', '漫画大全', '在线漫画'])) return () => Get.to(() => const ComicPage());
  // 美图
  if (_m(t, ['王者荣耀图集', '王者图集', '英雄图集'])) return () => Get.to(() => const HeroGalleryPage());
  if (_m(t, ['壁纸大全', '壁纸'])) return () => Get.to(() => const WallpaperTool());
  if (_m(t, ['头像大全', '头像'])) return () => Get.to(() => const AvatarTool());
  if (_m(t, ['表情包'])) return () => Get.to(() => const MemeTool());
  if (_m(t, ['随机美女'])) return () => Get.to(() => const BeautyTool());
  // 信息
  if (_m(t, ['每日一言', '每日一句', '每日一文'])) return () => Get.to(() => const QuotePage());
  if (_m(t, ['随机笑话', '笑话大全'])) return () => Get.to(() => const JokeTool());
  if (_m(t, ['舔狗日记'])) return () => Get.to(() => const CopywritingTool(title: '舔狗日记', samples: kTiangou));
  if (_m(t, ['疯狂星期四'])) return () => Get.to(() => const CopywritingTool(title: '疯狂星期四文案', samples: kKfc));
  if (_m(t, ['爱情公寓'])) return () => Get.to(() => const CopywritingTool(title: '爱情公寓语录', samples: kAiqing));
  if (_m(t, ['脑筋急转弯'])) return () => Get.to(() => const CopywritingTool(title: '脑筋急转弯', samples: kNaomin));
  // 计算
  if (_m(t, ['计算器'])) return () => Get.to(() => const CalculatorTool());
  if (_m(t, ['BMI'])) return () => Get.to(() => const BmiTool());
  if (_m(t, ['亲戚称呼'])) return () => Get.to(() => const RelativeTool());
  if (_m(t, ['油耗'])) return () => Get.to(() => const FuelTool());
  if (_m(t, ['血型'])) return () => Get.to(() => const BloodTypeTool());
  if (_m(t, ['单位换算'])) return () => Get.to(() => const UnitTool());
  if (_m(t, ['汇率换算'])) return () => Get.to(() => const ExchangeTool());
  if (_m(t, ['房贷'])) return () => Get.to(() => const LoanTool());
  // 文本
  if (_m(t, ['汉字转拼音'])) return () => Get.to(() => const PinyinTool());
  if (_m(t, ['数字转中文'])) return () => Get.to(() => const NumToCnTool());
  if (_m(t, ['上下标'])) return () => Get.to(() => const SubSupTool());
  if (_m(t, ['Base64'])) return () => Get.to(() => const Base64Tool());
  if (_m(t, ['摩斯电码', '摩尔斯'])) return () => Get.to(() => const MorseTool());
  if (_m(t, ['RC4', 'Rc4'])) return () => Get.to(() => const Rc4Tool());
  if (_m(t, ['特殊文本', '花体字'])) return () => Get.to(() => const FancyTextTool());
  if (_m(t, ['翻译'])) return () => Get.to(() => const TranslateTool());
  if (_m(t, ['拼音缩写'])) return () => Get.to(() => const PinyinAbbrTool());
  // 娱乐
  if (_m(t, ['随机转盘', '转盘'])) return () => Get.to(() => const WheelTool());
  if (_m(t, ['2048'])) return () => Get.to(() => const Game2048Tool());
  if (_m(t, ['扫雷'])) return () => Get.to(() => const MinesweeperTool());
  if (_m(t, ['贪吃蛇'])) return () => Get.to(() => const SnakeTool());
  if (_m(t, ['手持弹幕', '弹幕'])) return () => Get.to(() => const DanmakuTool());
  if (_m(t, ['电子琴', '钢琴'])) return () => Get.to(() => const PianoTool());
  if (_m(t, ['画板', '写字板'])) return () => Get.to(() => const DrawBoardTool());
  // 图片
  if (_m(t, ['二维码'])) return () => Get.to(() => const QrTool());
  if (_m(t, ['图片取色', '取色'])) return () => Get.to(() => const ColorPickerTool());
  if (_m(t, ['九宫格'])) return () => Get.to(() => const JiuGongGeTool());
  if (_m(t, ['图片压缩'])) return () => Get.to(() => const ImageCompressTool());
  // 设计
  if (_m(t, ['ARGB', 'RGBA'])) return () => Get.to(() => const ArgBTool());
  if (_m(t, ['MD配色', 'Material'])) return () => Get.to(() => const MdColorTool());
  // 查询
  if (_m(t, ['天气'])) return () => Get.to(() => const WeatherTool());
  if (_m(t, ['油价'])) return () => Get.to(() => const OilPriceTool());
  if (_m(t, ['快递'])) return () => Get.to(() => const ExpressTool());
  if (_m(t, ['热搜'])) return () => Get.to(() => const HotSearchTool());
  if (_m(t, ['历史上的今天'])) return () => Get.to(() => const TodayHistoryTool());
  // 系统
  if (_m(t, ['设备信息', '手机信息', '系统信息'])) return () => Get.to(() => const DeviceInfoTool());
  if (_m(t, ['坏点检测', '屏幕检测'])) return () => Get.to(() => const DeadPixelTool());
  if (_m(t, ['水平仪'])) return () => Get.to(() => const LevelTool());
  if (_m(t, ['指南针'])) return () => Get.to(() => const CompassTool());
  if (_m(t, ['秒表'])) return () => Get.to(() => const StopwatchTool());
  if (_m(t, ['倒计时'])) return () => Get.to(() => const CountdownTool());
  if (_m(t, ['分贝'])) return () => Get.to(() => const DecibelTool());
  if (_m(t, ['量角器'])) return () => Get.to(() => const ProtractorTool());
  return null;
}

bool _m(String t, List<String> keys) {
  for (final k in keys) {
    if (t == k || t.contains(k)) return true;
  }
  return false;
}

// ═══════════ 趣味文案语料库 ═══════════

const List<String> kTiangou = [
  '今天下雨了，我站在雨里等你，你没来。\n雨水打湿了我的头发，也打湿了我想你的心。\n明天还在这里等你。',
  '你说你喜欢花，我种了一院子的花。\n你说你喜欢风，我跑遍了所有山顶。\n你说你喜欢他，我学会了闭嘴。',
  '我给你发了消息，你没回。\n我想你一定是太忙了。\n没关系，我可以等，等到你有空为止。',
  '今天我学会了做菜，第一个想到的是你。\n可惜我做的菜你吃不到。\n不过没关系，我替你吃了。',
  '我把你设成了特别关心，\n这样你发朋友圈我第一时间就能看到。\n虽然你从来没有发过。',
  '别人问我为什么单身，\n我说我在等一个人。\n其实我也不知道在等谁，只是还没遇到像你一样的。',
  '我今天去看了你喜欢的那部电影，\n一个人坐在最后一排。\n电影很感人，我哭得比女主角还惨。',
  '我知道我们不可能，\n但我还是想每天和你说一句晚安。\n哪怕你从来没有回过。',
];

const List<String> kAiqing = [
  '别难过，你还有我。\n虽然我也不是很靠谱。',
  '人生就是要开心，不开心的时候就看看钱包，然后你就更不开心了。',
  '曾小贤说：好男人就是我，我就是曾小贤。',
  '我不是针对谁，我是说在座的各位都是垃圾。',
  '爱情公寓里没有爱情，只有一群沙雕。',
  '关谷神奇：我分分钟切腹自尽！',
  '吕子乔：我不是随便的人，我随便起来不是人。',
  '人生苦短，必须性感。',
];

const List<String> kKfc = [
  '今天是疯狂星期四，谁V我50，我给他表演一个原地消失。',
  '疯狂星期四，V我50，我请你吃空气，管饱。',
  '你问我爱你有多深，我爱你有几分，我的钱也真，我的爱也真，V我50行不行。',
  '别人都在谈恋爱，只有我在等星期四。',
  '我这一生都是坚定的唯物主义者，唯有V我50这件事上，我希望有来生。',
  '今天星期四，我叫肯德基，你叫V我50。',
  '这个周四不太冷，因为有你的50块。',
  '我在等一个人，等一个愿意V我50的人。',
];

const List<String> kNaomin = [
  '什么东西越洗越脏？\n答案：水',
  '什么车子寸步难行？\n答案：风车',
  '什么东西天气越热，它爬得越高？\n答案：温度计',
  '什么动物没有方向感？\n答案：麋鹿（迷路）',
  '什么东西别人请你吃，但你自己还是要付钱？\n答案：官司',
  '一个人从飞机上掉下来为什么没摔死？\n答案：因为飞机停在地上',
  '哪个字永远写不好？\n答案：坏',
  '什么东西要打破了才能用？\n答案：鸡蛋',
];

const List<String> kEnglish = [
  'The best way to predict the future is to create it.',
  'Life is what happens when you are busy making other plans.',
  'Do not go where the path may lead, go instead where there is no path.',
  'The only way to do great work is to love what you do.',
  'In the middle of difficulty lies opportunity.',
  'Success is not final, failure is not fatal.',
  'It always seems impossible until it is done.',
  'Believe you can and you are halfway there.',
];
