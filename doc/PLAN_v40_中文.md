# Softlib 第40阶段 改造计划（v40）

## 一、后端（服务器 /www/wwwroot/flrjk.52yfx.cn）
源码本地副本：/root/softlib-backend

### B1. 采集导入补全图标/版本/大小/应用截图（对应#3）
- `app/collect_api.php` → `admin_collect_import()`
  - ★ 真因1：写死 `$put('screenshots','')` → 改为写入 preview
  - ★ 真因2：App 只传 4 字段 → App 侧补齐（见 A1）
  - 新增：`$put('screenshots', 处理后的preview)`
  - icon 兼容多字段名
- `app/collect_extra.php` → `admin_collect_results()`（日志反查）
  - ★ 真因3：反查只返回 ok/name/url/desc → 缺失 logo/size/version/preview
  - 修法：反查时按 name 回查站点列表页缓存，补全字段
    （或把采集列表页字段缓存到 data/collect_meta.json，反查时合并）

### B2. 赞助排行榜包含余额充值（对应#5）
- `app/user_api.php` → `user_donate_rank()`
  - ★ 真因：`WHERE ... o.plan_id <> 'recharge'` 排除了充值
  - 改为：统计全部已支付订单（会员+充值），并区分展示
  - 返回增加 `vip_amount` / `recharge_amount` / `total`

### B3. 抖音/快手视频解析真直链（对应#13）
- `app/video_extra.php`
  - ★ 真因：抖音返回分享页 iframe，WebView 里 isAutoOpenApp 强制跳 App → 播不了
  - 修法：接入第三方解析源拿 mp4 直链（多源备用）
    - 主源：https://api.xingzhige.com/API/douyin/?url=<encoded>
      → data.item.url = 无水印 mp4 直链, cover, duration, width, height
    - 备用源若干（失败降级到 iframe）
  - 返回：type=file, url=直链, cover=封面  （App 用原生播放器）

### B4. 开屏配置 + 后台可配主页两个按钮（对应#9、#14）
- `app/admin_api.php` → `admin_config()` / `admin_config_save()`
  - 补 `feedback_group_on/user_on/group/user`（主页两个圆形按钮）
  - 补 splash 相关（应已有）
- 网页端 `public/admin/splash.php` 同步补这两个开关

### B5. 网页端后台功能对齐（对应#11）
- 新增/补全接口：评论管理、帖子编辑、举报处理、卡密、版本、推荐位等
  （admin_api.php 里已有大部分，缺的补齐）

## 二、App 端（/root/work/softlib）

### A1. 采集导入字段补全（对应#3）
- `lib/app/pages/admin/tabs/admin_collect_tab.dart` → `_import()`
  - 传 preview（应用截图）
  - 保存采集列表的完整元数据，供反查合并

### A2. 软件下载判断逻辑修复（对应#2）
- `lib/app/pages/app_details/app_details_page.dart` → `_onDownload()`
  - ★ 真因：`if (!isVipItem) { 下载; return; }` 没判断 vip_price
  - 改为：只要是「会员专享 或 有价格」都要走 UnlockService 校验
  - AppItem 增加 `hasPrice` getter

### A3. 广场/详情视频尺寸 + 加载优化（对应#1）
- `lib/app/widgets/post_video_player.dart`
  - ★ 真因：写死 height 210 / 全屏 AspectRatio，且每个卡片自动加载
  - 改：默认按 16:9 限制高度（maxHeight），列表态显示封面不自动加载
  - file 类型支持 cover 占位、懒加载（滚动可见才初始化）
  - 支持 type='file' 播抖音直链，size 可控

### A4. 开屏本地数据优先（对应#9）
- `lib/app/pages/splash/splash_page.dart`
  - ★ 需求：用户「替换开屏」选过图 → 走本地；没选过 → 走服务器
  - 改：用户选的图存本地文件路径（SharedPreferences），启动时优先读本地
- `lib/app/pages/navigate/mine/mine_logic.dart` → 替换开屏
  - 保存本地路径

### A5. 后台软件管理可编辑可增删（对应#7）
- `lib/app/pages/admin/tabs/admin_apps_tab.dart`
  - 新增/编辑弹窗（完整字段：名称/图标/来源/链接/大小/版本/描述/分类/会员专享/会员价/截图/排序/开关）
  - 删除确认
  - 分类管理（增删改）
  - 依赖 admin_service 已有 saveApp/deleteApp/saveCat/deleteCat

### A6. App 内后台补全网页端功能（对应#11）
- `admin_content_tab.dart` 完善：评论/帖子增删改、举报、卡密、版本、推荐位
- 移动端适配（列表/表单/弹窗自适应）

### A7. 下载列表美化（对应#6）
- `lib/app/pages/app_download/app_download_page.dart`
  - 卡片重做：图标/名称/大小/进度条/状态标签/操作按钮
  - 分组：下载中 / 已完成
  - 空状态美化

### A8. 性能 + 过渡动画（对应#12）
- 过渡动画统一 Cupertino（已有，检查补全）
- 列表 CachedNetworkImage 加 memCacheWidth 降内存
- 图片懒加载、避免重复请求
- 减少不必要 rebuild（GetBuilder id 收敛）

### A9. 全项目扫描布局溢出（沿用上阶段方法）

## 三、验证
- 后端：写 fulltest_v40.php，HTTP 实测全部接口
- App：本地 dart analyze + 关键逻辑单测；CI 构建 APK
- 交付：APK 路径 + CI run 链接
