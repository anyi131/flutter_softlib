import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/app_item.dart';
import '../../services/soft_service.dart';

class AppSearchLogic extends GetxController {
  /// 搜索结果（供搜索结果页使用）
  List<AppItem> results = [];

  final SoftService _service = SoftService.instance;
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;

  /// 执行搜索
  Future<List<AppItem>> search(String keyword) async {
    isSearching = true;
    update();
    try {
      results = await _service.fetchApps(keyword: keyword);
      return results;
    } finally {
      isSearching = false;
      update();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
