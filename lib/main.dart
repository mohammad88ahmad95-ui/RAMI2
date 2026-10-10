import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  try {
    await state.load();
  } catch (_) {
    runApp(const _StartupError());
    return;
  }
  runApp(ChangeNotifierProvider<AppState>.value(value: state, child: const RamiApp()));
}

class _StartupError extends StatelessWidget {
  const _StartupError();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: buildTheme(Brightness.light),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: kOrange),
                const SizedBox(height: 16),
                const Text('تعذّر تشغيل التطبيق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('تعذّر فتح قاعدة البيانات. أغلق التطبيق وأعد فتحه.', textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
