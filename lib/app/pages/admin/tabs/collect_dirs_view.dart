import 'package:flutter/material.dart';

import '../../../api/admin_service.dart';
import '../../../design/adaptive.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/toast_util.dart';

/// 采集 · 目录配置（只读展示站点上已配置的蓝奏云目录）
///
/// 说明：目录的增删改在采集平台站点上操作，这里展示当前生效的规则，
/// 让你清楚「哪个软件会被传到哪个目录」。
class CollectDirsView extends StatefulWidget {
  const CollectDirsView({super.key});

  @override
  State<CollectDirsView> createState() => _CollectDirsViewState();
}

class _CollectDirsViewState extends State<CollectDirsView>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _dirs = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await AdminService.instance.collectDirs();
      if (!mounted) return;
      setState(() {
        _dirs = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _dirs.isEmpty) {
      return const LoadingState(text: '加载目录配置…');
    }
    if (_dirs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [
          const SizedBox(height: 90),
          EmptyState(
            text: '还没有目录配置',
            hint: '请在采集平台网站上添加蓝奏云目录',
            icon: Icons.folder_off_outlined,
            action: SoftButton(label: '重新加载', onPressed: _load),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
            context.pagePadding, 8, context.pagePadding, 24),
        itemCount: _dirs.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: KitCard(
                radius: R.md,
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.rule_folder_outlined, size: 18, color: C.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '采集时按「关键词匹配」决定软件传到哪个目录；'
                        '带「兜底」的目录会在都没匹配上时使用。',
                        style: Ty.tiny.copyWith(
                            color: context.t3, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return _dirCard(_dirs[i - 1]);
        },
      ),
    );
  }

  Widget _dirCard(Map<String, dynamic> d) {
    final enabled = d['status'] == 1 || d['status'] == '1';
    final fallback =
        d['is_fallback'] == 1 || d['is_fallback'] == '1';
    final kw = (d['keyword'] ?? '').toString();
    final block = (d['block_keyword'] ?? '').toString();
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: KitCard(
        margin: const EdgeInsets.only(bottom: 8),
        radius: R.md,
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_rounded,
                    size: 19, color: enabled ? C.brand : context.t3),
                const SizedBox(width: 8),
                Flexible(
                  child: Text((d['name'] ?? '未命名').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Ty.h3.copyWith(fontSize: 14.5, color: context.t1)),
                ),
                const SizedBox(width: 6),
                if (fallback)
                  const Pill('兜底', color: C.accentOrange, small: true),
                if (!enabled) ...[
                  const SizedBox(width: 4),
                  Pill('已禁用', color: C.danger, small: true),
                ],
              ],
            ),
            const SizedBox(height: 7),
            _kv(Icons.tag_rounded, '目录 ID  ${d['dir_id']}'),
            if ((d['path'] ?? '').toString().isNotEmpty)
              _kv(Icons.account_tree_outlined, '${d['path']}'),
            _kv(Icons.sort_rounded, '优先级  ${d['priority'] ?? 0}'),
            if (kw.isNotEmpty)
              _kv(Icons.filter_alt_outlined, '关键词  $kw', color: C.mint),
            if (block.isNotEmpty)
              _kv(Icons.block_rounded, '屏蔽  $block', color: C.warning),
          ],
        ),
      ),
    );
  }

  Widget _kv(IconData i, String text, {Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(i, size: 13, color: color ?? context.t3),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: Ty.tiny.copyWith(
                      fontSize: 11.5, color: color ?? context.t3, height: 1.5)),
            ),
          ],
        ),
      );
}
