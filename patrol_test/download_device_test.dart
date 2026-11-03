// 下载链路测试：会被 `patrol test`（不带 --target）一起执行。
//
// 原则：**不依赖登录态、不依赖网络一定有结果**。
// 搜不到就跳过；没登录就只校验点了不崩。真正的「下载完成」断言留给手工跑。
// 手工跑：
//   patrol test --target patrol_test/download_device_test.dart -d <deviceId>

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
    '详情页点下载 → 能拉起下载流程且不崩',
    ($) async {
      // ★ 1103：main() 改写了这两个全局，flutter_test 在用例结束时会校验，
      //   必须在 body 返回前还原（addTearDown 太晚）。
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      final originalFlutterErrorOnError = FlutterError.onError;

      // ★ 1103：设备首启会停在引导页，标记已引导，否则后面找不到任何控件。
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
        await $.tester.testTextInput.receiveAction(TextInputAction.done);
        await $.pumpAndTrySettle(timeout: const Duration(seconds: 25));

        // 网络/接口抖动时可能没有结果——跳过而不是判失败，避免把 CI 拖红
        if ($(find.byType(AppCard)).evaluate().isEmpty) {
          $.log('搜索无结果（可能是网络），跳过下载断言');
          return;
        }

        await $(find.byType(AppCard)).first.tap();
        await $.pumpAndTrySettle(timeout: const Duration(seconds: 25));

        // 详情页核心控件必须在
        expect($(#downloadBtn), findsOneWidget);

        await $(#downloadBtn).tap();
        // 让解析/下载请求有机会发出去
        await $.pump(const Duration(seconds: 4));

        // ★ 原生层：未登录会弹登录面板，已登录可能弹「允许安装未知应用」
        //   两种都只是记录，不作为失败条件（CI 上不保证有账号）
        try {
          final perm = await $.platform.mobile.isPermissionDialogVisible(
            timeout: const Duration(seconds: 3),
          );
          if (perm) {
            await $.platform.mobile.grantPermissionOnlyThisTime();
            $.log('已接管系统权限弹窗');
          } else {
            $.log('无系统权限弹窗（可能未登录或已授权）');
          }
        } catch (e) {
          $.log('原生弹窗检查异常（不影响结论）: $e');
        }

        await $.pump(const Duration(seconds: 6));

        // 只要还停在详情页且按钮还在，说明点下载没把页面打崩
        expect($(#downloadBtn), findsOneWidget);
        $.log('下载入口可点击，页面未崩溃');
      } finally {
        ErrorWidget.builder = originalErrorWidgetBuilder;
        FlutterError.onError = originalFlutterErrorOnError;
      }
    },
  );
}
