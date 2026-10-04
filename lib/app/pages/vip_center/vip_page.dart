import 'dart:async';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../api/pay_service.dart';
import '../../api/user_service.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/toast_util.dart';

/// 开通会员 / VIP 中心页
/// VIP PRO 头卡 + 三档套餐 + 支付方式 + 立即开通 + 会员权益
/// 套餐与价格由后台配置下发（pay/plans），支付走易支付收银台
class VipPage extends StatefulWidget {
  const VipPage({super.key});

  @override
  State<VipPage> createState() => _VipPageState();
}

class _VipPageState extends State<VipPage> {
  /// 默认套餐（后端拉取失败时的兜底，保证页面可用）
  List<PayPlan> _plans = const [
    PayPlan(id: 'plan1', name: '一周会员', money: '8', days: 7),
    PayPlan(id: 'plan2', name: '三个月会员', money: '28.88', days: 90),
    PayPlan(id: 'plan3', name: '永久会员', money: '45.99', days: 0),
  ];
  bool _payEnabled = false;
  bool _loadingPlans = true;
  bool _submitting = false;
  Map<String, int> _methods = {'alipay': 1, 'wxpay': 1, 'qqpay': 1};

  int _selectedPlan = 1; // 默认选中「推荐」的三个月
  int _payMethod = 0; // 0 支付宝 1 微信 2 QQ

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final r = await PayService.instance.plans();
      final list = (r['planList'] as List?)?.cast<PayPlan>() ?? [];
      if (!mounted) return;
      setState(() {
        if (list.isNotEmpty) _plans = list;
        _payEnabled = r['enabled'] == 1 || r['enabled'] == true;
        final m = r['methods'];
        if (m is Map) {
          _methods = {
            'alipay': (m['alipay'] ?? 1) as int,
            'wxpay': (m['wxpay'] ?? 1) as int,
            'qqpay': (m['qqpay'] ?? 1) as int,
          };
        }
        _loadingPlans = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  bool _methodOn(int i) {
    final k = ['alipay', 'wxpay', 'qqpay'][i];
    return (_methods[k] ?? 1) == 1;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          ListView(
            // ★ 顶部留出状态栏 + 悬浮返回栏的高度，避免内容被遮挡
            padding: EdgeInsets.fromLTRB(14, topInset + 52, 14, 28),
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 18),
              SectionHeader(
                title: '选择套餐',
                accent: C.gold,
              ),
              Row(
                children: List.generate(_plans.length, (i) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: i == _plans.length - 1 ? 0 : 10),
                      child: _buildPlanCard(i),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: '支付方式'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildPayItem(0, '支付宝', Icons.account_balance_wallet_outlined),
                  const SizedBox(width: 10),
                  _buildPayItem(1, '微信', Icons.chat_bubble_outline),
                  const SizedBox(width: 10),
                  _buildPayItem(2, 'QQ', Icons.pets_outlined),
                ],
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: '立即开通会员',
                icon: Icons.workspace_premium_rounded,
                gold: true,
                onPressed: _onBuy,
              ),
              const SizedBox(height: 20),
              KitCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: '会员权益', accent: C.gold),
                    _benefit('不限次数下载软件库资源'),
                    _benefit('评论区展示会员身份标识'),
                    _benefit('新功能和资源优先体验'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  '支付完成后会员状态会自动同步到账户',
                  style: Ty.tiny.copyWith(color: context.t3),
                ),
              ),
            ],
          ),
          // 悬浮返回栏（透明背景，仅一个圆形返回按钮）
          Positioned(
            top: topInset + 4,
            left: 12,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.isDark
                      ? Colors.white.withAlpha(16)
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.isDark
                        ? Colors.white.withAlpha(24)
                        : Colors.black.withAlpha(8),
                  ),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: context.t1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部 VIP PRO 头卡（深色渐变 + 金色标题）
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3226), Color(0xFF241F18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(R.xl),
        boxShadow: [
          BoxShadow(
            color: C.gold.withAlpha(context.isDark ? 60 : 34),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: Deco.goldGradient,
              borderRadius: BorderRadius.circular(R.full),
            ),
            child: const Text(
              'VIP PRO',
              style: TextStyle(
                color: Color(0xFF241F18),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '解锁完整软件库体验',
            style: TextStyle(
              color: Color(0xFFF7E6B8),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '会员资源、专属标识、优先服务一次开通，所有套餐均自动对接后台价格。',
            style: TextStyle(
              color: const Color(0xFFF7E6B8).withAlpha(200),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 套餐卡片
  Widget _buildPlanCard(int index) {
    final plan = _plans[index];
    final selected = _selectedPlan == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? (context.isDark
                  ? C.bg3
                  : C.gold.withAlpha(18))
              : (context.isDark ? C.bg2 : Colors.white),
          borderRadius: BorderRadius.circular(R.md),
          border: Border.all(
            color: selected ? C.gold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Pill(
              _planTag(index),
              color: index == 1 ? C.gold : context.t3,
              solid: index == 1,
              small: true,
            ),
            const SizedBox(height: 10),
            Text(
              plan.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Ty.small.copyWith(
                  fontSize: 14, fontWeight: FontWeight.w700, color: context.t1),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('¥',
                    style: Ty.small.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: C.accentOrange)),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    plan.money,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ty.h1.copyWith(
                        fontSize: 22, color: C.accentOrange),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 支付方式项
  Widget _buildPayItem(int index, String label, IconData icon) {
    final on = _methodOn(index);
    final selected = _payMethod == index && on;
    final accent = C.brand;
    return Expanded(
      child: Opacity(
        opacity: on ? 1 : 0.4,
        child: GestureDetector(
          onTap: on
              ? () => setState(() => _payMethod = index)
              : () => ToastUtil.info('该支付方式暂未开放'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 44,
            decoration: BoxDecoration(
              color: selected
                  ? accent.withAlpha(context.isDark ? 38 : 22)
                  : (context.isDark ? C.bg2 : Colors.white),
              borderRadius: BorderRadius.circular(R.sm),
              border: Border.all(
                color: selected
                    ? accent.withAlpha(150)
                    : (context.isDark
                        ? Colors.white.withAlpha(22)
                        : Colors.black.withAlpha(20)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: selected ? accent : context.t3),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Ty.small.copyWith(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? accent : context.t2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: C.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Ty.body.copyWith(fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  /// 套餐角标（按位置给语义化标签）
  String _planTag(int index) {
    switch (index) {
      case 0:
        return '体验';
      case 1:
        return '推荐';
      default:
        return _plans.length > 2 && _plans[index].days == 0 ? '长期' : '超值';
    }
  }

  /// 下单 → 打开收银台 → 轮询支付结果 → 刷新会员状态
  Future<void> _onBuy() async {
    if (_submitting) return;
    if (!UserService.instance.isLoggedIn) {
      ToastUtil.info('请先登录后再开通会员');
      Get.toNamed('/login');
      return;
    }
    if (!_payEnabled) {
      ToastUtil.info('支付功能暂未开启，请联系管理员');
      return;
    }
    final plan = _plans[_selectedPlan];
    final payType = ['alipay', 'wxpay', 'qqpay'][_payMethod];

    setState(() => _submitting = true);
    try {
      final order = await PayService.instance.create(
        planId: plan.id,
        payType: payType,
      );
      if (order.payUrl.isEmpty) {
        ToastUtil.error('下单失败，请稍后重试');
        return;
      }
      // ★ App 内打开收银台（不跳转外部浏览器）
      Get.toNamed('/payWeb', arguments: {
        'pay_url': order.payUrl,
        'out_trade_no': order.outTradeNo,
        'money': order.money,
      });
      if (mounted) setState(() => _submitting = false);
      return;
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && _submitting) setState(() => _submitting = false);
    }
  }

}
