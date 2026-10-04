import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../design/kit.dart';
import '../../design/ui.dart';

/// 开通会员 / VIP 中心页
/// 复刻用户提供的截图：VIP PRO 头卡 + 三档套餐 + 支付方式 + 立即开通 + 会员权益
class VipPage extends StatefulWidget {
  const VipPage({super.key});

  @override
  State<VipPage> createState() => _VipPageState();
}

class _Plan {
  final String name;
  final String price;
  final String tag;
  final bool recommended;
  const _Plan(this.name, this.price, this.tag, {this.recommended = false});
}

class _VipPageState extends State<VipPage> {
  final List<_Plan> _plans = const [
    _Plan('一周会员', '8', '体验'),
    _Plan('三个月会员', '28.88', '推荐', recommended: true),
    _Plan('永久', '45.99', '长期'),
  ];

  int _selectedPlan = 0;
  int _payMethod = 0; // 0 支付宝 1 微信 2 QQ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
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
              plan.tag,
              color: plan.recommended ? C.gold : context.t3,
              solid: plan.recommended,
              small: true,
            ),
            const SizedBox(height: 10),
            Text(
              plan.name,
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
                Text(
                  plan.price,
                  style: Ty.h1.copyWith(
                      fontSize: 22, color: C.accentOrange),
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
    final selected = _payMethod == index;
    final accent = C.brand;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _payMethod = index),
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

  void _onBuy() {
    final plan = _plans[_selectedPlan];
    final pay = ['支付宝', '微信', 'QQ'][_payMethod];
    Get.dialog(AlertDialog(
      title: const Text('确认订单'),
      content: Text('${plan.name} · ¥${plan.price}\n支付方式：$pay\n\n支付通道对接中，请联系管理员开通。'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('我知道了')),
      ],
    ));
  }
}
