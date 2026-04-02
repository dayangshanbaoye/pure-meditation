# Pure Meditation · 纯粹冥想

> 一款极简、优雅的冥想计时与数据可视化工具。
> 摒弃繁杂的课程推荐与社交功能，专注于「计时」与「记录」，为你的冥想旅程提供纯粹的反馈与习惯养成动力。

---

## 产品特性

### 🧘 极简冥想空间

- **一键开始/结束**：首页仅保留最核心的交互。一个优雅的呼吸灯效果按钮，点击开始计时，再次点击结束——自动生成冥想记录。
- **呼吸引导**：冥想过程中，屏幕中央的「吸气 / 呼气」引导文字与按钮光晕同步呼吸节律，帮助你自然地进入深度放松。
- **实时计时器**：采用 Space Grotesk 等宽字体，优雅显示冥想时长，运行时以荧光渐变色高亮。

### 🎵 背景音乐系统

- **4 种内置环境音**：雨声 · 海浪 · 颂钵 · 森林，自带高品质本地音频资源，完全离线免流，一键播放即刻沉浸。
- **导入本地音频**：支持导入手机中的任意音频文件作为冥想背景音。
- **本地音乐管理**：已导入的音乐会被持久化保存，可随时查看列表、重新播放或删除。
- **迷你播放控制条**：主屏幕底部显示当前播放的音频名称，提供播放/暂停、停止控制，无需再次打开音乐选择面板。
- **后台播放**：冥想时切出 App，音乐在后台持续播放不中断，系统通知栏提供媒体控制。

### 🎨 自定义冥想类型

- **自由创建**：预置「正念呼吸」「内观」「睡前放松」三种类型，你也可以随时新增自定义类型（如行走冥想、瑜伽冥想等）。
- **颜色标识**：12 色调色板，为每个类型分配专属强调色，在统计图表中一目了然。
- **编辑与删除**：支持编辑名称/颜色，左滑删除，操作直觉流畅。

### 📊 数据统计与优雅可视化

- **总览数据卡**：首屏展示累计冥想总时长（小时）和总次数，采用荧光渐变数字 + 发光毛玻璃卡片设计。
- **GitHub 风格热力图**：以网格形式展示全年打卡记录，颜色从深到浅直观体现每日冥想投入度。共 5 个色阶：
  - 空白 → < 5分钟 → 5-10分钟 → 10-30分钟 → 30-60分钟 → > 60分钟
- **月度趋势图**：柱状图展示每月/每周冥想时长分布，叠加折线图显示累计总时长增长趋势。
- **按类型筛选**：顶部标签支持一键切换，单独查看某一冥想类型的热力图和统计图。

---

## 设计语言

| 维度 | 实现 |
|------|------|
| **色彩** | 深色模式为主（深藏青 `#060A18` → `#0F1428`），荧光青 `#00FFC8` 作为主强调色，暖琥珀 `#FFB74D` 为辅助色 |
| **字体** | Inter（UI/正文）+ Space Grotesk（计时器/数字），均为本地字体 |
| **视觉风格** | 毛玻璃（Glassmorphism）卡片、渐变发光阴影、微动画过渡 |
| **动画** | 呼吸按钮光晕 4-6秒循环、导航切换弹跳、卡片入场渐显 |
| **交互** | 极简手势：点击计时、下拉选择、左滑删除、底部弹窗 |

---

## 技术架构

| 层级 | 技术选型 |
|------|---------|
| **框架** | Flutter（跨 Android / iOS） |
| **状态管理** | Provider + ChangeNotifier |
| **本地存储** | Hive（冥想记录、类型、每日统计）+ SharedPreferences（音乐列表） |
| **音频播放** | just_audio + audio_service（后台播放 + 系统通知栏控制） |
| **图表** | fl_chart（柱状图 + 折线图） |
| **热力图** | 自定义 GridView 实现 |
| **文件管理** | file_picker + path_provider |

## 数据模型

### MeditationType（冥想类型）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String (UUID) | 唯一标识 |
| `name` | String | 类型名称，如「正念呼吸」 |
| `colorCode` | String | 颜色代码，如 `#00FFC8` |

### MeditationRecord（冥想记录）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String (UUID) | 唯一标识 |
| `startTime` | DateTime | 开始时间 |
| `endTime` | DateTime | 结束时间 |
| `durationSeconds` | int | 冥想时长（秒） |
| `typeId` | String | 关联的冥想类型 ID |
| `musicUsed` | String? | 使用的音频路径/名称 |

### DailyStats（每日统计 · 聚合表）

| 字段 | 类型 | 说明 |
|------|------|------|
| `date` | String | 日期 `yyyy-MM-dd` |
| `totalDurationSeconds` | int | 当日总冥想时长 |
| `sessionCount` | int | 当日冥想次数 |
| `typeBreakdown` | Map\<String, int\> | 各类型时长分布 |

---

## 应用结构

```
lib/
├── main.dart                          # 应用入口 & Provider 注入
├── models/
│   ├── meditation_type.dart           # 冥想类型模型
│   ├── meditation_record.dart         # 冥想记录模型
│   └── daily_stats.dart               # 每日统计模型
├── services/
│   ├── storage_service.dart           # Hive 数据存储
│   ├── timer_service.dart             # 计时器核心（时间戳比较）
│   ├── audio_handler.dart             # 音频播放 & 后台服务
│   └── local_music_service.dart       # 本地音乐持久化管理
├── providers/
│   ├── timer_provider.dart            # 计时状态管理
│   └── meditation_provider.dart       # 冥想类型/记录/统计管理
├── screens/
│   ├── main_screen.dart               # 主框架 + 底部导航
│   ├── home_screen.dart               # 冥想首页 + 迷你播放控制
│   ├── stats_screen.dart              # 数据统计页
│   └── type_manage_screen.dart        # 冥想类型管理页
├── widgets/
│   ├── breathing_button.dart          # 呼吸灯效果按钮
│   ├── audio_picker.dart              # 音频选择 & 本地音乐管理
│   ├── heatmap_widget.dart            # GitHub 风格热力图
│   ├── stats_chart.dart               # 趋势统计图表
│   └── glassmorphic_card.dart         # 毛玻璃卡片组件
└── theme/
    ├── app_theme.dart                 # 全局主题
    ├── app_colors.dart                # 色彩系统
    └── app_typography.dart            # 字体 & 间距 & 圆角系统
```

---

## 构建与安装

```bash
# 开发调试
flutter run

# 构建 Android APK
flutter build apk --debug

# APK 输出路径
build/app/outputs/flutter-apk/app-debug.apk
```

将 APK 传输到手机安装即可使用。

---

## 版本记录

### v1.1.1（热修复补丁）
- 🔧 将4款内置音效转为纯本地资产（Assets）打包，去除对第三方 CDN 的网络依赖，彻底解决真机防盗链导致的无声问题

### v1.1
- 🔧 修复内置音效无法播放的问题（添加网络权限）
- ✨ 新增本地音乐持久化管理（查看列表 / 播放 / 删除）
- ✨ 新增首页迷你播放控制条（播放/暂停/停止）
- 💎 音乐按钮状态指示（有音频播放时图标变化）

### v1.0
- 🧘 冥想计时核心功能
- 🎨 自定义冥想类型（创建/编辑/删除/颜色标识）
- 📊 GitHub 热力图 + 月度趋势图
- 🎵 内置环境音 + 本地音频导入
- 🌙 深色毛玻璃 UI 设计