import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/app_item.dart';
import '../../routes/app_pages.dart';
import '../../services/soft_service.dart';
import '../../widgets/app_card.dart';

/// 软件搜索页（搜索已入库软件，含服务器直传 + 蓝奏云两种来源）
class AppSearchPage extends StatefulWidget {
  const AppSearchPage({super.key});

  @override
  State<AppSearchPage> createState() => _AppSearchPageState();
}

class _AppSearchPageState extends State<AppSearchPage> {
  final TextEditingController _ctrl = TextEditingController();
  final SoftService _service = SoftService.instance;

  List<AppItem> _results = [];
  bool _loading = false;
  bool _searched = false;
  String _keyword = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final kw = _ctrl.text.trim();
    if (kw.isEmpty) {
      Get.snackbar('提示', '请输入搜索关键词',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _searched = true;
      _keyword = kw;
    });
    try {
      final list = await _service.fetchApps(keyword: kw);
      if (!mounted) return;
      setState(() {
        _results = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
      });
      Get.snackbar('搜索失败', '网络异常，请稍后重试',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('软件搜索', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark
                          ? scheme.surfaceContainerHighest
                          : Colors.white,
                      borderRadius: BorderRadius.circular(23),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: '输入软件名称关键词',
                        hintStyle:
                            TextStyle(fontSize: 14, color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search,
                            size: 20, color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 46,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    onPressed: _loading ? null : _search,
                    child: const Text('搜索'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    if (!_searched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded,
                size: 64, color: Colors.grey.withAlpha(90)),
            const SizedBox(height: 12),
            Text('输入关键词，搜索软件库资源',
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied,
                size: 56, color: Colors.grey.withAlpha(90)),
            const SizedBox(height: 12),
            Text('没有找到「$_keyword」相关软件',
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 6),
            Text('换个关键词试试',
                style: TextStyle(color: Colors.grey[400], fontSize: 12.5)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      itemCount: _results.length,
      itemBuilder: (context, index) => AppCard(
        item: _results[index],
        onTap: () => Get.toNamed(Routes.appDetails, arguments: {
          'appId': _results[index].id.toString(),
          'item': _results[index],
        }),
      ),
    );
  }
}
