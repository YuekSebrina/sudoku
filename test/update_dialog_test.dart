import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/models/update_info.dart';
import 'package:sudoku/widgets/update_dialog.dart';

void main() {
  testWidgets('showUpdateDialog works with root MaterialApp context', (
    tester,
  ) async {
    final appKey = GlobalKey();
    final info = UpdateInfo(
      hasUpdate: true,
      latestVersion: '1.1.0',
      downloadUrl: 'http://example.com/sudoku-windows.zip',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          key: appKey,
          builder: (context) => const SizedBox.shrink(),
        ),
      ),
    );

    final dialog = showUpdateDialog(appKey.currentContext!, info);
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('1.1.0'), findsWidgets);

    Navigator.of(appKey.currentContext!).pop();
    await dialog;
  });
}
