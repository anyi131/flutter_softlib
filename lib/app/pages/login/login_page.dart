import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/user_service.dart';
import 'register_page.dart';
import 'reset_page.dart';

/// 登录页
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _account = TextEditingController();
  final _pwd = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _account.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final account = _account.text.trim();
    final pwd = _pwd.text;
    if (account.isEmpty) return _tip('请输入邮箱或用户名');
    if (pwd.isEmpty) return _tip('请输入密码');
    setState(() => _loading = true);
    try {
      await UserService.instance.login(account, pwd);
      if (!mounted) return;
      Get.snackbar('登录成功', '欢迎回来', snackPosition: SnackPosition.BOTTOM);
      Navigator.of(context).pop(true);
    } catch (e) {
      _tip(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _tip(String msg) {
    Get.snackbar('提示', msg,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('登录'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        children: [
          const SizedBox(height: 10),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.primary.withAlpha(180)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 18),
          const Text('欢迎回来',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('登录后可下载资源、参与社区互动',
              style: TextStyle(fontSize: 13.5, color: Colors.grey[500])),
          const SizedBox(height: 30),
          TextField(
            controller: _account,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: '邮箱 / 用户名',
              prefixIcon: const Icon(Icons.alternate_email),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pwd,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.to(() => const ResetPage()),
              child: const Text('忘记密码？'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('登 录',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('还没有账号？',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13.5)),
              TextButton(
                onPressed: () => Get.to(() => const RegisterPage()),
                child: const Text('立即注册'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '注册即表示同意《用户协议》与《隐私政策》',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
