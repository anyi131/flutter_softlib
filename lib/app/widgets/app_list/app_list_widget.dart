import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config.dart';
import '../../models/http/results/lzy_dir_parse_model.dart';
import 'app_list_logic.dart';

class AppListWidget extends StatefulWidget {
  final String? url;

  const AppListWidget({super.key, required this.url});

  @override
  State<AppListWidget> createState() => _AppListWidgetState();
}

class _AppListWidgetState extends State<AppListWidget>
    with AutomaticKeepAliveClientMixin<AppListWidget> {
  late AppListLogic logic;

  @override
  void initState() {
    super.initState();
    logic = Get.find<AppListLogic>(tag: widget.url);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GetBuilder<AppListLogic>(
      id: 'apps',
      tag: widget.url,
      builder: (logic) {
        List<LzyDirParseData>? appList = logic.appList;
        if (logic.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (appList == null || appList.isEmpty) {
          return const Center(child: Text('暂无数据'));
        }
        return EasyRefresh(
          onLoad: logic.loadNextPage,
          onRefresh: logic.reload,
          controller: logic.easyRefreshController,
          child: ListView.builder(
            itemCount: appList.length,
            itemBuilder: (context, index) {
              LzyDirParseData appInfo = appList[index];
              return _buildListItem(appInfo);
            },
          ),
        );
      },
    );
  }

  /// 构建列表元素（现代卡片式）
  Widget _buildListItem(LzyDirParseData appInfo) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: appInfo.icon ?? '',
            fit: BoxFit.cover,
            width: 56,
            height: 56,
            placeholder: (context, url) => appIcon(56, 56),
            errorWidget: (context, url, error) => appIcon(56, 56),
          ),
        ),
        title: Text(
          appInfo.nameAll ?? '未知应用',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  if ((appInfo.size ?? '').isNotEmpty) ...[
                    Icon(Icons.data_usage,
                        size: 13, color: scheme.primary.withAlpha(150)),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        appInfo.size!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if ((appInfo.time ?? '').isNotEmpty)
                Text(
                  appInfo.time!,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '查看',
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        onTap: () => logic.goToView(appInfo),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
