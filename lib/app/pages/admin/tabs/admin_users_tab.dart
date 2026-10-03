import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/admin_service.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                    itemCount: _list.length,
                    itemBuilder: (context, i) {
                      final u = _list[i];
                      final isAdmin = u['is_admin'] == true;
                      final isVip = u['is_vip'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1C1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                                          color: const Color(0xFF465CFF)
                                              .withAlpha(26),
                                          child: const Icon(Icons.person,
                                              size: 21,
                                              color: Color(0xFF465CFF)))
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
                                          Text('${u['nickname']}',
                                              style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700)),
                                          if (isAdmin) ...[
                                            const SizedBox(width: 5),
                                            _tag('管理员', const Color(0xFF3730A3),
                                                const Color(0xFFE0E7FF)),
                                          ],
                                          if (isVip) ...[
                                            const SizedBox(width: 5),
                                            _tag('VIP', const Color(0xFFB45309),
                                                const Color(0xFFFEF3C7)),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text('${u['email']}',
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey[500])),
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
                                _btn('+30天VIP', () async {
                                  await _svc.grantVip(
                                      int.tryParse('${u['id']}') ?? 0, 30);
                                  ToastUtil.success('已赠送 30 天会员');
                                  _load();
                                }),
                                _btn(isAdmin ? '取消管理' : '设为管理', () async {
                                  await _svc.setAdmin(
                                      int.tryParse('${u['id']}') ?? 0, !isAdmin);
                                  ToastUtil.success(isAdmin ? '已取消' : '已设为管理员');
                                  _load();
                                }),
                                _btn(
                                    u['status'] == 'hidden' ? '解禁' : '禁用',
                                    () async {
                                  await _svc.toggleUserStatus(
                                      int.tryParse('${u['id']}') ?? 0);
                                  _load();
                                }),
                                _btn('删除', () async {
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
                                }, danger: true),
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

  Widget _tag(String t, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(t,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: fg)),
      );

  Widget _btn(String label, VoidCallback onTap, {bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: danger
              ? const Color(0xFFFEF2F2)
              : const Color(0xFFF1F3F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: danger
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF374151))),
      ),
    );
  }
}
