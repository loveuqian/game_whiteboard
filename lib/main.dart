import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

const Color whiteboardColor = Colors.white;
const int whiteboardSectionCount = 3;

int _whiteboardSectionIndex = 0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    final display = await screenRetriever.getPrimaryDisplay();
    final visibleFrame = display.visiblePosition ?? Offset.zero;
    final size = Size(display.size.width, display.size.height / whiteboardSectionCount);

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
          SingleActivator(LogicalKeyboardKey.keyQ, control: true, alt: true, shift: true): CloseWindowIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp, control: true, alt: true, shift: true): MoveWindowIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowDown, control: true, alt: true, shift: true): MoveWindowIntent(1),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            CloseWindowIntent: CallbackAction<CloseWindowIntent>(
              onInvoke: (_) {
                windowManager.close();
                return null;
              },
            ),
            MoveWindowIntent: CallbackAction<MoveWindowIntent>(
              onInvoke: (intent) {
                _moveWhiteboard(intent.offset);
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

class CloseWindowIntent extends Intent {
  const CloseWindowIntent();
}

class MoveWindowIntent extends Intent {
  const MoveWindowIntent(this.offset);

  final int offset;
}

Future<void> _moveWhiteboard(int offset) async {
  if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    return;
  }

  final display = await screenRetriever.getPrimaryDisplay();
  final visibleFrame = display.visiblePosition ?? Offset.zero;
  final size = Size(display.size.width, display.size.height / whiteboardSectionCount);
  final nextSectionIndex = _whiteboardSectionIndex + offset;
  _whiteboardSectionIndex = nextSectionIndex.clamp(0, whiteboardSectionCount - 1).toInt();

  await windowManager.setBounds(
    Rect.fromLTWH(
      visibleFrame.dx,
      visibleFrame.dy + size.height * _whiteboardSectionIndex,
      size.width,
      size.height,
    ),
  );
}
