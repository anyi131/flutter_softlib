import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/admin_service.dart';
import '../../../design/adaptive.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/toast_util.dart';

/// 用户管理
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _svc = AdminService.instance;
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String _kw = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final l = await _svc.users(keyword: _kw);
      if (mounted) setState(() {
        _list = l;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: SizedBox(
            height: 40,
            child: TextField(
              onSubmitted: (v) {
                _kw = v;
                _load();
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '搜索邮箱 / 昵称 / QQ',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(R.md)),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingState(text: '加载用户列表…')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                        context.pagePadding, 4, context.pagePadding, 20),
                    itemCount: _list.length,
                    itemBuilder: (context, i) {
                      final u = _list[i];
                      final isAdmin = u['is_admin'] == true;
                      final isVip = u['is_vip'] == true;
                      return KitCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipOval(
                                  child: (u['avatar'] ?? '').toString().isEmpty
                                      ? Container(
                                          width: 40,
                                          height: 40,
                                          color: C.brand
                                              .withAlpha(context.isDark ? 40 : 26),
                                          child: const Icon(Icons.person,
                                              size: 21, color: C.brand))
                                      : CachedNetworkImage(
                                          imageUrl: '${u['avatar']}',
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text('${u['nickname']}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Ty.h3.copyWith(
                                                    fontSize: 14.5,
                                                    color: context.t1)),
                                          ),
                                          if (isAdmin) ...[
                                            const SizedBox(width: 5),
                                            const Pill('管理员',
                                                color: C.brand, small: true),
                                          ],
                                          if (isVip) ...[
                                            const SizedBox(width: 5),
                                            const Pill('VIP',
                                                color: C.gold, small: true),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text('${u['email']}',
                                          style: Ty.tiny
                                              .copyWith(color: context.t3)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 7,
                              runSpacing: 6,
                              children: [
                                MiniAction(
                                    label: '编辑',
                                    icon: Icons.edit_outlined,
                                    onTap: () => _editUser(u)),
                                MiniAction(
                                  label: '+30天VIP',
                                  icon: Icons.workspace_premium_outlined,
                                  color: C.gold,
                                  onTap: () async {
                                    await _svc.grantVip(
                                        int.tryParse('${u['id']}') ?? 0, 30);
                                    ToastUtil.success('已赠送 30 天会员');
                                    _load();
                                  },
                                ),
                                MiniAction(
                                  label: isAdmin ? '取消管理' : '设为管理',
                                  icon: isAdmin
                                      ? Icons.person_remove_alt_1_outlined
                                      : Icons.admin_panel_settings_outlined,
                                  onTap: () async {
                                    await _svc.setAdmin(
                                        int.tryParse('${u['id']}') ?? 0,
                                        !isAdmin);
                                    ToastUtil.success(
                                        isAdmin ? '已取消' : '已设为管理员');
                                    _load();
                                  },
                                ),
                                MiniAction(
                                  label: u['status'] == 'hidden' ? '解禁' : '禁用',
                                  icon: u['status'] == 'hidden'
                                      ? Icons.lock_open_rounded
                                      : Icons.block_rounded,
                                  color: C.warning,
                                  onTap: () async {
                                    await _svc.toggleUserStatus(
                                        int.tryParse('${u['id']}') ?? 0);
                                    _load();
                                  },
                                ),
                                MiniAction(
                                  label: '删除',
                                  icon: Icons.delete_outline_rounded,
                                  color: C.danger,
                                  onTap: () async {
                                  final ok = await Get.dialog<bool>(
                                      AlertDialog(
                                    title: const Text('删除用户'),
                                    content:
                                        Text('确定删除「${u['nickname']}」？'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Get.back(result: false),
                                          child: const Text('取消')),
                                      FilledButton(
                                          onPressed: () =>
                                              Get.back(result: true),
                                          child: const Text('删除')),
                                    ],
                                  ));
                                  if (ok != true) return;
                                    await _svc.deleteUser(
                                        int.tryParse('${u['id']}') ?? 0);
                                    ToastUtil.success('已删除');
                                    _load();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// 编辑用户
  Future<void> _editUser(Map u) async {
    final nickCtrl = TextEditingController(text: '${u['nickname'] ?? ''}');
    final emailCtrl = TextEditingController(text: '${u['email'] ?? ''}');
    final qqCtrl = TextEditingController(text: '${u['qq'] ?? ''}');
    final scoreCtrl = TextEditingController(text: '${u['score'] ?? 0}');
    final titleCtrl = TextEditingController(text: '${u['title'] ?? ''}');
    final pwdCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.xl)),
        title: Text('编辑用户：${u['nickname']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nickCtrl,
                    decoration: const InputDecoration(labelText: '昵称')),
                const SizedBox(height: 10),
                TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: '邮箱')),
                const SizedBox(height: 10),
                TextField(
                    controller: qqCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'QQ号')),
                const SizedBox(height: 10),
                TextField(
                    controller: scoreCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '积分')),
                const SizedBox(height: 10),
                TextField(
                    controller: titleCtrl,
                    maxLength: 12,
                    decoration: const InputDecoration(
                        labelText: '自定义称号',
                        helperText: '显示在广场动态旁，留空则清除')),
                TextField(
                    controller: pwdCtrl,
                    decoration: const InputDecoration(
                        labelText: '新密码（留空不修改）')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false), child: const Text('取消')),
          FilledButton(
              onPressed: () => Get.back(result: true), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.saveUser({
        'id': u['id'],
        'nickname': nickCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'qq': qqCtrl.text.trim(),
        'score': int.tryParse(scoreCtrl.text) ?? 0,
        'title': titleCtrl.text.trim(),
        if (pwdCtrl.text.trim().isNotEmpty) 'password': pwdCtrl.text.trim(),
      });
      ToastUtil.success('保存成功');
      _load();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

}
