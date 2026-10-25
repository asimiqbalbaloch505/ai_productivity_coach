import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'db_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.init();
  runApp(const MyApp());
}
