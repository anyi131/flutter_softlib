import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';

import '../../../generated/assets.dart';
import '../../api/soft_service.dart';
import '../../api/user_service.dart';
import '../../models/app_config.dart';
import '../../routes/app_pages.dart';
import '../../utils/jump_util.dart';
import '../../utils/local_splash.dart';

/// 启动页：远程开屏图 + 倒计时 + 公告弹窗（后台可下发，无需发版）
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  AppConfig? _config;
  int _left = 2;
  Timer? _timer;
  bool _entered = false;
  /// 本地自定义开屏图路径（用户「替换开屏」选过才有）
  String _localSplash = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    // ★ 先读本地开屏图（用户选过的图优先，秒开且不依赖网络）
    _localSplash = await LocalSplash.get();
    if (mounted && _localSplash.isNotEmpty) {
      setState(() {});
    }

    final cfg = await SoftService.instance.fetchConfig();
    if (!mounted) return;

    // 维护模式：直接显示维护页，不进入主界面
    if (cfg != null && cfg.maintainEnable) {
      setState(() => _config = cfg);
      return;
    }

    final seconds = (cfg?.splashEnable ?? true)
        ? (cfg?.splashSeconds ?? 2).clamp(1, 10)
        : 0;
    setState(() {
      _config = cfg;
      _left = seconds;
    });

    if (seconds <= 0) {
      _enter();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        _enter();
      }
    });
  }

  /// 进入主界面（并弹出公告）
  void _enter() {
    if (_entered || !mounted) return;
    _entered = true;
    Navigator.of(context).pushReplacementNamed(Routes.index);
    final cfg = _config;
    if (cfg != null && cfg.noticeEnable && cfg.noticeContent.trim().isNotEmpty) {
      // 等主界面挂载后再弹公告
      Future.delayed(const Duration(milliseconds: 600), () {
        _showNotice(cfg);
      });
    }
  }

  /// 公告弹窗
  void _showNotice(AppConfig cfg) {
    showDialog(
      context: Get.context!,
      barrierDismissible: !cfg.noticeForce,
      builder: (ctx) => PopScope(
        canPop: !cfg.noticeForce,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.campaign, color: Color(0xFF465CFF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(cfg.noticeTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: HtmlWidget(
              cfg.noticeContent,
              textStyle: const TextStyle(fontSize: 14.5, height: 1.6),
            ),
          ),
          actions: [
            if (cfg.noticeUrl.isNotEmpty)
              TextButton(
                onPressed: () {
                  JumpUtil.openUrl(cfg.noticeUrl);
                  if (!cfg.noticeForce) Navigator.of(ctx).pop();
                },
                child: const Text('查看详情'),
              ),
            if (!cfg.noticeForce)
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('我知道了'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 维护模式
    if (_config?.maintainEnable == true) {
      return Scaffold(
        backgroundColor: const Color(0xFF1F1F1F),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.construction_rounded,
                    size: 72, color: Color(0xFF465CFF)),
                const SizedBox(height: 20),
                const Text('系统维护中',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(
                  (_config?.maintainText ?? '').isEmpty
                      ? '请稍后再试'
                      : _config?.maintainText ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withAlpha(180), height: 1.6),
                ),
                const SizedBox(height: 26),
                OutlinedButton(
                  onPressed: _boot,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('重新加载'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cfg = _config;
    // ★ 开屏图优先级（用户 #9 的要求）：
    //   ① 用户「替换开屏」选的本地图（本地文件，秒开）
    //   ② 用户存在服务器上的自定义图（老数据兼容 / 换机后）
    //   ③ 后台下发的全局开屏图
    //   ④ 内置默认开屏
    final userSplash = UserService.instance.user?.splashImage ?? '';
    final netImg = userSplash.isNotEmpty
        ? userSplash
        : (cfg?.splashImage ?? '');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 开屏图：本地优先，其次远程
          if (_localSplash.isNotEmpty)
            Image.file(
              File(_localSplash),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _remoteOrDefault(netImg),
            )
          else
            _remoteOrDefault(netImg),

          // 标题/副标题
          if ((cfg?.splashTitle ?? '').isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              child: Column(
                children: [
                  Text(
                    cfg?.splashTitle ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF181818),
                    ),
                  ),
                  if ((cfg?.splashDesc ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      cfg?.splashDesc ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),

          // 右上角跳过 / 倒计时
          Positioned(
            top: 52,
            right: 18,
            child: GestureDetector(
              onTap: _enter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(70),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _left > 0 ? '跳过 $_left' : '跳过',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),

          // 底部品牌
          Positioned(
            left: 0,
            right: 0,
            bottom: 34,
            child: Column(
              children: [
                Text('安逸软件库',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withAlpha(110),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('优质软件 · 持续更新',
                    style: TextStyle(
                        fontSize: 11, color: Colors.black.withAlpha(80))),
              ],
            ),
          ),

          // 点击开屏图跳转
          if ((cfg?.splashUrl ?? '').isNotEmpty)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => JumpUtil.openUrl(cfg?.splashUrl ?? ''),
              ),
            ),
        ],
      ),
    );
  }

  /// 远程开屏图（无则用内置默认）
  Widget _remoteOrDefault(String url) {
    if (url.isEmpty) return _defaultSplash();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => _defaultSplash(),
    );
  }

  /// 默认开屏（后台未设置图片时）
  Widget _defaultSplash() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF465CFF), Color(0xFF7B8CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(Assets.imagesApp, width: 104, height: 104),
          ),
          const SizedBox(height: 22),
          const Text('安逸软件库',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text('优质软件 · 持续更新',
              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
        ],
      ),
    );
  }
}
