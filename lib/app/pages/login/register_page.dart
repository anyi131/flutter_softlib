import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/user_service.dart';
import '../navigate/mine/mine_logic.dart';
import 'widgets/form_tip.dart';

/// 注册页：QQ邮箱验证码 + QQ头像自动获取
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();
  final _nickname = TextEditingController();
  final _qq = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _sending = false;
  bool _qqAutoFilled = false;
  int _countdown = 0;
  Timer? _timer;
  String _qqAvatar = '';
  bool _loadingAvatar = false;

  String _error = '';

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _pwd.dispose();
    _pwd2.dispose();
    _nickname.dispose();
    _qq.dispose();
    super.dispose();
  }

  /// 输入 QQ 号：自动获取头像 + 自动填充邮箱
  Future<void> _onQqChanged(String v) async {
    final qq = v.trim();
    final valid = RegExp(r'^\d{5,12}$').hasMatch(qq);

    // 邮箱为空或此前是自动填充的 → 跟随 QQ 号变化
    if (valid && (_email.text.trim().isEmpty || _qqAutoFilled)) {
      _email.text = '$qq@qq.com';
      _qqAutoFilled = true;
    } else if (!valid && _qqAutoFilled) {
      _email.text = '';
      _qqAutoFilled = false;
    }

    if (!valid) {
      if (mounted) setState(() => _qqAvatar = '');
      return;
    }
    if (mounted) setState(() => _loadingAvatar = true);
    final url = await UserService.instance.fetchQqAvatar(qq);
    if (mounted) {
      setState(() {
        _qqAvatar = url ?? '';
        _loadingAvatar = false;
      });
    }
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      return setState(() => _error = '请输入正确的邮箱（如 123456@qq.com）');
    }
    setState(() {
      _error = '';
      _sending = true;
    });
    try {
      await UserService.instance.sendCode(email);
      setState(() => _countdown = 60);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _countdown--);
        if (_countdown <= 0) t.cancel();
      });
      if (mounted) {
        setState(() => _error = '验证码已发送至 $email，5 分钟内有效');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    final pwd = _pwd.text;
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      return setState(() => _error = '请输入正确的邮箱');
    }
    if (code.isEmpty) return setState(() => _error = '请输入邮箱验证码');
    if (pwd.length < 6) return setState(() => _error = '密码至少 6 位');
    if (pwd != _pwd2.text) return setState(() => _error = '两次输入的密码不一致');

    setState(() {
      _error = '';
      _loading = true;
    });
    try {
      await UserService.instance.register(
        email: email,
        code: code,
        password: pwd,
        nickname: _nickname.text.trim(),
        qq: _qq.text.trim(),
      );
      if (!mounted) return;
      try {
        final mine = Get.find<MineLogic>(tag: 'mine');
        await mine.load();
      } catch (_) {}
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('注册'), elevation: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            // ===== QQ 头像 =====
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surfaceContainerHighest,
                          border: Border.all(color: scheme.primary, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _qqAvatar.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _qqAvatar,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Icon(Icons.person,
                                    size: 40,
                                    color: scheme.primary.withAlpha(150)),
                                errorWidget: (_, __, ___) => Icon(Icons.person,
                                    size: 40,
                                    color: scheme.primary.withAlpha(150)),
                              )
                            : Icon(Icons.person,
                                size: 40, color: scheme.primary.withAlpha(150)),
                      ),
                      if (_loadingAvatar)
                        const SizedBox(
                          width: 78,
                          height: 78,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _qqAvatar.isEmpty ? '填写 QQ 号自动获取头像' : '已获取 QQ 头像',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _qq,
              keyboardType: TextInputType.number,
              onChanged: _onQqChanged,
              decoration: InputDecoration(
                labelText: 'QQ 号（选填，自动获取头像）',
                prefixIcon: const Icon(Icons.chat_bubble_outline),
                helperText: '填写后自动同步 QQ 头像，并自动填写 QQ 邮箱',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            FormTip(
              message: _error,
              isError: !_error.contains('已发送'),
              child: TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) {
                  // 用户手动改动后不再自动覆盖
                  if (!v.trim().startsWith(_qq.text.trim())) {
                    _qqAutoFilled = false;
                  }
                },
                decoration: InputDecoration(
                  labelText: '邮箱（推荐 QQ 邮箱）',
                  prefixIcon: const Icon(Icons.mail_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '邮箱验证码',
                      prefixIcon: const Icon(Icons.verified_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: (_sending || _countdown > 0) ? null : _sendCode,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _sending
                          ? '发送中'
                          : (_countdown > 0 ? '${_countdown}s' : '获取验证码'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _nickname,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: '昵称（选填）',
                prefixIcon: const Icon(Icons.badge_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            TextField(
              controller: _pwd,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: '设置密码（至少 6 位）',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _pwd2,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '再次确认密码',
                prefixIcon: const Icon(Icons.lock_reset),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 22),

            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('注册并登录',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '验证码有效期 5 分钟。若未收到，请检查垃圾邮件箱。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
