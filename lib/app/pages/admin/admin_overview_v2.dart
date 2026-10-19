import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/admin_service.dart';
import '../../design/adaptive.dart';
import '../../design/ui.dart';
import '../../utils/err_text.dart';
import '../../utils/toast_util.dart';
import 'admin_ui_kit.dart';
import 'mini_chart.dart';

/// ═══════════════════════════════════════════════════════════════
/// 管理后台 · 概览（★ 1020 重做）
///
/// 用户反馈：「样式太丑陋了太垃圾了根本数据不详细」
///
/// 旧版问题：
///   ① 所有指标平铺成一堆 AdMetric 小卡，没有主次
///   ② 只有数字，没有趋势 —— 看不出「今天比昨天好还是差」
///   ③ 信息重复（累计/今日/在线各自一堆卡）
///   ④ 数据虽多但串不起来，看完不知道「现在该关注什么」
///
/// 新版结构（从上到下，按「先看关键 → 再看细节」）：
///   ① 今日健康度大卡     —— 一句话结论 + 三个核心数（今日下载/新增用户/活跃）
///   ② 7 日趋势图         —— 用户 / 下载两条折线，看得见走势
///   ③ 实时在线条         —— 5/15/60 分钟 + 今日活跃
///   ④ 收入卡             —— 累计/本月/今日三档 + 订单状态
///   ⑤ 软件表现           —— Top5 条形榜 + 下载失败率
///   ⑥ 需要处理           —— 待付款/待审/举报，红点提示
///   ⑦ 最近下载流         —— 可点开看详情
///   ⑧ 今日启动用户       —— 具体是谁
/// ═══════════════════════════════════════════════════════════════
class AdminOverviewV2 extends StatefulWidget {
  const AdminOverviewV2({super.key});

  @override
  State<AdminOverviewV2> createState() => _AdminOverviewV2State();
}

class _AdminOverviewV2State extends State<AdminOverviewV2> {
  final _svc = AdminService.instance;

  Map<String, dynamic> _d = {};
  Map<String, dynamic>? _appStats;
  bool _loading = true;
  bool _statsLoading = true;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadAppStats();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = '';
    });
    try {
      final d = await _svc.dashboard();
      if (!mounted) return;
      setState(() {
        _d = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _err = ErrText.of(e);
      });
    }
  }

  Future<void> _loadAppStats({bool force = false}) async {
    setState(() => _statsLoading = true);
    try {
      final d = await _svc.collectEx('app_stats_summary', {
        'limit': 12,
        if (force) 'force': 1,
      });
      if (!mounted) return;
      setState(() {
        _appStats = d;
        _statsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statsLoading = false);
    }
  }

  int _i(String k) => int.tryParse('${_d[k] ?? 0}') ?? 0;
  String _s(String k) => '${_d[k] ?? ''}';
  double _dbl(String k) =>
      double.tryParse('${_d[k] ?? 0}'.replaceAll('%', '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState(text: '加载概览…');
    if (_err.isNotEmpty) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        text: '概览加载失败',
        hint: _err,
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_load(), _loadAppStats(force: true)]);
      },
      color: C.brand,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          context.pagePadding,
          8,
          context.pagePadding,
          30,
        ),
        children: [
          _healthCard(),
          const SizedBox(height: 14),
          _trendCard(),
          const SizedBox(height: 14),
          _onlineCard(),
          const SizedBox(height: 14),
          _moneyCard(),
          const SizedBox(height: 14),
          _todoCard(),
          const SizedBox(height: 14),
          _appCard(),
          const SizedBox(height: 14),
          _recentCard(),
          const SizedBox(height: 14),
          _bootUsersCard(),
        ],
      ),
    );
  }

  // ═══════════ ① 今日健康度 ═══════════

  Widget _healthCard() {
    final downToday = _i('down_today');
    final newUsers = _i('today_users');
    final active = _i('today_active_users');
    final boot = _i('boot_today');
    final failRate = _dbl('down_fail_rate');

    // 一句话结论：先给判断，再给数字
    final String verdict;
    final Color verdictColor;
    if (failRate > 15) {
      verdict = '下载失败率偏高，建议检查解析通道';
      verdictColor = C.danger;
    } else if (downToday == 0 && boot > 0) {
      verdict = '有人打开但没人下载，检查首页推荐';
      verdictColor = C.amber;
    } else if (downToday > 0 && newUsers > 0) {
      verdict = '运行正常，今日有新增用户与下载';
      verdictColor = C.mint;
    } else {
      verdict = '今日暂无活动';
      verdictColor = context.t3;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(R.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? [const Color(0xFF232A42), const Color(0xFF1A1E2E)]
              : [const Color(0xFFF2F5FF), const Color(0xFFFFFFFF)],
        ),
        border: Border.all(
          color: C.brand.withAlpha(context.isDark ? 60 : 40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: C.brand.withAlpha(context.isDark ? 30 : 20),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: verdictColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '今日概况',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: context.t2,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                _dateText(),
                style: Ty.tiny.copyWith(fontSize: 10.5, color: context.t3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            verdict,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: verdictColor == context.t3 ? context.t2 : verdictColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _bigStat('$downToday', '今日下载', C.brand),
              _vline(),
              _bigStat('$newUsers', '新增用户', C.mint),
              _vline(),
              _bigStat('$active', '活跃用户', C.violet),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.isDark ? Colors.white.withAlpha(8) : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _tinyStat(
                    '启动次数',
                    '$boot',
                    Icons.rocket_launch_rounded,
                  ),
                ),
                Expanded(
                  child: _tinyStat(
                    '失败率',
                    '${failRate.toStringAsFixed(1)}%',
                    Icons.error_outline_rounded,
                    warn: failRate > 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateText() {
    final n = DateTime.now();
    const w = ['一', '二', '三', '四', '五', '六', '日'];
    return '${n.month}月${n.day}日 周${w[n.weekday - 1]}';
  }

  Widget _bigStat(String value, String label, Color c) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            height: 1,
            fontWeight: FontWeight.w900,
            color: c,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: Ty.tiny.copyWith(fontSize: 10, color: context.t3)),
      ],
    ),
  );

  Widget _vline() => Container(
    width: 1,
    height: 30,
    color: context.isDark ? Colors.white12 : Colors.black.withAlpha(10),
  );

  Widget _tinyStat(
    String label,
    String value,
    IconData icon, {
    bool warn = false,
  }) => Row(
    children: [
      Icon(icon, size: 12, color: warn ? C.danger : context.t3),
      const SizedBox(width: 4),
      Text(label, style: Ty.tiny.copyWith(fontSize: 10, color: context.t3)),
      const SizedBox(width: 5),
      Text(
        value,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: warn ? C.danger : context.t1,
        ),
      ),
    ],
  );

  // ═══════════ ② 7 日趋势 ═══════════

  Widget _trendCard() {
    final trend = (_d['trend'] as List?) ?? const [];
    if (trend.isEmpty) return const SizedBox.shrink();

    final users = <double>[];
    final downs = <double>[];
    final labels = <String>[];
    for (final e in trend) {
      final m = Map<String, dynamic>.from(e as Map);
      users.add((m['users'] as num?)?.toDouble() ?? 0);
      downs.add((m['downs'] as num?)?.toDouble() ?? 0);
      labels.add('${m['date'] ?? ''}');
    }

    return _card(
      title: '近 7 日趋势',
      icon: Icons.show_chart_rounded,
      trailing: Row(
        children: [
          _legend('新增用户', C.mint),
          const SizedBox(width: 10),
          _legend('下载', C.brand),
        ],
      ),
      child: Column(
        children: [
          MiniLineChart(
            values: users,
            labels: labels,
            color: C.mint,
            height: 88,
          ),
          const SizedBox(height: 8),
          MiniLineChart(
            values: downs,
            labels: labels,
            color: C.brand,
            height: 88,
          ),
        ],
      ),
    );
  }

  Widget _legend(String text, Color c) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(text, style: Ty.tiny.copyWith(fontSize: 9.5, color: context.t3)),
    ],
  );

  // ═══════════ ③ 实时在线 ═══════════

  Widget _onlineCard() {
    return _card(
      title: '实时在线',
      icon: Icons.wifi_tethering_rounded,
      child: Column(
        children: [
          Row(
            children: [
              _pulse('5 分钟', _i('online_5m'), C.mint),
              _pulse('15 分钟', _i('online_15m'), C.brand),
              _pulse('60 分钟', _i('online_60m'), C.violet),
              _pulse('24 小时', _i('online_24h'), context.t3),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _kv('有效会话', '${_i('active_tokens')}'),
              _kv('今日登录', '${_i('today_active_users')}'),
              _kv('启动设备', '${_i('boot_devices_today')}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pulse(String label, int n, Color c) => Expanded(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              '$n',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: c,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(label, style: Ty.tiny.copyWith(fontSize: 9.5, color: context.t3)),
      ],
    ),
  );

  Widget _kv(String k, String v) => Expanded(
    child: Column(
      children: [
        Text(
          v,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: context.t1,
          ),
        ),
        const SizedBox(height: 2),
        Text(k, style: Ty.tiny.copyWith(fontSize: 9.5, color: context.t3)),
      ],
    ),
  );

  // ═══════════ ④ 收入 ═══════════

  Widget _moneyCard() {
    return _card(
      title: '收入',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: C.gold,
      child: Column(
        children: [
          Row(
            children: [
              _money('累计', '¥${_s('total_money')}', C.gold),
              _vline(),
              _money('本月', '¥${_s('month_money')}', C.amber),
              _vline(),
              _money('今日', '¥${_s('today_money')}', C.mint),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _kv('已付订单', '${_i('paid_orders')}'),
              _kv('待付订单', '${_i('unpaid_orders')}'),
              _kv('今日订单', '${_i('today_orders')}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _money(String label, String v, Color c) => Expanded(
    child: Column(
      children: [
        Text(
          v,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: c,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: Ty.tiny.copyWith(fontSize: 9.5, color: context.t3)),
      ],
    ),
  );

  // ═══════════ ⑤ 需要处理 ═══════════

  Widget _todoCard() {
    final pending = _i('pending_orders');
    final unpaid = _i('unpaid_orders');
    final reviews = _i('reviewsPending');
    final reports = _i('open_reports');
    final total = pending + unpaid + reviews + reports;

    return _card(
      title: '需要处理',
      icon: Icons.pending_actions_rounded,
      iconColor: total > 0 ? C.danger : C.mint,
      trailing: total > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: C.danger,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$total',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      child: total == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: C.mint),
                  const SizedBox(width: 6),
                  Text(
                    '没有待处理事项',
                    style: TextStyle(fontSize: 12.5, color: context.t2),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                _todoItem('待发货订单', pending, C.amber),
                _todoItem('未付订单', unpaid, C.violet),
                _todoItem('待审评价', reviews, C.brand),
                _todoItem('未处理举报', reports, C.danger),
              ],
            ),
    );
  }

  Widget _todoItem(String label, int n, Color c) => Expanded(
    child: Column(
      children: [
        Text(
          '$n',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: n > 0 ? c : context.t3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Ty.tiny.copyWith(fontSize: 9, color: context.t3),
        ),
      ],
    ),
  );

  // ═══════════ ⑥ 软件表现 ═══════════

  Widget _appCard() {
    final topApps = (_d['top_apps'] as List?) ?? const [];
    final items = <MapEntry<String, double>>[];
    for (final a in topApps) {
      final m = Map<String, dynamic>.from(a as Map);
      items.add(
        MapEntry(
          '${m['title'] ?? ''}',
          (m['down_count'] as num?)?.toDouble() ?? 0,
        ),
      );
    }
    final downTop = (_d['down_top'] as List?) ?? const [];
    final todayItems = <MapEntry<String, double>>[];
    for (final a in downTop) {
      final m = Map<String, dynamic>.from(a as Map);
      todayItems.add(
        MapEntry('${m['title'] ?? ''}', (m['c'] as num?)?.toDouble() ?? 0),
      );
    }

    return _card(
      title: '软件表现',
      icon: Icons.apps_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _kv('在库软件', '${_i('apps')}'),
              _kv('总下载', '${_i('total_down_all')}'),
              _kv('总浏览', '${_i('total_views')}'),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '累计下载 Top 5',
              style: Ty.tiny.copyWith(
                fontSize: 10.5,
                color: context.t3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            MiniBarList(items: items, maxItems: 5),
          ],
          if (todayItems.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '今日下载 Top 5',
              style: Ty.tiny.copyWith(
                fontSize: 10.5,
                color: context.t3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            MiniBarList(items: todayItems, color: C.mint, maxItems: 5),
          ],
        ],
      ),
    );
  }

  // ═══════════ ⑦ 最近下载 ═══════════

  Widget _recentCard() {
    final list = (_d['recent_downloads'] as List?) ?? const [];
    if (list.isEmpty) return const SizedBox.shrink();
    return _card(
      title: '最近下载',
      icon: Icons.download_rounded,
      child: Column(
        children: list.take(8).map((e) {
          final r = Map<String, dynamic>.from(e as Map);
          final ok = '${r['status']}' == 'ok';
          return InkWell(
            onTap: () => _showDownloadDetail(r),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: ok ? C.mint : C.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r['app_title'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.t1,
                          ),
                        ),
                        if (!ok && '${r['error'] ?? ''}'.isNotEmpty)
                          Text(
                            '${r['error']}'.split('\n').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Ty.tiny.copyWith(
                              fontSize: 9.5,
                              color: C.danger.withAlpha(200),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${r['time_text'] ?? ''}',
                    style: Ty.tiny.copyWith(fontSize: 9.5, color: context.t3),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDownloadDetail(Map<String, dynamic> r) {
    Get.dialog(
      AlertDialog(
        title: Text(
          '${r['app_title'] ?? '下载详情'}',
          style: const TextStyle(fontSize: 15),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _row('状态', '${r['status']}' == 'ok' ? '成功' : '失败'),
              if ('${r['error'] ?? ''}'.isNotEmpty)
                _row('失败原因', '${r['error']}'),
              if ('${r['channel'] ?? ''}'.isNotEmpty)
                _row('解析方式', '${r['channel']}'),
              if ('${r['nickname'] ?? ''}'.isNotEmpty)
                _row('用户', '${r['nickname']}'),
              if ('${r['device'] ?? ''}'.isNotEmpty)
                _row('设备', '${r['device']}'),
              if ('${r['ip'] ?? ''}'.isNotEmpty) _row('IP', '${r['ip']}'),
              if ('${r['time_text'] ?? ''}'.isNotEmpty)
                _row('时间', '${r['time_text']}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('关闭')),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: TextStyle(fontSize: 10.5, color: context.t3)),
        const SizedBox(height: 2),
        SelectableText(
          v,
          style: TextStyle(fontSize: 12.5, height: 1.5, color: context.t1),
        ),
      ],
    ),
  );

  // ═══════════ ⑧ 今日启动用户 ═══════════

  Widget _bootUsersCard() {
    final list = (_d['boot_users'] as List?) ?? const [];
    if (list.isEmpty) return const SizedBox.shrink();
    return _card(
      title: '今日启动用户',
      icon: Icons.people_alt_rounded,
      child: Column(
        children: list.take(8).map((e) {
          final u = Map<String, dynamic>.from(e as Map);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: C.brand.withAlpha(22),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${u['nickname'] ?? '?'}'.characters.first,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: C.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${u['nickname'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.t1,
                        ),
                      ),
                      Text(
                        '${u['version'] ?? ''} · ${u['last'] ?? ''}',
                        style: Ty.tiny.copyWith(
                          fontSize: 9.5,
                          color: context.t3,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${u['count']} 次',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: C.brand,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════ 通用卡片 ═══════════

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
    Widget? trailing,
  }) {
    final c = iconColor ?? C.brand;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withAlpha(12)
              : Colors.black.withAlpha(7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(context.isDark ? 40 : 10),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: c),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.t1,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
