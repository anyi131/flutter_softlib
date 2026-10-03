import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/admin_service.dart';
import '../../../utils/toast_util.dart';

/// 软件管理
class AdminAppsTab extends StatefulWidget {
  const AdminAppsTab({super.key});

  @override
  State<AdminAppsTab> createState() => _AdminAppsTabState();
}

class _AdminAppsTabState extends State<AdminAppsTab> {
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
      final l = await _svc.apps(keyword: _kw);
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
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    onSubmitted: (v) {
                      _kw = v;
                      _load();
                    },
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '搜索软件名称',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF465CFF),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => _edit(null),
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('新增', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
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
                      final a = _list[i];
                      final isLocal = a['provider'] == 'local';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1C1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: (a['icon'] ?? '').toString().isEmpty
                                  ? Container(
                                      width: 44,
                                      height: 44,
                                      color: const Color(0xFF465CFF)
                                          .withAlpha(28),
                                      child: const Icon(Icons.android,
                                          color: Color(0xFF465CFF), size: 22))
                                  : CachedNetworkImage(
                                      imageUrl: '${a['icon']}',
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${a['title']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isLocal
                                              ? const Color(0xFFDBEAFE)
                                              : const Color(0xFFFEF3C7),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isLocal ? '服务器' : '蓝奏云',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isLocal
                                                  ? const Color(0xFF1D4ED8)
                                                  : const Color(0xFFB45309)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${a['size_str'] ?? ''} ${a['version_name'] ?? ''}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 19),
                              onPressed: () => _edit(a),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 19, color: Color(0xFFDC2626)),
                              onPressed: () => _del(a),
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

  Future<void> _del(Map a) async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('删除软件'),
      content: Text('确定删除「${a['title']}」吗？'),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false), child: const Text('取消')),
        FilledButton(
            onPressed: () => Get.back(result: true), child: const Text('删除')),
      ],
    ));
    if (ok != true) return;
    try {
      await _svc.deleteApp(int.tryParse('${a['id']}') ?? 0);
      ToastUtil.success('已删除');
      _load();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _edit(Map? a) async {
    List<Map<String, dynamic>> cats = [];
    try {
      cats = await _svc.appCats();
    } catch (_) {}

    final title = TextEditingController(text: '${a?['title'] ?? ''}');
    final url = TextEditingController(text: '${a?['url'] ?? ''}');
    final icon = TextEditingController(text: '${a?['icon'] ?? ''}');
    final size = TextEditingController(text: '${a?['size_str'] ?? ''}');
    final ver = TextEditingController(text: '${a?['version_name'] ?? ''}');
    final desc = TextEditingController(text: '${a?['description'] ?? ''}');
    final weigh = TextEditingController(text: '${a?['weigh'] ?? 0}');
    final shots = TextEditingController(text: '${a?['screenshots'] ?? ''}');
    String provider = '${a?['provider'] ?? 'lzy'}';
    String filePath = '${a?['file_path'] ?? ''}';
    int catId = int.tryParse('${a?['cat_id'] ?? 0}') ?? 0;
    bool isVip = '${a?['is_vip'] ?? 0}' == '1';
    final vipPrice = TextEditingController(text: '${a?['vip_price'] ?? ''}');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        bool saving = false;
        bool parsing = false;
        String err = '';
        String okTip = '';

        /// 自动解析（蓝奏云链接 → 名称/大小/图标/描述/版本）
        Future<void> doParse() async {
          if (url.text.trim().isEmpty) {
            setS(() => err = '请先填写蓝奏云链接');
            return;
          }
          setS(() {
            parsing = true;
            err = '';
            okTip = '';
          });
          try {
            final d = await _svc.parse(type: 'lzy', url: url.text.trim());
            setS(() {
              parsing = false;
              if ((d['name'] ?? '').toString().isNotEmpty && title.text.isEmpty) {
                title.text = d['name'].toString().replaceAll('.apk', '');
              }
              if ((d['size_str'] ?? '').toString().isNotEmpty) {
                size.text = d['size_str'].toString();
              }
              if ((d['icon'] ?? '').toString().isNotEmpty) {
                icon.text = d['icon'].toString();
              }
              if ((d['description'] ?? '').toString().isNotEmpty) {
                desc.text = d['description'].toString();
              }
              if ((d['version'] ?? '').toString().isNotEmpty) {
                ver.text = d['version'].toString();
              }
              okTip = '解析成功，已自动填充信息 ✅';
            });
          } catch (e) {
            setS(() {
              parsing = false;
              err = e.toString().replaceFirst('Exception: ', '');
            });
          }
        }

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(a == null ? '新增软件' : '编辑软件',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    // ===== 来源选择 =====
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('蓝奏云链接'),
                            selected: provider == 'lzy',
                            onSelected: (_) => setS(() => provider = 'lzy'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('服务器文件'),
                            selected: provider == 'local',
                            onSelected: (_) => setS(() => provider = 'local'),
                          ),
                        ],
                      ),
                    ),

                    // ===== 蓝奏云：链接 + 一键解析 =====
                    if (provider == 'lzy') ...[
                      TextField(
                        controller: url,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: '蓝奏云分享链接',
                          hintText: 'https://xxx.lanzoup.com/xxxx',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            tooltip: '自动解析软件信息',
                            icon: parsing
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.auto_fix_high, size: 19),
                            onPressed: parsing ? null : doParse,
                          ),
                        ),
                        onChanged: (v) {},
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: parsing ? null : doParse,
                          icon: const Icon(Icons.cloud_download_outlined,
                              size: 17),
                          label: Text(
                            parsing ? '正在解析…' : '自动解析软件信息（名称/大小/图标/版本）',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],

                    // ===== 本地文件：上传 =====
                    if (provider == 'local') ...[
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final picked = await FilePicker.platform
                                  .pickFiles(withData: false);
                              if (picked == null || picked.files.isEmpty) return;
                              final f = picked.files.first;
                              setS(() {
                                parsing = true;
                                err = '';
                              });
                              final d = await _svc.uploadFile(File(f.path!));
                              setS(() {
                                parsing = false;
                                filePath = '${d['file_path'] ?? ''}';
                                if ((d['name'] ?? '').toString().isNotEmpty) {
                                  title.text = '${d['name']}';
                                }
                                if ((d['size_str'] ?? '').toString().isNotEmpty) {
                                  size.text = '${d['size_str']}';
                                }
                                okTip = '上传成功，已自动填充信息 ✅';
                              });
                            } catch (e) {
                              setS(() {
                                parsing = false;
                                err = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                          icon: const Icon(Icons.upload_file, size: 17),
                          label: Text(
                            parsing
                                ? '上传中…'
                                : (filePath.isEmpty ? '选择并上传安装包' : '已上传 ✓ 点击重选'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      if (filePath.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('文件路径：$filePath',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500])),
                        ),
                    ],

                    if (okTip.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F9EE),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(okTip,
                              style: const TextStyle(
                                  fontSize: 12.5, color: Color(0xFF0E9F6E))),
                        ),
                      ),

                    const SizedBox(height: 14),
                    const Text('基础信息',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6B7280))),
                    const SizedBox(height: 8),
                    _field('软件名称 *', title),
                    // 图标：URL + 上传
                    Row(
                      children: [
                        Expanded(child: _field('图标 URL', icon)),
                        IconButton(
                          tooltip: '上传图标',
                          icon: const Icon(Icons.add_photo_alternate_outlined,
                              size: 21),
                          onPressed: () async {
                            try {
                              final picked = await ImagePicker()
                                  .pickImage(source: ImageSource.gallery,
                                      imageQuality: 85);
                              if (picked == null) return;
                              setS(() => parsing = true);
                              final url = await _svc
                                  .uploadImage(File(picked.path));
                              setS(() {
                                icon.text = url;
                                parsing = false;
                                okTip = '图标上传成功 ✅';
                              });
                            } catch (e) {
                              setS(() {
                                parsing = false;
                                err = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    _field('文件大小', size),
                    _field('版本号', ver),
                    _field('软件描述', desc, maxLines: 3),
                    Row(
                      children: [
                        Expanded(child: _field('截图 URL（逗号分隔）', shots)),
                        IconButton(
                          tooltip: '上传截图（可多选）',
                          icon: const Icon(Icons.collections_outlined, size: 21),
                          onPressed: () async {
                            try {
                              final picked = await ImagePicker()
                                  .pickMultiImage(imageQuality: 80);
                              if (picked.isEmpty) return;
                              setS(() => parsing = true);
                              final urls = <String>[];
                              for (final f in picked) {
                                urls.add(await _svc.uploadImage(File(f.path)));
                              }
                              final cur = shots.text.trim();
                              shots.text = cur.isEmpty
                                  ? urls.join(',')
                                  : '$cur,${urls.join(',')}';
                              setS(() {
                                parsing = false;
                                okTip = '已上传 ${urls.length} 张截图 ✅';
                              });
                            } catch (e) {
                              setS(() {
                                parsing = false;
                                err = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    // ===== 会员专享设置 =====
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.workspace_premium_rounded,
                                  size: 18, color: Color(0xFFC9A227)),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('会员专享资源',
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF8A6A16))),
                              ),
                              Switch(
                                value: isVip,
                                activeThumbColor: const Color(0xFFC9A227),
                                onChanged: (v) => setS(() => isVip = v),
                              ),
                            ],
                          ),
                          if (isVip)
                            _field('会员价（如 ¥9.9）', vipPrice),
                          Text('开启后，非会员下载时会提示开通会员',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<int>(
                        initialValue: catId,
                        decoration: const InputDecoration(
                          labelText: '所属分类',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: 0, child: Text('未分类')),
                          ...cats.map((c) => DropdownMenuItem(
                                value: int.tryParse('${c['id']}') ?? 0,
                                child: Text('${c['title']}'),
                              )),
                        ],
                        onChanged: (v) => setS(() => catId = v ?? 0),
                      ),
                    ),
                    _field('权重（越大越靠前）', weigh),
                    if (err.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(err,
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFFDC2626))),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF465CFF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23)),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          if (title.text.trim().isEmpty) {
                            setS(() => err = '软件名称不能为空');
                            return;
                          }
                          if (provider == 'lzy' && url.text.trim().isEmpty) {
                            setS(() => err = '请填写蓝奏云链接');
                            return;
                          }
                          if (provider == 'local' && filePath.isEmpty) {
                            setS(() => err = '请先上传安装包');
                            return;
                          }
                          setS(() {
                            saving = true;
                            err = '';
                          });
                          try {
                            await _svc.saveApp({
                              'id': a?['id'] ?? 0,
                              'title': title.text.trim(),
                              'provider': provider,
                              'url': url.text.trim(),
                              'icon': icon.text.trim(),
                              'size_str': size.text.trim(),
                              'version_name': ver.text.trim(),
                              'description': desc.text.trim(),
                              'screenshots': shots.text.trim(),
                              'cat_id': catId,
                              'weigh': int.tryParse(weigh.text) ?? 0,
                              'enable_switch': 1,
                              'file_path': filePath,
                              'is_vip': isVip ? 1 : 0,
                              'vip_price': vipPrice.text.trim(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            ToastUtil.success('保存成功');
                            _load();
                          } catch (e) {
                            setS(() {
                              saving = false;
                              err = e.toString().replaceFirst('Exception: ', '');
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('保存',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
