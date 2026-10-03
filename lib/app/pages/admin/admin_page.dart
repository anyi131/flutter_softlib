import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/admin_service.dart';
import '../../design/app_theme.dart';
import '../../api/user_service.dart';
import '../../utils/toast_util.dart';
import 'tabs/admin_apps_tab.dart';
import 'tabs/admin_content_tab.dart';
import 'tabs/admin_splash_tab.dart';
import 'tabs/admin_users_tab.dart';

/// 软件内嵌管理系统（管理员专用）
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  bool _checking = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final u = UserService.instance.user;
    if (!UserService.instance.isLoggedIn) {
      setState(() {
        _checking = false;
        _isAdmin = false;
      });
      return;
    }
    if (u?.isAdmin != true) {
      await UserService.instance.refreshProfile();
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      _isAdmin = UserService.instance.user?.isAdmin == true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF1F2F6);

    if (_checking) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(title: const Text('管理后台')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(title: const Text('管理后台')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline,
                    size: 56, color: Colors.grey.withAlpha(110)),
                const SizedBox(height: 14),
                const Text('仅管理员可访问',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('请使用管理员账号登录后重试',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('管理后台',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColor.primary,
          labelColor: AppColor.primary,
          unselectedLabelColor: Colors.grey[500],
          labelStyle:
              const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
          unselectedLabelStyle:
              const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: '概览'),
            Tab(text: '软件'),
            Tab(text: '用户'),
            Tab(text: '内容/配置'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _DashboardTab(),
          AdminAppsTab(),
          AdminUsersTab(),
          AdminContentTab(),
        ],
      ),
    );
  }
}

// ==================== 概览 ====================
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic> _d = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await AdminService.instance.dashboard();
      if (mounted) setState(() {
        _d = d;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      ('软件总数', _d['apps'], const Color(0xFF465CFF), Icons.apps_rounded),
      ('用户总数', _d['users'], const Color(0xFF0E9F6E), Icons.people_rounded),
      ('今日注册', _d['today_users'], const Color(0xFFD97706),
          Icons.person_add_rounded),
      ('会员数', _d['vip_users'], const Color(0xFFC9A227),
          Icons.workspace_premium_rounded),
      ('动态数', _d['posts'], const Color(0xFF8B5CF6),
          Icons.forum_rounded),
      ('评价数', _d['reviews'], const Color(0xFFEC4899),
          Icons.rate_review_rounded),
      ('线报文章', _d['reports'], const Color(0xFF06B6D4),
          Icons.article_rounded),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.65,
            children: items
                .map((it) => Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(it.$4, size: 22, color: it.$3),
                          Text('${it.$2 ?? 0}',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0)),
                          Text(it.$1,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AdminSplashTab(),
        ],
      ),
    );
  }
}
