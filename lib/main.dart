import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_provider.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  await auth.init();
  runApp(BatoBuzzAdminApp(auth: auth));
}

class BatoBuzzAdminApp extends StatelessWidget {
  final AuthProvider auth;
  const BatoBuzzAdminApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: auth,
      child: Builder(
        builder: (context) {
          final router = buildRouter(auth);
          return MaterialApp.router(
            title: 'BatoBuzz Admin',
            theme: AppTheme.dark,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
