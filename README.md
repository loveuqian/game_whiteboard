# game_whiteboard

一个用于游戏双开电脑的纯色白板应用，默认覆盖主屏幕顶部三分之一，并拦截落在该区域的鼠标点击。

## 运行

```bash
flutter run -d macos
```

Windows 电脑上运行：

```bash
flutter run -d windows
```

## 构建 Windows 程序

需要在 Windows 电脑上执行：

```bash
flutter build windows
```

构建产物在 `build/windows/x64/runner/Release/` 目录。

## 使用说明

- 启动后窗口会置顶、无边框、纯白显示。
- 默认覆盖主屏幕顶部三分之一。
- 点击白板区域不会穿透到桌面。
- 按 `Ctrl+Alt+Shift+Q` 退出。
- 窗口尺寸按系统返回的屏幕逻辑尺寸计算，适配 4K 和 Windows 缩放比例。
