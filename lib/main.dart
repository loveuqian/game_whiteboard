import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

const Color whiteboardColor = Colors.white;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    final display = await screenRetriever.getPrimaryDisplay();
    final visibleFrame = display.visiblePosition ?? Offset.zero;
    final size = Size(display.size.width, display.size.height / 3);

    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: size,
        minimumSize: size,
        maximumSize: size,
        center: false,
        titleBarStyle: TitleBarStyle.hidden,
        alwaysOnTop: true,
        skipTaskbar: true,
        backgroundColor: whiteboardColor,
      ),
      () async {
        await windowManager.setBounds(
          Rect.fromLTWH(
            visibleFrame.dx,
            visibleFrame.dy,
            size.width,
            size.height,
          ),
        );
        await windowManager.setResizable(false);
        await windowManager.setAlwaysOnTop(true);
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  runApp(const WhiteboardApp());
}

class WhiteboardApp extends StatelessWidget {
  const WhiteboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyQ, control: true, alt: true, shift: true): ActivateIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<Intent>(
              onInvoke: (_) {
                windowManager.close();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: const ColoredBox(
              color: whiteboardColor,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}
