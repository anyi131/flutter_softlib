import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  static const Color kGold = Color(0xFFB8860B);
  static const Color kGoldLight = Color(0xFFD4A73F);

  final List<_Plan> _plans = const [
    _Plan('一周会员', '8', '体验'),
    _Plan('三个月会员', '28.88', '推荐', recommended: true),
    _Plan('永久', '45.99', '长期'),
  ];

  int _selectedPlan = 0;
  int _payMethod = 0; // 0 支付宝 1 微信 2 QQ

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F6F7);
    final cardBg = isDark ? const Color(0xFF222222) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('开通会员', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: bg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 18),
          Text('选择套餐',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              )),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_plans.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == _plans.length - 1 ? 0 : 10),
                  child: _buildPlanCard(i, isDark),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text('支付方式',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              )),
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
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2B2B2B),
                foregroundColor: const Color(0xFFF5D283),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _onBuy,
              child: const Text(
                '立即开通会员',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('会员权益',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    )),
                const SizedBox(height: 12),
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
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: kGoldLight,
              borderRadius: BorderRadius.circular(12),
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
  Widget _buildPlanCard(int index, bool isDark) {
    final plan = _plans[index];
    final selected = _selectedPlan == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF2C2618) : const Color(0xFFFFFBF0))
              : (isDark ? const Color(0xFF262626) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kGoldLight : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: plan.recommended
                    ? const Color(0xFFF3E4C0)
                    : (isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFEFEFEF)),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                plan.tag,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: plan.recommended
                      ? const Color(0xFF8A6A16)
                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              plan.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text('¥',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC0562E))),
                const SizedBox(width: 2),
                Text(
                  plan.price,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC0562E),
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
    final selected = _payMethod == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _payMethod = index),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEAF0FF)
                : (isDark ? const Color(0xFF262626) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  selected ? const Color(0xFF6B8CFF) : Colors.grey.withAlpha(60),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: selected ? const Color(0xFF3B5BDB) : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? const Color(0xFF3B5BDB) : Colors.grey[700],
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
          const Icon(Icons.check_circle, size: 16, color: kGoldLight),
          const SizedBox(width: 8),
          Expanded(
            child:
                Text(text, style: const TextStyle(fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }

  void _onBuy() {
    final plan = _plans[_selectedPlan];
    final pay = ['支付宝', '微信', 'QQ'][_payMethod];
    Get.snackbar(
      '确认订单',
      '${plan.name} · ¥${plan.price}\n支付方式：$pay\n（支付通道对接中，请联系管理员开通）',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}
