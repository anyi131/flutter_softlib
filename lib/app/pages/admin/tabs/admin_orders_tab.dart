import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/admin_service.dart';
import '../../../design/adaptive.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/toast_util.dart';

/// 后台 · 订单管理
/// 收入概览 + 状态筛选 + 订单列表（补单 / 删除）
class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab>
    with AutomaticKeepAliveClientMixin {
  final _svc = AdminService.instance;
  bool _loading = true;
  List<Map<String, dynamic>> _list = [];
  Map<String, dynamic> _stats = {};
  int? _status; // null=全部 0=待支付 1=已支付
  final _kwCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _kwCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _svc.orders(status: _status, keyword: _kwCtrl.text.trim()),
        _svc.orderStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _list = results[0] as List<Map<String, dynamic>>;
        _stats = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _statsRow(),
        _filterRow(),
        Expanded(
          child: _loading
              ? const LoadingState(text: '加载订单…')
              : (_list.isEmpty
                  ? const EmptyState(
                      text: '暂无订单',
                      hint: '用户购买会员后订单会显示在这里',
                      icon: Icons.receipt_long_rounded,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                            context.pagePadding, 4, context.pagePadding, 24),
                        itemCount: _list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _orderCard(_list[i]),
                      ),
                    )),
        ),
      ],
    );
  }

  /// 收入概览（总/今日/已付/待付）
  Widget _statsRow() {
    final items = [
      ('总收入', '¥${_stats['total_money'] ?? '0.00'}', C.gold),
      ('今日', '¥${_stats['today_money'] ?? '0.00'}', C.success),
      ('已支付', '${_stats['paid_count'] ?? 0}', C.brand),
      ('待支付', '${_stats['unpaid_count'] ?? 0}', C.warning),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 10, context.pagePadding, 6),
      child: GlassCard(
        radius: R.lg,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 28,
                  color: context.isDark
                      ? Colors.white.withAlpha(14)
                      : Colors.black.withAlpha(8),
                ),
              Expanded(
                child: Column(
                  children: [
                    Text(items[i].$2,
                        style: Ty.h3.copyWith(
                            fontSize: 15, color: items[i].$3)),
                    const SizedBox(height: 3),
                    Text(items[i].$1,
                        style: Ty.tiny.copyWith(color: context.t3)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterRow() {
    const labels = ['全部', '待支付', '已支付'];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 6, context.pagePadding, 8),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            GestureDetector(
              onTap: () {
                setState(() => _status = i == 0 ? null : i - 1);
                _load();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: (_status == (i == 0 ? null : i - 1))
                      ? C.brand
                      : (context.isDark ? C.bg2 : Colors.white),
                  borderRadius: BorderRadius.circular(R.full),
                  border: Border.all(
                    color: (_status == (i == 0 ? null : i - 1))
                        ? C.brand
                        : (context.isDark
                            ? Colors.white.withAlpha(20)
                            : Colors.black.withAlpha(8)),
                  ),
                ),
                child: Text(labels[i],
                    style: Ty.tiny.copyWith(
                      fontWeight: FontWeight.w800,
                      color: (_status == (i == 0 ? null : i - 1))
                          ? Colors.white
                          : context.t2,
                    )),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Spacer(),
          IconButton(
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded, size: 20, color: context.t2),
            tooltip: '刷新',
          ),
        ],
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> o) {
    final paid = o['status'] == 1 || o['status'] == '1';
    final money = (o['money'] ?? '').toString();
    final name = (o['name'] ?? '').toString();
    final no = (o['out_trade_no'] ?? '').toString();
    final user = (o['nickname'] ?? '').toString().isNotEmpty
        ? o['nickname'].toString()
        : (o['email'] ?? '').toString();
    final payType = {'alipay': '支付宝', 'wxpay': '微信', 'qqpay': 'QQ'}[
            (o['pay_type'] ?? '').toString()] ??
        (o['pay_type'] ?? '').toString();
    final time = (paid
            ? (o['paytime_text'] ?? '')
            : (o['createtime_text'] ?? ''))
        .toString();

    return KitCard(
      radius: R.md,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: Ty.h3.copyWith(fontSize: 14.5, color: context.t1)),
              ),
              Text('¥$money',
                  style: Ty.h3.copyWith(fontSize: 16, color: C.gold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Pill(paid ? '已支付' : '待支付',
                  color: paid ? C.success : C.warning, small: true),
              const SizedBox(width: 6),
              if (payType.isNotEmpty)
                Pill(payType, color: C.brand, small: true),
              const Spacer(),
              Text(time, style: Ty.tiny.copyWith(color: context.t3)),
            ],
          ),
          const SizedBox(height: 8),
          Text('$user · $no',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Ty.tiny.copyWith(color: context.t3)),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!paid)
                MiniAction(
                  label: '补单',
                  icon: Icons.check_circle_outline_rounded,
                  color: C.success,
                  onTap: () => _deliver(no),
                ),
              const Spacer(),
              MiniAction(
                label: '删除',
                icon: Icons.delete_outline_rounded,
                color: C.danger,
                onTap: () => _delete((o['id'] ?? 0) as int),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deliver(String no) async {
    final go = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('确认补单'),
        content: Text('将把该订单标记为已支付，并给用户开通对应会员。\n订单号：$no'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false), child: const Text('取消')),
          FilledButton(
              onPressed: () => Get.back(result: true), child: const Text('确认补单')),
        ],
      ),
    );
    if (go != true) return;
    try {
      await _svc.deliverOrder(no);
      ToastUtil.success('补单成功，会员已到账');
      _load();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete(int id) async {
    final go = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('删除订单'),
        content: const Text('仅删除记录，不会回收已开通的会员。确认删除？'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false), child: const Text('取消')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.danger),
              onPressed: () => Get.back(result: true),
              child: const Text('删除')),
        ],
      ),
    );
    if (go != true) return;
    try {
      await _svc.deleteOrder(id);
      ToastUtil.success('已删除');
      _load();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
