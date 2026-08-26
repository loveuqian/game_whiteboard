import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

const Color whiteboardColor = Colors.white;
const int whiteboardSectionCount = 3;

int _whiteboardSectionIndex = 0;
int _whiteboardVisibleSectionCount = 1;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    final display = await screenRetriever.getPrimaryDisplay();
    final visibleFrame = display.visiblePosition ?? Offset.zero;
    final size = Size(display.size.width, display.size.height / whiteboardSectionCount);
    final maximumSize = Size(display.size.width, size.height * 2);

    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: size,
        minimumSize: size,
        maximumSize: maximumSize,
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
                _closeWhiteboard();
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
            child: const WhiteboardHome(),
          ),
        ),
      ),
    );
  }
}

class WhiteboardHome extends StatelessWidget {
  const WhiteboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: whiteboardColor,
      child: Stack(
        children: <Widget>[
          SizedBox.expand(),
          _YDHiddenCloseButton(),
          _YDWhiteboardSectionButtons(),
        ],
      ),
    );
  }
}

class _YDWhiteboardSectionButtons extends StatelessWidget {
  const _YDWhiteboardSectionButtons();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 88,
      right: 24,
      child: Column(
        children: List<Widget>.generate(5, (index) {
          const labels = <String>['上', '中', '下', '上中', '中下'];
          final visibleSectionCount = index >= whiteboardSectionCount ? 2 : 1;
          final sectionIndex = index >= whiteboardSectionCount ? index - whiteboardSectionCount : index;
          return Padding(
            padding: EdgeInsets.only(bottom: index == labels.length - 1 ? 0 : 8),
            child: SizedBox(
              width: 56,
              height: 36,
              child: OutlinedButton(
                onPressed: () => _setWhiteboardLayout(sectionIndex, visibleSectionCount),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.black.withAlpha(18),
                  foregroundColor: Colors.black.withAlpha(160),
                  side: BorderSide(color: Colors.black.withAlpha(35)),
                  padding: EdgeInsets.zero,
                ),
                child: Text(labels[index]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _YDHiddenCloseButton extends StatefulWidget {
  const _YDHiddenCloseButton();

  @override
  State<_YDHiddenCloseButton> createState() => _YDHiddenCloseButtonState();
}

class _YDHiddenCloseButtonState extends State<_YDHiddenCloseButton> with SingleTickerProviderStateMixin {
  static const Duration _closeDuration = Duration(seconds: 2);
  static const double _buttonSize = 56;
  static const double _progressStrokeWidth = 3;

  late final AnimationController _progressController;
  Timer? _closeTimer;
  bool _isPressing = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _closeDuration,
    );
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _toggleCloseProgress() {
    if (_closeTimer != null) {
      _cancelCloseProgress();
      return;
    }

    _closeTimer?.cancel();
    _progressController
      ..stop()
      ..value = 0
      ..forward();
    setState(() {
      _isPressing = true;
    });
    _closeTimer = Timer(_closeDuration, () {
      _closeTimer = null;
      _closeWhiteboard();
    });
  }

  void _cancelCloseProgress() {
    if (!_isPressing && _progressController.value == 0 && _closeTimer == null) {
      return;
    }

    _closeTimer?.cancel();
    _closeTimer = null;
    _progressController
      ..stop()
      ..value = 0;
    if (!mounted) {
      return;
    }

    setState(() {
      _isPressing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 24,
      right: 24,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleCloseProgress,
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return SizedBox(
                width: _buttonSize,
                height: _buttonSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(_isPressing ? 34 : 18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.withAlpha(35),
                          width: 1,
                        ),
                      ),
                      child: const SizedBox(
                        width: _buttonSize,
                        height: _buttonSize,
                      ),
                    ),
                    SizedBox(
                      width: _buttonSize,
                      height: _buttonSize,
                      child: CircularProgressIndicator(
                        value: _progressController.value,
                        strokeWidth: _progressStrokeWidth,
                        backgroundColor: Colors.red.withAlpha(24),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.red.withAlpha(_isPressing ? 180 : 0),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.stop,
                      size: 22,
                      color: Colors.red.withAlpha(_isPressing ? 180 : 80),
                    ),
                  ],
                ),
              );
            },
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
  await _setWhiteboardLayout(
    _whiteboardSectionIndex + offset,
    _whiteboardVisibleSectionCount,
  );
}

Future<void> _setWhiteboardLayout(int sectionIndex, int visibleSectionCount) async {
  if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    return;
  }

  final display = await screenRetriever.getPrimaryDisplay();
  final visibleFrame = display.visiblePosition ?? Offset.zero;
  final sectionHeight = display.size.height / whiteboardSectionCount;
  final maxSectionIndex = whiteboardSectionCount - visibleSectionCount;
  _whiteboardVisibleSectionCount = visibleSectionCount;
  _whiteboardSectionIndex = sectionIndex.clamp(0, maxSectionIndex).toInt();

  await windowManager.setBounds(
    Rect.fromLTWH(
      visibleFrame.dx,
      visibleFrame.dy + sectionHeight * _whiteboardSectionIndex,
      display.size.width,
      sectionHeight * visibleSectionCount,
    ),
  );
}

Future<void> _closeWhiteboard() async {
  if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    return;
  }

  await windowManager.close();
}
