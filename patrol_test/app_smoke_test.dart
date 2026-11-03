// 冒烟测试：搜索 → 详情页
//
// 本地跑：
//   patrol test --target patrol_test/app_smoke_test.dart -d <deviceId>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:flutter_softlib/app/routes/app_pages.dart';
import 'package:flutter_softlib/app/widgets/app_card.dart';
import 'package:get/get.dart';

import 'package:flutter_softlib/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  patrolTest(
    '搜索关键词，能出结果并进入详情页',
    ($) async {
      // ★ 1103：main() 里为了「不白屏」改写了 ErrorWidget.builder /
      //   FlutterError.onError。flutter_test 会在用例结束时校验这两个全局
      //   必须还原，否则报 "The value of ErrorWidget.builder was changed by
      //   the test."。必须在 body 返回前还原（addTearDown 太晚）。
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      final originalFlutterErrorOnError = FlutterError.onError;

      // ★ 1103：设备首启会停在引导页（onboard_done=false），
      //   后面所有断言都会找不到控件。用内存 prefs 标记已引导。
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({'onboard_done': true});

      try {
        app.main();
        await $.pump(const Duration(seconds: 2));
        await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

        // 直接进搜索页，跳过开屏/登录
        Get.toNamed(Routes.appSearch);
        await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));
        expect($(#searchField), findsOneWidget);

        await $(#searchField).enterText('病毒');
        await $.pump(const Duration(milliseconds: 400));

        // ★ 1103：搜索是「按钮触发」不是防抖也不是回车提交——
        //   之前用 receiveAction(done)，服务端一条搜索请求都没收到，
        //   结果永远是 0 条，测试白跑。改点按钮。
        if ($(#searchBtn).evaluate().isNotEmpty) {
          await $(#searchBtn).tap();
        } else {
          await $.tester.testTextInput.receiveAction(TextInputAction.search);
        }

        // 轮询等结果，最多 30s
        var found = false;
        for (var i = 0; i < 60; i++) {
          await $.pump(const Duration(milliseconds: 500));
          if ($(find.byType(AppCard)).evaluate().isNotEmpty) {
            found = true;
            break;
          }
        }
        expect(found, isTrue, reason: '搜索 30s 内没有返回任何结果，接口/网络异常');

        await $(find.byType(AppCard)).first.tap();
        // ★ 1103：详情页内容较长，下载按钮在底部，可能是懒加载的 Sliver，
        //   不滚动根本不会被 build。先轮询，中途滚一次，最后带诊断信息失败。
        var ready = false;
        for (var i = 0; i < 40 && !ready; i++) {
          await $.pump(const Duration(milliseconds: 500));
          ready = $(#downloadBtn).evaluate().isNotEmpty;
          if (!ready && i == 10) {
            try {
              await $.scrollUntilVisible(
                finder: find.byKey(const ValueKey('downloadBtn')),
                maxScrolls: 20,
              );
            } catch (_) {}
          }
        }
        if (!ready) {
          final texts = $.tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data)
              .whereType<String>()
              .take(25)
              .join(' | ');
          expect(ready, isTrue, reason: '没找到下载按钮，当前页面文字: $texts');
        }

        // 详情页核心控件在
        expect($(#downloadBtn), findsOneWidget);
        $.log('搜索有结果，详情页打开成功，下载按钮可见');
      } finally {
        ErrorWidget.builder = originalErrorWidgetBuilder;
        FlutterError.onError = originalFlutterErrorOnError;
      }
    },
  );
}
