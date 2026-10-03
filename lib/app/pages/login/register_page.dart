import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/user_service.dart';

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
  int _countdown = 0;
  Timer? _timer;
  String _qqAvatar = '';

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

  void _tip(String msg) {
    Get.snackbar('提示', msg,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2));
  }

  /// 邮箱后缀快捷选择
  void _useQqMail() {
    final v = _email.text.trim();
    if (v.contains('@')) return;
    if (v.isEmpty) return;
    _email.text = '$v@qq.com';
    setState(() {});
  }

  /// 输入 QQ 号后自动获取 QQ 头像
  Future<void> _loadQqAvatar() async {
    final qq = _qq.text.trim();
    if (!RegExp(r'^\d{5,12}$').hasMatch(qq)) {
      setState(() => _qqAvatar = '');
      return;
    }
    final url = await UserService.instance.fetchQqAvatar(qq);
    if (mounted) setState(() => _qqAvatar = url ?? '');
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      return _tip('请输入正确的邮箱');
    }
    setState(() => _sending = true);
    try {
      await UserService.instance.sendCode(email);
      _tip('验证码已发送，请查收邮箱');
      setState(() => _countdown = 60);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _countdown--);
        if (_countdown <= 0) t.cancel();
      });
    } catch (e) {
      _tip(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    final pwd = _pwd.text;
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      return _tip('请输入正确的邮箱');
    }
    if (code.isEmpty) return _tip('请输入邮箱验证码');
    if (pwd.length < 6) return _tip('密码至少 6 位');
    if (pwd != _pwd2.text) return _tip('两次输入的密码不一致');

    setState(() => _loading = true);
    try {
      await UserService.instance.register(
        email: email,
        code: code,
        password: pwd,
        nickname: _nickname.text.trim(),
        qq: _qq.text.trim(),
      );
      if (!mounted) return;
      _tip('注册成功，已自动登录');
      Navigator.of(context).pop(true);
    } catch (e) {
      _tip(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('注册'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
        children: [
          // ===== QQ 头像预览 =====
          Center(
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
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
                              size: 42, color: scheme.primary.withAlpha(150)),
                          errorWidget: (_, __, ___) => Icon(Icons.person,
                              size: 42, color: scheme.primary.withAlpha(150)),
                        )
                      : Icon(Icons.person,
                          size: 42, color: scheme.primary.withAlpha(150)),
                ),
                const SizedBox(height: 8),
                Text(
                  _qqAvatar.isEmpty ? '填写 QQ 号自动获取头像' : '已获取 QQ 头像',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ===== QQ 号 =====
          TextField(
            controller: _qq,
            keyboardType: TextInputType.number,
            onChanged: (_) => _loadQqAvatar(),
            decoration: InputDecoration(
              labelText: 'QQ 号（选填，用于头像）',
              prefixIcon: const Icon(Icons.chat_bubble_outline),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // ===== 邮箱 =====
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: '邮箱（推荐 QQ 邮箱）',
              prefixIcon: const Icon(Icons.mail_outline),
              suffixIcon: TextButton(
                onPressed: _useQqMail,
                child: const Text('@qq.com',
                    style: TextStyle(fontSize: 12)),
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // ===== 验证码 =====
          Row(
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
                  onPressed:
                      (_sending || _countdown > 0) ? null : _sendCode,
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
          const SizedBox(height: 16),

          // ===== 昵称 =====
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

          // ===== 密码 =====
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),

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
          const SizedBox(height: 14),
          Text(
            '验证码有效期 5 分钟。若未收到，请检查垃圾邮件箱。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
