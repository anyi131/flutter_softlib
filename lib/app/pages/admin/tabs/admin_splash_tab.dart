import 'package:flutter/material.dart';

import '../../../api/admin_service.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/toast_util.dart';

/// 开屏与远程控制管理
class AdminSplashTab extends StatefulWidget {
  const AdminSplashTab({super.key});

  @override
  State<AdminSplashTab> createState() => _AdminSplashTabState();
}

class _AdminSplashTabState extends State<AdminSplashTab> {
  final _svc = AdminService.instance;
  bool _loading = true;
  bool _inited = false;

  bool splashEnable = true;
  bool noticeEnable = false;
  bool noticeForce = false;
  bool maintainEnable = false;

  final imgCtrl = TextEditingController();
  final secondsCtrl = TextEditingController(text: '2');
  final urlCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final noticeTitleCtrl = TextEditingController(text: '公告');
  final noticeContentCtrl = TextEditingController();
  final maintainCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    imgCtrl.dispose();
    secondsCtrl.dispose();
    urlCtrl.dispose();
    titleCtrl.dispose();
    descCtrl.dispose();
    noticeTitleCtrl.dispose();
    noticeContentCtrl.dispose();
    maintainCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await _svc.splash();
      if (!mounted) return;
      setState(() {
        splashEnable = '${d['splash_enable']}' == '1';
        noticeEnable = '${d['notice_enable']}' == '1';
        noticeForce = '${d['notice_force']}' == '1';
        maintainEnable = '${d['maintain_enable']}' == '1';
        imgCtrl.text = '${d['splash_image'] ?? ''}';
        secondsCtrl.text = '${d['splash_seconds'] ?? 2}';
        urlCtrl.text = '${d['splash_url'] ?? ''}';
        titleCtrl.text = '${d['splash_title'] ?? ''}';
        descCtrl.text = '${d['splash_desc'] ?? ''}';
        noticeTitleCtrl.text = '${d['notice_title'] ?? '公告'}';
        noticeContentCtrl.text = '${d['notice_content'] ?? ''}';
        maintainCtrl.text = '${d['maintain_text'] ?? ''}';
        _loading = false;
        _inited = true;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _save() async {
    try {
      await _svc.saveSplash({
        'splash_enable': splashEnable ? 1 : 0,
        'splash_image': imgCtrl.text.trim(),
        'splash_seconds': int.tryParse(secondsCtrl.text) ?? 2,
        'splash_url': urlCtrl.text.trim(),
        'splash_title': titleCtrl.text.trim(),
        'splash_desc': descCtrl.text.trim(),
        'notice_enable': noticeEnable ? 1 : 0,
        'notice_title': noticeTitleCtrl.text.trim(),
        'notice_content': noticeContentCtrl.text,
        'notice_force': noticeForce ? 1 : 0,
        'maintain_enable': maintainEnable ? 1 : 0,
        'maintain_text': maintainCtrl.text.trim(),
      });
      ToastUtil.success('保存成功，App 下次启动生效');
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingState(text: '加载开屏配置…');
    }
    if (!_inited) {
      return ErrorState(
        text: '加载配置失败',
        hint: '请检查网络连接后重试',
        onRetry: _load,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _card(
          title: '开屏页',
          children: [
            _switch('启用开屏页', splashEnable,
                (v) => setState(() => splashEnable = v)),
            _field('开屏图片 URL', imgCtrl),
            _field('停留秒数（1-10）', secondsCtrl, keyboard: TextInputType.number),
            _field('点击跳转网址（选填）', urlCtrl),
            _field('标题（选填）', titleCtrl),
            _field('副标题（选填）', descCtrl),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          title: '公告弹窗',
          children: [
            _switch('启用公告弹窗', noticeEnable,
                (v) => setState(() => noticeEnable = v)),
            _switch('强制阅读（不可关闭）', noticeForce,
                (v) => setState(() => noticeForce = v)),
            _field('公告标题', noticeTitleCtrl),
            _field('公告内容（支持 HTML）', noticeContentCtrl, lines: 4),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          title: '远程控制',
          children: [
            _switch('开启维护模式（App 显示维护页）', maintainEnable,
                (v) => setState(() => maintainEnable = v)),
            _field('维护提示文案', maintainCtrl, lines: 2),
          ],
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: '保存全部配置',
          icon: Icons.save_rounded,
          onPressed: _save,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return KitCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          ...children,
        ],
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: const TextStyle(fontSize: 13.5))),
          Switch(
            value: value,
            activeThumbColor: C.brand,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {int lines = 1, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: c,
        maxLines: lines,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md)),
        ),
      ),
    );
  }
}
