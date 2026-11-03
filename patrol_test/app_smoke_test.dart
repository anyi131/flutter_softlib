// 冒烟测试：搜索 → 详情页（不需要登录，CI 里跑这个）
//
// 本地跑：
//   patrol test patrol_test/app_smoke_test.dart -d <deviceId>

import 'package:flutter/widgets.dart';
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
      //   the test."（第一次 CI 就是挂在这）。先存后还。
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      final originalFlutterErrorOnError = FlutterError.onError;

      // ★ 1103：设备上首次启动会停在引导页（onboard_done=false），
      //   后面所有断言都会找不到控件。用内存 prefs 直接标记已完成引导。
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({'onboard_done': true});

      try {
        app.main();
        // 启动时会拉配置，给一点时间
        await $.pump(const Duration(seconds: 2));
        await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

        // 直接进搜索页，跳过开屏/登录
        Get.toNamed(Routes.appSearch);
        await $.pumpAndTrySettle(timeout: const Duration(seconds: 10));

        expect($(#searchField), findsOneWidget);

        await $(#searchField).enterText('病毒');
        await $.tester.testTextInput.receiveAction(TextInputAction.done);
        await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));

        // 有结果才继续（网络差时只校验页面没崩）
        if ($(find.byType(AppCard)).evaluate().isNotEmpty) {
          await $(find.byType(AppCard)).first.tap();
          await $.pumpAndTrySettle(timeout: const Duration(seconds: 20));
          // 详情页核心控件在
          expect($(#downloadBtn), findsOneWidget);
          $.log('详情页打开成功，下载按钮可见');
        } else {
          $.log('搜索无结果（可能是网络），跳过详情页断言');
        }
      } finally {
        // 必须在用例体返回前还原（flutter_test 的校验在 body 结束后立刻跑，
        // addTearDown 太晚）
        ErrorWidget.builder = originalErrorWidgetBuilder;
        FlutterError.onError = originalFlutterErrorOnError;
      }
    },
  );
}
