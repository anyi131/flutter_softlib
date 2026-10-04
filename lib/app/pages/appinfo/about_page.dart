import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../api/soft_service.dart';
import '../../design/adaptive.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../models/app_config.dart';
import '../../utils/jump_util.dart';
import '../../utils/toast_util.dart';

/// 关于软件（v40 重做）
///
/// 全部内容由后台「关于软件」配置下发：
///   应用名 / 版本号 / Logo / 一句话简介 / 详细介绍 /
///   版权 / 联系方式 / 官网 / 检查更新地址 / 自定义条目
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  AppConfig? _cfg;
  String _localVersion = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _localVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    try {
      _cfg = await SoftService.instance.fetchConfig();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          SafeArea(
            bottom: false,
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(context.pagePadding, 8,
                        context.pagePadding, context.tabSpace + 30),
                    children: [
                      _topBar(),
                      const SizedBox(height: 20),
                      _hero(cfg),
                      const SizedBox(height: 22),
                      if ((cfg?.aboutDesc ?? '').isNotEmpty) ...[
                        _descCard(cfg!.aboutDesc),
                        const SizedBox(height: 14),
                      ],
                      _infoList(cfg),
                      const SizedBox(height: 16),
                      _extraEntries(cfg),
                      const SizedBox(height: 22),
                      _footer(cfg),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── 顶栏 ──
  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.isDark ? Colors.white.withAlpha(14) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.isDark
                    ? Colors.white.withAlpha(20)
                    : Colors.black.withAlpha(8),
              ),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: context.t1),
          ),
        ),
        const SizedBox(width: 12),
        ShaderMask(
          shaderCallback: (r) => Deco.aurora().createShader(r),
          child: Text('关于软件',
              style: Ty.h2.copyWith(color: Colors.white, fontSize: 21)),
        ),
      ],
    );
  }

  // ── 头部：Logo + 名称 + 版本 ──
  Widget _hero(AppConfig? cfg) {
    final name = cfg?.aboutName ?? '安逸软件库';
    final logo = cfg?.aboutLogo ?? '';
    final slogan = cfg?.aboutSlogan ?? '';
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: C.brand.withAlpha(context.isDark ? 90 : 60),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: logo.isEmpty
                ? _logoFallback()
                : CachedNetworkImage(
                    imageUrl: logo,
                    fit: BoxFit.cover,
                    memCacheWidth: 200,
                    placeholder: (_, __) => _logoFallback(),
                    errorWidget: (_, __, ___) => _logoFallback(),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(name, style: Ty.h1.copyWith(fontSize: 22, color: context.t1)),
        const SizedBox(height: 6),
        if (slogan.isNotEmpty)
          Text(slogan, style: Ty.small.copyWith(color: context.t3)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _localVersion));
            ToastUtil.success('版本号已复制');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: C.brand.withAlpha(context.isDark ? 40 : 26),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: C.brand.withAlpha(80), width: 0.8),
            ),
            child: Text('v${cfg?.aboutVersion ?? _localVersion}',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: C.brand)),
          ),
        ),
      ],
    );
  }

  Widget _logoFallback() => Container(
        decoration: const BoxDecoration(gradient: Deco.brandGradient),
        alignment: Alignment.center,
        child: const Icon(Icons.android_rounded, color: Colors.white, size: 40),
      );

  // ── 详细介绍 ──
  Widget _descCard(String desc) {
    return KitCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 3.5,
                  height: 14,
                  decoration: BoxDecoration(
                      color: C.brand, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('软件介绍',
                  style: Ty.h3.copyWith(fontSize: 14.5, color: context.t1)),
            ],
          ),
          const SizedBox(height: 10),
          Text(desc,
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.8,
                  color: context.isDark
                      ? Colors.grey[300]
                      : const Color(0xFF41454B))),
        ],
      ),
    );
  }

  // ── 信息列表 ──
  Widget _infoList(AppConfig? cfg) {
    final rows = <List<Widget>>[];
    void add(IconData i, Color c, String label, String value,
        {VoidCallback? onTap}) {
      if (value.isEmpty) return;
      rows.add([
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: c.withAlpha(context.isDark ? 38 : 24),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(i, size: 15, color: c),
        ),
        const SizedBox(width: 11),
        Text(label, style: Ty.body.copyWith(fontSize: 13.5, color: context.t2)),
        const Spacer(),
        Flexible(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Ty.small.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: onTap != null ? C.brand : context.t1)),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 16, color: context.t3),
        ],
      ]);
    }

    final contact = cfg?.aboutContact ?? '';
    final website = cfg?.aboutWebsite ?? '';
    add(Icons.alternate_email_rounded, C.cyan, '联系方式', contact,
        onTap: contact.isEmpty ? null : () => _copy(contact));
    add(Icons.language_rounded, C.mint, '官方网站', website,
        onTap: website.isEmpty ? null : () => JumpUtil.openUrl(website));

    final updateUrl = cfg?.aboutUpdateUrl ?? '';
    add(Icons.system_update_rounded, C.violet, '检查更新',
        updateUrl.isEmpty ? '' : '前往下载最新版',
        onTap: updateUrl.isEmpty ? null : () => JumpUtil.openUrl(updateUrl));

    if (rows.isEmpty) return const SizedBox.shrink();

    return KitCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  thickness: 0.5,
                  color: context.isDark
                      ? Colors.white.withAlpha(14)
                      : Colors.black.withAlpha(8)),
            InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(children: rows[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _copy(String s) {
    Clipboard.setData(ClipboardData(text: s));
    ToastUtil.success('已复制：$s');
  }

  // ── 后台自定义条目（about_extra: [{"title","content","url"}]）──
  Widget _extraEntries(AppConfig? cfg) {
    final raw = cfg?.aboutExtra ?? '';
    if (raw.trim().isEmpty) return const SizedBox.shrink();
    final items = <Map<String, String>>[];
    try {
      final reg = RegExp(r'\{[^{}]*\}');
      for (final m in reg.allMatches(raw)) {
        final o = m.group(0)!;
        String pick(String k) {
          final r = RegExp('"' + k + r'"\s*:\s*"([^"]*)"');
          final mm = r.firstMatch(o);
          return mm?.group(1) ?? '';
        }

        final t = pick('title');
        if (t.isEmpty) continue;
        items.add({'title': t, 'content': pick('content'), 'url': pick('url')});
      }
    } catch (_) {}
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final it in items) ...[
          KitCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            onTap: (it['url'] ?? '').isEmpty
                ? null
                : () => JumpUtil.openUrl(it['url']!),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it['title']!,
                          style: Ty.h3
                              .copyWith(fontSize: 14, color: context.t1)),
                      if ((it['content'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(it['content']!,
                            style: Ty.small.copyWith(color: context.t3)),
                      ],
                    ],
                  ),
                ),
                if ((it['url'] ?? '').isNotEmpty)
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: context.t3),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── 页脚 ──
  Widget _footer(AppConfig? cfg) {
    final copyright = cfg?.aboutCopyright ?? '';
    return Column(
      children: [
        if (copyright.isNotEmpty)
          Text(copyright,
              textAlign: TextAlign.center,
              style: Ty.tiny.copyWith(color: context.t3)),
        const SizedBox(height: 6),
        Text('Made with ❤  by iSh',
            style: Ty.tiny.copyWith(fontSize: 10, color: context.t3)),
      ],
    );
  }
}
