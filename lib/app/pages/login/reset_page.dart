import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/user_service.dart';
import 'widgets/form_tip.dart';

/// 找回密码页（邮箱验证码重置）
class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _sending = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _pwd.dispose();
    _pwd2.dispose();
    super.dispose();
  }

  String _error = '';

  void _tip(String msg) {
    setState(() => _error = msg);
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      return _tip('请输入正确的邮箱');
    }
    setState(() => _sending = true);
    try {
      await UserService.instance.sendCode(email, scene: 'reset');
      _tip('验证码已发送至 $email，5 分钟内有效');
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

  Future<void> _reset() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    final pwd = _pwd.text;
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      return _tip('请输入正确的邮箱');
    }
    if (code.isEmpty) return _tip('请输入验证码');
    if (pwd.length < 6) return _tip('密码至少 6 位');
    if (pwd != _pwd2.text) return _tip('两次输入的密码不一致');

    setState(() => _loading = true);
    try {
      await UserService.instance
          .resetPassword(email: email, code: code, password: pwd);
      _tip('密码重置成功，请用新密码登录');
      Navigator.of(context).pop();
    } catch (e) {
      _tip(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('找回密码'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
        children: [
          const SizedBox(height: 6),
          const Text('重置密码',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('输入注册邮箱，通过邮箱验证码重置密码',
              style: TextStyle(fontSize: 13.5, color: Colors.grey[500])),
          const SizedBox(height: 26),
          FormTip(
            message: _error,
            isError: !_error.contains('已发送'),
            child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: '注册邮箱',
              prefixIcon: const Icon(Icons.mail_outline),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          TextField(
            controller: _pwd,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: '新密码（至少 6 位）',
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
              labelText: '确认新密码',
              prefixIcon: const Icon(Icons.lock_reset),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : _reset,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('确认重置',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
