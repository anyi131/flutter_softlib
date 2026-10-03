import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_softlib/app/database/database.dart';
import 'package:flutter_softlib/app/http/http_api.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/design/app_theme.dart';
import 'app/design/ui.dart';
import 'app/widgets/pro_motion.dart';
import 'app/api/user_service.dart';

/// 应用程序主入口
Future<void> main() async {
  try {
    // 确保Flutter框架初始化
    WidgetsFlutterBinding.ensureInitialized();
    // 初始化各种服务
    await _initializeServices();
    // 运行应用
    runApp(const SoftLibApp());
  } catch (error, stackTrace) {
    // 捕获启动异常
    debugPrint('应用启动失败: $error');
    debugPrint('堆栈跟踪: $stackTrace');
    // 运行错误页面
    runApp(_buildErrorApp(error.toString()));
  }
}

/// 初始化应用服务
Future<void> _initializeServices() async {
  // 初始化下载器
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  // 初始化数据库
  Get.put<AppDatabase>(AppDatabase(), permanent: true);
  // 初始化HTTP服务
  Get.lazyPut(() => HttpApi(_createDioInstance()));
  // 恢复登录态（读取本地 token + 用户资料）
  await UserService.instance.restore();
  // 配置EasyLoading
  _configureEasyLoading();
  // 设置设备方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

/// 创建Dio实例
Dio _createDioInstance() {
  final dio = Dio();
  // 配置默认选项
  dio.options.connectTimeout = const Duration(seconds: 6);
  dio.options.receiveTimeout = const Duration(seconds: 6);
  dio.options.sendTimeout = const Duration(seconds: 6);
  return dio;
}

/// 配置EasyLoading样式
void _configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
}


// ============ SonPro 风格设计系统 ============
/// 品牌主色（蓝紫）
const Color kBrandPrimary = Color(0xFF4B5EF5);
/// 强调色（橙红，用于按钮/徽标）
const Color kBrandAccent = Color(0xFFFF6B35);
/// 浅灰分块背景（亮色模式卡片底）
const Color kBrandBgLight = Color(0xFFF4F5F9);
/// 暗色卡片底
const Color kBrandCardDark = Color(0xFF1A1D23);

/// 亮色/暗色主题统一由设计系统构建（见 design/app_theme.dart）
ThemeData buildLightTheme() => buildNewTheme(dark: false);
ThemeData buildDarkTheme() => buildNewTheme(dark: true);

/// 软件库应用主组件
class SoftLibApp extends StatelessWidget {
  const SoftLibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '软件库App',
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.splash,
      getPages: AppPages.routes,
      builder: (context, child) {
        // 全局高刷：常驻 Ticker 请求设备最高刷新率
        return HighRefreshScope(
          child: EasyLoading.init()(context, child),
        );
      },
      // 统一使用 iOS 风格右滑过渡（GetX 路由）
      // iOS 风格右滑过渡（比默认的 Android 缩放自然很多）
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      opaqueRoute: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale("zh", "CN"), Locale("en", "US")],
      locale: const Locale("zh", "CN"),
    );
  }
}

/// 构建错误应用页面
Widget _buildErrorApp(String error) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                '应用启动失败',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.red[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // 重启应用
                  SystemNavigator.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                ),
                child: const Text('退出应用'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
