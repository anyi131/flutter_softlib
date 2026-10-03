import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/soft_service.dart';
import '../../../models/app_item.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/app_card.dart';

/// 应用 - 软件列表（双数据源：蓝奏云解析 / 服务器直传）
class AppComponent extends StatefulWidget {
  const AppComponent({super.key});

  @override
  State<AppComponent> createState() => _AppComponentState();
}

class _AppComponentState extends State<AppComponent> {
  final SoftService _service = SoftService.instance;

  List<AppItem> _apps = [];
  bool _loading = true;
  String? _error;
  String _keyword = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchApps(keyword: _keyword);
      if (!mounted) return;
      setState(() {
        _apps = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请检查网络';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('软件', style: TextStyle(fontWeight: FontWeight.w600)),
        actionsPadding: const EdgeInsets.only(right: 6),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => Get.toNamed(Routes.appDownload),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(21),
              ),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (v) {
                  _keyword = v;
                  _load();
                },
                decoration: InputDecoration(
                  hintText: '搜索软件名称',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[500]),
                  suffixIcon: _keyword.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _keyword = '';
                            _load();
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 64, color: Colors.grey.withAlpha(120)),
          const SizedBox(height: 12),
          Center(child: Text(_error!, style: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(onPressed: _load, child: const Text('重试')),
          ),
        ],
      );
    }
    if (_apps.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 140),
          Center(child: Text('暂无软件', style: TextStyle(color: Colors.grey))),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 20),
      itemCount: _apps.length,
      itemBuilder: (context, index) => AppCard(
        item: _apps[index],
        onTap: () => Get.toNamed(Routes.appDetails, arguments: {
          'appId': _apps[index].id.toString(),
          'item': _apps[index],
        }),
      ),
    );
  }
}
