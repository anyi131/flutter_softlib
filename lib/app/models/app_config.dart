/// App 全局配置（来自 /api/softlib/config/index，后台可远程下发）
class AppConfig {
  final String placard;
  final String feedbackGroup;
  final String feedbackUser;

  // ===== 开屏页 =====
  final bool splashEnable;
  final String splashImage;
  final int splashSeconds;
  final String splashUrl;
  final String splashTitle;
  final String splashDesc;

  // ===== 公告弹窗 =====
  final bool noticeEnable;
  final String noticeTitle;
  final String noticeContent;
  final String noticeUrl;
  final bool noticeForce;

  // ===== 远程控制 =====
  final bool maintainEnable;
  final String maintainText;
  final String serviceUrl;
  final String agreement;
  final String privacy;
  final bool groupBtnOn;
  final bool userBtnOn;
  /// 软件列表数据源: all / local / lzy
  final String appSource;

  AppConfig({
    this.placard = '',
    this.feedbackGroup = '',
    this.feedbackUser = '',
    this.splashEnable = true,
    this.splashImage = '',
    this.splashSeconds = 2,
    this.splashUrl = '',
    this.splashTitle = '',
    this.splashDesc = '',
    this.noticeEnable = false,
    this.noticeTitle = '公告',
    this.noticeContent = '',
    this.noticeUrl = '',
    this.noticeForce = false,
    this.maintainEnable = false,
    this.maintainText = '',
    this.serviceUrl = '',
    this.agreement = '',
    this.privacy = '',
    this.groupBtnOn = true,
    this.userBtnOn = true,
    this.appSource = 'all',
  });

  static bool _b(dynamic v) =>
      v == true || v == 1 || v == '1' || v == 'true';
  static int _i(dynamic v) => int.tryParse((v ?? '').toString()) ?? 0;
  static String _s(dynamic v) => (v ?? '').toString();

  factory AppConfig.fromJson(Map json) => AppConfig(
        placard: _s(json['placard']),
        feedbackGroup: _s(json['feedback_group']),
        feedbackUser: _s(json['feedback_user']),
        splashEnable: json.containsKey('splash_enable')
            ? _b(json['splash_enable'])
            : true,
        splashImage: _s(json['splash_image']),
        splashSeconds: _i(json['splash_seconds']) <= 0
            ? 2
            : _i(json['splash_seconds']),
        splashUrl: _s(json['splash_url']),
        splashTitle: _s(json['splash_title']),
        splashDesc: _s(json['splash_desc']),
        noticeEnable: _b(json['notice_enable']),
        noticeTitle: _s(json['notice_title']).isEmpty
            ? '公告'
            : _s(json['notice_title']),
        noticeContent: _s(json['notice_content']),
        noticeUrl: _s(json['notice_url']),
        noticeForce: _b(json['notice_force']),
        maintainEnable: _b(json['maintain_enable']),
        maintainText: _s(json['maintain_text']),
        serviceUrl: _s(json['service_url']),
        agreement: _s(json['agreement']),
        privacy: _s(json['privacy']),
        groupBtnOn: json.containsKey('feedback_group_on')
            ? _b(json['feedback_group_on'])
            : true,
        userBtnOn: json.containsKey('feedback_user_on')
            ? _b(json['feedback_user_on'])
            : true,
        appSource: _s(json['app_source']).isEmpty
            ? 'all'
            : _s(json['app_source']),
      );
}
