import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/api_config.dart';
import 'core/l10n/l10n.dart';
import 'core/session/session.dart';

/// Entry point: restore the saved language, server address and login, then start the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([L10n.instance.load(), Session.instance.load(), ApiConfig.load()]);
  runApp(const MafqoodakApp());
}
