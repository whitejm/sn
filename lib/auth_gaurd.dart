import 'package:flutter/material.dart';
import 'package:sn/login_form.dart';
import 'package:sn/pocketbase_auth.dart';
import 'package:provider/provider.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loginStatus = Provider.of<PocketBaseAuthNotifier>(context);
    return Scaffold(body: loginStatus.isLoggedIn ? child : LoginForm());
  }
}
