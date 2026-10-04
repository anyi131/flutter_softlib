import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/admin_service.dart';
import '../../../design/adaptive.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/toast_util.dart';

/// 采集账号（版权梦）—— 配置登录态
///
/// 主路径：填账号密码 → 后端自动识别验证码登录（推荐，一劳永逸）
/// 备用路径：手工粘贴浏览器 Cookie（验证码识别失败时兜底）
class CollectAccountCard extends StatefulWidget {
  final bool loggedIn;
  final int totalPages;
  final VoidCallback onChanged;

  const CollectAccountCard({
    super.key,
    required this.loggedIn,
    required this.totalPages,
    required this.onChanged,
  });

  @override
  State<CollectAccountCard> createState() => _CollectAccountCardState();
}

class _CollectAccountCardState extends State<CollectAccountCard> {
  final _svc = AdminService.instance;
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _cookieCtrl = TextEditingController();

  bool _busy = false;
  bool _showCookie = false;
  bool _showPass = false;
  bool _hasPass = false;
  String _lastLogin = '';

  @override
  void initState() {
    super.initState();
    _loadCfg();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _cookieCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCfg() async {
    try {
      final cfg = await _svc.collectConfig();
      if (!mounted) return;
      setState(() {
        final u = (cfg['collect_user'] ?? '').toString();
        if (u.isNotEmpty) _userCtrl.text = u;
        _hasPass = cfg['has_pass'] == true || cfg['has_pass'] == 1;
        _lastLogin = (cfg['last_login'] ?? '').toString();
      });
    } catch (_) {}
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e) {
      if (mounted) {
        ToastUtil.error(_friendly(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 把后端/网络的原始异常翻成人话
  String _friendly(Object e) {
    final s = e.toString().replaceFirst('Exception: ', '');
    if (s.contains('500')) {
      return '服务器处理出错，请稍后重试或改用 Cookie 方式';
    }
    if (s.contains('Cookie') || s.contains('超时') || s.contains('timeout')) {
      return '网络异常，请检查连接后重试';
    }
    return s;
  }

  Future<void> _loginByPassword() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();
    if (u.isEmpty) {
      ToastUtil.info('请填写采集平台账号');
      return;
    }
    if (p.isEmpty && !_hasPass) {
      ToastUtil.info('请填写采集平台密码');
      return;
    }
    await _run(() async {
      final r = await _svc.collectLogin(user: u, pass: p);
      if (!mounted) return;
      _passCtrl.clear();
      ToastUtil.success(
          '登录成功（共 ${r['total_pages'] ?? 0} 页可采集）');
      setState(() {
        _hasPass = true;
        _lastLogin = '刚刚';
      });
      widget.onChanged();
    });
  }

  Future<void> _saveCookie() async {
    final v = _cookieCtrl.text.trim();
    if (v.isEmpty) {
      ToastUtil.info('请粘贴 Cookie');
      return;
    }
    await _run(() async {
      final ok = await _svc.saveCollectCookie(v);
      if (ok) {
        if (mounted) setState(() => _lastLogin = '刚刚');
        ToastUtil.success('登录态有效，可以采集了');
        widget.onChanged();
      } else {
        ToastUtil.error('Cookie 无效或已过期');
      }
    });
  }

  Future<void> _logout() async {
    await _run(() async {
      await _svc.collectLogout();
      ToastUtil.success('已退出采集平台登录');
      widget.onChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KitCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.loggedIn
                    ? Icons.verified_user_rounded
                    : Icons.link_off_rounded,
                color: widget.loggedIn ? C.success : C.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('采集账号（版权梦）',
                  style: Ty.h3.copyWith(color: context.t1)),
              const Spacer(),
              Pill(
                widget.loggedIn ? '已登录' : '未登录',
                color: widget.loggedIn ? C.success : C.warning,
                small: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.loggedIn
                ? '账号密码已保存，Cookie 过期会自动重新登录。'
                  '${widget.totalPages > 0 ? ' 平台共 ${widget.totalPages} 页。' : ''}'
                : '填写采集平台的账号密码，保存后即可一键登录（含验证码自动识别），'
                    '不用再手工从浏览器复制 Cookie。',
            style: Ty.small.copyWith(color: context.t2, height: 1.5),
          ),
          if (_lastLogin.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('上次登录：$_lastLogin',
                style: Ty.tiny.copyWith(color: context.t3)),
          ],
          const SizedBox(height: 12),

          // ── 账号 / 密码 ──
          Row(
            children: [
              Expanded(
                child: _field(
                  ctrl: _userCtrl,
                  label: '账号',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  ctrl: _passCtrl,
                  label: _hasPass ? '密码（留空则不修改）' : '密码',
                  icon: Icons.lock_outline_rounded,
                  obscure: !_showPass,
                  suffix: IconButton(
                    icon: Icon(
                      _showPass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: context.t3,
                    ),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: widget.loggedIn ? '重新登录' : '保存并登录',
            icon: Icons.login_rounded,
            height: 46,
            loading: _busy,
            onPressed: _loginByPassword,
          ),

          if (widget.loggedIn) ...[
            const SizedBox(height: 8),
            SoftButton(
              label: '退出采集平台登录',
              icon: Icons.logout_rounded,
              height: 40,
              onPressed: _busy ? null : _logout,
            ),
          ],

          const SizedBox(height: 4),
          // ── Cookie 兜底 ──
          TextButton.icon(
            onPressed: () => setState(() => _showCookie = !_showCookie),
            icon: Icon(
              _showCookie
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 18,
            ),
            label: Text('登录失败？改用浏览器 Cookie 方式'),
          ),
          if (_showCookie) ...[
            Text(
              '1. 在浏览器登录 app.125ks.cn\n'
              '2. F12 → Network → 任意请求 → 复制 Cookie\n'
              '3. 粘贴到下面（需含 PHPSESSID）',
              style: Ty.tiny.copyWith(color: context.t3, height: 1.6),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cookieCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'PHPSESSID=xxx; ol_token=xxx; ...',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(R.md)),
              ),
            ),
            const SizedBox(height: 10),
            SoftButton(
              label: '保存 Cookie 并验证',
              icon: Icons.check_circle_outline_rounded,
              height: 42,
              onPressed: _busy ? null : _saveCookie,
            ),
          ],
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md)),
      ),
    );
  }
}
