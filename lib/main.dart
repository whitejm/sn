import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:sn/auth_gaurd.dart';
import 'package:sn/dashboard.dart';
import 'package:sn/pocketbase_auth.dart';
import 'package:sn/pocketbase_library.dart';
import 'login_form.dart';
import 'password_reset_form.dart';
import 'sign_up_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';

Future<void> main() async {
  // Load environment variables from Netlify if available
  String pbUrl = String.fromEnvironment('POCKETBASE');

  // If the environment variable is not available in Netlify, load from .env file
  if (pbUrl.isEmpty) {
    await dotenv.load();
    pbUrl = dotenv.get('POCKETBASE', fallback: 'http://127.0.0.1:8090');
  }

  final pb = PocketBase(pbUrl);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => PocketBaseAuthNotifier(pb)),
      ChangeNotifierProvider(
          create: (context) => PocketBaseLibraryNotifier(pb)),
    ],
    child: App(),
  ));
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Subnotes",
      initialRoute: "/",
      routes: {
        '/': (context) => AuthGuard(child: DashboardPage()),
        '/login': (context) => AuthGuard(child: LoginForm()),
        '/signup': (context) => const Scaffold(body: SignUpForm()),
        '/resetpassword': (context) => Scaffold(body: PasswordResetForm()),
      },
    );
  }
}
