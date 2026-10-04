# Softlib UI 迁移规范（必读）

本项目正在做「设计系统统一 + 组件库」重构。所有页面必须遵守以下规则。

## 唯一真源
配色/圆角/排版/装饰 只能来自 `lib/app/design/ui.dart`：

```dart
import '../../design/ui.dart';   // 按层级调整相对路径
```

- **配色**：`C.*` — `C.brand`(主蓝 #4B5EF5) `C.brandBright` `C.brandDeep` `C.success`
  `C.warning` `C.danger` `C.gold` `C.cyan` `C.violet` `C.pink` `C.amber` `C.mint`
  `C.rose` `C.accentOrange`；深色底 `C.bg0/bg1/bg2/bg3`；浅色底 `C.lbg0/lbg1/lbg2/lbg3`；
  深色文字 `C.t1/t2/t3`；浅色文字 `C.lt1/lt2/lt3`；玻璃描边 `C.stroke`
- **圆角**：`R.xs=8 R.sm=12 R.md=16 R.lg=20 R.xl=26 R.xxl=32 R.full=999`
- **排版**：`Ty.display Ty.h1 Ty.h2 Ty.h3 Ty.body Ty.small Ty.tiny`
- **装饰**：`Deco.pageBackground(context)`（页面底 + 光晕）、`Deco.glass(...)`（玻璃卡）、
  `Deco.brandGradient` `Deco.goldGradient` `Deco.aurora()` `Deco.orb(color,size)`
- **context 扩展**：`context.isDark` `context.t1/t2/t3` `context.cardBg`

⚠️ **严禁**再写裸 `Color(0xFF...)`、`AppColor.*`、`AppRadius.*`。
例外：语义上的「品牌色微调」（如 `C.brand.withAlpha(20)`）是允许的。

## 统一组件库
按钮/卡片/标签/空态/加载 只能用 `lib/app/design/kit.dart`：

```dart
import '../../design/kit.dart';
```

- `PrimaryButton(label, onPressed, icon?, color?, gold?, loading?, height?, enabled?)`
  — 主行动按钮（渐变胶囊 + 内高光 + 光晕 + 图标圆底）。下载/提交/立即购买 用它。
- `SoftButton(label, onPressed, icon?, color?, height?, expand?)` — 次级描边按钮
- `MiniAction(label, icon, onTap, color?)` — 小圆角操作（暂停/取消/重试）
- `KitCard({child, padding?, margin?, radius?, onTap?, gradient?, border?})` — 统一卡片
- `Pill(text, color?, icon?, solid?, small?)` — 标签
- `SectionHeader(title, subtitle?, action?, accent?)` — 分区标题（左侧竖条）
- `EmptyState(text?, hint?, icon?, action?)` — 空态
- `ErrorState(text?, hint?, onRetry?)` — 错误态
- `LoadingState(text?)` — 首屏加载
- `Skeleton(width?, height?, radius?)` / `SkeletonList(count?)` — 骨架屏
- `KitProgress(value, color?, height?)` — 进度条
- `StatRow(items: [StatItem(value, label, color?)])` — 数据条

## 迁移要求
1. **不改变功能与布局结构**，只统一「视觉语言」：色值、圆角、按钮、空态、加载态。
2. 页面里的 `CircularProgressIndicator` 首屏加载 → `LoadingState` 或 `SkeletonList`。
   （行内小转圈如按钮加载态可保留）
3. 页面里的 `Center(child: Text('暂无数据'))` → `EmptyState`。
4. 私有按钮/卡片 widget（如 `_btn` / `_card` / `_myCard`）→ 若与 kit 组件等价则删除并改用 kit；
   若特殊则改造为基于 `C/R/Ty` 的自定义样式。
5. 所有 `AppColor.*` → 对应 `C.*`（`primary→brand`、`cardDark→bg2`、`bgLight→lbg0`、`bgDark→bg0`、
   `success→success`、`gold→gold`）；`AppRadius.*` → `R.*`。
6. **不要动** GetX 逻辑、网络请求、状态管理。
7. 完成后必须自查：
   - 花括号/圆括号平衡
   - 所有相对 import 路径存在
   - 删除无用的 import（避免 unused import 警告）
   - `grep -c "AppColor\|AppRadius" 文件` 应为 0

## 已完成范例
- `lib/app/pages/app_details/app_details_page.dart`（详情页）— 已完全迁移，可作参考。
- `lib/app/design/kit.dart` — 组件库实现。
