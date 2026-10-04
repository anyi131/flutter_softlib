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

  // ===== 关于软件（后台可配）=====
  final bool aboutEnable;
  final String aboutName;
  final String aboutVersion;
  final String aboutLogo;
  final String aboutSlogan;
  final String aboutDesc;
  final String aboutCopyright;
  final String aboutContact;
  final String aboutWebsite;
  final String aboutUpdateUrl;
  final String aboutExtra;

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
    this.aboutEnable = true,
    this.aboutName = '安逸软件库',
    this.aboutVersion = '1.0.0',
    this.aboutLogo = '',
    this.aboutSlogan = '优质软件 · 持续更新',
    this.aboutDesc = '',
    this.aboutCopyright = '',
    this.aboutContact = '',
    this.aboutWebsite = '',
    this.aboutUpdateUrl = '',
    this.aboutExtra = '',
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
        aboutEnable: json.containsKey('about_enable')
            ? _b(json['about_enable'])
            : true,
        aboutName: _s(json['about_name']).isEmpty
            ? '安逸软件库'
            : _s(json['about_name']),
        aboutVersion: _s(json['about_version']).isEmpty
            ? '1.0.0'
            : _s(json['about_version']),
        aboutLogo: _s(json['about_logo']),
        aboutSlogan: _s(json['about_slogan']),
        aboutDesc: _s(json['about_desc']),
        aboutCopyright: _s(json['about_copyright']),
        aboutContact: _s(json['about_contact']),
        aboutWebsite: _s(json['about_website']),
        aboutUpdateUrl: _s(json['about_update_url']),
        aboutExtra: _s(json['about_extra']),
      );
}
